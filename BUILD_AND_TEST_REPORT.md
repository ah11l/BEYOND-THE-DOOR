# BEYOND THE DOOR (ما وراء الباب) — Build & Test Report (V10)

**Engine:** Godot 4.5.2 (`GL Compatibility`)  
**Workflow:** `.github/workflows/main.yml` (`barichello/godot-ci:4.5.2`) — Verified Green for both Debug APK & Signed Google Play Release AAB  
**Content Scope:** 120 Stages (6 Worlds × 20), 120 Memory Crystals, Secret Ending at 60 Crystals in Stage 120.

## 1. Automated Static QA & Asset Integrity Audit (`tools/qa_stage_audit.py`)
- **Stages Parsed:** 120 / 120 (`world_1_data.gd` – `world_6_data.gd`)
- **State-Bound Collectibles Verified:** 42 keys + 42 memory crystals (gated by `set_state_active()`)
- **Broken `plate_id` / `zone_id` References:** 0
- **Unreachable Golden Exit Doors (BFS graph check):** 0
- **Asset Format Integrity (PNG / TTF / SVG / WAV magic-byte check):** 100% Pass (`assets/icons/majnon_studio_logo.png` converted to genuine PNG; 0 format mismatches).

## 2. V10 + V9 Fixes Applied
1. **Studio Logo Format Fix (`assets/icons/majnon_studio_logo.png`):** Re-encoded from misnamed JPEG bytes to genuine PNG so Godot imports it cleanly without `ERR_FILE_CORRUPT`.
2. **Hidden State Collectibles (`key_pickup.gd`, `memory_secret.gd`, `stage_builder.gd`):** `set_state_active(active: bool)` disables `visible`, `Area3D.monitoring`, `Area3D.monitorable`, collision layer/mask, and `CollisionShape3D.disabled`.
3. **Echo World/State Sync (`echo_ghost.gd`, `echo_recorder.gd`):** `EchoGhost` enforces live `world_side` and `room_state` matching.
4. **Overlapping Gravity Zones (`gravity_zone.gd`, `player.gd`):** `PlayerController` manages overlapping zones by `zone_id`.
5. **Stage Skip Cap & Cleanup (`stage_builder.gd`):** `skip_stage` uses `stage_id < GameState.TOTAL_STAGES` (120); duplicate branches removed.
6. **Production CI Pipeline (`.github/workflows/main.yml`):** Uses pure POSIX `awk` (no `python3` dependency), writes `android/.build_version = 4.5.2.stable`, injects AdMob `APPLICATION_ID`, and exports signed Google Play AAB.

## 3. Build & Runtime Status (Honest Separation)
- **GitHub Actions CI:** Verified green exporting both `beyond-the-door-debug-apk` and signed `beyond-the-door-google-play-aab`.
- **Static Audit:** `tools/qa_stage_audit.py` passes with exit code 0 (does not substitute for full live gameplay playtesting across all 120 stages).
- **Pending Live Device QA:** Playtest V9/V10 fixes on Debug APK, and verify live AdMob ads via Google Play Console Internal Testing with the signed AAB.
