#!/usr/bin/env python3
"""Clean replay of one reproduced result (gate G5).

  tools/replay.py --repo . --id PAPER_ID

Wipes the paper's scratch directory, runs reports/ID/recipe.sh from nothing, reads the
`VALUE <name> <number>` lines the recipe prints, compares them with the recorded values
and appends a `kind: clean` entry to result.json `replayed`. The ledger is rebuilt; the
caller commits. Exit 0 the replay agreed, 2 it did not, 3 it could not be run.

Recipe contract: for every claimed value the recipe prints one line `VALUE <name> <number>`.
A value that is stochastic by design may carry `replay_abs` in result.json; the default is
exact agreement to 1e-6 relative.
"""
from __future__ import annotations

import argparse
import copy
import datetime
import fcntl
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_ledger  # noqa: E402

SCRATCH = Path("/mnt/mishe-scratch/reproducibility-tail")
VALUE_LINE = re.compile(r"^VALUE (.+?) (\S+)\s*$", re.M)
NUMBER = re.compile(r"-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?")
LOG_TAIL = 400_000


def parse_values(text: str, recorded: list = ()) -> dict:
    """VALUE lines of the recipe: a float for a numeric claim, the raw token for an exact-string claim."""
    exact = {v["name"] for v in recorded if build_ledger.exact_string_claim(v)}
    out = {}
    for m in VALUE_LINE.finditer(text):
        name, token = m.group(1), m.group(2)
        if name in exact:
            out[name] = token
        elif NUMBER.fullmatch(token):
            out[name] = float(token)
    return out


def agrees(recorded: list, new: dict) -> tuple[bool, str]:
    """Same verdict as the registered tolerance gives, and the same number as the record."""
    missing = [v["name"] for v in recorded if v["name"] not in new]
    if missing:
        return False, f"recipe printed no VALUE line for {missing}"
    probe = copy.deepcopy(recorded)
    for v in probe:
        v["ours"] = new[v["name"]]
    if build_ledger.judge(probe) != "reproduced":
        return False, "the replayed value is outside the registered tolerance"
    for v, p in zip(recorded, probe):
        if build_ledger.exact_string_claim(v):
            if p["ours"] != v["ours"]:
                return False, f"{v['name']}: replayed {p['ours']!r} differs from recorded {v['ours']!r}"
            continue
        slack = v.get("replay_abs", max(1e-9, 1e-6 * abs(v["ours"])))
        if abs(p["ours"] - v["ours"]) > slack:
            return False, f"{v['name']}: replayed {p['ours']} differs from recorded {v['ours']} by more than {slack}"
    return True, "agrees with the record"


def run_recipe(recipe: Path, repo: Path, timeout: float) -> tuple[int, str]:
    proc = subprocess.Popen(["bash", str(recipe)], cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, errors="replace", start_new_session=True)
    try:
        out, _ = proc.communicate(timeout=timeout)
        return proc.returncode, out
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        out, _ = proc.communicate()
        return 124, out + f"\nreplay: timed out after {timeout:.0f} s\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    ap.add_argument("--id", required=True)
    ap.add_argument("--timeout", type=float, default=1500.0)
    ap.add_argument("--scratch", type=Path, default=SCRATCH)
    ap.add_argument("--min-free-gib", type=float, default=60.0)
    a = ap.parse_args(argv)
    if not re.fullmatch(r"[A-Za-z0-9._-]+", a.id):
        print("bad paper id", file=sys.stderr)
        return 3
    repo, rdir = a.repo.resolve(), a.repo.resolve() / "reports" / a.id
    result_path, recipe = rdir / "result.json", rdir / "recipe.sh"
    if not result_path.is_file() or not recipe.is_file():
        print(f"{a.id}: needs result.json and recipe.sh", file=sys.stderr)
        return 3
    result = json.loads(result_path.read_text(encoding="utf-8"))
    values = result["claim"]["values"]
    if build_ledger.judge(values) != "reproduced":
        print(f"{a.id}: only a reproduced result is replayed", file=sys.stderr)
        return 3
    lock_dir = repo / ".mishe-tauftauf"
    lock = open((lock_dir if lock_dir.is_dir() else repo) / "replay.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        print("another replay is running", file=sys.stderr)
        return 3
    free = shutil.disk_usage(a.scratch.parent if not a.scratch.exists() else a.scratch).free / 2**30
    if free < a.min_free_gib:
        print(f"refusing: {free:.1f} GiB free under the {a.min_free_gib:.0f} GiB floor", file=sys.stderr)
        return 3
    work = (a.scratch / a.id).resolve()
    if work.parent != a.scratch.resolve():
        print("scratch path escapes the scratch root", file=sys.stderr)
        return 3
    shutil.rmtree(work, ignore_errors=True)        # clean means from nothing
    started = time.time()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    code, out = run_recipe(recipe, repo, a.timeout)
    shutil.rmtree(work, ignore_errors=True)        # the cap is for what is in flight
    new = parse_values(out, values)
    stamp_name = stamp.replace(':', '')
    if code != 0 and not new:
        # A recipe that exits before printing any VALUE line (fetch, unpack or build failed) did not
        # produce a number, so there is nothing to compare: it could not be run (exit 3), not DIFFERS.
        log_rel = f"reports/{a.id}/evidence/replay-not-run-{stamp_name}.log"
        (repo / log_rel).parent.mkdir(parents=True, exist_ok=True)
        (repo / log_rel).write_text(out[-LOG_TAIL:], encoding="utf-8")
        # Visible in result.json so replay-due can flag it; G5 and the recorded values are untouched.
        result.setdefault("replayed", []).append(
            {"utc": stamp, "kind": "not-run", "exit": code, "log": log_rel,
             "why": f"recipe exited {code} before printing any value", "seconds": round(time.time() - started)})
        result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        (repo / "ledger.md").write_text(build_ledger.build(repo), encoding="utf-8")
        print(f"{a.id}: NOT RUN: recipe exited {code} before printing any value; not-run entry written; "
              f"log {log_rel}", file=sys.stderr)
        return 3
    ok, why = agrees(values, new) if code == 0 else (False, f"recipe exited {code} after printing values")
    log_rel = f"reports/{a.id}/evidence/replay-{stamp_name}.log"
    (repo / log_rel).parent.mkdir(parents=True, exist_ok=True)
    (repo / log_rel).write_text(out[-LOG_TAIL:], encoding="utf-8")
    result.setdefault("replayed", []).append(
        {"utc": stamp, "kind": "clean", "values": new, "ok": ok, "why": why, "log": log_rel,
         "seconds": round(time.time() - started)})
    result.setdefault("gates", {})["G5"] = "pass" if ok else "fail"
    result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (repo / "ledger.md").write_text(build_ledger.build(repo), encoding="utf-8")
    print(f"{a.id}: {'AGREES' if ok else 'DIFFERS'}: {why}; log {log_rel}")
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
