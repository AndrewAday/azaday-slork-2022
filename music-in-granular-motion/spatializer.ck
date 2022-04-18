// helper class for continuous spatialization
public class Spatializer {
    0 => int is_initialized;
    1 => int NUM_SPEAKERS;

    // spatialization mode enums
    0 => int CLOCKWISE;
    1 => int COUNTER_CLOCK;
    2 => int HOLD;

    3 => int NUM_MODES;
    
    0 => int MODE;

    // spatialization params
    0 => float cycle_rate;
    0 => float pos;  // tracks virtual position of drone in speaker array
    0 => float base_gain; // base gain for this drone across ALL hemis
        // TODO: implement base gain

    fun void init(int num_speakers) {
        true => is_initialized;
        num_speakers => this.NUM_SPEAKERS;
        spork ~ spatialize();
    }

    fun void change_cycle_rate(float amt) {
        Math.max(0, cycle_rate + amt) => cycle_rate;
    }

    fun void change_base_gain(float amt) {
        Math.min(1, Math.max(0, base_gain + amt)) => base_gain;
    }

    // cycles through spat modes
    fun void next_mode() { 
        (MODE + 1) % NUM_MODES => MODE;
    }

    fun void spatialize() {
        10::ms => dur update_dur;
        if (!is_initialized) {
            cherr <= "Spatializer uninitialized" <= IO.newline();
            return;
        }
        while (true) { 
            // at a cycle rate of 1, moves to the next hemi every 1 second
            if (MODE == CLOCKWISE) {
                (update_dur / 1::second) * cycle_rate +=> pos;
            } else if (MODE == COUNTER_CLOCK) {
                (update_dur / 1::second) * cycle_rate -=> pos;
            } else if (MODE == HOLD) {
                // don't update position.
            }
            
            // bounds checks
            if (pos >= NUM_SPEAKERS) {  // keep pos in range [0, NUM_SPEAKERS)
                pos - NUM_SPEAKERS => pos;
            }
            if (pos < 0) {
                NUM_SPEAKERS +=> pos;
            }

            update_dur => now;
        }
    }

    // populates out array with gain info
        // [idx0, gain0, idx1, gain1]
    fun void get_gains(int out_idx[], float out_gains[]) {
        Math.floor(pos) $ int => int idx0;
        (idx0 + 1) % NUM_SPEAKERS => int idx1;

        1.0 - (pos - idx0) => float gain0;
        1.0 - gain0 => float gain1;

        // apply base gain

        Math.min(1.0, base_gain + gain0) => gain0;
        Math.min(1.0, base_gain + gain1) => gain1;

        idx0 => out_idx[0]; idx1 => out_idx[1];
        gain0 => out_gains[0]; gain1 => out_gains[1];
    }

    // checks if a = b
    fun int approx(float a, float b) {
        return Std.fabs(a-b) < .0001;
    }

    // prints position and params for this spatializer
    fun string visualize() { 
        "" => string s;
        for (0 => int i; i < NUM_SPEAKERS; i++) {
            if (approx(pos, i)) {
                // "X=========" +=> s;
                "X          " +=> s;
                continue;
            }
            if (pos > i && pos < (i + 1)) {  // pos between [i, i + 1]
                // i +=> s;
                "|" +=> s;
                ((pos - i) * 10) $ int => int dec;
                for (0 => int j; j < 10; j++) {
                    if (j == dec) {
                        "X" +=> s;
                    } else {
                        // "=" +=> s;
                        " " +=> s;
                    }
                }
                continue;
            }
            // else pos is not in [i, i+1]
            // i + "=========" +=> s;
            "|" + "          " +=> s;
        }
        "|" +=> s;
        return s;
    }

    fun string get_mode_string() {
        if (this.MODE == CLOCKWISE) {
            return "CLCK";
        } else if (this.MODE == COUNTER_CLOCK) {
            return "CNTR";
        } else if (this.MODE == HOLD) {
            return "HOLD";
        } else {
            return "NONE";
        }
    }

    fun string get_string() {
        return get_string_tag() + visualize();
    }

    fun string get_string_tag() {
        "Rate: " + this.cycle_rate + " --- " + "Mode: " + get_mode_string()  => string s;
        " --- Base Gain: " + base_gain +=> s;
        return s;
    }
}

// unit_test(); 

fun void unit_test() {
    Spatializer spat;
    spat.init(6); // sporks spatializer
    // set params
    1 => spat.cycle_rate;
    spat.CLOCKWISE => spat.MODE;
    5::ms => now;
    while (true) {
        <<< spat.visualize() >>>;

        float gains[2];
        int idxs[2];
        spat.get_gains(idxs, gains);
        <<< idxs[0], gains[0], "   |   ", idxs[1], gains[1],  " | ",  spat.pos>>>;

        100::ms => now;
    }
}