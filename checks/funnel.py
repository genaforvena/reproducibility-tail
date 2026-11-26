#!/usr/bin/env python3
"""Detector: the candidate funnel is complete, ordered and evidenced.

Exit 0 GREEN, 2 RED (one line per violation), 3 a failed observation.

Frames (queue/frames/NAME.json) list every item of a sampling frame; the order to consider
them in is drawn by tools/frame_sample.py (NAME.sample.json), not chosen. Each candidate
considered is one line of queue/funnel.jsonl. Checked mechanically:
  - the frame exists, was sampled, and the line's item is the frame's item at that index
  - candidates are considered in the drawn order with none skipped (the considered indices
    are a prefix of the drawn order, each once): selection cannot follow tractability
  - outcome is registered, rejected or unreachable, with a reason from the fixed list
  - registered names an existing queue entry; unreachable cites at least two fallbacks tried
    and the evidence, so "gone" is a checked finding
  - the legacy unstructured queue/rejected.md has been migrated away
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tools"))
from build_ledger import FALLBACKS, OUTCOMES, REJECT_REASONS, UNREACHABLE_REASONS, load_funnel  # noqa: E402


def violations(repo: Path) -> list[str]:
    bad: list[str] = []
    legacy = repo / "queue" / "rejected.md"
    if legacy.exists() and any(x.startswith("- ") for x in legacy.read_text(encoding="utf-8").splitlines()):
        bad.append("queue/rejected.md still holds unstructured rejections: migrate each to queue/funnel.jsonl, then delete it")
    frames, lines = load_funnel(repo)
    seen: dict[str, list[int]] = {}
    for n, x in enumerate(lines, 1):
        tag = f"funnel line {n}"
        fr = frames.get(x.get("frame"))
        if fr is None:
            bad.append(f"{tag}: unknown frame {x.get('frame')!r}")
            continue
        if not fr["order"]:
            bad.append(f"{tag}: frame {fr['name']} has not been sampled (tools/frame_sample.py)")
            continue
        i = x.get("index")
        if not isinstance(i, int) or not 1 <= i <= len(fr["items"]) or fr["items"][i - 1] != x.get("item"):
            bad.append(f"{tag}: index/item do not match frame {fr['name']}")
            continue
        seen.setdefault(fr["name"], []).append(i)
        if x.get("outcome") not in OUTCOMES:
            bad.append(f"{tag}: outcome must be one of {OUTCOMES}")
        elif x["outcome"] == "registered":
            if not (repo / "queue" / f"{x.get('id')}.json").exists():
                bad.append(f"{tag}: registered but queue/{x.get('id')}.json does not exist")
        elif x["outcome"] == "rejected" and x.get("reason") not in REJECT_REASONS:
            bad.append(f"{tag}: rejection reason must be one of {REJECT_REASONS}")
        elif x["outcome"] == "unreachable":
            if x.get("reason") not in UNREACHABLE_REASONS:
                bad.append(f"{tag}: unreachable reason must be one of {UNREACHABLE_REASONS}")
            tried = [c for c in x.get("checked", []) if c in FALLBACKS]
            if len(set(tried)) < 2 or not str(x.get("evidence", "")).strip():
                bad.append(f"{tag}: unreachable needs two fallbacks from {FALLBACKS} and evidence")
        if x["outcome"] != "registered" and not str(x.get("detail", "")).strip():
            bad.append(f"{tag}: detail missing")
    for name, idx in seen.items():
        order = frames[name]["order"]
        if len(set(idx)) != len(idx):
            bad.append(f"frame {name}: an item was considered twice")
        if sorted(idx) != sorted(order[:len(idx)]):
            skipped = [i for i in order[:max(order.index(j) for j in idx if j in order) + 1] if i not in idx] if all(j in order for j in idx) else []
            bad.append(f"frame {name}: candidates must be considered in the drawn order with none skipped"
                       + (f"; skipped indices {skipped}" if skipped else ""))
    return bad


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    a = ap.parse_args(argv)
    try:
        bad = violations(a.repo)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"cannot read the funnel: {exc}", file=sys.stderr)
        return 3
    print("\n".join(bad) if bad else "the funnel is complete, ordered and evidenced")
    return 2 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
