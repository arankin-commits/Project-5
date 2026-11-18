"""Deterministic vector art fitted to the authored collision geometry.

References: rooms/references (four biome scenes), rooms/Hazards, and the
biome-specific room sheets. Source blockouts and gameplay data stay intact.
Run one biome at a time, in route order; no third-party packages required.
"""
import json
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTES = {
    'maintenance': ('#414b50', '#28343a', '#778486', '#56d7d5', '#ba8b43'),
    'factory': ('#49474b', '#302c32', '#8b8580', '#ec6953', '#d5a044'),
    'boiler': ('#514039', '#302523', '#977364', '#ff872e', '#bc7842'),
    'toxin_refinery': ('#444c40', '#29362d', '#7d8a71', '#adea43', '#b2a655'),
}


def render(g, biome):
    w, h = g['pixel_size']
    base, dark, edge, light, brass = PALETTES[biome]
    rng = random.Random(g['seed'])
    def project(p, z=0):
        x, y = p
        return (w*.5+(x-50)*.51*w/100-(y-37)*.45*w/74,
                h*.535+(x-50)*.19*h/100+(y-37)*.37*h/74-z)
    def pts(ps):
        return ' '.join(f'{x:.2f},{y:.2f}' for x, y in ps)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">']
    def poly(ps, fill, stroke='#171e22', width=1):
        out.append(f'<polygon points="{pts(ps)}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"/>')
    def line(a, b, color, width=1, extra=''):
        out.append(f'<path d="M {a[0]:.2f} {a[1]:.2f} L {b[0]:.2f} {b[1]:.2f}" fill="none" stroke="{color}" stroke-width="{width}" {extra}/>')
    def ellipse(x, y, rx, ry, fill, stroke='none', sw=1):
        out.append(f'<ellipse cx="{x:.2f}" cy="{y:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')
    floor = [project(p) for p in g['floor_polygon']]
    out.append(f'''<defs>
      <clipPath id="floor"><polygon points="{pts(floor)}"/></clipPath>
      <linearGradient id="steel" x2=".3" y2="1"><stop stop-color="{edge}"/><stop offset=".18" stop-color="{base}"/><stop offset="1" stop-color="{dark}"/></linearGradient>
      <linearGradient id="wall" x2="0" y2="1"><stop stop-color="{base}"/><stop offset="1" stop-color="{dark}"/></linearGradient>
      <radialGradient id="glow"><stop stop-color="{light}" stop-opacity=".25"/><stop offset="1" stop-color="{light}" stop-opacity="0"/></radialGradient>
      <pattern id="stripe" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="rotate(35)"><rect width="12" height="12" fill="{dark}"/><rect width="5" height="12" fill="{brass}"/></pattern>
    </defs>''')
    out.append(f'<rect width="{w}" height="{h}" fill="#0d161b"/>')
    # Underfloor service ducts and drop shadow ground every silhouette.
    poly([(x+5,y+22) for x,y in floor], '#080e12', '#080e12', 13)
    for i, a in enumerate(floor):
        b = floor[(i+1) % len(floor)]
        poly([a,b,(b[0],b[1]+18),(a[0],a[1]+18)], dark)
        line((a[0],a[1]+12),(b[0],b[1]+12), light, 2)
    poly(floor, base, edge, 2)
    out.append('<g clip-path="url(#floor)">')
    # Individual steel plates with seams, fasteners and restrained wear.
    for x in range(0,110,8):
        for y in range(0,85,8):
            corners = [project(p) for p in [(x,y),(x+8,y),(x+8,y+8),(x,y+8)]]
            shade = rng.uniform(.93, 1.07)
            plate = '#' + ''.join(f'{min(255,int(int(base[k:k+2],16)*shade)):02x}' for k in [1,3,5])
            poly(corners, plate, '#242c2e', .65)
            line(corners[0],corners[1],edge,.45)
            for dx,dy in [(.6,.6),(7.4,7.4)]:
                px,py = project((x+dx,y+dy))
                ellipse(px,py,.75,.4,brass)
            if rng.random()<.45:
                a=project((x+rng.uniform(1,5),y+rng.uniform(1,5)))
                line(a,(a[0]+rng.uniform(2,10),a[1]-1),edge,.5)
    for i,a in enumerate(floor):
        b=floor[(i+1)%len(floor)]
        line(a,b,'url(#stripe)',7)
        line(a,b,dark,1)
    for gap in g['gaps']:
        ps=[project(p) for p in gap['polygon']]
        poly(ps,'#080f12',brass,2)
        for a,b in zip(ps,ps[1:]+ps[:1]):
            line((a[0],a[1]+4),(b[0],b[1]+4),light,.8)
    out.append('</g>')
    # Back walls only: low front rim keeps combat readable.
    for i,a in enumerate(floor):
        b=floor[(i+1)%len(floor)]
        if b[0] >= a[0]:
            continue
        height=38
        poly([a,b,(b[0],b[1]-height),(a[0],a[1]-height)],'url(#wall)', '#10191e',2)
        line((a[0],a[1]-height),(b[0],b[1]-height),edge,3)
        line((a[0],a[1]-9),(b[0],b[1]-9),brass,2)
        line((a[0],a[1]-19),(b[0],b[1]-19),'#151d21',7)
        line((a[0],a[1]-20),(b[0],b[1]-20),edge,3)
        count=max(1,int(math.dist(a,b)/35))
        for j in range(count):
            t=(j+.5)/count
            x=a[0]+(b[0]-a[0])*t
            y=a[1]+(b[1]-a[1])*t
            line((x,y-4),(x,y-36),dark,4)
            ellipse(x,y-32,1.3,1.3,brass)
            if j%3==0:
                ellipse(x,y-15,35,24,'url(#glow)')
                line((x,y-12),(x,y-25),brass,6)
                line((x,y-13),(x,y-24),light,3)
            else:
                line((x-2,y-16),(x-2,y-23),brass,2)
    def box(item, low=False):
        cx,cy=item['center']; sx,sy=item['size']
        ps=[project(p) for p in [(cx-sx/2,cy-sy/2),(cx+sx/2,cy-sy/2),(cx+sx/2,cy+sy/2),(cx-sx/2,cy+sy/2)]]
        height=9 if low else 24
        top=[(x,y-height) for x,y in ps]
        poly([(x+8,y+5) for x,y in ps],'#182024','#182024',5)
        for k in [1,2]:
            q=(k+1)%4
            poly([ps[k],ps[q],top[q],top[k]],'url(#steel)', '#11191e',1.4)
            line((ps[k][0],ps[k][1]-3),(ps[q][0],ps[q][1]-3),'url(#stripe)',5)
            for t in [.15,.85]:
                a=(ps[k][0]*(1-t)+ps[q][0]*t,ps[k][1]*(1-t)+ps[q][1]*t)
                line((a[0],a[1]-5),(a[0],a[1]-height+2),brass,1.5)
        poly(top,'url(#steel)',edge,1)
        for x,y in top:
            ellipse(x,y,1.4,.8,brass)
        if not low:
            px,py=project((cx,cy),height+1)
            if biome in ['boiler','toxin_refinery']:
                # Riveted pressure vessel / chemical reservoir.
                ellipse(px,py+3,12,6,dark,brass,2)
                out.append(f'<rect x="{px-10:.2f}" y="{py-14:.2f}" width="20" height="17" fill="url(#steel)" stroke="{brass}"/>')
                ellipse(px,py-14,10,5,base,brass,1.5)
                line((px,py-10),(px,py),light,3)
                ellipse(px+6,py-8,3,3,'#dacdb0',dark)
                line((px+6,py-8),(px+7,py-10),dark)
            else:
                for j in range(-3,4):
                    line((px-9+j*2,py-3),(px-3+j*2,py),dark,1.4)
                line((px-6,py+4),(px+4,py+7),light,2)
    objects=[(project(i['center'])[1],i,False) for i in g['obstacles']]
    objects += [(project(i['center'])[1],i,True) for i in g['partial_cover']]
    for _,item,low in sorted(objects,key=lambda v:v[0]):
        box(item,low)
    for door in g['doors']:
        x,y=project(door['mid'])
        ellipse(x,y+1,30,14,'url(#glow)')
        # A visibly recessed portal with light bars and a brass lintel.
        poly([(x-19,y),(x+19,y),(x+19,y-35),(x-19,y-35)],dark,edge,3)
        for j in range(5):
            line((x-15,y-4-j*5),(x+15,y-4-j*5),base,2)
        for side in [-1,1]:
            line((x+side*20,y),(x+side*20,y-33),brass,5)
            line((x+side*20,y-8),(x+side*20,y-27),light,2)
        line((x-18,y-35),(x+18,y-35),'url(#stripe)',5)
    out.append('</svg>')
    return ''.join(out)


def main():
    for biome in sys.argv[1:] or PALETTES:
        target=ROOT/'art/biomes'/biome
        target.mkdir(parents=True,exist_ok=True)
        catalog=ROOT/'data/blockouts'/f'{biome}.json'
        data=json.loads(catalog.read_text())
        for room in data['rooms']:
            (target/f"{room['id']}.svg").write_text(render(room['geometry'],biome))
            room['image']=f"res://art/biomes/{biome}/{room['id']}.svg"
        catalog.write_text(json.dumps(data,indent=2)+'\n')
        print(f'{biome}: {len(data["rooms"])} room artworks fitted to original geometry')


if __name__=='__main__':
    main()

