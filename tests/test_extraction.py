"""The `extraction` patch kind: the patch step only copies a contiguous line range of the archive file."""
import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "checks"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import gates  # noqa: E402
import verify_sources as vs  # noqa: E402
from test_gates import git, make  # noqa: E402
from test_patch_rule import tree  # noqa: E402

ARCHIVE = b"prose, not Fortran\nprogram a\nend\n"          # 3 lines; the code is lines 2-3
CODE = b"program a\nend\n"                                  # what lines 2:3 are
CMD = "gfortran -std=legacy -w -o tomp TOMP.FOR"
M = "python3 tools/verify_sources.py manifest"
RECIPE = (f'#!/bin/sh\n{M} "$W/src" > "$W/manifest.pre"\ntail -n +2 "$W/src/733.f" > "$W/src/TOMP.FOR"\n'
          f'{M} "$W/src" > "$W/manifest.mid"\n{CMD}\n{M} "$W/src" > "$W/manifest.post"\n')


def setup(tmp_path, mid_extra=CODE, archive=ARCHIVE):
    repo = make(tmp_path)
    (repo / "queue" / "p1.json").write_text(json.dumps({"claim": "x", "code": {
        "commit": "netlib archive 733.gz (bytes 1, sha256 " + "ab" * 32 + ")"}}))
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "queue with archive hash")
    qc = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H", "--", "queue/p1.json"],
                        capture_output=True, text=True).stdout.strip()
    rp = repo / "reports" / "p1" / "result.json"
    r = json.loads(rp.read_text())
    r.update(basis="patched", queue_commit=qc, gates={"G1": "pass", "G2": "na", "G3": "pass", "cross_check": "na"})
    rp.write_text(json.dumps(r))
    (repo / "reports" / "p1" / "recipe.sh").write_text(RECIPE)
    arch = tmp_path / "733.f"
    arch.write_bytes(archive)
    pre = tmp_path / "m.pre"
    pre.write_text(tree(tmp_path, "t_pre", {"733.f": archive.decode()}))
    mid = tmp_path / "m.mid"
    mid.write_text(tree(tmp_path, "t_mid", {"733.f": archive.decode(), "TOMP.FOR": mid_extra.decode()}))
    post = tmp_path / "m.post"
    post.write_text(tree(tmp_path, "t_post", {"733.f": archive.decode(), "TOMP.FOR": mid_extra.decode()}))
    return repo, arch, pre, mid, post


def record(repo, arch, pre, mid, post):
    return vs.record(repo, "p1", pre, mid, post, [CMD],
                     {"archive_file": arch, "start": 2, "end": 3, "extracted": "TOMP.FOR"})


def test_range_is_contiguous_and_checked():
    assert vs.extract_range(ARCHIVE, 2, 3) == CODE
    with pytest.raises(ValueError):
        vs.extract_range(ARCHIVE, 2, 4)
    with pytest.raises(ValueError):
        vs.extract_range(ARCHIVE, 0, 2)


def test_verbatim_extraction_is_kind_extraction_and_passes_g2(tmp_path):
    repo, arch, pre, mid, post = setup(tmp_path)
    assert record(repo, arch, pre, mid, post)["kind"] == "extraction"
    assert gates.violations(repo) == []


def test_extraction_that_changed_a_line_is_source_and_fails_g2(tmp_path):
    repo, arch, pre, mid, post = setup(tmp_path, mid_extra=b"program b\nend\n")
    assert record(repo, arch, pre, mid, post)["kind"] == "source"
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_tampered_range_evidence_fails_the_gate(tmp_path):
    repo, arch, pre, mid, post = setup(tmp_path)
    record(repo, arch, pre, mid, post)
    (repo / "reports" / "p1" / "evidence" / "source-range.f").write_bytes(b"program b\nend\n")
    bad = gates.violations(repo)
    assert any("range_sha256 does not match" in v for v in bad)
    assert any("G2 fidelity not passed" in v for v in bad)


def test_patch_step_that_changes_the_archive_is_not_extraction(tmp_path):
    repo, arch, pre, mid, post = setup(tmp_path)
    mid.write_text(mid.read_text().replace(vs.render(vs.manifest(tmp_path / "t_pre")).split()[0], "0" * 64))
    assert record(repo, arch, pre, mid, post)["kind"] == "source"
