# BEYOND THE DOOR — ما وراء الباب

An atmospheric, offline-first 3D low-poly isometric puzzle-exploration game for Android, built with **Godot 4.3+ and GDScript**.

## Art Direction & Core Features

- **Low-Poly Isometric World**: Floating faceted stone islands suspended in a deep starry night sky (`starry_night_sky.gdshader`), stylized low-poly trees, glowing stone lanterns, benches, crystal clusters, and wooden/luminous bridges with 6 distinct world palettes.
- **Hooded Protagonist & Isometric Camera**: Responsive `CharacterBody3D` controller with isometric camera-relative movement, optional jump, void-fall checkpoint recovery, and a glowing cyan lantern.
- **Echo Mechanic ("صدى المكان")**: Records up to **5.0 seconds** of player movement and replays it via a translucent cyan Fresnel ghost (`echo_ghost.gdshader`) that activates pressure plates and switches while you move elsewhere.
- **Four Distinct Door Mechanics**:
  1. **Golden Door (`★`)**: Exit/path door unlocked when stage key and switch conditions are satisfied.
  2. **Blue Door (`▲`)**: Toggles local gravity fields (`GravityZone`) to lift the player smoothly to elevated floating islands.
  3. **Purple Door (`◈`)**: Shifts the room between Face A and Face B, revealing/hiding alternate platforms, bridges, keys, and secrets.
  4. **Black Door (`☾`)**: Transfers the player seamlessly between the Primary and Alternate versions of the room/world.
- **30 Distinct Stages Across 6 Worlds**:
  - World 1 (1–5): *The Awakening / عالم الاستيقاظ*
  - World 2 (6–10): *The Reversed Sky / عالم السماء المعكوسة*
  - World 3 (11–15): *The Two Faces / عالم الوجهين*
  - World 4 (16–20): *The Other Side / عالم الجانب الآخر*
  - World 5 (21–25): *Fractured Memories / عالم الذكريات المتصدعة*
  - World 6 (26–30): *Beyond the Door / عالم ما وراء الباب*
- **30 Hidden Memory Crystals & 3 Endings**: Collect 18+ of the 30 Memory Fragments to unlock the **Secret Ending (Liberation / التحرر)** alongside **Ending A (Stop / الإيقاف)** and **Ending B (Restart / إعادة التشغيل)** in Stage 30.
- **Localization & RTL**: Full **Arabic (RTL)** and **English (LTR)** support via `assets/localization/translations.csv`, with a pre-wired `es` (Spanish) column and bundled SIL OFL Noto Sans Arabic + Latin fonts.
- **Offline Local Save System**: Atomic JSON persistence (`user://beyond_the_door_save.json`) with automatic `.bak.json` backup recovery.

## Controls

| Action | Mobile Touch | PC Keyboard |
| :--- | :--- | :--- |
| Move | Bottom-left Virtual Joystick | `WASD` / Arrow Keys |
| Jump | Bottom-right `▲` Button | `Space` |
| Interact | Contextual `✦` Prompt Button | `E` |
| Echo (Record / Replay / Cancel) | Bottom-right `Echo / الصدى` Button | `Q` |
| Pause | Top-left `❚❚` Button | `Esc` |
| Restart Checkpoint | Left-rail `↺` Button | `R` |

## Opening in Godot 4.3+

1. Download **Godot 4.3** (Standard Edition, GDScript).
2. Extract this ZIP and click **Import** in the Godot Project Manager, selecting `project.godot`.
3. Press **F5** (Play) to launch `scenes/main/main_menu.tscn`.

## Exporting Android APK & Google Play AAB

Pre-configured export presets are included in `export_presets.cfg`:

1. Install **OpenJDK 17** and **Android SDK** (API 34, Build-Tools, Platform-Tools) via Android Studio or `sdkmanager`.
2. In Godot: **Editor → Manage Export Templates → Download and Install** for your Godot 4.3.x version.
3. In Godot: **Editor → Editor Settings → Export → Android**, configure your Android SDK path and Debug Keystore.
4. Open **Project → Export**:
   - Select **Android Debug APK** → click **Export Project** to generate `builds/beyond_the_door_debug.apk`.
   - Select **Android Google Play AAB** → configure your release keystore credentials → click **Export Project** to generate `builds/beyond_the_door_release.aab`.

## Audio & Art Notice

- All 3D low-poly assets are procedurally generated in `scripts/visuals/low_poly_mesh_library.gd` for cohesive stylized prototyping and lightweight Android performance.
- All 14 `.wav` audio files (`assets/audio/music/` and `assets/audio/sfx/`) are procedurally synthesized atmospheric **prototype** assets and can be replaced 1-to-1 with final studio recordings without changing any code.
- `scripts/autoload/monetization_bridge.gd` is a clean offline-first stub with **no hardcoded ad unit IDs**.

## GitHub Actions: build an APK automatically

This repository includes `.github/workflows/android.yml`. Push the project to a GitHub repository on branch `main` or `master`, or run **Actions → Build Android APK and Google Play AAB → Run workflow**. The workflow imports the project and attempts to export a debug APK; generated files appear under the run's **Artifacts** section. Builds run in GitHub's hosted environment, not on your phone.

### Enable signed Google Play AAB builds

A signed AAB requires your own upload/release keystore. **Never commit the keystore or its password to the repository.** In GitHub, open **Settings → Secrets and variables → Actions → New repository secret** and add:

- `BTD_RELEASE_KEYSTORE_BASE64` — the keystore file encoded as Base64.
- `BTD_RELEASE_KEYSTORE_PASSWORD` — the keystore password.
- `BTD_RELEASE_KEY_ALIAS` — the key alias inside the keystore.

The workflow expects the keystore password and key password to be the same, which is a common `keytool` setup. Keep a secure backup of the keystore and password; losing them can complicate future app updates. If these secrets are absent, the workflow exports/uploads the debug APK and clearly skips AAB signing.

On a computer with Java installed, create a keystore with an alias and matching store/key password, for example:

```bash
keytool -genkeypair -v -keystore beyond-the-door-upload.jks -alias beyondthedoor -keyalg RSA -keysize 2048 -validity 10000
```

Then encode the file as Base64 (Linux):

```bash
base64 -w 0 beyond-the-door-upload.jks
```

On macOS, use `base64 < beyond-the-door-upload.jks | tr -d '\n'`. Add the resulting text as `BTD_RELEASE_KEYSTORE_BASE64`; enter the chosen alias and password as the other two secrets. Store the original `.jks` and password somewhere safe.

### Important limits

- This workflow is automation configuration, not proof that a build has already succeeded. A real GitHub Actions run must finish successfully before an APK/AAB can be claimed as built.
- The project has not been runtime-tested on an Android device by this packaging step.
- The preset currently targets Android API 34. Verify Google Play's current target-API policy before publishing; a successful export alone does not guarantee store acceptance.
- The `builds/` output directory and keystore files are excluded from Git to avoid committing binaries or secrets.

---

## Google AdMob Integration (Top Banner + Rewarded Hint & Skip Stage)

- **Configured IDs in `scripts/autoload/monetization_bridge.gd`:**
  - Release builds automatically use your real AdMob App ID, Top Banner Unit ID, and Rewarded Unit ID.
  - Debug builds automatically use official Google AdMob Test IDs to keep your account safe during testing.
  - Works 100% offline: when offline, the Top Banner hides automatically and Hint/Skip buttons fail gracefully without blocking gameplay.
- **Activating Native Android Ads:** Install the **Poing Studios Godot AdMob Plugin** for Godot 4.3 (AssetLib → "AdMob by Poing Studios"), enable Gradle Build in Android export settings, and paste `android/admob_manifest_snippet.xml` inside `<application>` in `android/build/AndroidManifest.xml`.
