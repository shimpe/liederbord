(
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
				};
				0.2.wait;
			};
			~sensors.do {
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
}).enabled_(false));

~calibration.safeReg(\calstate, (\idx: 0, \method:\slow));

~calibration
)