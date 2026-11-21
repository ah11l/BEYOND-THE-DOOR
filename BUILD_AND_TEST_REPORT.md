# Factual Build & Test Report — BEYOND THE DOOR (ما وراء الباب)

## 1. Environment Capabilities & Blockers

| Capability / Tool | Status in Sandbox | Impact |
| :--- | :--- | :--- |
| Python 3.11.2 | Available | Used for procedural asset/audio generation, static validation, and ZIP packaging |
| Noto Arabic & Latin Fonts (SIL OFL) | Available | Bundled into `assets/fonts/` for Arabic shaping and Latin UI |
| Godot 4.x CLI / Editor (`godot`, `godot4`) | **Not Installed** | Cannot run headless scene parse, runtime playtests, or automated Godot unit tests here |
| Android SDK / Gradle / ADB / Export Templates | **Not Installed** | **APK and AAB binaries could NOT be exported or signed in this environment** |

## 2. Verification Matrix (Strictly Separated)

### A. Implemented & Statically Source-Reviewed (Automated Validator Passed: 0 Errors)
- **36 GDScript (`.gd`) files**, **6 Godot scenes (`.tscn`)**, **2 shaders (`.gdshader`)**, **14 WAV audio files**, **4 TTF font files**, `project.godot`, `export_presets.cfg`, `default_bus_layout.tres`, and `icon.svg`.
- **Resource Path Resolution:** Every `res://` path across `project.godot`, `.tscn`, `.tres`, and `.gd` files verified to exist on disk.
- **Godot 4.x API Hygiene:** Zero deprecated Godot 3 APIs (`KinematicBody`, `Spatial`, `yield()`, `.instance()`, `File.new()`, `deg2rad()`, `move_and_slide(args)`, etc.) detected across all 36 scripts.
- **Class Name Uniqueness:** Zero duplicate `class_name` declarations.
- **Localization Coverage:** `assets/localization/translations.csv` verified with **196 keys**, 100% populated in both English (`en`) and Arabic (`ar`), plus an `es` column ready for Spanish; every static UI key, stage title/objective, clue, hint, lore memory, and ending key referenced in code exists in the CSV.
- **30-Stage Distinctness & Structural Integrity:** All 30 stages (IDs 1–30, 5 per world across 6 worlds) verified to have unique layout/puzzle fingerprints, valid spawn/checkpoint/secret (`mem_01`–`mem_30`), valid exit (`GoldenDoor` on stages 1–29, 3 `EndingPedestal`s on stage 30), sufficient keys for every locked door, valid `BlueDoor`→`GravityZone` links, and valid `PressurePlate`→bridge links.
- **Audio & Font Integrity:** All 14 WAV files verified via Python `wave` module (non-zero frames); all 4 Noto TTF fonts verified present and valid.

### B. NOT Runtime-Tested (Requires Godot 4.3+ Editor/Runtime)
- Live 3D viewport rendering, shader compilation (`starry_night_sky.gdshader`, `echo_ghost.gdshader`), and lighting/fog balance.
- Live `CharacterBody3D` movement, jump arcs, `PushableBlock` physics feel, `GravityZone` vertical lift tuning, and `EchoGhost` timing across all 30 stages.
- Runtime save/load persistence across actual app restarts (`SaveManager`).
- Live Arabic RTL rendering, HarfBuzz glyph shaping, and HUD layout across multiple phone aspect ratios.

### C. NOT Device-Tested / NOT Exported
- Android APK (`beyond_the_door_debug.apk`) and Google Play AAB (`beyond_the_door_release.aab`) were **not built** due to missing Godot 4.x and Android SDK in this sandbox.
- Frame rate (FPS), thermal/memory usage, and physical touchscreen ergonomics on mid-range Android phones remain to be measured after exporting on a Godot + Android SDK machine.

## 3. Known Limitations & Next Steps
1. Open `project.godot` in Godot 4.3+ and run a quick playtest pass starting with Stage 1, Stage 4 (Echo), Stage 6 (Blue Door), Stage 11 (Purple Door), Stage 16 (Black Door), and Stage 30 (Endings).
2. Fine-tune `GravityZone.upward_lift` and island bridge clearances if any jump/lift feels too fast or slow during live playtesting.
3. Export APK/AAB using the pre-configured `export_presets.cfg` once Godot 4.3 export templates and Android SDK are configured.


## 4. Packaging automation added

- Added `.github/workflows/android.yml` to import the project in a GitHub-hosted runner, attempt a debug APK export, and upload build artifacts.
- Added optional signed AAB export when repository secrets are configured: `BTD_RELEASE_KEYSTORE_BASE64`, `BTD_RELEASE_KEYSTORE_PASSWORD`, and `BTD_RELEASE_KEY_ALIAS`.
- Added `.gitignore` entries for Godot-generated data, build outputs, and keystore files.
- Added instructions in `README.md` for running the workflow and setting up signing secrets.

**This ZIP has not been built by GitHub Actions yet.** The workflow and release-configuration script have been reviewed as text and the Python script can be syntax-checked locally, but the Godot export itself remains unverified until the workflow is run in the target GitHub repository. The preset currently targets Android API 34; verify the current Google Play target-API policy before publishing.
