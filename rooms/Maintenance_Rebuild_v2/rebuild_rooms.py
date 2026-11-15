from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
from shapely.geometry import Polygon
from shapely.affinity import scale as shp_scale, translate as shp_translate
from pathlib import Path
import math, random, json, zipfile, csv, shutil, statistics

BASE=Path('/mnt/data/Flying_Liberty_Maintenance_Rebuild_v2'); (BASE/'rooms').mkdir(parents=True,exist_ok=True); (BASE/'metadata').mkdir(exist_ok=True); (BASE/'previews').mkdir(exist_ok=True); (BASE/'modules').mkdir(exist_ok=True)
C={'shadow':'#3B4145','base':'#929799','brass':'#A7793E','light':'#DDDCD5','accent':'#85C9D0'}
# Normalized polygons: winding and stairs are straight segments, no bezier/organic curves.
rooms=[
 ('S01','Small','Valve Alcove',1280,720,[(.12,.16),(.28,.08),(.72,.08),(.87,.18),(.91,.43),(.86,.77),(.73,.88),(.31,.88),(.11,.70),(.08,.36)],'perimeter'),
 ('S02','Small','Cable Recess',1280,720,[(.12,.10),(.42,.10),(.48,.19),(.74,.19),(.85,.30),(.88,.70),(.76,.85),(.42,.85),(.33,.77),(.15,.77),(.07,.62),(.07,.23)],'corner'),
 ('S03','Small','Filter Intake',1280,720,[(.14,.17),(.30,.08),(.71,.08),(.86,.22),(.86,.38),(.95,.38),(.95,.69),(.80,.82),(.58,.82),(.48,.90),(.23,.90),(.08,.75),(.08,.41)],'junction'),
 ('M01','Medium','Twin Fan Transfer',2560,1620,[(.08,.22),(.22,.12),(.40,.12),(.47,.07),(.64,.07),(.73,.17),(.90,.17),(.95,.33),(.95,.68),(.80,.82),(.58,.82),(.53,.92),(.27,.92),(.21,.81),(.08,.74)],'fans'),
 ('M02','Medium','Switchback Gallery',2560,1620,[(.10,.12),(.39,.12),(.45,.22),(.65,.22),(.73,.09),(.90,.09),(.94,.33),(.85,.40),(.85,.68),(.94,.76),(.79,.89),(.58,.89),(.51,.80),(.26,.80),(.19,.91),(.07,.80),(.07,.37)],'switchback'),
 ('M03','Medium','Pressure Corridor',2560,1620,[(.08,.18),(.24,.09),(.70,.09),(.77,.19),(.91,.19),(.94,.41),(.88,.50),(.94,.66),(.78,.87),(.58,.87),(.49,.76),(.34,.76),(.27,.87),(.10,.87),(.06,.62)],'gallery'),
 ('M04','Medium','Cross Service Hub',2560,1620,[(.34,.05),(.65,.05),(.70,.19),(.88,.19),(.94,.35),(.94,.67),(.78,.76),(.68,.76),(.68,.93),(.35,.93),(.30,.78),(.11,.78),(.06,.62),(.06,.32),(.22,.23),(.34,.23)],'cross'),
 ('M05','Medium','Broken Cable Maze',2560,1620,[(.12,.10),(.43,.10),(.48,.21),(.64,.21),(.70,.12),(.88,.12),(.93,.28),(.84,.39),(.93,.50),(.93,.69),(.78,.84),(.54,.84),(.48,.92),(.26,.92),(.22,.79),(.08,.79),(.05,.60),(.13,.47),(.05,.33)],'cables'),
 ('M06','Medium','Coolant Pump Hall',2560,1620,[(.06,.19),(.22,.10),(.46,.10),(.52,.19),(.70,.10),(.89,.10),(.96,.32),(.96,.68),(.88,.83),(.64,.83),(.56,.91),(.35,.91),(.29,.82),(.09,.82),(.04,.65)],'pumps'),
 ('M07','Medium','Duct-Switch Annex',2560,1620,[(.11,.15),(.28,.06),(.53,.06),(.61,.18),(.80,.18),(.92,.32),(.92,.48),(.85,.55),(.92,.72),(.76,.88),(.57,.88),(.47,.79),(.27,.88),(.10,.78),(.05,.54),(.09,.39)],'ducts'),
 ('L01','Large','Grand Maintenance Transept',3200,1920,[(.06,.22),(.23,.11),(.36,.11),(.42,.04),(.59,.04),(.64,.13),(.81,.13),(.93,.25),(.93,.43),(.85,.50),(.94,.62),(.88,.81),(.70,.90),(.56,.83),(.43,.91),(.27,.83),(.13,.87),(.05,.67)],'transept'),
 ('L02','Large','Turbine Array',3200,1920,[(.10,.12),(.28,.07),(.41,.16),(.57,.07),(.76,.07),(.89,.18),(.92,.38),(.84,.45),(.92,.64),(.91,.78),(.75,.90),(.57,.84),(.42,.93),(.24,.86),(.08,.78),(.07,.53),(.13,.42),(.06,.27)],'turbines'),
 ('L03','Large','Octagonal Central Works',3200,1920,[(.20,.08),(.43,.08),(.51,.17),(.65,.06),(.83,.15),(.93,.34),(.93,.62),(.84,.82),(.68,.90),(.56,.82),(.34,.91),(.14,.81),(.06,.62),(.06,.35)],'octagon'),
 ('L04','Large','Double Pump Yard',3200,1920,[(.10,.13),(.26,.05),(.44,.05),(.50,.15),(.65,.07),(.80,.14),(.94,.30),(.88,.44),(.94,.60),(.83,.83),(.66,.90),(.52,.81),(.37,.92),(.16,.85),(.06,.72),(.06,.46),(.12,.35)],'duplex'),
 ('L05','Large','Winding Repair Concourse',3200,1920,[(.08,.16),(.27,.07),(.42,.07),(.47,.19),(.68,.10),(.86,.14),(.95,.33),(.88,.45),(.96,.63),(.88,.79),(.71,.86),(.57,.77),(.43,.92),(.21,.87),(.09,.76),(.04,.60),(.12,.48),(.04,.32)],'concourse'),
]
# Pixel canvas areas: S 921,600; M 4,147,200 (4.5x); L 6,144,000 (6.6667x)
from collections import Counter
# Normalize every footprint to the same 59% of its canvas area.
# This makes actual irregular walkable footprint areas scale in exactly the same
# 1 : 4.5 : 6.6667 ratio as the requested canvas/world pixel areas.
normalized=[]
for code,typ,name,w,h,poly,design in rooms:
    shp=Polygon(poly)
    k=math.sqrt(.59/shp.area)
    outline=shp_scale(shp,xfact=k,yfact=k,origin='centroid')
    outline_pts=[(round(x,6),round(y,6)) for x,y in list(outline.exterior.coords)[:-1]]
    normalized.append((code,typ,name,w,h,outline_pts,design))
rooms=normalized
assert Counter(r[1] for r in rooms)==Counter({'Small':3,'Medium':7,'Large':5})
for r in rooms:
    p=Polygon(r[5]); assert p.is_valid and p.area>.3,(r[0],p.is_valid,p.area)

fontpath='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
font=ImageFont.truetype(fontpath,24)

def rgba(h, a=255):
    h=h.strip('#');return (int(h[:2],16),int(h[2:4],16),int(h[4:],16),a)

def tint(h,amount):
    c=rgba(h) if isinstance(h,str) else h;return tuple(max(0,min(255,int(x+amount))) for x in c[:3])+(255,)

def iso_fn(w,h):
    # A Hades-style elevated oblique camera, preserving visible back wall height.
    def f(u,v,z=0):return (int(w*(.5+.56*(u-.5)-.43*(v-.5))),int(h*(.60+.26*(u-.5)+.33*(v-.5)-z)))
    return f

def path_pts(P,points,z=0):return [P(*p,z) for p in points]

def polygon_area(pts):return Polygon(pts).area

def draw_line(draw,pts,fill,width=1):
    draw.line(pts,fill=fill,width=max(1,int(width)),joint='curve')

def iso_box(d,P,x,y,a,b,ht,col,edge,brass=None):
    # 3D box in the same floor projection. Note: z is normalized to image HEIGHT.
    poly=[(x-a,y-b),(x+a,y-b),(x+a,y+b),(x-a,y+b)]
    bot=path_pts(P,poly,0);top=path_pts(P,poly,ht)
    d.polygon([bot[1],bot[2],top[2],top[1]],fill=tint(col,-40),outline=edge,width=2)
    d.polygon([bot[2],bot[3],top[3],top[2]],fill=tint(col,-55),outline=edge,width=2)
    d.polygon([bot[0],bot[1],top[1],top[0]],fill=tint(col,-24),outline=edge,width=2)
    d.polygon(top,fill=col,outline=edge,width=3)
    d.line(top+[top[0]],fill=brass or rgba(C['light'],85),width=3)
    for idx in (0,2):
        xx,yy=top[idx]; d.ellipse((xx-3,yy-3,xx+3,yy+3),fill=brass or rgba(C['brass']))
    return top

def ground_plate(d,P,x,y,a,b,typ='grate'):
    ps=[(x-a,y-b),(x+a,y-b),(x+a,y+b),(x-a,y+b)]
    pp=path_pts(P,ps)
    d.polygon(pp,fill=rgba(C['shadow']),outline=rgba(C['brass']),width=3)
    for t in range(1,8):
        k=t/8; A=P(x-a+2*a*k,y-b);B=P(x-a+2*a*k,y+b)
        d.line([A,B],fill=rgba(C['base']) if typ=='grate' else rgba(C['light']),width=2)
    for i in range(4):
        k=(i+1)/5; A=P(x-a,y-b+2*b*k); B=P(x+a,y-b+2*b*k)
        d.line([A,B],fill=rgba(C['base']),width=1)


def drawing(P,w,h,name,typ,pol):
    rng=random.Random(5000+sum(map(ord,name)))
    img=Image.new('RGBA',(w,h),(0,0,0,0));d=ImageDraw.Draw(img,'RGBA')
    # under-floor shadow, edges (not a black backdrop)
    floor_pts=path_pts(P,pol)
    d.polygon([(x,y+min(h*.06,92)) for x,y in floor_pts],fill=(12,16,17,110))
    # floor polygon
    d.polygon(floor_pts,fill=rgba(C['shadow']))
    # entire floor tile pattern as clipped layer
    tiles=Image.new('RGBA',(w,h),(0,0,0,0)); td=ImageDraw.Draw(tiles,'RGBA')
    divx=16 if typ=='Small' else (29 if typ=='Medium' else 35)
    divy=10 if typ=='Small' else (19 if typ=='Medium' else 23)
    for u in range(divx):
        for v in range(divy):
            x0=u/divx;x1=(u+1)/divx;y0=v/divy;y1=(v+1)/divy
            cl=tint(C['base'],rng.randint(-19,10))
            if rng.random()<.10:cl=tint(C['light'],-70)
            corners=path_pts(P,[(x0,y0),(x1,y0),(x1,y1),(x0,y1)])
            td.polygon(corners,fill=cl)
            td.line(corners+[corners[0]],fill=(37,43,45,195),width=max(1,int(w/1280)))
            if rng.random()<.18:
                cp=P((x0+x1)/2,(y0+y1)/2)
                td.line([(cp[0]-3,cp[1]),(cp[0]+6,cp[1]+1)],fill=(59,70,74,62),width=2)
            if rng.random()<.24:
                for n in (0,2):
                    xx,yy=corners[n];tt=max(1,w//1280)
                    td.ellipse((xx-tt,yy-tt,xx+tt,yy+tt),fill=rgba(C['brass'],110))
    mask=Image.new('L',(w,h),0);ImageDraw.Draw(mask).polygon(floor_pts,fill=255)
    tiles.putalpha(mask);img.alpha_composite(tiles); d=ImageDraw.Draw(img,'RGBA')
    # floor stencils: warning lines and panel locking catches, kept subtle.
    stamp=Image.new('RGBA',(w,h),(0,0,0,0)); sd=ImageDraw.Draw(stamp,'RGBA')
    for j in range(5 if typ=='Small' else 12):
        x,y=rng.uniform(.14,.86),rng.uniform(.21,.79)
        if Polygon(pol).buffer(-.055).contains(__import__('shapely').geometry.Point(x,y)):
            x1,y1=P(x,y); q=max(2,int(w/950))
            sd.line([(x1-8*q,y1),(x1+8*q,y1)],fill=rgba(C['brass'],78),width=q)
            sd.line([(x1-8*q,y1+q*2),(x1-2*q,y1+q*2)],fill=rgba(C['light'],65),width=q)
    img.alpha_composite(stamp);d=ImageDraw.Draw(img,'RGBA')
    # border: metallic perimeter cap, structural edge
    d.line(floor_pts+[floor_pts[0]],fill=(13,22,23,245),width=max(6,w//90),joint='curve')
    d.line(floor_pts+[floor_pts[0]],fill=rgba(C['brass'],230),width=max(2,w//410),joint='curve')
    # limited set of decorative obstacles, no active enemies, preserving clear arena; tailored per room
    styles={
     'perimeter':[(.31,.32,.07,.06,'cabinet'),(.78,.66,.05,.06,'cabinet')],
     'corner':[(.26,.40,.07,.08,'cabinet'),(.74,.67,.07,.06,'cabinet')],
     'junction':[(.22,.30,.05,.07,'cabinet'),(.77,.62,.06,.07,'cabinet')],
     'fans':[(.30,.34,.08,.08,'turbine'),(.72,.62,.07,.08,'turbine')],
     'switchback':[(.27,.33,.08,.08,'cabinet'),(.72,.68,.08,.05,'cabinet')],
     'gallery':[(.22,.34,.05,.08,'tank'),(.78,.55,.06,.07,'tank')],
     'cross':[(.35,.39,.06,.07,'cabinet'),(.67,.61,.05,.06,'cabinet')],
     'cables':[(.21,.35,.06,.08,'cabinet'),(.72,.60,.08,.08,'cabinet')],
     'pumps':[(.28,.30,.08,.07,'pump'),(.73,.60,.08,.06,'pump')],
     'ducts':[(.25,.39,.06,.07,'duct'),(.72,.56,.08,.06,'duct')],
     'transept':[(.21,.32,.07,.06,'pump'),(.75,.60,.07,.08,'pump'),(.48,.67,.06,.05,'cabinet')],
     'turbines':[(.22,.37,.08,.07,'turbine'),(.75,.39,.07,.08,'turbine'),(.52,.72,.06,.06,'cabinet')],
     'octagon':[(.30,.31,.07,.08,'cabinet'),(.66,.60,.08,.05,'cabinet')],
     'duplex':[(.28,.33,.07,.07,'pump'),(.66,.61,.07,.07,'pump'),(.50,.73,.05,.06,'cabinet')],
     'concourse':[(.18,.35,.06,.08,'duct'),(.77,.65,.08,.07,'duct'),(.54,.52,.07,.07,'cabinet')]
    }
    is_small=typ=='Small'
    # Embedded inset floor grates, some visual texture without blocking movement.
    for px,py in [(0.42,0.43),(0.62,0.67)] if is_small else [(0.28,.51),(.50,.39),(.70,.66),(.50,.78)]:
        if Polygon(pol).buffer(-.09).contains(__import__('shapely').geometry.Point(px,py)):
            ground_plate(d,P,px,py,.035 if is_small else .042,.030 if is_small else .040)
    for x,y,a,b,kind in styles[name]:
        if kind=='turbine':
            iso_box(d,P,x,y,a,b,.065,rgba(C['base']),rgba(C['shadow']),rgba(C['brass']))
            cx,cy=P(x,y,.069);rad=max(14,int(w*.013));d.ellipse((cx-rad,cy-rad*.6,cx+rad,cy+rad*.6),fill=rgba(C['shadow']),outline=rgba(C['brass']),width=4)
            for i in range(8):
                t=i*math.tau/8
                d.line([(cx,cy),(cx+rad*.75*math.cos(t),cy+rad*.36*math.sin(t))],fill=rgba(C['light']),width=2)
        elif kind=='tank':
            iso_box(d,P,x,y,a,b,.10,rgba(C['base']),rgba(C['shadow']),rgba(C['brass']))
            cx,cy=P(x,y,.10);r=int(w*.013);d.ellipse((cx-r,cy-r*.55,cx+r,cy+r*.55),outline=rgba(C['brass']),width=4)
        elif kind=='pump':
            iso_box(d,P,x,y,a,b,.082,rgba(C['base']),rgba(C['shadow']),rgba(C['brass']))
            x0,y0=P(x,y,.084);d.arc((x0-14,y0-10,x0+14,y0+10),0,300,fill=rgba(C['light']),width=3)
        else:
            iso_box(d,P,x,y,a,b,.075 if kind=='cabinet' else .09,rgba(C['base']),rgba(C['shadow']),rgba(C['brass']))
    # Wall extrusions -- far-side full height, near-side partial walls preserve clear sightlines
    hfull=.19 if typ=='Small' else .12 if typ=='Medium' else .095
    hlow=hfull*.35
    edges=[]
    for i in range(len(pol)):
        a=pol[i];b=pol[(i+1)%len(pol)]; pa=P(*a);pb=P(*b)
        # back walls are upper half in plan; full wall; foreground parapet stays low
        mid=((a[0]+b[0])/2,(a[1]+b[1])/2)
        back=(mid[1] <.56)
        z=hfull if back else hlow
        ta=P(*a,z);tb=P(*b,z)
        edges.append({'id':i,'a':a,'b':b,'mid':mid,'back':back,'len':math.dist(a,b),'p1':pa,'p2':pb,'top1':ta,'top2':tb,'z':z})
    # draw walls back-to-front by midpoint screen y for occlusion order
    for e in sorted(edges,key=lambda e:(e['p1'][1]+e['p2'][1])/2):
        pa,pb,ta,tb=e['p1'],e['p2'],e['top1'],e['top2']
        wallcol=rgba(C['base'] if e['back'] else C['shadow'])
        d.polygon([pa,pb,tb,ta],fill=wallcol,outline=rgba(C['shadow']),width=max(1,w//900))
        # machined horizontal cap
        d.line([ta,tb],fill=rgba(C['light']),width=max(3,w//300))
        d.line([pa,pb],fill=rgba(C['brass'],220),width=max(2,w//600))
        if e['back']:
            # Two actual pipe runs built INTO the rear walls, as in maintenance rooms.
            pipe0=(pa[0]*.93+pb[0]*.07,pa[1]*.93+pb[1]*.07-h*e['z']*.78)
            pipe1=(pa[0]*.07+pb[0]*.93,pa[1]*.07+pb[1]*.93-h*e['z']*.78)
            d.line([pipe0,pipe1],fill=rgba(C['shadow']),width=max(5,w//260))
            d.line([pipe0,pipe1],fill=rgba(C['brass']),width=max(2,w//570))
            for p in [pipe0,pipe1]:
                r=max(3,int(w/430));d.ellipse((p[0]-r,p[1]-r,p[0]+r,p[1]+r),fill=rgba(C['base']),outline=rgba(C['brass']),width=2)
            # Subdued tube light, no spurious windows or window shadows.
            if math.dist(pa,pb)>w*.12:
                cxx=(pa[0]+pb[0])*.5;cyy=(pa[1]+pb[1])*.5-h*e['z']*.90
                rr=max(9,int(w*.019))
                d.rounded_rectangle((cxx-rr,cyy-4,cxx+rr,cyy+4),radius=4,fill=rgba(C['light']),outline=rgba(C['brass']),width=2)
        seg_px=math.dist(pa,pb)
        n=max(1,int(seg_px/(w*.05)))
        # Riveted panel joints make wall scale readable from the gameplay camera.
        for q in range(1,n):
            frac=q/n;bot=(pa[0]+frac*(pb[0]-pa[0]),pa[1]+frac*(pb[1]-pa[1]))
            top=(ta[0]+frac*(tb[0]-ta[0]),ta[1]+frac*(tb[1]-ta[1]))
            d.line([bot,top],fill=(46,56,58,160),width=max(1,w//1000))
            if e['back'] and q%3==1:
                cy=int((bot[1]+top[1])*.5);cx=int((bot[0]+top[0])*.5)
                rr=max(2,w//450)
                d.rectangle((cx-rr,cy-rr,cx+rr,cy+rr),fill=rgba(C['accent'],180),outline=rgba(C['shadow']))
    # place exits on straight back walls; ensure both left and right positions where possible.
    potential=[e for e in edges if e['back'] and e['len']>.13 and e['mid'][1]<.42]
    potential.sort(key=lambda e:e['mid'][0]);
    chosen=[]
    if potential:
        chosen=[potential[0]]
        if len(potential)>1 and typ!='Small':
            cand=max(potential,key=lambda e:e['mid'][0]);
            if cand['id'] !=chosen[0]['id'] and abs(cand['mid'][0]-chosen[0]['mid'][0])>.16:chosen.append(cand)
    elif edges:chosen=[min(edges,key=lambda e:e['mid'][1])]
    # 1 exit for small, 2 exits for many medium/large, no entrances.
    exits=[]
    for j,e in enumerate(chosen):
        pa,pb=e['p1'],e['p2'];ta,tb=e['top1'],e['top2']
        if math.dist(pa,pb)<30:continue
        cx=(pa[0]+pb[0])/2; cy=((pa[1]+pb[1])/2+(ta[1]+tb[1])/2)/2
        dx=pb[0]-pa[0];dy=pb[1]-pa[1];length=math.hypot(dx,dy);ex,ey=dx/length,dy/length
        r=min(length*.31,h*e['z']*.49, w*.062)
        # Hades-style opening built flush into wall; eight *thin* blades, not shutter slats
        def ell(rad_x,rad_y,n=48):return [(cx+ex*rad_x*math.cos(i*math.tau/n),cy+ey*rad_x*math.cos(i*math.tau/n)-rad_y*math.sin(i*math.tau/n)) for i in range(n)]
        polyout=ell(r*1.20,r*.80);d.polygon(polyout,fill=rgba(C['shadow']),outline=rgba(C['brass']),width=max(4,int(w/450)))
        d.line(ell(r*.98,r*.62)+[ell(r*.98,r*.62)[0]],fill=rgba(C['light']),width=max(2,int(w/850)))
        for i in range(8):
            t=i*math.tau/8
            bx=cx+ex*r*.81*math.cos(t);by=cy+ey*r*.81*math.cos(t)-r*.52*math.sin(t)
            d.line([(cx,cy),(bx,by)],fill=rgba(C['light']),width=max(2,int(w/650)))
        hub=max(4,int(w*.004));d.ellipse((cx-hub,cy-hub,cx+hub,cy+hub),fill=rgba(C['brass']),outline=rgba(C['shadow']),width=2)
        d.text((cx+ex*r*.95-5,cy-r*.78),'',font=font)
        exits.append({'edge_id':e['id'],'wall_a_world_px':[round(e['a'][0]*w),round(e['a'][1]*h)],'wall_b_world_px':[round(e['b'][0]*w),round(e['b'][1]*h)],'wall_t':0.5,'type':'eight_thin_blade_fan_exit','open_condition':'stop_spinning; blades remain thin enough to slip between','position_canvas_px':[round(cx),round(cy)],'radius_canvas_px':round(r),'orientation':'top_left' if e['mid'][0]<.5 else 'top_right'})
    return img,exits

outrows=[];manifest=[]
for code,typ,name,w,h,poly,design in rooms:
    P=iso_fn(w,h)
    im,exits=drawing(P,w,h,design,typ,poly)
    filename=f'{code}_{name.replace(" ","_")}.png'
    im.save(BASE/'rooms'/filename,optimize=True)
    world_poly=[[round(u*w),round(v*h)] for u,v in poly]
    area=Polygon(world_poly).area
    assert im.size==(w,h)
    meta={'id':code,'name':name,'biome':'Maintenance','size_class':typ,'canvas_px':[w,h],
          'world_footprint_px':[w,h], 'world_polygon_px':world_poly,
          'world_polygon_area_px2':round(area),'projection':'elevated_3_4_oblique_isometric_reference',
          'wall_geometry':'straight_segments_only','palette':C,'exits':exits,'entrances':[],
          'hazard_authoring':{'projectile_turret':'optional overlay','push_fan':'optional overlay','open_wires':'optional overlay'},
          'note':'Decorative art reference and layout geometry; 2D collision and door logic must be implemented in Godot.'}
    (BASE/'metadata'/f'{code}.json').write_text(json.dumps(meta,indent=2))
    manifest.append(meta);outrows.append([code,typ,name,w,h,w*h,int(area),len(exits),filename])
    prev=im.copy();prev.thumbnail((800,500));prev.save(BASE/'previews'/filename,optimize=True)
    print('RENDER',code,w,h,len(exits),round(area),flush=True)

# Asset modules as transparent components, separate from room images.
def vent_component(side='left',mode='exit',scale=1):
    w,h=800,560
    im=Image.new('RGBA',(w,h),(0,0,0,0));d=ImageDraw.Draw(im,'RGBA')
    # Front elevation designed to embed into the corresponding diagonal straight wall.
    pts=[(54,155),(150,105),(650,105),(745,155),(745,425),(650,470),(150,470),(54,425)]
    d.polygon(pts,fill=rgba(C['base']),outline=rgba(C['brass']),width=13)
    d.polygon([(92,155),(148,133),(651,133),(710,157),(710,413),(652,443),(149,443),(92,416)],fill=rgba(C['shadow']),outline=rgba(C['light']),width=5)
    for xx in [115,685]:
        d.line((xx,154,xx,418),fill=rgba(C['brass']),width=8)
        for yy in [185,394]:d.ellipse((xx-6,yy-6,xx+6,yy+6),fill=rgba(C['light']))
    cx,cy=400,285;r=155
    d.ellipse((cx-r,cy-r,cx+r,cy+r),fill=(16,24,28,255),outline=rgba(C['brass']),width=16)
    d.ellipse((cx-r+19,cy-r+19,cx+r-19,cy+r-19),outline=rgba(C['light']),width=6)
    for i in range(8):
        angle=i*math.tau/8+(0.13 if mode=='exit' else 0)
        ux,uy=math.cos(angle),math.sin(angle)
        end=(cx+ux*r*.83,cy+uy*r*.83)
        d.line(((cx,cy),end),fill=rgba(C['light']),width=10) # only ~3.2% width of diameter
        # tiny rivet at outer tip
        d.ellipse((end[0]-3,end[1]-3,end[0]+3,end[1]+3),fill=rgba(C['brass']))
    d.ellipse((cx-22,cy-22,cx+22,cy+22),fill=rgba(C['brass']),outline=rgba(C['shadow']),width=5)
    d.rectangle((235,91,565,118),fill=rgba(C['shadow']),outline=rgba(C['brass']),width=3)
    for xx in [250,520]:d.rectangle((xx,83,xx+18,128),fill=rgba(C['shadow']),outline=rgba(C['brass']),width=3)
    if mode=='entrance':
        # Entrance version: powered down, cyan hint of a tunnel, no obstruction beyond thin blades.
        d.arc((cx-r+16,cy-r+16,cx+r-16,cy+r-16),15,150,fill=rgba(C['accent']),width=5)
    if side=='right':im=ImageOps.mirror(im)
    return im
for mode in ('exit','entrance'):
    for side in ('left','right'):
        vent_component(side,mode).save(BASE/'modules'/f'maintenance_{mode}_{side}.png')

# indexes and contact sheets (browsing only; full-size rooms are individually delivered)
with (BASE/'room_sizes.csv').open('w',newline='') as f:
    wr=csv.writer(f);wr.writerow(['id','size','name','canvas_width_px','canvas_height_px','canvas_area_px2','floor_polygon_area_px2','exit_count','file']);wr.writerows(outrows)
(BASE/'manifest.json').write_text(json.dumps({'project':'Flying Liberty','biome':'Maintenance','count':15,'palette':C,'sizes':{'small':[1280,720],'medium':[2560,1620],'large':[3200,1920]},'room_designs':manifest},indent=2))
# contact sheet with thumbnails only; standalone images remain full-res
cw=1600;th=340;pad=34
contact=Image.new('RGB',(cw,40+5*th+160),(27,31,34));cd=ImageDraw.Draw(contact)
fontb=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',29)
cd.text((35,18),'FLYING LIBERTY | MAINTENANCE | 15 DIMENSIONED ROOMS',font=fontb,fill=C['light'])
for i,row in enumerate(outrows):
    code,typ,name,w,h,*_=row; rr=i//3;cc=i%3; slotx=40+cc*520;sloty=100+rr*340
    p=BASE/'previews'/f'{code}_{name.replace(" ","_")}.png'; img=Image.open(p)
    img.thumbnail((495,273)); contact.paste(img,(slotx+(495-img.width)//2,sloty),img)
    cd.text((slotx+8,sloty+269),f'{code} | {name}',fill=C['light'],font=ImageFont.truetype(fontpath,20))
    cd.text((slotx+8,sloty+295),f'{w} x {h} px',fill=C['brass'],font=ImageFont.truetype(fontpath,18))
contact.save(BASE/'previews'/'15_room_contact_sheet.jpg',quality=90)

reference=Path('/mnt/data/a_clean_concept_art_asset_sheet_on_a_dark_charcoal.png')
if reference.exists():shutil.copy2(reference,BASE/'modules'/'fan_vent_painted_concept_reference.png')
mood=Path('/mnt/data/a_detailed_concept_art_game_map_sheet_a_large_inf.png')
if mood.exists():shutil.copy2(mood,BASE/'previews'/'maintenance_art_direction_moodboard.png')

smal=[x for x in outrows if x[1]=='Small']; med=[x for x in outrows if x[1]=='Medium']; larg=[x for x in outrows if x[1]=='Large']
small=smal[0][6]
readme=f'''# Flying Liberty — Maintenance biome v2 (measured standalone rooms)

Includes 15 separate PNG room images, full-size world geometry JSON, 4 transparent modular vent components, an illustrated vent reference, and a compact contact sheet to browse the designs. Contact sheet is NOT a replacement for individual room images.

**World/canvas dimensions** (actual PNG size):

- Small: 1280 × 720 pixels (921,600 pixels); 3 rooms.
- Medium: 2560 × 1620 pixels (4,147,200 pixels = 4.5× a small room canvas); 7 rooms.
- Large: 3200 × 1920 pixels (6,144,000 pixels = 6.6667× a small room canvas); 5 rooms.

Actual irregular playable floor polygon areas are separately measured in `room_sizes.csv` and `manifest.json`. The world polygon is the ground-plane source of truth; the oblique image is the corresponding environment reference.

The artwork uses an elevated oblique/isometric projection and straight-edged, polygonal footprints. All exits (one or two depending on chamber) attach to specific straight, upper wall segments, stored in per-room JSON with their segment endpoints. Entrances are **not** placed into any room; four isolated fan-vent modules include two entrance variants solely as design assets.

Maintenance colors: `#3B4145` shadow, `#929799` base, `#A7793E` brass, `#DDDCD5` light, `#85C9D0` rare cyan accent. Fans have 8 thin spokes and large openings so the powered-down fan passage can be traversed in the game. Collision remains a Godot implementation task, with stopping animations and movement needed.

For a high-detail painted treatment, use the `modules/fan_vent_painted_concept_reference.png` and `previews/maintenance_art_direction_moodboard.png` as stylistic references, and **preserve the measured JSON geometry** rather than repainting arbitrary new positions. These PNG room renderings are stylized geometry-first environment illustrations, not individually hand-painted game-ready layer separations. They are not animated and are not implemented in Godot.
'''
(BASE/'README.md').write_text(readme)
zipf=Path('/mnt/data/Flying_Liberty_Maintenance_15_Rooms_Measured_v2.zip')
with zipfile.ZipFile(zipf,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in BASE.rglob('*'):
        if path.is_file():z.write(path,arcname=str(path.relative_to(BASE.parent)))
print('PACKAGED',zipf,zipf.stat().st_size//(1024*1024),'MB',flush=True)
