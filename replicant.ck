// sounds terrible :(

public class Replicant extends Chugraph
{
  Gain g => LPF lowpass => ADSR env => outlet;
  SawOsc s0 => g; SawOsc s1 => g;
  .15 => s1.phase;

  .5 => s0.gain; .5 => s1.gain;

  // No lfo pitch modulation, is this even possible in a chugraph?
  // should be fine for width demo -- hands shaking will add tremolo
  /* SinOsc lfo => blackhole;
  2.0 => lfo.freq; */

  // connect oscillators


  // lowpass
  3000.0 => lowpass.freq;

  // adsr
  env.set(
      150::ms,
      100::ms,
      1.0,
      500::ms
  );

  fun float freq( float f )
  {
      f => s0.freq;
      f => s1.freq;
      return f;
  }

  fun float freq() {
      return s0.freq();
  }

  fun void keyOn()
  {
      env.keyOn();
  }

  fun void keyOff() {
      env.keyOff();
  }

  fun float gain(float g) {
      g => this.g.gain;
      return g;
  }

  fun float gain() {
      return g.gain();
  }
}

// unit test

Replicant org => dac;
while (true) {
    <<< org.freq() >>>;
    <<< org.s0.phase() >>>;
    org.keyOn();
    1::second => now;
    org.keyOff();
    1::second => now;
    Math.random2f(100, 400) => org.freq;

}



/*
Replicant xd
Filter
- Cutoff: 350
- Res: 250
AMP EG
- Atk: <100
- Dec: None
- Sus: Max
- Rel: 600
- Velocity:
EG
- Target: Cutoff
- Atk: 75%
- Dec: 650
- Int: 650
- Velocity:
LFO
- Target: Pitch Osc 1 2
- Wave:  Triangle
- Mode: Normal
- Rate: 550
- Int [-511, 511] (shift to invert): <10
- Sync
    - Target osc: All
    - Key sync: On
    - Voice sync: On
Effects Engine
- MOD Type: Stereo Chorus
    - Subtype (shift+select): Stereo
    - time: 50%
    - depth: 50%
- DEL: Stereo BPM
    - time: 1/3 at 120bpm
    - depth: 15% (tiny)
    - wet/dry (shift+depth): Balanced
- REV: Smooth
    - time: 6s
    - depth: 100%
    - wet/dry (shift+depth): Balanced
*/
