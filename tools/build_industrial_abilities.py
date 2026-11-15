"""Explicit gameplay definitions for the supplied 99 regular enemy moves."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = json.loads((root / 'data/enemies/industrial.json').read_text())

def move(kind, damage=0, reach=90, **options):
    return dict(kind=kind, damage=damage, reach=reach, **options)

# Entries follow the source's enemy ID and move order. Distances are game pixels.
sets = [
 [move('dash',9,130), move('shot',7,260), move('sidestep',reach=52)],
 [move('dash',4,65), move('dash',12,130), move('regroup')],
 [move('ring',18,156), move('cone',12,110,arc=90), move('pool',3,65,duration=3)],
 [move('cone',9,78,arc=100),move('cone',11,78,arc=100),move('disk',19,85)],
 [move('summon',reach=260,count=3,enemy='industrial_01'),move('ring',9,95,push=45),move('shot',6,190,count=2)],
 [move('hook',6,156,hook_duration=4),move('reel',reach=156,duration=.75),move('cone',13,70)],
 [move('teleport',reach=180),move('cone',14,85),move('cone',10,70)],
 [move('ring',0,91,status='interference',duration=3),move('shot',6,170),move('sidestep',reach=52)],
 [move('dash',18,182,velocity=234),move('cone',10,65,arc=75),move('sidestep',8,52)],
 [move('dash',11,78),move('cone',6,78,arc=150),move('split')],
 [move('radial',10,260,count=8),move('dash',9,65),move('lob',8,120,radius=26)],
 [move('combo',10,85,second_damage=12,delay=.4),move('cone',9,70),move('dash',13,65)],
 [move('dash',17,65,push=40),move('guard',duration=2,arc=140),move('cone',12,85,arc=150)],
 [move('cone',8,70,status='steal'),move('shot',9,230),move('sidestep',reach=42)],
 [move('lob',8,200,radius=35,status='hook'),move('reel',reach=200,duration=.75,distance=65),move('cone',14,100,arc=130)],
 [move('hook',6,91,hook_duration=.6,auto_reel=True),move('cone',11,65,arc=80),move('cone',9,90,arc=100)],
 [move('dash',0,104,trail=True),move('shot',9,210),move('sidestep',reach=52)],
 [move('dash',19,156,velocity=286,bounce=True),move('cone',10,80,arc=100,rear=True),move('sidestep',reach=39)],
 [move('lob',12,270,radius=39,pool=1),move('lob',7,270,radius=32,count=2,delay=.8),move('cone',9,70,arc=80)],
 [move('dash',12,104),move('ring',8,65),move('regroup')],
 [move('combo',8,100,second_damage=8,delay=.8),move('shot',6,210),move('sidestep',reach=52)],
 [move('combo',15,85,second_damage=15,delay=.4,pool=.7),move('dash',13,65),move('cone',12,85)],
 [move('cone',12,90,arc=35),move('backstep',reach=39),move('cone',16,100,arc=150)],
 [move('phantom',13,110,arc=30),move('haze',reach=115,duration=2),move('cone',8,70)],
 [move('buff',reach=260,duration=4),move('cone',9,65),move('backstep',reach=47)],
 [move('dash',17,156,bend=True),move('cone',11,75),move('pool',3,52,duration=1,count=2)],
 [move('dash',3,65,status='cling'),move('cone',4,60),move('sidestep',reach=52)],
 [move('combo',10,85,second_damage=11,delay=.4,pool=1),move('cone',9,65,arc=35),move('sidestep',reach=39)],
 [move('hook',5,145,hook_duration=4,auto_reel=True,distance=47),move('siphon',reach=100,duration=2),move('cone',10,70)],
 [move('teleport',reach=180,transit=True),move('cone',12,70,status='poison'),move('pool',5,65,duration=1.5,arc=55)],
 [move('ring',0,117,status='weaken',duration=3),move('shot',8,230),move('sidestep',reach=39)],
 [move('dash',7,65,guard=True,arc=150,push=30),move('cone',12,65,arc=140),move('sidestep',9,39)],
 [move('guard',duration=2,arc=145),move('cone',16,90,arc=145,push=35),move('cone',11,65,arc=90)],
]

result = {}
for key, enemy in source.items():
    moves = sets[enemy['id']]
    for definition, authored in zip(moves, enemy['moves']):
        definition['name'] = authored['name']
        for field, default in [('tell', .65), ('recovery', .4), ('cooldown', 3)]:
            match = re.search(r'\d+(?:\.\d+)?', authored[field])
            definition[field] = float(match[0]) if match else default
    result[key] = moves
(root / 'data/enemies/abilities.json').write_text(json.dumps(result, indent=2)+'\n')
print('Wrote explicit definitions for', sum(map(len, result.values())), 'moves')
