public class TaikoDrummer {

  // helper class for structuring playback data
  class DrumHit {
      int sample_idx;
      int num_beats;
  }

  fun dur bpm_to_qt_note(float bpm) {
    return (60. / (bpm))::second;
  }

  fun void load_and_patch_taiko_samps(SndBuf samples[], string prefix, UGen @ out) {
    for (int i; i < samples.cap(); i++) {
        samples[i] => out; // TODO: add reverb?
        me.dir() + "Samples/Taiko/" + prefix + i + ".wav" => samples[i].read;
        0 => samples[i].loop;  // don't loop
        0 => samples[i].rate; // don't play
    }
  }

  /*
  Generates a drum pattern in the format:
  [ (stored in assoc part of array)
      "0": [sample#, num_beats],
      "1": [sample#, num_beats],
      ...
  ]
  */
  fun int[][] generate_drum_pattern(
        int num_beats,
        int num_samples,  // number of samples are there to choose from
        float prob_sample_switch, // probably to switch sample between beats
        float prob_double_time // probability of double time
  ) {
      int pattern[1][1];
      int assoc_idx;
      Math.random2(0, num_samples - 1) => int sample_num;
      for (int beat_num; beat_num < num_beats; beat_num++) {
          // switch sample?
          if (num_samples > 1 && Math.randomf() < prob_sample_switch) {
              Math.random2(0, num_samples - 1) => sample_num;
          }
          if (Math.randomf() < prob_double_time) {
              // add a double time pattern
              [sample_num, 1] @=> pattern["" + assoc_idx++];
              [sample_num, 1] @=> pattern["" + assoc_idx++];
          } else {
              // single time pattern
              [sample_num, 2] @=> pattern["" + assoc_idx++];
          }
      }

      assoc_idx => pattern[0][0];  // store how long the pattern is
      return pattern;
  }
  fun void play_drum_pattern(
        SndBuf samples[],
        int pattern[][],
        dur beat_dur, // length of fastest pulse
        int num_repeats
  ) {
      pattern[0][0] => int num_hits;
      repeat (num_repeats) {
        for (int i; i < num_hits; i++) {
            pattern["" + i] @=> int drum_hit[];
            drum_hit[0] => int sample_idx;
            drum_hit[1] => int num_beats;

            0 => samples[sample_idx].pos;
            1 => samples[sample_idx].rate;

            num_beats::beat_dur => now;
      }
    }
  }

  // plays heart beat pattern .25d -> .75d a total of {n} times
  fun void play_heartbeat_pattern(dur d, SndBuf @ heart, int n) {
    repeat (n) {
      0 => heart.pos;
      1 => heart.rate;
      .25 * d => now;
      0 => heart.pos;
      1 => heart.rate;
      .75 * d => now;
    }
  }

  fun void restart_sndbuf(SndBuf @ s) {
    0 => s.pos;
    1 => s.rate;
  }

  fun void play_oneshot(SndBuf @ s) {
    restart_sndbuf(s);
  }

  fun void test(dur d, SndBuf h, int n) {
    return;
  }
}

/* Unit Test */
/*
TaikoDrummer td;
JCRev rev => Gain drummerGain => dac;
.05 => rev.mix;
.5 => drummerGain.gain;

SndBuf A[9];

td.load_and_patch_taiko_samps(A, "A", rev);
<<< "heartbeat" >>>;
td.play_heartbeat_pattern(1::second, A[0], 4);
<<< "generative pattern" >>>;
td.play_drum_pattern(
  A,
  td.generate_drum_pattern(
    10, // num beats
    A.size(), // num of samples in bank
    .25, // probability of sample switch
    .5 // probability of double time
  ),
  .5 * td.bpm_to_qt_note(86),  // shortest hit duration
  2 // num repeats
);
1::second => now;
*/
