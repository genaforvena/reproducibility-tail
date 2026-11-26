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
         "paper": {"short": "P", "year": 2011}, "field": "bio", "stack": "R", "field_class": "biology", "stack_class": "R",
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


@pytest.mark.parametrize("ours,cell", [(7.05, "10%"), (7.4, "80% ⚠"), (7.5, "100% ⚠"), (None, "–")])
def test_margin_cell(ours, cell):
    assert build_ledger.margin_cell(ours, 7.0, 0.5) == cell


def test_margin_cell_for_a_value_that_was_not_produced_is_a_dash():
    assert build_ledger.margin_cell(None, 7.0, 0) == "–" and build_ledger.margin_cell(7.0, None, 0.5) == "–"


def test_ledger_shows_margin_column(tmp_path):
    repo = make(tmp_path)
    build_ledger.main(["--repo", str(repo)])
    text = (repo / "ledger.md").read_text()
    assert "| margin |" in text and "10%" in text


def test_withdrawn_claim_moved_not_deleted_still_passes(tmp_path):
    repo = make(tmp_path)
    (repo / "queue" / "withdrawn").mkdir()
    (repo / "queue" / "p1.json").rename(repo / "queue" / "withdrawn" / "p1.json")
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "withdraw p1")
    assert gates.violations(repo) == []


def test_withdrawn_claim_edited_after_the_run_is_caught(tmp_path):
    repo = make(tmp_path)
    (repo / "queue" / "withdrawn").mkdir()
    (repo / "queue" / "p1.json").rename(repo / "queue" / "withdrawn" / "p1.json")
    (repo / "queue" / "withdrawn" / "p1.json").write_text('{"claim": "friendlier"}')
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "withdraw and edit")
    assert any("G0" in v for v in gates.violations(repo))


def test_deleting_the_claim_is_caught(tmp_path):
    repo = make(tmp_path)
    (repo / "queue" / "p1.json").unlink()
    assert any("no queue/p1.json" in v for v in gates.violations(repo))


def test_original_basis_needs_the_original_to_have_run_as_documented(tmp_path):
    bad = gates.violations(make(tmp_path, basis="original",
                                original_attempt={"tried": True, "outcome": "partial", "reason": "halts at G=4",
                                                  "log": "reports/p1/logs/orig.log"}))
    assert any("does not fit" in v for v in bad)


def test_patched_basis_fits_a_partial_original(tmp_path):
    assert gates.violations(make(tmp_path, basis="patched",
                                 original_attempt={"tried": True, "outcome": "partial", "reason": "workaround",
                                                   "log": "reports/p1/logs/orig.log"})) == []


def test_reimplemented_basis_does_not_fit_a_succeeded_original(tmp_path):
    bad = gates.violations(make(tmp_path, original_attempt={"tried": True, "outcome": "succeeded", "reason": "ran",
                                                            "log": "reports/p1/logs/orig.log"}))
    assert any("does not fit" in v for v in bad)


def test_unknown_original_outcome_is_caught(tmp_path):
    bad = gates.violations(make(tmp_path, original_attempt={"tried": True, "outcome": "sort-of", "reason": "x"}))
    assert any("G1 needs original_attempt" in v for v in bad)


def test_stack_and_field_classes_are_required(tmp_path):
    bad = gates.violations(make(tmp_path, stack_class="R 4.5.3 in a sandbox", field_class="statistical thing"))
    assert any("stack_class" in v for v in bad) and any("field_class" in v for v in bad)


def test_exact_claims_show_exact_not_a_dash():
    assert build_ledger.margin_cell(3, 3, 0) == "exact" and build_ledger.margin_cell(3, 4, 0) == "off"


def test_ledger_uses_classes_not_free_text(tmp_path):
    repo = make(tmp_path)
    text = build_ledger.build(repo)
    assert "By stack: R 1" in text and "By field: biology 1" in text
