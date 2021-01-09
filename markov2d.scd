(
// define a 2d markov chain (pseudo-)object
~markov2d = (
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
	},
	\storage : (
		// state to track 2nd last and last state, needed to select the next state
		\previous : nil,
		\previous_previous : nil
	);
);
~markov2d.safeReg(\setup, {
	// function called to setup the next-state table
	| self, first, second, list_of_pair_of_next_prob |
	var key = (""++first++"_"++second).asSymbol;
	if (self.storage[key].isNil) {
		var next = [];
		var prob = [];
		list_of_pair_of_next_prob.do({
			|el|
			next = next.add(el[0]);
			prob = prob.add(el[1]);
		});
		self.storage[key] = [next, prob.normalizeSum];
	};
});
~markov2d.safeReg(\getnext, {
	// selects the next state, given the previous state
	// internally, it will also track the 2nd last state and use both
	// 2nd last and last state to select the next state
	| self, previous |
	var next_prob, key, next;
	self.storage.previous_previous = self.storage.previous;
	self.storage.previous = previous;
	if (self.storage.previous.isNil) {
		next = 1;
	} {
		if (self.storage.previous_previous.isNil) {
			next = [3, 4, 5, 6].choose;
		} {
			key = (""++self.storage.previous_previous++"_"++previous).asSymbol;
			if (self.storage[key].isNil) {
				("Warning:"+key+"not found in markov table!").debug;
				[1, 2, 3, 4, 5, 6].choose;
			} {
				next_prob = self.storage[key];
				next = Pwrand(next_prob[0], next_prob[1], 1).asStream.next;
			}
		};
	};
});

// generate slightly better than random harmonic progressions using a 2nd order markov chain (initialized "by ear")
// table is defined as follows:
// setup(2nd_last tonal function, last tonal function, [ [next tonal function 1, prob1], [next2, prob2], ... ]
~markov2d.setup(1, 2, [[4, 0.5], [5, 1], [6, 0.5]]);
~markov2d.setup(1, 3, [[5, 1], [1, 1], [4, 0.7], [6, 1.5]]);
~markov2d.setup(1, 4, [[5, 1], [3, 0.5], [6, 0.5], [2, 0.4]]);
~markov2d.setup(1, 5, [[1, 1], [4, 1], [3, 0.6], [6, 0.5], [2, 0.5]]);
~markov2d.setup(1, 6, [[5, 1], [4, 1], [3, 0.6], [1, 0.5], [2, 0.5]]);
~markov2d.setup(2, 1, [[5, 1],[4,1],[6,0.5]]);
~markov2d.setup(2, 3, [[6, 1],[4,0.3],[5,0.3],[1,0.3]]);
~markov2d.setup(2, 4, [[5, 1], [1, 0.7], [3, 0.5], [6, 0.4]]);
~markov2d.setup(2, 5, [[1, 1], [3, 0.2], [6, 0.2]]);
~markov2d.setup(2, 6, [[5,1]]);
~markov2d.setup(3, 1, [[4, 1], [6, 1]]);
~markov2d.setup(3, 2, [[1, 1], [6, 1], [5, 1], [4, 1]]);
~markov2d.setup(3, 4, [[5, 1], [1, 1]]);
~markov2d.setup(3, 5, [[1, 1], [2, 0.3], [6, 0.5]]);
~markov2d.setup(3, 6, [[2, 1], [5, 1], [1, 1], [4, 1]]);
~markov2d.setup(4, 1, [[4, 1], [5, 1], [3, 1], [2, 1], [6, 0.3]]);
~markov2d.setup(4, 2, [[1, 1], [5, 1], [3, 1], [6, 1]]);
~markov2d.setup(4, 3, [[6, 1], [1, 1], [5, 1], [2, 0.3]]);
~markov2d.setup(4, 5, [[1, 2], [6, 1], [3, 0.3], [2, 0.1]]);
~markov2d.setup(4, 6, [[5, 1], [1, 1], [4, 0.5]]);
~markov2d.setup(5, 1, [[4, 1], [3, 1], [2, 1]]);
~markov2d.setup(5, 2, [[1, 1], [4, 1], [3, 1], [4, 1], [5, 1]]);
~markov2d.setup(5, 3, [[1,1]]);
~markov2d.setup(5, 4, [[1,1], [5, 0.5], [6, 1], [2,1]]);
~markov2d.setup(5, 6, [[3,1], [4,0.5], [2, 0.5], [1, 0.3]]);
~markov2d.setup(6, 1, [[3, 1], [5,1], [2, 0.3], [4, 0.3]]);
~markov2d.setup(6, 2, [[5,1], [3,1]]);
~markov2d.setup(6, 3, [[4,1], [2,1], [1,1], [5,1]]);
~markov2d.setup(6, 4, [[5,1], [2, 0.7], [1, 0.5], [3, 0.5]]);
~markov2d.setup(6, 5, [[4,1], [1,1], [2,0.3], [3,0.5]]);

~markov2d
)