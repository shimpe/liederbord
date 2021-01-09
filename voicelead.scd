(
~voicelead = {
	|from_chord_midi, to_chord_midi |
	var resulting_chord = [];
	var new_second_chord = [];
	to_chord_midi.do({
		|secondmidi |
		var distances = ();
		var extended_notes_second_chord = [secondmidi, secondmidi-12, secondmidi+12];
		var new_second_note = 0;
			var candidate_new_second_notes = Dictionary.new();
		var best_new_second_note;
		from_chord_midi.do({
			| firstmidi |
			var d = (extended_notes_second_chord - firstmidi).abs;
			var copyd = d.deepCopy();
			var min_dist = copyd.sort.first;
			var idx_of_min = d.indexOf(min_dist);
			candidate_new_second_notes[min_dist] = extended_notes_second_chord[idx_of_min];
		});
		best_new_second_note = candidate_new_second_notes.asSortedArray.first[1];
		new_second_chord = new_second_chord.add(best_new_second_note);
	});
	new_second_chord
};

)