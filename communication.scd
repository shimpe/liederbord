(
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

/*
// commented out because not used for now
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
*/

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

~communication
)