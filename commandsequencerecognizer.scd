
(
Require("patterndetector.scd");

~command_sequence_recognizer = (
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
~command_sequence_recognizer.safeReg(\memory, []);
~command_sequence_recognizer.safeReg(\register_sequence, {
	| self, pattern_sequence, handler |
	var pseq = pattern_sequence.collect({|p| ~pattern_detector[\known_shapes][p]});
	var regex= pseq.collect({|pat| pat[\mychar] }).join;
	var size = regex.size;
	if (self[\memory].size < size) {
		self[\memory] = (\star ! size);
	};
	self[\command_table] = self[\command_table].add((\regex : regex, \handler: handler));
});
~command_sequence_recognizer.safeReg(\add_input, {
	|self, input |
	var memory = self[\memory];
	if (memory != []) {
		memory.removeAt(0);
	};
	memory = memory.add(~pattern_detector[\known_shapes][input][\mychar]);
	self[\command_table].do({
		| command |
		var regex = command[\regex];
		var regex_size = regex.size;
		var check = self[\memory].copy().keep(regex_size.neg).join;
		if (regex == check) {
			var handler = command[\handler];
			handler.();
		};
	});
});
~command_sequence_recognizer.safeReg(\remove_all, {
	|self|
	self[\command_table] = ();
});

~command_sequence_recognizer
)