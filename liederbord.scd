(
var drones;
var max_value = 900; // to be calibrated
var uppermargin = 20;
var lowermargin = 0;

~previous_tonal_function = 1;
~tonal_function = 1;
~previous_chord = nil;
~octaves = [4,5];
~current_scale = Scale.aeolian;
~chord_type = nil;
~mute = (\bass:0, \chords:0);


if (MIDIClient.initialized.not) { MIDIClient.init; };
~midiout = MIDIOut.newByName("INTEGRA-7", "INTEGRA-7 MIDI 1");

~pattern_detector = Require("patterndetector.scd");
~sensormodel = Require("sensormodel.scd");
~communication = Require("communication.scd");
~calibration = Require("calibration.scd");

/* initialize the system */
~sensormodel.setDefaults(~calibration);
~communication.startSerialPortThread(
	[
		//	[~communication[\internal], ~communication[\debug_callback]],
		[~communication[\internal], ~communication[\send_supercollider]],
		//	[~communication[\godot], ~communication[\send_godot]]
	]
);

~command_sequence_recognizer = Require("commandsequencerecognizer.scd");
~markov2d = Require("markov2d.scd");

~supported_chord_types = [[0, 2, 4, 6], [0, 2, 4], [0, 1, 2, 4], [0, 3, 4], [0, 3, 4, 5.1]];

~music_patterns = ();
~music_patterns[\pat_bell] = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 0,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\degree, Plazy {
		Prand( ~chord_type + (~previous_tonal_function-1), inf)
	},
	\ctranspose, Prand([0, 12, 24, 36], inf),
	\amp, Pwhite(0.1, 0.6, inf),
	\dur, Pseq([0.1], 20.rrand(60))
);


~music_patterns[\pat_brass] = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 2,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\degree, Prand(~supported_chord_types + (~tonal_function - 1), inf),
	\ctranspose, Prand([-12, 0, 12], inf),
	\amp, Pwhite(0.4, 0.6, inf),
	\dur, Plazy { Prand([1, 2, 4], 1.rrand(6)) }
);

~voicelead = Require("voicelead.scd");

~music_patterns[\bass] = {Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 3,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\degree, Pfunc {
		if (~mute[\bass] == 1) {
			Rest(1);
		} {
			(~previous_tonal_function - 1);
		}
	},
	\octave, Pseq([3, 4], inf),
	\amp, Pseq([0.7], inf),
	\dur, Pseq([0.25], inf),
)};

~music_patterns[\chords] = {Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 1,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\midinote, Pfunc({
		|ev|
		var chord_degrees, chord_notes, octaves, midi_notes, result;
		if (~mute[\chords] == 1) {
			result = [Rest(1)];
		} {
			if (~chord_type.isNil){
				// first chord should not be too exotic :)
				~chord_type = [0, 2, 4];
			} {
				~chord_type = ~supported_chord_types.choose;
			};
			chord_degrees = (~chord_type + (~tonal_function.debug("new tonal function") - 1));
			chord_notes = chord_degrees.collect({|deg| deg.degreeToKey(~current_scale, 12)});
			octaves = ~octaves.choose;
			midi_notes = chord_notes.collect({|note| note + (12*[octaves, octaves-1].choose) });
			if (~previous_chord.isNil) {
				result = midi_notes.debug("new chord");
				~previous_chord = midi_notes.copy();
			} {
				var new_notes = ~voicelead.(~previous_chord, midi_notes);
				result = new_notes;
				~previous_chord = new_notes.copy().debug("new chord");
			};
			~previous_tonal_function = ~tonal_function;
			~tonal_function = ~markov2d.getnext(~tonal_function);
		};
		result
	}),
	\dur, 1000,
	\amp, Pbrown(0.1, 0.3, 0.1)
)};

~command_sequence_recognizer.register_sequence([\bottom_left_quadrant, \bottom_right_quadrant], {
	~music_patterns[\pat_bell].play;
});

~command_sequence_recognizer.register_sequence([\bottom_left_corner, \vertical_middle], {
	var events;
	if (~chord_player.notNil) {
		~chord_player.stop;
		16.do {
			|ch|
			~midiout.allNotesOff(ch);
		};
	};
	~chord_player = Ppar([~music_patterns[\bass].(), ~music_patterns[\chords].()], inf).play;
});

~command_sequence_recognizer.register_sequence([\bottom_left_corner, \wide_right], {
	~music_patterns[\pat_brass].play;
});

~command_sequence_recognizer.register_sequence([\1], {
	"trigger full stop".postln;
	if (~chord_player.notNil) {
		~chord_player.stop;
		16.do {
			|ch|
			~midiout.allNotesOff(ch);
		};
		~tonal_function = 1;
	};
});

~command_sequence_recognizer.register_sequence([\5], {
	"flip bass on/off".postln;
	~mute[\bass] = 1 - ~mute[\bass];
});

fork {
	2.wait;
	while (true) {
		~pattern_detector.add_state(~sensormodel, ~calibration);
		0.1.wait;
	};
};

w=Window.new;
v=UserView(w, w.view.bounds.insetBy(50,50));
v.resize = 5;
v.background_(Color.gray(0.8));
v.animate_(true);
v.drawFunc= ~sensormodel[\drawFunc];
v.mouseDownAction={v.refresh};
w.layout_(VLayout(
	HLayout(v),
	HLayout(~calibration[\fastcalbutton], ~calibration[\calbutton]),
	HLayout(~calibration[\status], ~calibration[\nextbutton])));
w.front;

CmdPeriod.doOnce {
	~communication[\port].doneAction = { "Serial communication closed.".postln; };
	~communication[\port].close;
	Window.closeAll;
	OSCdef.freeAll;
	Server.killAll;
	16.do {
		|ch|
		~midiout.allNotesOff(ch);
	};
};
);
