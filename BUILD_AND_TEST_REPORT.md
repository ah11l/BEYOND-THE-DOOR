# BEYOND THE DOOR (ما وراء الباب) — Build & Test Report (V9)

**Engine:** Godot 4.5.2 (`GL Compatibility`)  
**Workflow:** `.github/workflows/main.yml` (`barichello/godot-ci:4.5.2`)  
**Content Scope:** 120 Stages (6 Worlds × 20), 120 Memory Crystals, Secret Ending at 60 Crystals in Stage 120.

## 1. Automated Static QA Audit (`tools/qa_stage_audit.py`)
- **Stages Parsed:** 120 / 120 (`world_1_data.gd` – `world_6_data.gd`)
- **State-Bound Collectibles Verified:** 42 keys + 42 memory crystals (now gated by `set_state_active()` disabling `Area3D` monitoring/collision when hidden)
- **Broken `plate_id` / `zone_id` References:** 0
- **Unreachable Golden Exit Doors (BFS with jump/bridge/gravity-column/black-door graph):** 0

## 2. V9 Gameplay & Logic Fixes Applied
1. **Hidden State Collectibles (`key_pickup.gd`, `memory_secret.gd`, `stage_builder.gd`):** Added `set_state_active(active: bool)` disabling `visible`, `Area3D.monitoring`, `Area3D.monitorable`, collision layer/mask, and `CollisionShape3D.disabled` when hidden or collected.
2. **Echo World/State Sync (`echo_ghost.gd`, `echo_recorder.gd`):** `EchoGhost` now compares each recorded frame's `world_side` and `room_state` with live player state, toggling `visible`, `collision_layer`, and `CollisionShape3D.disabled`.
3. **Overlapping Gravity Zones (`gravity_zone.gd`, `player.gd`):** `PlayerController` now tracks active zones by `zone_id` and recomputes effective `gravity_scale` and `upward_lift` on enter/exit.
4. **Stage Skip Cap & Cleanup (`stage_builder.gd`):** Fixed `skip_stage` guard from `stage_id < 30` to `stage_id < GameState.TOTAL_STAGES` (120) and removed duplicate `match` and crystal-power branches.

## 3. Build & Runtime Status (Honest Separation)
- **Source & Static Verification:** Completed in this environment (`tools/qa_stage_audit.py` exit code 0). Godot runtime/editor is not installed in the source-packaging sandbox.
- **Android Debug APK:** Built automatically on GitHub Actions via `.github/workflows/main.yml` (`beyond-the-door-debug-apk` artifact; not bundled inside the source repository ZIP).
- **Android Release AAB (Google Play + AdMob):** Automated in `.github/workflows/main.yml` via Gradle Build + `AndroidManifest.xml` AdMob ID injection; activates automatically once the 3 keystore secrets (`BTD_RELEASE_KEYSTORE_BASE64`, `BTD_RELEASE_KEYSTORE_PASSWORD`, `BTD_RELEASE_KEY_ALIAS`) are added in GitHub Secrets.
- **Recommended Device QA Checklist (on freshly built Debug APK):**
  - Test a state-bound key/crystal stage (e.g., Stage 41 or 81) in both Room State A and Room State B.
  - Record an Echo on a plate, toggle Purple Door / Black Door, and confirm the Echo stops triggering the plate out of state.
  - Test Blue Door gravity columns (e.g., Stage 15, 21) and Stage 30+ rewarded skip.
