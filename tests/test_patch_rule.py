import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "checks"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_ledger  # noqa: E402
import gates  # noqa: E402
import verify_sources as vs  # noqa: E402
from test_gates import git, make  # noqa: E402

SHA = "ab" * 32


def build_tree(tmp_path, files):
    root = tmp_path / "tree"
    for rel, text in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
    return root


def patched_report(tmp_path, pre_files, post_files, generated=None, archive_sha=SHA, record=True):
    """A reproduced, patched report whose G2 is `na`, with a queue entry that registers an archive hash."""
    repo = make(tmp_path)
    (repo / "queue" / "p1.json").write_text(json.dumps({"claim": "x", "code": {"archive": f"sha256 {archive_sha} (netlib)"}}))
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "queue with archive hash")
    qc = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H", "--", "queue/p1.json"],
                        capture_output=True, text=True).stdout.strip()
    rp = repo / "reports" / "p1" / "result.json"
    r = json.loads(rp.read_text())
    r.update(basis="patched", queue_commit=qc, gates={"G1": "pass", "G2": "na", "G3": "pass", "cross_check": "na"},
             original_attempt={"tried": True, "outcome": "failed", "reason": "make cannot find a header",
                               "log": "reports/p1/logs/orig.log"})
    rp.write_text(json.dumps(r))
    pre, post = tmp_path / "pre", tmp_path / "post"
    pre.write_text(vs.render(vs.manifest(build_tree(tmp_path / "a", pre_files))))
    post.write_text(vs.render(vs.manifest(build_tree(tmp_path / "b", post_files))))
    if record:
        vs.record(repo, "p1", pre, post, generated or [])
    return repo


SRC = {"src/a.f": "program a\nend\n", "src/b.h": "#define B 1\n", "Makefile": "all:\n"}


# ---- the tool -------------------------------------------------------------------------------
def test_manifest_covers_source_files_only(tmp_path):
    root = build_tree(tmp_path, {**SRC, "build/a.o": "binary", "notes.png": "x", "src/.git/config": "x"})
    assert set(vs.manifest(root)) == {"src/a.f", "src/b.h", "Makefile"}


def test_compare_finds_modified_removed_added(tmp_path):
    pre = vs.manifest(build_tree(tmp_path / "a", SRC))
    post = vs.manifest(build_tree(tmp_path / "b", {"src/a.f": "program a\nprint *, 1\nend\n", "src/b.h": "#define B 1\n",
                                                   "extra.c": "int x;\n"}))
    d = vs.compare(pre, post)
    assert d["modified"] == ["src/a.f"] and d["removed"] == ["Makefile"] and d["added"] == ["extra.c"]


# ---- the gate accepts the exemption only when the manifests prove it ------------------------
def test_build_only_patch_passes_without_a_paper_check(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC)
    assert json.loads((repo / "reports/p1/result.json").read_text())["patch"]["kind"] == "build-only"
    assert gates.violations(repo) == []


def test_without_a_patch_record_the_paper_check_is_still_required(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC, record=False)
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_modified_source_is_not_build_only(tmp_path):
    repo = patched_report(tmp_path, SRC, {**SRC, "src/a.f": "program a\nstop\nend\n"})
    assert json.loads((repo / "reports/p1/result.json").read_text())["patch"]["kind"] == "source"
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_added_source_file_is_not_build_only_unless_declared_with_a_reason(tmp_path):
    repo = patched_report(tmp_path, SRC, {**SRC, "stub.c": "void pgstub(void){}\n"})
    assert json.loads((repo / "reports/p1/result.json").read_text())["patch"]["kind"] == "source"
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))
    declared = patched_report(tmp_path / "d", SRC, {**SRC, "gen/config.h": "#define X 1\n"},
                              generated=[{"glob": "gen/*.h", "reason": "written by the authors' configure step"}])
    assert json.loads((declared / "reports/p1/result.json").read_text())["patch"]["kind"] == "build-only"
    assert gates.violations(declared) == []
    no_reason = patched_report(tmp_path / "n", SRC, {**SRC, "gen/config.h": "x\n"}, generated=[{"glob": "gen/*.h", "reason": " "}])
    assert json.loads((no_reason / "reports/p1/result.json").read_text())["patch"]["kind"] == "source"


def test_a_record_that_claims_more_than_the_manifests_show_is_caught(tmp_path):
    repo = patched_report(tmp_path, SRC, {**SRC, "src/a.f": "tampered\n"})
    rp = repo / "reports/p1/result.json"
    r = json.loads(rp.read_text())
    r["patch"].update(kind="build-only", modified=[])          # lie about the comparison
    rp.write_text(json.dumps(r))
    bad = gates.violations(repo)
    assert any("does not match the manifests" in v for v in bad) and any("G2 fidelity not passed" in v for v in bad)


def test_edited_manifest_that_hides_a_change_is_caught_by_the_recorded_numbers(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC)
    post = repo / "reports/p1/evidence/manifest.post"
    lines = post.read_text().splitlines()
    post.write_text("\n".join(lines[:-1]) + "\n")                # drop a file from the post manifest
    assert any("does not match the manifests" in v for v in gates.violations(repo))


def test_archive_hash_must_be_the_registered_one(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC)
    rp = repo / "reports/p1/result.json"
    r = json.loads(rp.read_text())
    r["patch"]["archive_sha256"] = "cd" * 32
    rp.write_text(json.dumps(r))
    assert any("archive_sha256 must equal" in v for v in gates.violations(repo))


def test_nothing_compared_is_not_a_proof(tmp_path):
    repo = patched_report(tmp_path, {}, {})
    assert json.loads((repo / "reports/p1/result.json").read_text())["patch"]["kind"] == "source"
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_only_a_patched_basis_can_be_build_only(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC)
    rp = repo / "reports/p1/result.json"
    r = json.loads(rp.read_text())
    r["basis"] = "reimplemented"
    r["original_attempt"]["outcome"] = "failed"
    rp.write_text(json.dumps(r))
    assert any("belongs to basis patched" in v for v in gates.violations(repo))


def test_ledger_marks_a_verified_build_only_patch(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC)
    assert "patched (build-only)" in build_ledger.build(repo)
    other = patched_report(tmp_path / "o", SRC, {**SRC, "src/a.f": "x\n"})
    assert "patched (build-only)" not in build_ledger.build(other)


def test_cli_record_exit_code_follows_the_kind(tmp_path):
    repo = patched_report(tmp_path, SRC, SRC, record=False)
    pre, post = tmp_path / "pre", tmp_path / "post"
    assert vs.main(["record", "--repo", str(repo), "--id", "p1", "--pre", str(pre), "--post", str(post)]) == 0
    modified = tmp_path / "post2"
    modified.write_text(vs.render({**vs.parse(post.read_text()), "src/a.f": "0" * 64}))
    assert vs.main(["record", "--repo", str(repo), "--id", "p1", "--pre", str(pre), "--post", str(modified)]) == 2
