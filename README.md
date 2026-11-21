# BEYOND THE DOOR — ما وراء الباب

Developed by **majnon.studio (مجنون استديو)** — an atmospheric, offline-first 3D low-poly isometric puzzle-exploration game for Android, built with **Godot 4.5.2 and GDScript**.

## Core Features (V8)

- **120 Distinct Stages Across 6 Worlds (20 Stages per World):**
  - World 1 (1–20): *The Awakening / عالم الاستيقاظ* (ending with Stage 20 Hardcore Labyrinth)
  - World 2 (21–40): *The Reversed Sky / عالم السماء المعكوسة*
  - World 3 (41–60): *The Two Faces / عالم الوجهين*
  - World 4 (61–80): *The Other Side / عالم الجانب الآخر*
  - World 5 (81–100): *Fractured Memories / عالم الذكريات المتصدعة*
  - World 6 (101–120): *Beyond the Door / عالم ما وراء الباب* (Stage 120 Finale Sanctuary with 3 Endings)
- **Four Functional Door Mechanics:** Golden Door (automatic cinematic exit with floating 3D lock-requirement badges), Blue Door (local gravity lift), Purple Door (Room State A/B toggle), and Black Door (Alternate World transfer).
- **The Echo Mechanic ("صدى المكان"):** Records 5 seconds of movement (upgradable to **7 seconds** at 25 Crystals) and replays it via a glowing cyan Fresnel ghost.
- **120 Memory Crystals, Story Chapters & 4 Crystal Powers:**
  - Full-screen Arabic/English World Story Chapter cutscenes at the start of every World.
  - **10 ◆:** Lantern Insight • **25 ◆:** Extended 7-Second Echo • **45 ◆:** Starlight Stride (+15% Speed) • **60 ◆:** Unlocks the **Secret Ending (Liberation / التحرر)** in Stage 120 alongside **Stop** and **Restart**.
- **Mobile-First Arabic UI & Controls:** 100% embedded Arabic RTL + English localization (`translations_data.gd`, 773 keys), bundled Noto Sans Arabic fonts, full-left-half floating analog touchpad (`TouchJoystick`), Coyote Time & Jump Buffer, live 3D Main Menu diorama, and interactive vector-drawn `majnon.studio` splash screen.
- **Monetization (Offline-First):** Google AdMob v5.1.0 Android AARs bundled (`addons/admob/android/bin/ads/`) with Top Banner + Rewarded Hint/Skip bridge (`monetization_bridge.gd`); automatically uses Google Test IDs in Debug builds and remains 100% playable offline.

## Building Android APK & Google Play AAB

- **GitHub Actions CI (`.github/workflows/main.yml` / `android.yml`):** Uses `barichello/godot-ci:4.5.2` to export `builds/beyond_the_door_debug.apk` automatically on every push.
- **Google Play Release AAB:** Configured in `export_presets.cfg` (`[preset.1]` — `"Android Google Play AAB"`). Requires configuring your release keystore (`keystore/release`, `keystore/release_user`, `keystore/release_password`) and enabling Gradle Build with the Poing Studios AdMob addon before Play Console submission.
