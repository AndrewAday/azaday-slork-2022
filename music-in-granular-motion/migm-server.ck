/*==========Network Setup=========*/

// destination host name
[ // Note: Hosts must be added in consecutive order
    "localhost"
    // "donut.local",
    // "omelet.local",
    // "kimchi.local"
] @=> string hostnames[];

// destination port number
6449 => int port;

// check command line
// if( me.args() ) me.arg(0) => hostname;
// if( me.args() > 1 ) me.arg(1) => Std.atoi => port;

// sender object
hostnames.size() => int NUM_RECEIVERS;
OscOut xmits[NUM_RECEIVERS];

// aim the transmitter at destination
for (0 => int i; i < NUM_RECEIVERS; i++) {
    xmits[i].dest( hostnames[i], port );
}


/*==========HID config=========*/
// HID objects
Hid hi;
HidMsg msg;

// which joystick
0 => int device;
// 0 => int device;

// open joystick 0, exit on fail
if( !hi.openKeyboard( device ) ) me.exit();
// log
<<< "keyboard '" + hi.name() + "' ready", "" >>>;


/*===========OSC Senders==========*/
    /*===========Sequence Senders==========*/
        /*===========Multicast Senders==========*/
// change gain for this sequencer on ALL hemis
fun void change_seq_gain(int idx, float g) {  
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/sequence/gain");
        xmits[i].add(idx);
        xmits[i].add(g);
        xmits[i].send();
    }
}

// change octave for this sequencer on ALL hemis
fun void change_seq_octave(int idx, float octave) {
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/sequence/octave");
        xmits[i].add(idx);
        xmits[i].add(octave);
        xmits[i].send();
    }
}

fun void change_seq_scale_deg(int idx, int scale_deg) {
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/sequence/scale_deg");
        xmits[i].add(idx);
        xmits[i].add(scale_deg);
        xmits[i].send();
    }
}

fun void change_seq_rel_time(float ratio) {
  for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/sequence/release");
        xmits[i].add(ratio);
        xmits[i].send();
    }
}
        /*===========Targetted Senders==========*/
// hemi at idx
fun void seq_play(int idx, float freq) {
    xmits[idx] @=> OscOut @ xmit;
    xmit.start("/migm/sequence/play");
    xmit.add(freq);
    xmit.send();
}
    /*===========Drone Senders==========*/
        /*===========Multicast Senders==========*/
// changes gain on all hemis for droner at drones[idx]
fun void change_drone_gain(int idx, float g) {
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/drone/gain");
        xmits[i].add(idx);
        xmits[i].add(g);
        xmits[i].send();
    }
}

// change octave for this droner on ALL hemis
fun void change_drone_octave(int idx, float octave) {
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/drone/octave");
        xmits[i].add(idx);
        xmits[i].add(octave);
        xmits[i].send();
    }
}

// set drone fundamental pitch
fun void change_drone_scale_deg(int idx, float play_rate) {
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/drone/scale_deg");
        xmits[i].add(idx);
        xmits[i].add(play_rate);
        xmits[i].send();
    }
}
        /*===========Targetted Senders==========*/
fun void change_drone_spat_gain(int d_idx, int idx0, int idx1, float g0, float g1) {
    // update 2 hemi gains
    xmits[idx0].start("/migm/drone/spat_gain");
    xmits[idx0].add(d_idx);  // which drone
    xmits[idx0].add(g0);  // gain level
    xmits[idx0].send();

    xmits[idx1].start("/migm/drone/spat_gain");
    xmits[idx1].add(d_idx);  // which drone
    xmits[idx1].add(g1);  // gain level
    xmits[idx1].send();
}



/*========Sequencer global controls=========*/
"sequencer" => string SEQ_TYPE;
"drone" => string DRONE_TYPE;
// scales
[
    [1., 2/3., 3/4., 9/10., 9/8., 6/5., 4/3., 3/2.],
    [5/6., 3/4., 1., 9/8., 5/4., 3/2., 5/3.]  // penta min
] @=> float SCALES[][];

[
    "aeolian hexa",
    "penta minor"
] @=> string SCALE_NAMES[];

0 => int scale_idx;  // for browsing

SCALES[scale_idx] @=> float scale[];
scale_idx => int cur_scale_idx;
[3/4., 1., 9/8., 6/5., 4/3.] @=> float init_seq[];

188. => float BPM;
(60. / (BPM))::second => dur qt_note;  // seconds per quarter note

// SEQUENCE Manipulator
SeqMan seqman;
seqman.init(init_seq, scale);

0 => int REHEARSAL;

// local sequencer
MIGMPlayer local_player;
local_player.drone_grans.size() => int NUM_DRONES;
local_player.seq_grans.size() => int NUM_SEQS;

// drone spatializers
Spatializer drone_spats[NUM_DRONES];
0 => int drone_spat_idx;
    // init with num speakers
for (0 => int i; i < drone_spats.size(); i++){
    drone_spats[i].init(NUM_RECEIVERS);
}

// target gain buffs
float drone_target_gains[NUM_DRONES];
float seq_target_gains[NUM_SEQS];

// upon initialiation, make all drone spatializer gains = 0
fun void zero_all_spat_gains() {
    for (0 => int i; i < NUM_DRONES; i++) {
      for (0 => int j; j < NUM_RECEIVERS; j++) {
          xmits[j].start("/migm/drone/spat_gain");
          xmits[j].add(i);  // which drone
          xmits[j].add(0);  // gain level
          xmits[j].send();
      }
    }
}


// indices for tracking position in terminal display
0 => int seq_idx;
0 => int drone_idx;

/*========keyboard controls=======*/

// keyboard modes

20 => int KEY_Q;
26 => int KEY_W;
8 => int KEY_E;
21 => int KEY_R;
23 => int KEY_T;
28 => int KEY_Y;

// KEY_Q => int SEQ_SPATIALIZER_MODE;
// KEY_W => int DRONE_SPATIALIZER_MODE;
// KEY_E => int SEQ_MODE;
// KEY_R => int SEQ_VOICE_MODE;
// KEY_T => int DRONE_MODE;
// KEY_Y => int SCALE_MODE;

30 => int SEQ_SPATIALIZER_MODE;
31 => int DRONE_SPATIALIZER_MODE;
32 => int SEQ_MODE;
33 => int SEQ_VOICE_MODE;
34 => int DRONE_MODE;
35 => int SCALE_MODE;

30 => int KEY_ONE;
39 => int KEY_ZERO;

// keys
42 => int KEY_DELETE;
44 => int KEY_SPACE; 
45 => int KEY_DASH;
46 => int KEY_EQUAL;
54 => int KEY_COMMA;
55 => int KEY_PERIOD;
79 => int KEY_RIGHT;
80 => int KEY_LEFT;
81 => int KEY_DOWN;
82 => int KEY_UP;
47 => int KEY_LB;
48 => int KEY_RB;
56 => int KEY_SLASH;
225 => int KEY_LEFT_SHIFT;

29 => int KEY_Z;
22 => int KEY_S;
27 => int KEY_X;
7 => int KEY_D;
6 => int KEY_C;
9 => int KEY_F;
25 => int KEY_V;
10 => int KEY_G;
5 => int KEY_B;
11 => int KEY_H;
24 => int KEY_U;
16 => int KEY_M;

40 => int KEY_ENTER;

SEQ_MODE => int ACTIVE_MODE;

fun int key_to_int(int key) {
  if (key < KEY_ONE || key > KEY_ZERO) {
    return -1;  // invalid
  } 
  return key - KEY_ONE;  // maps 1 to zero, 2 to 1, 0 --> 9
}

fun void print_scales() {
  "current: " + SCALE_NAMES[cur_scale_idx] + " | " => string ret;
  "select: " + SCALE_NAMES[scale_idx] +=> ret;
  <<< ret >>>;
}

fun void print_voices(string type) {
    20::ms => now;  // to allow network to catch up
    Granulator @ grans[];
    int idx;
    if (type == SEQ_TYPE) {
        local_player.seq_grans @=> grans;
        seq_idx => idx;
    } else if (type == DRONE_TYPE) {
        local_player.drone_grans @=> grans;
        drone_idx => idx;
    }
    if (type == SEQ_TYPE) {
        println("<<<<<========================= Sequencers ============================>>>>>");
    } else {
        println("<<<<<=========================== Droners =============================>>>>>");
    }
    println("");
    for (int i; i < grans.cap(); i++) {
        "" => string ret;
        grans[i] @=> Granulator @ g;
        if (i == idx) {
        "[--->" +=> ret;
        }


        "Gain: " +=> ret;
        // g.lisa.gain() +=> ret;
        g.target_lisa_gain +=> ret;

        "   Octave: " +=> ret;
        g.GRAIN_PLAY_RATE_OFF $ int +=> ret;

        "   Degree: " +=> ret;
        g.GRAIN_SCALE_DEG +=> ret;


        " ========= " + "[" + i + "] " + g.sample +=> ret;

        if (i == idx) {
        "<---] " +=> ret;
        }

        println(ret);
        println("                                                                  ");

        // " | " +=> ret;
    }
    println("===========================================================================");
    println("");
    // <<< ret >>>;
    // <<< "                                 |                                 " >>>;
}

// prints drone spat info at regular interval
fun void print_drone_spats() {
    println("<<<<<=========================== Drone Spatializers =============================>>>>>");
    println("");
    for (0 => int i; i < NUM_DRONES; i++) {
        "" => string s;
        if (i == drone_spat_idx) {
          "[--> " +=> s;
        }
        drone_spats[i].get_string_tag() + " ========= " + "[" + i + "] " + local_player.drone_grans[i].sample +=> s;
        if (i == drone_spat_idx) {
          " <--]" +=> s;
        }
        println(s);
        println(drone_spats[i].visualize());
    }
    println("======================================================================================");
} 

fun void drone_spat_printer() {
  while (true) {
    1000::ms => now;
    if (ACTIVE_MODE != DRONE_SPATIALIZER_MODE) {
        continue;
    }
    print_drone_spats();
  }
} spork ~ drone_spat_printer();


fun void equip_scale(int idx) {
  idx => cur_scale_idx;
  SCALES[idx] @=> seqman.scale;
  SCALES[idx] @=> scale;
  <<< "--------------------------------------------" >>>;
  <<< "|                                          |" >>>;
  <<< "|            EQUIPPING NEW SCALE           |" >>>;
  <<< " |               ", SCALE_NAMES[idx], "              |" >>>;
  <<< "--------------------------------------------" >>>;
}

/*=============== Spatializers ==================*/

  /*=============== Sequence Spatializer ==================*/
// spat mode enums
0 => int CLOCKWISE;
1 => int COUNTER_CLOCK;
2 => int HOLD;
3 => int RANDOM;
4 => int NUM_SEQ_SPAT_MODES;

0 => int player_idx;
CLOCKWISE => int SEQ_SPAT_MODE;
1 => int num_seq_heads; // [1, n]. Evenly spaces. at n = 3, every other computer plays sequence. 
0 => int skip_n; // skips n hemis every speaker change.  if n = 0, we hold. capped at num_players - 1
5 => int change_rate; // changes hemis every n notes. if n = 0, we hold
1.0 => float release_ratio;  // release time for seq adsr

fun void next_seq_spat_mode() {
    (SEQ_SPAT_MODE + 1) % NUM_SEQ_SPAT_MODES => SEQ_SPAT_MODE;
}

fun void update_player_idx(int amt) {
    // TODO: exclude localhost
    amt + player_idx => int tmp;
    if (tmp > 0) {
      tmp % NUM_RECEIVERS => player_idx;
    } else {
      while (tmp < 0) {  // wrap around from -1 --> NUM_RECEIVERS - 1
        NUM_RECEIVERS +=> tmp;
      }
      tmp => player_idx;
    }
}

fun void seq_spatializer() {
    0 => int note_acc;  // counts notes played since change
    while (true) {
        seqman.seq @=> float seq[];
        for (int i; i < seq.cap(); i++) {
            seq_play(player_idx, seq[i]);  // trigger note play
            note_acc++;  // inc note counter

            qt_note/2.0 => now; // pass time

            // re-print console visuals after change
            if (ACTIVE_MODE == SEQ_SPATIALIZER_MODE) {
                print_seq_spat();
            }

            if (SEQ_SPAT_MODE == HOLD) {
                continue;
            }
            
            // check if we need to change hemis
            if (change_rate > 0 && note_acc >= change_rate) {
                0 => note_acc;  // reset accumulator
                // change player idx
                if (SEQ_SPAT_MODE == CLOCKWISE) {
                    update_player_idx(skip_n);
                } else if (SEQ_SPAT_MODE == COUNTER_CLOCK) {
                    update_player_idx(-skip_n);
                } else if (SEQ_SPAT_MODE == RANDOM) {
                    update_player_idx(Math.random2(0, NUM_RECEIVERS - 1));
                }
            }

            // TODO: don't play localhost
        }
    }
} spork ~ seq_spatializer();

fun string visualize_seq_pos() {
    "" => string s;
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        if (i == player_idx) {
            "[^]" +=> s;
        } else {
            "[ ]" +=> s;
        }
        if (i+1 != NUM_RECEIVERS) {
            // "==========" +=> s;
            "          " +=> s;
        }
    }
    return s;
}

fun string get_mode_string() {
    if (SEQ_SPAT_MODE == CLOCKWISE) {
        return "CLCK";
    } else if (SEQ_SPAT_MODE == COUNTER_CLOCK) {
        return "CNTR";
    } else if (SEQ_SPAT_MODE == HOLD) {
        return "HOLD";
    } else if (SEQ_SPAT_MODE == RANDOM) {
        return "RNDM";
    } else {
        return "N/A";
    }
}

// prints sequence spatialization params
fun void print_seq_spat() {
    "" => string s;
    "Mode: " + get_mode_string() +=> s;  // mode
    " | Skip: " + skip_n +=> s;  // number of hemis skipped
    " | Change: " + change_rate +=> s; // change every N notes
    " | Release: " + release_ratio +=> s;
    println(s);
    println(visualize_seq_pos());
}

// fun void seq_spat_printer() {

// }  spork ~  seq_spat_printer();





  /*
  =============== Continuous Broadcast ==================
  These functions will continuously send network messages
  updating state in players.
  These are for events that cannot afford to be lost over 
  UDP.
  */

// Drone Spatializer: reads all spatializer objects, sets gains on hemis accordingly
fun void set_drone_spat_gains() {
    int idxs[2]; float gains[2];
    while (true) {
        for (0 => int i; i < NUM_DRONES; i++) {  // foreach drone
            drone_spats[i].get_gains(idxs, gains);
            // update its gain at both hemis
            change_drone_spat_gain(i, idxs[0], idxs[1], gains[0], gains[1]);
        }
        15::ms => now;
    }
} spork ~ set_drone_spat_gains();

// Target Gain: set target lisa gain on all players
fun void set_drone_target_gains() {
    5::ms => now;
    while (true) {
        for (0 => int i; i < NUM_DRONES; i++) {  // foreach drone
            change_drone_gain(i, drone_target_gains[i]);
        }
        15::ms => now;
    }
} spork ~ set_drone_target_gains();

fun void set_seq_target_gains() {
    10::ms => now;
    while (true) {
        for (0 => int i; i < NUM_SEQS; i++) {  // foreach drone
            change_seq_gain(i, seq_target_gains[i]);
        }
        15::ms => now;
    }
} spork ~ set_seq_target_gains();



/*=============== Controls ==================*/

fun void println(string s) {
  chout <= s <= IO.newline();
}

zero_all_spat_gains();  // zero remnant spat gains

kb();
fun void kb() {
    while( true ) {
        hi => now;

        while( hi.recv( msg ) )
        {
            // <<< msg.which >>>;
            if( msg.isButtonDown() )
            {
                // selecting keyboard mode
                if (msg.which >= 30 && msg.which <= 37) {
                    msg.which => ACTIVE_MODE;
                    if (ACTIVE_MODE == SEQ_SPATIALIZER_MODE) {
                    //   println("<<<<<<<<<=======Spatializer Mode: Sequencers========>>>>>>>>>>>");
                      println("<<<<<======================== Sequence Spatializers ==========================>>>>>");
                      println("");
                      print_seq_spat();
                    } else if (ACTIVE_MODE == DRONE_SPATIALIZER_MODE) {
                    //   println("<<<<<<<<<=======Spatializer Mode: Drones========>>>>>>>>>>>");
                      print_drone_spats();
                    } else if (ACTIVE_MODE == SEQ_MODE) {
                        println("<<<<<<<<<=======Sequence Manipulator========>>>>>>>>>>>");
                        println("");
                        seqman.print_state();
                    } else if (ACTIVE_MODE == DRONE_MODE) {
                        // println("<<<<<<<<<=======Active Droners========>>>>>>>>>>>");
                        print_voices(DRONE_TYPE);
                    } else if (ACTIVE_MODE == SEQ_VOICE_MODE) {
                        // println("<<<<<<<<<=======Active Sequencers========>>>>>>>>>>>");
                        print_voices(SEQ_TYPE);
                    } else if (ACTIVE_MODE == SCALE_MODE) {
                        println("<<<<<<<<<=======Select Scale========>>>>>>>>>>>");
                        print_scales();
                    } else {
                        println("huh?");
                    }
                    continue;
                }

                if (ACTIVE_MODE == SEQ_SPATIALIZER_MODE) {
                  handle_seq_spat_mode(msg.which);
                } else if (ACTIVE_MODE == DRONE_SPATIALIZER_MODE) {
                  handle_drone_spat_mode(msg.which);
                } else if (ACTIVE_MODE == SEQ_MODE) {
                  handle_seq_mode(msg.which);
                } else if (ACTIVE_MODE == DRONE_MODE) {
                  handle_drone_mode(msg.which);
                } else if (ACTIVE_MODE == SEQ_VOICE_MODE) {
                  if (msg.which == KEY_UP) {
                      seq_idx--;
                      if (seq_idx < 0) { NUM_SEQS - 1 => seq_idx; }
                  } else if (msg.which == KEY_DOWN) {
                      seq_idx++;
                  }

                  seq_idx % NUM_SEQS => seq_idx;
                  // <<< seq_idx >>>;
                  local_player.seq_grans[seq_idx] @=> Granulator @ g;

                  // For now, all sequencer voice changes are multicast GLOBAL
                  if (msg.which == KEY_RIGHT) {
                    //   change_seq_gain(seq_idx, .1);
                    seq_target_gains[seq_idx] => float target_gain;
                    target_gain + .1 => seq_target_gains[seq_idx];
                  } else if (msg.which == KEY_LEFT) {
                    //   change_seq_gain(seq_idx, -.1);
                    seq_target_gains[seq_idx] => float target_gain;
                    Math.max(0, target_gain - .1) => seq_target_gains[seq_idx];
                  } else if (msg.which == KEY_LB) {
                      change_seq_octave(seq_idx, -1.0);
                  } else if (msg.which == KEY_RB) {
                      change_seq_octave(seq_idx, 1.0);
                  } else if (msg.which == KEY_COMMA) {
                      change_seq_scale_deg(seq_idx, -1);
                  } else if (msg.which == KEY_PERIOD) {
                      change_seq_scale_deg(seq_idx, 1);
                  } else if (msg.which == KEY_M) {
                      0.0 => seq_target_gains[seq_idx];
                    // TODO
                    // if (g.MUTED) {
                    //   spork ~ g.unmute(2::second);
                    // } else {
                    //   spork ~ g.mute(2::second);
                    // }
                  }
                  print_voices(SEQ_TYPE);
                } else if (ACTIVE_MODE == SCALE_MODE) {
                    if (msg.which == KEY_UP) {
                      if (scale_idx == SCALES.cap()-1) {
                        0 => scale_idx;
                      } else {
                        scale_idx++;
                      }
                    } else if (msg.which == KEY_DOWN) {
                      if (scale_idx == 0) {
                        SCALES.cap() - 1 => scale_idx;
                      } else {
                        scale_idx--;
                      }
                    }
                    if (msg.which == KEY_ENTER) {
                      equip_scale(scale_idx);
                      // gen new sequence of same size
                      seqman.gen_new_seq(seqman.seq.size());
                      
                    }
                    print_scales();
                }
            }
        }
    }
}

fun void handle_seq_spat_mode(int key) {

    if (key == KEY_SPACE) {  // cycle modes
        next_seq_spat_mode();
    } else if (key == KEY_RIGHT) {  // inc change rate
        change_rate++;
    } else if (key == KEY_LEFT) {  // dec change rate
        Math.max(0, change_rate-1) $ int => change_rate;
    } else if (key == KEY_UP) {  // inc skip
        Math.min(NUM_RECEIVERS - 1, skip_n + 1) $ int => skip_n;
    } else if (key == KEY_DOWN) {  // dec skip
        Math.max(0, skip_n - 1) $ int => skip_n;
    } else if (key == KEY_PERIOD) {  // inc release time
        .2 +=> release_ratio;
        change_seq_rel_time(release_ratio);
    } else if (key == KEY_COMMA) {  // dec rel time
        Math.max(0, release_ratio - .2) => release_ratio;
        change_seq_rel_time(release_ratio);
    }

    print_seq_spat();
}

fun void handle_drone_spat_mode(int key) {
    if (key == KEY_UP) {
      if (drone_spat_idx > 0) { drone_spat_idx--; }
      else { NUM_DRONES - 1 => drone_spat_idx; }
    } else if (key == KEY_DOWN) {
      if (drone_spat_idx < NUM_DRONES - 1) { drone_spat_idx++; }
      else { 0 => drone_spat_idx; }
    } 
    // else if (key_to_int(key) >= 0) {
    //   key_to_int(key) => drone_spat_idx;
    // }

    // <<< drone_spat_idx >>>;

    drone_spats[drone_spat_idx] @=> Spatializer spat;

    if (key == KEY_RIGHT) {  // inc rate
      spat.change_cycle_rate(.1);
    } else if (key == KEY_LEFT) {  // dec rate
      spat.change_cycle_rate(-.1);
    } else if (key == KEY_SPACE) {  // cycle mode
      spat.next_mode();
    } else if (key == KEY_EQUAL) {
      spat.change_base_gain(.1);
    } else if (key == KEY_DASH) {
      spat.change_base_gain(-.1);
    }

    20::ms => now;  // give time for network to prop

    print_drone_spats();
}

fun void handle_drone_mode(int key) {
    if (key == KEY_UP) {
      if (drone_idx > 0) { drone_idx--; }
      else { NUM_DRONES - 1 => drone_idx; }
    } else if (key == KEY_DOWN) {
      if (drone_idx < NUM_DRONES - 1) { drone_idx++; }
      else { 0 => drone_idx; }
    }

    local_player.drone_grans[drone_idx] @=> Granulator @ g;

    // TODO: refactor into network function calls
    if (key == KEY_RIGHT) {
        // change_drone_gain(drone_idx, .1);
        drone_target_gains[drone_idx] + .1 => drone_target_gains[drone_idx];
    } else if (key == KEY_LEFT) {
        // change_drone_gain(drone_idx, -.1);
        drone_target_gains[drone_idx] => float target_gain;
        Math.max(0, target_gain - .1) => drone_target_gains[drone_idx];
    } else if (key == KEY_LB) {
        change_drone_octave(drone_idx, -1);
    } else if (key == KEY_RB) {
        change_drone_octave(drone_idx, 1);
    } else if (key == KEY_R) { // randomize pitch
        seqman.scale[Math.random2(0, seqman.scale.cap()-1)] => float sd;
        while (Std.fabs(sd - g.GRAIN_SCALE_DEG) < .001) {  // gaurantee new note
          seqman.scale[Math.random2(0, seqman.scale.cap()-1)] => sd;
        }
        change_drone_scale_deg(drone_idx, sd);
    } else if (msg.which == KEY_M) {
        0.0 => drone_target_gains[drone_idx];
        // TODO: implement muting

        // if (g.MUTED) {
        //   spork ~ g.unmute(2::second);  
        // } else {
        //   spork ~ g.mute(2::second);
        // }
    }

    print_voices(DRONE_TYPE);
}

fun void handle_seq_mode(int key) {
  // these are all banked, discrete rehearsal-based changes
  false => int reset_seq;
  if (key == KEY_DELETE) {
      true => reset_seq;
      KEY_ENTER => key;  // force the sequence update
  }
  if( key == KEY_LEFT )
  {
    if (seqman.idx > 0) {seqman.idx--;}
    else if (seqman.idx == 0) { seqman.seq.cap() => seqman.idx; }
  }
  else if( key == KEY_RIGHT )
  {
    if (seqman.idx < seqman.seq.cap()) {seqman.idx++;}
    else if (seqman.idx == seqman.seq.cap()) {0 => seqman.idx; }
  }
  // TODO: remove replicate?
  else if (key == KEY_Z) { seqman.repl_n--; }
  else if (key == KEY_S) { seqman.repl_n++; }
  else if (key == KEY_X) { seqman.copy_n--; }
  else if (key == KEY_D) { seqman.copy_n++; }
  else if (key == KEY_C) { seqman.sub_n--; }
  else if (key == KEY_F) { seqman.sub_n++; }
  else if (key == KEY_V) { seqman.add_n--; }
  else if (key == KEY_G) { seqman.add_n++; }
  else if (key == KEY_B) { seqman.extr_n--; }
  else if (key == KEY_H) { seqman.extr_n++; }
  else if (key == KEY_R) {
    if (seqman.should_rev) { 0 => seqman.should_rev; }
    else { 1 => seqman.should_rev; }
  }
  // Apply all changes to new rehearsal
  if (key == KEY_ENTER) {  // TODO: have enter localized to specific keyboard mode
    REHEARSAL++;

    if (reset_seq) {  // completely recreate sequence
        seqman.gen_new_seq(seqman.seq.size());
    } else {      // apply changes from all keyboard modes
        seqman.manipulate();
    }

    // reset state
    seqman.reset();

    println("--------------------------------------------");
    println("|                                          |");
    println("|                REHEARSAL " +  REHEARSAL + "               |");
    println("|                                          |");
    println("--------------------------------------------");
  }
  seqman.print_state();
}