// Render the supplied procedural geometry as clean SVG animation atlases.
// No browser, packages, image generation, or changes to the source pack.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const pack = path.join(root, 'characters/enemies/Industrial_33_Enemies_Full_Animation_Pack');
const enemies = JSON.parse(fs.readFileSync(path.join(pack,'enemy_design_data.json'),'utf8'));
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(fs.readFileSync(path.join(pack,'models.js'),'utf8')+'\nthis.model=makeModel;this.palette=PAL;',sandbox);
const out = path.join(root,'art/industrial_enemies');
fs.mkdirSync(out,{recursive:true});
const phases = ['idle','idle','walk','walk','walk','walk','windup','windup','active','active','recover','recover','death','death','death','death'];
const biomeKeys = {'Maintenance':'maintenance','Factory':'factory','Boiler Room':'boiler','Toxin Refinery':'toxin_refinery'};
const catalog = {};
for (const enemy of enemies) {
  const key = 'industrial_'+String(enemy.id).padStart(2,'0');
  let svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="2048" viewBox="0 0 1024 2048"><defs><clipPath id="cell"><rect width="350" height="350"/></clipPath></defs>';
  for(let row=0;row<16;row++) for(let dir=0;dir<8;dir++) {
    const phase=phases[row];
    const q=phase==='death'?(row-12)/3:(row%2?0.8:0.25);
    const model=sandbox.model(enemy,{yaw:dir*Math.PI/4,t:phase==='walk'?(row-2)*Math.PI/16:row*.17,phase:phase==='walk'?'idle':phase,progress:q,moving:phase==='walk'?1:0});
    const faces=model.polys.map(face=>({...face,depth:face.v.reduce((s,p)=>s+p[0]+p[2]+p[1]*.8,0)/face.v.length})).sort((a,b)=>a.depth-b.depth);
    svg+=`<g transform="translate(${dir*128} ${row*128}) scale(${128/350})" clip-path="url(#cell)">`;
    for(const face of faces) {
      const [a,b,c]=face.v;
      const u=b.map((v,i)=>v-a[i]),v=c.map((v,i)=>v-a[i]);
      const n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];
      const diffuse=Math.max(.57,Math.min(1.18,.79+.18*(n[0]+n[1]*1.6+n[2]*.65)/(Math.hypot(...n)||1)));
      const color='#'+(sandbox.palette[face.mat]||sandbox.palette.shell).match(/[0-9a-f]{2}/gi).map(h=>Math.max(0,Math.min(255,Math.round(parseInt(h,16)*diffuse))).toString(16).padStart(2,'0')).join('');
      const points=face.v.map(p=>`${(175+(p[0]-p[2])*56).toFixed(2)},${(286+(p[0]+p[2])*25-p[1]*51).toFixed(2)}`).join(' ');
      svg+=`<polygon points="${points}" fill="${color}" stroke="#3d484d" stroke-width="0.64" stroke-linejoin="round"/>`;
    }
    svg+='</g>';
  }
  fs.writeFileSync(path.join(out,key+'.svg'),svg+'</svg>');
  const damage=enemy.moves[0].effect.match(/(?:for|deals?) (\d+) (?:contact )?damage/i);
  catalog[key]={...enemy,biome_key:biomeKeys[enemy.biome],texture:'res://art/industrial_enemies/'+key+'.svg',
    contact_damage:damage?Number(damage[1]):Math.max(4,enemy.danger*4),
    windup_seconds:parseFloat(enemy.moves[0].tell)||0.65,
    cooldown_seconds:parseFloat(enemy.moves[0].cooldown)||1.25};
}
fs.mkdirSync(path.join(root,'data/enemies'),{recursive:true});
fs.writeFileSync(path.join(root,'data/enemies/industrial.json'),JSON.stringify(catalog,null,2)+'\n');
console.log('Exported '+enemies.length+' enemies; 8 directions, 16 pose frames per direction.');
