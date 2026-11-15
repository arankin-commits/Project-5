#!/usr/bin/env python3
"""Deterministic original 120-room isometric factory-environment gameplay blockout pack."""
from __future__ import annotations
import math, random, json, csv, os, hashlib, zipfile, time
from pathlib import Path
from collections import Counter
from PIL import Image, ImageDraw, ImageFont, ImageChops
from shapely.geometry import box, Polygon, Point
from shapely.ops import unary_union
import numpy as np
import cv2

ROOT=Path('/mnt/data/four_biomes_120_rooms')
WORLDBOUNDS=(0,0,100,74)
SIZES={'small':(1280,720,1.0),'medium':(2688,1512,math.sqrt(4.41)),'large':(3200,1800,2.5)}
CATEGORIES=['small']*6+['medium']*14+['large']*10
MOTIFS=['dogleg','back-alcove','forked-gallery','stepped-court','wide-cross','offset-bay','cut-corner','side-bulge','double-niche','pinched-hall','split-wing','asymmetric-octagon','counterflow','perimeter-ring','offset-crossfire','central-lane','crossing-lanes','zigzag','corner-ambush','gauntlet','swept-edge','broken-axis','split-court','double-loop','bypass','offset-courtyard','staggered-cover','flank-run','sentry-loop','wide-arena']
NAMES={
'maintenance':[
'Intake Nook','Wire Junction','Fuse Pocket','Vent Spur','Service Elbow','Filter Kink',
'Pump Court','Conveyor Turn','Turbine Cross','Coolant Bend','Relay Hall','Cable Yard','Inspection Bay','Fan Gallery','Spindle Room','Circuit Yard','Pressure Loop','Service Maze','Scrap Transit','Boiler Link',
'Main Compressor','Duct Nexus','Generator Floor','Overflow Exchange','Turret Foundry','Cooling Manifold','Maintenance Hub','Rotor Basin','Grid Breaker','Waste Sorter'],
'factory':[
'Punch-Press Vestibule','Blade Feeder','Coil Annex','Die-Cast Nook','Piston Elbow','Stamping Pocket',
'Assembly Junction','Sawtooth Transfer','Capacitor Hall','Press-Line Bend','Molding Exchange','Rivet Yard','Stamping Gallery','Switchgear Run','Conveyor Quadrant','Hydraulic Turn','Forge Inspection','Blade Relay','Die Conveyor','Final Sorting',
'Grand Assembly Floor','Rotary Manufacturing','Heavy Press Foundry','Voltage Distribution','Blade Exchange','Automated Stamping','Production Crossroads','Smelting Dispatch','Robotic Assembly','Shutdown Complex'],
'boiler_room':[
'Pilot Burner','Cinder Intake','Steam Elbow','Ash Pocket','Pressure Nook','Ignition Hatch',
'Ember Gallery','Firebox Exchange','Flue Junction','Overheat Bend','Boiler Service Court','Furnace Relay','Soot Conveyor','Heat Diverter','Piston Furnace','Pressure Manifold','Ash Recovery','Flashpoint Passage','Steam Return','Combustion Hall',
'Great Boiler Chamber','Inferno Transfer','Superheater Floor','Pressure Cascade','Furnace Crucible','Steam Crown','Thermal Distribution','Redline Compressor','Ashfall Exchange','Core Ignition Complex'],
'toxin_refinery':[
'Reagent Intake','Caustic Elbow','Barrel Pocket','Acid Sump','Valve Nook','Spike Bay',
'Solvent Junction','Neutralizer Hall','Reagent Gallery','Corrosion Transfer','Barrel Exchange','Toxic Split','Acid Feeder','Hazard Inspection','Drip Court','Leakage Crossing','Distillate Bend','Separation Run','Fume Sorting','Pressure Filtration',
'Refinery Core','Catalyst Exchange','Containment Grid','Toxic Processing Floor','Acid Distribution','Waste Reclaimer','Spill Control','Reaction Manifold','Barrel Handling Complex','Final Purification']}
PALS={
'maintenance':{'accent':'#58e2d2','accent2':'#138e9c','wall':'#566777','top':'#84909b','floor':'#b0c0c5','dark':'#111d26','hazards':{'turret':'#ff5d64','fan':'#5fdbf6','wires':'#ffb345'}},
'factory':{'accent':'#f3bd71','accent2':'#b77840','wall':'#665d61','top':'#968789','floor':'#c1b9b2','dark':'#211820','hazards':{'saw':'#f5b24b','tesla':'#a977fc','press':'#fc7588'}},
'boiler_room':{'accent':'#ffae67','accent2':'#bd5b35','wall':'#685d59','top':'#938780','floor':'#c4ada0','dark':'#241915','hazards':{'spinner':'#f4a343','spitter':'#ff694c','oven':'#e54a39','vent':'#ffc26b','can':'#c3d64d'}},
'toxin_refinery':{'accent':'#adf26e','accent2':'#688e47','wall':'#5c6963','top':'#8b9a8c','floor':'#afbcae','dark':'#13211d','hazards':{'acid':'#97f557','spikes':'#dddebf','barrel':'#ffc65d'}}
}
HAZARD_NAMES={'turret':'PROJECTILE TURRET','fan':'BLOWER FAN','wires':'OPEN WIRES','saw':'MOVING SAW TRACK','tesla':'TESLA MACHINE','press':'BREAKABLE CEILING PRESS','spinner':'FIRE SPINNER','spitter':'FIRE SPITTER','oven':'FURNACE SPITTER','vent':'FIRE VENT','can':'EXPLOSIVE CAN','acid':'ACID SPITTER','spikes':'SPIKE TRAP','barrel':'EXPLODING BARREL'}
KINDS={'maintenance':['turret','fan','wires'],'factory':['saw','tesla','press'],'boiler_room':['spinner','spitter','oven','vent','can'],'toxin_refinery':['acid','spikes','barrel']}
FONT_DIR='/usr/share/fonts/truetype/dejavu/'

def font(size,bold=False):return ImageFont.truetype(FONT_DIR+('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf'),max(10,int(size)))
def rgb(s):return tuple(bytes.fromhex(s[1:]))
def mix(a,b,t):
 a=rgb(a) if isinstance(a,str) else a;b=rgb(b) if isinstance(b,str) else b
 return tuple(int(a[i]*(1-t)+b[i]*t) for i in range(3))
def px(points):return [tuple(map(int,p)) for p in points]

def chamfer_polygon(poly,rng):
 cs=list(poly.exterior.coords)[:-1];out=[]
 for i,p in enumerate(cs):
  prev=cs[(i-1)%len(cs)];nex=cs[(i+1)%len(cs)]
  v=(p[0]-prev[0],p[1]-prev[1]);w=(nex[0]-p[0],nex[1]-p[1]);vl=math.hypot(*v);wl=math.hypot(*w)
  cross=v[0]*w[1]-v[1]*w[0]
  if cross>0 and vl>5.5 and wl>5.5 and rng.random() < .70:
   c=min(rng.uniform(1.8,4.0),vl*.25,wl*.25)
   out.extend([(p[0]-c*v[0]/vl,p[1]-c*v[1]/vl),(p[0]+c*w[0]/wl,p[1]+c*w[1]/wl)])
  else:out.append(p)
 maybe=Polygon(out)
 if maybe.is_valid and maybe.area>.92*poly.area:return maybe
 return poly

def silhouette(rng,seed,biome_idx,local_index):
 # Variations of attached axial wings and exterior notches; no disconnected islands or curved boundary.
 style=(local_index*5+biome_idx*7)%13
 jitter=lambda lo,hi:rng.uniform(lo,hi)
 left=jitter(9,16);right=jitter(84,92);top=jitter(9,15);bottom=jitter(60,66)
 # Thirteen substantial layout families: courts, wings, L bends, crosses, zigzags,
 # a broken octagon, offset strips, and U-shaped cuts—not just minor wall jitter.
 if style==2:
  main=unary_union([box(left,top,left+36,bottom),box(left,bottom-30,right,bottom)])   # L bend
 elif style==3:
  main=unary_union([box(left,top+13,right,bottom-12),box(40,top,68,bottom)])      # T branch
 elif style==4:
  main=unary_union([box(23,top+12,77,bottom-10),box(39,top,63,bottom),box(left,31,right,48)]) # cross
 elif style==6:
  main=unary_union([box(24,top,72,bottom),box(left,24,32,53),box(66,20,right,48)]) # dual bays
 elif style==8:
  main=unary_union([box(left,top+8,49,47),box(39,26,74,57),box(64,36,right,bottom)]) # zigzag
 elif style==9:
  main=unary_union([box(left,top,right-9,top+38),box(39,top+25,right,bottom)])   # offset hook
 elif style==10:
  # more strongly chamfered octagonal perimeter
  main=Polygon([(left+13,top),(right-13,top),(right,top+12),(right,bottom-12),(right-12,bottom),(left+13,bottom),(left,bottom-13),(left,top+12)])
 else:
  main=box(left,top,right,bottom)
 parts=[main]
 if style in (0,4,5,8,9,12):parts.append(box(jitter(29,40),jitter(1,4),jitter(60,74),top+4))
 if style in (1,3,4,7,10,12):parts.append(box(jitter(25,37),bottom-4,jitter(68,79),jitter(69,72)))
 if style in (2,4,6,8,11):parts.append(box(jitter(1,4),jitter(18,30),left+3,jitter(42,55)))
 if style in (0,3,5,7,9,11):parts.append(box(right-4,jitter(20,29),jitter(96,99),jitter(45,57)))
 if style in (6,10):
  parts.append(box(jitter(1,3),jitter(19,24),left+4,jitter(46,54)))
  parts.append(box(right-4,jitter(18,23),jitter(97,99),jitter(42,52)))
 if style in (2,8,12):parts.append(box(jitter(42,49),bottom-4,jitter(62,69),jitter(69,72)))
 if style in (5,9,11):parts.append(box(jitter(32,39),jitter(2,5),jitter(58,63),top+4))
 shape=unary_union(parts)
 if not isinstance(shape,Polygon):shape=max(shape.geoms,key=lambda p:p.area)
 # Cut back connected rectangular bites along the exposed outside edges.
 cuts=[]
 if style in (0,1,8,10,12):cuts.append(box(left-8, jitter(30,36),left+jitter(6,12),jitter(42,50)))
 if style in (2,3,5,7,11):cuts.append(box(right-jitter(6,12), jitter(30,35),right+8,jitter(43,51)))
 if style in (1,4,6,9):cuts.append(box(jitter(41,46),top-10,jitter(52,61),top+jitter(6,11)))
 if style in (0,5,10):cuts.append(box(jitter(38,44),bottom-jitter(7,10),jitter(55,62),bottom+10))
 if style in (3,7,11):cuts.append(box(jitter(19,27),bottom-jitter(5,9),jitter(33,39),bottom+10))
 for c in cuts:
  test=shape.difference(c)
  if isinstance(test,Polygon) and test.is_valid and test.area>2500:shape=test
 shape=shape.simplify(.15,preserve_topology=True)
 shape=chamfer_polygon(shape,rng)
 if not shape.is_valid:shape=shape.buffer(0)
 if not isinstance(shape,Polygon):shape=max(shape.geoms,key=lambda p:p.area)
 return shape

class Project:
 def __init__(self,W,H):
  self.W=W;self.H=H;self.cx=.50*W;self.cy=.535*H
 def p(self,x,y,z=0):return (self.cx +(x-50)*(.51*self.W/100)-(y-37)*(.45*self.W/74),self.cy + (x-50)*(.19*self.H/100)+(y-37)*(.37*self.H/74)-z)
 def P(self,v,z=0):return self.p(v[0],v[1],z)

def normal_inner(poly,a,b):
 d=(b[0]-a[0],b[1]-a[1]);length=math.hypot(*d);nx,ny=-d[1]/length,d[0]/length
 mid=((a[0]+b[0])/2,(a[1]+b[1])/2)
 if poly.contains(Point(mid[0]+nx*.3,mid[1]+ny*.3)):return (nx,ny)
 return (-nx,-ny)

def doors_for(poly,size,rng,proj):
 coords=list(poly.exterior.coords)[:-1]
 s=SIZES[size][2];N={'small':2,'medium':3,'large':4}[size]
 candidates=[]
 for i,a in enumerate(coords):
  b=coords[(i+1)%len(coords)];L=math.dist(a,b)
  if L<max(8,10/s+3):continue
  norm=normal_inner(poly,a,b);mid=((a[0]+b[0])/2,(a[1]+b[1])/2)
  inside=(mid[0]+norm[0]*5.5/s,mid[1]+norm[1]*5.5/s)
  if not poly.contains(Point(inside)):continue
  screen=proj.P(mid)
  candidates.append({'seg':i,'a':a,'b':b,'length':L,'mid':mid,'normal':norm,'inside':inside,'screen':screen})
 if len(candidates)<N:return None
 # One front-side entrance, remaining exits distributed along the perimeter with angular separation.
 entry_pool=sorted(candidates,key=lambda d:d['screen'][1],reverse=True)[:max(2,len(candidates)//2)]
 entrance=rng.choice(entry_pool[:min(4,len(entry_pool))]);entrance['role']='entrance'
 selected=[entrance]
 while len(selected)<N:
  choices=[]
  for c in candidates:
   if c in selected:continue
   d=min(math.dist(c['mid'],p['mid']) for p in selected)
   if d<12/s:continue
   score=d + (proj.H*.53-c['screen'][1])*.015 + rng.random()*9
   choices.append((score,c))
  if not choices:return None
  c=max(choices,key=lambda x:x[0])[1];c['role']='exit';selected.append(c)
 for d in selected:
  d['width']=8.7/s
  d['approach']=(d['mid'][0]+d['normal'][0]*8/s,d['mid'][1]+d['normal'][1]*8/s)
 return selected

def place_objects(poly, doors, rng, size, biome, idx):
 scale=SIZES[size][2];safe=7.8/scale
 gap_n={'small':1,'medium':2,'large':4}[size] + (idx%3==0 and size!='small')
 block_n={'small':2,'medium':5,'large':9}[size] +(idx%4==0)
 cover_n={'small':2,'medium':4,'large':6}[size] +(idx%3==1)
 hazard_n={'small':2,'medium':5,'large':9}[size] +(idx%7==0)
 if biome=='boiler_room':hazard_n+=int(size=='large')
 reserved=[];gaps=[];blocks=[];covers=[];hazards=[]
 # Reserve door approaches and avoid placing any solids over doorway path.
 for d in doors:
  q=d['approach'];reserved.append((Point(q).buffer(6/scale), 'door'))
  reserved.append((Point(d['inside']).buffer(5/scale),'door'))
 inner=poly.buffer(-2.8/scale)
 if inner.is_empty:inner=poly.buffer(-1)
 def candidate(w,h, kinds=('door','gap','block','cover','hazard'),maxtry=130):
  minx,miny,maxx,maxy=poly.bounds
  for j in range(maxtry):
   x=rng.uniform(minx+w/2+1,maxx-w/2-1);y=rng.uniform(miny+h/2+1,maxy-h/2-1)
   r=box(x-w/2,y-h/2,x+w/2,y+h/2)
   if not inner.contains(r):continue
   if any(r.buffer(.9/scale).intersects(g) for (g,k) in reserved if k in kinds):continue
   return x,y,r
  return None
 def add_gap():
  w=rng.uniform(8.2,13.0)/scale;h=rng.uniform(4.6,7.3)/scale
  c=candidate(w,h,maxtry=200)
  if c:
   x,y,r=c;gaps.append({'center':[round(x,3),round(y,3)],'size':[round(w,3),round(h,3)],'polygon':list(map(list,list(r.exterior.coords)[:-1]))})
   reserved.append((r.buffer(1.8/scale),'gap'))
 for i in range(gap_n):add_gap()
 def add_block(half):
  if half:w=rng.uniform(7,12)/scale;h=rng.uniform(1.7,2.8)/scale
  else:w=rng.uniform(5.0,8.4)/scale;h=rng.uniform(4.5,7.7)/scale
  if rng.random()<.3:w,h=h,w
  c=candidate(w,h,maxtry=110)
  if c:
   x,y,r=c;dat={'center':[round(x,3),round(y,3)],'size':[round(w,3),round(h,3)],'blocks_projectiles':not half}
   (covers if half else blocks).append(dat)
   reserved.append((r.buffer(.75/scale),'cover' if half else 'block'))
 for i in range(block_n):add_block(False)
 for i in range(cover_n):add_block(True)
 types=KINDS[biome]
 # Frequent variation; ensure every hazard type is used across each pack, but not overloaded in small rooms.
 for i in range(hazard_n):
  htype=types[(idx*2+i)%len(types)]
  wid,hei=(5.7,5.2)
  if htype in ('saw','wires'):wid,hei=(10.5,3.5)
  elif htype in ('spikes','vent'):wid,hei=(6.5,4.5)
  elif htype in ('press','oven'):wid,hei=(7.0,5.7)
  w,h=wid/scale,hei/scale
  c=candidate(w,h,kinds=('door','gap','block','cover','hazard'),maxtry=100)
  if c:
   x,y,r=c;angle=(idx*43+i*79+rng.randrange(-16,16))%360
   dat={'type':htype,'center':[round(x,3),round(y,3)],'size':[round(w,3),round(h,3)],'direction_degrees':angle}
   hazards.append(dat)
   reserved.append((r.buffer(.60/scale),'hazard'))
 return gaps,blocks,covers,hazards

def navigation_ok(poly, doors,gaps,blocks,covers,size):
 # Conservative static walkability check on a raster grid. Moving/timed hazards are passable.
 factor=4
 mask=np.zeros((74*factor+1,100*factor+1),np.uint8)
 contours=np.round(np.asarray(list(poly.exterior.coords))*factor).astype(np.int32)
 cv2.fillPoly(mask,[contours],1)
 for g in gaps:
  cx,cy=g['center'];w,h=g['size'];cv2.rectangle(mask,(int((cx-w/2)*factor),int((cy-h/2)*factor)),(int((cx+w/2)*factor),int((cy+h/2)*factor)),0,-1)
 for b in blocks+covers:
  cx,cy=b['center'];w,h=b['size'];cv2.rectangle(mask,(int((cx-w/2)*factor),int((cy-h/2)*factor)),(int((cx+w/2)*factor),int((cy+h/2)*factor)),0,-1)
 n, labels=cv2.connectedComponents(mask)
 found=[]
 for d in doors:
  pt=d['approach'];x=int(pt[0]*factor);y=int(pt[1]*factor)
  if not (0<=x<mask.shape[1] and 0<=y<mask.shape[0]):return False
  found.append(int(labels[y,x]))
 return all(l>0 for l in found) and len(set(found))==1

# PIL primitives

def polyfill(draw,points,fill,outline=None,width=1):
 points=px(points)
 if len(points)>=3:draw.polygon(points,fill=fill)
 if outline and len(points)>=2:draw.line(points+[points[0]],fill=outline,width=width,joint='curve')
def ellipse(draw,cx,cy,r,fill=None,outline=None,width=2):draw.ellipse((int(cx-r),int(cy-r),int(cx+r),int(cy+r)),fill=fill,outline=outline,width=width)
def prism(draw,pr,center,size,z,basecolor,outline='#26343b',topcolor=None):
 x,y=center;w,h=size
 corners=[(x-w/2,y-h/2),(x+w/2,y-h/2),(x+w/2,y+h/2),(x-w/2,y+h/2)]
 base=[pr.P(p) for p in corners];up=[pr.P(p,z) for p in corners]
 # Vertical faces, back then front; no walkable tops on gameplay surfaces.
 for j in range(4):
  k=(j+1)%4
  face=[base[j],base[k],up[k],up[j]]
  light=(j in (0,1))
  polyfill(draw,face,mix(basecolor,'#000000',.18 if light else .35),outline=outline,width=max(1,int(pr.W/1500)))
 polyfill(draw,up,topcolor or mix(basecolor,'#ffffff',.14),outline=outline,width=max(1,int(pr.W/1400)))
 return base,up

def wall_segment(draw,pr,a,b,wall_height,colors):
 a0=pr.P(a);b0=pr.P(b);a1=pr.P(a,wall_height);b1=pr.P(b,wall_height)
 f=[a0,b0,b1,a1]
 face=mix(colors['wall'],'#060e17',.1 if (a0[0]+b0[0])<pr.W else .24)
 polyfill(draw,f,face,outline='#27333c',width=max(2,int(pr.W*.0011)))
 # slim solid cap
 cap=[a1,b1,(b1[0],b1[1]-max(2,int(3*pr.W/1280))),(a1[0],a1[1]-max(2,int(3*pr.W/1280)))]
 polyfill(draw,cap,colors['top'],outline=None)

def draw_arrow(draw,p1,p2,color,width):
 p1,p2=np.array(p1,dtype=float),np.array(p2,dtype=float);vec=p2-p1
 if np.linalg.norm(vec)<3:return
 vec=vec/np.linalg.norm(vec);perp=np.array([-vec[1],vec[0]])
 draw.line([tuple(p1),tuple(p2)],fill=color,width=width)
 a=p2-vec*width*3+perp*width*1.7;b=p2-vec*width*3-perp*width*1.7
 polyfill(draw,[a,p2,b],color)

def door_image(draw,pr,d,size,biome,pal):
 a,b=d['a'],d['b'];dx=b[0]-a[0];dy=b[1]-a[1];L=math.hypot(dx,dy);ux=dx/L;uy=dy/L;mid=d['mid'];half=d['width']/2
 a=(mid[0]-ux*half,mid[1]-uy*half);b=(mid[0]+ux*half,mid[1]+uy*half)
 z=pr.H*.061/SIZES[size][2]
 q0=pr.P(a);q1=pr.P(b);q2=pr.P(b,z);q3=pr.P(a,z)
 # Outer universal rim geometry but different biome mechanisms
 polyfill(draw,[q0,q1,q2,q3],mix(pal['accent'],'#2a2a30',.38),outline='#d8eef1',width=max(2,round(pr.W/600)))
 pad=.12
 def uv(t,v):
  # Horizontal t across wall and v above floor
  u=(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t)
  return pr.P(u,z*v)
 polyfill(draw,[uv(pad,.07),uv(1-pad,.07),uv(1-pad,.91),uv(pad,.91)],'#152830',outline=pal['accent'],width=max(1,int(pr.W/1200)))
 if biome=='factory':
  for i in range(9):
   v=.11+.08*i
   draw.line([uv(.16,v),uv(.84,v)],fill='#8fabb0' if i%2==0 else '#596c7a',width=max(1,int(pr.W/1400)))
  draw.line([uv(.12,.91),uv(.88,.91)],fill=pal['accent'],width=max(2,int(pr.W/720)))
 elif biome=='maintenance':
  cx,cy=uv(.5,.53);u=np.array(uv(.77,.53))-np.array(cx if False else uv(.5,.53));v=np.array(uv(.5,.80))-np.array([cx,cy]);
  # tilted radial fan silhouette, entirely on the vertical door plane
  rad=0.75
  for k in range(6):
   t=2*math.pi*k/6
   q=lambda radius,angle:np.array([cx,cy]) + (u*math.cos(angle)+v*math.sin(angle))*radius*1.35
   polyfill(draw,[q(.29,t),q(.83,t+.08),q(.82,t+.55),q(.19,t+.46)],pal['accent'],outline='#1a4a53',width=1)
  ellipse(draw,cx,cy,max(3,int(pr.W/260)),fill='#144b55',outline=pal['accent'],width=1)
 elif biome=='boiler_room':
  # Rectangular framed steam duct with recessed ribs, single stable model
  for i in range(4):
   t=.18+.16*i
   draw.line([uv(t,.17),uv(t,.83)],fill='#cbd4c8',width=max(2,int(pr.W/1200)))
  for v in (.22,.42,.62,.82):draw.line([uv(.15,v),uv(.86,v)],fill='#967e78',width=max(1,int(pr.W/1450)))
  draw.line([uv(.16,.12),uv(.84,.12)],fill='#f7d9ad',width=max(2,int(pr.W/1000)))
 else:
  # A high-speed control bus is treated as an electrical data-bus portal, not a vehicle.
  for i in range(5):
   v=.22+i*.115
   draw.line([uv(.17,v),uv(.83,v)],fill=pal['accent'] if i%2==0 else '#7bfbbe',width=max(2,int(pr.W/1050)))
  for t in (.29,.50,.71):
   draw.line([uv(t,.19),uv(t,.81)],fill='#55a58a',width=max(1,int(pr.W/1350)))
 # Flooring access marker; safe around entrance
 p=pr.P(d['approach']);c=pal['accent'];rad=max(6,int(pr.W*.009/SIZES[size][2]));ellipse(draw,p[0],p[1],rad,outline=c,width=max(2,int(pr.W/1700)))
 draw.text((p[0]+rad+3,p[1]-rad/2), 'IN' if d['role']=='entrance' else 'OUT',fill=c,font=font(pr.W*.009,True),stroke_width=1,stroke_fill='#111b20')

def draw_gap(draw,pr,g,W):
 x,y=g['center'];w,h=g['size'];p=[(x-w/2,y-h/2),(x+w/2,y-h/2),(x+w/2,y+h/2),(x-w/2,y+h/2)]
 q=[pr.P(z) for z in p];polyfill(draw,q,'#050b11',outline='#647784',width=max(2,int(W/1120)))
 # visible void lip: negative depth, NOT a walkable raised platform
 for i in (0,3):
  a=q[i];b=q[(i+1)%4]
  draw.line([a,b],fill='#2a333e',width=max(2,int(W/1000)))

def draw_hazard(draw,pr,h,biome,size,pal):
 typ=h['type'];x,y=h['center'];scale=SIZES[size][2];R=max(3.5,pr.W*.0076/scale);p=pr.P((x,y));accent=pal['hazards'][typ]
 def ring(radius,color=accent,width=2):ellipse(draw,p[0],p[1],radius,outline=color,width=width)
 def blob(z=.026):prism(draw,pr,(x,y),(h['size'][0]*.6,h['size'][1]*.6),pr.H*z/scale,accent,topcolor=mix(accent,'#ffffff',.12))
 if typ=='turret':
  blob(.035);cx,cy=pr.P((x,y),pr.H*.040/scale);draw.line([cx,cy,cx+R*2.8,cy-R*.4],fill=accent,width=max(3,int(R*.5)))
  ellipse(draw,cx,cy,R*.55,fill='#c82b3d',outline='#fbd5c9',width=1)
 elif typ=='fan':
  blob(.032)
  cx,cy=pr.P((x,y),pr.H*.04/scale);ring(R*1.1,color='#1cfcf1',width=2)
  for i in range(4):
   ang=i*math.pi/2;v1=(cx+math.cos(ang)*R*.4,cy+math.sin(ang)*R*.4);v2=(cx+math.cos(ang+.8)*R,cy+math.sin(ang+.8)*R)
   draw.line([v1,v2],fill='#072e47',width=max(2,int(R/4)))
  ang=h['direction_degrees']*math.pi/180
  for delta in (-.4,0,.4):
   q0=pr.p(x+math.cos(ang)*4/scale,y+math.sin(ang)*4/scale);q1=pr.p(x+math.cos(ang)*13/scale+math.sin(ang)*delta*3,y+math.sin(ang)*13/scale-math.cos(ang)*delta*3)
   draw_arrow(draw,q0,q1,accent,max(2,int(pr.W/950)))
 elif typ=='wires':
  angle=math.radians(h['direction_degrees']);dx=math.cos(angle)*h['size'][0]*.48;dy=math.sin(angle)*h['size'][0]*.45
  pts=[pr.p(x-dx+i*2*dx/6,y-dy+i*2*dy/6 + ((-1)**i)*.6/scale) for i in range(7)]
  draw.line(pts,fill='#5a3315',width=max(5,int(pr.W/390)))
  draw.line(pts,fill=accent,width=max(3,int(pr.W/690)))
  for q in pts[2::3]:
   draw.line([(q[0]-R*.35,q[1]-R),(q[0]+R*.25,q[1]+R*.3)],fill='#fff09a',width=max(2,int(R/4)))
 elif typ=='saw':
  angle=math.radians(h['direction_degrees']);dx=math.cos(angle)*h['size'][0]*.52;dy=math.sin(angle)*h['size'][0]*.52
  vec=np.array([dx,dy]);perp=np.array([-dy,dx]);perp=perp/(np.linalg.norm(perp)+.0001)*1.05/scale
  q0=pr.P(np.array([x,y])-vec+perp);q1=pr.P(np.array([x,y])+vec+perp)
  q2=pr.P(np.array([x,y])+vec-perp);q3=pr.P(np.array([x,y])-vec-perp)
  polyfill(draw,[q0,q1,q2,q3],'#7a4a2c',outline=accent,width=max(2,int(pr.W/1250)))
  a=np.array(pr.P(np.array([x,y])-vec*.7));b=np.array(pr.P(np.array([x,y])+vec*.7));draw_arrow(draw,a,b,'#ffda8b',max(2,int(pr.W/1380)))
  spikes=[]
  for k in range(16):
   theta=math.pi*2*k/16;r=R*(.9 if k%2==0 else .67)
   spikes.append((p[0]+math.cos(theta)*r,p[1]+math.sin(theta)*r))
  polyfill(draw,spikes,'#e5d7aa',outline='#6a4829',width=1);ring(R*.22,'#55493b',max(2,int(R/5)))
 elif typ=='tesla':
  blob(.05);cx,cy=pr.P((x,y),pr.H*.060/scale);ring(R*2.5,'#ba92ff',max(1,int(pr.W/1800)))
  draw.arc([p[0]-R*4,p[1]-R*4,p[0]+R*4,p[1]+R*4],10,315,fill='#aa7aff',width=max(1,int(pr.W/1450)))
  ellipse(draw,cx,cy,R*.7,fill='#e5cfff',outline='#8026cd',width=2)
  for k in range(4):
   th=k*math.pi*.5;draw.line([(cx,cy),(cx+math.cos(th)*R*1.9,cy+math.sin(th)*R*1.9)],fill='#bb86ff',width=2)
 elif typ=='press':
  # The only raised piece is a non-walkable suspended trap; floor below is not elevated.
  base=[pr.P((x-h['size'][0]/2,y-h['size'][1]/2)),pr.P((x+h['size'][0]/2,y-h['size'][1]/2)),pr.P((x+h['size'][0]/2,y+h['size'][1]/2)),pr.P((x-h['size'][0]/2,y+h['size'][1]/2))]
  polyfill(draw,base,'#d56469',outline='#ffbdaf',width=max(1,int(pr.W/1700)))
  prheight=pr.H*.093/scale
  upper=[pr.P((x-h['size'][0]/2,y-h['size'][1]/2),prheight),pr.P((x+h['size'][0]/2,y-h['size'][1]/2),prheight),pr.P((x+h['size'][0]/2,y+h['size'][1]/2),prheight),pr.P((x-h['size'][0]/2,y+h['size'][1]/2),prheight)]
  polyfill(draw,upper,'#6a4854',outline='#ffa5b3',width=max(2,int(pr.W/1450)))
  draw.line([p,pr.P((x,y),prheight)],fill='#ff889a',width=max(1,int(pr.W/1900)))
  ellipse(draw,p[0],p[1],R*.5,outline='#ffe0a6',width=max(2,int(R/3)))
 elif typ=='spinner':
  ring(R*2.8,'#dd8435',max(1,int(pr.W/1500)));blob(.023)
  for k in range(3):
   th=(h['direction_degrees']+120*k)*math.pi/180
   q=pr.p(x+math.cos(th)*11/scale,y+math.sin(th)*11/scale)
   draw_arrow(draw,p,q,accent,max(3,int(R*.37)))
 elif typ=='spitter':
  blob(.03);q=pr.p(x+10/scale,y-3/scale)
  draw_arrow(draw,p,q,'#fff3a8',max(3,int(R*.48)));ellipse(draw,p[0],p[1],R*.5,fill='#ce4323',outline='#ffd0a0',width=2)
 elif typ=='oven':
  prism(draw,pr,(x,y),(h['size'][0]*.85,h['size'][1]*.8),pr.H*.055/scale,'#914632',topcolor='#c76836')
  cx,cy=pr.P((x,y),pr.H*.04/scale);ellipse(draw,cx,cy,R*.75,fill='#ff9b32',outline='#ffe58d',width=2)
  q=pr.p(x+12/scale,y-2/scale);draw_arrow(draw,p,q,'#ff9238',max(3,int(R*.52)))
 elif typ=='vent':
  w,h0=h['size'];q=[pr.P(z) for z in [(x-w/2,y-h0/2),(x+w/2,y-h0/2),(x+w/2,y+h0/2),(x-w/2,y+h0/2)]]
  polyfill(draw,q,'#a74c2c',outline='#f4a95f',width=max(2,int(pr.W/1300)))
  for t in (-.26,0,.26):draw.line([pr.p(x-w*.35,y+h0*t),pr.p(x+w*.35,y+h0*t)],fill='#e4ad62',width=max(2,int(pr.W/1120)))
 elif typ=='can':
  blob(.04);cx,cy=pr.P((x,y),pr.H*.044/scale);ellipse(draw,cx,cy,R*.60,fill='#c6dd61',outline='#4b5c21',width=2)
  draw.text((cx-R*.27,cy-R*.52),'!',font=font(R*1.1,True),fill='#403521')
 elif typ=='acid':
  blob(.034);cx,cy=pr.P((x,y),pr.H*.04/scale);ellipse(draw,cx,cy,R*.6,fill='#a5ff75',outline='#297950',width=2)
  q=pr.p(x+11/scale,y-1/scale);draw_arrow(draw,p,q,accent,max(2,int(R*.4)))
 elif typ=='spikes':
  w,h0=h['size'];q=[pr.P(z) for z in [(x-w/2,y-h0/2),(x+w/2,y-h0/2),(x+w/2,y+h0/2),(x-w/2,y+h0/2)]]
  polyfill(draw,q,'#707c72',outline='#dceac6',width=max(1,int(pr.W/1700)))
  for i in range(3):
   for j in range(2):
    q=pr.p(x+(i-1)*w*.25,y+(j-.5)*h0*.4)
    polyfill(draw,[(q[0]-R*.36,q[1]+R*.4),(q[0]+R*.38,q[1]+R*.4),(q[0],q[1]-R*.7)],'#f4eecf',outline='#738070')
 elif typ=='barrel':
  prism(draw,pr,(x,y),(h['size'][0]*.55,h['size'][1]*.65),pr.H*.04/scale,'#bb8a3b',topcolor='#ffd35a');cx,cy=pr.P((x,y),pr.H*.046/scale)
  draw.text((cx-R*.32,cy-R*.6),'X',fill='#74482b',font=font(R*.95,True))

def render_room(room, dst):
 biome=room['biome'];pal=PALS[biome];W,H=room['pixel_size'];pr=Project(W,H);d=Image.new('RGB',(W,H),'#101821');D=ImageDraw.Draw(d)
 scale=SIZES[room['size']][2]
 titleht=int(H*.106)
 D.rounded_rectangle((int(W*.02),int(H*.028),int(W*.98),int(H*.105)),radius=int(H*.014),outline=mix(pal['accent'],'#87999a',.55),width=max(2,int(W/1450)),fill='#182129')
 f=font(H*.028,True)
 D.text((W*.037,H*.045),f"{room['number']:02d}  {room['name'].upper()}",fill='#f3f6f6',font=f)
 D.text((W*.965,H*.052),f"{room['size'].upper()}   •   {W} × {H} px",font=font(H*.018,True),fill=pal['accent'],anchor='ra')
 coords=room['floor_polygon'];floorp=[pr.P(p) for p in coords]
 # Single continuous floor slab; thickness below floor plane is not a raised walkway.
 slab= max(4,int(H*.016))
 for i,p in enumerate(coords):
  q=coords[(i+1)%len(coords)];a=pr.P(p);b=pr.P(q);aa=(a[0],a[1]+slab);bb=(b[0],b[1]+slab)
  if (a[1]+b[1])>pr.cy*2:
   polyfill(D,[a,b,bb,aa],mix(pal['wall'],'#101821',.35),outline='#27323e')
 polyfill(D,floorp,pal['floor'],outline='#d1d6d4',width=max(2,int(W*.00085)))
 # Ground-plane projected grid, clipped only to walkable floor.
 mask=Image.new('L',(W,H),0);md=ImageDraw.Draw(mask);md.polygon(px(floorp),fill=255)
 grid=Image.new('RGBA',(W,H),(0,0,0,0));gd=ImageDraw.Draw(grid)
 for X in np.arange(0,101,10):gd.line([pr.p(float(X),0),pr.p(float(X),74)],fill=(*mix(pal['floor'],'#62717b',.40),85),width=max(1,int(W/1950)))
 for Y in np.arange(0,75,10):gd.line([pr.p(0,float(Y)),pr.p(100,float(Y))],fill=(*mix(pal['floor'],'#617078',.35),85),width=max(1,int(W/1950)))
 grid.putalpha(ImageChops.multiply(grid.getchannel('A'),mask))
 d=Image.alpha_composite(d.convert('RGBA'),grid).convert('RGB')
 D=ImageDraw.Draw(d)
 for g in room['gaps']:draw_gap(D,pr,g,W)
 # Walls and door frame on back side before obstacle drawing.
 walls=[]
 for i,p in enumerate(coords):
  q=coords[(i+1)%len(coords)];walls.append(( (pr.P(p)[1]+pr.P(q)[1])/2,p,q ))
 walls.sort(key=lambda w:w[0]);wh=H*.076/scale
 for depth,p,q in walls:
  if depth<pr.cy:wall_segment(D,pr,p,q,wh,pal)
 # Partial cover and obstacles with actual volume, no walkable elevation.
 items=[]
 for kind in ['obstacles','partial_cover']:
  for o in room[kind]:items.append((pr.P(o['center'])[1],kind,o))
 for h in room['hazards']:items.append((pr.P(h['center'])[1],'hazard',h))
 items.sort(key=lambda o:o[0])
 for _,kind,item in items:
  if kind=='obstacles':prism(D,pr,item['center'],item['size'],H*.063/scale,'#59636b',topcolor='#778691')
  elif kind=='partial_cover':prism(D,pr,item['center'],item['size'],H*.025/scale,'#8b9aa4',topcolor='#afbbc1')
  else:draw_hazard(D,pr,item,biome,room['size'],pal)
 for depth,p,q in walls:
  if depth>=pr.cy:wall_segment(D,pr,p,q,wh,pal)
 for door in room['doors']:door_image(D,pr,door,room['size'],biome,pal)
 # Layout motif and Hades-like biome short focus line
 fsz=int(H*.0142)
 D.text((W*.047,H*.845),room['motif'].upper().replace('-','  /  '),fill=pal['accent'],font=font(fsz,True))
 D.text((W*.047,H*.871),room['focus'],fill='#c9d3d7',font=font(fsz*.91))
 # Explicit blockout legend: distinguish every gameplay class without detailed decoration
 y1=int(H*.914);y2=int(H*.976)
 D.rounded_rectangle((int(W*.02),y1,int(W*.98),y2),radius=int(H*.01),fill='#182128',outline='#586b71',width=max(1,int(W/1900)))
 legend=[('WALL',pal['wall']),('HALF COVER','#aebdc6'),('BLOCK','#54616b'),('GAP','#03080f')]
 legend +=[(k.upper(),pal['hazards'][k]) for k in KINDS[biome]]
 legend +=[('EXIT',pal['accent'])]
 pad=W*.032;usable=W*.932;step=usable/len(legend);legfont=font(H*.0135,True)
 for i,(lab,col) in enumerate(legend):
  x=pad+i*step
  D.rectangle((int(x),int(y1+H*.021),int(x+H*.014),int(y1+H*.036)),fill=col)
  D.text((x+H*.021,y1+H*.021),lab,fill='#e0e6e5',font=legfont)
 D.text((W*.972,H*.885),f"{room['biome_display'].upper()} / {room['number']:02d} OF 30",fill='#94a6ab',font=font(H*.012,True),anchor='ra')
 dst.parent.mkdir(parents=True,exist_ok=True)
 d.save(dst,optimize=False,compress_level=6)
 return dst

def newroom(biome,biome_idx,idx,used_shapes):
 size=CATEGORIES[idx];W,H,scale=SIZES[size]
 seed=(biome_idx+1)*345191+idx*17237+81
 rng=random.Random(seed);pr=Project(W,H)
 for tries in range(90):
  poly=silhouette(rng,seed,biome_idx,idx+tries*7)
  shape_key=hashlib.sha256(str([(round(x,2),round(y,2)) for x,y in list(poly.exterior.coords)[:-1]]).encode()).hexdigest()
  if shape_key in used_shapes:continue
  doorlist=doors_for(poly,size,rng,pr)
  if not doorlist:continue
  for route_attempt in range(6):
   gaps,obs,cov,hazards=place_objects(poly,doorlist,rng,size,biome,idx)
   if len(gaps)<max(1, {'small':1,'medium':2,'large':3}[size]):continue
   if len(hazards)<max(1,{'small':1,'medium':2,'large':3}[size]):continue
   if navigation_ok(poly,doorlist,gaps,obs,cov,size):break
  else:continue
  used_shapes.add(shape_key)
  name=NAMES[biome][idx]
  focus={
   'maintenance':['Line-of-sight control, turret pressure, and airflow-driven repositioning','Fan displacement creates alternate routes around electrified floor'],
   'factory':['Moving blade timing intersects telegraphed machinery attacks','Tesla area denial forces re-routing through cover lanes'],
   'boiler_room':['Fire arcs and vent timing define safe movement windows','Thermal crossfire and explosive placement create risk-reward routes'],
   'toxin_refinery':['Acid firing lanes, spike boundaries, and chain-reaction barrels','Toxic crossfire makes protected flanking lanes valuable']
  }[biome][idx%2]
  data={
   'number':idx+1,'id':f'{biome[:3]}_{idx+1:02d}','biome':biome,'biome_display':biome.replace('_',' ').title(),
   'size':size,'name':name,'motif':MOTIFS[idx], 'focus':focus,'seed':seed,'pixel_size':[W,H],
   'world_size_example':[round(40*scale,2),round(29.6*scale,2)],
   'floor_polygon':[[round(x,4),round(y,4)] for x,y in list(poly.exterior.coords)[:-1]],
   'area_normalized':round(poly.area,2),'area_example_world2':round(poly.area*(scale**2),2),
   'gaps':gaps,'obstacles':obs,'partial_cover':cov,'hazards':hazards,
   'doors':[{k: ([round(x,4) for x in v] if isinstance(v,(tuple,list)) else round(v,4) if isinstance(v,float) else v) for k,v in d.items() if k not in ('screen',)} for d in doorlist],
   'geometry_signature':shape_key,
   'validation':{'door_on_straight_wall':True,'all_exit_approaches_connected':True,'no_raised_walkable_areas':True}
  }
  return data
 raise RuntimeError(f'Could not generate valid room {biome} {idx}')

def contact_sheet(paths,dest,title,columns=3,thumbw=590):
 images=[Image.open(p).convert('RGB') for p in paths]
 ratio=16/9;th=int(thumbw/ratio);pad=20;header=100;cap=38
 rows=math.ceil(len(images)/columns)
 canvas=Image.new('RGB',(columns*thumbw+(columns+1)*pad,rows*(th+cap+pad)+header+pad),'#101821');D=ImageDraw.Draw(canvas)
 D.text((pad,32),title.upper(),font=font(33,True),fill='#ebf4f4')
 for i,im in enumerate(images):
  col=i%columns;row=i//columns;x=pad+col*(thumbw+pad);y=header+row*(th+cap+pad)
  img=im.resize((thumbw,th),Image.Resampling.LANCZOS);canvas.paste(img,(x,y))
  D.text((x+8,y+th+6),paths[i].stem.replace('_',' ').upper(),fill='#dbe5e6',font=font(15,True))
 canvas.save(dest,compress_level=5)
 for im in images:im.close()


def write_readmes(rooms):
 lines=['# Four Biomes — 120 Unique Gameplay Blockouts','',
        'A gameplay-first blockout collection, inspired by the chamber design principles of Hades, but with original geometry. These are not copied Hades rooms.','',
        '## Files and dimensions','',
        '- 4 biomes × (6 small + 14 medium + 10 large) = 120 individual PNG room blockouts.',
        '- Small: 1280 × 720 px. Medium: 2688 × 1512 px (4.41× pixel area). Large: 3200 × 1800 px (6.25× pixel area).',
        '- Each biome folder contains `small`, `medium`, and `large` image folders and 3 overview contact sheets.',
        '- `all_room_geometry.json` includes all room polygons, solid obstacles, half cover, gaps, hazards, and identical entrance/exit door styles.',
        '- `room_index.csv` includes names, counts, dimensions, and hazard inventory.',
        '- `generation_source.py` is included to reproduce the set.',
        '', '## Gameplay analysis before decoration', '',
        'Hades-style chamber design works because the combat arena is authored as a tactical space: floor and walls establish positioning, cover determines projectile interactions, and traps create movement choices. This set uses independent silhouettes and encounter motifs rather than re-skinning one layout. All floors are single-elevation and no platforms are walkable.','',
        '### Shared collision vocabulary','',
        '| Element | Gameplay blockout behavior |','|---|---|',
        '| Solid wall | Blocks movement and projectiles; defines the chamber edge |',
        '| Half cover | Blocks movement but allows most projectiles to pass overhead |',
        '| Full obstacle | Blocks movement and projectiles; cannot be climbed |',
        '| Floor gap | Non-walkable void; fixed black floor cutout |',
        '| Hazard | A damaging/time-sensitive mechanic; specific to the biome |',
        '| Exit | Reused identical mechanism per biome, always on straight walls |',
        '', '### Hazard analysis by biome', '',
        '#### Maintenance',
        '- Projectile-shooting turrets set exposed firing lanes. Place them opposite useful cover, not at spawn.',
        '- Blower fans change player position and exert force toward/away from obstacles, making movement choices meaningful.',
        '- Open wires punish predictable crossing paths. Avoid forcing a player to cross an unavoidable hazard and projectile simultaneously.',
        '- Spinning-vent entrances/exits use the same mechanically framed six-blade model at every portal.',
        '', '#### Factory',
        '- Sawblades travel back and forth along floor-level strips. Their travel direction is shown by a rail arrow and blade icon.',
        '- Tesla machines create pulsing circular danger fields; their ring is an attack indication, not a raised floor.',
        '- Breakable ceiling traps telegraph a crush zone and then descend. Ceiling slabs are non-walkable suspended objects, not platforms.',
        '- Roll-up exits use the same horizontal shutter slats at every portal.',
        '', '#### Boiler Room',
        '- Fire spinners project rotating fire arms; place them to create alternating safe sectors.',
        '- Fire spitters control directed lanes. Furnace/oven spitters use a heavier frontal flame attack.',
        '- Floor fire vents create intermittent danger at specific spots.',
        '- Explosive cans provide risk/reward chain reactions, ideally not in unavoidable entrance positions.',
        '- Steam-duct exits use identical framed ribbed portals on straight walls.',
        '', '#### Toxin Refinery',
        '- Acid spitters create ranged toxic lanes; use cover and alternative approaches for counterplay.',
        '- Spike traps threaten selected floor strips or intersections; floor elsewhere remains navigable.',
        '- Exploding barrels provide an opportunity to damage enemies but increase risk near cover.',
        '- The requested high-speed control buses are interpreted as high-speed electrical data-bus portals with uniform illuminated parallel signal rails.',
        '', '## Perspective',
        'The elevated orthographic three-quarter projection gives every wall and non-walkable obstacle visible thickness and height. Ground features remain on one planar floor. Rooms are not flat overhead schematics.',
        '', '## Uniqueness and verification',
        f'- {len(rooms)} distinct room names and {len(set(r["geometry_signature"] for r in rooms))} distinct exact outer-footprint signatures.',
        '- Unique chamber-edge silhouettes are combined with different encounter motifs, hazard counts, and obstruction placements.',
        '- Geometry placement validation confirmed that all door approaches are in the same traversable static floor component.',
        '- This validation does not simulate real-time hazard timings, enemy AI, or movement ability clearance; playtesting is still necessary.',
        '- Higher-resolution images are intentionally separate, not squeezed into one overview image.',
        ]
 (ROOT/'README_AND_DESIGN_ANALYSIS.md').write_text('\n'.join(lines),encoding='utf-8')


def main(limit=None):
 time0=time.time();rooms=[];used=set();index=[]
 for biome_idx,biome in enumerate(NAMES):
  pack=ROOT/biome
  for i in range(30 if limit is None else min(limit,30)):
   room=newroom(biome,biome_idx,i,used)
   rsize=room['size'];slug=''.join(c.lower() if c.isalnum() else '-' for c in room['name']).strip('-')
   filename=f'{i+1:02d}_{slug}.png';path=pack/rsize/filename
   render_room(room,path)
   room['image']=str(path.relative_to(ROOT))
   rooms.append(room)
   index.append({'biome':room['biome_display'],'number':i+1,'name':room['name'],'size':rsize,'width_px':room['pixel_size'][0],'height_px':room['pixel_size'][1],
    'image':room['image'],'motif':room['motif'],'floor_area_world2':room['area_example_world2'],'entry_count':1,'exit_count':len(room['doors'])-1,
    'gap_count':len(room['gaps']),'obstacle_count':len(room['obstacles']),'half_cover_count':len(room['partial_cover']),
    'hazards':'; '.join(h['type'] for h in room['hazards'])})
   print(f'GENERATED {len(rooms):3d}/120 [{biome:15}] [{rsize:6}] {room["name"]:30} {(time.time()-time0):.1f}s',flush=True)
  for group in ('small','medium','large'):
   paths=[ROOT/r['image'] for r in rooms if r['biome']==biome and r['size']==group]
   if paths:contact_sheet(paths,pack/f'overview_{group}.png',f'{biome.replace("_"," ")} — {group}: {len(paths)} rooms',columns=3 if group=='small' else 2 if group=='large' else 3,thumbw=490)
  print(f'COMPLETED {biome} with overview sheets',flush=True)
 (ROOT/'all_room_geometry.json').write_text(json.dumps({'projection':'elevated orthographic three-quarter','world_area_scale_factors':{x:SIZES[x][2] for x in SIZES},'collision_rules':{'wall':'blocks movement and projectiles','partial_cover':'blocks movement, projectiles pass over','obstacle':'blocks movement and projectiles','gap':'non-walkable void','hazard':'biome-specific time/position danger','doors':'identical per biome and on straight exterior wall segments'},'rooms':rooms},indent=2),encoding='utf-8')
 with open(ROOT/'room_index.csv','w',newline='',encoding='utf-8') as f:
  writer=csv.DictWriter(f,fieldnames=index[0].keys());writer.writeheader();writer.writerows(index)
 write_readmes(rooms)
 assert len(used)==len(rooms)
 counts=Counter((r['biome'],r['size']) for r in rooms)
 if not limit:
  assert len(rooms)==120
  for biome in NAMES:
   for size,n in [('small',6),('medium',14),('large',10)]:assert counts[(biome,size)]==n
  assert len({r['name'] for r in rooms})==120
 # A single archive and optional per-biome archives for easier downloading.
 archives=[]
 for biome in NAMES:
  target=Path('/mnt/data')/f'{biome}_30_unique_blockouts.zip'
  with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=5) as z:
   for p in (ROOT/biome).rglob('*'):
    if p.is_file():z.write(p,arcname=str(p.relative_to(ROOT)))
   for p in [ROOT/'all_room_geometry.json',ROOT/'room_index.csv',ROOT/'README_AND_DESIGN_ANALYSIS.md',ROOT/'generate_all.py']:
    z.write(p,arcname=p.name)
  archives.append(target)
 target=Path('/mnt/data')/'ALL_4_BIOMES_120_UNIQUE_BLOCKOUTS.zip'
 with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=5) as z:
  for p in ROOT.rglob('*'):
   if p.is_file() and p.name!='__pycache__':z.write(p,arcname=str(p.relative_to(ROOT)))
 print('TOTAL',len(rooms),'UNIQUE FOOTPRINTS',len(used),'TIME',round(time.time()-time0,1),'ARCHIVE',target,target.stat().st_size,flush=True)

if __name__=='__main__':
 import sys
 main(int(sys.argv[1]) if len(sys.argv)>1 else None)
