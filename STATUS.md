# BEYOND THE DOOR (ما وراء الباب) — Project Status (V24 Complete Overhaul)

**Studio:** majnon.studio (مجنون استديو)  
**Engine:** Godot 4.5.2 (`GL Compatibility` / GDScript)  
**Repository:** `ah11l/BEYOND-THE-DOOR`

## Implemented & Statically Verified in Source (V24)
- **Visual Redesign (Reference-Aligned, Restrained Cosmic Style):**
  - `low_poly_mesh_library.gd` & `stage_builder.gd`: Restrained deep-navy, muted indigo, dark sage-moss grass rims, subdued turquoise crystals, layered canopy & pine trees (with layer-32 camera occlusion fade), dark-timber cabins, and luminous waterfalls across all 6 worlds while preserving the approved hooded protagonist silhouette.
- **Intelligent Dynamic Camera (`iso_camera.gd`):**
  - Initial stage overview glide framing spawn & layout, smooth velocity lookahead near corners/edges, elevation/span zoom adaptation, layer-32 prop occlusion handling, and 3D cinematic shot support.
- **Contextual Circular Interaction UI & Parchment Notes (`game_hud.gd`):**
  - Replaced permanent bottom text bar with a compact 76×76 circular icon button (Hand, Book, Door, Search) projected safely near the active target, plus an aged Parchment Scroll reading panel («ملاحظة قديمة» / "Ancient Note") for Clue Stones.
- **Merged Emotional Story, 3D Opening Cinematic & 6 World Bosses (`translations_data.gd`, `guardian_boss.gd`, `stage_builder.gd`):**
  - Updated all 6 worlds (الجزر المنسية، غابة الهمس، مدينة الساعات المتوقفة، الهاوية الصامتة، بحر المرايا، ما وراء الباب), added skippable 3D Opening Cinematic on Stage 1, and added Guardian/Echo Boss Sentinels on Stages 20, 40, 60, 80, 100, and 120 (838 synced AR/EN keys).
- **Difficulty Modes & Character Wardrobe (`save_manager.gd`, `game_state.gd`, `main_menu.gd`):**
  - 3 difficulty modes (Story / Normal / Master), 5 crystal-unlocked character cloak/lantern styles (`0/10/25/45/60 ◆`), and toggleable subtle ground-rune Puzzle Guides.
- **Cumulative V9/V10 Fixes Included:**
  - Hidden room-state pickups disable `Area3D` monitoring/collision; Echo Ghost syncs `world_side` & `room_state` with luminous path trail; overlapping `GravityZone`s tracked by `zone_id`; `skip_stage` works up to Stage 120; `majnon_studio_logo.png` converted to genuine PNG; CI `.github/workflows/main.yml` builds Debug APK & Signed Google Play AAB.

## Pending Live Device Verification
- Real Android device testing of the compiled V24 Debug APK (dynamic camera feel, contextual circular button placement across aspect ratios, 3D opening cinematic, boss encounters, and wardrobe switching).
- Live AdMob ad testing via Google Play Console Internal Testing using the signed AAB.

- **V24 Upgrades:** Responsive anchor-based parchment/story/ending panels (zero fixed-width overflow), interactive `GuardianBoss` jumpable 3D shockwave rings + Boss Seal Bar, and dedicated `qa-audit` GitHub Actions job running `tools/qa_stage_audit.py` on every push.

- **V24 Visual & Gameplay Overhaul:** Auto-lush island decorator across all 120 stages (wooden cabins, hanging cliff vines, dense perimeter grass, varied plum/indigo/pine trees, cyan crystal clusters with strict >=1.65m gameplay clearance), closer dynamic camera (`8.6, 7.6, 8.6`, FOV 38, lookahead + corner yaw), luminous pedestals & 2.1m circular Hand/Search contextual zones on Keys & Crystals, early Guardian Watchers on Stages 5 & 10, and first-launch 3D Opening Cinematic regardless of Continue/Stage.

- **V24 Hotfix:** Fixed swapped `overlay.add_child(panel)` / `center.add_child(panel)` scope bug in `scripts/ui/game_hud.gd` (`_build_pause_overlay` and `show_story_chapter`).

- **V24 Crash Fix (Blue Screen on Stage Load):** Replaced `Vector3.min()`/`.max()` in `stage_builder.gd` with explicit `minf`/`maxf` bounds, removed `GameState` autoload access from `static func LowPolyMeshLibrary.build_hooded_character()`, and bundled fixed `game_hud.gd`.

- **V24 Painted 3D Textures & Cosmic Skybox:** Added 4 real hand-painted seamless PNG textures (`assets/textures/cosmic_sky.png`, `island_top.png`, `cliff_rock.png`, `wood_planks.png`) mapped via triplanar 2-surface floating islands, textured wooden bridges/cabins/benches/arches/rocks, and 360° `PanoramaSkyMaterial` cosmic nebula skybox in both Gameplay and Main Menu.

- **V24 Parse Fix & CI Script-Error Gate:** Fixed `Array[Vector3]` / `wp: Vector3` explicit typing in `stage_builder.gd`, added stray root `.gd` duplicate detector in `tools/qa_stage_audit.py`, and added strict `SCRIPT ERROR:` / `Parse Error:` CI failure gate in `.github/workflows/main.yml`.

- **V24 Extreme Transformation:** Added 6 animated giant 3D `WorldLandmarks` (ruin archways, spirit forest + fireflies, rotating clockwork gears, abyssal energy columns, floating crystal mirrors, orbiting golden astral rings), 3D `CinematicDirector` (Opening, 6 World Intros, 6 Mid-World Echo/Guardian scenes, Boss Entrances), 6 distinct `GuardianBoss` archetypes, anti-cheese jump physics (`jump=5.6, gravity=20.5`) synced with `6.0s -> 8.0s` Echo duration, and full checkpoint state (`pos + world_side + room_state`) restoration.

- **V24 Audio & Sync Polish:** Synthesized `footstep.wav`, `jump.wav`, and `land.wav`; upgraded `AudioManager` with subtle cosmic SFX bus reverb (`AudioEffectReverb`) and anti-overlap cooldown throttling; synchronized stride footsteps, jump launch, and landing SFX in `player.gd`.
