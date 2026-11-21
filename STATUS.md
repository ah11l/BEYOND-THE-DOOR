# Project Status — BEYOND THE DOOR (ما وراء الباب)

**Studio:** majnon.studio (مجنون استديو)  
**Version:** `v8.0-source`  
**Engine Target:** Godot 4.5.2 (`GL Compatibility` mobile renderer)

## Current Implementation Status

- **Core Engine & Gameplay:** Complete (Godot 4.5.2, 120 distinct geometrically verified stages across 6 worlds, 4 functional door types, 5s/7s Echo system, luminous energy conduits, 3D door lock badges, automatic cinematic Golden Door transitions).
- **Story, Crystals & Endings:** Complete (6 World Story Chapter cutscenes, 120 lore memories, 4 Crystal Power milestones at 10/25/45/60 crystals, 3 endings at Stage 120).
- **UI, Localization & Branding:** Complete (773 embedded AR/EN keys in `translations_data.gd`, bundled Noto Arabic fonts, live 3D Main Menu, minimal frosted-glass HUD, full-left-half floating touchpad, interactive vector `majnon.studio` splash, official borderless Android/Google Play app icons).
- **Android Debug APK CI & Device Testing:** Debug APK successfully exported via GitHub Actions (`barichello/godot-ci:4.5.2`) and tested on Android hardware through iterative V1–V8 visual, HUD, stability, and geometry fixes.

## Remaining Before Google Play Release

1. **Full Playtest Pass on V8 APK:** Verify updated V8 geometry, bridges, story chapter cards, and extended play stability on target Android devices.
2. **Release AAB & Signing:** Configure a private release keystore and Gradle Build workflow to export and sign `beyond_the_door_release.aab` for Google Play Console.
3. **Live AdMob Verification:** Complete Google AdMob app-ads.txt / Play Store linking and verify live banner & rewarded ads on a release build.
