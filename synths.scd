
/**
 * useful synths from around and about
 */
(
SynthDef(\sinegrain, { |freq = 440, amp = 0.2, sustain = 1|
    var sig, env;
	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: 2);
	sig = SinOsc.ar(freq, 0, amp) * env;
    Out.ar(0, sig ! 2);    // sig ! 2 is the same as [sig, sig]
}).add;
)

(
SynthDef(\marimba, {arg freq = 440, amp = 0.4;
	var snd, env;
	env = Env.linen(0.015, 1, 0.5, amp).kr(doneAction: 2);
	snd = BPF.ar(Saw.ar(0), freq, 0.02);
	snd = BLowShelf.ar(snd, 220, 0.81, 6);
	snd = snd * env;
	Out.ar(0, Splay.ar(snd));
}).add;
)

(
SynthDef(\harpsichord1, { arg out = 0, freq = 440, amp = 0.1, pan = 0;
    var env, snd;
	env = Env.perc(level: amp).kr(doneAction: 2);
	snd = Pulse.ar(freq, 0.25, 0.75);
	snd = snd * env;
	Out.ar(out, Pan2.ar(snd, pan));
}).add;
)

(
SynthDef(\pitchy, {arg ratio = 1, grainSize = 0.2;
	var son = SoundIn.ar;
	var result = PitchShift.ar(son, grainSize, ratio);
	Out.ar(0, result);
}).add;
)

(
SynthDef(\acid, { | out, freq = 1000, gate = 1, pan = 1, cut = 4000, rez = 0.8, amp = 1|
    Out.ar(out,
        Pan2.ar(
            RLPF.ar(
                Pulse.ar(freq, 0.05),
            cut, rez),
        pan) * EnvGen.kr(Env.linen(0.01, 1, 0.3), gate, amp, doneAction:2);
    )
}).add;
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

(
SynthDef(\blippy, { | out, freq = 440, amp = 0.1, nharms = 10, pan = 0, gate = 1 |
    var audio = Blip.ar(freq, nharms, amp);
    var env = Linen.kr(gate, doneAction: 2);
    OffsetOut.ar(out, Pan2.ar(audio, pan, env) );
}).add;
)
