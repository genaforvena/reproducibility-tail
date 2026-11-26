#!/usr/bin/env python3
"""Detector: every report obeys the reproduction gates (docs/method.md).

Exit 0 GREEN, 2 RED (prints one line per violation), 3 a failed observation.
A report without result.json is a violation: the ledger and the gates read only the
machine record, so prose-only reports are unfinished.

Checked mechanically, per reports/ID/result.json:
  G0  the claim (queue/ID.json, or queue/withdrawn/ID.json once withdrawn) is byte-identical to the one
      at the commit the run recorded (no moving goalposts); a withdrawn claim is moved, never deleted
  G1  basis patched/reimplemented needs original_attempt with tried, an outcome
      (failed or not-possible), a reason and, for failed, an existing log
  G2  a reimplemented or patched reproduced result needs gates.G2 == pass
  G3  recipe exists; a reproduced result needs a replay (gates.G3 == pass)
  G4  the stated verdict equals the verdict computed from the recorded values
  G6  not-reproduced needs a confirmed second pass (gates.G6 == pass) and a cause
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tools"))
from build_ledger import CAUSES, judge  # noqa: E402

BASES = ("original", "patched", "reimplemented")


def last_commit(repo: Path, rel: str) -> str:
    done = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H", "--", rel],
                          capture_output=True, text=True, timeout=30)
    return done.stdout.strip() if done.returncode == 0 else ""


def violations(repo: Path) -> list[str]:
    bad: list[str] = []
    reports = repo / "reports"
    for d in sorted(p for p in reports.iterdir() if p.is_dir()):
        rid = d.name
        f = d / "result.json"
        if not f.exists():
            bad.append(f"{rid}: no result.json (prose-only report)")
            continue
        try:
            r = json.loads(f.read_text(encoding="utf-8"))
        except ValueError as exc:
            bad.append(f"{rid}: result.json unreadable: {exc}")
            continue
        values = r.get("claim", {}).get("values")
        if not isinstance(values, list) or not values:
            bad.append(f"{rid}: claim.values missing")
            continue
        for v in values:
            if not isinstance(v.get("paper"), (int, float)) or not isinstance(v.get("tol_abs"), (int, float)):
                bad.append(f"{rid}: every claim value needs numeric paper and tol_abs")
                break
        verdict = judge(values)
        if r.get("verdict") != verdict:
            bad.append(f"{rid}: G4 stated verdict {r.get('verdict')!r}, recorded values give {verdict!r}")
        qrel = next((q for q in (f"queue/{rid}.json", f"queue/withdrawn/{rid}.json") if (repo / q).exists()), None)
        if qrel is None:
            bad.append(f"{rid}: no queue/{rid}.json (a withdrawn claim moves to queue/withdrawn/, it is not deleted)")
        else:
            was = subprocess.run(["git", "-C", str(repo), "show", f"{r.get('queue_commit')}:queue/{rid}.json"],
                                 capture_output=True, text=True, timeout=30)
            if was.returncode != 0:
                bad.append(f"{rid}: G0 queue_commit {str(r.get('queue_commit'))[:8]} does not hold queue/{rid}.json")
            elif was.stdout != (repo / qrel).read_text(encoding="utf-8"):
                bad.append(f"{rid}: G0 the claim in {qrel} differs from the one the run was made against ({str(r.get('queue_commit'))[:8]})")
        basis = r.get("basis")
        gates = r.get("gates", {})
        if verdict != "blocked":
            if basis not in BASES:
                bad.append(f"{rid}: basis must be one of {BASES}")
            if not (repo / str(r.get("recipe", "-"))).is_file():
                bad.append(f"{rid}: G3 recipe missing")
        if basis in ("patched", "reimplemented"):
            o = r.get("original_attempt") or {}
            if not (o.get("tried") and o.get("outcome") in ("failed", "not-possible") and str(o.get("reason", "")).strip()):
                bad.append(f"{rid}: G1 {basis} needs original_attempt (tried, outcome failed|not-possible, reason)")
            elif o["outcome"] == "failed" and not (repo / str(o.get("log", "-"))).is_file():
                bad.append(f"{rid}: G1 failed original attempt has no log file")
            if verdict == "reproduced" and gates.get("G2") != "pass":
                bad.append(f"{rid}: G2 fidelity not passed for a {basis} result")
        if verdict == "reproduced" and gates.get("G3") != "pass":
            bad.append(f"{rid}: G3 replay not passed")
        if verdict in ("not-reproduced", "partial"):
            if gates.get("G6") != "pass":
                bad.append(f"{rid}: G6 second pass not confirmed")
            if r.get("cause") not in CAUSES:
                bad.append(f"{rid}: cause must be one of {CAUSES}")
    return bad


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    a = ap.parse_args(argv)
    try:
        bad = violations(a.repo)
    except (OSError, subprocess.SubprocessError) as exc:
        print(f"cannot check gates: {exc}", file=sys.stderr)
        return 3
    if bad:
        print("\n".join(bad))
        return 2
    print("all reports pass the gates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
