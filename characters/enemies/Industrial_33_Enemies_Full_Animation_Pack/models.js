// All geometry is generated here: 33 individual graybox enemy bodies.
// World Y is vertical; local +Z is forward. No external 3D libraries.
const PAL={shell:'#b4bcc0', top:'#d7dbdc', metal:'#939da2', dark:'#58646b', black:'#2d3940', edge:'#7f898e', detail:'#dce0de', warn:'#cc9258', glass:'#7e969d', cable:'#626b72'};
const TAU=Math.PI*2;
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const lerp=(a,b,t)=>a+(b-a)*t;
const I=()=>[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];
function MM(a,b){const m=new Array(16).fill(0);for(let j=0;j<4;j++)for(let i=0;i<4;i++)for(let k=0;k<4;k++)m[j*4+i]+=a[k*4+i]*b[j*4+k];return m;}
function T(x=0,y=0,z=0){let a=I();a[12]=x;a[13]=y;a[14]=z;return a;}
function RX(a=0){let c=Math.cos(a),s=Math.sin(a),m=I();m[5]=c;m[6]=s;m[9]=-s;m[10]=c;return m;}
function RY(a=0){let c=Math.cos(a),s=Math.sin(a),m=I();m[0]=c;m[2]=-s;m[8]=s;m[10]=c;return m;}
function RZ(a=0){let c=Math.cos(a),s=Math.sin(a),m=I();m[0]=c;m[1]=s;m[4]=-s;m[5]=c;return m;}
const rand3=(i,t)=>Math.sin(i*31.13+t*.73)*.5+.5;
class ModelDraw{
 constructor(){this.polys=[];this.lines=[];this.stack=[I()];}
 get m(){return this.stack.at(-1)}
 push(x=0,y=0,z=0,rx=0,ry=0,rz=0){let m=MM(this.m,T(x,y,z));m=MM(m,RY(ry));m=MM(m,RX(rx));m=MM(m,RZ(rz));this.stack.push(m);}
 pop(){this.stack.pop();}
 v(p){const m=this.m,x=p[0],y=p[1],z=p[2];return [m[0]*x+m[4]*y+m[8]*z+m[12],m[1]*x+m[5]*y+m[9]*z+m[13],m[2]*x+m[6]*y+m[10]*z+m[14]];}
 poly(ps,mat='shell'){this.polys.push({v:ps.map(p=>this.v(p)),mat});}
 line(a,b,mat='edge',width=1.5){this.lines.push({a:this.v(a),b:this.v(b),mat,width});}
 box(x,y,z,w,h,d,mat='shell'){
  let X=w/2,Y=h/2,Z=d/2,p=[[-X,-Y,-Z],[X,-Y,-Z],[X,Y,-Z],[-X,Y,-Z],[-X,-Y,Z],[X,-Y,Z],[X,Y,Z],[-X,Y,Z]].map(q=>[q[0]+x,q[1]+y,q[2]+z]);
  for(const [a,b,c,e] of [[0,1,2,3],[4,7,6,5],[0,3,7,4],[1,5,6,2],[3,2,6,7],[0,4,5,1]])this.poly([p[a],p[b],p[c],p[e]],mat);
 }
 cyl(x,y,z,r,h,axis='y',mat='metal',steps=10,r2=r){
  const pp=(a,at,rad)=>{
    if(axis==='y')return [x+Math.cos(a)*rad,y+at,z+Math.sin(a)*rad];
    if(axis==='x')return [x+at,y+Math.cos(a)*rad,z+Math.sin(a)*rad];
    return [x+Math.cos(a)*rad,y+Math.sin(a)*rad,z+at];
  };
  let lo=[],hi=[];for(let i=0;i<steps;i++){let a=i*TAU/steps;lo.push(pp(a,-h/2,r));hi.push(pp(a,h/2,r2));}
  for(let i=0;i<steps;i++)this.poly([lo[i],lo[(i+1)%steps],hi[(i+1)%steps],hi[i]],mat);
  this.poly([...lo].reverse(),mat);this.poly(hi,mat);
 }
 sph(x,y,z,rad,mat='shell',rings=5,slices=10){for(let j=0;j<rings;j++){const a=-Math.PI/2+j*Math.PI/rings,b=-Math.PI/2+(j+1)*Math.PI/rings;for(let k=0;k<slices;k++){let p=k*TAU/slices,q=(k+1)*TAU/slices;let f=(t,u)=>[x+rad*Math.cos(t)*Math.cos(u),y+rad*Math.sin(t),z+rad*Math.cos(t)*Math.sin(u)];this.poly([f(a,p),f(a,q),f(b,q),f(b,p)],mat);}}}
 rod(a,b,r=.07,mat='metal',steps=7){let d=b.map((v,i)=>v-a[i]),L=Math.hypot(...d);if(!L)return;d=d.map(v=>v/L);let n=Math.abs(d[1])<.94?[0,1,0]:[1,0,0];let u=[d[1]*n[2]-d[2]*n[1],d[2]*n[0]-d[0]*n[2],d[0]*n[1]-d[1]*n[0]],ul=Math.hypot(...u);u=u.map(v=>v/ul);let v=[d[1]*u[2]-d[2]*u[1],d[2]*u[0]-d[0]*u[2],d[0]*u[1]-d[1]*u[0]];for(let k=0;k<steps;k++){let p=k*TAU/steps,q=(k+1)*TAU/steps;let pt=(c,t)=>c.map((a0,i)=>a0+r*(u[i]*Math.cos(t)+v[i]*Math.sin(t)));this.poly([pt(a,p),pt(a,q),pt(b,q),pt(b,p)],mat);}}
 ring(x,y,z,r,axis='y',mat='metal',width=.045,steps=18){let ps=[];for(let k=0;k<=steps;k++){let a=k/steps*TAU;if(axis==='z')ps.push([x+Math.cos(a)*r,y+Math.sin(a)*r,z]);else if(axis==='x')ps.push([x,y+Math.sin(a)*r,z+Math.cos(a)*r]);else ps.push([x+Math.cos(a)*r,y,z+Math.sin(a)*r]);}for(let k=0;k<steps;k++)this.rod(ps[k],ps[k+1],width,mat,4);}
 wedge(x,y,z,w,h,d,mat='shell'){let x1=x-w/2,x2=x+w/2,y1=y-h/2,y2=y+h/2,z1=z-d/2,z2=z+d/2;let lo=[[x1,y1,z1],[x2,y1,z1],[x2,y1,z2],[x1,y1,z2]],hi=[[x-w*.33,y2,z1],[x+w*.33,y2,z1],[x,y2,z2+.17*d]];this.poly(lo,mat);this.poly([lo[0],lo[1],hi[1],hi[0]],mat);this.poly([lo[1],lo[2],hi[2],hi[1]],mat);this.poly([lo[2],lo[3],hi[2]],mat);this.poly([lo[3],lo[0],hi[0],hi[2]],mat);this.poly(hi,mat);}
}
function makeModel(enemy,view={}){
 const b=new ModelDraw(),id=enemy.id, t=view.t||0, phase=view.phase||'idle', q=view.progress||0;
 const move=view.moving||0, elite=!!view.elite;
 const wave=Math.sin(t*8)*move, hover=Math.sin(t*3.3)*.055;const hit=phase==='active'?1:phase==='windup'?.55:phase==='recover'?.26:0;
 const punch=Math.sin(clamp(q,0,1)*Math.PI)*hit;
 const cyc=t*6, arm=(Math.sin(cyc)*move*.28);const core='dark', shell='shell',steel='metal',light='top',trim='edge';
 const B=(...a)=>b.box(...a), C=(...a)=>b.cyl(...a), S=(...a)=>b.sph(...a), R=(...a)=>b.rod(...a), ring=(...a)=>b.ring(...a),W=(...a)=>b.wedge(...a);
 function foot(x,wide=false){b.push(x,.0,Math.sin(cyc+(x<0?0:Math.PI))*move*.13,0,0,0);B(0,.14,.07,wide?.42:.28,.27,.48,steel);b.pop();}
 function leg(x,top=1.1,short=false){let f=Math.sin(cyc+(x<0?0:Math.PI))*move*.17;R([x,top,0],[x,top*.51,.1+f],short?.105:.115,steel);R([x,top*.51,.1+f],[x,.22,.11+f],.09,trim);foot(x);}
 function humanoid({h=1.95,w=.75,head='box',arms=true,legs=true,feet=true,shoulders=.47}={}){
  if(legs){leg(-w*.32,h*.47);leg(w*.32,h*.47);}
  B(0,h*.64,0,w,h*.42,.55,shell);B(0,h*.65,-.31,w*.7,h*.26,.06,steel);
  if(head==='box'){B(0,h-.13,.12,w*.53,.28,.4,light);B(0,h-.13,.35,w*.39,.09,.07,core);}
  if(head==='cyl'){C(0,h-.12,.12,w*.28,.32,'y',steel,10);B(0,h-.12,.39,w*.34,.1,.06,core);}
  if(arms)for(let s of [-1,1]){let x=s*shoulders;b.push(x,h*.77,0,arm*.22,0,s*(hit*.28+wave*.2));B(s*.11,-.14,.05,.24,.43,.26,steel);R([s*.1,-.27,.09],[s*.18,-.52,.23],.11,trim);b.pop();}
 }
 function fins(x,z,h=.5){b.push(x,.0,z,0,0,x<0?-.1:.1);W(0,h*.45,0,.2,h,.35,steel);b.pop();}
 function eye(x,y,z,r=.25,axis='z'){C(x,y,z,r,.13,axis,steel,14);C(x,y,z+(axis==='z'?.083:0),r*.72,.15,axis,core,14);C(x,y,z+(axis==='z'?.17:0),r*.36,.08,axis,light,12);}
 function claw(x,y,z,s=1){R([x,y,z],[x,y-.22*s,z+.28*s],.075,steel);R([x-.1*s,y-.12*s,z+.15*s],[x-.21*s,y-.3*s,z+.38*s],.048,trim);R([x+.1*s,y-.12*s,z+.15*s],[x+.2*s,y-.3*s,z+.38*s],.048,trim);}
 function rotor(x,y,z,r=.27){C(x,y,z,r,.42,'z',steel,12);C(x,y,z+.25,r*.7,.045,'z',core,12);ring(x,y,z+.29,r*.55,'z',light,.018,12);for(let k=0;k<3;k++){let a=t*9+k*TAU/3;R([x,y,z+.30],[x+Math.cos(a)*r*.55,y+Math.sin(a)*r*.55,z+.30],.026,steel);}}
 function wrench(x,y,z,s=1){R([x,y,z],[x,y-.15*s,z+.36*s],.055,light);for(let a of [-1,1])R([x+a*.1*s,y-.13*s,z+.32*s],[x+a*.13*s,y-.02*s,z+.52*s],.06,steel);}
 function wheel(x,y,z,r=.2){C(x,y,z,r,.18,'x',steel,12);C(x,y,z,r*.56,.23,'x',core,12);ring(x,y,z,r*.78,'x',trim,.024,12);}
 function spool(x,y,z,r=.33){C(x,y,z,r,.24,'x',steel,14);ring(x+.145,y,z,r*.8,'x',core,.042);ring(x-.145,y,z,r*.8,'x',core,.042);}
 function pipeLimb(a,end,r=.08){R(a,end,r,steel);C(end[0],end[1],end[2],r*1.7,.13,'y',trim,8);}
 function warning(x,y,z){B(x,y,z,.12,.07,.10,'warn');}
 let yaw=view.yaw||0, pitch=0, roll=move*Math.sin(t*6)*.055;
 let fly=['Inspection Wasp','Dust Mites','Foreman Node','Signal Scrambler','Cinder Kettle','Soot Midges','Spark Wisps','Heat Mirage'].includes(enemy.name);
 if(fly){pitch=hit*.16+move*.12;roll+=Math.sin(t*4)*.05;}
 if(['Soot Torpedo','Conveyor Hound','Corrosion Eel'].includes(enemy.name))pitch+=hit*.12;
 if(phase==='death')pitch+=q*1.04;
 b.push(0,(fly?.50+hover:0),0,pitch,yaw,roll);
 switch(id){
 case 0: // Inspection Wasp -- preserve triangular wedge eye, twin jets, fins and telescopic probe
  W(0,1.36,.04,.94,.49,.90,shell);B(0,1.45,-.25,.67,.20,.70,light);B(0,1.24,.21,.48,.28,.35,steel);
  for(let x of [-.59,.59]){rotor(x,1.36,-.1,.25);fins(x,-.36,.43);}eye(0,1.34,.59,.25);warning(0,1.64,-.2);
  R([0,1.14,.23],[0,.74-hit*.18,.45],.11,steel);R([0,.74-hit*.18,.45],[0,.43-hit*.36,.58],.054,light);break;
 case 1: // Dust Mites: hovering brush cluster
  for(let i=0;i<6;i++){let a=i*TAU/6+t*.21,rr=i===0?0:.57;let x=Math.cos(a)*rr,z=Math.sin(a)*rr;b.push(x,.67+.07*Math.sin(t*4+i),z,0,0,.05*Math.sin(t*4+i));S(0,.12,0,.17,shell,4,8);C(0,-.02,0,.16,.07,'y',core,10);ring(0,-.065,0,.17,'y',light,.027,12);eye(0,.13,.17,.07);rotor(-.19,.14,-.06,.07);rotor(.19,.14,-.06,.07);b.pop();}break;
 case 2: // Pressure Purger
  C(0,.28,0,.88,.48,'y',steel,8);C(0,1.35,0,.59,1.6,'y',shell,12);C(0,2.2,0,.52,.25,'y',steel,12);C(0,2.42,0,.14,.18,'y','warn');
  for(let k=0;k<8;k++){let a=k*TAU/8;b.push(Math.sin(a)*.62,1.28,Math.cos(a)*.62,0,a,0);B(0,0,.03,.32,.48,.15,core);B(0,0,.13,.24,.29,.03,trim);b.pop();}
  for(let k=0;k<4;k++){let a=k*TAU/4;R([Math.sin(a)*.55,.8,Math.cos(a)*.55],[Math.sin(a)*.87,.15,Math.cos(a)*.87],.08,steel);}eye(0,1.85,.63,.16);break;
 case 3: // Spanner Guard
  humanoid({h:2,w:.86,head:'cyl',shoulders:.57});for(let s of [-1,1]){b.push(s*.62,1.25,.13,0,0,s*(arm*.25+hit*.65));wrench(s*.1,-.05,.10,1.5);b.pop();}break;
 case 4: // Foreman Node
  C(0,1.25,0,.72,.90,'y',shell,12);C(0,1.66,0,.62,.18,'y',light);eye(0,1.25,.75,.23);C(0,.75,0,.52,.2,'y',steel,12);
  for(let k=0;k<6;k++){let a=k*TAU/6;b.push(Math.sin(a)*.63,.74,Math.cos(a)*.63,0,a,0);B(0,0,.04,.35,.18,.34,steel);B(0,-.1,.2,.25,.08,.12,core);b.pop();}
  for(let k=0;k<4;k++){let a=k*TAU/4;R([0,1.4,0],[Math.sin(a)*1.0,1.16,Math.cos(a)*1.0],.09,steel);claw(Math.sin(a)*1.0,1.16,Math.cos(a)*1.0,.65);}break;
 case 5: // Cable Snare Unit
  B(0,.96,0,.73,.50,.86,shell);spool(-.42,1.09,0,.34);for(let k=0;k<3;k++){let a=k*TAU/3;R([Math.sin(a)*.22,.85,Math.cos(a)*.22],[Math.sin(a)*.62,.15,Math.cos(a)*.62],.12,steel);B(Math.sin(a)*.62,.14,Math.cos(a)*.62,.2,.18,.25,steel);}
  R([.22,1.11,.23],[.48,1.17,.63],.12,steel);R([.48,1.17,.63],[.48+hit*.16,1.17,.92+hit*.3],.08,light);claw(.48+hit*.16,1.17,.92+hit*.3,1.1);break;
 case 6: // Phase Custodian
  humanoid({h:2.18,w:.53,head:'box',shoulders:.33});for(let k=0;k<3;k++)B(0,.97+k*.28,.29,.44,.07,.09,k%2?'steel':'edge');R([.38,1.20,.20],[.54,.64,.53+hit*.28],.045,core);break;
 case 7: // Signal Scrambler
  S(0,1.3,0,.48,shell,6,12);ring(0,1.3,0,.66,'y',steel,.05,20);ring(0,1.3,0,.58,'x',trim,.035,16);for(let k=0;k<8;k++){let a=k*TAU/8;R([Math.sin(a)*.35,1.32,Math.cos(a)*.35],[Math.sin(a)*.86,1.66,Math.cos(a)*.86],.04,steel);S(Math.sin(a)*.86,1.66,Math.cos(a)*.86,.07,core,3,7);}eye(0,1.37,.41,.15);break;
 case 8: // Conveyor Hound
  B(0,.77,0,.96,.55,1.28,shell);W(0,.67,.67,.78,.4,.52,steel);for(let s of [-1,1]){B(s*.55,.75,-.08,.25,.38,1.25,core);for(let z of [-.49,0,.49]){wheel(s*.62,.45,z,.19);R([s*.48,.62,z],[s*.59,.15,z+.09*Math.sin(cyc+z*8)],.065,trim);}}
  for(let k=0;k<3;k++)R([-.24+k*.24,.63,.85],[-.24+k*.24,.73,.91],.07,'metal');warning(-.25,1.11,.51);warning(.25,1.11,.51);break;
 case 9: // Link Crawlers
  for(let i=0;i<5;i++){let z=.83-i*.37,x=.13*Math.sin(t*5-i*.67)*(1-hit*.8);b.push(x,.24+.04*Math.sin(t*5-i),z,0,0,0);B(0,.04,0,.35,.20,.29,i%2?'metal':'shell');for(let s of [-1,1])R([s*.15,0,0],[s*.31,-.06,.05],.045,steel);B(0,.16,0,.15,.08,.12,core);b.pop();}break;
 case 10: // Gearburst Canister
  C(0,.68,0,.58,.95,'y',shell,12);ring(0,1.10,0,.66,'y',steel,.07,14);ring(0,.31,0,.65,'y',steel,.07,14);for(let k=0;k<8;k++){let a=k*TAU/8;b.push(Math.sin(a)*.56,.65,Math.cos(a)*.56,0,a,0);B(0,0,.05,.18,.53,.14,core);W(0,.40,.01,.24,.22,.26,steel);b.pop();}C(0,1.27,0,.3,.13,'y',light,12);break;
 case 11: // Shearblade
  humanoid({h:2.28,w:.52,head:'box',arms:false,shoulders:.36});for(let s of [-1,1]){b.push(s*.32,1.72,.12,0,s*hit*.35,s*(hit*.38+.10));R([0,0,0],[s*.63,-.15,.40],.13,steel);R([s*.63,-.15,.4],[s*.91,-.36,1.1],.10,light);W(s*.91,-.36,1.15,.2,.20,.65,steel);b.pop();}C(0,1.3,.27,.18,.21,'z',core);break;
 case 12: // Presswall Worker
  humanoid({h:2.23,w:1.26,head:'box',arms:false,shoulders:.62});for(let s of [-1,1])R([s*.59,1.65,.25],[s*.67,1.17,.66],.13,steel);B(0,1.22,.89,1.74,1.52,.24,steel);B(0,1.25,1.03,1.51,1.2,.05,shell);for(let k=0;k<3;k++)R([-.72,1.54-k*.26,1.08],[.72,1.54-k*.26,1.08],.027,trim);break;
 case 13: // Torque Thief
  humanoid({h:1.79,w:.68,head:'cyl',shoulders:.43});C(0,1.25,-.39,.35,.36,'z',steel,12);for(let s of [-1,1]){spool(s*.53,.87,.27,.26);claw(s*.60,.79,.45,.95);}break;
 case 14: // Crane Hooker
  for(let x of [-.52,.52])for(let z of [-.44,.44])R([x,1.85,z],[x*1.25,.13,z*1.25],.13,steel);
  B(0,2.0,0,1.38,.23,.65,steel);B(0,2.19,0,1.38,.17,.44,shell);B(0,2.25,.32,1.26,.15,.20,light);C(0,2.08,.15,.28,.35,'x',core,12);
  R([.18,2.05,.35],[.18,.75,.79],.045,core);claw(.18,.68,.79,1.4);break;
 case 15: // Chain Binder
  B(0,.77,0,1.0,.55,.78,shell);spool(-.48,1.10,-.04,.4);spool(.48,1.10,-.04,.4);for(let s of [-1,1]){R([s*.35,.80,.26],[s*.72,.72,.74],.1,steel);claw(s*.72,.70,.74,1.1);}B(0,.23,.0,.78,.25,.70,steel);break;
 case 16: // Cinder Kettle
  S(0,1.23,0,.48,shell,6,12);C(0,1.65,0,.36,.16,'y',steel,12);C(0,1.79,0,.13,.17,'y',core,9);B(0,1.02,.45,.31,.22,.34,core);R([0,1.33,.29],[.04,1.2,.94],.11,steel);W(0,1.22,.99,.22,.15,.29,light);for(let s of [-1,1]){W(s*.56,1.15,-.14,.38,.27,.49,steel);C(s*.54,1.13,-.22,.12,.34,'z',core,10);}break;
 case 17: // Soot Torpedo
  W(0,.49,.46,.92,.48,1.23,shell);C(0,.57,-.62,.48,.70,'z',steel,12);C(0,.57,-1.01,.28,.10,'z',core,12);for(let s of [-1,1]){B(s*.48,.25,.02,.14,.24,1.34,steel);B(s*.34,.52,-.2,.13,.19,.6,core);}warning(0,.88,.2);break;
 case 18: // Condensate Mortar
  C(0,1.13,0,.47,1.20,'y',shell,12);C(0,1.79,0,.48,.20,'y',steel);for(let x of [-.42,.42])for(let z of [-.42,.42])R([x,1.15,z],[x*1.45,.15,z*1.45],.09,steel);R([0,1.54,.25],[0,1.8,.64],.14,steel);R([0,1.8,.64],[0,1.55,.97],.12,steel);C(0,1.5,1.03,.20,.14,'z',core,10);break;
 case 19: // Soot Midges
  for(let i=0;i<7;i++){let a=i*2.4+t*.62,rr=.2+(i%3)*.18;let x=Math.cos(a)*rr,y=1.1+Math.sin(a*2+t)*.20,z=Math.sin(a)*rr;b.push(x,y,z);S(0,0,0,.12,core,4,8);for(let s of [-1,1])W(s*.12,.03,-.03,.19,.08,.24,shell);R([0,-.02,0],[0,-.18,.09],.023,steel);b.pop();}break;
 case 20: // Spark Wisps
  for(let i=0;i<5;i++){let a=i*TAU/5+t*.5,x=Math.cos(a)*.48,z=Math.sin(a)*.48,y=1.25+.14*Math.sin(t*3+i);b.push(x,y,z);S(0,0,0,.16,light,5,9);ring(0,0,0,.22,'y',steel,.025,12);b.pop();R([x,y,z],[Math.cos(a+TAU/5)*.48,1.25+.14*Math.sin(t*3+i+1),Math.sin(a+TAU/5)*.48],.022,trim);}break;
 case 21: // Grate Mauler
  humanoid({h:2.20,w:1.20,head:'box',arms:false,shoulders:.68});B(0,1.32,.32,1.17,1.01,.18,core);for(let k=0;k<5;k++)B(0,1.0+k*.15,.45,1.1,.055,.09,steel);for(let s of [-1,1]){R([s*.69,1.54,.05],[s*.86,.9,.36+hit*.26],.17,steel);B(s*.9,.76,.40+hit*.28,.45,.39,.48,shell);}break;
 case 22: // Ash Shunter
  humanoid({h:2.2,w:.45,head:'cyl',shoulders:.31});R([.35,1.6,.16],[.55,.2,.80],.07,steel);ring(.55,1.65,.15,.32,'z',steel,.06);R([.55,1.65,.15],[.55,1.65,.53],.06,steel);break;
 case 23: // Heat Mirage
  B(0,1.15,0,.62,1.52,.43,steel);for(let k=0;k<6;k++)B(0,.60+k*.25,.28,.9,.10,.24,light);for(let s of [-1,1]){R([s*.29,.63,0],[s*.38,.15,0],.07,steel);W(s*.57,1.4,-.12,.35,.80,.38,steel);}eye(0,1.85,.30,.15);break;
 case 24: // Forge Bellows
  for(let x of [-.46,.46])for(let z of [-.35,.35])R([x,.85,z],[x*1.15,.16,z*1.3],.09,steel);
  for(let k=0;k<6;k++){let y=.55+k*.17;B(0,y,0,1.12+((k%2)?-.13:.1),.13,.91, k%2?'metal':'shell');}
  B(0,1.15,.45,.78,.33,.28,steel);C(0,.92,.64,.20,.44,'z',core,10);break;
 case 25: // Corrosion Eel
  for(let k=0;k<7;k++){let z=.83-k*.40,x=.27*Math.sin(k*.65+t*3)*(.5+.5*move);b.push(x,.37+.05*Math.sin(k+t*5),z,0,.11*Math.sin(k+t),0);C(0,0,0,.25-k*.014,.40,'z',k%2?'shell':'steel',10);ring(0,0,.18,.2,'z',core,.025,9);b.pop();}W(0,.42,1.15,.4,.22,.55,steel);R([0,.41,1.2],[0,.37,1.53],.07,light);break;
 case 26: // Rust Lice
  for(let i=0;i<6;i++){let a=i*TAU/6+t*.38,r=i%2?.42:.62,x=Math.cos(a)*r,z=Math.sin(a)*r;b.push(x,.20+.06*Math.sin(t*4+i),z);S(0,0,0,.14,steel,4,8);for(let k=0;k<4;k++)R([-.08+k*.05,-.04,-.02],[-.19+k*.08,-.13,.12],.026,core);W(0,.11,-.02,.25,.15,.21,light);b.pop();}break;
 case 27: // Etch Claw
  humanoid({h:1.75,w:.68,head:'cyl',arms:false,shoulders:.45});C(0,.99,.36,.32,.42,'y',core,10);for(let s of [-1,1]){for(let k=0;k<3;k++){let z=-.15+k*.22;R([s*.27,1.03,z],[s*(.70+.06*k),.45,z+.05],.063,steel);}R([s*.45,1.46,.1],[s*.86,.91,.55+hit*.24],.12,steel);claw(s*.86,.91,.55+hit*.24,1.35);}break;
 case 28: // Leech Harvester
  humanoid({h:1.86,w:.56,head:'box',arms:false,shoulders:.37});C(0,1.02,-.26,.36,.55,'z',steel,10);for(let k=0;k<4;k++){let x=(k-1.5)*.27;R([x*.6,1.18,.21],[x,1.08,.73],.075,steel);R([x,1.08,.73],[x*1.4,.75,1.12+hit*.17],.052,light);C(x*1.4,.75,1.17+hit*.17,.06,.20,'z',core,7);}break;
 case 29: // Vapor Walker
  humanoid({h:2.08,w:.57,head:'cyl',arms:true,shoulders:.38});C(0,1.88,.16,.36,.48,'y',shell,10);eye(0,1.91,.43,.19);for(let s of [-1,1]){b.poly([[s*.48,1.41,-.20],[s*.57,.25,-.18],[s*.29,.06,.15],[s*.31,1.48,.20]],'steel');}break;
 case 30: // Contamination Siren
  C(0,.33,0,.55,.55,'y',steel,10);C(0,1.24,0,.30,1.56,'y',shell,10);C(0,2.08,0,.47,.28,'y',steel,10);C(0,2.29,0,.31,.25,'y',light,10);for(let y of [.66,1.10,1.55])ring(0,y,0,.37,'y',core,.04,12);for(let k=0;k<4;k++)R([0,2.10,0],[Math.cos(k*TAU/4)*.43,2.12,Math.sin(k*TAU/4)*.43],.045,trim);break;
 case 31: // Corrosion Shellback
  B(0,.52,0,1.25,.70,1.22,shell);for(let k=0;k<5;k++){let z=-.56+k*.27;C(0,.91,z,.73-k*.05,.24,'z',k%2?'metal':'shell',12);}for(let s of [-1,1])for(let k=0;k<3;k++){let z=-.42+k*.40;R([s*.52,.47,z],[s*1.08,.23,z+.08],.115,steel);}W(0,.77,.77,.69,.24,.43,core);break;
 case 32: // Vat Lid Warden
  humanoid({h:2.09,w:.78,head:'cyl',arms:false,shoulders:.51});R([-.46,1.50,.15],[-.7,1.25,.44],.12,steel);C(-.72,1.32,.70,.75,.20,'z',steel,18);C(-.72,1.32,.82,.57,.12,'z',shell,18);ring(-.72,1.32,.93,.53,'z',trim,.065,18);R([.43,1.43,.12],[.68,.74,.62+hit*.26],.12,steel);claw(.66,.72,.63+hit*.26,1.20);break;
 }
 if(elite){ring(0,2.35,0,.30,'y','warn',.05,14);B(0,2.44,0,.16,.10,.18,'warn');}
 b.pop();return b;
}
// fixed 3/4-isometric projection; same viewpoint for every enemy, no camera orbiting.
function drawModelSprite(enemy, opts={}){
 const cn=document.createElement('canvas');cn.width=350;cn.height=350;const g=cn.getContext('2d');g.lineJoin='round';g.lineCap='round';
 const model=makeModel(enemy,opts);
 const projected=p=>[175+(p[0]-p[2])*56,286+(p[0]+p[2])*25-p[1]*51];
 let faces=model.polys.map(face=>{let cx=0,cy=0,cz=0;for(const p of face.v){cx+=p[0];cy+=p[1];cz+=p[2]};let n=face.v.length;return {...face,depth:(cx+cz+cy*.80)/n};}).sort((a,b)=>a.depth-b.depth);
 const colors={...PAL};
 function shade(hex,k){let m=hex.match(/[0-9a-f]{2}/gi);if(!m)return hex;return '#'+m.map(h=>clamp(Math.round(parseInt(h,16)*k),0,255).toString(16).padStart(2,'0')).join('');}
 for(const face of faces){let ps=face.v.map(projected);if(ps.length<3)continue;let a=face.v[0],b=face.v[1],c=face.v[2],u=b.map((v,i)=>v-a[i]),v=c.map((q,i)=>q-a[i]);let norm=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];let length=Math.hypot(...norm)||1;let diffuse=.79+.18*(norm[0]+norm[1]*1.6+norm[2]*.65)/length;diffuse=clamp(diffuse,.57,1.18);g.beginPath();g.moveTo(ps[0][0],ps[0][1]);for(let i=1;i<ps.length;i++)g.lineTo(ps[i][0],ps[i][1]);g.closePath();g.fillStyle=shade(colors[face.mat]||colors.shell,diffuse);g.fill();g.strokeStyle='#3d484d';g.lineWidth=.64;g.stroke();}
 // accent edges on cylindrical body parts have already been represented by faces.
 return cn;
}
