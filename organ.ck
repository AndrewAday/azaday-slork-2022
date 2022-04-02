// organ = os.osc(freq * .5) + os.triangle(freq) + os.triangle(freq * 2)*.6 : _ / 3 : fi.resonlp(fc, 1, 1) with {
//     octave = hslider("organOctave", 0, -1, 3, 1);
//     freq = hslider("organFreq", 250, 50, 1000, .01) * (2^octave);
//     fc = hslider("organFC", 1750, 20, 10000, .01);
// };

// organEnv = en.adsr(.1, .1, 1, .07, gate) with {
//     gate = checkbox("organGate");
// };

// bestOrgan(ampEnv) = organ * organEnv * gain * ampEnv with {
//     gain = hslider("organGain", 1, 0, 1, .01);
// };


public class Organ extends Chugraph
{
    Gain g => LPF lowpass => ADSR env => outlet;

    // setup oscillators
    SinOsc s => g;
    TriOsc t0 => g;
    TriOsc t1 => g;

    .6 => t1.gain;

    // setup lowpass
    1700. => lowpass.freq;
    
    // setup adsr
    env.set(
        100::ms,
        100::ms,
        1.0,
        70::ms
    );

    260 => this.freq;
    
    fun float freq( float f )
    {
        f * .5 => s.freq;
        f => t0.freq;
        f * 2.0 => t1.freq;
        return f;
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

    fun float freq() {
        return t0.freq();
    }
}

// unit test
/*
Organ org => dac;
while (true) {
    <<< org.freq() >>>;
    org.keyOn();
    1::second => now;
    org.keyOff();
    1::second => now;
    Math.random2f(100, 400) => org.freq;
    
}
*/