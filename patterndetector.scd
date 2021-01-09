(
var sns = [];

~sensors = 16;
~sensors.do {
	| sensoridx |
	// make a list of [ [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0], [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0], ..., [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]]
	// to represent a single sensor being active
	sns = sns ++ [~sensors.collect({|idx| if (idx == sensoridx) {1} {0} })];
};

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
~pattern_detector.safeReg(\sns, sns);
~pattern_detector.safeReg(\last_recognized_gesture, \none);
~pattern_detector.safeReg(\update_counter, 0);
~pattern_detector.safeReg(\error_tolerance, 5); // bigger error for all shapes results in shape \none
~pattern_detector.safeReg(\max_event_counter, 10);
~pattern_detector.safeReg(\state, (0!~sensors)!~pattern_detector[\max_event_counter]);
~pattern_detector.safeReg(\callback, {
	| shapeerror |
	~sensors.do{
		| sensoridx |
		~sensormodel.setHighlight(sensoridx, \none);
	};
	shapeerror[\raw_info][\sensors].do {
		| sensoridx |
		~sensormodel.setHighlight(sensoridx, \recognized);
	};
	if (~command_sequence_recognizer.notNil) {
		~command_sequence_recognizer.add_input(shapeerror[\mytype]);
	};
});
~pattern_detector.safeReg(\norm, {
	|self, vector |
	vector.sumsqr(0!~sensors).sum;
});
~pattern_detector.safeReg(\normalize, {
	|self, vector |
	var norm = self.norm(vector);
	vector.collect({ | el | el /  norm });
});
~pattern_detector.safeReg(\mkshape, {
	|self, list_of_sensors |
	var sum = 0!~sensors;
	list_of_sensors.do {
		|sensoridx|
		if (sensoridx >= ~sensors) {
			"ERROR! Invalid sensor index passed to mkshape!".postln;
		} {
			sum = sum + self[\sns][sensoridx];
		};
	};
	~pattern_detector.normalize(sum)
});
~pattern_detector.safeReg(\makepat, {
	|self, list_of_sensors |
	(\vector: ~pattern_detector.mkshape(list_of_sensors), \sensors: list_of_sensors.copy())
});

~pattern_detector.safeReg(\known_shapes, (
	// single-sensor patterns
	\1: ~pattern_detector.makepat([0]),
	\2: ~pattern_detector.makepat([1]),
	\3: ~pattern_detector.makepat([2]),
	\4: ~pattern_detector.makepat([3]),
	\5: ~pattern_detector.makepat([4]),
	\8: ~pattern_detector.makepat([7]),
	\9: ~pattern_detector.makepat([8]),
	\12: ~pattern_detector.makepat([11]),
	\13: ~pattern_detector.makepat([12]),
	\14: ~pattern_detector.makepat([13]),
	\15: ~pattern_detector.makepat([14]),
	\16: ~pattern_detector.makepat([15]),

	// single-sensor, but quasi unreachable
	\6 : ~pattern_detector.makepat([5]),
	\7 : ~pattern_detector.makepat([6]),
	\10: ~pattern_detector.makepat([9]),
	\11: ~pattern_detector.makepat([10]),


	// one-handed patterns
	\left  : ~pattern_detector.makepat([0,4,8,12]),
	\wide_left: ~pattern_detector.makepat([0,1,4,5,8,9,12,13]),
	\right : ~pattern_detector.makepat([3,7,11,15]),
	\wide_right: ~pattern_detector.makepat([2,3,6,7,10,11,14,15]),
	\top   : ~pattern_detector.makepat([0,1,2,3]),
	\wide_top: ~pattern_detector.makepat([0,1,2,3,4,5,6,7]),
	\bottom: ~pattern_detector.makepat([12,13,14,15]),
	\wide_bottom: ~pattern_detector.makepat([8,9,10,11,12,13,14,15]),
	\top_left_corner : ~pattern_detector.makepat([0,1,2,3,4,8,12]),
	\top_right_corner : ~pattern_detector.makepat([0,1,2,3,7,11,15]),
	\top_left_quadrant : ~pattern_detector.makepat([0,1,4,5]),
	\top_right_quadrant : ~pattern_detector.makepat([2,3,6,7]),
	\bottom_left_quadrant: ~pattern_detector.makepat([8,9,12,13]),
	\bottom_right_quadrant: ~pattern_detector.makepat([10,11,14,15]),
	\horizontal_middle: ~pattern_detector.makepat([4,5,6,7,8,9,10,11]),
	\vertical_middle: ~pattern_detector.makepat([1,2,5,6,9,10,13,14]),

	/*
	\top_left_two_horizontal: ~pattern_detector.makepat([0,1]),
	\top_left_two_vertical: ~pattern_detector.makepat([0,4]),
	\bottom_left_two_vertical: ~pattern_detector.makepat([8,12]),
	\bottom_left_two_horizontal: ~pattern_detector.makepat([12,13]),
	\bottom_right_two_horizontal: ~pattern_detector.makepat([14,15]),
	\bottom_right_two_vertical: ~pattern_detector.makepat([11,15]),
	\top_right_two_vertical: ~pattern_detector.makepat([3,7]),
	\top_right_two_horizontal: ~pattern_detector.makepat([2,3]),
	*/

	// two handed patterns
	\bottom_left_corner : ~pattern_detector.makepat([0,4,8,12,13,14,15]),
	\bottom_right_corner : ~pattern_detector.makepat([3,7,11,12,13,14,15]),
	\left_and_right_column: ~pattern_detector.makepat([0,3,4,7,8,11,12,15]),
	\top_and_bottom_row: ~pattern_detector.makepat([0,1,2,3,12,13,14,15]),
	\top_left_to_bottom_right_opposing_quadrants: ~pattern_detector.makepat([0,1,4,5,10,11,14,15]),
	\top_right_to_bottom_left_opposing_quadrants: ~pattern_detector.makepat([2,3,6,7,8,9,12,13]),
));

// augment shape definitions with some meta information
~pattern_detector[\known_shapes].keysValuesDo{
	|key, val, idx|
	// add some information
	var acceptable_symbols = ((0..25) + "a".ascii).asAscii ++ ((0..25) + "A".ascii).asAscii ++ ((0..9) + "0".ascii).asAscii;
	~pattern_detector[\known_shapes][key][\mytype] = key;
	~pattern_detector[\known_shapes][key][\myname] = key.asString.replace("_", " ");
	~pattern_detector[\known_shapes][key][\mychar] = acceptable_symbols[idx];
};

~pattern_detector.safeReg(\add_state, {
	|self, sensormodel, calibration |
	var values = [];
	~sensors.do {
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
		self[\state] = (0!~sensors)!~pattern_detector[\max_event_counter];
	};
});
~pattern_detector.safeReg(\calculate_new_gesture, {
	|self|
	var dc_level = self[\state].flatten.sum;
	var dc_level_over_no_of_sensors = dc_level / ~sensors / ~pattern_detector[\max_event_counter];
	var differences = (0!~sensors)!(~pattern_detector[\max_event_counter] - 1);
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
		self[\last_recognized_gesture] = (\shape: shapes[min_error_idx], \error: min_error, \strength:strength, \mytype: best_type, \raw_info:~pattern_detector[\known_shapes][best_type]);
		if (self[\callback].notNil) {
			self[\callback].(self[\last_recognized_gesture]);
		};
	} {
		self[\last_recognized_gesture] = (\shape: shapes[min_error_idx], \error: min_error, \strength:0, \mytype: \none);
	};
});

~pattern_detector
)