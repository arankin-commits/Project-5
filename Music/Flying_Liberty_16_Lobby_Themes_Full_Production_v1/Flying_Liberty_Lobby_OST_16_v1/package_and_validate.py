import json, csv, zipfile, pathlib, shutil, numpy as np, soundfile as sf, html
from collections import Counter
ROOT=pathlib.Path(__file__).resolve().parent
MAN=json.loads((ROOT/'track_manifest.json').read_text())
assert len(MAN['tracks'])==16, f'expected 16 tracks but found {len(MAN["tracks"])}'
assert len(set(t['title'] for t in MAN['tracks']))==16
checks=[]
for t in MAN['tracks']:
 s=f"{t['index']:02d}_"; dirs=[p for p in (ROOT/'Audio').iterdir() if p.is_dir() and p.name.startswith(s)]
 assert len(dirs)==1,(s,dirs)
 d=dirs[0]; sr=t['sample_rate']; expected=t['samples_per_stem']
 for fn in ['Foundation.ogg','Theme.ogg','Counterpoint.ogg','Atmosphere.ogg','Quiet_Lobby_Loop.ogg','Full_Story_Loop.ogg','Listen_Quiet_Lobby.mp3','Dynamic_Layer_Demo.mp3']:
  p=d/fn; assert p.exists() and p.stat().st_size>2500,p
  info=sf.info(p)
  if fn.endswith('.ogg'):
   assert info.frames==expected,(p,info.frames,expected)
   assert info.samplerate==sr and info.channels==2
  if fn=='Quiet_Lobby_Loop.ogg':
   a, _=sf.read(p,always_2d=True);peak=float(np.max(np.abs(a)));rms=float(np.sqrt(np.mean(a*a)))
   assert .005 < rms < .3 and peak<.99,(p,rms,peak)
 checks.append((t['index'],t['title'],d.name,round(expected/sr,2),round(peak,3),round(rms,3)))
for fn in ['Classical_8_Track_Sampler.mp3','New_Age_8_Track_Sampler.mp3']:
 assert (ROOT/'Previews'/fn).exists(), fn
assert len(list((ROOT/'MIDI').glob('*.mid')))==80
# locally viewable album player
rows=[]
for t in MAN['tracks']:
 slug=next(p.name for p in (ROOT/'Audio').iterdir() if p.is_dir() and p.name.startswith(f"{t['index']:02d}_"))
 rows.append({'id':t['index'],'title':t['title'],'group':'Classical' if t['index']<=8 else 'New Age','slug':slug,'meter':t['meter'],'bpm':t['bpm'],'key':t['key'],'seconds':t['duration_seconds'],'idea':t['concept']})
css='''*{box-sizing:border-box}body{margin:0;background:#16171d;color:#eaddc7;font:15px/1.6 system-ui,Segoe UI,sans-serif}header{padding:38px 18px 24px;max-width:1100px;margin:auto}h1{font:36px Georgia,serif;color:#e1c289;margin:0}h2{font:25px Georgia,serif;color:#e1c289;margin:0 0 16px}.eyebrow{color:#a7793e;letter-spacing:.22em;font-size:12px}.sub{color:#aea7a1}.bar{border:1px solid #66513c;border-radius:16px;padding:17px;background:#212128;max-width:1100px;margin:0 auto 25px;display:grid;gap:10px}audio{width:100%}main{max-width:1100px;margin:auto;padding:5px 18px 60px}.section{margin-bottom:34px}.list{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:11px}.track{border:1px solid #4e4740;border-radius:12px;background:#26252a;padding:15px;text-align:left;color:inherit;cursor:pointer;transition:.1s}.track:hover,.track.selected{border-color:#cf9b61;background:#35302d}.track .num{color:#c39a68;font-size:12px;letter-spacing:.1em}.track strong{display:block;color:#f2e4cf;font:20px Georgia,serif}.track .meta{font-size:12px;color:#c9bbaa}.track .desc{font-size:13px;color:#9f9a93;min-height:45px;margin-top:7px}.row{display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}button.switch{background:#533e30;color:#f8dfbf;border:1px solid #9d744a;border-radius:7px;padding:7px 13px;cursor:pointer}.disclaimer{font-size:12px;color:#888}'''
src=json.dumps(rows,ensure_ascii=False)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Flying Liberty — 16 Lobby Themes</title><style>{css}</style></head><body><header><div class="eyebrow">FLYING LIBERTY · ORIGINAL GAME SCORE</div><h1>The Lobby Collection</h1><p class="sub">16 original instrumental tracks • Classical Renaissance × Victorian fantasy and modern New Age interpretations • interactive local player</p></header><div class="bar"><div class="row"><strong id="now">Select a track</strong><button class="switch" id="mode" onclick="changeMode()">Mix: Quiet Lobby</button></div><audio id="player" controls preload="none"></audio><div class="disclaimer">The player uses files inside Audio/ — keep this HTML next to the Audio folder after extracting the ZIP.</div></div><main><div class="section"><h2>Volume I — Historical Fantasy</h2><div id="classic" class="list"></div></div><div class="section"><h2>Volume II — Neo-Renaissance / New Age</h2><div id="modern" class="list"></div></div><p class="disclaimer">Original compositions. Rendered with sampled GM instruments; see README for sample-library licensing and performance limitations.</p></main><script>const tracks={src};let selected=null;let story=false;const player=document.getElementById('player');function render(){{for(const t of tracks){{const el=document.createElement('button');el.className='track';el.dataset.index=t.id;el.innerHTML='<div class="num">'+String(t.id).padStart(2,'0')+' · '+t.key+'</div><strong>'+t.title+'</strong><div class="meta">'+t.meter+' · '+t.bpm+' BPM · '+Math.round(t.seconds)+' sec</div><div class="desc">'+t.idea+'</div>';el.onclick=()=>play(t);document.getElementById(t.id<=8?'classic':'modern').appendChild(el);}}}}function play(t){{const wasPlaying=!player.paused;selected=t;const file=story?'Full_Story_Loop.ogg':'Listen_Quiet_Lobby.mp3';player.src='Audio/'+t.slug+'/'+file;document.getElementById('now').textContent=String(t.id).padStart(2,'0')+' — '+t.title;document.querySelectorAll('.track').forEach(e=>e.classList.toggle('selected',+e.dataset.index===t.id));player.play().catch(()=>{{}});}}function changeMode(){{story=!story;document.getElementById('mode').textContent='Mix: '+(story?'Full Story':'Quiet Lobby');if(selected){{const at=player.currentTime;const current=selected;play(current);try{{player.currentTime=at;}}catch(e){{}}}}}}render();</script></body></html>'''
(ROOT/'Album_Player.html').write_text(page,encoding='utf8')
with open(ROOT/'Tracklist.csv','w',newline='',encoding='utf8') as f:
 w=csv.writer(f);w.writerow(['#','Track','Group','Key/Mode','Meter','BPM','Duration seconds','Concept'])
 for t in MAN['tracks']:
  w.writerow([t['index'],t['title'],t['group'],t['key'],t['meter'],t['bpm'],t['duration_seconds'],t['concept']])
# zip music, full production assets and Godot-ready stem subset
OUT=ROOT.parent
packs=[
 (OUT/'Flying_Liberty_16_Lobby_Themes_Full_Production_v1.zip','full'),
 (OUT/'Flying_Liberty_16_Lobby_Themes_MP3_v1.zip','mp3'),
 (OUT/'Flying_Liberty_16_Lobby_Godot_OGG_Stems_v1.zip','godot'),
]
for path,kind in packs:
 print('Packaging',path.name,flush=True)
 with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=2) as z:
  if kind=='full':
   for p in ROOT.rglob('*'):
    if p.is_file() and p.name!='render.log' and p.name!='render.pid' and '__pycache__' not in p.parts:
     z.write(p,(pathlib.Path('Flying_Liberty_Lobby_OST_16_v1')/p.relative_to(ROOT)).as_posix())
  elif kind=='mp3':
   z.write(ROOT/'README.md','README.md')
   z.write(ROOT/'Tracklist.csv','Tracklist.csv')
   for t in MAN['tracks']:
    slug=next(p.name for p in (ROOT/'Audio').iterdir() if p.is_dir() and p.name.startswith(f"{t['index']:02d}_"))
    z.write(ROOT/'Audio'/slug/'Listen_Quiet_Lobby.mp3',f'{slug}.mp3')
   for p in (ROOT/'Previews').glob('*.mp3'):z.write(p,f'Previews/{p.name}')
  else:
   for p in [ROOT/'README.md',ROOT/'track_manifest.json',ROOT/'Godot/LobbyMusicDirector.gd']:
    z.write(p,p.relative_to(ROOT).as_posix())
   for d in (ROOT/'Audio').iterdir():
    if d.is_dir():
     for p in d.glob('*.ogg'):z.write(p,p.relative_to(ROOT).as_posix())
 assert path.stat().st_size>50000
 print('PACK',path.name,round(path.stat().st_size/(1024*1024),1),'MB',flush=True)
print('Validated',len(checks),'tracks / 64 stems / 80 MIDI files')
for row in checks: print('  ',row)
