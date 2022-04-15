public class Pumper {
    // turns any instrument into a pump organ by changing the gain according to
    // pulls from the gametrack

    GameTrack gt;
    Gain gain;

    0.0 => float air;
    .008 => float leak_rate;
    7 => float fill_rate;

    spork ~ pump(gt.LZ);
    5::ms => now; // offset slightly
    spork ~ pump(gt.RZ);


    fun void init(GameTrack @ gt, Gain @ gain) {
        gt @=> this.gt;
        gain @=> this.gain;
    }

    fun void pump(int axis) {
        0.0 => float last_pump_pos;
        

        while (true) {
            0. => float air_in;
            0. => float air_out;
            0. => float cur_pump_pos;

            // calculate the amount of air pumped in
            gt.curAxis[axis] => cur_pump_pos;
            if (cur_pump_pos > last_pump_pos) {
                // only push air when drawing tether out
                fill_rate * (cur_pump_pos - last_pump_pos) => air_in;
            }
            cur_pump_pos => last_pump_pos;

            // amount of air pumped out
            leak_rate => air_out;

            // update air tank
            update_air(air_in - air_out);
            
            // set instrument gain
            Math.min(2.5, this.air) => this.gain.gain;

            // pass time
            10::ms => now;
        }
    }

    fun void update_air(float amt) {
        Math.min(3.5, Math.max(0, amt + this.air)) => this.air;
    }

    fun void print() {
        <<< this.air >>>;
    }
}

//array with key codes, for MacBook anyhow
[ 	

[30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 45, 46, 42],	//1234... row
[20, 26, 8, 21, 23, 28, 24, 12, 18, 19, 47, 48, 49],	//qwer... row
[4, 22, 7, 9, 10, 11, 13, 14, 15, 51, 52],		//asdf... row
[29, 27, 6, 25, 5, 17, 16, 54, 55, 56]   		//zxcv... row

]   @=> int row[][];

int keyToPitch_table[256];
Event noteOffs[256];
-2 => int octave_off;
-2 => int string_off;

//tune them strings in 5ths
tuneString(3, 55);  // G
tuneString(2, 62);  // D
tuneString(1, 69);  // A
tuneString(0, 76);  // E

unit_test();



//our big array of pitch values, indexed by ASCII value

//this function takes each row and tunes it in half steps, based
//on whatever fundamental pitch note specified
fun void tuneString(int whichString, int basepitch) {
	
	for (0 => int i; i < row[whichString].cap(); i++) {
		
		string_off + basepitch + i => keyToPitch_table[row[whichString][i]];
		
		<<<row[whichString][i], keyToPitch_table[row[whichString][i]]>>>;
		
	}
	
}


fun void keysound(float freq, Gain @ g, Event noteOff) {
	// SinOsc sine => ADSR envelope => dac;
	// envelope.set(20::ms, 25::ms, 0.1, 150::ms);

    Organ org => g;
    2000 => org.lowpass.freq;
    // BeeThree org => g;
    .25 => org.gain;
    freq => org.freq;
	
	org.keyOn();
    // 1 => org.noteOn;
	noteOff => now;
	org.keyOff();
    // 0 => org.noteOff;
	150::ms => now;
	
	org =< g;
}


fun void unit_test() {

    Hid hi;
    HidMsg msg;

    1 => int deviceNum;
    hi.openKeyboard( deviceNum ) => int deviceAvailable;
    if ( deviceAvailable == 0 ) me.exit();
    <<< "keyboard '", hi.name(), "' ready" >>>;

    // gametrack
    GameTrack gt;
    gt.init(0);

    // pump mechanism
    Gain g => dac;
    Pumper pump_organ;
    pump_organ.init(gt, g);
    spork ~ print_pump(pump_organ);

    // keyboard events
    while (true) {
        hi => now;
        
        while( hi.recv( msg ) )
        {
            if( msg.isButtonDown() )  // key on
            {
                <<< "down:", msg.which >>>;
                    
                keyToPitch_table[ msg.which ] + (12 * octave_off) => Std.mtof => float freq;			
                spork ~ keysound(freq, g, noteOffs[msg.which] );
            }
            
            else  // key off
            {
                <<< "up:", msg.which >>>;
                    
                noteOffs[ msg.which ].signal();
            }
        }
    }
}

fun void print_pump(Pumper @ p) {
    while (true) {
        50::ms => now;
        p.print();
    }
}
    
