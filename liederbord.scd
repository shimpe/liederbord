(
var drones;

var max_value = 900; // to be calibrated
var uppermargin = 20;
var lowermargin = 0;

~pattern_detector = (
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

~pattern_detector.safeReg(\last_recognized_gesture, \none);
~pattern_detector.safeReg(\update_counter, 0);
~pattern_detector.safeReg(\error_tolerance, 5); // bigger error for all shapes results in shape \none
~pattern_detector.safeReg(\max_event_counter, 30);
~pattern_detector.safeReg(\state, (0!16)!~pattern_detector[\max_event_counter]);
~pattern_detector.safeReg(\callback, {
	| shapeerror |
	("Recognized a" + shapeerror[\shape] + "with strength" + shapeerror[\strength] + "and with error" + shapeerror[\error]).postln;
});
~pattern_detector.safeReg(\norm, {
	|self, vector |
	vector.sumsqr(0!16).sum;
});
~pattern_detector.safeReg(\normalize, {
	|self, vector |
	var norm = self.norm(vector);
	vector.collect({ | el | el /  norm });
});
~pattern_detector.safeReg(\known_shapes, (
	\left  : (\vector:  ~pattern_detector.normalize([1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0]), \mytype:\left, \myname: "left"),
	\fatleft:(\vector:  ~pattern_detector.normalize([1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0]), \mytype:\fatleft, \myname: "wide_left"),
	\right : (\vector:  ~pattern_detector.normalize([0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1]), \mytype:\right, \myname: "right"),
	\fatright:(\vector: ~pattern_detector.normalize([0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1]), \mytype:\fatright, \myname: "wide_right"),
	\top   : (\vector:  ~pattern_detector.normalize([1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0]), \mytype:\top, \myname: "top"),
	\fattop: (\vector:  ~pattern_detector.normalize([1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0]), \mytype:\fattop, \myname: "wide_top"),
	\bottom: (\vector:  ~pattern_detector.normalize([0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1]), \mytype:\bottom, \myname: "bottom"),
	\fatbottom:(\vector:~pattern_detector.normalize([0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1]), \mytype:\fatbottom, \myname: "wide_bottom"),
	\tlbr  : (\vector: ~pattern_detector.normalize([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]), \mytype:\tlbr, \myname: "topleft_to_bottomright"),
	\bottomleft_corner : (\vector: ~pattern_detector.normalize([1,0,0,0,1,0,0,0,1,0,0,0,1,1,1,1]), \mytype:\bottomleft_corner, \myname: "bottom left corner"),
	\bottomright_corner : (\vector: ~pattern_detector.normalize([0,0,0,1,0,0,0,1,0,0,0,1,1,1,1,1]), \mytype:\bottomright_corner, \myname: "bottom right corner"),
	\topleft_corner : (\vector: ~pattern_detector.normalize([1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0]), \mytype:\topleft_corner, \myname: "top left corner"),
	\topright_corner : (\vector: ~pattern_detector.normalize([1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,1]), \mytype:\topright_corner, \myname:"top right corner"),
	\topleft_quadrant : (\vector: ~pattern_detector.normalize([1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,0]), \mytype:\topleft_quadrant, \myname:"top left quadrant"),
	\topright_quadrant : (\vector: ~pattern_detector.normalize([0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0]), \mytype:\topright_quadrant, \myname:"top right quadrant"),
	\bottomleft_quadrant: (\vector: ~pattern_detector.normalize([0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0]), \mytype:\bottomleft_quadrant, \myname:"bottom left quadrant"),
	\bottomright_quadrant: (\vector: ~pattern_detector.normalize([0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1]), \mytype:\bottomright_quadrant, \myname:"bottom right quadrant"),
	\horizontal_middle: (\vector: ~pattern_detector.normalize([0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0]), \mytype:\horizontal_middle, \myname:"horizontal middle"),
	\vertical_middle: (\vector: ~pattern_detector.normalize([0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0]), \mytype:\vertical_middle, \myname:"vertical middle"),
));
~pattern_detector.safeReg(\add_state, {
	|self, sensormodel, calibration |
	var values = [];
	16.do {
		|sensoridx|
		var val = sensormodel.val(sensoridx).linlin(
			calibration.minval(sensoridx),
			calibration.maxval(sensoridx),
			1,
			0);
		values = values ++ val;
	};
	self[\state][self[\update_counter]] = values.copy();
	self[\update_counter] = self[\update_counter] + 1;
	if (self[\update_counter] >= self[\max_event_counter]) {
		self.calculate_new_gesture;
		self[\update_counter] = 0;
		self[\state] = (0!16)!~pattern_detector[\max_event_counter];
	};
});
~pattern_detector.safeReg(\calculate_new_gesture, {
	|self|
	var dc_level = self[\state].flatten.sum;
	var dc_level_over_no_of_sensors = dc_level / 16;
	var differences = (0!16)!(~pattern_detector[\max_event_counter] - 1);
	var measured_shape, shapes=[], errors=[], types=[], min_error_idx=0, min_error=1000, shape=\none;
	(~pattern_detector[\max_event_counter] - 1).do {
		| timeidx |
		var row1 = timeidx;
		var row2 = timeidx + 1;
		differences[timeidx] = (self[\state][row2] - self[\state][row1]).abs;
	};
	measured_shape = self.normalize(differences.sum);
	self[\known_shapes].do {
		|shape|
		shapes = shapes ++ [shape[\myname]];
		errors = errors ++ self.norm(shape[\vector] - measured_shape);
		types = types ++ shape[\mytype];
	};
	min_error_idx = errors.minIndex;
	min_error = errors[min_error_idx];
	if (min_error < self[\error_tolerance]) {
		var known_shapes = self[\known_shapes];
		var best_type = types[min_error_idx];
		var best_shape = known_shapes[types[min_error_idx]];
		var strength = dc_level_over_no_of_sensors*best_shape[\vector].count({|el| el!=0;}); // dc_level * #sensors involved in pattern / #total no of sensors
		self[\last_recognized_gesture] = (\shape: shapes[min_error_idx], \error: min_error, \strength:strength);
		if (self[\callback].notNil) {
			self[\callback].(self[\last_recognized_gesture]);
		};
	} {
		self[\last_recognized_gesture] = (\shape: shapes[min_error_idx], \error: min_error, \strength:0);
		//self[\last_recognized_gesture].debug("not chosen because of error");
	};
});

~sensormodel = (
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
~sensormodel.safeReg(\setVal, {
	| self, index, val |
	self[index.asSymbol][\val] = val;
});
~sensormodel.safeReg(\val, {
	| self, index |
	self[index.asSymbol][\val]
});
~sensormodel.safeReg(\setHighlight, {
	| self, index, highlight |
	self[index.asSymbol][\highlight] = highlight;
});
~sensormodel.safeReg(\highlight, {
	| self, index|
	self[index.asSymbol][\highlight];
});
~sensormodel.safeReg(\setShowcalibration, {
	| self, index, showcalibration |
	self[index.asSymbol][\showcalibration] = showcalibration;
});
~sensormodel.safeReg(\showcalibration, {
	| self, index, showcalibration |
	self[index.asSymbol][\showcalibration];
});
~sensormodel.safeReg(\registerOscListener, {
	| self, handler |
	if (self[\oschandler].isNil) {
		self[\oschandler] = handler;
	}
});
~sensormodel.safeReg(\drawFunc, {
	|uview|
	var totalwidth = uview.bounds.width;
	var totalheight= uview.bounds.height;
	16.do({
		| sensorindex |
		var sensor = ~sensormodel[sensorindex.asSymbol];
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
});
~sensormodel.safeReg(\setDefaults, {
	|self, calibration |

	4.do {
		|y|
		4.do {
			|x|
			var linindex = y*4 + x;
			self[linindex.asSymbol] = (
				\x: x,
				\y: y,
				\linindex:linindex,
				\min: calibration[linindex.asSymbol][\min],
				\max: calibration[linindex.asSymbol][\max],
				\highlight: \none,
				\showcalibration: false,
				\val:0);
		};
	};
});

~sensormodel.registerOscListener(
	OSCFunc({
		|msg|
		var x = msg[1];
		var y = msg[2];
		var value = msg[3];
		var linindex = y*4 + x;
	~sensormodel.setVal(linindex, value);
	//("received"+x+y+value).postln;
}, '/gui'));

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
~communication.safeReg(\pattern_tracker, {
	| self, netaddr, list_of_values |
	~pattern_detector.add(list_of_values);
});
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
~calibration.safeReg(\minval, {
	| self, sensoridx |
	self[sensoridx.asSymbol][\min];
});
~calibration.safeReg(\maxval, {
	| self, sensoridx |
	self[sensoridx.asSymbol][\max];
});

~calibration.safeReg(\calbutton, Button().states_([["Slow calibrate"]]).action_({
	~calibration[\calbutton].enabled_(false);
	~calibration[\fastcalbutton].enabled_(false);
	~calibration[\nextbutton].enabled_(true);
	~calibration[\calstate] = (\idx: 0, \method: \slow);
	~calibration[\status].string_("Please close sensor 1 and press next");
	~sensormodel.setHighlight(0, \min);
	~sensormodel.setShowcalibration(0, true);
}));
~calibration.safeReg(\fastcalbutton, Button().states_([["Fast calibrate"]]).action_({
	~calibration[\calbutton].enabled_(false);
	~calibration[\fastcalbutton].enabled_(false);
	~calibration[\nextbutton].enabled_(true);
	~calibration[\calstate] = (\idx: 0, \method: \fast);
	~calibration[\status].string_("Cover ALL sensors and press next.");
	16.do {
		|idx|
		~sensormodel.setHighlight(idx, \min);
		~sensormodel.setShowcalibration(idx, true);
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
				sensorvalues = sensorvalues ++ ~sensormodel.val(buttonindex);
				0.05.wait;
			};

			if (currentoperation == \min) {
				~calibration[buttonindex.asSymbol][currentoperation] = sensorvalues[sensorvalues.minIndex];
			} {
				~calibration[buttonindex.asSymbol][currentoperation] = sensorvalues[sensorvalues.maxIndex];
			};
			~sensormodel[buttonindex.asSymbol][currentoperation] = ~calibration[buttonindex.asSymbol][currentoperation];

			if (calindex == 31) {
				// last step done: reset everything
				defer {
					~calibration[\calbutton].enabled_(true);
					~calibration[\fastcalbutton].enabled_(true);
					~calibration[\nextbutton].enabled_(false);
					~calibration[\status].string_("");
				};
				~calibration[\calstate] = (\idx:0, \method:\slow);
				~sensormodel.setHighlight(buttonindex, \none);
				16.do {
					| idx |
					~sensormodel.setShowcalibration(idx, false);
				};
			} {
				// go to next step and set up texts for next step
				~calibration[\calstate] = (\idx:calindex+1,\method:\slow);
				// setup texts and states for next step
				if (currentoperation == \min) {
					defer { ~calibration[\status].string_("Please open sensor" + (buttonindex + 1) + "and press next"); };
					~sensormodel.setHighlight(buttonindex, \max);
					~sensormodel.setShowcalibration(buttonindex, true);
				} {
					defer { ~calibration[\status].string_("Please close sensor" + (buttonindex + 2) + "and press next"); };
					~sensormodel.setHighlight(buttonindex, \none);
					~sensormodel.setHighlight(buttonindex+1, \min);
					~sensormodel.setShowcalibration(buttonindex+1, true);
				};
			};
		};

	} {
		// fast method
		var sensorvalues = ();
		16.do {
			|idx|
			sensorvalues[idx.asSymbol] = [];
			~sensormodel.setHighlight(idx, if (currentoperation == \min) { \max } { \min });
		};
		fork {
			10.do {
				|meas|
				16.do {
					|sensoridx|
					sensorvalues[sensoridx.asSymbol] = sensorvalues[sensoridx.asSymbol] ++ ~sensormodel.val(sensoridx);
				};
				0.2.wait;
			};
			16.do {
				| sensoridx |
				if (calindex == 0) {
					~sensormodel[sensoridx.asSymbol][\min] = sensorvalues[sensoridx.asSymbol][sensorvalues[sensoridx.asSymbol].minIndex];
					defer {
						~calibration[\status].string_("Open ALL sensors and click next.");
					};
				} {
					~sensormodel[sensoridx.asSymbol][\max] = sensorvalues[sensoridx.asSymbol][sensorvalues[sensoridx.asSymbol].maxIndex];
				};
			};
			~calibration[\calstate][\idx] = calindex + 1;
		};

		if (calindex > 0) {
			16.do {
				|idx|
				~sensormodel.setHighlight(idx, \none);
				~sensormodel.setShowcalibration(idx, false);
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

~calibration.safeReg(\calstate, (\idx: 0, \method:\slow));

~sensormodel.setDefaults(~calibration);
~communication.startSerialPortThread(
	[
		//	[~communication[\internal], ~communication[\debug_callback]],
		[~communication[\internal], ~communication[\send_supercollider]],
		//	[~communication[\godot], ~communication[\send_godot]]
	]
);

fork {
	while(true) {
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