(
var drones;

var max_value = 900; // to be calibrated
var uppermargin = 20;
var lowermargin = 0;

var sensormodel = ();

f = OSCFunc({
	|msg|
	var x = msg[1];
	var y = msg[2];
	var value = msg[3];
	var linindex = y*4 + x;
	sensormodel[linindex.asSymbol][\val] = value;
	//("received"+x+y+value).postln;
}, '/gui');

~communication = (
		\safeReg : {
		// adding methods to the event using safeReg will warn you if you overwrite methods
		// that already have a pre-defined meaning (like: "next").
		| self, name, implementation, verbose=0 |
		var symbolicname = name.asSymbol;
		if (self.respondsTo(symbolicname)) {
			("Error! Registering" + "\\" ++ symbolicname + "would overwrite a member that exists already.").postln;
		} {
			if (self.keys.includes(symbolicname)) {
				("Error! Cannot register" + "\\" ++ symbolicname + "twice.").postln;
			} {
				if (verbose != 0) {
					("Registered" + "\\" ++ symbolicname ++ ".").postln;
				};
				self[symbolicname] = implementation;
			};
		};
	};
);
~communication.safeReg(\debug_callback, {
	| self, netaddr, list_of_values |
	list_of_values.debug("[DEBUG] received: ");
});
~communication.safeReg(\send_supercollider, {
	| netaddr, list_of_values |
	4.do {
		| y |
		4.do {
			| x |
			var linindex = y*4 + x;
			if (list_of_values.size > linindex) {
				netaddr.sendMsg("/gui", x, y, list_of_values[linindex]);
			};
		};
	};
});
~communication.safeReg(\send_godot, {
	| netaddr, list_of_values |
	4.do {
		| y |
		4.do {
			| x |
			var linindex = y*4 + x;
			if (list_of_values.size > linindex) {
				var value = list_of_values[linindex];
				var idx = linindex.asSymbol;
				if (~communication[\drop_msg] < ~communication[\drop_godot_msg]) {
					~communication[\drop_msg] = ~communication[\drop_msg] + 1;
				}
				/*else*/
				{
					~communication[\drop_msg] = 0;
					netaddr.sendMsg("/" ++ linindex ++ "/set/color",
						x,
						y,
						linindex,
						0,
						max_value,
						value
					);
				}
			};
		};
	};
});
~communication.safeReg(\startSerialPortThread, {
	| self, list_of_netaddr_callback_pairs |
	fork {
		var values = [];
		var value_in_progress = "";
		while {true} {
			var val = ~communication[\port].read.asAscii;
			// val.debug("read");
			if (val == ~communication[\startOfSequence]) {
				// start of new list of values
				//"start new sequence".postln;
				values = [];
				value_in_progress = "";
			}
			/* else */ {
				if (val == ~communication[\endOfSequence]) {
					// end of new list of values
					//"end sequence and callback".postln;
					if (value_in_progress != "") {
						values = values.add(value_in_progress.asInteger);
					};
					list_of_netaddr_callback_pairs.do {
						|netaddr_callback|
						var netaddr = netaddr_callback[0];
						var callback = netaddr_callback[1];
						callback.(netaddr, values);
					};
					values = [];
				}
				/* else */
				{
					if (val == ~communication[\numberSeparator]) {
						//"start new number".postln;
						values = values.add(value_in_progress.asInteger);
						value_in_progress = "";
					}
					/* else */
					{
						//("append digit" + val + "to value in progress").postln;
						value_in_progress = value_in_progress ++ val;
						//("value_in_progress =" + value_in_progress).postln;
					};
				};
			};
		};
	};
});

~communication.safeReg(\internal, NetAddr("127.0.0.1", NetAddr.langPort));
~communication.safeReg(\godot, NetAddr("127.0.0.1", 4242));
~communication.safeReg(\startOfSequence, $@);
~communication.safeReg(\endOfSequence, $#);
~communication.safeReg(\numberSeparator, $;);
~communication.safeReg(\arduino, "/dev/ttyACM0");
~communication.safeReg(\baudrate, 9600);
~communication.safeReg(\port, SerialPort(port:~communication[\arduino], baudrate: ~communication[\baudrate], crtscts: true));
~communication.safeReg(\drop_msg, 0);
~communication.safeReg(\drop_godot_msg, 10);

~calibration = (
	\0 : (\min: 270, \max: 900),
	\1 : (\min: 270, \max: 900),
	\2 : (\min: 270, \max: 900),
	\3 : (\min: 270, \max: 900),
	\4 : (\min: 270, \max: 900),
	\5 : (\min: 270, \max: 900),
	\6 : (\min: 270, \max: 900),
	\7 : (\min: 270, \max: 900),
	\8 : (\min: 270, \max: 900),
	\9 : (\min: 270, \max: 900),
	\10 : (\min: 270, \max: 900),
	\11 : (\min: 270, \max: 900),
	\12 : (\min: 270, \max: 900),
	\13 : (\min: 270, \max: 900),
	\14 : (\min: 270, \max: 900),
	\15 : (\min: 270, \max: 900),

	\safeReg : {
		// adding methods to the event using safeReg will warn you if you overwrite methods
		// that already have a pre-defined meaning (like: "next").
		| self, name, implementation, verbose=0 |
		var symbolicname = name.asSymbol;
		if (self.respondsTo(symbolicname)) {
			("Error! Registering" + "\\" ++ symbolicname + "would overwrite a member that exists already.").postln;
		} {
			if (self.keys.includes(symbolicname)) {
				("Error! Cannot register" + "\\" ++ symbolicname + "twice.").postln;
			} {
				if (verbose != 0) {
					("Registered" + "\\" ++ symbolicname ++ ".").postln;
				};
				self[symbolicname] = implementation;
			};
		};
	};
);

~calibration.safeReg(\calbutton, Button().states_([["Slow calibrate"]]).action_({
	~calibration[\calbutton].enabled_(false);
	~calibration[\fastcalbutton].enabled_(false);
	~calibration[\nextbutton].enabled_(true);
	~calibration[\calstate] = (\idx: 0, \method: \slow);
	~calibration[\status].string_("Please close sensor 1 and press next");
	sensormodel[\0][\highlight] = \min;
	sensormodel[\0][\showcalibration] = true;
}));
~calibration.safeReg(\fastcalbutton, Button().states_([["Fast calibrate"]]).action_({
	~calibration[\calbutton].enabled_(false);
	~calibration[\fastcalbutton].enabled_(false);
	~calibration[\nextbutton].enabled_(true);
	~calibration[\calstate] = (\idx: 0, \method: \fast);
	~calibration[\status].string_("Cover ALL sensors and press next.");
	16.do {
		|idx|
		sensormodel[idx.asSymbol][\highlight] = \min;
		sensormodel[idx.asSymbol][\showcalibration] = true;
	}
});
);

~calibration.safeReg(\status, TextField());
~calibration.safeReg(\nextbutton, Button().states_([["Next"]]).action_({
	var calindex = ~calibration[\calstate][\idx];
	var buttonindex = calindex.div(2);
	var currentoperation = if (calindex % 2 == 0) { \min } { \max };
	var calmethod = ~calibration[\calstate][\method];
	var sensorvalues = [];
	if (calmethod == \slow) {
		fork {
			10.do {
				sensorvalues = sensorvalues ++ sensormodel[buttonindex.asSymbol][\val];
				0.05.wait;
			};

			if (currentoperation == \min) {
				~calibration[buttonindex.asSymbol][currentoperation] = sensorvalues[sensorvalues.minIndex];
			} {
				~calibration[buttonindex.asSymbol][currentoperation] = sensorvalues[sensorvalues.maxIndex];
			};
			sensormodel[buttonindex.asSymbol][currentoperation] = ~calibration[buttonindex.asSymbol][currentoperation];

			if (calindex == 31) {
				// last step done: reset everything
				defer {
					~calibration[\calbutton].enabled_(true);
					~calibration[\fastcalbutton].enabled_(true);
					~calibration[\nextbutton].enabled_(false);
					~calibration[\status].string_("");
				};
				~calibration[\calstate] = (\idx:0);
				sensormodel[buttonindex.asSymbol][\highlight] = \none;
				16.do {
					| idx |
					sensormodel[idx.asSymbol][\showcalibration] = false;
				};
			} {
				// go to next step and set up texts for next step
				~calibration[\calstate] = (\idx:calindex+1);
				// setup texts and states for next step
				if (currentoperation == \min) {
					defer { ~calibration[\status].string_("Please open sensor" + (buttonindex + 1) + "and press next"); };
					sensormodel[buttonindex.asSymbol][\highlight] = \max;
					sensormodel[buttonindex.asSymbol][\showcalibration] = true;
				} {
					defer { ~calibration[\status].string_("Please close sensor" + (buttonindex + 2) + "and press next"); };
					sensormodel[buttonindex.asSymbol][\highlight] = \none;
					sensormodel[(buttonindex+1).asSymbol][\highlight] = \min;
					sensormodel[(buttonindex+1).asSymbol][\showcalibration] = true;
				};
			};
		};

	} {
		// fast method
		var sensorvalues = ();
		16.do {
			|idx|
			sensorvalues[idx.asSymbol] = [];
			sensormodel[idx.asSymbol][\highlight] = if (currentoperation == \min) { \max } { \min };
		};
		fork {
			10.do {
				|meas|
				16.do {
					|sensoridx|
					sensorvalues[sensoridx.asSymbol] = sensorvalues[sensoridx.asSymbol] ++ sensormodel[sensoridx.asSymbol][\val];
				};
				0.2.wait;
			};
			16.do {
				| sensoridx |
				if (calindex == 0) {
					sensormodel[sensoridx.asSymbol][\min] = sensorvalues[sensoridx.asSymbol][sensorvalues[sensoridx.asSymbol].minIndex];
					defer {
						~calibration[\status].string_("Open ALL sensors and click next.");
					};
				} {
					sensormodel[sensoridx.asSymbol][\max] = sensorvalues[sensoridx.asSymbol][sensorvalues[sensoridx.asSymbol].maxIndex];
				};
			};
			~calibration[\calstate][\idx] = calindex + 1;
		};

		if (calindex > 0) {
			16.do {
				|idx|
				sensormodel[idx.asSymbol][\highlight] = \none;
				sensormodel[idx.asSymbol][\showcalibration] = \false;
			};
			defer {
				~calibration[\status].string_("");
				~calibration[\nextbutton].enabled_(false);
				~calibration[\calbutton].enabled_(true);
				~calibration[\fastcalbutton].enabled_(true);
				~calibration[\calstate] = (\idx:0, \method:\slow);
			};
		};
	};
}).enabled_(false));

~calibration.safeReg(\calstate, (\idx: 0));


4.do {
	|y|
	4.do {
		|x|
		var linindex = y*4 + x;
		sensormodel[linindex.asSymbol] = (\x: x, \y: y, \linindex:linindex,
			\min: ~calibration[linindex.asSymbol][\min],
			\max: ~calibration[linindex.asSymbol][\max],
			\highlight: \none,
			\showcalibration: false,
			\val:0);
	};
};

~communication.startSerialPortThread(
	[
		//	[~communication[\internal], ~communication[\debug_callback]],
		[~communication[\internal], ~communication[\send_supercollider]],
		//	[~communication[\godot], ~communication[\send_godot]]
	]
);

s.waitForBoot({
	SynthDef(\osc, {
		| out=0, freq=440, amp=0.2, pan=0, pulsefreq=1 |
		var sig = amp*LFSaw.ar(freq);
		var pulse = SinOsc.kr(pulsefreq, phase:2pi.rrand(0.0)).range(0,1);
		var panned_sig = Pan2.ar(pulse*sig, pan);
		Out.ar(out, panned_sig);
	}).add;

	s.sync;

	drones = Array.fill(16, {
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
				var sensor = sensormodel[droneidx.asSymbol];
				var freq = (droneidx + 60).midicps;
				drone.set(\pulsefreq, sensor[\val].linexp(sensor[\min], sensor[\max], 0.5, 20.0));
				drone.set(\amp, sensor[\val].linlin(sensor[\min], sensor[\max]-20, 0.5, 0.0));
			});
			0.2.wait;
		};
	};

	w=Window.new;
	v=UserView(w, w.view.bounds.insetBy(50,50));
	v.resize = 5;
	v.background_(Color.gray(0.8));
	v.animate_(true);
	v.drawFunc={|uview|
		var totalwidth = uview.bounds.width;
		var totalheight= uview.bounds.height;
		sensormodel.do({
			| sensor |
			var x = sensor[\x];
			var y = sensor[\y];
			var left = ((x*2) + 1)*totalwidth/9;
			var top = ((y*2) + 1)*totalheight/9;
			var color = Color(sensor[\val].linlin(sensor[\min], sensor[\max], 0, 1));
			var highlightcolor = if (sensor[\highlight] == \min) { Color(0, 0, 1.0); } { Color(0.5, 0.5, 1.0); };

			if (sensor[\highlight] != \none) {
				var extrawidth = (totalwidth/6) - (totalwidth/9);
				var extraheight = (totalheight/6) - (totalheight/9);
				var highlightleft = left - (extrawidth/2.0);
				var highlighttop = top - (extraheight/2.0);
				Pen.addRect(Rect(highlightleft, highlighttop, totalwidth/6, totalheight/6));
				Pen.color_(highlightcolor);
				Pen.fill;
			};

			Pen.addRect(Rect(left, top, totalwidth/9, totalheight/9));
			Pen.color_(color);
			Pen.fill;

			if (sensor[\showcalibration] == true) {
				var minimum = "" ++ sensor[\min];
				var maximum = "" ++ sensor[\max];
				Pen.color_(Color.white).stringCenteredIn(minimum ++ "\n" ++ maximum, Rect(left, top, totalwidth/9, totalheight/9));
				Pen.stroke;
			};

		});
	};
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