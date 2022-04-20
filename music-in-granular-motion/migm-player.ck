/*
BPM: 188
TODO: add kick on every repeat of sequence

End mode: press enter, set all gains to 0
*/
public class MIGMPlayer {
    "sequencer" => string SEQ_TYPE;
    "drone" => string DRONE_TYPE;
    // 2 => int NUM_CHANNELS;
    6 => int NUM_CHANNELS;

    188. => float BPM;
    (60. / (BPM))::second => dur qt_note;  // seconds per quarter note

    [
        "basal-0.wav",
        "basal-1.wav",
        "energy-lead.wav",
        "energy-drone.wav",  // 3
        "wtx-0.wav",
        "wtx-1.wav",
        "wtx+1.wav",
        "einstein.wav",  // 7
        "lamonte.wav",
        "tanpura.wav",
        "tuvan.wav",  // 10
        "female-choir.wav",
        "male-choir.wav"  // 12
        // TODO: add cello
    ] @=> string drone_paths[];

    // add sequencers
    Granulator @ seq_grans[0];
                        //  gain  oct  note
    add_seq("basal-0.wav", 0., 1., 1.);
    add_seq("wtx+1.wav", 0., 0, 1.);
    add_seq("energy-lead.wav", 0., 0, 1.);
    add_seq("minimoon-high.wav", 0., 0, 1.);
    add_seq("basal-0.wav", 0., 0., 1.);


    fun void add_seq(string filepath, float gain, float off, float deg) {
        Granulator seq_gran;  // init new sequencer voice
        seq_grans << seq_gran;  // add to array of sequencers

        seq_gran.init(filepath, SEQ_TYPE, NUM_CHANNELS);
        off => seq_gran.GRAIN_PLAY_RATE_OFF;
        gain => seq_gran.lisa.gain;
        deg => seq_gran.GRAIN_SCALE_DEG;
        qt_note / 4. => seq_gran.GRAIN_LENGTH;
        // TODO: lfo cycle release or expose param to control attack shape
        seq_gran.adsr.set(
            qt_note / 6.,
            qt_note / 6.,
            // .6,
            1,
            qt_note / 2.  // TODO: play with release time
            // qt_note / 1 
        );
        spork ~ seq_gran.cycle_pos();
        spork ~ seq_gran.granulate();
    }


    // Drone state params
    Granulator @ drone_grans[0];

    // init drone
    add_drone("tpl-organ.wav", 0, 0, 1.);
    add_drone("lukewarm-low.wav", 0, 0, 1.);
    add_drone("energy-drone.wav", 0, 0, 1.);
    add_drone("cellos.wav", 0, 0, 1.);
    add_drone("tuvan.wav", 0, 0, 1.);
    add_drone("replicant-high.wav", 0, 0, 1.);
    // add_drone("basal-0.wav", 0, 0, 1.);
    add_drone("female-choir.wav", 0, 0, 1.);
    add_drone("male-choir.wav", 0, 0, 1.);
    add_drone("minimoon-high.wav", 0, 0, 1.);
    add_drone("minimoon-low.wav", 0, 0, 1.);
    add_drone("lamonte.wav", 0, 0, 1.);
    // add_drone("replicant-octave.wav", 0, 0, 1.);

    fun void add_drone(string filepath, float gain, float off, float deg) {
        Granulator drone;
        drone_grans << drone;

        drone.init(filepath, DRONE_TYPE, NUM_CHANNELS);
        gain => drone.lisa.gain;
        off => drone.GRAIN_PLAY_RATE_OFF;
        deg => drone.GRAIN_SCALE_DEG;

        spork ~ drone.cycle_pos();
        spork ~ drone.granulate();
    }

    // spork network event listeners
    spork ~ step_seq();
    spork ~ seq_gain_handler();
    spork ~ seq_octave_handler();
    spork ~ seq_adsr_rel_handler();
    spork ~ seq_scale_deg_handler();

    spork ~ drone_gain_handler();
    spork ~ drone_octave_handler();
    spork ~ drone_scale_deg_handler();
    spork ~ drone_spat_gain_handler();


/* =============== Network Handlers =============== */

    fun void seq_gain_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/sequence/gain, i f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                seq_grans[msg.getInt(0)] @=> Granulator @ g;
                // if (g.MUTED) { 0 => g.lisa.gain; continue; }
                Math.max(0, g.lisa.gain() + msg.getFloat(1)) => g.lisa.gain;
            }
        }
    }

    fun void seq_octave_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/sequence/octave, i f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                seq_grans[msg.getInt(0)] @=> Granulator @ g;
                msg.getFloat(1) +=> g.GRAIN_PLAY_RATE_OFF;
            }
        }
    }

    fun void seq_scale_deg_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/sequence/scale_deg, i i" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                seq_grans[msg.getInt(0)] @=> Granulator @ g;
                msg.getInt(1) +=> g.seq_off_idx;
                // clamp
                Math.max(0, Math.min(g.SEQ_OFFSETS.size() - 1, g.seq_off_idx)) $ int => g.seq_off_idx;
                g.SEQ_OFFSETS[g.seq_off_idx] => g.GRAIN_SCALE_DEG;
            }
        }
    }

    // multicast set release for ALL sequence voices
    fun void seq_adsr_rel_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/sequence/release, f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                for (int j; j < seq_grans.cap(); j++) {
                    Math.max(0.01, msg.getFloat(0)) => float rel;
                    seq_grans[j].adsr.releaseTime(rel * (qt_note / 2));
                }
            }
        }
    }
    
    fun void step_seq() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/sequence/play, f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                for (int j; j < seq_grans.cap(); j++) {
                    msg.getFloat(0) => seq_grans[j].GRAIN_PLAY_RATE;
                    seq_grans[j].adsr.keyOn();
                }
                qt_note/4. => now;
                for (int j; j < seq_grans.cap(); j++) {
                    seq_grans[j].adsr.keyOff();
                }
            }
        }
    }


/*========================Drone Handlers===========================*/
    fun void drone_gain_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/drone/gain, i f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                drone_grans[msg.getInt(0)] @=> Granulator @ g;
                // if (g.MUTED) { 0 => g.lisa.gain; continue; } // TODO: muting
                Math.max(0, g.lisa.gain() + msg.getFloat(1)) => g.lisa.gain;
            }
        }
    }

    fun void drone_octave_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/drone/octave, i f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                drone_grans[msg.getInt(0)] @=> Granulator @ g;
                msg.getFloat(1) +=> g.GRAIN_PLAY_RATE_OFF;
            }
        }
    }

    fun void drone_scale_deg_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/drone/scale_deg, i f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                drone_grans[msg.getInt(0)] @=> Granulator @ g;
                msg.getFloat(1) => g.GRAIN_SCALE_DEG;
            }
        }
    }

    fun void drone_spat_gain_handler() {
        OscIn oin;
        OscMsg msg;
        6449 => oin.port;

        // create an address in the receiver, expect an int and a float
        oin.addAddress( "/migm/drone/spat_gain, i f" );

        while (true) {
            oin => now;
            while (oin.recv(msg)) {
                drone_grans[msg.getInt(0)] @=> Granulator @ g;
                msg.getFloat(1) => g.spat_gain.gain;
            }
        }
    }
    

}