# Boiler district validation — 2026-11-11

Executed locally with Godot 4.7.2 stable, Windows, GL Compatibility.

- Editor import completed. New art resources and game scripts load successfully.
- `tests/test_cockpit.gd`: `COCKPIT_TESTS_PASSED` (existing ship travel, collisions, interactions, core terminal, Sync Pod).
- `tests/test_run_setup.gd`: `BOILER_RUN_CHECKS=178 FAILURES=0`, `RUN_SETUP_TESTS_PASSED`.
- `tests/test_live_combat.gd`: `LIVE_COMBAT_PASSED`; normal movement/attacks cleared all three first-room enemies with 100 hull remaining. No direct enemy damage or player-health override is used by this smoke test.
- `tests/capture_run.gd`: all eight room captures, boss warning, punch pose, and salvage UI saved successfully (PNG save result 0). Final capture/test runs report no game parser/runtime errors or leaked instances.
- Visually inspected boiler, condenser, boss, attack, and reward renders. Isometric floor projection, upright directional sprites, transparency, and machinery overlap are working. No missing art was observed.

The environment reports user-log/editor-settings write restrictions and an unavailable certificate store. These are sandbox/host warnings, separate from the game checks above.

The progression test clears later waves through damage/death callbacks; it is not a manual full-run combat playthrough. Difficulty balance beyond the first live encounter remains a playtesting task. The eight layouts share four painted room shells; the robot uses directional keyposes with a two-pose gait, not a full animation cycle. No known blocking alignment/collision issue remained in the automated route and footprint checks.
