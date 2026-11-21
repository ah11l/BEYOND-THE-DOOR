# BEYOND THE DOOR (ما وراء الباب) — Project Status (V9)

**Studio:** majnon.studio (مجنون استديو)  
**Engine:** Godot 4.5.2 (`GL Compatibility` / GDScript)  
**Repository:** `ah11l/BEYOND-THE-DOOR`

## Implemented & Verified in Source (V9)
- **120 Stages across 6 Worlds (20 stages/world)** with 120 Memory Crystals, 4 Crystal Powers (10 / 25 / 45 / 60 crystals), and 3 Endings in Stage 120 (Stop, Restart, and Secret Ending "Liberation" at 60 crystals).
- **V9 Gameplay & Physics Fixes:**
  - `KeyPickup` & `MemorySecret`: Added `set_state_active(active)` to disable `Area3D` monitoring, monitorable, collision layer/mask, and `CollisionShape3D` when hidden by `room_state` (42 state-bound keys & 42 state-bound memory crystals).
  - `EchoGhost` & `EchoRecorder`: Echo replay now checks the recorded `world_side` and `room_state` against the live player state every physics frame, disabling visibility and collision when out of sync so echoes cannot press plates in another state/world.
  - `PlayerController` & `GravityZone`: Replaced single-reset gravity exit with a `zone_id`-keyed active zones registry (`enter_gravity_zone` / `exit_gravity_zone`) so overlapping gravity zones blend cleanly without cancelling each other.
  - `StageBuilder`: Fixed `skip_stage` rewarded ad cap from `< 30` to `< GameState.TOTAL_STAGES` (120), removed duplicate `match` and crystal threshold branches, and updated doc comments.
  - `tools/qa_stage_audit.py`: Automated static physics/graph reachability audit passing 120/120 stages (0 broken references, 0 unreachable exit doors).
- **CI/CD & Android Export (`.github/workflows/main.yml` + `export_presets.cfg`):**
  - Automatic Android **Debug APK** build on every push via `barichello/godot-ci:4.5.2`.
  - Automatic **Signed Google Play Release AAB** build with Gradle Build + AdMob `APPLICATION_ID` injection into `AndroidManifest.xml` once the 3 keystore GitHub Secrets are configured.

## Pending Device & Release Verification
- Live Android gameplay verification of the V9 fixes (hidden state pickups, cross-state echo sync, overlapping gravity zones, and Stage 30+ skip) after downloading the latest GitHub Actions Debug APK artifact.
- Generating `release.keystore` and adding `BTD_RELEASE_KEYSTORE_BASE64`, `BTD_RELEASE_KEYSTORE_PASSWORD`, and `BTD_RELEASE_KEY_ALIAS` to GitHub Secrets to export the signed Play Store AAB.
