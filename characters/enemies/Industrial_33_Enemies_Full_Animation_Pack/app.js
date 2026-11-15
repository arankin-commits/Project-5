(()=>{'use strict';
const A=document.querySelector('#arena'),ctx=A.getContext('2d'), $=id=>document.getElementById(id);
const floor=(x,z)=>({x:645+(x-z)*82,y:415+(x+z)*30});
const target={x:1.25,z:.82,hp:100,max:100,flash:0};
const state={id:0,x:-.4,z:-.38,yaw:Math.PI/2,desired:Math.PI/2,move:.0,velocity:0,angleCount:32,mode:'manual', keys:{},now:0,last:0,at:0,modeT:0,tourStep:0,phase:'idle',act:-1,phaseT:0,phaseDuration:0,progress:0,attackYaw:0,attackStart:{x:0,z:0},attacked:false,elite:false,mouseAim:false,showTele:true,showShadow:true,inspect:false, status:'Ready', fx:[],summons:[],died:false,deathT:0,angleOverride:null,comboStep:0,projectiles:[],screenMouse:null};
const img=new Image();img.src=ROOM_IMAGE;
function enemy(){return ENEMIES[state.id]}
const roleTag=(r)=>r.toUpperCase();
function text(id,s){$(id).textContent=s}
function unitVec(y){return {x:Math.sin(y),z:Math.cos(y)}}
function unitFromScreen(dx,dy){let x=(dx/82+dy/30)/2,z=(dy/30-dx/82)/2,L=Math.hypot(x,z);return L>1e-5?{x:x/L,z:z/L}:{x:0,z:0}}
function isRoom(x,z){return x>-2.0&&x<1.9&&z>-1.84&&z<1.68&&!(x<-1.1&&z<-1.12)&&!(x>1.25&&z>.82)}
function canMove(x,z){if(isRoom(x,z)){state.x=x;state.z=z;return}if(isRoom(x,state.z))state.x=x;if(isRoom(state.x,z))state.z=z}
const startPos=()=>{state.x=-.40;state.z=-.38;state.yaw=Math.PI/2;state.desired=state.yaw;state.died=false;state.phase='idle';state.act=-1;state.phaseT=0;state.fx=[];state.summons=[];state.projectiles=[];target.hp=100;target.flash=0;state.comboStep=0;};
function switchEnemy(i){state.id=clamp(Number(i)||0,0,ENEMIES.length-1);startPos();state.mode='manual';state.modeT=0;state.tourStep=0;state.angleOverride=null;state.inspectionCache=new Map();state.sprites=new Map();state.status='Ready';$('enemySelect').value=state.id;$('eliteToggle').checked=state.elite;document.querySelectorAll('.modeBtn').forEach(b=>b.classList.toggle('active',b.dataset.mode==='manual'));updatePanel();refreshTurnaround();}
function updatePanel(){let e=enemy(),grp=ENEMIES.filter(v=>v.biome===e.biome);$('enemyTitle').textContent=e.name;$('roleLabel').textContent=e.biome+'  /  '+e.role;$('roleText').textContent=e.visual;$('statHP').textContent=e.hp+(state.elite?' +50%':'');$('statMove').textContent=e.speed.toFixed(1);$('statTier').textContent=e.danger+'/5';$('statSize').textContent=e.size;$('animationInfo').textContent=e.pivots;$('aiInfo').textContent=e.ai;$('eliteInfo').innerHTML='<b>'+e.eliteName+'</b> — '+e.elite;$('deathInfo').textContent=e.death;for(let i=0;i<3;i++){let m=e.moves[i];$('move'+i).innerHTML='<span class="moveNum">'+(i+1)+'</span><span><b>'+m.name+'</b><small>'+m.tell+' · '+m.effect+'</small></span>';}text('enemyIndex',(state.id+1)+' / 33');$('biomeSelect').value=e.biome;document.querySelectorAll('#sortGrid button').forEach(b=>b.classList.toggle('on',b.dataset.enemyid==state.id));}
function makeBiomeFilters(){let bsel=$('biomeSelect');for(let biome of ['All biomes','Maintenance','Factory','Boiler Room','Toxin Refinery']){let a=document.createElement('option');a.value=biome;a.textContent=biome;bsel.appendChild(a);}for(let e of ENEMIES){let a=document.createElement('option');a.value=e.id;a.textContent=String(e.id+1).padStart(2,'0')+'  '+e.name+' — '+e.role;$('enemySelect').appendChild(a);}bsel.onchange=()=>{const b=bsel.value;if(b==='All biomes')return;let e=ENEMIES.find(v=>v.biome===b);if(e)switchEnemy(e.id);};$('enemySelect').onchange=e=>switchEnemy(e.target.value);}
function refreshTurnaround(){const strip=$('angleStrip');strip.textContent='';for(let i=0;i<8;i++){let angle=i*Math.PI/4;let b=document.createElement('button');b.className='turn';b.innerHTML='<canvas width="90" height="90"></canvas><span>'+i*45+'°</span>';let canvas=b.querySelector('canvas'),g=canvas.getContext('2d');let sprite=drawModelSprite(enemy(),{yaw:angle,t:1.5,elite:state.elite});g.drawImage(sprite,0,0,350,350,0,0,90,90);b.onclick=()=>{state.mode='manual';document.querySelectorAll('.modeBtn').forEach(v=>v.classList.toggle('active',v.dataset.mode==='manual'));state.desired=angle;state.yaw=angle;state.angleOverride=angle;state.move=0;};strip.appendChild(b);}}
function parseTime(s,def=.6){let m=(s||'').match(/(\d+(?:\.\d+)?)\s*s\b/i);return m?Number(m[1]):def}
function startAction(i){if(state.died)return;if(state.phase!=='idle'&&state.phase!=='recover')return;let m=enemy().moves[i];state.act=i;state.phase='windup';state.phaseT=0;state.phaseDuration=parseTime(m.tell,.65);state.progress=0;state.attacked=false;state.attackYaw=state.yaw;state.attackStart={x:state.x,z:state.z};state.status=m.name+' • WINDUP';state.fx.length=0;state.angleOverride=null;}
function spawnText(msg,world=target,color='#f2ba80'){state.fx.push({type:'text',msg,x:world.x,z:world.z,color,t:0,duration:.92});}
function impactDamage(amount=10){target.hp=Math.max(0,target.hp-amount);target.flash=.38;spawnText('-'+amount+' HP');if(target.hp<=0){spawnText('TARGET RESET',target,'#b9d8da');target.hp=100;}}
function doAction(e,m){let name=m.name.toLowerCase(),role=e.role;
 if(/hop|strafe|drift|feint|scatter|regroup|reverse/.test(name)){let s=unitVec(state.attackYaw+Math.PI/2);canMove(state.x+s.x*.65,state.z+s.z*.65);spawnText('REPOSITION',{x:state.x,z:state.z},'#a0ccd2');return;}
 if(/step|skip|walker|phase/.test(name)&&role==='Teleport'){state.x=target.x-.65;state.z=target.z-.43;spawnText('REPOSITION',{x:state.x,z:state.z},'#a0ccd2');return;}
 if(/summon|deploy|release|fabricat|breed/.test(name)||role==='Summoner'&&state.act===0){state.summons.push({x:state.x+.55,z:state.z+.5,t:0},{x:state.x-.45,z:state.z+.4,t:0},{x:state.x,z:state.z+.7,t:0});spawnText('SUMMONED');return;}
 if(/guard|shield|armor|boost|overclock|link/.test(name)&&role==='Buffer'){spawnText('ALLY BUFF', {x:state.x,z:state.z},'#c8d4d9');return;}
 const dist=Math.hypot(state.x-target.x,state.z-target.z),dir=unitVec(state.attackYaw);
 if(role==='Charging'||/chase|ram|torpedo|lunge|rush|pierc/.test(name)&&role!=='Swarm'){canMove(state.x+dir.x*1.45,state.z+dir.z*1.45);}
 if(role==='Teleport'&&/slash|jab|sting/.test(name)){/* attack at newly arrived destination */}
 if(role==='Grappler'&&/grab|grapple|hook|loop|reel|drag|siphon/.test(name)){spawnText('HOOK!',target,'#eac18a');}
 if(role==='AOE'||role==='Disruptor'||/ring|pulse|burst|sweep|shock|mirage/.test(name)){if(dist<3.6)impactDamage(9+e.danger*2);else spawnText('DODGED',target,'#c5d5dc');return;}
 if(role==='Projectile'||/spit|toss|shot|mortar|barrage|spray|dart/.test(name)){state.projectiles.push({x:state.x,z:state.z,tx:target.x,tz:target.z,t:0,duration:.42,color:'#ed9b72'});return;}
 if(dist<2.6)impactDamage(5+e.danger*3);else spawnText('OUT OF RANGE',target,'#b2bec4');
}
function actionUpdate(dt){if(state.phase==='idle')return;state.phaseT+=dt;state.progress=clamp(state.phaseT/(state.phaseDuration||1),0,1);
 if(state.phase==='death'){if(state.phaseT>=2.2){startPos();}return;}
 if(state.phaseT<state.phaseDuration)return;
 let e=enemy(),m=e.moves[state.act];
 if(state.phase==='windup'){state.phase='active';state.phaseT=0;state.phaseDuration=(e.role==='Charging'?.48:e.role==='Grappler'?.5:.36);state.status=m.name+' • ACTIVE';state.progress=0;doAction(e,m);}
 else if(state.phase==='active'){state.phase='recover';state.phaseT=0;state.phaseDuration=parseTime(m.recovery,.60);state.status=m.name+' • RECOVERY';state.progress=0;}
 else if(state.phase==='recover'){state.phase='idle';state.phaseT=0;state.act=-1;state.status='Ready';state.progress=0;}
}
function setMode(mode){state.mode=mode;state.modeT=0;state.tourStep=0;state.angleOverride=null;state.phase='idle';state.act=-1;document.querySelectorAll('.modeBtn').forEach(b=>b.classList.toggle('active',b.dataset.mode===mode));}
function worldMove(dt){let dx=0,dy=0;
 if(state.mode==='manual'){let k=state.keys;dx=(k.d||k.arrowright?1:0)-(k.a||k.arrowleft?1:0);dy=(k.s||k.arrowdown?1:0)-(k.w||k.arrowup?1:0);}
 else if(state.mode==='tour'){let vectors=[[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]];let step=Math.floor(state.modeT/1.40)%8;state.tourStep=step;[dx,dy]=vectors[step];if(state.modeT>=11.2)state.modeT=0;}
 else if(state.mode==='combat'){
   let phase=(state.modeT%19);if(phase<3.2){dx=1;dy=0;}else if(phase<6.3){dx=0;dy=1;}else if(phase<9.3){dx=-1;dy=0;}else if(phase<12){dx=0;dy=-1;}else{dx=dy=0;}
   let actionPhase=phase;for(let [t,a] of [[2.5,0],[6.2,1],[10.5,2],[15.1,0]])if(actionPhase>=t&&actionPhase<t+dt+.02&&state.phase==='idle')startAction(a);
   if(state.modeT>40)state.modeT=0;
 }
 if(state.phase==='windup'||state.phase==='active'||state.phase==='death'){dx=dy=0;}
 if(dx||dy){let length=Math.hypot(dx,dy);dx/=length;dy/=length;let dir=unitFromScreen(dx,dy);let scale=enemy().speed*.42*dt; // room is designed as a compact animation lab, speeds normalized
  if(state.mode==='tour'){scale=Math.min(scale,.017);if(Math.hypot(state.x,state.z)>1.15){dir.x=-state.x;dir.z=-state.z;let L=Math.hypot(dir.x,dir.z)||1;dir.x/=L;dir.z/=L;}}
  canMove(state.x+dir.x*scale,state.z+dir.z*scale);state.desired=Math.atan2(dir.x,dir.z);state.move=lerp(state.move,1,clamp(dt*8,0,1));state.velocity=enemy().speed*.42;state.angleOverride=null;
 }else{state.move=lerp(state.move,0,clamp(dt*7,0,1));state.velocity=0;}
 if(state.mouseAim&&state.mode==='manual'&&state.screenMouse&&!dx&&!dy){let p=floor(state.x,state.z);let dir=unitFromScreen(state.screenMouse.x-p.x,state.screenMouse.y-p.y);state.desired=Math.atan2(dir.x,dir.z);state.angleOverride=null;}
 let yawDiff=((state.desired-state.yaw+Math.PI*3)%(Math.PI*2))-Math.PI;
 // Discrete multi-view behavior with continuous travel and limited turn lag for secondary bank.
 state.yaw+=clamp(yawDiff,-dt*10,dt*10);
}
function bg(){ctx.fillStyle='#0c1216';ctx.fillRect(0,0,1280,720);if(img.complete&&img.naturalWidth){ctx.drawImage(img,0,0,1280,720);}else{ctx.fillStyle='#5c6367';ctx.fillRect(0,0,1280,720);}}
function dot(x,z,r=10,color='#d5aa77',alpha=.6){const p=floor(x,z);ctx.save();ctx.globalAlpha=alpha;ctx.fillStyle=color;ctx.beginPath();ctx.ellipse(p.x,p.y,r,r*.38,0,0,Math.PI*2);ctx.fill();ctx.restore();}
function circle(x,z,r,color='#e5a05b',fill=false){const p=floor(x,z);ctx.beginPath();ctx.ellipse(p.x,p.y,r*82,r*30,0,0,Math.PI*2);ctx.strokeStyle=color;ctx.lineWidth=2.4;ctx.stroke();if(fill){ctx.fillStyle='rgba(216,105,73,.12)';ctx.fill();}}
function lineWorld(x,z,x2,z2,col='#e7aa72',w=3){let a=floor(x,z),b=floor(x2,z2);ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.strokeStyle=col;ctx.lineWidth=w;ctx.stroke();}
function arc(x,z,r,yaw,span=Math.PI*.78,col='#e7ab70',fill=false){let p=floor(x,z);ctx.save();ctx.beginPath();let n=32;for(let k=0;k<=n;k++){let angle=yaw-span/2+span*k/n,v=unitVec(angle),q=floor(x+v.x*r,z+v.z*r);if(k===0)ctx.moveTo(q.x,q.y);else ctx.lineTo(q.x,q.y);}ctx.strokeStyle=col;ctx.lineWidth=3;ctx.stroke();if(fill){ctx.lineTo(p.x,p.y);ctx.closePath();ctx.fillStyle='#d9866040';ctx.fill();}ctx.restore();}
function FXGround(){let e=enemy();if(state.phase==='idle'||state.phase==='death'||state.act<0)return;let m=e.moves[state.act],n=m.name.toLowerCase(),p=state.progress,tele=state.phase==='windup';const col=tele?'#df965d':'#f1ca91';if(!state.showTele)return;
 ctx.save();ctx.globalAlpha=tele?.66+Math.sin(state.now*14)*.12:.95;const y=state.attackYaw,v=unitVec(y),ox=state.x,oz=state.z;
 if(e.role==='AOE'||e.role==='Disruptor'||e.role==='Buffer'||/ring|burst|pulse|overclock|guard/.test(n)){circle(ox,oz,1.0+2*p,col,true);if(/eight|gear|wave/.test(n))for(let k=0;k<8;k++){let a=y+k*Math.PI/4,dir=unitVec(a);lineWorld(ox,oz,ox+dir.x*3,oz+dir.z*3,col,1.6);}}
 else if(e.role==='Projectile'||/spit|shot|spray|toss|barrage/.test(n)){lineWorld(ox,oz,ox+v.x*3.6,oz+v.z*3.6,col,2);circle(target.x,target.z,.42,col,true);}
 else if(e.role==='Grappler'||/hook|grab|reel|tether|chain/.test(n)){lineWorld(ox,oz,target.x,target.z,col,tele?2:5);circle(target.x,target.z,.40,col,true);}
 else if(e.role==='Charging'||/dive|lunge|chase|torpedo|ram/.test(n)){let q=floor(ox+v.x*4,oz+v.z*4),a=floor(ox,oz);ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(q.x,q.y);ctx.strokeStyle=col;ctx.lineWidth=8;ctx.globalAlpha=.35;ctx.stroke();ctx.globalAlpha=.8;ctx.lineWidth=2;ctx.stroke();}
 else if(e.role==='Teleport'||/phase|vapor|flicker/.test(n)){circle(target.x-.65,target.z-.43,.65,col,true);}
 else{arc(ox,oz,1.35,y,Math.PI*.73,col,true);}
 ctx.restore();}
function drawTarget(){let p=floor(target.x,target.z);dot(target.x,target.z,30,'#000000',.33);ctx.save();ctx.translate(p.x,p.y);ctx.strokeStyle='#26333d';ctx.lineWidth=1.5;ctx.fillStyle=target.flash>0?'#f6c1a9':'#8f9ca0';ctx.fillRect(-16,-64,32,47);ctx.strokeRect(-16,-64,32,47);ctx.fillStyle='#d3d7d6';ctx.beginPath();ctx.arc(0,-76,12,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.strokeStyle='#53616b';ctx.lineWidth=5;ctx.beginPath();ctx.moveTo(-12,-44);ctx.lineTo(-26,-19);ctx.moveTo(12,-44);ctx.lineTo(26,-19);ctx.moveTo(-6,-19);ctx.lineTo(-11,0);ctx.moveTo(6,-19);ctx.lineTo(11,0);ctx.stroke();ctx.restore();
 ctx.fillStyle='#1c2529';ctx.fillRect(p.x-35,p.y-106,70,8);ctx.fillStyle='#b78b72';ctx.fillRect(p.x-34,p.y-105,68*(target.hp/target.max),6);ctx.font='bold 10px system-ui';ctx.textAlign='center';ctx.fillStyle='#d0d8dc';ctx.fillText('TEST TARGET',p.x,p.y-115);}
const sprites=new Map();
function frameSprite(){let e=enemy(),a=state.yaw,N=state.angleCount,index=((Math.round(a/TAU*N)%N)+N)%N,quant=index*TAU/N;
 let idle=(state.phase==='idle')&&!state.move&&!state.elite?Math.floor(state.now*3)%2:Math.floor(state.now*8)%4;
 let phase=state.phase,prog=phase==='idle'?0:Math.floor(state.progress*5)/5;
 let key=[e.id,index,phase,prog,idle,Math.round(state.move*2),state.elite].join(':');if(sprites.has(key))return {sprite:sprites.get(key),index,quant};
 let image=drawModelSprite(e,{yaw:quant,t:state.now,moving:state.move,phase:phase==='death'?'death':phase,progress:state.progress,elite:state.elite});
 sprites.set(key,image);if(sprites.size>170){let first=sprites.keys().next().value;sprites.delete(first);}return {sprite:image,index,quant};}
function drawEnemy(){let p=floor(state.x,state.z),float=['Flying','Swarm'].includes(enemy().role)?1:0;const h=enemy().size==='Tiny'?.90:enemy().size==='Large'?1.27:enemy().size==='Small'?1.14:1.16;
 if(state.showShadow)dot(state.x,state.z,44*h,'#071215',.34);
 const {sprite,index,quant}=frameSprite();let alpha=state.died?clamp(1-state.phaseT/2.1,0,1):1;
 if(state.phase==='windup'&&enemy().role==='Teleport'&&state.progress>.62)alpha=.38;
 ctx.save();ctx.globalAlpha=alpha;ctx.translate(p.x,p.y);ctx.scale(h,h);ctx.drawImage(sprite,-175,-286);ctx.restore();
 if(state.showTele&&state.move>.18&&state.phase==='idle'){let v=unitVec(state.yaw),pp=floor(state.x+v.x*.75,state.z+v.z*.75);ctx.strokeStyle='#d8b27a98';ctx.lineWidth=1.5;ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.lineTo(pp.x,pp.y);ctx.stroke();}
 text('currentYaw',Math.round((state.yaw%TAU+TAU)%TAU*180/Math.PI).toString().padStart(3,'0')+'°');text('spriteIndex',index+'/'+state.angleCount);text('currentState',state.phase.toUpperCase());text('currentSpeed',state.velocity.toFixed(2));
}
function drawFX(dt){for(let f of state.fx){f.t+=dt;let p=floor(f.x,f.z);ctx.globalAlpha=clamp(1-f.t/f.duration,0,1);ctx.textAlign='center';ctx.font='bold 14px system-ui';ctx.fillStyle=f.color;ctx.fillText(f.msg,p.x,p.y-110-f.t*35);ctx.globalAlpha=1;}state.fx=state.fx.filter(f=>f.t<f.duration);
 for(let p of state.projectiles){p.t+=dt;let t=clamp(p.t/p.duration,0,1),q=floor(lerp(p.x,p.tx,t),lerp(p.z,p.tz,t));ctx.fillStyle='#e4a97d';ctx.strokeStyle='#f1d4b5';ctx.lineWidth=2;ctx.beginPath();ctx.arc(q.x,q.y-40-30*Math.sin(t*Math.PI),8,0,TAU);ctx.fill();ctx.stroke();if(p.t>=p.duration){impactDamage(8+enemy().danger*2);}}state.projectiles=state.projectiles.filter(p=>p.t<p.duration);
 for(let s of state.summons){s.t+=dt;let p=floor(s.x+.19*Math.sin(s.t*3),s.z+.15*Math.cos(s.t*4));ctx.globalAlpha=clamp(1-s.t/5.5,0,.85);ctx.fillStyle='#98a3a8';ctx.strokeStyle='#283137';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(p.x,p.y-32+Math.sin(s.t*4)*3,12,8,0,0,TAU);ctx.fill();ctx.stroke();ctx.globalAlpha=1;}state.summons=state.summons.filter(s=>s.t<5.5);}
function HUD(){ctx.save();let grad=ctx.createLinearGradient(0,0,570,0);grad.addColorStop(0,'rgba(6,12,18,.88)');grad.addColorStop(1,'rgba(6,12,18,0)');ctx.fillStyle=grad;ctx.fillRect(0,0,750,115);ctx.textAlign='left';ctx.fillStyle='#d8b47f';ctx.font='bold 12px system-ui';ctx.fillText('ISOMETRIC ANIMATION LAB  /  '+enemy().biome.toUpperCase(),28,35);ctx.fillStyle='#ecf1f0';ctx.font='bold 27px system-ui';ctx.fillText(enemy().name,28,68);ctx.fillStyle='#a9b9bf';ctx.font='12px system-ui';ctx.fillText(enemy().role.toUpperCase()+'   •   '+(state.elite?enemy().eliteName.toUpperCase()+'   •   ':'')+state.status,29,94);
 ctx.font='11px system-ui';ctx.textAlign='left';ctx.fillStyle='#fff';ctx.fillText('33 ORIGINAL GRAYBOX MODELS  ·  '+state.angleCount+' DIRECTIONAL VIEWS  ·  FIXED CAMERA',24,696);
 if(state.mode==='tour'){ctx.textAlign='right';ctx.fillStyle='#ecc696';ctx.font='bold 18px system-ui';ctx.fillText(['N','NE','E','SE','S','SW','W','NW'][state.tourStep]+' FACING',1230,50);}
 ctx.restore();}
let last=performance.now();function loop(ts){let dt=clamp((ts-last)/1000,0,.05);last=ts;state.now+=dt;state.modeT+=dt;target.flash=Math.max(0,target.flash-dt);worldMove(dt);actionUpdate(dt);bg();FXGround();drawTarget();drawEnemy();drawFX(dt);HUD();requestAnimationFrame(loop);}
function keymap(ev){const t=ev.target?.tagName;if(t==='INPUT'||t==='TEXTAREA'||t==='SELECT')return;let k=ev.key.toLowerCase();if(['w','a','s','d',' ','arrowup','arrowdown','arrowleft','arrowright','1','2','3','r','k','t'].includes(k))ev.preventDefault();state.keys[k===' '?'space':k]=true;if(ev.repeat)return;
 if(k==='1'||k==='2'||k==='3')startAction(Number(k)-1);
 if(k==='r')startPos();if(k==='k'){state.phase='death';state.act=0;state.phaseT=0;state.phaseDuration=2.2;state.died=true;state.progress=0;state.status='DEATH ANIMATION';}
 if(k==='t')setMode(state.mode==='tour'?'manual':'tour');
 if(k===' '&&state.phase==='idle')startAction(0);
}
window.addEventListener('keydown',keymap);window.addEventListener('keyup',e=>{state.keys[e.key.toLowerCase()=== ' '?'space':e.key.toLowerCase()]=false});window.addEventListener('blur',()=>state.keys={});
A.addEventListener('mousemove',ev=>{const rect=A.getBoundingClientRect();state.screenMouse={x:(ev.clientX-rect.left)/rect.width*1280,y:(ev.clientY-rect.top)/rect.height*720};});
A.addEventListener('click',()=>{if(state.phase==='idle')startAction(state.comboStep++%3);A.focus();});
$('prevBtn').onclick=()=>switchEnemy((state.id+32)%33);$('nextBtn').onclick=()=>switchEnemy((state.id+1)%33);
for(let i=0;i<3;i++)$('move'+i).onclick=()=>{setMode('manual');startAction(i);};
$('deathBtn').onclick=()=>{state.died=true;state.phase='death';state.phaseT=0;state.phaseDuration=2.2;state.status='DEATH ANIMATION';};
$('resetBtn').onclick=()=>{startPos();setMode('manual')};
document.querySelectorAll('.modeBtn').forEach(b=>b.onclick=()=>{setMode(b.dataset.mode);A.focus();});
$('angles').onchange=ev=>{state.angleCount=Number(ev.target.value);sprites.clear();};
$('eliteToggle').onchange=ev=>{state.elite=ev.target.checked;sprites.clear();updatePanel();refreshTurnaround();};
$('teleToggle').onchange=ev=>state.showTele=ev.target.checked;
$('shadowToggle').onchange=ev=>state.showShadow=ev.target.checked;
$('mouseToggle').onchange=ev=>state.mouseAim=ev.target.checked;

function buildGrid(){let grid=$('sortGrid');grid.innerHTML='';for(let e of ENEMIES){let b=document.createElement('button');b.textContent=e.name;b.title=e.role+' / '+e.biome;b.dataset.enemyid=e.id;b.onclick=()=>switchEnemy(e.id);grid.appendChild(b);}}
// Export and scripted screenshot API for model atlas generation and regression tests.
window.GreyboxLab={
 setEnemy:switchEnemy,
 setYaw:(angle)=>{state.yaw=angle;state.desired=angle;state.angleOverride=angle;state.move=0;},
 setPhase:(phase,progress=.5,move=0)=>{state.phase=phase;state.phaseDuration=1;state.phaseT=progress;state.progress=progress;state.move=move;state.act=0;state.status=phase.toUpperCase();},
 setMode,
 triggerMove:startAction,
 reset:startPos,
 getState:()=>({...state,name:enemy().name}),
 spriteData:(id,angle,phase='idle',progress=.4)=>drawModelSprite(ENEMIES[id],{yaw:angle,phase,progress,t:1.5,moving:phase==='idle'?.65:0}).toDataURL('image/png'),
 previewFrame:(i)=>{const step=i%20;state.now=i*.145+1.0;state.mode='manual';state.modeT=0;state.angleOverride=null;state.summons=[];state.projectiles=[];state.fx=[];state.x=-.40;state.z=-.38;if(step<8){state.yaw=step*Math.PI/4;state.desired=state.yaw;state.move=.85;state.phase='idle';state.act=-1;state.progress=0;let p=unitVec(state.yaw);state.x+=p.x*.36;state.z+=p.z*.30;}else{state.yaw=Math.PI/4;state.desired=state.yaw;state.move=0;state.act=Math.floor((step-8)/4);let stage=(step-8)%4;state.phase=['windup','windup','active','recover'][stage];state.progress=[.25,.75,.52,.58][stage];if(stage===2){const role=enemy().role;if(role==='Projectile')state.projectiles=[{x:state.x,z:state.z,tx:target.x,tz:target.z,t:.20,duration:.42}];if(role==='Summoner')state.summons=[{x:state.x+.5,z:state.z+.5,t:0},{x:state.x-.4,z:state.z+.3,t:0}];if(role==='Charging'){state.x+=.46;state.z+=.46;}if(role==='Teleport'){state.x=target.x-.56;state.z=target.z-.65;}}}bg();FXGround();drawTarget();drawEnemy();drawFX(0);HUD();return A.toDataURL('image/png');},
 screenshot:()=>A.toDataURL('image/png'),
 screenshotSprite:()=>frameSprite().sprite.toDataURL('image/png'),
 roster:ENEMIES,
 meshData:(i)=>makeModel(ENEMIES[i],{yaw:0,t:0,phase:'idle',progress:0,moving:0}).polys,
};
makeBiomeFilters();buildGrid();switchEnemy(0);requestAnimationFrame(loop);
})();
