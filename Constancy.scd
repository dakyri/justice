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

	SynthDef(\harpsichord1, { arg out = 0, freq = 440, amp = 0.1, pan = 0;
		var env, snd;
		env = Env.perc(attackTime:0.01, releaseTime:1.0, level: amp).kr(doneAction: 2);
		snd = Pulse.ar(freq, 0.25, 0.75);
		snd = snd * env;
		Out.ar(out, Pan2.ar(snd, pan));
	}).add;

	MIDIIn.connectAll;
	MIDIdef.noteOn(\on, {|vel, note, chan, src|
		~constancy.note_on(vel, note, chan);
	});

	MIDIdef.noteOff(\off, {|vel, note, chan, src|
		~constancy.note_off(vel, note, chan);
	});

	~constancy = (
		type: \composite,
		play: { |self| },
		mapper: ~mapper.new(~mapper.tet(24)),
		notes: Array.fill(128, nil),
		note_on: { |self, vel, note, chan|
			var f = self.mapper.map(note);
			self.notes[note] = Synth(
				\harpsichord1,
				[\freq, f, \sustain, 1, \amp, vel * self.amp * 0.00315, \pan, self.pan]
			);
		},
		note_off: { |self, vel, note, chan|
			self.notes[note].set(\gate, 0);
			self.notes[note] = nil;
		},

		amp: 1.0,
		pan: 0.0,

		window: nil,

		build_gui: { |self|
			var win = Window("Constancy", Rect(200, 200, 500, 200));
			var font = Font("Helvetica", 14);
			var ts = nil;
			var kv = nil;
			self.window = win;
//			win.userCanClose = false;

			ts = PopUpMenu(win, Rect(10, 10, 220, 20));
			ts.items_(ServerOptions.outDevices).action_(
				{ |menu|
					menu.item.postln;
					s.options.outDevice_(menu.item);
					s.reboot;
				}
			);

			StaticText(win, Rect(250, 10, 30, 20)).string_("Amp").font = font;
			kv = Knob(win, Rect(285, 10, 30, 30)).action_(
				{ |knob|
					self.amp = knob.value;
				}
			);
			kv.value = self.amp;

			StaticText(win, Rect(330, 10, 30, 20)).string_("Pan").font = font;
			kv = Knob(win, Rect(360, 10, 30, 30)).action_(
				{ |knob|
					self.pan = (knob.value*2) - 1;
				}
			);
			kv.centered(true);
			kv.value = (self.pan+1) * 0.5;

			StaticText(win, Rect(10, 40, 80, 20)).string_("Center Note").font = font;
			kv = NumberBox(win, Rect(90, 40, 30, 20)).action_(
				{ |box|
					self.mapper.center_midi = box.value;
				}
			);
			kv.clipLo_(0).clipHi_(127).decimals_(0).step_(1);
			kv.value = self.mapper.center_midi;

			StaticText(win, Rect(135, 40, 80, 20)).string_("Center Freq").font = font;
			kv = NumberBox(win, Rect(215, 40, 50, 20)).action_(
				{ |box|
					self.mapper.center_f = box.value;
				}
			);
			kv.clipLo_(50).clipHi_(880).minDecimals_(0).maxDecimals_(2).step_(1);
			kv.value = self.mapper.center_f;

			StaticText(win, Rect(280, 40, 30, 20)).string_("TET").font = font;
			kv = NumberBox(win, Rect(310, 40, 30, 20)).action_(
				{ |box|
					self.mapper.ratios = ~mapper.tet(box.value);
				}
			);
			kv.clipLo_(6).clipHi_(48).decimals_(0).step_(1);
			kv.value = self.mapper.ratios.size;

			win.front;
		},
	);
	~constancy.build_gui();
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
ServerOptions.outDevices
ServerOptions.inDevices
ServerOptions.devices
s.options.outDevice_("MME : Speaker/HP (Realtek High Defini")
s.reboot
ServerOptions.

(
~image = Image(64, 64).draw({
    Pen.fillColor = Color.blue;
    Pen.fillOval(Rect(0, 0, 64, 64));
});

~menu = Menu(
    MenuAction("checked", { "checked".postln })
        .checked_(true),

    MenuAction("disabled", { "disabled".postln })
        .enabled_(false),

    MenuAction("keyboard short", { "keyboard short".postln })
        .shortcut_("Ctrl+Shift+N"),

    MenuAction("icon", { "icon".postln })
        .icon_(~image),

    MenuAction("font", { "font".postln })
        .font_(Font("Helvetica", 20, italic:true)),

    MenuAction.separator.string_("other stuff"),

    CustomViewAction(Slider().orientation_(\horizontal)).action_({ |v| v.value.postln }),

    Menu(
        "string.toAction",
        { "function.toAction".postln }
    ).title_("submenu")
).front;
)
(
View().layout_(HLayout(
    ~text = StaticText().string_("Right-click me").minWidth_(100)
)).front;

~text.setContextMenuActions(
    MenuAction("Red", { ~text.background = Color.red }),
    MenuAction("Green", { ~text.background = Color.green }),
    MenuAction("Blue", { ~text.background = Color.blue })
)
)
{var sig = SinOsc.ar(120); Out.ar(0, sig!2);}.play