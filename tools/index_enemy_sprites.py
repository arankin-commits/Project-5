"""Index sprite bounds from generated alpha without altering the source artwork."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
result = {}
for biome, rows in [("maintenance",8),("factory",8),("boiler",9),("toxin_refinery",8)]:
    im = Image.open(ROOT / "art/enemies_reference" / (biome + ".png"))
    # Boiler's generated sheet has generous uneven row spacing; authored cuts follow its gutters.
    cuts = [0,220,400,620,810,990,1200,1410,1620,1881] if biome == "boiler" else [round(i*im.height/rows) for i in range(rows+1)]
    indexed = []
    for row in range(rows):
        frames = []
        for direction in range(8):
            left, right = round(direction*im.width/8), round((direction+1)*im.width/8)
            tile = im.getchannel("A").crop((left,cuts[row],right,cuts[row+1]))
            bounds = tile.point(lambda a: 255 if a > 220 else 0).getbbox()
            assert bounds, (biome,row,direction)
            frames.append({"center": (bounds[0]+bounds[2])/2, "bottom": bounds[3]})
        indexed.append({"top": cuts[row], "height": cuts[row+1]-cuts[row], "frames": frames})
    result[biome] = indexed
(ROOT / "data/enemies/reference_sprites.json").write_text(json.dumps(result,indent=2)+"\n")
print("Indexed 33 enemies and 264 directional sprites")
