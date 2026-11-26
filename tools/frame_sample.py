#!/usr/bin/env python3
"""Draw the order in which a sampling frame is considered. The scout does not choose it.

  tools/frame_sample.py --repo . --frame NAME --n 20 --seed 7

queue/frames/NAME.json lists every item of a frame (a library index, a journal volume list,
a search result enumerated in full): {"name", "description", "source", "enumerated_utc",
"items": [...]}. This writes queue/frames/NAME.sample.json with a seeded random order of
the first n items to consider. Candidates are then considered in that order, none skipped
(checks/funnel.py), so the funnel's denominator is the frame, not the scout's taste.
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


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    ap.add_argument("--frame", required=True)
    ap.add_argument("--n", required=True, type=int)
    ap.add_argument("--seed", required=True, type=int)
    a = ap.parse_args(argv)
    fdir = a.repo / "queue" / "frames"
    frame = json.loads((fdir / f"{a.frame}.json").read_text(encoding="utf-8"))
    out = fdir / f"{a.frame}.sample.json"
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
