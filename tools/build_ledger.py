#!/usr/bin/env python3
"""Build ledger.md from reports/*/result.json. The ledger is generated, never hand-edited.

  tools/build_ledger.py --repo REPO            write REPO/ledger.md
  tools/build_ledger.py --repo REPO --check    exit 0 if ledger.md matches, 2 if it differs, 3 if unreadable

result.json is the machine record written by `rerun` (schema in docs/method.md). The
verdict and the grade are computed here from the recorded values, not copied from prose.
"""
from __future__ import annotations

import argparse
import collections
import json
import sys
from pathlib import Path

CAUSES = ["dependency-rot", "missing-code", "missing-data", "unstated-parameter",
          "numerical-discrepancy", "nondeterminism", "platform", "other"]
REJECT_REASONS = ["paywalled", "figure-only", "no-numeric-claim", "claim-not-located", "no-method-description",
                  "runtime", "machine-dependent", "restricted-data", "gpu", "other"]
UNREACHABLE_REASONS = ["unreachable-code", "unreachable-data"]
FALLBACKS = ["software-heritage", "wayback", "zenodo", "author-page", "publisher-supplement", "contact"]
OUTCOMES = ["registered", "rejected", "unreachable"]
GRADE_TEXT = {
    "A": "authors' code, run clean",
    "B": "authors' code with build fixes",
    "C": "reimplemented, with an independent cross-check",
    "D": "reimplemented only",
    "X": "not reproduced, cause diagnosed",
    "-": "blocked or not yet run",
}


def judge(values: list) -> str:
    """Compare every recorded value to its pre-registered tolerance. Pure arithmetic."""
    if not values or any(v.get("ours") is None for v in values):
        return "blocked"
    hits = [abs(v["ours"] - v["paper"]) <= v["tol_abs"] for v in values]
    return "reproduced" if all(hits) else ("partial" if any(hits) else "not-reproduced")


def grade(r: dict) -> str:
    verdict = judge(r.get("claim", {}).get("values", []))
    if verdict == "blocked":
        return "-"
    if verdict in ("not-reproduced", "partial"):
        return "X"
    basis = r.get("basis")
    if basis == "original":
        return "A"
    if basis == "patched":
        return "B"
    return "C" if r.get("gates", {}).get("cross_check") == "pass" else "D"


def load(repo: Path) -> list[dict]:
    rows = []
    for f in sorted((repo / "reports").glob("*/result.json")):
        r = json.loads(f.read_text(encoding="utf-8"))
        r["_dir"] = f.parent.name
        rows.append(r)
    return rows


def fmt(x) -> str:
    return "–" if x is None else (f"{x:.6g}" if isinstance(x, (int, float)) else str(x))


EDGE = 0.8   # a result using this share of its tolerance or more is flagged


def margin_cell(ours, paper, tol) -> str:
    """|difference| as a share of the registered tolerance; flagged near the edge."""
    if ours is None or paper is None or not tol:
        return "–"
    share = abs(ours - paper) / tol
    return f"{share:.0%}" + (" ⚠" if share >= EDGE else "")


def gate_cell(r: dict) -> str:
    g = r.get("gates", {})
    mark = {"pass": "✓", "fail": "✗", "na": "·"}
    return " ".join(mark.get(g.get(k, "na"), "?") for k in ("G1", "G2", "G3", "G5"))


def replay_cell(r: dict) -> str:
    rep = [e for e in (r.get("replayed") or []) if e.get("kind") == "clean"]
    if not rep:
        return "never clean"
    last = max(rep, key=lambda e: e.get("utc", ""))
    return f"{last.get('utc', '?')[:10]} {'ok' if last.get('ok') else 'CHANGED'}"


def load_funnel(repo: Path) -> tuple[dict, list[dict]]:
    """Frames (name -> frame plus its sample order) and the considered-candidate lines."""
    frames = {}
    for f in sorted((repo / "queue" / "frames").glob("*.json")):
        if f.name.endswith(".sample.json"):
            continue
        fr = json.loads(f.read_text(encoding="utf-8"))
        s = f.with_name(f.stem + ".sample.json")
        fr["order"] = json.loads(s.read_text(encoding="utf-8"))["order"] if s.exists() else []
        frames[fr["name"]] = fr
    lines = []
    p = repo / "queue" / "funnel.jsonl"
    if p.exists():
        lines = [json.loads(x) for x in p.read_text(encoding="utf-8").splitlines() if x.strip()]
    return frames, lines


def pct(a: int, b: int) -> str:
    return f"{a / b:.0%}" if b else "–"


def funnel_section(repo: Path, rows: list[dict]) -> list[str]:
    frames, lines = load_funnel(repo)
    legacy = repo / "queue" / "rejected.md"
    old = sum(1 for x in legacy.read_text(encoding="utf-8").splitlines() if x.startswith("- ")) if legacy.exists() else 0
    queued = {p.stem for p in (repo / "queue").glob("*.json")}
    framed_ids = {x.get("id") for x in lines if x.get("outcome") == "registered"}
    unframed = sorted(queued - framed_ids)
    by = collections.Counter(x["outcome"] for x in lines)
    out = ["## The funnel", "",
           "Every candidate is drawn from a named frame in a seeded order and none is skipped, so the "
           "denominator is the frame, not what looked tractable (docs/method.md).", ""]
    if old or unframed:
        out += [f"Not yet framed: {old} candidates in the legacy rejection log and {len(unframed)} attempted "
                f"papers ({', '.join(unframed) or 'none'}) were chosen before frames existed, so they are "
                "excluded from the numbers below.", ""]
    n = len(lines)
    out += [f"**{n} candidates considered from {len(frames)} frames: {by.get('registered', 0)} attempted "
            f"({pct(by.get('registered', 0), n)}), {by.get('unreachable', 0)} unreachable, "
            f"{by.get('rejected', 0)} rejected.**", ""]
    out += ["| frame | size | drawn | considered | coverage | attempted | unreachable | rejected |", "|---|---|---|---|---|---|---|---|"]
    for name, fr in sorted(frames.items()):
        mine = [x for x in lines if x.get("frame") == name]
        c = collections.Counter(x["outcome"] for x in mine)
        out.append(f"| {name} | {len(fr['items'])} | {len(fr['order'])} | {len(mine)} | {pct(len(mine), len(fr['order']))} "
                   f"| {c.get('registered', 0)} | {c.get('unreachable', 0)} | {c.get('rejected', 0)} |")
    out += ["", "| why a candidate was not attempted | candidates |", "|---|---|"]
    why = collections.Counter(x.get("reason") for x in lines if x["outcome"] != "registered")
    for k in REJECT_REASONS + UNREACHABLE_REASONS:
        out.append(f"| {k} | {why.get(k, 0)} |")
    out += ["", "Survivorship: the share of each stack among all candidates considered, and among those attempted.", "",
            "| stack | considered | attempted |", "|---|---|---|"]
    stacks = sorted({x.get("stack", "?") for x in lines})
    for s in stacks:
        out.append(f"| {s} | {sum(1 for x in lines if x.get('stack', '?') == s)} "
                   f"| {sum(1 for x in lines if x.get('stack', '?') == s and x['outcome'] == 'registered')} |")
    gone = [x for x in lines if x["outcome"] == "unreachable"]
    out += ["", "### Unreachable", "",
            "The artifact cannot be obtained, and the method is not described well enough to rebuild it. "
            "This is a finding about the tail, not a filtered-out candidate.", "",
            "| paper | year · stack | what is gone | fallbacks tried | checked |", "|---|---|---|---|---|"]
    for x in gone:
        out.append(f"| {x.get('paper', x.get('item', '?'))} | {x.get('year', '?')} · {x.get('stack', '?')} "
                   f"| {x.get('reason')}: {x.get('detail', '')} | {', '.join(x.get('checked', []))} | {x.get('utc', '?')[:10]} |")
    if not gone:
        out.append("| none yet | | | | |")
    state = collections.Counter((r.get("original_attempt") or {}).get("outcome", "none") for r in rows)
    out += ["", "Authors' original artifact among attempted papers: "
            + ", ".join(f"{k} {v}" for k, v in sorted(state.items())) + ".", ""]
    return out


def build(repo: Path) -> str:
    rows = load(repo)
    out = ["# Ledger", "",
           "Generated by `tools/build_ledger.py` from `reports/*/result.json`; do not edit by hand.",
           "Method and gates: [docs/method.md](docs/method.md).", ""]
    grades = collections.Counter(grade(r) for r in rows)
    out += ["## Scoreboard", "", f"{len(rows)} papers attempted.", "", "| grade | meaning | papers |", "|---|---|---|"]
    for k in ("A", "B", "C", "D", "X", "-"):
        out.append(f"| {k} | {GRADE_TEXT[k]} | {grades.get(k, 0)} |")
    out.append("")
    for title, key in (("field", "field"), ("stack", "stack"), ("decade", None)):
        c = collections.Counter()
        for r in rows:
            c[(r.get("paper", {}).get("year", 0) // 10 * 10 if key is None else r.get(key, "?"))] += 1
        out.append(f"By {title}: " + (", ".join(f"{k} {v}" for k, v in sorted(c.items(), key=lambda x: str(x[0]))) or "none"))
    out += [""] + funnel_section(repo, rows)
    out += ["## Results", "",
            "| paper | field · year · stack | claim | paper value ± tol | our value | Δ | margin | basis | gates G1 G2 G3 G5 | grade | verdict | last replay |",
            "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        p, c = r.get("paper", {}), r.get("claim", {})
        for v in c.get("values", [{}]):
            ours = v.get("ours")
            delta = None if ours is None or "paper" not in v else ours - v["paper"]
            out.append("| " + " | ".join([
                f"[{p.get('short', r['_dir'])}](reports/{r['_dir']}/result.md)",
                f"{r.get('field', '?')} · {p.get('year', '?')} · {r.get('stack', '?')}",
                f"{c.get('text', '?')}" + (f" ({v['name']})" if v.get("name") else ""),
                f"{fmt(v.get('paper'))} ± {fmt(v.get('tol_abs'))}",
                fmt(ours), fmt(delta), margin_cell(ours, v.get("paper"), v.get("tol_abs")), r.get("basis", "?"), gate_cell(r), grade(r),
                judge(c.get("values", [])), replay_cell(r)]) + " |")
    out += ["", f"Margin is |our value − paper value| as a share of the tolerance registered before the run; ⚠ marks {EDGE:.0%} or more, a result that a different environment could flip.", "",
            "## Why papers stopped reproducing", "",
            "Cause of every `not-reproduced` or `blocked` result.", "", "| cause | papers |", "|---|---|"]
    causes = collections.Counter(r.get("cause") for r in rows if judge(r.get("claim", {}).get("values", [])) != "reproduced")
    for k in CAUSES:
        out.append(f"| {k} | {causes.get(k, 0)} |")
    out.append("")
    return "\n".join(out)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, type=Path)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args(argv)
    try:
        text = build(a.repo)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"cannot build ledger: {exc}", file=sys.stderr)
        return 3
    target = a.repo / "ledger.md"
    if a.check:
        have = target.read_text(encoding="utf-8") if target.exists() else ""
        if have != text:
            print("ledger.md differs from the generated ledger; run tools/build_ledger.py --repo .")
            return 2
        print("ledger.md matches reports/*/result.json")
        return 0
    target.write_text(text, encoding="utf-8")
    print(f"wrote {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
