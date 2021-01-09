(
var drones;
var max_value = 900; // to be calibrated
var uppermargin = 20;
var lowermargin = 0;

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

~music_patterns = ();
~music_patterns[\pat_bell] = Pbind(
	\instrument, \bell,
	\fs, Pwrand([Pseq( (60..72), 1).midicps, Pseq( (72..40), 1).midicps], [1, 1].normalizeSum, inf),
	\t60, Pwhite(0.5, 9),
	\pitchy, Pwhite(1,4),
	\amp, 0.1,
	\dur, Pseq([0.1], 20.rrand(50))
);
~music_patterns[\pat_sin] = Pbind(
	\instrument, \simplesin,
	\freq, Pfunc {
		var newfreq = ~freq * ~intervals.choose;
		if ((newfreq > 200) && (newfreq < 2000)) { ~freq = newfreq; };
		~freq
	},
	\len, 8,
	\dur, Pseq([1], 10)
);
~music_patterns[\pat_flute] = Pbind(
	\instrument, \flute,
	\degree, Pxrand([1,3,5,6,Rest(),Rest(),Rest()], inf),
	\octave, Prand([5,6], inf),
	\dur, Prand([1.0,2.0,4.0], 20.rrand(30)),
	\amp, Pbrown(0.15, 0.3, 0.05, inf),
	\a, Prand([0.2, 0.5, 1.0], inf),
	\r, Prand([1.0, 2.0], inf),
);


~command_sequence_recognizer.register_sequence([\bottom_left_quadrant, \bottom_right_quadrant], {
	~music_patterns[\pat_bell].play;
});
~command_sequence_recognizer.register_sequence([\top_left_quadrant, \top_right_quadrant], {
	~music_patterns[\pat_flute].play;
});
~command_sequence_recognizer.register_sequence([\left, \right, \left], {
	~music_patterns[\pat_sin].play;
});

fork {
	2.wait;
	while (true) {
		~pattern_detector.add_state(~sensormodel, ~calibration);
		0.1.wait;
	};
};

s.waitForBoot({
	SynthDef(\osc, {
		| out=0, freq=440, amp=0.2, pan=0, pulsefreq=1 |
		var sig = amp*LFSaw.ar(freq);
		var pulse = SinOsc.kr(pulsefreq, phase:2pi.rrand(0.0)).range(0,1);
		var panned_sig = Pan2.ar(pulse*sig, pan);
		Out.ar(out, panned_sig);
	}).add;

	// 1. define the synth
	SynthDef(\bell, {
		|fs=1, t60=1, pitchy=1, amp=0.25, gate=1|
		var sig, exciter;
		//exciter = Impulse.ar(0);
		exciter = WhiteNoise.ar() * EnvGen.ar(Env.perc(0.001, 0.05), gate) * 0.25;
		sig = Klank.ar(
			`[
				[1, 2, 2.803, 3.871, 5.074, 7.81, 10.948, 14.421],   // freqs
				[1, 0.044, 0.891, 0.0891, 0.794, 0.1, 0.281, 0.079], // amplitudes
				[1, 0.205, 1, 0.196, 0.339, 0.047, 0.058, 0.047]*t60     // ring times
			],
			exciter,
			freqscale:fs*pitchy);
		sig = FreeVerb.ar(sig) * amp;
		DetectSilence.ar(sig, 0.01, 0.5, doneAction:2);
		Out.ar(0, sig!2);
	}).add;

	SynthDef(\simplesin,{
		|freq=440, amp=0.02, len=8|
		var oscFreq = freq+SinOsc.ar(Rand(0.01,0.3),0,Rand(0,0));
		var env = EnvGen.ar(Env([0,1,0],[len/2,len/2]),doneAction:2);
		var out = HPF.ar(LPF.ar(Pulse.ar(oscFreq,env)*amp*env,freq+(freq*1.5*env)),freq);
		Out.ar(0,out!2);
	}).add;

	SynthDef(\flute, {
		| out = 0, freq = 440, amp = 1.0, a = 0.1, r = 0.1|
		//var fmod = 1; // clean
		//var fmod = LFCub.kr(freq:1/12).range(1, LFNoise2.kr(freq:12.0).range(1,1.1)); // tone deaf flute
		var fmod = LFCub.kr(freq:1/12).range(1, LFNoise2.kr(freq:12.0).range(1,1.02)); // flute-like sound
		var env = EnvGen.ar(Env.perc(a, r), levelScale:0.5, doneAction:2);
		var snd = SinOsc.ar(freq * fmod)!2;
		Out.ar(bus:out, channelsArray:(env*(amp*snd).tanh));
	}).add;

	s.sync;

	drones = Array.fill(~sensors, {
		|idx|
		Synth(\osc, [
			\freq, ((idx*2) + 60).midicps,
			\amp, 0.1,
			\pan, 0.7.neg.rrand(0.7),
			\pulsefreq, idx.linlin(0,15,1,2*pi) ]);
	});

	fork {
		while (true) {
			drones.do({
				|drone, droneidx|
				var sensor = ~sensormodel[droneidx.asSymbol];
				var freq = (droneidx + 60).midicps;
				drone.set(\pulsefreq, sensor[\val].linexp(sensor[\min], sensor[\max], 0.5, 20.0));
				drone.set(\amp, sensor[\val].linlin(sensor[\min], sensor[\max]-20, 0.7, 0.0));
			});
			0.2.wait;
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

});

CmdPeriod.doOnce {
		~communication[\port].doneAction = { "Serial communication closed.".postln; };
		~communication[\port].close;
		Window.closeAll;
		OSCdef.freeAll;
		drones.do({|el| el.free; });
		Server.killAll;
	};
);
