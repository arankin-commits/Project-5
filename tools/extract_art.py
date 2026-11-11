"""Extract the original full-canvas paint layers from the supplied OpenRaster file."""
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Flying_Liberty_Cockpit_v4_Krita_and_Sprites" / "Cockpit_v4_Genuine_Editable_Layers.ora"
DEST = ROOT / "art" / "cockpit" / "full_canvas"
DEST.mkdir(parents=True, exist_ok=True)

with ZipFile(SOURCE) as archive:
    stack = ET.fromstring(archive.read("stack.xml")).find("stack")
    for layer in stack.findall("layer"):
        name = layer.attrib["name"].replace(" ", "_") + ".png"
        (DEST / name).write_bytes(archive.read(layer.attrib["src"]))
        print(name)
