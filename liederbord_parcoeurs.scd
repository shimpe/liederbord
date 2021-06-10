(
var drones;
var max_value = 900; // to be calibrated
var uppermargin = 20;
var lowermargin = 0;

if (MIDIClient.initialized.not) { MIDIClient.init; };
~midiout = MIDIOut.newByName("INTEGRA-7", "INTEGRA-7 MIDI 1");

~pattern_detector = Require("patterndetector.scd");
~sensormodel = Require("sensormodel.scd");
~communication = Require("communication.scd");
~calibration = Require("calibration.scd");
~calibration[\file_location] = "/home/shimpe/development/music/liederbord/calibration.archive";
~calibration.load;

/* initialize the system */
~sensormodel.setDefaults(~calibration);
~communication.startSerialPortThread(
	[
		//[~communication[\internal], ~communication[\debug_callback]],
		[~communication[\internal], ~communication[\send_supercollider]],
		//	[~communication[\godot], ~communication[\send_godot]]
	]
);

~command_sequence_recognizer = Require("commandsequencerecognizer.scd");
~music_patterns = Require("musicpatterns.scd");
~scene_switcher = Require("sceneswitcher.scd");

fork {
	2.wait;
	while (true) {
		~pattern_detector.add_state(~sensormodel, ~calibration);
		0.1.wait;
	};
};

s.options.memSize_(16384*10);
s.reboot;
s.waitForBoot {
	fork {
		// \freejazz, \lockdown, \beeps, \balance, \percussionist,
		//~scene_switcher.switch_to(\balance);
		//~scene_switcher.switch_to(\beeps);
		//~scene_switcher.switch_to(\freejazz);
		~scene_switcher.switch_to(\lockdown);
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

CmdPeriod.doOnce {
	~communication[\port].doneAction = { "Serial communication closed.".postln; };
	~communication[\port].close;
	Window.closeAll;
	OSCdef.freeAll;
	Server.killAll;
	16.do {
		|ch|
		~midiout.allNotesOff(ch);
	};
};
);
