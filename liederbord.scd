(
var drones;
var max_value = 900; // to be calibrated
var uppermargin = 20;
var lowermargin = 0;

~current_tonal_function = 1;
~next_tonal_function = 1;
~previous_chord = nil;
~octaves = [4,5,6];
~current_scale = Scale.aeolian;
~chord_type = nil;
~mute = (\bass:1, \chords:0, \drums:1);


if (MIDIClient.initialized.not) { MIDIClient.init; };
~midiout = MIDIOut.newByName("INTEGRA-7", "INTEGRA-7 MIDI 1");

~pattern_detector = Require("patterndetector.scd");
~sensormodel = Require("sensormodel.scd");
~communication = Require("communication.scd");
~calibration = Require("calibration.scd");
~calibration[\file_location] = "/home/shimpe/development/music/liederbord/calibration.archive";
~calibration.load;

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

~supported_chord_types_basic = [[0, 2, 4], [0, 2, 4, 6]];
~supported_chord_types_all = ~supported_chord_types_basic ++ [[0, 1, 2, 4], [0, 3, 4], [0, 3, 4, 6], [0, 3, 4, 5.1]];
~supported_chord_types = ~supported_chord_types_all;

~current_scene = \scene2;

~music_patterns = ();
~music_patterns[\scenes] = ()
~music_patterns[\scenes][\scene1] = ()
~music_patterns[\scenes][\scene2] = ()
~music_patterns[\scenes][\scene1][\pat_bell] = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 0,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\degree, Pn(Plazy {
		Prand( ~supported_chord_types.choose + (~current_tonal_function-1), 1)
	}, inf),
	\ctranspose, Prand([0, 12, 24, 36], inf),
	\amp, Pwhite(0.5, 0.9, inf),
	\dur, Pseq([0.1], 40.rrand(80))
);


~music_patterns[\scenes][\scene1][\pat_brass] = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 2,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\degree, Pn(Plazy { Prand(~supported_chord_types + (~current_tonal_function - 1), 1) }, inf),
	\ctranspose, Prand([0, 12], inf),
	\amp, Pwhite(0.4, 0.6, inf),
	\dur, Plazy { Prand([1, 2, 4], 6.rrand(12)) },
	\strum, Prand([0, 0.1, 0.2], inf),
);

~voicelead = Require("voicelead.scd");

~drum_pattern_gen = Require("drumcomputer.scd");

~current_drum_preset = \bossanova;

~music_patterns[\scenes][\scene1][\drums] = {
	var composite;
	composite = Pbindf(Ppar(~drum_presets[~current_drum_preset].collect({|el|
		~drum_pattern_gen.(
			pattern: el[0],
			instrument: el[1],
			midiout: ~midiout,
			repeat: inf,
			division: el[2],
			midichannel: 9,
			amplitudeerrors:0.1,
			timingerrors: 0.01,
			percmap: ~percmap);
	})), \midinote, Pfunc({|ev| if (~mute[\drums] == 1) {Rest(1)} { ev[\midinote]; }; }));
};

~music_patterns[\scenes][\scene1][\bass] = {Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\chan, 3,
	\midiout, ~midiout,
	\scale, Pfunc { ~current_scale },
	\degree, Pfunc {
		if (~mute[\bass] == 1) {
			Rest(1);
		} {
			(~current_tonal_function - 1);
		}
	},
	[\octave, \dur], Prout {
		loop {
			var oct_dur = Pwrand([
				[[3,4], [0.25, 0.25]],
				[[3,4,4], [0.25,0.125,0.125]],
				[[3,4,3], [0.125,0.25,0.125]],
			],
			[
				3,
				1,
				0.25,
			].normalizeSum,
			1).asStream.next;
			oct_dur[0].size.do {
				|idx|
				[oct_dur[0][idx], oct_dur[1][idx]].yield;
			};
		};
	},
	\amp, Pseq([0.7], inf),
)};

~music_patterns[\scenes][\scene1][\chords] = {Pbind(
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
			chord_degrees = (~chord_type + (~next_tonal_function.debug("new tonal function") - 1));
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
			~current_tonal_function = ~next_tonal_function;
			~next_tonal_function = ~markov2d.getnext(~next_tonal_function);
			~supported_chord_types = ~supported_chord_types_all;
		};
		result
	}),
	\strum, Pwrand([0, 1], [1, 1].normalizeSum, inf),
	\dur, 1000,
	\amp, Pbrown(0.7, 0.9, 0.1)
)};


~command_sequence_recognizer.register_sequence([\bottom_left_quadrant, \bottom_right_quadrant], {
	if (~music_patterns[\scenes][~current_scene][\pat_bell].notNil) {
		~music_patterns[\scenes][~current_scene][\pat_bell].play;
	};
});

~command_sequence_recognizer.register_sequence([\bottom_left_corner, \bottom_left_quadrant], {
	if (~chord_player.notNil) {
		~chord_player.stop;
		16.do {
			|ch|
			~midiout.allNotesOff(ch);
		};
	};
	if (~music_patterns[\scenes][~current_scene][\bass].notNil) {
		~chord_player = Ppar([
			~music_patterns[\scenes][~current_scene][\bass].(),
			~music_patterns[\scenes][~current_scene][\chords].(),
			~music_patterns[\scenes][~current_scene][\drums].()
		], inf).play;
	};
});

~command_sequence_recognizer.register_sequence([\bottom_left_quadrant, \wide_right], {
	if (~music_patterns[\scenes][~current_scene][\pat_brass].notNil) {
		~music_patterns[\scenes][~current_scene][\pat_brass].play;
	};
});

~command_sequence_recognizer.register_sequence([\4], {
	"trigger full stop".postln;
	if (~chord_player.notNil) {
		~chord_player.stop;
		16.do {
			|ch|
			~midiout.allNotesOff(ch);
		};
		~next_tonal_function = 1;
	};
});

~command_sequence_recognizer.register_sequence([\8], {
	~mute[\bass] = 1 - ~mute[\bass];
	("set mute bass to" + ~mute[\bass]).postln;
});

~command_sequence_recognizer.register_sequence([\12], {
	~mute[\drums] = 1 - ~mute[\drums];
	("set mute drums to" + ~mute[\drums]).postln;
});

~command_sequence_recognizer.register_sequence([\bottom_left_corner, \13, \14], {
	~current_drum_preset = ~drum_presets.keys.choose;
	("set drum preset to" + ~current_drum_preset.asString).postln;
});

~command_sequence_recognizer.register_sequence([\16, \16], {
	("force next tonal function to 1").postln;
	if (~chord_player.notNil) {
		~chord_player.stop;
		16.do {
			|ch|
			~midiout.allNotesOff(ch);
		};
	};
	~next_tonal_function = 1;
	~supported_chord_types = ~supported_chord_types_basic;
	if (~music_patterns[\scenes][~current_scene][\bass].notNil) {
		~chord_player = Ppar([
			~music_patterns[\scenes][~current_scene][\bass].(),
			~music_patterns[\scenes][~current_scene][\chords].(),
			~music_patterns[\scenes][~current_scene][\drums].()
		], inf).play;
	};
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
