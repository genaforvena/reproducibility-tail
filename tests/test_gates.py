import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "checks"))
sys.path.insert(0, str(ROOT / "tools"))
import build_ledger  # noqa: E402
import gates  # noqa: E402


def git(repo, *a):
    subprocess.run(["git", "-C", str(repo), *a], check=True, capture_output=True,
                   env={"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
                        "GIT_COMMITTER_EMAIL": "t@t", "PATH": "/usr/bin:/bin", "HOME": str(repo)})


def make(tmp_path, **over):
    repo = tmp_path / "r"
    (repo / "queue").mkdir(parents=True)
    (repo / "reports" / "p1" / "logs").mkdir(parents=True)
    git(repo.parent, "init", "-q", str(repo))
    (repo / "queue" / "p1.json").write_text('{"claim": "x"}')
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "q")
    qc = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H", "--", "queue/p1.json"],
                        capture_output=True, text=True).stdout.strip()
    (repo / "reports" / "p1" / "recipe.sh").write_text("#!/bin/sh\n")
    (repo / "reports" / "p1" / "logs" / "orig.log").write_text("failed to build\n")
    r = {"claim": {"text": "t", "values": [{"name": "v", "paper": 7.0, "tol_abs": 0.5, "ours": 7.05}]},
         "paper": {"short": "P", "year": 2011}, "field": "bio", "stack": "R",
         "basis": "reimplemented", "verdict": "reproduced", "queue_commit": qc,
         "recipe": "reports/p1/recipe.sh",
         "original_attempt": {"tried": True, "outcome": "failed", "reason": "no R", "log": "reports/p1/logs/orig.log"},
         "gates": {"G1": "pass", "G2": "pass", "G3": "pass", "cross_check": "pass"}}
    r.update(over)
    (repo / "reports" / "p1" / "result.json").write_text(json.dumps(r))
    return repo


def test_clean_report_passes(tmp_path):
    assert gates.violations(make(tmp_path)) == []


def test_prose_only_report_is_a_violation(tmp_path):
    repo = make(tmp_path)
    (repo / "reports" / "p1" / "result.json").unlink()
    assert any("no result.json" in v for v in gates.violations(repo))


def test_wrong_verdict_is_caught(tmp_path):
    bad = gates.violations(make(tmp_path, verdict="not-reproduced"))
    assert any("G4" in v for v in bad)


def test_moved_goalposts_are_caught(tmp_path):
    repo = make(tmp_path)
    (repo / "queue" / "p1.json").write_text('{"claim": "friendlier"}')
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "edit claim")
    assert any("G0" in v for v in gates.violations(repo))


def test_reimplemented_without_original_attempt_is_caught(tmp_path):
    bad = gates.violations(make(tmp_path, original_attempt={"tried": False}))
    assert any("G1" in v for v in bad)


def test_failed_original_needs_its_log(tmp_path):
    repo = make(tmp_path)
    (repo / "reports" / "p1" / "logs" / "orig.log").unlink()
    assert any("no log" in v for v in gates.violations(repo))


def test_not_reproduced_needs_second_pass_and_cause(tmp_path):
    over = {"claim": {"text": "t", "values": [{"name": "v", "paper": 7.0, "tol_abs": 0.5, "ours": 9.0}]},
            "verdict": "not-reproduced"}
    bad = gates.violations(make(tmp_path, **over))
    assert any("G6" in v for v in bad) and any("cause" in v for v in bad)


@pytest.mark.parametrize("ours,verdict", [(7.2, "reproduced"), (9.0, "not-reproduced"), (None, "blocked")])
def test_judge_is_pure_arithmetic(ours, verdict):
    assert build_ledger.judge([{"paper": 7.0, "tol_abs": 0.5, "ours": ours}]) == verdict


def test_grades(tmp_path):
    repo = make(tmp_path)
    r = json.loads((repo / "reports" / "p1" / "result.json").read_text())
    assert build_ledger.grade(r) == "C"
    r["gates"]["cross_check"] = "na"
    assert build_ledger.grade(r) == "D"
    r["basis"] = "original"
    assert build_ledger.grade(r) == "A"


def test_ledger_roundtrip_and_check(tmp_path):
    repo = make(tmp_path)
    assert build_ledger.main(["--repo", str(repo), "--check"]) == 2   # no ledger yet
    assert build_ledger.main(["--repo", str(repo)]) == 0
    assert build_ledger.main(["--repo", str(repo), "--check"]) == 0
    (repo / "ledger.md").write_text("hand edited")
    assert build_ledger.main(["--repo", str(repo), "--check"]) == 2
