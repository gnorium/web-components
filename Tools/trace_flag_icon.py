#!/usr/bin/env python3
"""Traces the circular United States flag icon (UnitedStatesFlagView) to one SVG path.

The icon is cut from the flag the way the user specified (2026-10-18): the
circle is centered on the canton's bottom-right corner and is the largest that
stays inside the flag, so its radius is the distance from that corner to the
nearest flag edge (the bottom: 3900 - 2100 = 1800). It is monochrome: the red
stripes and the blue canton are one ink, the white stripes and the 50 stars
are knocked out of it. No clip path and no mask: the result is the exact
outline of the ink, with the circle's arcs kept as true SVG arcs.

Geometry is the standard flag (Executive Order 10834 proportions) as in the
reference SVG, in its 7410 x 3900 units; the 1024 x 1024 icon box is the
circle's bounding square.

Usage (needs shapely): trace_flag_icon.py          prints the path data (SVG d)
                       trace_flag_icon.py --swift  prints the typed path DSL for
                                                   UnitedStatesFlagIconView
"""
import math
import sys

from shapely.geometry import Polygon, box, Point
from shapely.ops import unary_union

# The flag, in its own units.
FLAG_W, FLAG_H = 7410, 3900
STRIPE = 300                   # 13 stripes of 300: 7 red, 6 white
CANTON_W, CANTON_H = 2964, 2100
STAR_R = 120                   # outer radius of a star
STAR_CENTER = (247, 210)       # first star, relative to the canton origin
COLUMNS = [                    # (x offset, stars, y offset), as the reference
    (0, 5, 0), (247, 4, 210), (494, 5, 0), (741, 4, 210),
    (988, 5, 0), (1235, 4, 210), (1482, 5, 0), (1729, 4, 210),
    (1976, 5, 0), (2223, 4, 210), (2470, 5, 0),
]
STAR_STEP = 420

# The icon: centered on the canton's bottom-right corner, largest circle that fits.
CX, CY = CANTON_W, CANTON_H
R = min(CX, CY, FLAG_W - CX, FLAG_H - CY)      # 1800
SIZE = 1024
SCALE = SIZE / (2 * R)


def star(cx, cy, r=STAR_R):
    """A five-pointed star: outer radius r, inner radius of the {5/2} pentagram."""
    inner = r * math.cos(math.radians(72)) / math.cos(math.radians(36))
    pts = []
    for k in range(10):
        radius = r if k % 2 == 0 else inner
        angle = math.radians(-90 + 36 * k)
        pts.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return Polygon(pts)


def ink():
    """The ink: red stripes and the canton, less the white stripes and stars."""
    flag = box(0, 0, FLAG_W, FLAG_H)
    white = unary_union([box(0, y, FLAG_W, y + STRIPE) for y in range(STRIPE, FLAG_H, 2 * STRIPE)])
    canton = box(0, 0, CANTON_W, CANTON_H)
    stars = unary_union([
        star(STAR_CENTER[0] + ox, STAR_CENTER[1] + oy + i * STAR_STEP)
        for ox, count, oy in COLUMNS for i in range(count)
    ])
    region = flag.difference(white.difference(canton)).difference(stars.intersection(canton))
    circle = Point(CX, CY).buffer(R, quad_segs=2048)
    return region.intersection(circle)


def to_icon(x, y):
    return ((x - (CX - R)) * SCALE, (y - (CY - R)) * SCALE)


def fmt(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def ring_to_path(coords):
    """One ring as path data; runs of vertices on the circle become true arcs."""
    pts = [to_icon(x, y) for x, y in coords[:-1]]
    c = SIZE / 2
    r = SIZE / 2
    tol = 0.02

    def on_circle(p):
        return abs(math.hypot(p[0] - c, p[1] - c) - r) < tol

    n = len(pts)
    flags = [on_circle(p) for p in pts]
    # An edge is an arc when both its ends are on the circle and it is short
    # (a chord of the 2048-gon); a long straight edge between two on-circle
    # points (a stripe's end) is a line. Polygon edges of the circle are tiny.
    chord_max = 2 * math.pi * r / 2048 * 1.5

    def arc_edge(i):
        j = (i + 1) % n
        if not (flags[i] and flags[j]):
            return False
        return math.dist(pts[i], pts[j]) <= chord_max

    # Start at a vertex that begins a non-arc edge, or at 0 for a pure circle.
    start = next((i for i in range(n) if not arc_edge(i - 1)), 0)
    out = [f"M{fmt(pts[start][0])} {fmt(pts[start][1])}"]
    i = start
    done = 0
    while done < n:
        j = (i + 1) % n
        if arc_edge(i):
            k = j
            steps = 1
            while arc_edge(k) and done + steps < n:
                k = (k + 1) % n
                steps += 1
            a0 = math.atan2(pts[i][1] - c, pts[i][0] - c)
            a1 = math.atan2(pts[k][1] - c, pts[k][0] - c)
            # Sweep in the direction the ring travels (y down: increasing angle is clockwise).
            mid = pts[(i + steps // 2) % n]
            am = math.atan2(mid[1] - c, mid[0] - c)
            d1 = (am - a0) % (2 * math.pi)
            d2 = (a1 - a0) % (2 * math.pi)
            clockwise = d1 <= d2 if d2 != 0 else True
            span = d2 if clockwise else (2 * math.pi - d2)
            if d2 == 0:
                span = 2 * math.pi
            large = 1 if span > math.pi else 0
            sweep = 1 if clockwise else 0
            if span >= 2 * math.pi - 1e-9:  # a full circle needs two arcs
                opp = (c + (c - pts[i][0]), c + (c - pts[i][1]))
                out.append(f"A{fmt(r)} {fmt(r)} 0 1 {sweep} {fmt(opp[0])} {fmt(opp[1])}")
                out.append(f"A{fmt(r)} {fmt(r)} 0 1 {sweep} {fmt(pts[i][0])} {fmt(pts[i][1])}")
            else:
                out.append(f"A{fmt(r)} {fmt(r)} 0 {large} {sweep} {fmt(pts[k][0])} {fmt(pts[k][1])}")
            i = k
            done += steps
        else:
            out.append(f"L{fmt(pts[j][0])} {fmt(pts[j][1])}")
            i = j
            done += 1
    out.append("Z")
    return "".join(out)


def path_data():
    geom = ink()
    polys = list(geom.geoms) if geom.geom_type == "MultiPolygon" else [geom]
    parts = []
    for poly in polys:
        poly = poly.simplify(0)  # drop nothing, normalizes collinear runs lightly
        parts.append(ring_to_path(list(poly.exterior.coords)))
        for hole in poly.interiors:
            parts.append(ring_to_path(list(hole.coords)))
    return "".join(parts)


def swift_commands(d):
    """The path data as typed DSL commands (M, L, A, Z), one per line."""
    import re
    out = []
    for cmd, args in re.findall(r"([MLAZ])([^MLAZ]*)", d):
        nums = [n for n in re.split(r"[ ,]+", args.strip()) if n]
        if cmd == "Z":
            out.append("Z()")
        elif cmd == "A":
            rx, ry, rot, large, sweep, x, y = nums
            out.append(f"A({rx}, {ry}, {rot}, {'true' if large == '1' else 'false'}, "
                       f"{'true' if sweep == '1' else 'false'}, {x}, {y})")
        else:
            out.append(f"{cmd}({', '.join(nums)})")
    return out


if __name__ == "__main__":
    d = path_data()
    if "--swift" in sys.argv:
        lines = swift_commands(d)
        print("    static let commands: [SVG.Path.Definition.Command] = [")
        for i in range(0, len(lines), 4):
            print("      " + ", ".join(lines[i:i + 4]) + ",")
        print("    ]")
    else:
        print(d)
        print(f"# {len(d)} characters, circle r={R} centered ({CX}, {CY}) in flag units, "
              f"scale {SCALE:.5f}", file=sys.stderr)
