import os

target_dirs = [
    'art/biomes',
    'art/industrial_enemies',
    'art/painted_biomes',
    'art/characters',
    'characters/NPCS',
    'characters/MC',
    'rooms/Flying liberty',
    'rooms/Hazards',
    'art/boiler',
    'art/cockpit'
]

extensions = ('.png.import', '.svg.import')

updated_files = []
already_lossy = 0

for target in target_dirs:
    if not os.path.exists(target):
        continue
    for root, dirs, files in os.walk(target):
        for f in files:
            if f.endswith(extensions):
                p = os.path.join(root, f)
                try:
                    with open(p, 'r', encoding='utf-8') as fh:
                        content = fh.read()
                    
                    if 'compress/mode=1' in content:
                        already_lossy += 1
                        continue

                    lines = content.splitlines(keepends=True)
                    new_lines = []
                    has_mode = False
                    has_quality = False

                    for line in lines:
                        if line.startswith('compress/mode='):
                            new_lines.append('compress/mode=1\n')
                            has_mode = True
                        elif line.startswith('compress/lossy_quality='):
                            new_lines.append('compress/lossy_quality=0.85\n')
                            has_quality = True
                        elif line.startswith('mipmaps/generate='):
                            new_lines.append('mipmaps/generate=false\n')
                        else:
                            new_lines.append(line)

                    # If mode wasn't present in lines, insert after [params]
                    if not has_mode:
                        final_lines = []
                        for line in new_lines:
                            final_lines.append(line)
                            if line.strip() == '[params]':
                                final_lines.append('compress/mode=1\n')
                                if not has_quality:
                                    final_lines.append('compress/lossy_quality=0.85\n')
                        new_lines = final_lines

                    with open(p, 'w', encoding='utf-8') as fh:
                        fh.writelines(new_lines)

                    updated_files.append(p.replace('\\', '/'))
                except Exception as e:
                    print(f"Error updating {p}: {e}")

print(f"Updated {len(updated_files)} import files to Lossy WebP (quality 0.85).")
print(f"Already lossy: {already_lossy} files.")
