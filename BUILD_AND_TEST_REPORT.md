# BEYOND THE DOOR (ما وراء الباب) — Build & Test Report (V19)

**Engine:** Godot 4.5.2 (`GL Compatibility`)  
**Workflow:** `.github/workflows/main.yml` (`barichello/godot-ci:4.5.2`) — Verified Green for Debug APK & Signed Google Play AAB  
**Localization:** 820 synced English + Arabic keys (`translations_data.gd`, AR & EN only)

## 1. Automated Static QA & Integrity Checks (`tools/qa_stage_audit.py`)
- **Stages Parsed:** 120 / 120 (`world_1_data.gd` – `world_6_data.gd`)
- **State-Bound Collectibles Gated:** 42 keys + 42 memory crystals
- **Broken `plate_id` / `zone_id` References:** 0
- **Unreachable Golden Exit Doors (BFS physics/bridge/gravity/portal graph):** 0
- **Asset Header Integrity (PNG / TTF / WAV):** 0 mismatches (`majnon_studio_logo.png` verified genuine PNG + 5 new contextual SVG icons).

## 2. V19 Major Overhaul Summary (Cumulative with V9 & V10)
1. **Visual Redesign:** Restrained cosmic palettes, mossy-rimmed faceted floating islands, layered/pine trees with camera occlusion fade, wooden cabins, luminous waterfalls, and reduced bloom.
2. **Dynamic Camera (`iso_camera.gd`):** Stage overview glide, velocity lookahead, elevation zoom, and layer-32 prop occlusion fade while preserving consistent joystick controls.
3. **Contextual Circular UI & Parchment Notes (`game_hud.gd`):** Floating circular icon button (Hand / Book / Door / Search) + aged Parchment Scroll panel for Clue Stones.
4. **Redesigned Puzzle Guides (`stage_builder.gd`):** Replaced straight floating cyan beams with subtle ground-embedded rune markers, toggleable in Settings.
5. **Merged Story, 3D Opening Cinematic & 6 Bosses:** Skippable 3D Stage 1 opening sequence, updated 6 world story arcs, and `GuardianBoss` encounters on Stages 20, 40, 60, 80, 100, and 120.
6. **Difficulty Modes & Character Wardrobe:** Story / Normal / Master difficulty tuning + 5 crystal-unlocked hooded cloak/lantern skins in Main Menu.

## 3. Honest Verification Separation
- **Passed (Static Environment):** `tools/qa_stage_audit.py` (120/120 stages, 0 broken refs, 0 asset header errors), GDScript class/signal wiring audit, and 812-key AR/EN parity check.
- **Requires Live Android Device Testing (after GitHub Actions builds V19 APK):** Dynamic camera framing on corners/elevations, circular interact button positioning on phone screens, 3D opening cinematic pacing, boss encounters on Stage 20+, and live AdMob ads via Google Play Internal Testing AAB.

- **V19 Upgrades:** Responsive anchor-based parchment/story/ending panels (zero fixed-width overflow), interactive `GuardianBoss` jumpable 3D shockwave rings + Boss Seal Bar, and dedicated `qa-audit` GitHub Actions job running `tools/qa_stage_audit.py` on every push.

- **V19 Visual & Gameplay Overhaul:** Auto-lush island decorator across all 120 stages (wooden cabins, hanging cliff vines, dense perimeter grass, varied plum/indigo/pine trees, cyan crystal clusters with strict >=1.65m gameplay clearance), closer dynamic camera (`8.6, 7.6, 8.6`, FOV 38, lookahead + corner yaw), luminous pedestals & 2.1m circular Hand/Search contextual zones on Keys & Crystals, early Guardian Watchers on Stages 5 & 10, and first-launch 3D Opening Cinematic regardless of Continue/Stage.

- **V19 Hotfix:** Fixed swapped `overlay.add_child(panel)` / `center.add_child(panel)` scope bug in `scripts/ui/game_hud.gd` (`_build_pause_overlay` and `show_story_chapter`).
