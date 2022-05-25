(
s.waitForBoot({
	~mapper = (
		type: \composite,
		/*! returns a list of ratios for an octave of the given equal temperment */
		tet: {|self, n| (0..(n-1)).collect({|degree| 2.pow(degree/n)})},
		/*! builds a mapper for a given set of ratios */
		new: { |self, ratios, center_f=440, center_midi=69|
			(
				type: \composite,
				center_f: center_f,
				center_midi: center_midi,
				ratios: ratios,
				npo: ratios.size,
				map: { |self, midin|
					if (midin.isNumber, {
						var relMidiIn = midin-self.center_midi;
						var size = self.ratios.size;
						var rat = self.ratios.at(relMidiIn % self.npo);
						var oct = floor(relMidiIn / self.npo);
						var freq = (2 ** oct) * self.center_f * rat;
						freq;
					}, {
						var result = List.new();
						midin.do ({ |item, i|
							result.add(self.map(item));
						});
						result;
					});
				}
			)
		}
	);

	~m = ~mapper.new(~mapper.tet(24));

	SynthDef(\harpsichord1, { arg out = 0, freq = 440, amp = 0.1, pan = 0;
		var env, snd;
		env = Env.perc(level: amp).kr(doneAction: 2);
		snd = Pulse.ar(freq, 0.25, 0.75);
		snd = snd * env;
		Out.ar(out, Pan2.ar(snd, pan));
	}).add;

	MIDIIn.connectAll;
	~notes = Array.fill(128, nil);
	MIDIdef.noteOn(\on, { |vel, num|
		~notes[num] = Synth(
			\harpsichord1,
			[\freq, ~m.map(num), \sustain, 1, \amp, vel * 0.00315]);
	});

	MIDIdef.noteOff(\off, { |val, num|
		~notes[num].set(\gate, 0);
		~notes[num] = nil;
	});

})
)

(
SynthDef(\berlinb, { arg out=0, freq = 80, amp = 0.01, pan=0, gate=1;
    var synth, env;
    env = Decay2.kr(gate, 0.05, 8, 0.0003);
    synth = RLPF.ar(
        LFPulse.ar(freq, 0, SinOsc.kr(0.12, [0, 0.5pi], 0.48, 0.5)),
        freq * SinOsc.kr(0.21, 0, 18, 20),
        0.07
    );
    #a, b = synth*env;
    DetectSilence.ar(a, 0.1, doneAction: 2);
    Out.ar(out, amp * Mix.ar(PanAz.ar(4, [a, b], [pan, pan+1])));
}).add;
)
