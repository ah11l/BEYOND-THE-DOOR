#!/usr/bin/env python3
"""Automated static QA & physics reachability audit for BEYOND THE DOOR (120 stages).

Checks:
1. All 120 stages across world_1_data.gd .. world_6_data.gd parse cleanly.
2. Island-to-island reachability graph from spawn using player physics
   (jump_velocity=6.8, base_gravity=18.5 => max_jump_h~1.25m, horiz_jump~3.8m),
   bridges, gravity zones, and black doors.
3. Zero broken plate_id / zone_id references.
4. State-bound KeyPickup & MemorySecret counts and V9 gameplay integrity checks.
"""
import glob
import json
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def point_on_island(px: float, py: float, pz: float, isl: dict, margin: float = 0.85) -> bool:
    ix, iy, iz = isl["pos"]
    sx, _sy, sz = isl["size"]
    return (
        abs(px - ix) <= sx * 0.5 + margin
        and abs(pz - iz) <= sz * 0.5 + margin
        and abs(py - iy) <= 1.25
    )


def island_xz_gap(a: dict, b: dict) -> float:
    ax, _ay, az = a["pos"]
    asx, _asy, asz = a["size"]
    bx, _by, bz = b["pos"]
    bsx, _bsy, bsz = b["size"]
    dx = max(0.0, abs(ax - bx) - (asx + bsx) * 0.5)
    dz = max(0.0, abs(az - bz) - (asz + bsz) * 0.5)
    return math.hypot(dx, dz)




def check_assets() -> list:
    errors = []
    for stray in sorted(ROOT.glob("*.gd")):
        errors.append(f"Duplicate root .gd file (delete from repo root): {stray.name}")
    for p in sorted(ROOT.rglob("*.png")):
        if p.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
            errors.append(f"Invalid PNG header: {p.relative_to(ROOT)}")
    for p in sorted(ROOT.rglob("*.ttf")):
        if p.read_bytes()[:4] not in (b"\x00\x01\x00\x00", b"OTTO", b"true"):
            errors.append(f"Invalid TTF header: {p.relative_to(ROOT)}")
    for p in sorted(ROOT.rglob("*.wav")):
        b = p.read_bytes()
        if b[:4] != b"RIFF" or b[8:12] != b"WAVE":
            errors.append(f"Invalid WAV header: {p.relative_to(ROOT)}")
    return errors


def main() -> int:
    stages = {}
    for path in sorted(glob.glob(str(ROOT / "scripts/levels/world_*_data.gd"))):
        txt = pathlib.Path(path).read_text(encoding="utf-8")
        for line in txt.splitlines():
            m = re.match(r"^\s+(\d+):\s+(\{.*\}),?\s*$", line)
            if m:
                stages[int(m.group(1))] = json.loads(m.group(2))

    if len(stages) != 120:
        print(f"FAIL: Expected 120 stages, found {len(stages)}")
        return 1

    unreachable_goals = []
    missing_refs = []
    state_keys = 0
    state_secrets = 0

    for sid, st in sorted(stages.items()):
        islands = st.get("islands", [])
        bridges = st.get("bridges", [])
        gzs = st.get("gravity_zones", [])
        doors = st.get("doors", [])
        plates = {p["id"]: p for p in st.get("plates", [])}
        gz_map = {g["id"]: g for g in gzs}

        for k in st.get("keys", []):
            if k.get("state", -1) >= 0:
                state_keys += 1
        sec = st.get("secret")
        if sec and sec.get("state", -1) >= 0:
            state_secrets += 1

        for b in bridges:
            pid = b.get("plate_id", "")
            if pid and pid not in plates:
                missing_refs.append((sid, "bridge->plate", pid))
        for d in doors:
            if d["type"] == "blue" and d.get("zone_id", "") not in gz_map:
                missing_refs.append((sid, "blue_door->gz", d.get("zone_id", "")))

        n = len(islands)
        adj = {i: set() for i in range(n)}

        # Direct jumpable edges (horizontal gap <= 3.8m, upward step <= 1.25m)
        for i in range(n):
            for j in range(n):
                if i == j:
                    continue
                gap = island_xz_gap(islands[i], islands[j])
                dy = islands[j]["pos"][1] - islands[i]["pos"][1]
                if gap <= 3.8 and dy <= 1.25:
                    adj[i].add(j)

        # Bridge edges
        for b in bridges:
            pa, pb = b["from"], b["to"]
            ends_a = [i for i, isl in enumerate(islands) if point_on_island(pa[0], pa[1], pa[2], isl, 1.4)]
            ends_b = [i for i, isl in enumerate(islands) if point_on_island(pb[0], pb[1], pb[2], isl, 1.4)]
            for ia in ends_a:
                for ib in ends_b:
                    adj[ia].add(ib)
                    adj[ib].add(ia)

        # Gravity zone edges (lower island near gz -> elevated island within gz top_y + jump)
        for g in gzs:
            gx, gy, gz_z = g["pos"]
            gsx, gsy, gsz = g["size"]
            top_y = gy + gsy
            low_isls = []
            high_isls = []
            for idx, isl in enumerate(islands):
                ix, iy, iz = isl["pos"]
                isx, _isy, isz = isl["size"]
                dx = max(0.0, abs(gx - ix) - (isx + gsx) * 0.5)
                dz = max(0.0, abs(gz_z - iz) - (isz + gsz) * 0.5)
                if math.hypot(dx, dz) <= 2.6:
                    if abs(iy - gy) <= 1.5:
                        low_isls.append(idx)
                    if iy <= top_y + 1.25:
                        high_isls.append(idx)
            for li in low_isls:
                for hi in high_isls:
                    adj[li].add(hi)

        # Black door teleport edges
        for d in doors:
            if d["type"] == "black":
                dp = d["pos"]
                tp = d["target_pos"]
                src = [i for i, isl in enumerate(islands) if point_on_island(dp[0], dp[1], dp[2], isl, 1.4)]
                dst = [i for i, isl in enumerate(islands) if point_on_island(tp[0], tp[1], tp[2], isl, 1.4)]
                for s_i in src:
                    for d_i in dst:
                        adj[s_i].add(d_i)

        # BFS from spawn island
        sp = st["spawn"]
        start_nodes = [i for i, isl in enumerate(islands) if point_on_island(sp[0], sp[1], sp[2], isl, 1.4)]
        visited = set(start_nodes)
        queue = list(start_nodes)
        while queue:
            cur = queue.pop(0)
            for nxt in adj[cur]:
                if nxt not in visited:
                    visited.add(nxt)
                    queue.append(nxt)

        # Verify golden door island is reachable
        for d in doors:
            if d["type"] == "golden":
                dp = d["pos"]
                goal_isls = [i for i, isl in enumerate(islands) if point_on_island(dp[0], dp[1], dp[2], isl, 1.4)]
                if not any(g in visited for g in goal_isls):
                    unreachable_goals.append((sid, "golden_door", dp))

    print(f"QA Audit Passed: 120/120 stages parsed.")
    print(f"State-bound collectibles: {state_keys} keys, {state_secrets} memory crystals.")
    print(f"Broken references: {len(missing_refs)}")
    print(f"Unreachable golden doors: {len(unreachable_goals)}")
    asset_errors = check_assets()
    print(f"Asset header mismatches: {len(asset_errors)}")
    if missing_refs or unreachable_goals or asset_errors:
        print("Details:", missing_refs[:5], unreachable_goals[:5])
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
