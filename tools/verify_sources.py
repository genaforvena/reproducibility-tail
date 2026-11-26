#!/usr/bin/env python3
"""Prove that a patch is build-only: the authors' source files are byte-identical before and after.

A recipe takes a manifest of the authors' source files right after it unpacks the archive (before
any patch), builds, and takes another. This tool compares them.

  tools/verify_sources.py manifest DIR                       print "sha256  path" for every source file
  tools/verify_sources.py compare PRE POST                   print modified / removed / added as JSON
  tools/verify_sources.py record --repo . --id ID --pre PRE --post POST [--generated GLOB=REASON ...]
                                                             copy the manifests into the report and
                                                             write result.json `patch`

A patch is `build-only` when no source file was modified or removed and every added source file is a
declared, reasoned `generated` file (files the authors' own build writes, such as configure output).
Anything else is `source`, which keeps the paper check of gate G2. checks/gates.py re-derives the
comparison from the two manifests kept in the report, so the record cannot claim more than they show.
"""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import re
import sys
from pathlib import Path

SOURCE_EXT = {".f", ".for", ".f77", ".f90", ".f95", ".c", ".cc", ".cpp", ".cxx", ".h", ".hh", ".hpp", ".hxx",
              ".m", ".r", ".py", ".jl", ".java", ".pas", ".pl", ".tex", ".sh", ".mk", ".in", ".ac", ".am"}
SOURCE_NAMES = {"makefile", "gnumakefile", "configure", "cmakelists.txt", "description", "namespace"}
SKIP_DIRS = {".git", "__pycache__", "node_modules"}
MAX_BYTES = 50_000_000


def is_source(path: Path) -> bool:
    return path.suffix.lower() in SOURCE_EXT or path.name.lower() in SOURCE_NAMES


def manifest(root: Path) -> dict[str, str]:
    out = {}
    for p in sorted(root.rglob("*")):
        if p.is_file() and not any(part in SKIP_DIRS for part in p.parts) and is_source(p) and p.stat().st_size <= MAX_BYTES:
            out[p.relative_to(root).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    return out


def render(m: dict[str, str]) -> str:
    return "".join(f"{h}  {path}\n" for path, h in sorted(m.items()))


def parse(text: str) -> dict[str, str]:
    m = {}
    for line in text.splitlines():
        got = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if got:
            m[got.group(2)] = got.group(1)
    return m


def compare(pre: dict[str, str], post: dict[str, str]) -> dict:
    return {"compared": len(pre),
            "modified": sorted(p for p in pre if p in post and pre[p] != post[p]),
            "removed": sorted(p for p in pre if p not in post),
            "added": sorted(p for p in post if p not in pre)}


def classify(diff: dict, generated: list[dict]) -> str:
    """build-only when nothing the authors wrote changed and every added file is a declared generated one."""
    if diff["compared"] == 0 or diff["modified"] or diff["removed"]:
        return "source"
    for path in diff["added"]:
        if not any(fnmatch.fnmatch(path, g["glob"]) and str(g.get("reason", "")).strip() for g in generated):
            return "source"
    return "build-only"


def archive_sha(queue_entry: dict) -> str:
    m = re.search(r"sha256 ([0-9a-f]{64})", str((queue_entry.get("code") or {}).get("archive", "")))
    return m.group(1) if m else ""


def record(repo: Path, rid: str, pre_path: Path, post_path: Path, generated: list[dict]) -> dict:
    ev = repo / "reports" / rid / "evidence"
    ev.mkdir(parents=True, exist_ok=True)
    pre_text, post_text = pre_path.read_text(encoding="utf-8"), post_path.read_text(encoding="utf-8")
    (ev / "manifest.pre").write_text(pre_text, encoding="utf-8")
    (ev / "manifest.post").write_text(post_text, encoding="utf-8")
    diff = compare(parse(pre_text), parse(post_text))
    queue = json.loads((repo / "queue" / f"{rid}.json").read_text(encoding="utf-8")) if (repo / "queue" / f"{rid}.json").exists() \
        else json.loads((repo / "queue" / "withdrawn" / f"{rid}.json").read_text(encoding="utf-8"))
    patch = {"kind": classify(diff, generated), "archive_sha256": archive_sha(queue), **diff, "generated": generated,
             "manifest_pre": f"reports/{rid}/evidence/manifest.pre", "manifest_post": f"reports/{rid}/evidence/manifest.post"}
    rp = repo / "reports" / rid / "result.json"
    result = json.loads(rp.read_text(encoding="utf-8"))
    result["patch"] = patch
    rp.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return patch


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("manifest"); m.add_argument("dir", type=Path)
    c = sub.add_parser("compare"); c.add_argument("pre", type=Path); c.add_argument("post", type=Path)
    r = sub.add_parser("record")
    r.add_argument("--repo", required=True, type=Path); r.add_argument("--id", required=True)
    r.add_argument("--pre", required=True, type=Path); r.add_argument("--post", required=True, type=Path)
    r.add_argument("--generated", action="append", default=[], help="GLOB=REASON for a file the authors' own build writes")
    a = ap.parse_args(argv)
    if a.cmd == "manifest":
        sys.stdout.write(render(manifest(a.dir)))
        return 0
    if a.cmd == "compare":
        print(json.dumps(compare(parse(a.pre.read_text()), parse(a.post.read_text())), indent=1))
        return 0
    generated = [{"glob": g.split("=", 1)[0], "reason": g.split("=", 1)[1] if "=" in g else ""} for g in a.generated]
    patch = record(a.repo, a.id, a.pre, a.post, generated)
    print(f"{a.id}: patch kind {patch['kind']}: compared {patch['compared']}, modified {len(patch['modified'])}, "
          f"removed {len(patch['removed'])}, added {len(patch['added'])}")
    return 0 if patch["kind"] == "build-only" else 2


if __name__ == "__main__":
    sys.exit(main())
