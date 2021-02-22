(
~scene_switcher = (
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

~scene_switcher.safeReg(\switch_to, {
	| self, scene |
	if (~scene_switcher[\current_scene] != scene) {
		if (~scene_switcher[\current_scene].notNil) {
			~music_patterns[\scenes][~scene_switcher[\current_scene]].cleanup;
			if (~music_patterns[\scenes][~scene_switcher[\current_scene]][\gestures].notNil) {
				~command_sequence_recognizer.remove_all;
			};
		};
		~scene_switcher[\current_scene] = scene;
		if (~music_patterns[\scenes][~scene_switcher[\current_scene]][\gestures].notNil) {
			~music_patterns[\scenes][~scene_switcher[\current_scene]][\gestures].do {
				| gesture |
				("register gesture" + gesture[\name]).postln;
				~command_sequence_recognizer.register_sequence(gesture[\pattern], gesture[\action]);
			};
		};
	};
	~music_patterns[\scenes][scene].prepare;
});

~scene_switcher

)