Bowed a => NRev re => PitShift pit => pan2 p =>  dac;
Bowed b => NRev rev => PitShift pits => pan2 q => dac;
Bowed c => NRev reve => PitShift pitsh => pan2 r => dac;
Bowed d => NRev rever => PitShift pitshi => pan2 s => dac;
Bowed e => NRev reverb => PitShift pitshif => pan2 t => dac;

a.help();

-1 => p.pan;
-.5 => r.pan;
0 => t.pan;
.5 => s.pan;
1 => q.pan;

[0,1,2,3,4,5,6,7,8,9,10,11,12] @=> int scale[]; //sequence data

for (0=>int i; 10; i++) 
{
Std.rand2f (.5, 1 ) => re.mix;
Std.rand2f (.5, 1 ) => rev.mix;
Std.rand2f (.5, 1 ) => reve.mix;
Std.rand2f (.5, 1 ) => rever.mix;
Std.rand2f (.5, 1 ) => reverb.mix;
    <<< "---", "" >>>;
    <<< "i:", i >>>;  

    Std.rand2f( 0, .2 ) => a.vibratoFreq;
    Std.rand2f( 0, .2 ) => a.vibratoGain;
    Std.rand2f( 0, .2 ) => b.vibratoFreq;
    Std.rand2f( 0, .2 ) => b.vibratoGain;
    Std.rand2f( 0, .2 ) => c.vibratoFreq;
    Std.rand2f( 0, .2 ) => c.vibratoGain;
    Std.rand2f( 0, .2 ) => d.vibratoFreq;
    Std.rand2f( 0, .2 ) => d.vibratoGain;
    Std.rand2f( 0, .2 ) => e.vibratoFreq;
    Std.rand2f( 0, .2 ) => e.vibratoGain;
  Std.mtof( 48 + scale[ Std.rand2 (0,12) ] ) => a.freq => float ass; //set the note
  Std.mtof( 48 + scale[ Std.rand2 (0,12) ] ) => b.freq => float bass;//set the note
  Std.mtof( 48 + scale[ Std.rand2 (0,12) ] ) => c.freq => float cash; //set the note
  Std.mtof( 48 + scale[ Std.rand2 (0,12) ] ) => d.freq => float dash; //set the note
  Std.mtof( 48 + scale[ Std.rand2 (0,12) ] ) => e.freq => float er; //set the note
      // print
    <<< "---", "" >>>;
    <<< "a:", a.freq() >>>;

    
  1 => a.noteOn;
  if (i > 2) 1 => b.noteOn;
  if (i > 4) .5 => c.noteOn;
  if (i > 6) .5 => d.noteOn;
  if (i > 8) 1 => e.noteOn;
  
  Std.rand2f (0,.9) => float num;
  if (num < .3) std.rand2f(8,12)::second => now; //compute audio  
  if (num > .6) std.rand2f(4,8)::second => now; //compute audio
  else bass => a.freq;
  Std.rand2f (0,.9) => float numb;
  if (numb < .3) cash => b.freq;
  if (numb > .6) dash => c.freq;
  else er => d.freq;

} 
