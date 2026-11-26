import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "checks"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_ledger  # noqa: E402
import gates  # noqa: E402
import verify_sources as vs  # noqa: E402
from test_gates import git, make  # noqa: E402

SHA = "ab" * 32
SRC = {"src/a.f": "program a\nend\n", "src/b.h": "#define B 1\n", "Makefile": "all:\n"}
BUILD = "sh ./configure PREFIX=/work/ntl && make -j2 && make install"
M = "python3 tools/verify_sources.py manifest"


def recipe(build=BUILD, patch_step="# our patch: compile flags only", calls=3):
    lines = ["#!/bin/sh", f'{M} "$W/src" > "$W/manifest.pre"', patch_step]
    if calls >= 2:
        lines.append(f'{M} "$W/src" > "$W/manifest.mid"')
    lines.append(build)
    if calls >= 3:
        lines.append(f'{M} "$W/src" > "$W/manifest.post"')
    return "\n".join(lines) + "\n"


def tree(tmp_path, name, files):
    root = tmp_path / name
    for rel, text in files.items():
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
    return vs.render(vs.manifest(root))


def patched_report(tmp_path, pre=SRC, mid=SRC, post=SRC, recipe_text=None, commands=(BUILD,), archive_sha=SHA, record=True):
    """A reproduced, patched report with G2 `na`, a queue entry that registers an archive hash, and a recipe."""
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
    (repo / "reports" / "p1" / "recipe.sh").write_text(recipe_text if recipe_text is not None else recipe())
    paths = {}
    for n, files in (("pre", pre), ("mid", mid), ("post", post)):
        paths[n] = tmp_path / f"m.{n}"
        paths[n].write_text(tree(tmp_path, f"t_{n}", files))
    if record:
        vs.record(repo, "p1", paths["pre"], paths["mid"], paths["post"], list(commands))
    return repo


def result(repo):
    return json.loads((repo / "reports/p1/result.json").read_text())


def force_kind(repo, **changes):
    r = result(repo)
    r["patch"].update(kind="build-only", **changes)
    (repo / "reports/p1/result.json").write_text(json.dumps(r))


TOOL_POST = {**SRC, "src/b.h": "#define B 2\n", "src/config.h": "generated\n", "src/GetTime.c": "int t;\n"}


# ---- the tool -------------------------------------------------------------------------------
def test_manifest_covers_source_files_only(tmp_path):
    root = tmp_path / "t"
    for rel in ("src/a.f", "src/b.h", "Makefile", "build/a.o", "notes.png", "src/.git/config"):
        (root / rel).parent.mkdir(parents=True, exist_ok=True)
        (root / rel).write_text("x")
    assert set(vs.manifest(root)) == {"src/a.f", "src/b.h", "Makefile"}


def test_compare_finds_modified_removed_added(tmp_path):
    a = vs.parse(tree(tmp_path, "a", SRC))
    b = vs.parse(tree(tmp_path, "b", {"src/a.f": "changed\n", "src/b.h": "#define B 1\n", "extra.c": "int x;\n"}))
    d = vs.compare(a, b)
    assert d["modified"] == ["src/a.f"] and d["removed"] == ["Makefile"] and d["added"] == ["extra.c"]


# ---- accepted: we touched nothing before the build ------------------------------------------
def test_build_only_with_no_tool_changes_passes_without_a_paper_check(tmp_path):
    repo = patched_report(tmp_path)
    assert result(repo)["patch"]["kind"] == "build-only"
    assert gates.violations(repo) == []
    assert "patched (build-only)" in build_ledger.build(repo)


def test_authors_build_tool_rewriting_files_is_shown_not_judged(tmp_path):
    """The NTL case: configure edits a shipped header in place and writes new ones."""
    repo = patched_report(tmp_path, post=TOOL_POST)
    p = result(repo)["patch"]
    assert p["kind"] == "build-only" and p["tool"]["modified"] == ["src/b.h"] and sorted(p["tool"]["added"]) == ["src/GetTime.c", "src/config.h"]
    assert gates.violations(repo) == []
    assert "the build tool rewrote 3 files" in build_ledger.build(repo)


def test_comment_lines_in_the_build_step_are_ignored(tmp_path):
    repo = patched_report(tmp_path, recipe_text=recipe(build="# we never run sed -i here\n" + BUILD))
    assert result(repo)["patch"]["kind"] == "build-only" and gates.violations(repo) == []


# ---- refused: we changed something before the build -----------------------------------------
def test_modified_source_before_the_build_is_not_build_only(tmp_path):
    repo = patched_report(tmp_path, mid={**SRC, "src/a.f": "program a\nstop\nend\n"})
    assert result(repo)["patch"]["kind"] == "source"
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_stub_added_before_the_build_is_not_build_only(tmp_path):
    repo = patched_report(tmp_path, mid={**SRC, "pgstub.c": "void pgstub(void){}\n"})
    assert result(repo)["patch"]["kind"] == "source"
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_removed_source_before_the_build_is_not_build_only(tmp_path):
    repo = patched_report(tmp_path, mid={k: v for k, v in SRC.items() if k != "Makefile"})
    assert result(repo)["patch"]["kind"] == "source"


def test_nothing_compared_is_not_a_proof(tmp_path):
    repo = patched_report(tmp_path, pre={}, mid={}, post={})
    assert result(repo)["patch"]["kind"] == "source"


def test_without_a_patch_record_the_paper_check_is_still_required(tmp_path):
    repo = patched_report(tmp_path, record=False)
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


# ---- the hole a build-only claim could hide behind ------------------------------------------
@pytest.mark.parametrize("build", [
    "sed -i 's/B 1/B 2/' src/b.h && make",
    "patch -p1 < fix.diff && make",
    "cat > src/fix.h <<EOF\nint x;\nEOF\nmake",
    "python3 -c \"open('src/a.f','w').write('x')\" && make",
    "cp stub.c src/stub.c && make",
    "perl -pi -e 's/a/b/' src/a.f && make",
])
def test_in_place_editing_in_the_build_step_is_refused(tmp_path, build):
    repo = patched_report(tmp_path, recipe_text=recipe(build=build), commands=(build,))
    assert result(repo)["patch"]["kind"] == "source"
    force_kind(repo)                                             # someone writes build-only by hand
    assert any("edits files in place" in v for v in gates.violations(repo))


@pytest.mark.parametrize("build", [BUILD, "make -j2 > build.log 2>&1", "g++ -I../Src ex.cpp -o ex.exe -lntl", "./configure --prefix=/x && make install"])
def test_ordinary_build_commands_are_not_flagged(build):
    assert vs.suspicious(build) == []


def test_recipe_must_call_the_manifest_tool_three_times(tmp_path):
    repo = patched_report(tmp_path, recipe_text=recipe(calls=2))
    assert result(repo)["patch"]["kind"] == "source"
    force_kind(repo)
    assert any("exactly three times" in v for v in gates.violations(repo))


def test_recorded_build_command_must_be_in_the_recipe_between_the_manifests(tmp_path):
    repo = patched_report(tmp_path, commands=("make something-else",))
    assert result(repo)["patch"]["kind"] == "source"
    force_kind(repo)
    assert any("not found between the second and third" in v for v in gates.violations(repo))


def test_build_commands_are_required(tmp_path):
    repo = patched_report(tmp_path, commands=())
    assert result(repo)["patch"]["kind"] == "source"


# ---- records cannot claim more than the manifests show --------------------------------------
def test_a_record_that_hides_a_change_is_caught(tmp_path):
    repo = patched_report(tmp_path, mid={**SRC, "src/a.f": "tampered\n"})
    force_kind(repo, ours={"modified": [], "removed": [], "added": []})
    bad = gates.violations(repo)
    assert any("does not match the pre and mid manifests" in v for v in bad) and any("changed source files before the build" in v for v in bad)


def test_an_edited_manifest_is_caught_by_the_recorded_numbers(tmp_path):
    repo = patched_report(tmp_path)
    mid = repo / "reports/p1/evidence/manifest.mid"
    mid.write_text("".join(mid.read_text().splitlines(True)[:-1]))
    assert any("does not match the pre and mid manifests" in v for v in gates.violations(repo))


def test_a_wrong_tool_record_is_caught(tmp_path):
    repo = patched_report(tmp_path, post=TOOL_POST)
    r = result(repo)
    r["patch"]["tool"] = {"modified": [], "removed": [], "added": []}
    (repo / "reports/p1/result.json").write_text(json.dumps(r))
    assert any("patch.tool does not match" in v for v in gates.violations(repo))


def test_archive_hash_must_be_the_registered_one(tmp_path):
    repo = patched_report(tmp_path)
    r = result(repo)
    r["patch"]["archive_sha256"] = "cd" * 32
    (repo / "reports/p1/result.json").write_text(json.dumps(r))
    assert any("archive_sha256 must equal" in v for v in gates.violations(repo))


def test_only_a_patched_basis_can_be_build_only(tmp_path):
    repo = patched_report(tmp_path)
    r = result(repo)
    r["basis"] = "reimplemented"
    (repo / "reports/p1/result.json").write_text(json.dumps(r))
    assert any("belongs to basis patched" in v for v in gates.violations(repo))


def test_missing_manifest_is_reported(tmp_path):
    repo = patched_report(tmp_path)
    (repo / "reports/p1/evidence/manifest.post").unlink()
    assert any("manifest.post" in v for v in gates.violations(repo))


def test_an_old_two_manifest_record_of_kind_source_still_needs_the_paper_check(tmp_path):
    repo = patched_report(tmp_path, record=False)
    r = result(repo)
    r["patch"] = {"kind": "source", "modified": ["a"], "added": [], "removed": [], "compared": 3}
    (repo / "reports/p1/result.json").write_text(json.dumps(r))
    assert any("G2 fidelity not passed" in v for v in gates.violations(repo))


def test_cli_record_exit_code_follows_the_kind(tmp_path):
    repo = patched_report(tmp_path, record=False)
    pre, mid, post = (tmp_path / f"m.{n}" for n in ("pre", "mid", "post"))
    args = ["record", "--repo", str(repo), "--id", "p1", "--pre", str(pre), "--mid", str(mid), "--post", str(post), "--command", BUILD]
    assert vs.main(args) == 0
    mid.write_text(vs.render({**vs.parse(mid.read_text()), "src/a.f": "0" * 64}))
    assert vs.main(args) == 2
