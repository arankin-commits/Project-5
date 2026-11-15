import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
metadata_path = 'res://rooms/Maintenance_Rebuild_v2/metadata/'
image_path = 'res://rooms/Maintenance_Rebuild_v2/art pass/Flying Liberty Maintenance Room Set-2.png'
layouts = json.loads((root / 'data/maintenance/painted_layouts.json').read_text())
data_path = root / 'data/maintenance/rooms.json'
data = json.loads(data_path.read_text())
assert len(layouts) == len(data['rooms']) == 15
for room, layout in zip(data['rooms'], layouts):
    assert room['id'] == layout['id']
    room['metadata'] = metadata_path + room['id'] + '.json'
    room['image'] = 'res://rooms/Maintenance_Rebuild_v2/rooms/' + room['id'] + '_' + room['name'].replace(' ', '_') + '.png'
    # Retain measured obstacle half-extents in the catalog.
data_path.write_text(json.dumps(data, indent=2) + '\n')
