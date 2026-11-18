import os
import json
import re
from PIL import Image

base_dir = r"C:\NCAT\Project-5"
manifest_path = os.path.join(base_dir, r"combat\Elemental_Animation_Reference_Pack\Elemental_Animation_Pack\Animation_Manifest.json")
combat_dir = os.path.join(base_dir, r"combat\Elemental_Animation_Reference_Pack\Elemental_Animation_Pack")
output_dir = os.path.join(base_dir, r"art\card_hud")

with open(manifest_path, 'r', encoding='utf-8') as f:
    manifest = json.load(f)

print(f"Loaded manifest with {len(manifest)} cards.")

card_id_map = {
    "Earthen Armor: Orbiting Wall": "earthen_armor",
    "Earthen Dash: Stone Creation": "earthen_dash"
}

def get_best_frame(im):
    best_frame = 0
    max_energy = -1
    n = im.n_frames
    
    # We want to pick the peak action frame (typically between 30% and 80% into the animation)
    # Background color is roughly dark charcoal #0d1016 (R < 25, G < 25, B < 30)
    for i in range(n):
        im.seek(i)
        rgb = im.convert('RGB')
        pixels = list(rgb.getdata())
        # Energy = sum of color intensity above dark background
        energy = 0
        for p in pixels:
            # Check if pixel has vibrant color or brightness
            if p[0] > 45 or p[1] > 45 or p[2] > 45:
                # Weight by saturation/brightness
                diff = max(p) - min(p)
                bright = sum(p)
                energy += bright + diff * 2
        
        # Slight preference for middle/later frames over first 2 frames
        if i >= 3:
            energy = int(energy * 1.1)
        
        if energy > max_energy:
            max_energy = energy
            best_frame = i
            
    return best_frame

extracted_count = 0
for item in manifest:
    name = item['name']
    gif_rel = item['gif']
    gif_path = os.path.join(combat_dir, gif_rel)
    
    if name in card_id_map:
        cid = card_id_map[name]
    else:
        cid = name.lower().replace(":", "").replace("-", "").replace("  ", " ").replace(" ", "_")
    
    out_filename = f"art_{cid}.png"
    out_path = os.path.join(output_dir, out_filename)
    
    if os.path.exists(gif_path):
        im = Image.open(gif_path)
        best_idx = get_best_frame(im)
        im.seek(best_idx)
        frame_rgb = im.convert('RGB')
        
        # Save frame as PNG
        frame_rgb.save(out_path, format="PNG", optimize=True)
        extracted_count += 1
        print(f"[{extracted_count}/65] Extracted '{name}' (frame {best_idx}/{im.n_frames}) -> {out_filename}")
    else:
        print(f"MISSING GIF: {gif_path}")

print(f"\nDone! Extracted {extracted_count} card visual reference textures to {output_dir}.")
