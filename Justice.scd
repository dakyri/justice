(
/**
 * a closure to simulate a class for handling the frequency mappings for various
 * intonation systems.
 */
~cJustice = (
	otoneF: { |self, freq, order=0, span=3, oct=0, harmonics = #[4, 5, 6, 7, 9, 11]|
		var frequencies;
		frequencies = List.new();
		if ((order >= 0) && (order < harmonics.size), {
			var atI, divisor;
			atI = order + span - 1;
			if (atI >= harmonics.size, {
				atI = harmonics.size - 1;
			});
			divisor = 2 ** (floor(log2(harmonics[order]))-oct);
			harmonics.do(
				{ |item, i|
					if ((i >= order) && (i <= atI), {
						frequencies.add(freq * item / divisor);
					})
				}
			);

		});
		frequencies;
	},
	utoneF: { |self, freq, order=0, span=3, oct=0, harmonics = #[4, 5, 6, 7, 9, 11]|
		var frequencies;
		frequencies = List.new();
		if ((order >= 0) && (order < harmonics.size), {
			var atI, dividend;
			atI = order + span - 1;
			if (atI >= harmonics.size, {
				atI = harmonics.size - 1;
			});
			dividend = 2 ** (floor(log2(harmonics[order]))+oct);
			harmonics.do(
				{ |item, i|
					if ((i >= order) && (i <= atI), {
						frequencies.addFirst(freq * dividend / item);
					})
				}
			);

		});
		frequencies;
	},
	otoneScaleF: { | self, freq, order=0, span=6 oct=0 |
		self.otoneF(freq, order, span, oct, #[4, 4.5, 5, 5.5, 6, 7]);
	},
	utoneScaleF: { | self, freq, order=0, span=6 oct=0 |
		self.utoneF(freq, order, span, oct, #[4, 4.5, 5, 5.5, 6, 7]);
	},
	otDiamondF: { | self, freq, ui=0, oi=0, un=1, on=1 |
		var uList = self.utoneScaleF(freq, ui, un, 0);
		var oList = List.new();
		uList.do({ |uFreq, i|
			oList.addFirst(self.otoneScaleF(uFreq, ui, un, 0));
		});
		oList;
	},
	utDiamondF: { | self, freq, oi=0, ui=0, on=1, un=1 |
		var oList = self.otoneScaleF(freq, oi, on, 0);
		var uList = List.new();
		oList.do({ |oFreq, i|
			uList.add(self.utoneScaleF(oFreq, ui, un, 0));
		});
		uList;
	},
	diaMarimbaF: { | self, freq, ui, oi |
		if (ui.isNumber && oi.isNumber, {
			var utoneH = #[11, 9, 7, 6, 5, 4];
			var otoneH = #[4, 5, 6, 7, 9, 11];
			var rat = otoneH.foldAt(oi) / utoneH.foldAt(ui);
			var range = (oi + ui) % 11;
			var oct = 1;
			case
			{range <= 1} { oct = 1; }
			{range <= 4} { oct = 2; }
			{range <= 8} { oct = 3; }
			{range <= 10} { oct = 4; }
			;
			rat*freq;
		}, {
			var result;
			case
			{not(oi.isNumber) && not(ui.isNumber)} {
				result = List.new();
				ui.do ({|itemu, i|
					oi.do ({|itemo, j|
						result.add(self.diaMarimbaF(freq, itemu, itemo));
					});
				});
			}
			{oi.isNumber} {
				result = List.new();
				ui.do ({|item, i|
					result.add(self.diaMarimbaF(freq, item, oi));
				});
			}
			{ui.isNumber} {
				result = List.new();
				oi.do ({|item, i|
					result.add(self.diaMarimbaF(freq, ui, item));
				});
			};
			result;
		});
	},
	toOctave: { | self, root, freq |
		if (freq.isNumber, {
			while ({freq < root}, {freq = freq*2});
			while ({freq >= (2 * root)}, {freq = freq/2});
			freq;
		},{
			var result = List.new();
			freq.do ({ |item, i|
				result.add(self.toOctave(root, item));
			});
			result;
		});
	},
	/**
	 * builds an object that has a mapping function between midi note and frequency
	 *  @param bf is the base frequence of the mapper
	 *  @param c the center midi note for that frequency
	 *  @param m is the map. it should span a ration between >= 1 and < 2
	 *      octaves are mapped out according to the lenght of the map
	 */
	makeMapper: {
		|self, m=#[1, 1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9], bf=1.0, c=36|
		var instance;
		var baseFreq = bf;
		var center = c;
		var map = m;
		var static = self;
		m.size.postln;
		instance = (
			map: { |self, midin|
				if (midin.isNumber, {
					var relMidiIn = midin-center;
					var rat = map.at(relMidiIn % map.size);
					var oct = floor(relMidiIn / map.size);
					var freq = (2 ** oct) * baseFreq * rat;
					freq;
				}, {
					var result = List.new();
					midin.do ({ |item, i|
						result.add(self.map(item));
					});
					result;
				});
			}
		);
		instance;
	},
	/**
	 * symmetrical, maps a symmetrical set from C in 12 note octave
	 * C7#11 and corresponding undertonality,
	 * 'tritone' at 7/5 as we have the 11 tritones in already
	 */
	makeMapperA: { | self, bf=261.625565, c=60 |
		self.makeMapper(
			[1, 9/8, 8/7, 5/4, 4/3, 11/8, 7/5, 16/11, 3/2, 8/5, 7/4, 16/9], bf, c);
	},
	/**
	 * symmetrical, maps a symmetrical set from C in 12 note octave
	 * C 7 and corresponding undertonality, 'tritone' at 7/5 as we have
	 * no 11-limit notes otherwise. add the 5/4 for G and corresponding Db to complete
	 * undertone for F
	 */
	makeMapperB: { | self, bf=261.625565, c=60 |
		self.makeMapper(
			[1, 16/15, 9/8, 8/7, 5/4, 4/3, 7/5, 3/2, 8/5, 7/4, 16/9, 15/8], bf, c);
	},
	/**
	 * very close to a straight ptolemaic just thing for chromatic. substitute the
	 * good minor 7 and short minor 4rd for a great minor 3rd and maj 6
	 */
	makeMapperC: { | self, bf=261.625565, c=60 |
		self.makeMapper(
			[1, 16/15, 9/8, 6/5, 5/4, 4/3, 7/5, 3/2, 8/5, 5/3, 16/9, 15/8], bf, c);
	},
	build: {
		|self, bf, rf=0|
		var instance, baseFreq, rootFreq, static;
		static = self;
		baseFreq = bf;
		rootFreq = if (rf == 0, bf, rf);
		instance = (
			otone: { |self, order=0, span=3, oct=0|
				static.otoneF(baseFreq, order, span, oct);
			},
			utone: { |self, order=0, span=3, oct=0|
				static.utoneF(baseFreq, order, span, oct);
			},
			otoneScale: { |self, order=0, span=3, oct=0|
				static.otoneScaleF(baseFreq, order, span, oct);
			},
			utoneScale: { |self, order=0, span=3, oct=0|
				static.utoneScaleF(baseFreq, order, span, oct);
			},
			otDiamond: { | self, ui=0, oi=0, un=1, on=1 |
				static.otDiamondF(baseFreq, ui, oi, un, on);
			},
			utDiamond: { | self, oi=0, ui=0, on=1, un=1 |
				static.utDiamondF(baseFreq, oi, ui, on, un);
			},
			diaMarimba: { | self, ui, oi |
				static.diaMarimbaF(baseFreq, ui, oi);
			},
			dom: {
				static.build(static.toOctave(rootFreq, 3*baseFreq/2), rootFreq);
			},
			sub: {
				static.build(static.toOctave(rootFreq, 4*baseFreq/3), rootFreq);
			},
			baseFrequency: {
				baseFreq
			},
			rootFrequency: {
				rootFreq
			}

		);
		instance;
	}
);
)

(
/** basic tests of cJustics */
j = ~cJustice.build(200);
j.otDiamond(1,1, 3,3).postln;
j.utDiamond(1,1, 3,3).postln;

~cJustice.toOctave(100, j.utDiamond(1,1, 3,3)).postln;
j.diaMarimba([0, [1, 2]], [5, 3]);

a = ~cJustice.makeMapperA();
b = ~cJustice.makeMapperB();
c = ~cJustice.makeMapperC();
/*
a=Pbind(
	\instrument, \sinegrain,
	\freq, Place(b.map([60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72]), inf),
	\dur, 0.4,
	\amp, Pwhite(0.1, 0.5)
).play;
*/
)

/**
 * start up
 */
(
var notes, on, off;

MIDIClient.init;
MIDIIn.connectAll;

notes = Array.newClear(128);    // array has one slot per possible MIDI note

on = MIDIFunc.noteOn({ |veloc, num, chan, src|
	notes[num] = Synth(
		\harpsichord1,
		[\freq, b.map(num), \sustain, 1, \amp, veloc * 0.00315]);
});

off = MIDIFunc.noteOff({ |veloc, num, chan, src|
    notes[num].release;
});

q = {
	"clearing ... ".postln;
	on.free;
	off.free;

};
)
b.map(53)
/**
 * some handy startup instructions
 */
q.value;
a.stop;
s.boot;
s.reboot;
s.options.device_("ASIO : ASIO4ALL v2");
s.options.device_("ASIO : Yamaha Steinberg USB ASIO");
MIDIClient.init;
MIDIClient.sources;
MIDIIn.connect(0, MIDIClient.sources.at(1));
j.diaMarimba([0, [1, 2]], [5, 3]);
j.otDiamond(1,1, 3,3)
/*********************************
 * experiments with pbind thingies
 *********************************/
(
p = Pmono(\pitchy,
	\dur, 0.2,
	\ratio, Pseq([1, 1,25, 1.5, 2, 1.8, 1.5, 2], inf) ).play;
)

x = Synth(\pitchy);
(
p = Pbind(
    \type, \set,
    \id, x.nodeID,
	\args, #[\ratio],
	\dur, 0.2,
	\ratio,  Pseq([1, 1,25, 1.5, 2, 2.5], inf)).play;
)

(
p=Pbind(
	\instrument, \harpsichord1,
	\freq, Pseq(j.diaMarimba([0, 3, 5], [0, 3, 5, 3, 0]), inf),
	\pan, Pfunc({1.0.rand2}),
	\dur, Pseq([0.2, 0.2], inf),
	\amp, Pwhite(0.1, 0.5)
).play;
)
p.stop;

(
p=Pbind(\instrument, \acid,
	\dur, Pseq([0.25, 0.5, 0.25], inf), \root, -12,
    \degree, Pseq([0, 3, 5, 7, 9, 11, 5, 1], inf),
	\pan, Pfunc({1.0.rand2}),
    \cut, Pxrand([1000, 500, 2000, 300], inf),
	\rez, Pfunc({0.7.rand +0.3}),
	\amp, 0.2).play;
)
p.stop
(
p=Pbind(\instrument, \blippy,
	\freq, Prand([1, 1.2, 2, 2.5, 3, 4], inf) * 200, \dur, 0.1).play;
)

(
a = Pfunc({ exprand(0.1, 0.3) + #[1, 2, 3, 6, 7].choose }).asStream;
{
    a.do { |val|
        Synth(\sinegrain, [\freq, val * 100 + 300]);
        0.02.wait;
    }
}.fork;
)

(
p=Pbind(
	\instrument, \marimba,
	\degree, Pseq([[1,4,7], [1, 3, 6], [1, 3, 5], [1,2,4], [1,2,3], 10, -10, 1], inf),
	\dur, 0.2,
	\amp, Pwhite(0.1, 0.5)
).play;
)
p.stop

(
var a, b, c;
a = Pseries.new(0,1,10);    // a is a pattern whose stream counts from 0 to 9
b = a.squared;            // pattern b is a square of the pattern a
c = b.asStream;
12.do({ c.next.postln; });
)

/**
 * a Duty looks like this
 */
(
{
	z = Duty.kr(0.05, 0, Dseq([0, 4, 7, 10, 12, 10, 7, 4].midiratio, inf));
	z.postln;
}.scope
)