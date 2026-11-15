"""Build runtime catalogs from the supplied blockouts without changing artwork."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
pack = root / 'rooms/ALL_4_BIOMES_120_UNIQUE_BLOCKOUTS'
source = json.loads((pack / 'all_room_geometry.json').read_text())
enemies = json.loads((root / 'data/enemies/industrial.json').read_text())
bosses = {'maintenance': 'MAINTENANCE GUARDIAN', 'factory': 'ASSEMBLY OVERSEER',
          'boiler': 'FURNACE WARDEN', 'toxin_refinery': 'REFINERY GUARDIAN'}
for biome, boss in bosses.items():
    source_biome = 'boiler_room' if biome == 'boiler' else biome
    rooms = []
    roster = [key for key, enemy in enemies.items() if enemy['biome_key'] == biome]
    for geometry in source['rooms']:
        if geometry['biome'] != source_biome:
            continue
        rooms.append(dict(id=geometry['id'], name=geometry['name'],
                          biome=geometry['biome_display'].upper(), layout=len(rooms),
                          size=geometry['size'], blockout=True, geometry=geometry,
                          image='res://rooms/ALL_4_BIOMES_120_UNIQUE_BLOCKOUTS/' + geometry['image'],
                          reward='repair', waves=[[roster[(len(rooms)*3+n) % len(roster)] for n in [0,1]], [roster[(len(rooms)*3+n) % len(roster)] for n in [2,3]]]))
    assert len(rooms) == 30
    target = root / 'data' / 'blockouts' / (biome + '.json')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(dict(area=source_biome, rooms=rooms,
        boss_encounter=dict(name=boss.title(), boss=True, boss_name=boss,
                            reward='hull', waves=[['boss']])), indent=2) + '\n')
