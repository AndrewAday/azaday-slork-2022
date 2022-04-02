/* =============== CONSTANTS =============== */
.10 => float stage1start;
.55 => float stage1end;
.68 => float stage2start;
.93 => float stage2end;

293.0 => float tonic;  // middle D

// intervals
9./8. => float M2;
5.0/4 => float M3;
4.0/3 => float P4;
45.0/32 => float Aug4;
3.0/2 => float P5;
5.0/3 => float M6;
15.0/8 => float M7;

// note freqs
  // stage 1
tonic*P4*.25 => float G1;
tonic*.5 => float D2;
tonic*M6*.5 => float B2;
tonic*M3 => float Fs3;
tonic*P5 => float A3;
tonic*M7 => float Cs4;
  // stage 2
D2 * .5 => float D1;
D1 * .5 => float D0;
Fs3 * .5 => float Fs2;
tonic*M2 => float E3;
tonic*Aug4*2 => float Gs4;
B2 * 4.0 => float B4;
A3 * .5 => float A2;
Fs3 * 4.0 => float Fs5;

// G1, D2, B2,  F#3,  A3,  C#4
[
  Cs4, Cs4, Cs4,
  A3, A3,
  Fs3,
  B2, B2,
  D2,
  G1, G1, G1
] @=> float targetFreqs1[];

[
  Fs5,
  B4,
  Gs4,
  Cs4,
  A3,
  E3,
  B2,  // B2 or A2, both sound great
  Fs2,
  D2,
  G1,
  D1,
  D0
] @=> float targetFreqs2[];


/* =============== UTIL =============== */
fun float lerp(float a, float b, float t) {
  return a + t * (b - a);
}

fun float invLerp(time a, time b, time c) {
  return (c-a) / (b-a);
}

fun float clamp01(float f) {
  return Math.max(.0, Math.min(f, .99999));
}

fun float lfo(float freq) {
  return Math.sin(2*pi*freq*(now/second));
}

0. => float pwmDepth;
400 => float fcBase;
0.0 => float fcDepth;
fun void pwm(PulseOsc @ p, LPF @ l, Gain @ g, float wf, float lf, float gf) {
    /* now + fadein => time later; */
  while (true) {

    // mod pulse width
    .5 + pwmDepth * lfo(wf) => p.width;

    // mod filter cutoff
    fcBase + (fcDepth * fcBase) * lfo(lf) =>l.freq;

    // TODO: mod pan?
    /* Math.sin(2*pi*pf*(now/second))=>pan.pan; */

    10::ms => now;
  }
}



/* =============== Setup =============== */
// GameTrak HID
GameTrack gt;
gt.init(0);  // also sporks tracker

// Drummer setup
TaikoDrummer td;
Gain drumGain => dac;
.7 => drumGain.gain;

SndBuf heartbeat[1];
SndBuf E[4];
td.load_and_patch_taiko_samps(heartbeat, "heartbeat", drumGain);
td.load_and_patch_taiko_samps(E, "E", drumGain);
.7 => heartbeat[0].gain;


// connect UGens
targetFreqs1.size() => int numVoices;
PulseOsc voices[numVoices];
LPF lpfs[numVoices];
Gain gains[numVoices];
/* Chorus chorus => NRev rev => OverDrive drive => dac; */
Chorus chorus => NRev rev => dac;
/* Chorus chorus => NRev rev => Fuzz fuzz => dac;  */

/* .0 => fuzz.mix; */  // distortion clips :(
/* .0 => drive.mix; */
.0 => rev.mix;

// chorus settings
.0 => chorus.mix;
.2 => chorus.modFreq;
.07 => chorus.modDepth;

// setup signal flow
for (0 => int i; i < numVoices; i++) {
  voices[i] => lpfs[i] => gains[i] => chorus;

  Math.random2f(1.0/7, 1.0/5) => float wf;  // pulse width mod rate
  Math.random2f(1.0/7, 1.0/5) => float lf;  // low pass cutoff mod rate
  Math.random2f(1.0/7, 1.0/5) => float gf;  // gain mod rate

  spork ~ pwm(voices[i], lpfs[i], gains[i], wf, lf, gf);
  /* spork ~ this.pwm(p2, l2, g2, pan2, 1./12, 1./16, 1./14, -1./18); // pan in opposite direction! */

  // set freq
  tonic => voices[i].freq;

  // set voice gain
  .5 / numVoices => voices[i].gain;
  0.0 => gains[i].gain;

  // TODO: add spatialization here?
    // ranomize which channel the voice is playing from
    // OR split each voice into 6 gains, each feeding into a speaker
      // as hands widen, ramp all to full gain
}



// lerp stage 1
false => int inStage1;  // true when inside stage1 chord
false => int inStage2; // true when inside stage2 chord zone
false => int aboveStage1;  // true when position > stage1 end
60.0 => float beat_bpm;


// heartbeat pattern
fun void heartbeat_pattern() {
  while (true) {
    if (!inStage2) {
      5::ms => now;
      continue;
    }
    Math.random2(0, E.cap()-1) => int idx;
    td.play_heartbeat_pattern(td.bpm_to_qt_note(92), E[idx], 1);
  }
} spork ~ heartbeat_pattern();

fun void stage1_drum_pattern() {
  while (true) {
    if (inStage1) {
      td.play_oneshot(heartbeat[0]);
      td.bpm_to_qt_note(60) => now;
      <<< "bump" >>>;
    } else if (aboveStage1 && !inStage2) {
      td.play_oneshot(heartbeat[0]);
      td.bpm_to_qt_note(beat_bpm) => now;  // accelerate to 92bpm
      <<< "bump" >>>;
    } else {
      5::ms => now;
    }
  }

} spork ~ stage1_drum_pattern();

while (true) {
  gt.GetXZPlaneHandDist() => float handDist;
  /* <<< "handDist: ", handDist >>>; */
  clamp01(gt.invLerp(0, 100, handDist)) => float percentage;

  // stage enter/exit events
  if (!(percentage >= stage1end && percentage <= stage2start)) {
    if (inStage1) {
      <<< "exiting stage1 resolution" >>>;
    }
    false => inStage1;
  }
  if (!(percentage >= stage2end)) {
    if (inStage2) <<< "existing stage2 resoltion" >>>;
    false => inStage2;
  }
  if (percentage >= stage2start && percentage <= stage2end) {
    true => aboveStage1;
    gt.remap(stage2start, stage2end, 60.0, 160.0, percentage) => beat_bpm;
  } else {
    false => aboveStage1;
  }

  // scale params for all voices
  for (0 => int i; i < numVoices; i++) {
    percentage => gains[i].gain;

    // pwm
    percentage * .45 => pwmDepth;

    // lp freq mod
    percentage * (1400) + 400 => fcBase;
    percentage * .85 => fcDepth;

    // effects mod
    percentage * .35 => rev.mix;
    percentage => chorus.mix;
  }

  // chord stage scaling
  if (percentage < stage1start) { // hold tonic

  } else if (percentage >= stage1start && percentage < stage1end) {
    gt.invLerp(stage1start, stage1end, percentage) => float t;
    /* printProgress(t); */
    for (0 => int i; i < numVoices; i++) {
      gt.remap(stage1start, stage1end, tonic, targetFreqs1[i], percentage) => voices[i].freq;
    }
  } else if (percentage >= stage1end && percentage < stage2start) {  // between stages
    if (!inStage1) {
      <<< "entered stage1 resolution!" >>>;
      true => inStage1;
    }
  } else if (percentage >= stage2start && percentage < stage2end) { // stage 2
    gt.invLerp(stage2start, stage2end, percentage) => float t;
    for (0 => int i; i < numVoices; i++) {
      lerp(targetFreqs1[i], targetFreqs2[i], t) => voices[i].freq;

      // lerp overdrive
      /* lerp(.0, .5, t) => drive.mix; */
    }
  } else {  // past stage 2
    if (!inStage2) {
      <<< "entered stage2 resolution!" >>>;
      true => inStage2;
    }
  }

  5::ms => now;
}

int lastT;
fun void printProgress(float t) {
  (t * 10) $ int => int T;
  if (T == lastT) {
    return;
  }
  T => lastT;
  "S[" @=> string output;
  repeat(T) {
    "=" +=> output;
  }
  repeat (10-T) {
    " " +=> output;
  }
  "]E" +=> output;
  <<< output >>>;
}
