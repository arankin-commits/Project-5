import json,html
from pathlib import Path
root=Path('/mnt/data/four_biomes_120_rooms')
rooms=json.loads((root/'all_room_geometry.json').read_text())['rooms']
css='''
:root{color-scheme:dark;font-family:Inter,Arial,sans-serif;background:#0d151c;color:#e7f2f2}
*{box-sizing:border-box}body{margin:0}.shell{max-width:1500px;margin:auto;padding:28px}
h1{font-size:32px;margin:0 0 7px}p{margin:0;color:#a9bbc2;line-height:1.5}
header{padding-bottom:25px;border-bottom:1px solid #35454c}.filters{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0;align-items:end}
label{display:grid;gap:6px;color:#98bec4;font-size:12px;text-transform:uppercase;font-weight:700;letter-spacing:.08em}
select,input{border:1px solid #485c62;background:#18252f;color:#f5ffff;border-radius:8px;padding:9px 14px;font:inherit;min-width:155px}
#stats{margin-left:auto;color:#acc5cc;padding:10px 0}.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(335px,1fr));gap:20px}
.card{border:1px solid #36454d;border-radius:13px;background:#15222b;overflow:hidden}.card img{width:100%;height:auto;display:block;aspect-ratio:16/9;object-fit:contain;background:#0d151c}
.info{padding:13px 15px}.info h2{font-size:16px;margin:0 0 7px}.chips{display:flex;gap:7px;flex-wrap:wrap}
.chip{font-size:11px;color:#a2b9bf;background:#20313b;padding:5px 8px;border-radius:5px}
a{color:#85dee2;text-decoration:none}a:hover{text-decoration:underline}.empty{padding:40px;color:#bdcacc}
footer{border-top:1px solid #35454c;margin-top:35px;padding-top:20px;color:#98b1b8;font-size:13px}
'''
cards=[]
for r in rooms:
 img=html.escape(r['image'],quote=True)
 name=html.escape(r['name'])
 biome=r['biome'];size=r['size']
 hazards=' / '.join(sorted({h['type'] for h in r['hazards']}))
 cards.append(f'''<article class="card" data-biome="{biome}" data-size="{size}" data-title="{html.escape((name+' '+hazards).lower(),quote=True)}">
 <a href="{img}" target="_blank"><img loading="lazy" src="{img}" alt="{name} three-quarter perspective blockout"></a>
 <div class="info"><h2>{r['number']:02d} · {name}</h2><div class="chips"><span class="chip">{size.upper()}</span><span class="chip">{r['pixel_size'][0]}×{r['pixel_size'][1]} px</span><span class="chip">{len(r['doors'])-1} exits</span><span class="chip">{html.escape(hazards)}</span></div></div></article>''')
text=f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Four Biomes — 120 Blockouts</title><style>{css}</style></head><body>
<div class="shell"><header><h1>Four Biomes · 120 Unique Blockouts</h1><p>Maintenance · Factory · Boiler Room · Toxin Refinery — individually rendered in elevated three-quarter perspective. Open any room image to inspect full resolution.</p></header>
<div class="filters"><label>Biome<select id="biome"><option value="all">All four biomes</option><option value="maintenance">Maintenance</option><option value="factory">Factory</option><option value="boiler_room">Boiler Room</option><option value="toxin_refinery">Toxin Refinery</option></select></label>
<label>Room size<select id="size"><option value="all">All sizes</option><option value="small">Small · 1280×720</option><option value="medium">Medium · 2688×1512</option><option value="large">Large · 3200×1800</option></select></label>
<label>Search<input id="query" placeholder="Name or hazard..." type="search"></label><div id="stats">Showing 120 rooms</div></div>
<main class="gallery">{''.join(cards)}</main><div class="empty" id="empty" hidden>No rooms match these filters.</div>
<footer>Geometry and room-specific hazard placement are stored in <a href="all_room_geometry.json">all_room_geometry.json</a>. Design rules: <a href="README_AND_DESIGN_ANALYSIS.md">README_AND_DESIGN_ANALYSIS.md</a>.</footer></div>
<script>const b=document.querySelector('#biome'),s=document.querySelector('#size'),q=document.querySelector('#query'),cards=[...document.querySelectorAll('.card')],stats=document.querySelector('#stats'),empty=document.querySelector('#empty');
function apply(){{let num=0;for(const c of cards){{let show=(b.value==='all'||c.dataset.biome===b.value)&&(s.value==='all'||c.dataset.size===s.value)&&c.dataset.title.includes(q.value.toLowerCase().trim());c.hidden=!show;if(show)num++;}}stats.textContent=`Showing ${{num}} of 120 rooms`;empty.hidden=num>0;}}[b,s,q].forEach(e=>e.addEventListener('input',apply));</script></body></html>'''
(root/'gallery.html').write_text(text,encoding='utf-8')
print(len(text),'gallery generated')
