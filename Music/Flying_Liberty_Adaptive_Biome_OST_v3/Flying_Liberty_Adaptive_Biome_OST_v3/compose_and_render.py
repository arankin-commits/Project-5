#!/usr/bin/env python3
"""Flying Liberty Vol. 3: original adaptive steampunk music arrangements.
Uses local TimGM6mb SoundFont (not distributed) via libfluidsynth, MIDI exported with pretty_midi.
Tracks contain a deliberately related rising minor seventh leitmotif but have distinct meters/texture.
All stems are full-length loop-aligned and can be crossfaded in game.
"""
import os, sys, math, json, ctypes, subprocess, time
from collections import defaultdict
from pathlib import Path
import numpy as np, soundfile as sf, pretty_midi
from scipy.signal import lfilter

OUT = Path(__file__).parent
SOUNDFONT='/usr/share/sounds/sf2/TimGM6mb.sf2'
SR=32000  # ample for sampled GM timbres, practical for game file size
rng=np.random.default_rng(118)

# GM programs (0-indexed)
P={
 'piano':0,'harpsichord':6,'celesta':8,'music_box':10,'vibes':11,
 'organ':19,'accordion':21,'nylon_guitar':24,'pizz':45,'strings':48,'slow_strings':49,
 'cello':42,'contrabass':43,'brass_section':61,'trombone':57,'horn':60,
 'bassoon':70,'clarinet':71,'oboe':68,'english_horn':69,'flute':73,'bass_clarinet':71,
 'choir':52,'synth_pad':89,'timpani':47,'woodblock':115,'tubular_bells':14
}

# (root in semitones from C, chord tones offsets rooted at MIDI pitch class, bass MIDI note)
TRACKS={
 'Maintenance':{
  'slug':'01_Maintenance_Clockwork_Service_Reimagined', 'title':'Clockwork Service — The Quiet Mechanism',
  'bpm':102,'meter':(3,4),'bars':40,'tonic':62,'key':'D minor','texture':'High, delicate music-box/flute and pizzicato strings. Three-step clockwork waltz.',
  'chords':[(38,[0,3,7,10,14]),(34,[0,4,7,11]),(31,[0,3,7,10,14]),(33,[0,4,7,10,13]),(38,[0,3,7,10,14]),(41,[0,4,7,11]),(34,[0,4,7,11]),(33,[0,4,7,10,13])],
  'patterns':[0,2,4,7,4,2], # D F A C A F -- leitmotif (relative)
  'programs':{'foundation':['slow_strings','cello'], 'motif':['flute','celesta','english_horn'], 'pulse':['pizz','harpsichord'], 'combat':['horn','strings']},
  'desc':'3/4 waltz • airy upper-register motif; ticking and plucked mechanisms; combat adds urgent low strings and horns'
 },
 'Factory':{
  'slug':'02_Factory_Iron_March_Reimagined', 'title':'Iron March — Piston Assembly',
  'bpm':136,'meter':(4,4),'bars':40,'tonic':64,'key':'E minor','texture':'Grounded low-brass/staccato strings, hard march beat, synchronized industrial hits.',
  'chords':[(40,[0,3,7,10,14]),(43,[0,4,7,11]),(36,[0,4,7,11]),(35,[0,4,8,11,13]),(40,[0,3,7,10]),(36,[0,4,7,11]),(33,[0,3,7,10]),(35,[0,4,8,11,13])],
  'patterns':[0,2,4,7,4,2],
  'programs':{'foundation':['cello','strings'], 'motif':['trombone','brass_section'], 'pulse':['pizz','organ'], 'combat':['brass_section','trombone']},
  'desc':'4/4 industrial march • compressed low-register motif and jagged syncopation; combat adds pounding brass and percussion'
 },
 'Toxin_Refinery':{
  'slug':'03_Toxin_Refinery_Verdigris_Depths_Reimagined', 'title':'Verdigris Depths — Poisoned Current',
  'bpm':90,'meter':(5,4),'bars':24,'tonic':61,'key':'C-sharp minor','texture':'Suspended glassy vibraphone, eerie oboe and bass clarinet, asymmetrical five-step pulse.',
  'chords':[(37,[0,3,7,11,14]),(37,[0,1,3,7,10]),(33,[0,4,7,11]),(32,[0,4,7,10,13]),(30,[0,3,7,10,14]),(38,[0,4,7,11,18]),(35,[0,3,7,10]),(32,[0,4,8,10,13])],
  'patterns':[0,2,4,7,4,2],
  'programs':{'foundation':['slow_strings','bassoon'], 'motif':['oboe','vibes','clarinet'], 'pulse':['pizz','harpsichord'], 'combat':['bassoon','strings']},
  'desc':'5/4 lurching pulse • sparse, high, questioning motif and uneasy chromatic harmony; combat adds distorted-feeling low clusters'
 }
}

# Notes: explicit beat-domain pitches, velocities, duration. Tracks are freely modifiable via script.
class Part:
 def __init__(self,programs):
  self.programs=programs;self.notes=[];self.drums=[]
 def note(self,inst,pitch,beat,duration,vel=90):
  if duration<=0:return
  self.notes.append((inst,int(np.clip(pitch,0,127)),float(beat),float(duration),int(np.clip(vel,1,127))))
 def chord(self,inst,pitches,beat,duration,vel=85):
  for j,p in enumerate(pitches):self.note(inst,p,beat+j*.009,duration,vel-2*j)
 def drum(self,pitch,beat,duration=.10,vel=88):
  self.drums.append((int(pitch),float(beat),float(duration),int(vel)))

# Note-specific pitch bend out of scope; true original 3D spatial effects can be layered in Godot.
def arrange(name,c):
 nbeats=c['meter'][0]; nbar=c['bars']; total=nbar*nbeats
 foundation=Part(c['programs']['foundation']);motif=Part(c['programs']['motif']);pulse=Part(c['programs']['pulse']);combat=Part(c['programs']['combat']);parts={'Foundation':foundation,'Motif':motif,'Pulse':pulse,'Combat':combat}
 for bar in range(nbar):
  beat=bar*nbeats; root, intervals=c['chords'][bar%8]; degrees=intervals
  # Bass and diatonic sustaining foundation. Consistent harmonic progression across stems.
  if name=='Maintenance':
   foundation.note(1, root-2, beat, nbeats*.88, 70)
   foundation.chord(0, [root+12+v for v in degrees[1:4]], beat+.05,nbeats*.87, 55)
   if bar%2==1:foundation.note(1,root+7,beat+2.1,.67,55)
   # Sparse, weightless celesta punctuation
   if bar%4==1:motif.note(1,root+36+degrees[2],beat+2.0,.65,68)
   # Waltz: BOOM chick chick (pizzicato + harpsichord ticking)
   pulse.note(0,root+12,beat,.38,83)
   pulse.note(0,root+24+degrees[1],beat+1,.24,70)
   pulse.note(0,root+24+degrees[2],beat+2,.24,70)
   for k in range(6):
    pulse.note(1,root+36+([0,7,3,7,4,7][k]),beat+k/2,.12,48+(5 if k%3==0 else 0))
   pulse.drum(42,beat,.075,40);pulse.drum(37,beat+1,.07,32);pulse.drum(37,beat+2,.07,36)
   # Combat: pointed counter-rhythm in low strings and horns, within same waltz.
   combat.note(0, root+12,beat+.05,.47,100)
   combat.note(0, root+19,beat+1.5,.44,92)
   for k in [0,.75,1.5,2.25]:combat.note(1,root+24+degrees[(int(k*2)+1)%len(degrees)],beat+k,.31,85)
   combat.drum(36,beat,.13,105);combat.drum(38,beat+2,.1,83)
  elif name=='Factory':
   foundation.note(0,root-12,beat,.9,86)
   foundation.note(0,root-5,beat+2,.9,82)
   foundation.chord(1,[root+12+v for v in degrees[1:4]],beat+.03,nbeats*.89,56)
   # Clockwork gears: riff uses precisely spaced syncopation but no random percussive sounds.
   for k,p in enumerate([0,7,3,7,0,7,10,7]):
    pulse.note(0,root+12+p,beat+k*.5,.28,79+(6 if k in (0,3,6) else 0))
   pulse.note(1,root+12,beat,1.0,61);pulse.note(1,root+7,beat+2,1,61)
   pulse.drum(36,beat,.12,108);pulse.drum(38,beat+1,.12,94)
   pulse.drum(36,beat+2,.12,103);pulse.drum(38,beat+3,.12,99)
   for k in range(8): pulse.drum(42,beat+k*.5,.08,44+(7 if k%2==0 else 0))
   # Combat reinforced bass, aggressive horn stabs and fills.
   for k in [0,1.5,2.5,3.5]:combat.chord(0,[root+24+v for v in degrees[:3]],beat+k,.28,100)
   combat.note(1,root+19,beat+1.0,.55,95);combat.note(1,root+24,beat+3,.45,98)
   combat.drum(41,beat,.14,100);combat.drum(45,beat+2,.12,95)
   combat.drum(49,beat+3.5,.13,75)
  else: # 5/4 toxin
   foundation.note(1,root-12,beat,2.3,70)
   foundation.note(1,root-5,beat+3.05,1.4,60)
   # minor ninth and occasional b2 create uneasy pressure at the harmonic layer
   foundation.chord(0,[root+12+v for v in degrees[1:5]],beat+.07, nbeats*.87,53)
   pulse.note(0,root+12,beat,.3,61)
   pulse.note(0,root+19,beat+2.5,.28,63)
   pulse.note(0,root+12+degrees[1],beat+3.5,.28,60)
   for k in range(5):
    if k in (0,2,4):pulse.note(1,root+24+[0,7,11,3,1][k],beat+k+.04,.13,45)
   pulse.drum(36,beat,.15,57);pulse.drum(42,beat+2.5,.08,42);pulse.drum(39,beat+4,.09,47)
   # Combat: low uneasy ostinato plus sharper half-beat attacks in 5/4
   for k in range(5):combat.note(1,root+12+([0,7,1,10,3][k]),beat+k,.54,79)
   if bar%2==0:combat.chord(0,[root+12,root+15,root+19,root+25],beat+1.48,1.9,83)
   combat.drum(36,beat,.12,88);combat.drum(41,beat+2,.13,84);combat.drum(38,beat+4,.11,78)
  # Cohesive six-note leitmotif: [tonic, min3, fifth, min7, fifth, min3].
  # Each biome keeps the same INTERVAL CONTOUR but alters spacing, register, voicing.
  pat=c['patterns'];offsets=[(0,3,7,10,7,3)[i] for i in range(6)]
  if name=='Maintenance':
   # one high airy call every two bars, waltz response in clarinet-esque woodwind.
   if bar%2==0:
    for j,k in enumerate([0,.5,1,1.55,2.07,2.55]):
     motif.note(0,c['tonic']+12+offsets[j]+(12 if bar%8==4 else 0),beat+k,[.37,.31,.43,.3,.32,.37][j], 78+(bar//8)%3*2)
   else:
    for j,(k,idx) in enumerate(zip([.25,1.16,2.2],[0,2,4])):
     motif.note(2,c['tonic']+offsets[idx]-2,beat+k,.43,58)
  elif name=='Factory':
   if bar%2==0:
    rhythm=[0,.5,1.5,2,3,3.5] # clipped triplet-like syncopated phrase in duple meter
    for j,k in enumerate(rhythm):motif.note(0,c['tonic']-12+offsets[j],beat+k,.31+(0.16 if j in [0,3] else 0),95)
   else:
    for j,k in enumerate([.0,1.25,2.5,3.0]):
     motif.note(1,c['tonic']+([0,3,7,10][j]),beat+k,.46,78)
  else:
   if bar%2==0:
    for j,k in enumerate([.12,.95,2.0,3.28,4.02,4.65]):
     motif.note(0,c['tonic']+12+offsets[j]+(1 if (bar%8)==2 and j==3 else 0),beat+k,.34 if j%2 else .63,76)
   else:
    for j,k in enumerate([.12,1.97,3.4]):
     motif.note(1,c['tonic']+24+([7,3,0][j]),beat+k,.85,60)
    # whispers in low register via clarinet
    if bar%4==3:motif.note(2,c['tonic']-12+1,beat+4,.85,43)
 # Print check: no event beyond track end. Leave small note release gap to ensure repeatable loop.
 for part in parts.values():
  for i,p,b,d,v in part.notes:
   if b+d>total+.02:print('WARN OVERRUN',name,b,d,total)
 return parts

# FluidSynth ctypes facade, single synth per stem, no generated sounds unrelated to melody.
fl=ctypes.CDLL('libfluidsynth.so.3')
fl.new_fluid_settings.restype=ctypes.c_void_p
fl.fluid_settings_setnum.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_double]
fl.fluid_settings_setint.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int]
fl.new_fluid_synth.argtypes=[ctypes.c_void_p];fl.new_fluid_synth.restype=ctypes.c_void_p
fl.fluid_synth_sfload.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int];fl.fluid_synth_sfload.restype=ctypes.c_int
fl.fluid_synth_program_select.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_int]
fl.fluid_synth_noteon.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int]
fl.fluid_synth_noteoff.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int]
fl.fluid_synth_write_float.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_void_p,ctypes.c_int,ctypes.c_int]
fl.delete_fluid_synth.argtypes=[ctypes.c_void_p]; fl.delete_fluid_settings.argtypes=[ctypes.c_void_p]

def fluidsynth_render(c,part):
 nbeats=c['meter'][0];total_beats=c['bars']*nbeats; sec_per_beat=60/c['bpm']
 frames_per_loop=round(total_beats*sec_per_beat*SR)
 settings=fl.new_fluid_settings()
 fl.fluid_settings_setnum(settings,b'synth.sample-rate',float(SR))
 fl.fluid_settings_setnum(settings,b'synth.gain',0.6)
 fl.fluid_settings_setint(settings,b'synth.polyphony',192)
 fl.fluid_settings_setint(settings,b'synth.reverb.active',0)
 fl.fluid_settings_setint(settings,b'synth.chorus.active',0)
 synth=fl.new_fluid_synth(settings)
 sfid=fl.fluid_synth_sfload(synth,SOUNDFONT.encode('utf8'),1)
 if sfid<0:raise RuntimeError('SoundFont failed to load')
 programs=part.programs
 for i,ins in enumerate(programs):fl.fluid_synth_program_select(synth,i,sfid,0,P[ins])
 fl.fluid_synth_program_select(synth,9,sfid,128,0)
 ev=[]
 for chan,pitch,start,dur,vel in part.notes:
  for lap in range(2):
   b=lap*total_beats
   ev.append((round((start+b)*sec_per_beat*SR),1,chan,pitch,vel))
   ev.append((round((start+dur+b)*sec_per_beat*SR),0,chan,pitch,0))
 for pitch,start,dur,vel in part.drums:
  for lap in range(2):
   b=lap*total_beats
   ev.append((round((start+b)*sec_per_beat*SR),1,9,pitch,vel))
   ev.append((round((start+dur+b)*sec_per_beat*SR),0,9,pitch,0))
 ev.sort(key=lambda x:(x[0],x[1]))
 # render from 0 to 2*loop frames, discard first to obtain steady-state tail envelope
 result=np.empty((frames_per_loop,2),dtype=np.float32)
 cursor=0
 def render_chunk(count,save):
  nonlocal cursor
  if count<=0:return
  l=np.empty(count,dtype=np.float32);r=np.empty(count,dtype=np.float32)
  fl.fluid_synth_write_float(synth,count,l.ctypes.data,0,1,r.ctypes.data,0,1)
  if save:
   start=max(cursor,frames_per_loop)
   end=min(cursor+count,frames_per_loop*2)
   if end>start:
    src=start-cursor;dst=start-frames_per_loop;length=end-start
    result[dst:dst+length,0]=l[src:src+length]
    result[dst:dst+length,1]=r[src:src+length]
  cursor+=count
 for sample,type_,chan,pitch,vel in ev:
  if sample>2*frames_per_loop:break
  render_chunk(sample-cursor,True)
  if type_:fl.fluid_synth_noteon(synth,chan,pitch,vel)
  else:fl.fluid_synth_noteoff(synth,chan,pitch)
 render_chunk(frames_per_loop*2-cursor,True)
 fl.delete_fluid_synth(synth);fl.delete_fluid_settings(settings)
 # Light circular reverb/room reflection. Wrapping explicitly preserves exact loop length.
 for delay_sec,gain in [(0.137,.07),(0.223,.04)]:
  d=int(SR*delay_sec)
  result+=(np.roll(result,d,axis=0)*gain)
 return result

def midi_for(c,partlist,path):
 m=pretty_midi.PrettyMIDI(initial_tempo=c['bpm'])
 m.time_signature_changes=[pretty_midi.TimeSignature(c['meter'][0],c['meter'][1],0)]
 for pname,part in partlist:
  for i,ins in enumerate(part.programs):
   inst=pretty_midi.Instrument(program=P[ins],name=pname+'_'+ins)
   for j,p,b,d,v in part.notes:
    if i==j:
     start=b*60/c['bpm'];end=(b+d)*60/c['bpm']
     inst.notes.append(pretty_midi.Note(v,p,start,end))
   if inst.notes:m.instruments.append(inst)
  if part.drums:
   inst=pretty_midi.Instrument(program=0,is_drum=True,name=pname+'_Percussion')
   for p,b,d,v in part.drums:inst.notes.append(pretty_midi.Note(v,p,b*60/c['bpm'],(b+d)*60/c['bpm']))
   m.instruments.append(inst)
 m.write(str(path))

def encode_audio(path,wav,codec):
 tmp=str(path)+'.raw'
 wav.astype('float32').tofile(tmp)
 try:
  cmd=['ffmpeg','-hide_banner','-loglevel','error','-y','-f','f32le','-ar',str(SR),'-ac','2','-i',tmp]
  if codec=='ogg':cmd+=['-codec:a','libvorbis','-q:a','5']
  elif codec=='mp3':cmd+=['-codec:a','libmp3lame','-b:a','192k']
  else:raise ValueError(codec)
  subprocess.run(cmd+[str(path)],check=True)
 finally:
  os.remove(tmp)

def mp3(path,wav):encode_audio(path,wav,'mp3')
def ogg(path,wav):encode_audio(path,wav,'ogg')

def limiter(y,thr=.92):
 peak=np.max(np.abs(y))
 if peak>thr:y=y*(thr/peak)
 return y.astype('float32')

def rms(x):return float(np.sqrt(np.mean(x**2)))

MANIFEST={'title':'Flying Liberty — Adaptive Biome OST v3','copyright':'Original compositions; audio rendered via TimGM6mb third-party sampled GM SoundFont (not included). Verify SoundFont license for redistribution.','leitmotif':{'intervals_semitones':[0,3,7,10,7,3],'text':'Minor tonic, minor third, perfect fifth, minor seventh, perfect fifth, minor third; transformed by meter, rhythm, register, instrumentation and harmonization.'},'tracks':[]}
all_preview=[]
for name,c in TRACKS.items():
 if len(sys.argv)>1 and name!=sys.argv[1]:continue
 t0=time.time();print('START',name,flush=True)
 parts=arrange(name,c)
 trackdir=OUT/name;trackdir.mkdir(exist_ok=True)
 length_sec=c['bars']*c['meter'][0]*60/c['bpm'];nsample=round(length_sec*SR)
 wavs={}
 target_rms={'Foundation':.048,'Motif':.047,'Pulse':.031,'Combat':.052}
 for label,part in parts.items():
  print(' render',label,'notes',len(part.notes),'drums',len(part.drums),flush=True)
  audio=fluidsynth_render(c,part)
  if len(audio)!=nsample:raise RuntimeError('Wrong samples')
  gain=min(9.0,target_rms[label]/(rms(audio)+1e-10))
  audio=(audio*gain).astype(np.float32)
  audio=limiter(audio,.77)
  wavs[label]=audio
  ogg(trackdir/(f'{label}.ogg'),audio)
  midi_for(c,[(label,part)],OUT/'MIDI'/(name+'_'+label+'.mid'))
  del audio
 # Two full, loopable mixes prepared using the SAME stem phases. Combat is vertical remixing, no re-timing.
 exploration=limiter(wavs['Foundation']*.78+wavs['Motif']*.9+wavs['Pulse']*.42,.91)
 combatmix=limiter(wavs['Foundation']*.85+wavs['Motif']*.88+wavs['Pulse']*.98+wavs['Combat']*.95,.92)
 ogg(trackdir/'Exploration_Loop.ogg',exploration)
 ogg(trackdir/'Combat_Loop.ogg',combatmix)
 mp3(trackdir/'Exploration_Preview.mp3',exploration)
 mp3(trackdir/'Combat_Preview.mp3',combatmix)
 midi_for(c,list(parts.items()),OUT/'MIDI'/(name+'_FULL.mid'))
 # 32-second demo: 0-12 exploration, 12-20 escalating, 20-32 combat.
 demonstration=np.zeros((SR*32,2),dtype='float32')
 for sec in range(32):
  begin=sec*SR;end=(sec+1)*SR
  q=0 if sec<12 else (sec-12)/8 if sec<20 else 1
  demonstration[begin:end]=exploration[begin:end]*(1-q)+combatmix[begin:end]*q
 mp3(trackdir/'Dynamic_Mix_Demo.mp3',demonstration)
 all_preview.append(demonstration[:12*SR])
 # seam checks: transition (end-last) not necessarily zero but should stay low relative to peak; release tails of periodic rendering phase.
 seam=max(abs(float(wavs[label][-1,0]-wavs[label][0,0])) for label in wavs)
 MANIFEST['tracks'].append({'biome':name,'title':c['title'],'key':c['key'],'bpm':c['bpm'],'meter':f"{c['meter'][0]}/{c['meter'][1]}",'bars':c['bars'],'duration_seconds':round(length_sec,3),'sample_rate':SR,'samples_per_stem':nsample,'stems':['Foundation','Motif','Pulse','Combat'],'description':c['desc'],'exploration_stem_mix':{'Foundation':.78,'Motif':.9,'Pulse':.42,'Combat':0},'combat_stem_mix':{'Foundation':.85,'Motif':.88,'Pulse':.98,'Combat':.95},'peak_seam_discontinuity':round(seam,5)})
 print('DONE',name,'secs',round(time.time()-t0,1),'duration',round(length_sec,2),'seam',round(seam,3),flush=True)
 # Save memory for next track
 del parts,wavs,exploration,combatmix,demonstration

if len(sys.argv)==1:
 # 3-part sampler with .65-second breath between distinct biome themes.
 preview=[]
 for i,p in enumerate(all_preview):
  if i:preview.append(np.zeros((int(SR*.65),2),dtype=np.float32))
  preview.append(p)
 mp3(OUT/'Previews'/'Three_Biome_Sampler.mp3',np.concatenate(preview))
(OUT/'track_manifest.json').write_text(json.dumps(MANIFEST,indent=2))
print('ALL COMPLETE',flush=True)
