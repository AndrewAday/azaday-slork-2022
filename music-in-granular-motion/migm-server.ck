// destination host name
[
    "localhost"
] @=> string hostnames[];

// destination port number
6449 => int port;

// check command line
// if( me.args() ) me.arg(0) => hostname;
// if( me.args() > 1 ) me.arg(1) => Std.atoi => port;

// sender object
1 => int NUM_RECEIVERS;
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
1 => int device;
// 0 => int device;

// open joystick 0, exit on fail
if( !hi.openKeyboard( device ) ) me.exit();
// log
<<< "keyboard '" + hi.name() + "' ready", "" >>>;


/*===========OSC Senders==========*/
    /*===========Sequence Senders==========*/
        /*===========Multicast Senders==========*/
fun void change_seq_gain(int idx, float g) {
    for (0 => int i; i < NUM_RECEIVERS; i++) {
        xmits[i].start("/migm/sequence/gain");
        xmits[i].add(idx);
        xmits[i].add(g);
        xmits[i].send();
    }
}

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
        /*===========Targetted Senders==========*/
fun void seq_play(int idx, float freq) {
    xmits[idx] @=> OscOut @ xmit;
    xmit.start("/migm/sequence/play");
    xmit.add(freq);
    xmit.send();
}
    /*===========Drone Senders==========*/
        /*===========Multicast Senders==========*/
        /*===========Targetted Senders==========*/

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


// indices for tracking position in terminal display
0 => int seq_idx;
0 => int drone_idx;

/*========keyboard controls=======*/

// keyboard modes
30 => int SPATIALIZER_MODE;
31 => int SEQ_MODE;
32 => int SEQ_VOICE_MODE;
33 => int DRONE_MODE;
34 => int SCALE_MODE;


// keys
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
21 => int KEY_R;
16 => int KEY_M;

40 => int KEY_ENTER;

SEQ_MODE => int ACTIVE_MODE;

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
    "" => string ret;
    for (int i; i < grans.cap(); i++) {
        grans[i] @=> Granulator @ g;
        if (i == idx) {
        "[--->" +=> ret;
        }

        g.sample + ": " +=> ret;
        if (g.MUTED) {
        "MUT" +=> ret;
        } else {
        g.lisa.gain() +=> ret;
        }

        "~" +=> ret;
        g.GRAIN_PLAY_RATE_OFF $ int +=> ret;

        "~" +=> ret;
        g.GRAIN_SCALE_DEG +=> ret;

        if (i == idx) {
        "<---] " +=> ret;
        }

        " | " +=> ret;
    }
    <<< ret >>>;
    <<< "                                 |                                 " >>>;
    <<< "                                 |                                 " >>>;
}

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

// spat mode enums
0 => int CLOCK;
1 => int COUNTER_CLOCK;
2 => int RANDOM;

0 => int player_idx;
CLOCK => int seq_spat_mode;
1 => int num_seq_heads; // [1, n]. Evenly spaces. at n = 3, every other computer plays sequence. 

fun void seq_spatializer() {
    0 => int note_acc;  // counts notes played since change
    while (true) {
        seqman.seq @=> float seq[];
        for (int i; i < seq.cap(); i++) {
            seq_play(player_idx, seq[i]);
            qt_note/2.0 => now;

            // TODO: cycle player idx
        }
    }
} spork ~ seq_spatializer();















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
                if (msg.which >= 30 && msg.which <= 35) {
                    msg.which => ACTIVE_MODE;
                    if (ACTIVE_MODE == SEQ_MODE) {
                        <<< "<<<<<<<<<=======Sequence Mode========>>>>>>>>>>>" >>>;
                        seqman.print_state();
                    } else if (ACTIVE_MODE == DRONE_MODE) {
                        <<< "<<<<<<<<<=======Active Droners========>>>>>>>>>>>" >>>;
                        print_voices(DRONE_TYPE);
                    } else if (ACTIVE_MODE == SEQ_VOICE_MODE) {
                        <<< "<<<<<<<<<=======Active Sequencers========>>>>>>>>>>>" >>>;
                        print_voices(SEQ_TYPE);
                    } else if (ACTIVE_MODE == SCALE_MODE) {
                        <<< "<<<<<<<<<=======Select Scale========>>>>>>>>>>>" >>>;
                        print_scales();
                    } else {
                        <<< "huh" >>>;
                        <<< "active", ACTIVE_MODE >>>;
                    }
                    continue;
                }

                if (ACTIVE_MODE == SEQ_MODE) {
                  // these are all banked, discrete rehearsal-based changes
                  if( msg.which == KEY_LEFT )
                  {
                    if (seqman.idx > 0) {seqman.idx--;}
                    else if (seqman.idx == 0) { seqman.seq.cap() => seqman.idx; }
                  }
                  else if( msg.which == KEY_RIGHT )
                  {
                    if (seqman.idx < seqman.seq.cap()) {seqman.idx++;}
                    else if (seqman.idx == seqman.seq.cap()) {0 => seqman.idx; }
                  }
                  else if (msg.which == KEY_Z) { seqman.repl_n--; }
                  else if (msg.which == KEY_S) { seqman.repl_n++; }
                  else if (msg.which == KEY_X) { seqman.copy_n--; }
                  else if (msg.which == KEY_D) { seqman.copy_n++; }
                  else if (msg.which == KEY_C) { seqman.sub_n--; }
                  else if (msg.which == KEY_F) { seqman.sub_n++; }
                  else if (msg.which == KEY_V) { seqman.add_n--; }
                  else if (msg.which == KEY_G) { seqman.add_n++; }
                  else if (msg.which == KEY_B) { seqman.extr_n--; }
                  else if (msg.which == KEY_H) { seqman.extr_n++; }
                  else if (msg.which == KEY_R) {
                    if (seqman.should_rev) { 0 => seqman.should_rev; }
                    else { 1 => seqman.should_rev; }
                  }
                  // Apply all changes to new rehearsal
                  if (msg.which == KEY_ENTER) {  // TODO: have enter localized to specific keyboard mode
                    REHEARSAL++;

                    // apply changes from all keyboard modes
                    seqman.manipulate();

                    // reset state
                    seqman.reset();

                    <<< "--------------------------------------------" >>>;
                    <<< "|                                          |" >>>;
                    <<< " |                REHEARSAL", REHEARSAL, "              |" >>>;
                    <<< "|                                          |" >>>;
                    <<< "--------------------------------------------" >>>;
                  }
                  seqman.print_state();
                } else if (ACTIVE_MODE == DRONE_MODE) {
                  if (msg.which == KEY_LEFT) {
                      drone_idx--;
                  } else if (msg.which == KEY_RIGHT) {
                      drone_idx++;
                  }

                  drone_idx % NUM_DRONES => drone_idx;
                  local_player.drone_grans[drone_idx] @=> Granulator @ g;

                  if (msg.which == KEY_UP) {
                    if (g.MUTED) { continue; }  
                    .1 + g.lisa.gain() => g.lisa.gain;
                  } else if (msg.which == KEY_DOWN) {
                    if (g.MUTED) { continue; }
                    if (g.lisa.gain() < .11){
                      0 => g.lisa.gain;
                    } else {
                      g.lisa.gain() - .1 => g.lisa.gain;
                    }
                  } else if (msg.which == KEY_LB) {
                    1 -=> g.GRAIN_PLAY_RATE_OFF;
                  } else if (msg.which == KEY_RB) {
                    1 +=> g.GRAIN_PLAY_RATE_OFF;
                  } else if (msg.which == KEY_R) { // randomize pitch
                    seqman.scale[Math.random2(0, seqman.scale.cap()-1)] => float sd;
                    while (Std.fabs(sd - g.GRAIN_SCALE_DEG) < .001) {  // gaurantee new note
                      seqman.scale[Math.random2(0, seqman.scale.cap()-1)] => sd;
                    }
                    sd => g.GRAIN_SCALE_DEG;
                  } else if (msg.which == KEY_M) {
                    if (g.MUTED) {
                      spork ~ g.unmute(2::second);  
                    } else {
                      spork ~ g.mute(2::second);
                    }
                  }
                  print_voices(DRONE_TYPE);
                } else if (ACTIVE_MODE == SEQ_VOICE_MODE) {
                  if (msg.which == KEY_LEFT) {
                      seq_idx--;
                      if (seq_idx < 0) { NUM_SEQS - 1 => seq_idx; }
                  } else if (msg.which == KEY_RIGHT) {
                      seq_idx++;
                  }

                  seq_idx % NUM_SEQS => seq_idx;
                  <<< seq_idx >>>;
                  local_player.seq_grans[seq_idx] @=> Granulator @ g;

                  // For now, all sequencer voice changes are multicast GLOBAL
                  if (msg.which == KEY_UP) {
                      change_seq_gain(seq_idx, .1);
                  } else if (msg.which == KEY_DOWN) {
                      change_seq_gain(seq_idx, -.1);
                  } else if (msg.which == KEY_LB) {
                      change_seq_octave(seq_idx, -1.0);
                  } else if (msg.which == KEY_RB) {
                      change_seq_octave(seq_idx, 1.0);
                  } else if (msg.which == KEY_COMMA) {
                      change_seq_scale_deg(seq_idx, -1);
                  } else if (msg.which == KEY_PERIOD) {
                      change_seq_scale_deg(seq_idx, 1);
                  } else if (msg.which == KEY_M) {
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
                      // TODO: replace current sequence with notes exclusive from new scale
                    }
                    print_scales();
                }
            }
        }
    }
}