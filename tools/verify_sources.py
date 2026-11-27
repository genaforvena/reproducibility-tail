#!/usr/bin/env python3
"""Prove that a patch is build-only: we changed no source file before running the authors' build.

A recipe takes THREE manifests of the authors' source files:
  pre   right after the archive is unpacked, before any patch
  mid   after our own patch step, immediately before the build commands
  post  after the build

  tools/verify_sources.py manifest DIR                          print "sha256  path" for each source file
  tools/verify_sources.py compare A B                           print modified / removed / added as JSON
  tools/verify_sources.py record --repo . --id ID --pre PRE --mid MID --post POST --command CMD [--command CMD]
      [--archive-file F --range START:END --extracted NAME]

`record` copies the manifests into the report and writes result.json `patch`. The patch is `build-only`
when pre and mid are identical (at least one file compared): nothing we did touched a source file.
What the authors' own build tool rewrites between mid and post (NTL's configure edits config.h in place,
for example) is recorded as `tool` changes and shown in the ledger, but does not disqualify. Anything else
is `source` and keeps gate G2's paper check.

The `extraction` kind is the one exception to that check: the patch step only copies a contiguous line range of the
authors' archive file into a new file (the authors' code, byte for byte, nothing added or changed). Passing
--archive-file, --range and --extracted to `record` proves it: the new file's hash in the mid manifest must equal the
sha256 of that line range, and the range bytes are kept in the report as evidence/source-range.f. The gate re-checks
the same chain from the kept manifests and range file. The archive's own hash (the .gz the queue entry registers) is
checked against the queue entry as for every kind; the extracted file's hash is the range's hash, so the gate needs no
archive bytes.

checks/gates.py re-derives all of this from the manifests, requires the recorded build commands to appear
in recipe.sh between the second and third `verify_sources.py manifest` lines, and refuses that region if it
contains in-place editing (see SUSPICIOUS). That scan is a heuristic, not a proof: an edit hidden in a script
the build calls is not seen, which is why the label shows what the build tool rewrote.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

SOURCE_EXT = {".f", ".for", ".f77", ".f90", ".f95", ".c", ".cc", ".cpp", ".cxx", ".h", ".hh", ".hpp", ".hxx",
              ".m", ".r", ".py", ".jl", ".java", ".pas", ".pl", ".tex", ".sh", ".mk", ".in", ".ac", ".am",
              ".inc", ".cmake", ".cfg", ".conf", ".def", ".ini", ".mak", ".make"}
SOURCE_NAMES = {"makefile", "gnumakefile", "configure", "cmakelists.txt", "description", "namespace"}
# Files that choose compilers, flags and libraries are part of the build recipe, so a file we add or edit
# before the build (makefile.inc, make.inc, Makefile.local) must show up in the pre/mid comparison.
SOURCE_PREFIXES = ("makefile", "gnumakefile", "make.", "config.mk", "setup.", "build.")
SKIP_DIRS = {".git", "__pycache__", "node_modules"}
MAX_BYTES = 50_000_000
MANIFEST_CALL = "verify_sources.py manifest"

# In-place editing a build step must not contain. A heuristic: it names the usual ways to change a file.
SUSPICIOUS = [
    (r"\bsed\b[^\n|;&]*\s(-[a-zA-Z]*i|--in-place)\b", "sed in place"),
    (r"\bperl\b[^\n|;&]*\s-[a-zA-Z]*i", "perl in place"),
    (r"(?<![\w.])patch\s+-|(?<![\w.])patch\s+<|\bgit\s+apply\b|\bdiff\b[^\n]*\|\s*patch", "patch/apply"),
    (r"\b(tee|truncate|dd|install|ed|ex)\s+[^\n|;&]*\.(f|for|f77|f90|f95|c|cc|cpp|cxx|h|hh|hpp|hxx|m|r|py|jl|java|pas)\b",
     "writes a source file"),
    (r">>?\s*['\"]?[\w./${}-]*\.(f|for|f77|f90|f95|c|cc|cpp|cxx|h|hh|hpp|hxx|m|r|py|jl|java|pas)\b", "redirect into a source file"),
    (r"\b(cp|mv|ln)\s+[^\n|;&]*\.(f|for|f77|f90|f95|c|cc|cpp|cxx|h|hh|hpp|hxx|m|r|py|jl|java|pas)\b", "copies a source file"),
    (r"\bpython[\d.]*\s+-c\b|\bperl\s+-[a-zA-Z]*e\b|\bawk\b[^\n]*>\s*\S", "scripted write"),
]


def is_source(path: Path) -> bool:
    n = path.name.lower()
    return path.suffix.lower() in SOURCE_EXT or n in SOURCE_NAMES or n.startswith(SOURCE_PREFIXES)


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


def compare(a: dict[str, str], b: dict[str, str]) -> dict:
    return {"compared": len(a),
            "modified": sorted(p for p in a if p in b and a[p] != b[p]),
            "removed": sorted(p for p in a if p not in b),
            "added": sorted(p for p in b if p not in a)}


def unchanged(diff: dict) -> bool:
    return diff["compared"] > 0 and not (diff["modified"] or diff["removed"] or diff["added"])


def build_region(recipe_text: str) -> str | None:
    """The part of recipe.sh between its second and third manifest calls (the build commands), or None."""
    lines = recipe_text.splitlines()
    marks = [i for i, ln in enumerate(lines) if MANIFEST_CALL in ln and not ln.lstrip().startswith("#")]
    return "\n".join(lines[marks[1] + 1:marks[2]]) if len(marks) == 3 else None


def suspicious(region: str) -> list[str]:
    hits = []
    for line in region.splitlines():
        if line.lstrip().startswith("#"):
            continue
        for pattern, why in SUSPICIOUS:
            if re.search(pattern, line):
                hits.append(f"{why}: {line.strip()[:100]}")
    return hits


def norm(s: str) -> str:
    return " ".join(s.split())


def classify(ours: dict, commands: list[str], region: str | None) -> str:
    if not unchanged(ours) or not commands or region is None or suspicious(region):
        return "source"
    return "build-only" if all(norm(c) in norm(region) for c in commands) else "source"


def extract_range(archive: bytes, start: int, end: int) -> bytes:
    """Lines START..END (1-based, inclusive) of the archive file, as bytes with their line endings."""
    lines = archive.splitlines(keepends=True)
    if not 1 <= start <= end <= len(lines):
        raise ValueError(f"range {start}:{end} is outside the archive file ({len(lines)} lines)")
    return b"".join(lines[start - 1:end])


def classify_extraction(ours: dict, mid: dict, extracted: str, range_sha: str, commands: list[str], region: str | None) -> str:
    """`extraction` when the patch step only added the extracted file, its hash is the range's, and the build is as recorded."""
    same = ours["modified"] == [] and ours["removed"] == [] and ours["added"] == [extracted] and mid.get(extracted) == range_sha
    if not same or not commands or region is None or suspicious(region):
        return "source"
    return "extraction" if all(norm(c) in norm(region) for c in commands) else "source"


def archive_sha(queue_entry: dict) -> str:
    """The sha256 the queue entry registers for the archive: code.archive, else the .gz hash named in code.commit."""
    code = queue_entry.get("code") or {}
    m = re.search(r"sha256 ([0-9a-f]{64})", str(code.get("archive", "")))
    if not m:
        m = re.search(r"\.(?:gz|zip)\b[^;]*?sha256 ([0-9a-f]{64})", str(code.get("commit", "")))
    return m.group(1) if m else ""


def tool_changes(mid: dict, post: dict) -> dict:
    d = compare(mid, post)
    return {"modified": d["modified"], "removed": d["removed"], "added": d["added"]}


def record(repo: Path, rid: str, pre_p: Path, mid_p: Path, post_p: Path, commands: list[str],
           extraction: dict | None = None) -> dict:
    """Write the three manifests and the patch record into result.json.

    extraction: {"archive_file": Path, "start": int, "end": int, "extracted": str} when the patch step copied a line range.
    """
    ev = repo / "reports" / rid / "evidence"
    ev.mkdir(parents=True, exist_ok=True)
    texts = {}
    for name, src in (("pre", pre_p), ("mid", mid_p), ("post", post_p)):
        texts[name] = src.read_text(encoding="utf-8")
        (ev / f"manifest.{name}").write_text(texts[name], encoding="utf-8")
    pre, mid, post = (parse(texts[n]) for n in ("pre", "mid", "post"))
    ours = compare(pre, mid)
    recipe = repo / "reports" / rid / "recipe.sh"
    region = build_region(recipe.read_text(encoding="utf-8")) if recipe.exists() else None
    qp = repo / "queue" / f"{rid}.json"
    qp = qp if qp.exists() else repo / "queue" / "withdrawn" / f"{rid}.json"
    kind = classify(ours, commands, region)
    patch = {"kind": kind, "archive_sha256": archive_sha(json.loads(qp.read_text(encoding="utf-8"))),
             "compared": ours["compared"], "ours": {k: ours[k] for k in ("modified", "removed", "added")},
             "tool": tool_changes(mid, post), "build_commands": commands,
             "manifests": {n: f"reports/{rid}/evidence/manifest.{n}" for n in ("pre", "mid", "post")}}
    if extraction is not None:
        archive = extraction["archive_file"].read_bytes()
        rng = extract_range(archive, extraction["start"], extraction["end"])
        range_sha = hashlib.sha256(rng).hexdigest()
        (ev / "source-range.f").write_bytes(rng)
        patch["kind"] = classify_extraction(ours, mid, extraction["extracted"], range_sha, commands, region)
        patch["extraction"] = {"file_sha256": hashlib.sha256(archive).hexdigest(), "file": extraction["archive_file"].name,
                               "start": extraction["start"], "end": extraction["end"],
                               "extracted": extraction["extracted"], "range_sha256": range_sha}
    rp = repo / "reports" / rid / "result.json"
    result = json.loads(rp.read_text(encoding="utf-8"))
    result["patch"] = patch
    rp.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return patch


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("manifest"); m.add_argument("dir", type=Path)
    c = sub.add_parser("compare"); c.add_argument("a", type=Path); c.add_argument("b", type=Path)
    r = sub.add_parser("record")
    r.add_argument("--repo", required=True, type=Path); r.add_argument("--id", required=True)
    for n in ("pre", "mid", "post"):
        r.add_argument(f"--{n}", required=True, type=Path)
    r.add_argument("--command", action="append", default=[], help="a build command exactly as recipe.sh runs it")
    r.add_argument("--archive-file", type=Path, help="the authors' archive file the patch step copied a range from")
    r.add_argument("--range", help="START:END, 1-based inclusive lines of --archive-file")
    r.add_argument("--extracted", help="the file the patch step created from that range, as named in the manifests")
    a = ap.parse_args(argv)
    if a.cmd == "manifest":
        sys.stdout.write(render(manifest(a.dir)))
        return 0
    if a.cmd == "compare":
        print(json.dumps(compare(parse(a.a.read_text()), parse(a.b.read_text())), indent=1))
        return 0
    extraction = None
    if a.range or a.archive_file or a.extracted:
        if not (a.range and a.archive_file and a.extracted):
            ap.error("--range, --archive-file and --extracted go together")
        start, end = (int(x) for x in a.range.split(":"))
        extraction = {"archive_file": a.archive_file, "start": start, "end": end, "extracted": a.extracted}
    patch = record(a.repo, a.id, a.pre, a.mid, a.post, a.command, extraction)
    t = patch["tool"]
    print(f"{a.id}: patch kind {patch['kind']}: compared {patch['compared']}; ours modified {len(patch['ours']['modified'])}, "
          f"removed {len(patch['ours']['removed'])}, added {len(patch['ours']['added'])}; build tool modified {len(t['modified'])}, "
          f"added {len(t['added'])}, removed {len(t['removed'])}")
    return 0 if patch["kind"] in ("build-only", "extraction") else 2


if __name__ == "__main__":
    sys.exit(main())
