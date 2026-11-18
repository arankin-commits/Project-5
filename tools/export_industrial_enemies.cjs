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
// The prototype assigns every powered lens the same dark gray as a cavity.
// Restore a distinct material in the export copy, leaving the source untouched.
const modelSource = fs.readFileSync(path.join(pack,'models.js'),'utf8').replace("const core='dark'", "const core='glass'");
vm.runInContext(modelSource+'\nthis.model=makeModel;this.palette=PAL;',sandbox);
const out = path.join(root,'art/industrial_enemies');
fs.mkdirSync(out,{recursive:true});
const phases = ['idle','idle','walk','walk','walk','walk','windup','windup','active','active','recover','recover','death','death','death','death'];
const biomeKeys = {'Maintenance':'maintenance','Factory':'factory','Boiler Room':'boiler','Toxin Refinery':'toxin_refinery'};
const catalog = {};
const selectedBiome = process.argv[2];
const finishes = {
 maintenance: {shell:'#b9b3a5',top:'#e0d6bf',metal:'#697a80',dark:'#303c43',black:'#15242c',edge:'#b88843',detail:'#eed9a1',warn:'#edac36',glass:'#63edf0',cable:'#835043'},
 factory: {shell:'#a98c60',top:'#d6b57a',metal:'#7c858c',dark:'#37353b',black:'#201f29',edge:'#c49140',detail:'#eadab5',warn:'#f0b739',glass:'#ff6446',cable:'#655044'},
 boiler: {shell:'#a2694c',top:'#d99a62',metal:'#78625c',dark:'#3e2928',black:'#211a22',edge:'#d0944c',detail:'#f8d29a',warn:'#ff8e28',glass:'#ffb33e',cable:'#593735'},
 toxin_refinery: {shell:'#8f9b6a',top:'#c5c59a',metal:'#6a837b',dark:'#303f38',black:'#182d29',edge:'#b8a05c',detail:'#e4e5ad',warn:'#d6bf43',glass:'#b8f63f',cable:'#64523d'}
};
for (const enemy of enemies) {
  if (selectedBiome && biomeKeys[enemy.biome] !== selectedBiome) continue;
  const finish = finishes[biomeKeys[enemy.biome]];
  const key = 'industrial_'+String(enemy.id).padStart(2,'0');
  let svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="2048" viewBox="0 0 1024 2048"><defs><clipPath id="cell"><rect width="350" height="350"/></clipPath><pattern id="warning" width="16" height="16" patternUnits="userSpaceOnUse" patternTransform="rotate(35)"><rect width="16" height="16" fill="'+finish.warn+'"/><rect width="7" height="16" fill="'+finish.black+'"/></pattern></defs>';
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
      const color='#'+(finish[face.mat]||finish.shell).match(/[0-9a-f]{2}/gi).map(h=>Math.max(0,Math.min(255,Math.round(parseInt(h,16)*(face.mat==='glass'?1:diffuse)))).toString(16).padStart(2,'0')).join('');
      const points=face.v.map(p=>`${(175+(p[0]-p[2])*56).toFixed(2)},${(286+(p[0]+p[2])*25-p[1]*51).toFixed(2)}`).join(' ');
      svg+=`<polygon points="${points}" fill="${face.mat==='warn'?'url(#warning)':color}" stroke="${finish.black}" stroke-width="0.9" stroke-linejoin="round"/>`;
      // Inset panel seams, edge highlights and rivets follow each posed face.
      const projected=face.v.map(p=>[175+(p[0]-p[2])*56,286+(p[0]+p[2])*25-p[1]*51]);
      const area=Math.abs(projected.reduce((sum,p,i)=>{const q=projected[(i+1)%projected.length];return sum+p[0]*q[1]-q[0]*p[1];},0))/2;
      if(['shell','top'].includes(face.mat) && area>120) {
        const center=projected.reduce((a,p)=>[a[0]+p[0]/projected.length,a[1]+p[1]/projected.length],[0,0]);
        const inset=projected.map(p=>p.map((v,i)=>center[i]+(v-center[i])*.83));
        svg+=`<polygon points="${inset.map(p=>p.map(v=>v.toFixed(2)).join(',')).join(' ')}" fill="none" stroke="${finish.dark}" stroke-width=".8"/>`;
        for(const p of inset) svg+=`<circle cx="${p[0].toFixed(2)}" cy="${p[1].toFixed(2)}" r="1.1" fill="${finish.edge}" stroke="${finish.black}" stroke-width=".4"/>`;
        const [p,q]=inset;
        svg+=`<path d="M${p.join(' ')} L${q.join(' ')}" stroke="${finish.detail}" stroke-width=".8" opacity=".65"/>`;
      }
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
// Existing gameplay stats may have been tuned since the source pack shipped.
// Art-only exports must never reset those values.
if (!fs.existsSync(path.join(root,'data/enemies/industrial.json')))
  fs.writeFileSync(path.join(root,'data/enemies/industrial.json'),JSON.stringify(catalog,null,2)+'\n');
console.log('Exported '+Object.keys(catalog).length+' enemies; 8 directions, 16 pose frames per direction.');
