#!/usr/bin/env python3
"""Detector: every report obeys the reproduction gates (docs/method.md).

Exit 0 GREEN, 2 RED (prints one line per violation), 3 a failed observation.
A report without result.json is a violation: the ledger and the gates read only the
machine record, so prose-only reports are unfinished.

Checked mechanically, per reports/ID/result.json:
  G0  the claim (queue/ID.json, or queue/withdrawn/ID.json once withdrawn) is byte-identical to the one
      at the commit the run recorded (no moving goalposts); a withdrawn claim is moved, never deleted
  G1  basis follows how the authors' artifact behaved: original needs it to have run as documented
      (succeeded), patched needs partial or failed, reimplemented needs failed or not-possible;
      the attempt carries a reason and, unless not-possible, an existing log
  G2  a reimplemented or patched reproduced result needs gates.G2 == pass, except a patched one whose
      `patch` is build-only: the authors' source files byte-identical before and after (re-derived here
      from the two manifests in the report, archive hash equal to the queue entry's)
  G3  recipe exists; a reproduced result needs a replay (gates.G3 == pass)
  G4  the stated verdict equals the verdict computed from the recorded values
  G0b an artifact-reference claim keeps the shipped reference output in the report, hash-checked
  G6  not-reproduced needs a confirmed second pass (gates.G6 == pass) and a cause
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "tools"))
from build_ledger import CAUSES, FIELDS, ORIGINAL_OUTCOMES, STACKS, judge  # noqa: E402
import verify_sources  # noqa: E402

BASES = ("original", "patched", "reimplemented")


def last_commit(repo: Path, rel: str) -> str:
    done = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H", "--", rel],
                          capture_output=True, text=True, timeout=30)
    return done.stdout.strip() if done.returncode == 0 else ""


def build_only_problems(repo: Path, rid: str, r: dict, qrel) -> list[str]:
    """Problems with a `patch` record that claims kind build-only; [] when it holds (or claims nothing).

    The claim is re-derived, never trusted: the two manifests kept in the report are compared again,
    the recorded lists must equal the recomputed ones, no authors' source file may be modified or
    removed, each added file must be a declared generated file with a reason, and the archive hash must
    be the one registered in the queue entry.
    """
    p = r.get("patch")
    if not isinstance(p, dict) or p.get("kind") != "build-only":
        return []
    bad: list[str] = []
    if r.get("basis") != "patched":
        bad.append(f"{rid}: a build-only patch belongs to basis patched, not {r.get('basis')!r}")
    pre, post = repo / "reports" / rid / "evidence" / "manifest.pre", repo / "reports" / rid / "evidence" / "manifest.post"
    if not (pre.is_file() and post.is_file()):
        return bad + [f"{rid}: build-only patch needs reports/{rid}/evidence/manifest.pre and manifest.post"]
    diff = verify_sources.compare(verify_sources.parse(pre.read_text(encoding="utf-8")),
                                  verify_sources.parse(post.read_text(encoding="utf-8")))
    for key in ("compared", "modified", "removed", "added"):
        if p.get(key) != diff[key]:
            bad.append(f"{rid}: patch.{key} does not match the manifests ({p.get(key)!r} recorded, {diff[key]!r} recomputed)")
    if verify_sources.classify(diff, p.get("generated") or []) != "build-only":
        bad.append(f"{rid}: the manifests do not show a build-only patch (modified {diff['modified'][:3]}, removed "
                   f"{diff['removed'][:3]}, added without a declared reason {diff['added'][:3]}, compared {diff['compared']})")
    want = ""
    if qrel is not None:
        want = verify_sources.archive_sha(json.loads((repo / qrel).read_text(encoding="utf-8")))
    if not want or p.get("archive_sha256") != want:
        bad.append(f"{rid}: patch.archive_sha256 must equal the sha256 registered in the queue entry's code.archive")
    return bad


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
        claim = r.get("claim", {})
        if claim.get("source", "paper-text") not in ("paper-text", "artifact-reference"):
            bad.append(f"{rid}: claim.source must be paper-text or artifact-reference")
        if claim.get("source") == "artifact-reference":
            ref = claim.get("reference") or {}
            fpath = repo / str(ref.get("file", "-"))
            if not fpath.is_file():
                bad.append(f"{rid}: artifact-reference claim needs claim.reference.file (the shipped reference output, kept in the report)")
            elif hashlib.sha256(fpath.read_bytes()).hexdigest() != ref.get("sha256"):
                bad.append(f"{rid}: claim.reference.sha256 does not match {ref.get('file')}")
            elif not str(ref.get("archive", "")).strip():
                bad.append(f"{rid}: claim.reference.archive (where the reference was shipped, with its own hash) is missing")
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
        o = r.get("original_attempt") or {}
        if verdict != "blocked" or basis:
            if r.get("stack_class") not in STACKS:
                bad.append(f"{rid}: stack_class must be one of {STACKS} (the paper's own stack)")
            if r.get("field_class") not in FIELDS:
                bad.append(f"{rid}: field_class must be one of {FIELDS}")
        if basis in BASES:
            if o.get("outcome") not in ORIGINAL_OUTCOMES or not o.get("tried") or not str(o.get("reason", "")).strip():
                bad.append(f"{rid}: G1 needs original_attempt with tried, outcome in {list(ORIGINAL_OUTCOMES)} and a reason")
            elif o["outcome"] != "not-possible" and not (repo / str(o.get("log", "-"))).is_file():
                bad.append(f"{rid}: G1 the original attempt has no log file")
            else:
                allowed = {"original": ("succeeded",), "patched": ("partial", "failed"),
                           "reimplemented": ("failed", "not-possible")}[basis]
                if o["outcome"] not in allowed:
                    bad.append(f"{rid}: G1 basis {basis} does not fit original attempt outcome {o['outcome']!r} "
                               f"(original needs succeeded; patched partial or failed; reimplemented failed or not-possible)")
        patch_bad = build_only_problems(repo, rid, r, qrel)
        bad.extend(patch_bad)
        build_only = isinstance(r.get("patch"), dict) and r["patch"].get("kind") == "build-only" and not patch_bad
        if basis in ("patched", "reimplemented") and verdict == "reproduced" and gates.get("G2") != "pass" and not build_only:
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
