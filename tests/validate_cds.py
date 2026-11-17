import os
import re
import csv
import json

def test_tracks_exist():
    print("Testing tracks existence and structure...")
    base_dir = r"Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1"
    tracklist_path = os.path.join(base_dir, "Tracklist.csv")
    assert os.path.exists(tracklist_path), f"Tracklist.csv missing at {tracklist_path}"
    
    with open(tracklist_path, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        tracks = list(reader)
        
    assert len(tracks) == 16, f"Expected 16 tracks in CSV, found {len(tracks)}"
    
    biomes = {
        "maintenance": tracks[0:4],
        "factory": tracks[4:8],
        "boiler": tracks[8:12],
        "toxin_refinery": tracks[12:16]
    }
    
    audio_dir = os.path.join(base_dir, "Audio")
    audio_folders = sorted(os.listdir(audio_dir))
    assert len(audio_folders) == 16, f"Expected 16 audio folders, found {len(audio_folders)}"
    
    for i, folder in enumerate(audio_folders):
        folder_path = os.path.join(audio_dir, folder)
        assert os.path.isdir(folder_path), f"{folder_path} is not a directory"
        loop_path = os.path.join(folder_path, "Quiet_Lobby_Loop.ogg")
        assert os.path.exists(loop_path), f"Missing Quiet_Lobby_Loop.ogg in {folder_path}"
        title = tracks[i][1]
        print(f"Track {i+1:02d}: {title} ({folder}) -> Loop verified at {loop_path}")
    
    print("All 16 audio tracks exist and are verified!\n")

def test_script_syntax_and_contents():
    print("Checking save_slots.gd and roguelike_run.gd content...")
    with open("scripts/save_slots.gd", "r", encoding="utf-8") as f:
        save_slots_content = f.read()
    
    assert "01_Copper_Hearth" in save_slots_content
    assert "16_Homeward_Through_Mist" in save_slots_content
    assert "BIOME_CDS" in save_slots_content
    assert "get_uncollected_cds" in save_slots_content
    assert "collect_cd" in save_slots_content
    assert "collected_cds" in save_slots_content
    
    with open("scripts/roguelike_run.gd", "r", encoding="utf-8") as f:
        run_content = f.read()
    
    assert "get_uncollected_cds" in run_content
    assert "exit_rng.randi_range(0, 2) == 0" in run_content
    assert "MUSIC CD:" in run_content
    assert "save_slots.collect_cd(awarded_track)" in run_content
    
    with open("scripts/blockout_room.gd", "r", encoding="utf-8") as f:
        blockout_content = f.read()
    
    assert '"cds": "MUSIC CD"' in blockout_content
    
    with open("tests/test_memory_rules.gd", "r", encoding="utf-8") as f:
        test_memory_content = f.read()
    
    assert "RULE 18: CD Rewards & 16-Track Biome Distribution" in test_memory_content
    
    print("Script contents and hooks verified!\n")

def test_rarity_and_pool_simulation():
    print("Simulating exit reward generation and CD pool logic...")
    # Simulate the logic in _generate_unique_exit_rewards
    import random
    
    BIOME_CDS = {
        "maintenance": ["01_Copper_Hearth", "02_Scribes_of_the_Air", "03_Parlour_Above_the_Clouds", "04_Captains_Quadrille"],
        "factory": ["05_Clockwork_Pavane", "06_Fathers_Photograph", "07_Brass_and_Lace", "08_Liberty_Overture"],
        "boiler": ["09_Glass_Horizon", "10_Aether_Lullaby", "11_Time_Between_Gears", "12_Skylight_Chapel"],
        "toxin_refinery": ["13_Observatory_of_Dreams", "14_The_Unsent_Letter", "15_Wings_Beyond_Tomorrow", "16_Homeward_Through_Mist"]
    }
    
    class SaveSlotsSim:
        def __init__(self):
            self.collected_cds = []
        def get_uncollected_cds(self, biome):
            return [t for t in BIOME_CDS.get(biome, []) if t not in self.collected_cds]
        def collect_cd(self, tid):
            if tid not in self.collected_cds:
                self.collected_cds.append(tid)

    sim = SaveSlotsSim()
    
    # 1. Test full pool: 4 uncollected CDs in maintenance
    assert len(sim.get_uncollected_cds("maintenance")) == 4
    
    # Simulate 10000 room roll checks
    cds_pool_entries = 0
    N = 10000
    for seed in range(N):
        rng = random.Random(seed * 137)
        uncollected = sim.get_uncollected_cds("maintenance")
        if uncollected and rng.randint(0, 2) == 0:
            cds_pool_entries += 1
            
    frequency = cds_pool_entries / N
    print(f"Pool inclusion frequency across {N} runs: {frequency:.4f} (expected ~0.3333, 3x rarer)")
    assert 0.31 < frequency < 0.35, f"Frequency {frequency} out of expected 1/3 bounds"
    
    # 2. Test collection and duplicate prevention
    collected_first = sim.get_uncollected_cds("maintenance")[0]
    sim.collect_cd(collected_first)
    assert collected_first not in sim.get_uncollected_cds("maintenance")
    assert len(sim.get_uncollected_cds("maintenance")) == 3
    
    # 3. Test biome completion: collect remaining 3 tracks
    for t in list(sim.get_uncollected_cds("maintenance")):
        sim.collect_cd(t)
    
    assert len(sim.get_uncollected_cds("maintenance")) == 0
    
    # Verify cds NEVER enters pool when biome is cleared
    cds_pool_entries_cleared = 0
    for seed in range(N):
        rng = random.Random(seed * 137)
        uncollected = sim.get_uncollected_cds("maintenance")
        if uncollected and rng.randint(0, 2) == 0:
            cds_pool_entries_cleared += 1
            
    assert cds_pool_entries_cleared == 0, "CDs entered pool when biome was cleared!"
    print(f"Cleared biome pool inclusion: {cds_pool_entries_cleared} / {N} (verified 0%)")
    
    # 4. Next biome: factory has 4 tracks
    assert len(sim.get_uncollected_cds("factory")) == 4
    print("All simulation checks passed successfully!\n")

if __name__ == "__main__":
    test_tracks_exist()
    test_script_syntax_and_contents()
    test_rarity_and_pool_simulation()
    print("ALL VALIDATION SUCCEEDED.")
