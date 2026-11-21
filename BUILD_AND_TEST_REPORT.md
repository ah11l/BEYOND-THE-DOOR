# Factual Build & Test Report — BEYOND THE DOOR (ما وراء الباب)

**Engine:** Godot 4.5.2 (`GL Compatibility`)  
**Scope:** 120 Stages (6 Worlds × 20 Stages), 120 Memory Crystals, 3 Endings (Stage 120; Secret Ending at 60 Crystals)

## 1. Statically & Geometrically Verified
- **120 Distinct Stages:** Automated Python validation confirmed 0 duplicate stage layouts, 0 missing localization keys (773 EN/AR embedded keys in `translations_data.gd`), valid key/plate/gravity-zone links, and mathematical clamping of all doors, keys, plates, blocks, checkpoints, secrets, and props strictly inside island boundaries (116 overlapping/out-of-bounds props removed in V8).
- **Resource & Asset Integrity:** All `res://` paths, SVG UI icons, official borderless Android/Google Play PNG icons (`512×512`, `192×192`, `432×432` adaptive), Noto Arabic fonts, and 14 prototype WAV audio files verified present.

## 2. Built & Device-Tested (Android Debug APK via GitHub Actions)
- **GitHub Actions Export:** Successfully exported `beyond_the_door_debug.apk` using `barichello/godot-ci:4.5.2` (`main.yml`).
- **On-Device Fixes Verified Iteratively:** Resolved Android `.pck` CSV localization issue (moved to embedded `translations_data.gd`), replaced unsupported emojis with SVG icons, added full-left-half floating touchpad, fixed `SubViewport` typing error, disabled `OmniLight3D` cubemap shadows + converted stars to `MultiMeshInstance3D` for mobile stability, fixed bridge Z-fighting/gaps, and cleaned up HUD clutter.

## 3. Not Yet Completed (Pre-Release Checklist)
- **V8 Final Device QA:** Playtest the latest V8 Debug APK across mid/late worlds (Worlds 2–6) and Stage 120 endings.
- **Google Play Release AAB:** Not yet exported or signed (`main.yml` currently exports Debug APK only; Release AAB requires a release keystore and Gradle Build configuration).
- **Production AdMob Live Test:** Production ads require linking the published Google Play listing in AdMob and testing a signed Release build.
