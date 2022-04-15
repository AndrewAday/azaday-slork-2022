public class ElectricOrgan extends Chugraph
{
    // patch
    BeeThree organ => JCRev r => Echo e => Echo e2 => dac;
    // Rhodey organ => JCRev r => Echo e => Echo e2 => dac;
    organ.help();
    r => dac;

    // set delays
    240::ms => e.max => e.delay;
    480::ms => e2.max => e2.delay;
    // set gains
    .6 => e.gain;
    .3 => e2.gain;
    .1 => r.mix;
    0 => organ.gain;
    
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