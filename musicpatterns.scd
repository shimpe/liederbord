(
~music_patterns = ();
~music_patterns[\scenes] = ();
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
~music_patterns[\scenes][\theremin] = ();
~music_patterns[\scenes][\theremin][\prepare] = {
	|self|

	self.synths = [];

	SynthDef(\oscillator, {
		| out = 0, freq = 440, amp = 0.1, pan = 0, ampmult=1, freqmult=1.0 |
		Out.ar(0, Pan2.ar(ampmult*amp*LFSaw.ar({freqmult*freq*LFNoise2.kr(2).range(-1,1)}!2), pan));
	}).add;

	s.sync;

	16.do {
		|idx|
		self.synths = self.synths.add(Synth(\oscillator, [\amp, 0.1/16, \freqmult, idx/4.0]));
	};

	Tdef(\task_theremin, {

		loop {
			16.do {
				| idx |
				var row = idx.div(4);
				var col = idx.mod(4);
				0.01.wait;
				self.synths[idx].set(\freqmult, (~sensormodel.val(idx).linlin(
					~calibration.minval(idx),
					~calibration.maxval(idx),
					3,
					0.5,
				)));
				self.synths[idx].set(\amp, ~sensormodel.val(idx).linexp(
					~calibration.minval(idx),
					~calibration.maxval(idx),
					0.4/4,
					0.1/4
				));
			};
		};
	});

	Tdef(\task_theremin_interrupt, {
		var state = 0;
		loop {

			var svals = 16.collect { |idx| ~sensormodel.val(idx); };
			var minel = svals.minItem;
			var minidx = svals.minIndex;
			var waitval = minel.linlin(
				~calibration.minval(minidx),
				~calibration.maxval(minidx),
				0.5,
				0.01).debug("waitval");

			16.do {
				| idx |
				self.synths[idx].set(\ampmult, state);
			};
			state = 1 - state; // toggle between 0 - 1

			waitval.wait;

		};
	});

	Tdef(\task_theremin).play;
	Tdef(\task_theremin_interrupt).play;
};
~music_patterns[\scenes][\theremin][\cleanup] = {
	| self |
	Tdef(\task_theremin).stop;
	Tdef(\task_theremin_interrupt).stop;
	self.synths.do{ |synth| synth.free; };
	self.synths = [];
};
~music_patterns[\scenes][\theremin][\patterns] = ();

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
~music_patterns[\scenes][\percussionist] = ();
~music_patterns[\scenes][\percussionist][\prepare] = {
	|self|
	self[\patterns][\p2].play;
};
~music_patterns[\scenes][\percussionist][\cleanup] = {
	| self |
	16.do {
		|ch|
		~midiout.allNotesOff(ch);
	};
};
~music_patterns[\scenes][\percussionist][\players] = ();
~music_patterns[\scenes][\percussionist][\gestures] = [
	(
		\name: "p1",
		\pattern: [ \bottom_left_quadrant, \bottom_right_quadrant ],
		\action: {
			"play p1".postln;
			if (~music_patterns[\scenes][\percussionist][\players][\p1].notNil) {
				~music_patterns[\scenes][\percussionist][\players][\p1].stop;
				~music_patterns[\scenes][\percussionist][\players][\p1] = nil;

			};
			~music_patterns[\scenes][\percussionist][\players][\p1] = ~music_patterns[\scenes][\percussionist][\patterns][\p1].play;
		},
	),
	(
		\name: "p2",
		\pattern: [ \wide_left, \wide_right ],
		\action: {
			"play p2".postln;
			if (~music_patterns[\scenes][\percussionist][\players][\p2].notNil) {
				~music_patterns[\scenes][\percussionist][\players][\p2].stop;
				~music_patterns[\scenes][\percussionist][\players][\p2] = nil;

			};
			~music_patterns[\scenes][\percussionist][\players][\p2] = ~music_patterns[\scenes][\percussionist][\patterns][\p2].play;
		},
	),
	(
		\name: "p3",
		\pattern : [ \wide_left, \bottom_left_corner ],
		\action: {
			"play p3".postln;
			if (~music_patterns[\scenes][\percussionist][\players][\p3].notNil) {
				~music_patterns[\scenes][\percussionist][\players][\p3].stop;
				~music_patterns[\scenes][\percussionist][\players][\p3] = nil;

			};
			~music_patterns[\scenes][\percussionist][\players][\p3] = ~music_patterns[\scenes][\percussionist][\patterns][\p3].play;
		},
	),
	(
		\name: "p4",
		\pattern : [ \wide_left, \bottom_left_corner ],
		\action: {
			"play p3".postln;
			if (~music_patterns[\scenes][\percussionist][\players][\p3].notNil) {
				~music_patterns[\scenes][\percussionist][\players][\p3].stop;
				~music_patterns[\scenes][\percussionist][\players][\p3] = nil;

			};
			~music_patterns[\scenes][\percussionist][\players][\p3] = ~music_patterns[\scenes][\percussionist][\patterns][\p3].play;
		},
	),
	(
		\name: "p4",
		\pattern : [ \wide_left, \bottom_right_corner ],
		\action: {
			"play p4".postln;
			if (~music_patterns[\scenes][\percussionist][\players][\p4].notNil) {
				~music_patterns[\scenes][\percussionist][\players][\p4].stop;
				~music_patterns[\scenes][\percussionist][\players][\p4] = nil;

			};
			~music_patterns[\scenes][\percussionist][\players][\p4] = ~music_patterns[\scenes][\percussionist][\patterns][\p4].play;
		},
	),
	(
		\name: "p5",
		\pattern : [ \wide_right, \bottom_left_quadrant ],
		\action: {
			"play p5".postln;
			if (~music_patterns[\scenes][\percussionist][\players][\p5].notNil) {
				~music_patterns[\scenes][\percussionist][\players][\p5].stop;
				~music_patterns[\scenes][\percussionist][\players][\p5] = nil;

			};
			~music_patterns[\scenes][\percussionist][\players][\p5] = ~music_patterns[\scenes][\percussionist][\patterns][\p5].play;
		},
	),
];
~music_patterns[\scenes][\percussionist][\patterns] = (
	\p1 : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\chan, 9,
		\midiout, ~midiout,
		\midinote, Pwhite(27,87,20),
		\amp, Pbrown(0.5, 0.7, 0.05, inf),
		\dur, Prand([0.125, 0.25, 0.5], inf),
	),
	\p2 : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\chan, 9,
	    \midiout, ~midiout,
		\midinote, Pwhite(60,71,20),
		\amp, Pbrown(0.2, 0.5, 0.1, inf),
		\dur, Prand([0.125, 0.25, 0.5], inf),
	),
	\p3 : Pbind(
		\type, \midi,
		\chan, 9,
	    \midiout, ~midiout,
		\midinote, Pwhite(27,87,40),
		\amp, Pbrown(0.6, 0.9, 0.1, inf),
		\dur, Pgeom(0.0676379, 0.95.reciprocal, inf),
	),
	\p4 : Pbind(
		\type, \midi,
		\chan, 9,
		\midiout, ~midiout,
		\midinote, Pxrand([60, 61, 62, 63], inf),
		\amp, Pbrown(0.6, 0.9, 0.1, inf),
		\dur, Pseq([0.1, 0.05], 75),
	),
	\p5 : Pbind(
		\type, \midi,
		\chan, 9,
		\midiout, ~midiout,
		\midinote, Pxrand([76,77,78,79,80,81], inf),
		\amp, Pbrown(0.6, 0.9, 0.1, inf),
		\dur, Pseq([Pgeom(0.5, 0.95, 40), Pgeom(0.067637977139528, 0.95.reciprocal, 40)], 1)
	)
);
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

~music_patterns[\scenes][\freejazz] = ();
~music_patterns[\scenes][\freejazz][\prepare] = {
	|self|
};
~music_patterns[\scenes][\freejazz][\players] = ();
~music_patterns[\scenes][\freejazz][\gestures] = [
	(
		\name: "slow piano",
		\pattern: [ \bottom_left_quadrant, \bottom_right_quadrant ],
		\action: {
			"toggle slowpiano".postln;
			if (~music_patterns[\scenes][\freejazz][\players][\slowpiano].notNil) {
				~music_patterns[\scenes][\freejazz][\players][\slowpiano].stop;
				~music_patterns[\scenes][\freejazz][\players][\slowpiano] = nil;

			} {
				~music_patterns[\scenes][\freejazz][\players][\slowpiano] = ~music_patterns[\scenes][\freejazz][\patterns][\slowpiano].play;
			};
		},
	),
	(
		\name: "fast piano",
		\pattern: [ \wide_left, \wide_right ],
		\action: {
			"toggle fastpiano".postln;
			if (~music_patterns[\scenes][\freejazz][\players][\fastpiano].notNil) {
				~music_patterns[\scenes][\freejazz][\players][\fastpiano].stop;
				~music_patterns[\scenes][\freejazz][\players][\fastpiano] = nil;

			} {
				~music_patterns[\scenes][\freejazz][\players][\fastpiano] = ~music_patterns[\scenes][\freejazz][\patterns][\fastpiano].play;
			};
		},
	),
	(
		\name: "strings",
		\pattern: [ \wide_left, \bottom_left_corner ],
		\action : {
			"toggle strings".postln;
			if (~music_patterns[\scenes][\freejazz][\players][\strings].notNil) {
				~music_patterns[\scenes][\freejazz][\players][\strings].stop;
				~music_patterns[\scenes][\freejazz][\players][\strings] = nil;

			} {
				~music_patterns[\scenes][\freejazz][\players][\strings] = ~music_patterns[\scenes][\freejazz][\patterns][\strings].play;
			};
		},
	),
	(
		\name : "brass",
		\pattern: [ \wide_left, \bottom_right_corner],
		\action : {
			"toggle brass".postln;
			if (~music_patterns[\scenes][\freejazz][\players][\brass].notNil) {
				~music_patterns[\scenes][\freejazz][\players][\brass].stop;
				~music_patterns[\scenes][\freejazz][\players][\brass] = nil;

			} {
				~music_patterns[\scenes][\freejazz][\players][\brass] = ~music_patterns[\scenes][\freejazz][\patterns][\brass].play;
			};
		},
	),
	(
		\name : "percussion",
		\pattern: [ \wide_right, \bottom_left_quadrant],
		\action : {
			"toggle percussion".postln;
			if (~music_patterns[\scenes][\freejazz][\players][\percussion].notNil) {
				~music_patterns[\scenes][\freejazz][\players][\percussion].stop;
				~music_patterns[\scenes][\freejazz][\players][\percussion] = nil;

			} {
				~music_patterns[\scenes][\freejazz][\players][\percussion] = ~music_patterns[\scenes][\freejazz][\patterns][\percussion].play;
			};
		},
	),
	(
		\name: "stop all",
		\pattern: [ \13, \16],
		\action : {
			"toggle stop all".postln;
			~music_patterns[\scenes][\freejazz][\players].do ({
				| player |
				player.stop;
			});
			~music_patterns[\scenes][\freejazz][\players] = ();
			~music_patterns[\scenes][\freejazz][\patterns][\gong].play;
		};
	)
];

~music_patterns[\scenes][\freejazz][\cleanup] = {
	| self |
	~music_patterns[\scenes][\freejazz][\players].do ({
		| player |
		player.stop;
	});
	~music_patterns[\scenes][\freejazz][\players] = ();
	16.do {
		|ch|
		~midiout.allNotesOff(ch);
	};
};

~music_patterns[\scenes][\freejazz][\patterns] = (
	\slowpiano : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~midiout,
		\chan, 0,
		\midinote, Prand([
			Pwhite(20, 30, 2),
			Pwhite(30, 60, 3),
			Pwhite(80, 95, 4),
			Rest(1),
			Pfunc{ 0.7.coin.if { var note = 50.rrand(60); [note, note+12] } { nil }; }
		], inf),
		\dur, Prand([1.0, 0.5, 0.25, 0.125], inf),
		\amp, Pbrown(0.4, 0.9, 0.05, inf),
	),

	\fastpiano : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~midiout,
		\chan, 0,
		\midinote, Pn(
			Prand([
				Pbrown(20, 80, 4.rrand(1), 30.rrand(10)),
				Pseq([Rest(1)], 1)], 1), inf),
		\dur, Prand([0.25, 0.125], inf),
		\amp, Pbrown(0.4, 0.9, 0.05, inf),
		\legato, Pn(Pbrown(0.2, 1.0, 0.05, 20), inf)
	),

	\strings : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~midiout,
		\chan, 1,
		\midinote, Pn(Pgbrown(60, 75, 0.3, 3.rrand(6)), inf),
		\dur, Pseq([
			Pseq([0.25, 0.5, 0.25], 2),
			Pwrand([1, 0.5, 2, 4], [1,1,1,0.2].normalizeSum, 4.rrand(1))], inf),
		\amp, Pn(Pbrown(0.5, 0.8, 0.05, 5), inf)
	),

	\brass : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~midiout,
		\chan, 2,
		\midinote, Pbrown(60, 80, 5, inf),
		\dur, Prand([0.25, 0.125, 2], inf),
		\amp, Pn(Pbrown(0.6, 0.9, 0.05, 7), inf)
	),

	\percussion : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~midiout,
		\chan, 9,
		\midinote, Pwhite(32, 60, inf),
		\dur, Pwrand([
			Pseq(0.125!8),
			Pseq(0.125!4 ++ [0.5]),
			Pseq([0.5] ++ (0.25!2))],
		[1, 3, 10].normalizeSum, inf),
		\amp, Pwhite(0.5, 0.7, inf)
	),

	\gong : Pbind(
		\type, \midi,
		\midicmd, \noteOn,
		\midiout, ~midiout,
		\chan, 9,
		\midinote, Pseq([55], inf),
		\dur, Pseq([1], inf),
		\amp, Pseq([1.0], 1),
	)
);

~music_patterns[\scenes][\lockdown] = ();
~music_patterns[\scenes][\lockdown][\prepare] = {
	| self |

	Ndef(\bits, {
		var t = PulseCount.ar(Impulse.ar(8e3));
		var u = PulseCount.ar(Impulse.ar(7009));
		var sig = HPF.ar(
			(
				((t * 15) & (t >> 5)) |
				((t * 5) & (t >> [3, 4])) |
				((t * 2) & (t >> 9)) |
				((t * 8) & (t >> 11)) |
				(((t*t) & t) | (t >> 3))
				- 3 % 256
			) / 127-1 * 3
			, 20
		) * 0.1;
		var sig2 = LPF.ar(HPF.ar(gcd(t*u, u+t), WhiteNoise.ar()*2000 + 1000), 20);
		sig2 = sig2*sig;
		sig = 0.6*LeakDC.ar(Splay.ar(Limiter.ar(Greyhole.ar(sig + sig2, sig, 0.5, sig), 0.5).flatten));
	});

	Ndef(\bits).fadeTime_(2.0);

	SynthDef(\fatsaw, {
		| out=0, freq = 440, octave=1, amp=0.1, ampmult=1, gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1, filterSpeed=100, filterFreqStart=300, filterFreqEnd=400, resonance=1 |
		var sig, env, filtFreq;
		env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, levelScale:0.5, doneAction:Done.freeSelf);
		sig = env*Splay.ar(LFSaw.ar(VarLag.kr(freq, 5)*octave*[0.98,0.99,1.0,1.01,1.02],[LFNoise0.kr(2), LFNoise0.kr(1.9), LFNoise0.kr(2.1)]) + SinOsc.ar(freq*[0.98,0.99,1.0,1.01,1.02],[LFNoise0.kr(2), LFNoise0.kr(1.9), LFNoise0.kr(2.1)]));
		filtFreq = LFSaw.kr(filterSpeed,iphase:1).range(filterFreqStart,filterFreqEnd);
		sig = RLPF.ar(sig, filtFreq, resonance);
		4.do({
			sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], 1);
		});
		Out.ar(out, ampmult*amp*sig.tanh);
	}).add;

	s.sync;

	Tdef(\lockdown_react, {
		self.synths = [];
		loop {
			var allvals = 16.collect {
				| idx |
				var row = idx.div(4);
				var col = idx.mod(4);
				(
					\val: ~sensormodel.val(idx).linlin(~calibration.minval(idx),~calibration.maxval(idx),0,1),
					\row: row,
					\col: col
				)
			};
			var minvalidx = allvals.minIndex({|el| el[\val]; });
			var minval = allvals[minvalidx][\val];
			var minrow = allvals[minvalidx][\row];
			var mincol = allvals[minvalidx][\col];
			var threshold = 0.8;
			//("minrow: " + minrow + "mincol:" + mincol + "minval:" + minval).postln;
			0.1.wait;
			if (minval < threshold) {
				var ampmult = minval.linlin(0,threshold,1,0.5);
				var freq = minval.linexp(0,threshold,220,220*([minrow,mincol].max + 1));
				var octave = (mincol+1).asInteger;
				self.synths.do { |snt| snt.set(\gate, 0); };
				self.synths = [];
				self.synths = self.synths.add(Synth(\fatsaw, [\amp, 1, \octave, octave, \ampmult, ampmult, \freq, freq, \filterFreqStart, 50*(minrow+1), \filterFreqEnd, 2000*(mincol+1)]));
			} {
				var ampmult = 0;
				self.synths.do { |synth | synth.set(\gate, 0); };
				self.synths = [];
			};
		};

	}).play;

};
~music_patterns[\scenes][\lockdown][\players] = ();
~music_patterns[\scenes][\lockdown][\gestures] = [
	(
		\name: "stop all",
		\pattern: [\13, \16],
		\action: {
			"toggle on off".postln;
			if (~music_patterns[\scenes][\lockdown][\players][\eightbit].notNil) {
				Ndef(\bits).stop(fadeTime:10.0);
				~music_patterns[\scenes][\lockdown][\players][\eightbit] = nil;

			} {
				Ndef(\bits).play(fadeTime:4.0);
				~music_patterns[\scenes][\lockdown][\players][\eightbit] = 1;
			};
		}
	),
];

~music_patterns[\scenes][\lockdown][\cleanup] = {
	| self |

	Ndef(\bits).stop;
	Tdef(\lockdown_react).stop;

	self.synths.do {
		| synth |
		synth.free;
	};

	self.synths = [];
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
~music_patterns[\scenes][\beeps] = ();
~music_patterns[\scenes][\beeps][\prepare] = {
	| self |

	var scale, buffer;

	SynthDef(\beep, {
		var sig, env;
		sig = SinOsc.ar(\freq.ir(1000));
		env = Env(
			[0,1,1,0],
			[\atk.ir(0), \sus.ir(0.03), \rel.ir(0)],
			[\atkcrv.ir(2), 0, \relcrv.ir(-2)]
		).ar(2);
		sig = sig * env;
		sig = Pan2.ar(sig, \pan.ir(0), \amp.ir(0.3));
		Out.ar(\out.ir(0), sig);
		Out.ar(\outfx.ir(0), sig * \send.ir(-30).dbamp);
	}).add;

	s.sync;

	SynthDef(\drone, {
		| out=0,freq=440, dur=1, amp=0.1, pan=0, width=0 |
		var env = EnvGen.kr(Env.new([0, 1, 1, 0], [1.0, dur, 1.0]), doneAction:Done.freeSelf);
		var sig = Array.fill(20, {
			var multiplier = [
				0.99, 1, 1.01,
				1.99, 2, 2.01,
				3.99, 4, 4.01].choose;
			var ampmult = multiplier.reciprocal;
			RLPF.ar(
				in: LFSaw.ar(
					freq:LFNoise1.kr(0.5.rrand(1.0)).range(freq*(1-width), freq*(1+width))*multiplier,
					iphase:0.0.rrand(2pi)),
				rq: LFNoise1.kr(0.5).range(0.2,0.6),
				mul:LFNoise0.kr(2.0).range(16.reciprocal, ampmult));
		});
		var finalsig = Splay.ar(env*sig);
		var finalsig_panned = Balance2.ar(
			finalsig[0],
			finalsig[1],
			pan*SinOsc.kr(LFNoise1.kr(1).range(0.05,0.2)));
		Out.ar(out, LeakDC.ar(amp*finalsig_panned));
	},
	metadata: (
		credit: "Stefaan Himpe",
		category: \pad,
		tags: [\pitched]
	)).add;

	s.sync;

	SynthDef(\noise, {
		| out, dur, amp, pan |
		var env = EnvGen.kr(Env.perc(1.0, dur*0.8, curve:10.neg), doneAction:Done.freeSelf);
		var sig = LPF.ar(WhiteNoise.ar()*LFPulse.kr(LFNoise1.kr(0.5).range(3,12)), LFNoise1.kr(2).range(2, 1)*4000);
		Out.ar(out, Pan2.ar(env*amp*sig, pan));
	}, metadata: (
		credit: "Stefaan Himpe",
		category: \noise,
		tags: [\unpitched]
	)).add;

	s.sync;

	SynthDef(\reverb, {
		var sig, wet;
		sig = In.ar(\in.ir(0), 2);
		sig = FreeVerb2.ar(sig[0], sig[1], mix:1, room:0.99, damp:0.99);
		sig = LPF.ar(sig, 900);
		Out.ar(\out.ir(0), sig);
	}).add;

	s.sync;

	// modal space
	// mouse x controls discrete pitch in dorian mode
	scale = FloatArray[0, 2, 3.2, 5, 7, 9, 10]; // dorian scale
	buffer = Buffer.alloc(s, scale.size,1, {|b| b.setnMsg(0, scale) });

	s.sync;

	SynthDef(\shepherd, {
		| out = 0, amp=0, note=0, overallamp=0 |
		var sig;
		sig =
		// lead tone
		(amp*SinOsc.ar(
			(
				DegreeToKey.kr(
					buffer.bufnum,
					note,		// mouse indexes into scale
					12,					// 12 notes per octave
					1,					// mul = 1
					72					// offset by 72 notes
				)
				+ LFNoise1.kr([3,3], 0.04)	// add some low freq stereo detuning
			).midicps,						// convert midi notes to hertz
			0,
			0.1))

		// drone 5ths
		+ (0.1*RLPF.ar(LFPulse.ar([48,55].midicps, 0.15),
			SinOsc.kr(0.1, 0, 10, 72).midicps, 0.1, 0.1));

		// add some 70's euro-space-rock echo
		sig = CombN.ar(sig, 0.31, 0.31, 2, 1, sig);
		Out.ar(out, Lag.kr(overallamp, 4.0)*sig);
	}).add;

	s.sync;

	Tdef(\update_shepherd, {
		loop {
			var svals = 16.collect { |idx| ~sensormodel.val(idx); };
			var minel = svals.minItem;
			var minidx = svals.minIndex;
			var trigger = minel.linlin(
				~calibration.minval(minidx),
				~calibration.maxval(minidx),
				1,
				0);

			if (trigger < 0.2) {
				~shepherd.set(\amp, 0);
			} {
				var note = trigger.linlin(0.2, 1, 0, 15);
				~shepherd.set(\note, note);
				~shepherd.set(\amp, 1.5);
			};

			0.1.wait;
		};
	}).stop;

	s.newBusAllocators;

	~reverbBus= Bus.audio(s, 2);
	~synthgroup = Group();
	~fxgroup = Group.after(~synthgroup);
	~reverb = Synth(\reverb, [\in, ~reverbBus], ~fxgroup);
	~freeze = nil;
	~shepherd = Synth(\shepherd, target:~synthgroup);
};

~music_patterns[\scenes][\beeps][\cleanup] = {
	|self|
	Tdef(\update_shepherd).stop;
	~music_patterns[\scenes][\beeps][\players].do ({
		| player |
		player.stop;
	});
	~reverbBus.free;
	~fxgroup.free;
	~reverbBus= nil;
	~fxgroup = nil;
	~reverb = nil;
};
~music_patterns[\scenes][\beeps][\patterns] = (
	\sonar : Pbind(
		\instrument, \beep,
		\freq, Prand([Pseq([1500, 1500, Rest()], 1), Pseq([1500,1500,1500,Rest()], 1)], inf)*Pfunc({0.25.rrand(1.0)}),
		\out, 0,
		\outfx, Pfunc { ~reverbBus },
		\send, -20,
		\rel, 0.01,
		\dur, Pseq([0.25, 0.25, 0.5], inf),
		\pan, Pwhite(-0.85,0.85,inf),
		\group, Pfunc { ~synthgroup },
	),

	\melody : Pbind(
		\instrument, \beep,
		\degree, Pseq([
			Pwrand([
				Pseq([0, 6, Rest()], 1),
				Pseq([0, 4, Rest()], 1),
				Pseq([0, 3, Rest()], 1),
				Pseq([0, 2, Rest()], 1),
				Pseq([0, 0, Rest()], 1),
			],
			[0.5,3,3,2,1].normalizeSum,
			12),
			Pseq([Rest()], 30)], inf),
		\octave, 7,
		\scale, Scale.dorian,
		\atk, Pbrown(0.0, 0.25, 0.05, inf),
		\out, 0,
		\outfx, Pfunc { ~reverbBus },
		\send, -20,
		\rel, 0.1,
		\dur, Pseq([0.25, 0.25, 0.5]*3.reciprocal, inf),
		\group, Pfunc { ~synthgroup },
	),

	\percussion : Pbind(
		\instrument, \beep,
		\freq, Pseq([Pseq([100, 150, Rest()], 4), Pseq([Rest(),Rest(),Rest()], 8)], inf),
		\atk, 0,
		\out, 0,
		\outfx, Pfunc { ~reverbBus },
		\send, 0,
		\rel, 0.01,
		\amp, 0.6,
		\dur, Pseq([0.25, 0.25, 1.0], inf)*Pfunc({[2,1].choose;}),
		\group, Pfunc { ~synthgroup },
	),

	\chords : Pbind(
		\instrument, \drone,
		\out, 0,
		\degree, Prand([[0,2,4],[0,3,4],[0,1,4]], inf),
		\octave, 6,
		\scale, Scale.dorian,
		\dur, 10.0,
		\amp, Pseq([0.1, 0.2, 0.3, 0.4, 0.5], inf),
		\group, Pfunc { ~synthgroup },
	),

	\noise : Pbind(
		\instrument, \noise,
		\degree, Pseq([0, Rest()], inf),
		\dur, Prand([5.0, 10.0, 20.0], inf),
		\amp, 0.2,
		\pan, 0,
		\out, Pwrand([0, Pfunc{ ~reverbBus } ], [1, 1].normalizeSum, inf),
		\group, Pfunc { ~synthgroup },
	),

	\final: Pbind(	\instrument, \noise,
		\degree, Pseq([0], 1),
		\dur, 40,
		\amp, 0.6,
		\pan, 0,
		\group, Pfunc { ~synthgroup },
		\out, Pfunc { ~reverbBus },
	),

);
~music_patterns[\scenes][\beeps][\players] = ();

~music_patterns[\scenes][\beeps][\gestures] = [
	(
		\name: "sonar",
		\pattern: [\bottom_left_quadrant, \bottom_right_quadrant ],
		\action: {
			if (~freeze.isNil) {
				"toggle sonar".postln;
				if (~music_patterns[\scenes][\beeps][\players][\sonar].notNil) {
					~music_patterns[\scenes][\beeps][\players][\sonar].stop;
					~music_patterns[\scenes][\beeps][\players][\sonar] = nil;

				} {
					~music_patterns[\scenes][\beeps][\patterns][\sonar].debug("pattern");
					~music_patterns[\scenes][\beeps][\players][\sonar] = ~music_patterns[\scenes][\beeps][\patterns][\sonar].play;
				};
			}
		}
	),
	(
		\name: "melody",
		\pattern: [\wide_left, \wide_right],
		\action: {
			if (~freeze.isNil) {
				"toggle melody".postln;
				if (~music_patterns[\scenes][\beeps][\players][\melody].notNil) {
					~music_patterns[\scenes][\beeps][\players][\melody].stop;
					~music_patterns[\scenes][\beeps][\players][\melody] = nil;

				} {
					~music_patterns[\scenes][\beeps][\players][\melody] = ~music_patterns[\scenes][\beeps][\patterns][\melody].play;
				};
			};
		}
	),
	(
		\name: "percussion",
		\pattern: [ \wide_left, \bottom_left_corner ],
		\action: {
			if (~freeze.isNil) {
				"toggle percussion".postln;
				if (~music_patterns[\scenes][\beeps][\players][\percussion].notNil) {
					~music_patterns[\scenes][\beeps][\players][\percussion].stop;
					~music_patterns[\scenes][\beeps][\players][\percussion] = nil;
				} {
					~music_patterns[\scenes][\beeps][\players][\percussion] = ~music_patterns[\scenes][\beeps][\patterns][\percussion].play;
				};

			};
		}
	),
	(
		\name: "chords",
		\pattern: [ \wide_left, \bottom_right_corner],
		\action: {
			if (~freeze.isNil) {
				"toggle chords".postln;
				if (~music_patterns[\scenes][\beeps][\players][\chords].notNil) {
					~music_patterns[\scenes][\beeps][\players][\chords].stop;
					~music_patterns[\scenes][\beeps][\players][\chords] = nil;
				} {
					~music_patterns[\scenes][\beeps][\players][\chords] = ~music_patterns[\scenes][\beeps][\patterns][\chords].play;
				};
			};
		}
	),
	(
		\name: "noise",
		\pattern: [\wide_right, \bottom_left_quadrant],
		\action: {
			if (~freeze.isNil) {
				"toggle noise".postln;
				if (~music_patterns[\scenes][\beeps][\players][\noise].notNil) {
					~music_patterns[\scenes][\beeps][\players][\noise].stop;
					~music_patterns[\scenes][\beeps][\players][\noise] = nil;

				} {
					~music_patterns[\scenes][\beeps][\players][\noise] = ~music_patterns[\scenes][\beeps][\patterns][\noise].play;
				};
			};
		};
	),
	(
		\name: "freeze/switch",
		\pattern: [\wide_right, \bottom_left_corner],
		\action: {
			if (~freeze.isNil) {
				"~freeze active".postln;
				~freeze = 1;
				~shepherd.set(\overallamp, 1.0);
				Tdef(\update_shepherd).play;
			} {
				"~freeze deactivated".postln;
				~freeze = nil;
				Tdef(\update_shepherd).stop;
				~shepherd.set(\overallamp, 0);
			};
		}
	),
	(
		\name: "stop all",
		\pattern: [\13, \16],
		\action: {
			"toggle stop all".postln;
			~music_patterns[\scenes][\beeps][\players].do ({
				| player |
				player.stop;
			});
			Tdef(\shepherd_update).stop;
			~shepherd.set(\overallamp, 0);
			~music_patterns[\scenes][\beeps][\players] = ();
			~music_patterns[\scenes][\beeps][\patterns][\final].play;
		};
	)
];

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

~music_patterns[\scenes][\balance] = ();
~music_patterns[\scenes][\balance][\prepare]  = {|self|
	self.buffer = Buffer.read(s, PathName(thisProcess.nowExecutingPath).pathOnly +/+ "resources" +/+ "butifthenwhy.wav");

	s.sync;

	SynthDef(\bufplayerboth, {
		/// arguments
		var out = \out.kr(0);
		var bufnum = \bufnum.kr(1);
		var pan = \pan.kr(0);
		var amp = \amp.kr(0.6);
		var rate = \rate.kr(0.8);
		var lag1 = \lag1.ar(0);
		var lag2 = \lag2.ar(0);
		/// code
		var phasor = Phasor.ar(trig:0, rate:VarLag.kr(rate,1.0)*BufRateScale.kr(bufnum), start:0.0, end:BufFrames.kr(bufnum));
		var pos1 = (phasor + VarLag.ar(lag1*SampleRate.ir, 1.0));
		var pos2 = (phasor + VarLag.ar(lag2*SampleRate.ir, 1.0));

		var monitor = PulseCount.ar(phasor >= (BufFrames.ir(bufnum)-100)).poll(label:"pulse 1");

		var bufplay = amp*(BufRd.ar(2, bufnum, pos1, loop:0.0)
			               +
			               BufRd.ar(2, bufnum, pos2, loop:0.0));

	    FreeSelf.kr(A2K.kr(monitor >= 1));

		Out.ar(out, bufplay);
	}).add;

	s.sync;

	self.synt = nil;

	Tdef(\update_synth, {
		loop {

			var lvals = [0,1,4,5,8,9,12,13].collect { |idx| ~sensormodel.val(idx); };
			var lminel = lvals.minItem;
			var lminidx = lvals.minIndex;
			var llag = lminel.linlin(
				~calibration.minval(lminidx),
				~calibration.maxval(lminidx),
				0.2.neg,
				0.2);

			var rvals = [2,3,6,7,10,11,14,15].collect { |idx| ~sensormodel.val(idx); };
			var rminel = rvals.minItem;
			var rminidx = rvals.minIndex;
			var rlag = rminel.linlin(
				~calibration.minval(rminidx),
				~calibration.maxval(rminidx),
				0.2.neg,
				0.2);
			var rate = [lminel, rminel].minItem.linlin(
				~calibration.minval(rminidx),
				~calibration.maxval(rminidx),
				1.1,
				0.9);

			if (self.synt.notNil) {
				("set synth lag1 to " ++ llag ++ "; lag2 to" + rlag ++ "; rate to " ++ rate).postln;
				self.synt.set(\lag1, llag);
				self.synt.set(\lag2, rlag);
				self.synt.set(\rate, rate);
			};
			0.1.wait;
		};
	});
};
~music_patterns[\scenes][\balance][\cleanup] = { |self|
	self.synt.free;
	self.buffer.free;
};
// needed for pattern based processors
~music_patterns[\scenes][\balance][\patterns] = ();
~music_patterns[\scenes][\balance][\synths] = nil;
~music_patterns[\scenes][\balance][\players] = ();
~music_patterns[\scenes][\balance][\gestures] = [
	(
		\name: "balance",
		\pattern: [\bottom_left_quadrant, \bottom_right_quadrant],
		\action: {
			~music_patterns[\scenes][\balance][\synths].debug("synths");
			if (~music_patterns[\scenes][\balance][\synt].isNil) {
				"start synths".postln;
				~music_patterns[\scenes][\balance][\synt] = Synth(\bufplayerboth, [\bufnum, ~music_patterns[\scenes][\balance][\buffer]]);
				Tdef(\update_synth).play;
			} {
				~music_patterns[\scenes][\balance][\synt].free;
				Tdef(\update_synth).stop;
				~music_patterns[\scenes][\balance][\synt] = nil;
			};
		};
	);
];

/*
// template for new character
// needed for raw value processors
~music_patterns[\scenes][\newcharacter] = ();
~music_patterns[\scenes][\newcharacter][\prepare]  = {|self| };
~music_patterns[\scenes][\newcharacter][\cleanup] = { |self| };
// needed for pattern based processors
~music_patterns[\scenes][\newcharacter][\patterns] = (
\patternname : Pbind(...)
);
~music_patterns[\scenes][\newcharacter][\players] = ();
~music_patterns[\scenes][\newcharacter][\gestures] = [
     (
       \name: "name",
       \pattern: [\left, \right],
       \action: {}
     )
];


*/

~music_patterns
)