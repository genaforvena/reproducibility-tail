"""Exact-string claims: a string paper judged character for character (docs/method.md, 'Exact-string claims').

Narrow by design: only a string `paper` whose `tol_abs` is half a unit in its last printed decimal qualifies.
Numeric claims keep the arithmetic path; a string paper that does not qualify is never a pass.
"""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "checks"))
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_ledger  # noqa: E402
import gates  # noqa: E402
import replay  # noqa: E402
from test_gates import git, make  # noqa: E402

SQRT3 = "1.7320508075688772935274463415058723669428"  # 40 decimals, as registered for smith1991-fmpack-693
TOL = 5e-41
NAME = "SQRT(3) to 40 decimal places"


def value(ours, paper=SQRT3, tol=TOL, name=NAME):
    return {"name": name, "paper": paper, "tol_abs": tol, "ours": ours}


def test_identical_string_is_reproduced():
    assert build_ledger.judge([value(SQRT3)]) == "reproduced"


def test_one_digit_different_is_not_reproduced():
    wrong = SQRT3[:-1] + ("7" if SQRT3[-1] != "7" else "8")
    assert build_ledger.judge([value(wrong)]) == "not-reproduced"


def test_one_digit_different_in_the_middle_is_not_reproduced():
    wrong = SQRT3[:20] + ("0" if SQRT3[20] != "0" else "1") + SQRT3[21:]
    assert build_ledger.judge([value(wrong)]) == "not-reproduced"


def test_truncated_string_is_not_reproduced():
    assert build_ledger.judge([value(SQRT3[:-1])]) == "not-reproduced"


def test_longer_string_is_not_reproduced():
    assert build_ledger.judge([value(SQRT3 + "0")]) == "not-reproduced"


def test_no_prefix_or_substring_match():
    assert build_ledger.judge([value(SQRT3[:10])]) == "not-reproduced"
    assert build_ledger.judge([value("x" + SQRT3)]) == "not-reproduced"


def test_surrounding_whitespace_is_not_trimmed():
    assert build_ledger.judge([value(" " + SQRT3)]) == "not-reproduced"


def test_missing_string_is_blocked():
    assert build_ledger.judge([value(None)]) == "blocked"


def test_a_number_is_not_a_string_result():
    assert build_ledger.judge([value(1.7320508075688772)]) == "not-reproduced"


def test_string_paper_without_exact_tolerance_is_never_a_pass():
    # '3.877' with a tolerance of 0.001 is not an exact-string claim: blocked, even when the strings are equal
    assert not build_ledger.exact_string_claim({"paper": "3.877", "tol_abs": 0.001})
    assert build_ledger.judge([{"name": "x", "paper": "3.877", "tol_abs": 0.001, "ours": "3.877"}]) == "blocked"


def test_string_paper_with_zero_tolerance_is_never_a_pass():
    assert build_ledger.judge([{"name": "x", "paper": "0.0", "tol_abs": 0, "ours": "0.0"}]) == "blocked"


def test_integer_string_is_not_an_exact_string_claim():
    assert not build_ledger.exact_string_claim({"paper": "4490", "tol_abs": 0.5})


def test_numeric_claims_are_unchanged():
    assert build_ledger.judge([{"name": "n", "paper": 1.0, "tol_abs": 0.1, "ours": 1.05}]) == "reproduced"
    assert build_ledger.judge([{"name": "n", "paper": 1.0, "tol_abs": 0.01, "ours": 1.05}]) == "not-reproduced"
    # the sentinel 0 / tol 0 numeric value stays the numeric path (IFAIL-style counts)
    assert build_ledger.judge([{"name": "IFAIL", "paper": 0, "tol_abs": 0, "ours": 0}]) == "reproduced"
    assert build_ledger.judge([{"name": "IFAIL", "paper": 0, "tol_abs": 0, "ours": 1}]) == "not-reproduced"


def test_ledger_cells_do_not_crash_on_a_string_claim():
    assert build_ledger.margin_cell(SQRT3, SQRT3, TOL) == "match"
    assert build_ledger.margin_cell(SQRT3[:-1], SQRT3, TOL) == "mismatch"


def test_gates_accept_an_exact_string_claim_registered_in_the_queue(tmp_path):
    repo = _registered(tmp_path, SQRT3, SQRT3)
    assert gates.violations(repo) == []


def test_gates_reject_an_exact_string_not_registered_in_the_queue(tmp_path):
    # the queue claim says a different string: the report may not carry a converted claim
    repo = _registered(tmp_path, SQRT3, SQRT3, queue_paper=SQRT3[:-1] + "0")
    assert any("not registered as a string" in v for v in gates.violations(repo))


def test_gates_reject_a_string_paper_that_is_not_an_exact_string_claim(tmp_path):
    repo = _registered(tmp_path, "3.877", "3.877", tol=0.001, name="SUM")
    assert any("every claim value needs" in v for v in gates.violations(repo))


def _registered(tmp_path, ours, paper, tol=TOL, name=NAME, queue_paper=None):
    repo = make(tmp_path, verdict="reproduced")
    claim = {"values": [{"name": name, "paper": queue_paper or paper, "tol_abs": tol}]}
    (repo / "queue" / "p1.json").write_text(json.dumps({"claim": claim}))
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "q2")
    qc = subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%H", "--", "queue/p1.json"],
                        capture_output=True, text=True).stdout.strip()
    r = json.loads((repo / "reports" / "p1" / "result.json").read_text())
    r["claim"] = {"text": "t", "values": [{"name": name, "paper": paper, "tol_abs": tol, "ours": ours}]}
    r["verdict"] = build_ledger.judge(r["claim"]["values"])
    r["queue_commit"] = qc
    (repo / "reports" / "p1" / "result.json").write_text(json.dumps(r))
    return repo


def test_replay_compares_the_printed_string_exactly():
    recorded = [value(SQRT3)]
    text = f"VALUE {NAME} {SQRT3}\n"
    new = replay.parse_values(text, recorded)
    assert new == {NAME: SQRT3}
    assert replay.agrees(recorded, new) == (True, "agrees with the record")


def test_replay_one_digit_different_does_not_agree():
    recorded = [value(SQRT3)]
    wrong = SQRT3[:-1] + ("7" if SQRT3[-1] != "7" else "8")
    new = replay.parse_values(f"VALUE {NAME} {wrong}\n", recorded)
    ok, why = replay.agrees(recorded, new)
    assert not ok and "outside the registered tolerance" in why


def test_replay_does_not_float_an_exact_string():
    # 40 digits do not survive float: the raw token must be kept, not parsed
    recorded = [value(SQRT3)]
    new = replay.parse_values(f"VALUE {NAME} {SQRT3}\n", recorded)
    assert isinstance(new[NAME], str)


def test_replay_missing_string_line_does_not_agree():
    recorded = [value(SQRT3)]
    ok, why = replay.agrees(recorded, replay.parse_values("VALUE other 1.0\n", recorded))
    assert not ok and "no VALUE line" in why
