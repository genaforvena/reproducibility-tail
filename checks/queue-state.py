#!/usr/bin/env python3
"""Queue detector. Exit 0 GREEN, 2 RED, anything else is a failed observation.

  queue-state.py --repo REPO low    RED when fewer than MIN open entries (scout owed)
  queue-state.py --repo REPO owed   RED when an unclaimed entry exists (rerun owed)

An entry is queue/<id>.json. It is open until reports/<id>/result.md exists, and
claimed once reports/<id>/claimed exists. A claim older than STALE_HOURS without a
result no longer counts as claimed, so the entry is owed again.
"""
import argparse
import json
import sys
import time
from pathlib import Path

MIN_OPEN = 5
STALE_HOURS = 6


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("mode", choices=["low", "owed"])
    a = ap.parse_args()
    repo = Path(a.repo)
    q = repo / "queue"
    if not q.is_dir():
        print("queue/ missing", file=sys.stderr)
        return 3
    now = time.time()
    open_ids, unclaimed = [], []
    for f in sorted(q.glob("*.json")):
        try:
            json.loads(f.read_text(encoding="utf-8"))
        except (OSError, ValueError) as e:
            print(f"unreadable entry {f.name}: {e}", file=sys.stderr)
            return 3
        pid = f.stem
        rep = repo / "reports" / pid
        if (rep / "result.md").exists():
            continue
        open_ids.append(pid)
        claimed = rep / "claimed"
        if not claimed.exists() or now - claimed.stat().st_mtime > STALE_HOURS * 3600:
            unclaimed.append(pid)
    if a.mode == "low":
        red = len(open_ids) < MIN_OPEN
        print(f"open={len(open_ids)} min={MIN_OPEN}")
    else:
        red = bool(unclaimed)
        print(f"unclaimed={len(unclaimed)} open={len(open_ids)}")
    return 2 if red else 0


if __name__ == "__main__":
    sys.exit(main())
