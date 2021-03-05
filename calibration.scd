(
~calibration = (
	\table : (
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
	),
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
	self[\table][sensoridx.asSymbol][\min];
});
~calibration.safeReg(\maxval, {
	| self, sensoridx |
	self[\table][sensoridx.asSymbol][\max];
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
	~sensors.do {
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
				~calibration[\table][buttonindex.asSymbol][currentoperation] = sensorvalues[sensorvalues.minIndex];
			} {
				~calibration[\table][buttonindex.asSymbol][currentoperation] = sensorvalues[sensorvalues.maxIndex];
			};
			~sensormodel[buttonindex.asSymbol][currentoperation] = ~calibration[\table][buttonindex.asSymbol][currentoperation];

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
				~sensors.do {
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
		~sensors.do {
			|idx|
			sensorvalues[idx.asSymbol] = [];
			~sensormodel.setHighlight(idx, if (currentoperation == \min) { \max } { \min });
		};
		fork {
			10.do {
				|meas|
				~sensors.do {
					|sensoridx|
					sensorvalues[sensoridx.asSymbol] = sensorvalues[sensoridx.asSymbol] ++ ~sensormodel.val(sensoridx);
					//("meas" + meas + "sensoridx" + sensoridx + "has value" + ~sensormodel.val(sensoridx)).debug;
				};
				0.2.wait;
			};
			~sensors.do {
				| sensoridx |
				if (calindex == 0) {
					~sensormodel[sensoridx.asSymbol][\min] = sensorvalues[sensoridx.asSymbol][sensorvalues[sensoridx.asSymbol].minIndex];
					~calibration[\table][sensoridx.asSymbol][\min] = ~sensormodel[sensoridx.asSymbol][\min];
					//("at sensoridx" + sensoridx + "storing min value" + ~sensormodel[sensoridx.asSymbol][\min]).postln;
					defer {
						~calibration[\status].string_("Open ALL sensors and click next.");
					};
				} {
					~sensormodel[sensoridx.asSymbol][\max] = sensorvalues[sensoridx.asSymbol][sensorvalues[sensoridx.asSymbol].maxIndex];
					~calibration[\table][sensoridx.asSymbol][\max] = ~sensormodel[sensoridx.asSymbol][\max];
					//("at sensoridx" + sensoridx + "storing max value" + ~sensormodel[sensoridx.asSymbol][\max]).postln;
				};
			};
			~calibration[\calstate][\idx] = calindex + 1;
			~calibration.save;
		};

		if (calindex > 0) {
			~sensors.do {
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

	if (calmethod == \slow) {
		~calibration.save;
	}

}).enabled_(false));

~calibration.safeReg(\calstate, (\idx: 0, \method:\slow));
~calibration.safeReg(\load, {
	| self, fullpath=nil |
	if (fullpath.isNil) {
		fullpath = ~calibration[\file_location];
	};
	("Load calibration triggered with fullpath=" + fullpath).postln;
	if (fullpath.notNil) {
		if (File.existsCaseSensitive(fullpath).not) {
			("Calibration file" + fullpath + "not found!").postln;
		} {
			var path = PathName(fullpath);
			Archive.archiveDir_(path.pathOnly.debug("set path"));
			Archive.read(path.fileName.debug("loading"));
			Archive.global.debug("global archive");
			if (Archive.global.isNil.not) {
				~calibration[\table] = Archive.global.at(\calibration_table).copy();
				~sensors.do {
					|sensoridx|
					if (~sensormodel[sensoridx.asSymbol].isNil) {
						~sensormodel[sensoridx.asSymbol] = ();
					};
					~sensormodel[sensoridx.asSymbol][\min] = ~calibration[\table][sensoridx.asSymbol][\min];
					~sensormodel[sensoridx.asSymbol][\max] = ~calibration[\table][sensoridx.asSymbol][\max];
					//("sensor" + sensoridx + "has min" + ~sensormodel[sensoridx.asSymbol][\min] + "and max" +  ~sensormodel[sensoridx.asSymbol][\max]).postln;
				};
			};
		};
	} {
		"No path specified for loading calibration!".error;
	};
});

~calibration.safeReg(\save, {
	| self, fullpath |
	"save triggered".postln;
	if (fullpath.isNil) {
		fullpath = ~calibration[\file_location];
	};

	if (fullpath.notNil) {
		var path = PathName(fullpath);
		if (File.existsCaseSensitive(fullpath)) {
			("Overwriting existing file" + fullpath).postln;
		} {
			("File" + fullpath + "doesn't exist yet. Creating...").postln;
		};

		Archive.global.put(\calibration_table, ~calibration[\table]);
		Archive.global.debug("archive");
		Archive.archiveDir_((path.pathOnly).debug("in location"));
		Archive.write((path.fileName).debug("write"));
	} {
		"No path specified for saving calibration!".error;
	};

});

~calibration
)