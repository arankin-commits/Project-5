"""Slice supplied character frames into Godot-ready textures without redrawing them."""
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "characters" / "Hades-Style Character and Robot Sprite Sheet.png"
GIF = ROOT / "characters" / "medium_robot_dash.gif"
DEST = ROOT / "art" / "characters"
DEST.mkdir(parents=True, exist_ok=True)

sheet = Image.open(SOURCE).convert("RGBA")
for index in range(8):
    crop = sheet.crop((635 + 105 * index, 65, 750 + 105 * index, 200))
    rgb = np.asarray(crop)[:, :, :3].astype(np.int16)
    brightest = rgb.max(axis=2)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    # The supplied sheet has a dark painted backdrop rather than alpha. Keep
    # the bright colored figure, then close its dark costume details inside it.
    seed = np.where((brightest > 64) & ((chroma > 13) | (brightest > 100)), 255, 0).astype("uint8")
    mask = Image.fromarray(seed, "L")
    mask = mask.filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.MinFilter(13))
    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    crop.putalpha(mask)
    crop.save(DEST / f"main_walk_{index}.png")

for index in range(8):
    crop = sheet.crop((635 + 105 * index, 500, 750 + 105 * index, 640))
    rgb = np.asarray(crop)[:, :, :3].astype(np.int16)
    brightest = rgb.max(axis=2)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    seed = np.where((brightest > 64) & ((chroma > 13) | (brightest > 100)), 255, 0).astype("uint8")
    mask = Image.fromarray(seed, "L")
    mask = mask.filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.MinFilter(13))
    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    crop.putalpha(mask)
    crop.save(DEST / f"medium_walk_{index}.png")

robot = Image.open(GIF)
for index in range(robot.n_frames):
    robot.seek(index)
    frame = robot.convert("RGBA")
    rgb = np.asarray(frame)[:, :, :3].astype(np.int16)
    brightest = rgb.max(axis=2)
    mask = Image.fromarray(np.where(brightest > 23, 255, 0).astype("uint8"), "L")
    mask = mask.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(7))
    mask = mask.filter(ImageFilter.GaussianBlur(0.5))
    frame.putalpha(mask)
    frame.save(DEST / f"medium_dash_{index}.png")

print("Exported 8 main-character walk frames, 8 Medium walk frames, and 6 Medium dash frames")
