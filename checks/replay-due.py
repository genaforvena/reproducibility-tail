#!/usr/bin/env python3
"""Detector for gate G5: every reproduced result has a recent clean replay that agreed.

Exit 0 GREEN, 2 RED (one line per owed or changed result), 3 a failed observation.
Read-only: it never runs a recipe. `rerun` runs `tools/replay.py --id ID` for what this lists.

A result is owed a replay when its computed verdict is `reproduced` and its newest entry
of kind `clean` in result.json `replayed` is missing or older than MAX_AGE_DAYS. A result
is CHANGED when that newest clean entry did not agree with the record: that needs
diagnosis, not another replay, and stays RED until an entry that agrees follows it.
"""
from __future__ import annotations

import argparse
import datetime
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tools"))
from build_ledger import judge  # noqa: E402

MAX_AGE_DAYS = 7


def utc(text: str) -> datetime.datetime:
    return datetime.datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)


def findings(repo: Path, now: datetime.datetime, max_age_days: float = MAX_AGE_DAYS) -> list[str]:
    owed = []
    for f in sorted((repo / "reports").glob("*/result.json")):
        r = json.loads(f.read_text(encoding="utf-8"))
        if judge(r.get("claim", {}).get("values", [])) != "reproduced":
            continue
        rid = f.parent.name
        clean = [e for e in r.get("replayed", []) if e.get("kind") == "clean"]
        if not clean:
            owed.append(f"{rid}: never replayed clean")
            continue
        newest = max(clean, key=lambda e: e["utc"])
        if not newest.get("ok"):
            owed.append(f"{rid}: CHANGED at the clean replay of {newest['utc']}")
        elif now - utc(newest["utc"]) > datetime.timedelta(days=max_age_days):
            owed.append(f"{rid}: last clean replay {newest['utc']} is older than {max_age_days} days")
    return owed


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    ap.add_argument("--max-age-days", type=float, default=MAX_AGE_DAYS)
    a = ap.parse_args(argv)
    try:
        owed = findings(a.repo, datetime.datetime.now(datetime.timezone.utc), a.max_age_days)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"cannot read replay records: {exc}", file=sys.stderr)
        return 3
    print("\n".join(owed) if owed else "every reproduced result has a recent clean replay that agreed")
    return 2 if owed else 0


if __name__ == "__main__":
    sys.exit(main())
