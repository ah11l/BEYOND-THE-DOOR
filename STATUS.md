# BEYOND THE DOOR (ما وراء الباب) — Project Status (V16 Complete Overhaul)

**Studio:** majnon.studio (مجنون استديو)  
**Engine:** Godot 4.5.2 (`GL Compatibility` / GDScript)  
**Repository:** `ah11l/BEYOND-THE-DOOR`

## Implemented & Statically Verified in Source (V16)
- **Visual Redesign (Reference-Aligned, Restrained Cosmic Style):**
  - `low_poly_mesh_library.gd` & `stage_builder.gd`: Restrained deep-navy, muted indigo, dark sage-moss grass rims, subdued turquoise crystals, layered canopy & pine trees (with layer-32 camera occlusion fade), dark-timber cabins, and luminous waterfalls across all 6 worlds while preserving the approved hooded protagonist silhouette.
- **Intelligent Dynamic Camera (`iso_camera.gd`):**
  - Initial stage overview glide framing spawn & layout, smooth velocity lookahead near corners/edges, elevation/span zoom adaptation, layer-32 prop occlusion handling, and 3D cinematic shot support.
- **Contextual Circular Interaction UI & Parchment Notes (`game_hud.gd`):**
  - Replaced permanent bottom text bar with a compact 76×76 circular icon button (Hand, Book, Door, Search) projected safely near the active target, plus an aged Parchment Scroll reading panel («ملاحظة قديمة» / "Ancient Note") for Clue Stones.
- **Merged Emotional Story, 3D Opening Cinematic & 6 World Bosses (`translations_data.gd`, `guardian_boss.gd`, `stage_builder.gd`):**
  - Updated all 6 worlds (الجزر المنسية، غابة الهمس، مدينة الساعات المتوقفة، الهاوية الصامتة، بحر المرايا، ما وراء الباب), added skippable 3D Opening Cinematic on Stage 1, and added Guardian/Echo Boss Sentinels on Stages 20, 40, 60, 80, 100, and 120 (812 synced AR/EN keys).
- **Difficulty Modes & Character Wardrobe (`save_manager.gd`, `game_state.gd`, `main_menu.gd`):**
  - 3 difficulty modes (Story / Normal / Master), 5 crystal-unlocked character cloak/lantern styles (`0/10/25/45/60 ◆`), and toggleable subtle ground-rune Puzzle Guides.
- **Cumulative V9/V10 Fixes Included:**
  - Hidden room-state pickups disable `Area3D` monitoring/collision; Echo Ghost syncs `world_side` & `room_state` with luminous path trail; overlapping `GravityZone`s tracked by `zone_id`; `skip_stage` works up to Stage 120; `majnon_studio_logo.png` converted to genuine PNG; CI `.github/workflows/main.yml` builds Debug APK & Signed Google Play AAB.

## Pending Live Device Verification
- Real Android device testing of the compiled V16 Debug APK (dynamic camera feel, contextual circular button placement across aspect ratios, 3D opening cinematic, boss encounters, and wardrobe switching).
- Live AdMob ad testing via Google Play Console Internal Testing using the signed AAB.
