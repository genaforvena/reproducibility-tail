#!/usr/bin/env python3
"""Draw the order in which a sampling frame is considered. The scout does not choose it.

  tools/frame_sample.py --repo . --frame NAME --n 20 --seed 7

queue/frames/NAME.json lists every item of a frame (a library index, a journal volume list,
a search result enumerated in full): {"name", "description", "source", "enumerated_utc",
"items": [...]}. This writes queue/frames/NAME.sample.json with a seeded random order of
the first n items to consider. Candidates are then considered in that order, none skipped
(checks/funnel.py), so the funnel's denominator is the frame, not the scout's taste. A frame is drawn once; when its
draw is used up, `--extend K` appends K more items (seeded, the earlier order untouched).
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path


def draw(items: list, n: int, seed: int) -> list[int]:
    """1-based item indices in the order they must be considered."""
    return random.Random(seed).sample(range(1, len(items) + 1), min(n, len(items)))


def extend(items: list, order: list[int], seed: int, k: int) -> list[int]:
    """The next k indices: a seeded draw from what is left. The existing order never changes, so an
    extension raises the count without letting anyone re-pick the items already drawn."""
    left = [i for i in range(1, len(items) + 1) if i not in set(order)]
    return random.Random(f"{seed}:{len(order)}").sample(left, min(k, len(left)))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    ap.add_argument("--frame", required=True)
    ap.add_argument("--n", type=int)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--extend", type=int, help="append this many more items to an existing draw")
    a = ap.parse_args(argv)
    if (a.extend is None) == (a.n is None or a.seed is None):
        print("give --n and --seed for the first draw, or --extend K for a later one", file=sys.stderr)
        return 3
    fdir = a.repo / "queue" / "frames"
    frame = json.loads((fdir / f"{a.frame}.json").read_text(encoding="utf-8"))
    out = fdir / f"{a.frame}.sample.json"
    if a.extend is not None:
        if not out.exists():
            print("nothing to extend: draw first", file=sys.stderr)
            return 3
        cur = json.loads(out.read_text(encoding="utf-8"))
        more = extend(frame["items"], cur["order"], cur["seed"], a.extend)
        cur["order"] += more
        cur["n"] = len(cur["order"])
        cur.setdefault("extensions", []).append({"at": cur["n"] - len(more), "k": len(more)})
        out.write_text(json.dumps(cur, indent=1) + "\n", encoding="utf-8")
        print(f"{a.frame}: {len(more)} more drawn, {cur['n']} of {len(frame['items'])}; the earlier order is unchanged")
        return 0
    if out.exists():
        print(f"{out.name} exists: a frame is sampled once, so the draw cannot be redone to taste", file=sys.stderr)
        return 3
    order = draw(frame["items"], a.n, a.seed)
    out.write_text(json.dumps({"frame": a.frame, "seed": a.seed, "n": len(order), "size": len(frame["items"]),
                               "method": "random.Random(seed).sample(range(1, size + 1), n)", "order": order},
                              indent=1) + "\n", encoding="utf-8")
    print(f"{a.frame}: {len(order)} of {len(frame['items'])} items drawn; consider them in this order")
    return 0


if __name__ == "__main__":
    sys.exit(main())
