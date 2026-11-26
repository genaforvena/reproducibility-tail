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
      `patch` is build-only: the authors' source files byte-identical between unpacking and the start of the
      build (three manifests kept in the report and re-derived here; the build commands from recipe.sh with no
      in-place edits; archive hash equal to the queue entry's). What the authors' own build tool rewrites is shown, not judged.
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

    Nothing in the record is trusted. The three manifests kept in the report are compared again: pre
    (after unpacking) and mid (after our patch step, before the build) must be identical, so we changed
    no source file; the recorded lists must equal the recomputed ones; what the authors' own build tool
    rewrote between mid and post is recomputed too (and shown in the ledger, not judged). recipe.sh must
    call the manifest tool three times, the recorded build commands must appear between the second and
    third call, and that region must not contain in-place editing. The archive hash must be the one the
    queue entry registered.
    """
    p = r.get("patch")
    if not isinstance(p, dict) or p.get("kind") != "build-only":
        return []
    bad: list[str] = []
    if r.get("basis") != "patched":
        bad.append(f"{rid}: a build-only patch belongs to basis patched, not {r.get('basis')!r}")
    ev = repo / "reports" / rid / "evidence"
    texts = {}
    for n in ("pre", "mid", "post"):
        f = ev / f"manifest.{n}"
        if not f.is_file():
            return bad + [f"{rid}: build-only patch needs reports/{rid}/evidence/manifest.{n} (three manifests: pre, mid, post)"]
        texts[n] = verify_sources.parse(f.read_text(encoding="utf-8"))
    ours = verify_sources.compare(texts["pre"], texts["mid"])
    if p.get("compared") != ours["compared"] or p.get("ours") != {k: ours[k] for k in ("modified", "removed", "added")}:
        bad.append(f"{rid}: patch.ours does not match the pre and mid manifests (recomputed {ours})")
    if not verify_sources.unchanged(ours):
        bad.append(f"{rid}: our patch step changed source files before the build (modified {ours['modified'][:3]}, removed "
                   f"{ours['removed'][:3]}, added {ours['added'][:3]}, compared {ours['compared']}): not build-only")
    if p.get("tool") != verify_sources.tool_changes(texts["mid"], texts["post"]):
        bad.append(f"{rid}: patch.tool does not match the mid and post manifests")
    commands = p.get("build_commands")
    recipe = repo / "reports" / rid / "recipe.sh"
    region = verify_sources.build_region(recipe.read_text(encoding="utf-8")) if recipe.is_file() else None
    if not isinstance(commands, list) or not commands or not all(isinstance(c, str) and c.strip() for c in commands):
        bad.append(f"{rid}: patch.build_commands must list the build commands exactly as recipe.sh runs them")
    elif region is None:
        bad.append(f"{rid}: recipe.sh must call 'verify_sources.py manifest' exactly three times (pre, mid, post) with the build commands between the second and third")
    else:
        missing = [c for c in commands if verify_sources.norm(c) not in verify_sources.norm(region)]
        if missing:
            bad.append(f"{rid}: build command not found between the second and third manifest calls of recipe.sh: {missing[0][:80]!r}")
        for hit in verify_sources.suspicious(region):
            bad.append(f"{rid}: the build step of recipe.sh edits files in place ({hit}): not build-only")
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
