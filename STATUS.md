# BEYOND THE DOOR (ما وراء الباب) — Project Status (V10)

**Studio:** majnon.studio (مجنون استديو)  
**Engine:** Godot 4.5.2 (`GL Compatibility` / GDScript)  
**Repository:** `ah11l/BEYOND-THE-DOOR`

## Implemented & Verified in Source (V10)
- **120 Stages across 6 Worlds (20 stages/world)** with 120 Memory Crystals, 4 Crystal Powers (10 / 25 / 45 / 60 crystals), and 3 Endings in Stage 120 (Stop, Restart, and Secret Ending "Liberation" at 60 crystals).
- **V10 Asset Integrity Fix:**
  - Converted `assets/icons/majnon_studio_logo.png` from misnamed JPEG bytes to a genuine PNG (`\x89PNG\r\n\x1a\n`), eliminating `ERR_FILE_CORRUPT` during Godot resource import.
  - Added automated magic-byte asset verification (PNG, TTF, SVG, WAV) to `tools/qa_stage_audit.py`.
- **V9 Gameplay & Physics Fixes (Included Cumulatively):**
  - `KeyPickup` & `MemorySecret`: Added `set_state_active(active)` disabling `Area3D` monitoring, monitorable, collision layer/mask, and `CollisionShape3D` when hidden by `room_state` (42 state-bound keys & 42 state-bound memory crystals).
  - `EchoGhost` & `EchoRecorder`: Echo replay checks recorded `world_side` and `room_state` against live player state every physics frame, disabling visibility and collision when out of sync.
  - `PlayerController` & `GravityZone`: Tracks overlapping active zones by `zone_id` (`enter_gravity_zone` / `exit_gravity_zone`).
  - `StageBuilder`: Fixed `skip_stage` rewarded ad cap to `< GameState.TOTAL_STAGES` (120) and removed duplicate `match`/threshold branches.
- **CI/CD & Android Export (Verified Green on GitHub Actions):**
  - `.github/workflows/main.yml` (`barichello/godot-ci:4.5.2`) builds both **Debug APK** (`beyond-the-door-debug-apk`) and **Signed Google Play Release AAB** (`beyond-the-door-google-play-aab`) with Gradle Build, `android/.build_version = 4.5.2.stable`, and automatic AdMob `APPLICATION_ID` injection into `AndroidManifest.xml`.

## Pending Device & Release Verification
- Live Android testing of V9/V10 fixes on the latest Debug APK artifact (state-bound pickups, Echo state sync, overlapping gravity zones, and studio logo in pause menu).
- Live AdMob ad verification via Google Play Console Internal Testing using `beyond-the-door-google-play-aab`.
