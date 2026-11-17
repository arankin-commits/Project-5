#!/usr/bin/env python3
"""Flying Liberty: 16 ORIGINAL historically-informed and New Age lobby instrumentals.
16 independently arranged scores with a shared six-note melodic contour, four
synchronized stems each, MIDI and Godot-friendly OGG export. No borrowed melodies.
Prerequisites: numpy, pretty_midi, libfluidsynth, ffmpeg, TimGM6mb.sf2.
"""
import os, sys, math, time, json, ctypes, subprocess, hashlib
from pathlib import Path
import numpy as np
import pretty_midi
ROOT = Path(__file__).resolve().parent
AUDIO=ROOT/'Audio'; MIDI=ROOT/'MIDI'; PREV=ROOT/'Previews'
for p in (AUDIO,MIDI,PREV): p.mkdir(exist_ok=True)
SR=24000
SOUNDFONT='/usr/share/sounds/sf2/TimGM6mb.sf2'
P={'piano':0,'bright_piano':1,'elec_piano':2,'harpsichord':6,'celesta':8,'music_box':10,
   'vibraphone':11,'marimba':12,'tubular':14,'reed_organ':20,'organ':19,'accordion':21,
   'nylon_guitar':24,'steel_guitar':25,'bass':32,'violin':40,'viola':41,'cello':42,
   'contrabass':43,'pizz':45,'harp':46,'timpani':47,'strings':48,'slow_strings':49,
   'choir':52,'voice':53,'trumpet':56,'trombone':57,'tuba':58,'horn':60,'brass':61,
   'oboe':68,'english_horn':69,'bassoon':70,'clarinet':71,'flute':73,'recorder':74,
   'woodblock':115,'warm_pad':89,'halo_pad':94,'sweep_pad':95,'bowed_pad':92,
   'synth_bass':38,'church_bells':14}
MODES={
'major':[0,2,4,5,7,9,11], 'natural_minor':[0,2,3,5,7,8,10],
'dorian':[0,2,3,5,7,9,10], 'mixolydian':[0,2,4,5,7,9,10],
'lydian':[0,2,4,6,7,9,11], 'phrygian':[0,1,3,5,7,8,10],
}
# Four independent stems per track: Ground, Theme, Counterpoint, Atmosphere.
# 'mel' and 'cp' select fundamentally different instrument combinations, registers,
# and note-density. Rhythmic architecture and harmonic progressions vary by track.
TRACKS=[
 # historically informed Renaissance + Victorian parlour fusion
 dict(id=1,group='Classical Renaissance x Victorian',name='Copper Hearth',slug='01_Copper_Hearth',key='G',tonic=55,mode='major',bpm=96,meter='3/4',bars=32,
      progression=[0,3,4,0,5,1,4,0],parts=[['piano','cello'],['violin','flute'],['clarinet','harp'],['reed_organ','music_box']],style='waltz',register=0,seed=101,
      idea='Warm Victorian parlour waltz with imitation between violin and flute; the ship feels lived-in.'),
 dict(id=2,group='Classical Renaissance x Victorian',name='Scribes of the Air',slug='02_Scribes_of_the_Air',key='D',tonic=50,mode='dorian',bpm=90,meter='4/4',bars=24,
      progression=[0,6,3,0,4,3,6,0],parts=[['reed_organ','cello'],['recorder','violin'],['clarinet','nylon_guitar'],['harpsichord','tubular']],style='canon',register=2,seed=102,
      idea='Dorian modal counterpoint; recorder and violin answer each other over a reed organ.'),
 dict(id=3,group='Classical Renaissance x Victorian',name='Parlour Above the Clouds',slug='03_Parlour_Above_the_Clouds',key='F',tonic=53,mode='major',bpm=84,meter='6/8',bars=32,
      progression=[0,4,5,3,1,4,0,0],parts=[['harp','bass'],['flute','violin'],['nylon_guitar','clarinet'],['piano','celesta']],style='siciliana',register=5,seed=103,
      idea='Lyrical 6/8, alternating harp and parlour guitar with woodwind ornament.'),
 dict(id=4,group='Classical Renaissance x Victorian',name="Captain's Quadrille",slug='04_Captains_Quadrille',key='C',tonic=48,mode='major',bpm=118,meter='2/4',bars=52,
      progression=[0,4,0,3,5,1,4,0],parts=[['accordion','tuba'],['trumpet','clarinet'],['flute','violin'],['pizz','woodblock']],style='march',register=-5,seed=104,
      idea='Nimble 2/4 ballroom march with cornet-like trumpet and concertina.'),
 dict(id=5,group='Classical Renaissance x Victorian',name='Clockwork Pavane',slug='05_Clockwork_Pavane',key='A',tonic=57,mode='natural_minor',bpm=76,meter='4/4',bars=24,
      progression=[0,6,3,0,5,4,6,0],parts=[['reed_organ','cello'],['oboe','viola'],['harp','recorder'],['tubular','slow_strings']],style='pavane',register=-5,seed=105,
      idea='Slow ceremonial Renaissance-inspired pavane, suspended organ and imitative reed voices.'),
 dict(id=6,group='Classical Renaissance x Victorian',name="Father's Photograph",slug='06_Fathers_Photograph',key='E',tonic=52,mode='natural_minor',bpm=72,meter='3/4',bars=30,
      progression=[0,3,6,4,0,5,4,0],parts=[['piano','cello'],['violin','english_horn'],['harp','clarinet'],['reed_organ','music_box']],style='lament',register=-2,seed=106,
      idea='Intimate elegiac piano-and-cello miniature for the CEO son’s family storyline.'),
 dict(id=7,group='Classical Renaissance x Victorian',name='Brass and Lace',slug='07_Brass_and_Lace',key='A',tonic=57,mode='dorian',bpm=112,meter='6/8',bars=36,
      progression=[0,4,3,0,6,3,4,0],parts=[['nylon_guitar','bass'],['accordion','violin'],['flute','oboe'],['harpsichord','pizz']],style='galliard',register=0,seed=107,
      idea='Buoyant triple dance, plucked strings, lilting concertina, and agile contrapuntal lines.'),
 dict(id=8,group='Classical Renaissance x Victorian',name='Liberty Overture',slug='08_Liberty_Overture',key='Bb',tonic=58,mode='major',bpm=92,meter='4/4',bars=28,
      progression=[0,3,4,0,5,1,4,0],parts=[['strings','contrabass'],['horn','violin'],['flute','clarinet'],['brass','timpani']],style='overture',register=-2,seed=108,
      idea='Ceremonial flying-ship theme: warm horn lines, string countermelody, and measured brass.'),
 # New-age / neo-Renaissance, historically evocative but contemporary in compositional language
 dict(id=9,group='New Age Neo-Renaissance',name='Glass Horizon',slug='09_Glass_Horizon',key='C',tonic=60,mode='lydian',bpm=68,meter='4/4',bars=22,
      progression=[0,4,1,0,5,3,4,0],parts=[['warm_pad','bass'],['piano','flute'],['harp','vibraphone'],['halo_pad','celesta']],style='ambient',register=7,seed=209,
      idea='Lydian open sky: repeating piano figures bloom into distant airy strings and pads.'),
 dict(id=10,group='New Age Neo-Renaissance',name='Aether Lullaby',slug='10_Aether_Lullaby',key='D',tonic=62,mode='major',bpm=76,meter='6/8',bars=34,
      progression=[0,5,3,4,0,1,3,0],parts=[['slow_strings','harp'],['flute','music_box'],['piano','vibraphone'],['warm_pad','choir']],style='float',register=3,seed=210,
      idea='A gentle suspended 6/8 wash: harp, music box, flute and distant harmonic glow.'),
 dict(id=11,group='New Age Neo-Renaissance',name='Time Between Gears',slug='11_Time_Between_Gears',key='E',tonic=52,mode='dorian',bpm=83,meter='5/4',bars=22,
      progression=[0,3,6,4,0,6,3,0],parts=[['warm_pad','cello'],['music_box','clarinet'],['marimba','harp'],['halo_pad','vibraphone']],style='five',register=5,seed=211,
      idea='Uneven 5/4 puzzle-like pulse from a repeating music-box motif with spacious modal pads.'),
 dict(id=12,group='New Age Neo-Renaissance',name='Skylight Chapel',slug='12_Skylight_Chapel',key='G',tonic=55,mode='mixolydian',bpm=64,meter='3/4',bars=24,
      progression=[0,3,6,0,4,3,6,0],parts=[['reed_organ','cello'],['flute','voice'],['harp','choir'],['halo_pad','tubular']],style='hymn',register=2,seed=212,
      idea='A meditative modal hymn texture with pump organ, harp and distant wordless choir timbre.'),
 dict(id=13,group='New Age Neo-Renaissance',name='Observatory of Dreams',slug='13_Observatory_of_Dreams',key='A',tonic=57,mode='natural_minor',bpm=88,meter='7/8',bars=30,
      progression=[0,5,3,6,0,4,5,0],parts=[['bowed_pad','bass'],['vibraphone','oboe'],['harp','clarinet'],['music_box','halo_pad']],style='seven',register=9,seed=213,
      idea='Dreamlike 7/8 grouped 3+2+2, glassy counterpoints and distant clockwork echoes.'),
 dict(id=14,group='New Age Neo-Renaissance',name='The Unsent Letter',slug='14_The_Unsent_Letter',key='E',tonic=52,mode='natural_minor',bpm=65,meter='4/4',bars=20,
      progression=[0,3,6,0,5,4,3,0],parts=[['piano','cello'],['english_horn','violin'],['harp','flute'],['slow_strings','warm_pad']],style='intimate',register=-2,seed=214,
      idea='Modern sentimental parlour echoes, with slowly shifting harmonies and low piano register.'),
 dict(id=15,group='New Age Neo-Renaissance',name='Wings Beyond Tomorrow',slug='15_Wings_Beyond_Tomorrow',key='F',tonic=53,mode='lydian',bpm=82,meter='6/8',bars=32,
      progression=[0,4,5,3,0,1,4,0],parts=[['slow_strings','bass'],['horn','flute'],['harp','piano'],['halo_pad','choir']],style='cinematic',register=0,seed=215,
      idea='Broad optimistic Lydian arcs, harp currents, warm horn, and an ascending atmospheric swell.'),
 dict(id=16,group='New Age Neo-Renaissance',name='Homeward Through Mist',slug='16_Homeward_Through_Mist',key='D',tonic=50,mode='major',bpm=72,meter='4/4',bars=24,
      progression=[0,3,5,4,0,1,4,0],parts=[['piano','bass'],['flute','cello'],['harp','clarinet'],['warm_pad','music_box']],style='return',register=5,seed=216,
      idea='Warm ambient homecoming, gently resolving the Flying Liberty motif as the sky clears.'),
]

class Part:
 def __init__(self,insts):self.insts=insts;self.notes=[]
 def add(self,i,p,b,d,v=65):
  if d > 0.03 and p>15 and p<116:
   self.notes.append((int(i),int(p),float(b),float(d),int(max(4,min(127,v)))))
 def chord(self,i,ps,b,d,v=60):
  for j,p in enumerate(ps):self.add(i,p,b+j*.011,d,v-j*3)

def meter_beats(m):
 n,d=map(int,m.split('/'));return n*4/d

def scale_pitch(c,degree,octave=0):
 scale=MODES[c['mode']]; deg=int(degree)
 o,step=divmod(deg,7)
 return c['tonic']+scale[step]+(o+octave)*12

def chords(c,idx):
 root=c['progression'][idx%len(c['progression'])]
 return [scale_pitch(c,root+k) for k in (0,2,4,6)]

def compose(c):
 rng=np.random.default_rng(c['seed']);meter=meter_beats(c['meter']);total=c['bars']*meter
 foundation=Part(c['parts'][0]);theme=Part(c['parts'][1]);counter=Part(c['parts'][2]);color=Part(c['parts'][3]);parts={'Foundation':foundation,'Theme':theme,'Counterpoint':counter,'Atmosphere':color}
 historical=c['id']<=8
 style=c['style'];scale=MODES[c['mode']]
 # Main identity: scale-degree contour (1, 2, 4, 5, 4, 2), transposed, mode-adjusted, re-timed, invertible.
 motif=(0,1,3,4,3,1)
 for bar in range(c['bars']):
  b=bar*meter; ch=chords(c,bar); root=ch[0]; bass=root-12 if root>50 else root-0
  phrase=(bar//4)%4; late=bar>=.5*c['bars'];section=bar/(c['bars']-1)
  dynamics=[.77,1.0,.9,.75][min(3,int(bar/(c['bars']/4)))];
  if style in ('lament','intimate'): dynamics*=.85
  # Bass roles are restrained for ambience and softly varied between phrases.
  foundation.add(1,bass-12 if bass>=43 else bass,b, min(meter*.9,meter-.1),int(56*dynamics))
  if style in ('ambient','float','five','seven','hymn','cinematic','return','intimate'):
   foundation.chord(0,[ch[0]+12,ch[1]+12,ch[2]+12] + ([ch[3]+12] if bar%2==0 else []),b+.02,meter*.85,int(46*dynamics))
   if bar%4==2:foundation.add(0,ch[1]+12,b+meter*.56,meter*.32,int(35*dynamics))
  elif style in ('pavane','canon','overture'):
   foundation.chord(0,[ch[0]+12,ch[1]+12,ch[2]+12],b+.02,meter*.88,int(53*dynamics))
  elif style in ('waltz','lament'):
   foundation.add(0,root+12,b,.6,int(68*dynamics))
   for t in [1,2]:foundation.chord(0,[ch[1]+12,ch[2]+12],b+t*.99,.38,int(47*dynamics))
  elif style in ('march','galliard'):
   for t in np.arange(0,meter,.5 if style=='galliard' else 1):
    foundation.add(0,ch[0]+12+(12 if int(t*2)%3==0 else 0),b+float(t),.3,int(56*dynamics))
  else:
   foundation.chord(0,ch[:3],b+.02,meter*.74,int(47*dynamics))
  # Melodic call and response; each four-bar phrase has a motif statement in bars 0-1 and an answer bars 2-3.
  if bar%4 in (0,2):
   idx=bar//4;answer=bar%4==2
   shift=[0,2,4,1,3,5,0,2][idx%8] if answer else (0 if idx%2==0 else 3)
   seq=list(motif)
   if style in ('canon','pavane','hymn') and answer:seq=list(reversed(motif))
   if style in ('lament','intimate','return') and idx%4==3:seq=[0,1,2,4,3,1]
   if style=='march': slots=np.array([0,.16,.34,.51,.76,.87])*2*meter
   elif style=='seven':slots=np.array([0,.18,.38,.53,.76,.9])*2*meter
   elif style=='five':slots=np.array([0,.13,.31,.58,.78,.87])*2*meter
   elif style=='pavane':slots=np.array([0,.18,.38,.57,.77,.89])*2*meter
   elif style=='galliard':slots=np.array([0,.20,.35,.54,.72,.88])*2*meter
   else:slots=np.array([0,.18,.37,.54,.72,.87])*2*meter
   # In a two-bar window keep last note within loop; low, mid, or high register by track.
   reg=12+c['register']
   for j,d in enumerate(seq):
    pos=b+float(slots[j]); nxt=(float(slots[j+1]) if j<5 else 2*meter)
    dur=max(.17,(nxt-float(slots[j]))*(.76 if historical else .94))
    v= int((77 if historical else 62)*dynamics) +(3 if j in (0,3) else 0)
    p=scale_pitch(c,d+shift)+reg
    theme.add(0,p,pos,min(dur,total-pos-.08),v)
    # secondary register can softly highlight selected motif notes as recorder, flute or harmonics
    if j in (0,3) and idx%2==1 and style not in ('intimate','lament'):
     theme.add(1,p-12,pos+.04,min(dur*.74,total-pos-.12),int(v*.51))
  # History style employs counterpoint/imitative phrases; new age uses more slowly breathing arpeggios.
  if historical:
   if bar%4 in (1,3):
    shift=0 if bar%4==1 else 4
    entrance=[0,1,3,4,3,1] if bar%4==1 else [4,3,1,0,1,3]
    for j,d in enumerate(entrance):
     t=(j+.2)*(meter/7)
     p=scale_pitch(c,d+shift)+ (6 if c['register']>2 else 2)
     counter.add(0,p,b+t,meter/8.1,int((52+4*(j==0))*dynamics))
     if j%3==0:counter.add(1,p-12,b+t+.13,meter/5,int(34*dynamics))
   elif bar%4==0:
    for t,j in [(meter*.42,0),(meter*.71,2)]:counter.add(1,ch[j%3]+12,b+t,meter*.20,int(40*dynamics))
  else:
   arps=[0,2,1,3,2,1,0,2] if style in ('ambient','float','cinematic','return') else [0,1,2,3,2,1,3,0]
   step=.5 if style in ('seven','five') else .75
   kk=int(meter/step)
   for k in range(kk):
    if (bar%4==3 and k%3==2):continue
    deg=arps[(k+bar%3)%len(arps)]
    pitch=ch[deg]+(12 if k%4!=0 else 0)
    counter.add(0,pitch,b+k*step,step*.77,int((45 if style not in ('seven','five') else 53)*dynamics))
   if bar%2==0:counter.add(1,ch[2]+12,b+meter*.18,meter*.64,int(28*dynamics))
  # Atmosphere layer: mechanical instrumentation with tempo-aware accents, never random noise.
  if historical:
   if style in ('march','galliard'):
    for k in range(int(meter*2)):
     color.add(0,scale_pitch(c,[0,4,2,4][k%4])+24,b+k*.5,.16,int(42*dynamics))
   elif style=='overture':
    if bar%2==0:color.chord(0,[ch[0]+12,ch[1]+12,ch[2]+12],b,1.24,int(54*dynamics))
    if bar%4==3:color.add(1,ch[0]-12,b+meter*.73,.31,int(40*dynamics))
   elif style=='pavane':
    if bar%2==0:color.add(0,ch[2]+24,b+meter*.7,1.0,int(40*dynamics))
    if bar%4==0:color.chord(1,[ch[0]+12,ch[1]+12,ch[2]+12],b+.1,meter*.8,int(31*dynamics))
   else:
    color.chord(0,[ch[0]+12,ch[1]+12,ch[2]+12],b+meter*.05,meter*.73,int(35*dynamics))
    if bar%2==0:color.add(1,ch[2]+24,b+meter*.55,meter*.22,int(42*dynamics))
  else:
   color.chord(0,[ch[0]+12,ch[1]+12,ch[2]+12],b+.03,meter*.9,int(41*dynamics))
   if (bar+phrase)%3==0:color.add(1,ch[2]+24,b+meter*.54,meter*.32,int(40*dynamics))
   if style in ('five','seven') and bar%2==0:color.add(1,ch[1]+24,b+meter*.16,meter*.3,int(37*dynamics))
 # clamp durations at total, guard phasing
 for part in parts.values():
  part.notes=[(i,p,b,min(d,total-b-.05),v) for i,p,b,d,v in part.notes if b<total-.06]
 return parts

# GM SoundFont MIDI renderer based on libfluidsynth, no external service.
lib=ctypes.CDLL('libfluidsynth.so.3')
lib.new_fluid_settings.restype=ctypes.c_void_p
lib.fluid_settings_setnum.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_double]
lib.fluid_settings_setint.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int]
lib.new_fluid_synth.argtypes=[ctypes.c_void_p];lib.new_fluid_synth.restype=ctypes.c_void_p
lib.fluid_synth_sfload.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int];lib.fluid_synth_sfload.restype=ctypes.c_int
lib.fluid_synth_program_select.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_int]
lib.fluid_synth_noteon.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int]
lib.fluid_synth_noteoff.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int]
lib.fluid_synth_write_float.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_void_p,ctypes.c_int,ctypes.c_int]
lib.delete_fluid_synth.argtypes=[ctypes.c_void_p];lib.delete_fluid_settings.argtypes=[ctypes.c_void_p]

def render(c,part):
 sec_per_beat=60/c['bpm'];nb=c['bars']*meter_beats(c['meter']);ns=round(nb*sec_per_beat*SR)
 settings=lib.new_fluid_settings()
 lib.fluid_settings_setnum(settings,b'synth.sample-rate',float(SR))
 lib.fluid_settings_setnum(settings,b'synth.gain',0.56)
 lib.fluid_settings_setint(settings,b'synth.polyphony',128)
 lib.fluid_settings_setint(settings,b'synth.reverb.active',0)
 lib.fluid_settings_setint(settings,b'synth.chorus.active',0)
 sy=lib.new_fluid_synth(settings)
 sfid=lib.fluid_synth_sfload(sy,SOUNDFONT.encode(),1)
 if sfid<0:raise RuntimeError('Could not load SoundFont')
 for i,inst in enumerate(part.insts):lib.fluid_synth_program_select(sy,i,sfid,0,P[inst])
 events=[]
 for inst,pitch,beat,dur,v in part.notes:
  for lap in [0,1]:
   events.append((round((beat+lap*nb)*sec_per_beat*SR),1,inst,pitch,v))
   events.append((round((beat+dur+lap*nb)*sec_per_beat*SR),0,inst,pitch,0))
 events.sort(key=lambda x:(x[0],x[1]));out=np.zeros((ns,2),dtype='float32');cursor=0
 def write_chunk(n):
  nonlocal cursor
  while n>0:
   take=min(n,16384)
   l=np.empty(take,dtype='float32');r=np.empty(take,dtype='float32')
   lib.fluid_synth_write_float(sy,take,l.ctypes.data,0,1,r.ctypes.data,0,1)
   a=max(cursor,ns);z=min(cursor+take,2*ns)
   if z>a:
    start=a-cursor;d=a-ns;size=z-a
    out[d:d+size,0]=l[start:start+size];out[d:d+size,1]=r[start:start+size]
   cursor+=take;n-=take
 for sample,t,chan,pitch,velocity in events:
  if sample>2*ns:break
  if sample>cursor:write_chunk(sample-cursor)
  if t:lib.fluid_synth_noteon(sy,chan,pitch,velocity)
  else:lib.fluid_synth_noteoff(sy,chan,pitch)
 if cursor<2*ns:write_chunk(2*ns-cursor)
 lib.delete_fluid_synth(sy);lib.delete_fluid_settings(settings)
 # Gentle stereo space (periodic circular reflections) keeps exported stems sample-aligned.
 reflected=.065*np.roll(out,int(.131*SR),axis=0)+.036*np.roll(out,int(.287*SR),axis=0)
 out+=reflected
 return out

def save_midi(c,parts,path):
 m=pretty_midi.PrettyMIDI(initial_tempo=c['bpm'])
 n,d=map(int,c['meter'].split('/'));m.time_signature_changes=[pretty_midi.TimeSignature(n,d,0)]
 for label,part in parts:
  for i,ins in enumerate(part.insts):
   insobj=pretty_midi.Instrument(program=P[ins],name=f'{label} - {ins}')
   for ch,p,b,dur,v in part.notes:
    if ch==i:insobj.notes.append(pretty_midi.Note(velocity=v,pitch=p,start=b*60/c['bpm'],end=(b+dur)*60/c['bpm']))
   if insobj.notes:m.instruments.append(insobj)
 m.write(str(path))

def encode(audio,path,kind):
 audio=np.ascontiguousarray(audio,dtype='float32')
 args=['ffmpeg','-hide_banner','-loglevel','error','-y','-f','f32le','-ar',str(SR),'-ac','2','-i','pipe:0']
 args+=['-c:a','libvorbis','-q:a','4'] if kind=='ogg' else ['-c:a','libmp3lame','-b:a','160k']
 # Avoid subprocess OOM: raw audio memory fed through stdin, one file at a time.
 cmd=subprocess.Popen(args+[str(path)],stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
 for off in range(0,len(audio),8192):cmd.stdin.write(audio[off:off+8192].tobytes())
 cmd.stdin.close();err=cmd.stderr.read();ret=cmd.wait()
 if ret!=0:raise RuntimeError(f'ffmpeg failed {path}: {err.decode()[:500]}')

def rms(x):return float(np.sqrt(np.mean(x*x)))
def safe(y,ceiling=.88):
 peak=float(np.max(np.abs(y)))
 if peak>ceiling:y=y*(ceiling/peak)
 return y.astype('float32')

def process_one(c):
 t0=time.time();print(f'COMPOSE {c["id"]:02d}/16 {c["name"]} | {c["meter"]} {c["bpm"]} BPM',flush=True)
 folder=AUDIO/c['slug'];folder.mkdir(exist_ok=True)
 parts=compose(c)
 save_midi(c,list(parts.items()),MIDI/(c['slug']+'_Full.mid'))
 wavs={};count=None
 levels={'Foundation':.055,'Theme':.045,'Counterpoint':.034,'Atmosphere':.029}
 for name,part in parts.items():
  wav=render(c,part)
  nr=len(wav)
  if count is not None and count!=nr:raise AssertionError('stem length mismatch')
  count=nr
  r=rms(wav)
  # Carefully avoid huge boosts of near-silent patches.
  gain=min(5.0, levels[name]/max(.0001,r))
  wav=safe(wav*gain,.68)
  wavs[name]=wav
  encode(wav,folder/(name+'.ogg'),'ogg')
  # Each stem also has editable MIDI
  save_midi(c,[(name,part)],MIDI/(c['slug']+'_'+name+'.mid'))
 # Balanced arrangement: quieter lobby with subtle texture; story moment builds naturally.
 quiet=safe(.86*wavs['Foundation']+.88*wavs['Theme']+.35*wavs['Counterpoint']+.48*wavs['Atmosphere'])
 story=safe(.86*wavs['Foundation']+.95*wavs['Theme']+.83*wavs['Counterpoint']+.88*wavs['Atmosphere'])
 encode(quiet,folder/'Quiet_Lobby_Loop.ogg','ogg')
 encode(story,folder/'Full_Story_Loop.ogg','ogg')
 encode(quiet,folder/'Listen_Quiet_Lobby.mp3','mp3')
 # 20s seamless dynamic mixing demonstration: 0-7 quiet, 7-13 upward crossfade, 13-20 full.
 n=min(int(20*SR),len(quiet))
 alpha=np.zeros(n,dtype='float32');a=int(7*SR);z=min(int(13*SR),n)
 if z>a:alpha[a:z]=np.linspace(0,1,z-a,endpoint=False)
 if z<n:alpha[z:]=1
 dem=(quiet[:n]*(1-alpha[:,None])+story[:n]*alpha[:,None]).astype('float32')
 encode(dem,folder/'Dynamic_Layer_Demo.mp3','mp3')
 del dem
 data=dict(index=c['id'],title=c['name'],group=c['group'],key=c['key']+' '+c['mode'],bpm=c['bpm'],meter=c['meter'],
   bars=c['bars'],duration_seconds=round(len(quiet)/SR,3),samples_per_stem=count,sample_rate=SR,
   instruments={key:part.insts for key,part in parts.items()},style=c['style'],concept=c['idea'],
   stems=list(parts.keys()),quiet_mix=dict(Foundation=.86,Theme=.88,Counterpoint=.35,Atmosphere=.48),
   story_mix=dict(Foundation=.86,Theme=.95,Counterpoint=.83,Atmosphere=.88),
   notes_per_stem={key:len(part.notes) for key,part in parts.items()},
   quiet_rms=round(rms(quiet),5),quiet_peak=round(float(np.max(np.abs(quiet))),5),
   duration_samples=count)
 # Only 9sec per track used in samplers, slow concat across all 16 to keep compact.
 preview=quiet[int(5*SR):int(13*SR)]
 print('  exported',count,'samples per stem',round(time.time()-t0,1),'s',flush=True)
 del parts,wavs,quiet,story
 return data,preview

if __name__=='__main__':
 chosen=[x for x in TRACKS if not len(sys.argv)>1 or str(x['id'])==sys.argv[1]]
 manifest={'title':'Flying Liberty: 16 Lobby Themes — Historical and New Age v1',
           'historical_note':'Renaissance c.1400-1600, Victorian c.1837-1901. Classical set is a deliberate fantasy fusion; New Age is modern neo-Renaissance / neo-Victorian crossover, not a historical genre.',
           'leitmotif':{'scale_degrees':[1,2,4,5,4,2], 'description':'A recurring six-note rising/falling contour transformed through mode, counterpoint, meter, key and register; all original music.'},
           'production':'Composed as individual MIDI arrangements, rendered using TimGM6mb GM sample library via libfluidsynth; the SoundFont itself is NOT included. Clear samples for commercial licensing.',
           'tracks':[]}
 previews1=[];previews2=[]
 for c in chosen:
  data,short=process_one(c);manifest['tracks'].append(data)
  if c['id']<=8:previews1.append(short)
  else:previews2.append(short)
  (ROOT/'track_manifest.json').write_text(json.dumps(manifest,indent=2))
 if len(chosen)==16:
  for name,arr in [('Classical_8_Track_Sampler.mp3',previews1),('New_Age_8_Track_Sampler.mp3',previews2)]:
   chunks=[]
   for i,a in enumerate(arr):
    if i:chunks.append(np.zeros((int(.25*SR),2),dtype='float32'))
    chunks.append(a)
   encode(np.concatenate(chunks),PREV/name,'mp3')
  print('ALL 16 TRACKS RENDERED',flush=True)
