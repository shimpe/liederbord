(
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
	~sensors.do({
		| sensorindex |
		var sensor = ~sensormodel[sensorindex.asSymbol];
		var x = sensor[\x];
		var y = sensor[\y];
		var left = ((x*2) + 1)*totalwidth/9;
		var top = ((y*2) + 1)*totalheight/9;
		var color = Color(sensor[\val].linlin(sensor[\min], sensor[\max], 0, 1));
		var highlightcolor = if (sensor[\highlight] == \min) {
			Color(0, 0, 1.0);
		} {
			if (sensor[\highlight] == \max) {
				Color(0.5, 0.5, 1.0);
			} {
				Color(234.0/255, 231.0/255, 58.0/255);
			};
		};

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


~sensormodel

)