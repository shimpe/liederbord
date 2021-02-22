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
		\amp, Pseq([1.0], 5),
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
		sig = 0.3*Splay.ar(Limiter.ar(Greyhole.ar(sig + sig2, sig, 0.5, sig), 0.5).flatten);
	}).play;

	SynthDef(\fatsaw, {
		| out=0, freq = 440, amp=0.1, ampmult=1, gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1, filterSpeed=100, filterFreqStart=300, filterFreqEnd=400, resonance=1, hfFilterFreq=1, hfFilterResonance=1 |
		var sig, env, filtFreq;
		env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, levelScale:0.5, doneAction:Done.freeSelf);
		sig = env*Splay.ar(LFSaw.ar(freq*[0.98,0.99,1.0,1.01,1.02],[LFNoise0.kr(2), LFNoise0.kr(1.9), LFNoise0.kr(2.1)]) + SinOsc.ar(freq*[0.98,0.99,1.0,1.01,1.02],[LFNoise0.kr(2), LFNoise0.kr(1.9), LFNoise0.kr(2.1)]));
		filtFreq = LFSaw.kr(filterSpeed,iphase:1).range(filterFreqStart,filterFreqEnd);
		sig = RLPF.ar(sig, filtFreq, resonance);
		sig = RHPF.ar(sig, hfFilterFreq, hfFilterResonance);
		2.do({
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
				var ampmult = minval.linlin(0,threshold,0.5,10);
				var freq = minval.linexp(0,threshold,220,220*([minrow,mincol].max + 1));
				self.synths.do { |snt| snt.set(\gate, 0); };
				self.synths = [];
				self.synths = self.synths.add(Synth(\fatsaw, [\ampmult, ampmult, \freq, freq, \filterFreqStart, 50*(minrow+1), \filterFreqEnd, 1000*(mincol+1)]));
			} {
				var ampmult = 0;
				self.synths.do { |synth | synth.set(\gate, 0); };
				self.synths = [];
			};
		};

	}).play;

};

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