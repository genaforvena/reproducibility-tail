import datetime
import importlib.util
import json
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "checks"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import replay  # noqa: E402
from test_gates import make  # noqa: E402

spec = importlib.util.spec_from_file_location("replay_due", ROOT / "checks" / "replay-due.py")
replay_due = importlib.util.module_from_spec(spec)
spec.loader.exec_module(replay_due)

NOW = datetime.datetime(2026, 12, 1, 12, 0, tzinfo=datetime.timezone.utc)


def recipe(repo, body):
    p = repo / "reports" / "p1" / "recipe.sh"
    p.write_text("#!/bin/sh\n" + body)
    return p


def run(repo, tmp_path, *extra):
    return replay.main(["--repo", str(repo), "--id", "p1", "--scratch", str(tmp_path / "scratch"),
                        "--min-free-gib", "0", *extra])


def entry(repo):
    return json.loads((repo / "reports" / "p1" / "result.json").read_text())["replayed"][-1]


def test_agreeing_replay_is_recorded_and_ledger_rebuilt(tmp_path):
    repo = make(tmp_path)
    recipe(repo, "echo noise\necho VALUE v 7.05\n")
    assert run(repo, tmp_path) == 0
    e = entry(repo)
    assert e["kind"] == "clean" and e["ok"] and e["values"] == {"v": 7.05}
    assert (repo / e["log"]).is_file()
    r = json.loads((repo / "reports" / "p1" / "result.json").read_text())
    assert r["gates"]["G5"] == "pass"
    assert "ok" in (repo / "ledger.md").read_text()


def test_a_different_value_is_a_change_even_inside_tolerance(tmp_path):
    repo = make(tmp_path)
    recipe(repo, "echo VALUE v 7.2\n")
    assert run(repo, tmp_path) == 2
    assert not entry(repo)["ok"] and "differs" in entry(repo)["why"]


def test_value_outside_tolerance_fails(tmp_path):
    repo = make(tmp_path)
    recipe(repo, "echo VALUE v 9.0\n")
    assert run(repo, tmp_path) == 2
    assert "tolerance" in entry(repo)["why"]


def test_recipe_without_value_lines_fails(tmp_path):
    repo = make(tmp_path)
    recipe(repo, "echo done\n")
    assert run(repo, tmp_path) == 2
    assert "no VALUE line" in entry(repo)["why"]


def test_timeout_is_a_failed_replay_not_a_hang(tmp_path):
    repo = make(tmp_path)
    recipe(repo, "sleep 30\necho VALUE v 7.05\n")
    assert run(repo, tmp_path, "--timeout", "1") == 2
    assert "exited 124" in entry(repo)["why"]


def test_scratch_is_wiped_before_the_run(tmp_path):
    repo = make(tmp_path)
    old = tmp_path / "scratch" / "p1"
    old.mkdir(parents=True)
    (old / "leftover").write_text("x")
    body = f'test ! -e "{old}/leftover" && echo VALUE v 7.05\n'
    recipe(repo, body)
    assert run(repo, tmp_path) == 0
    assert not old.exists()           # and nothing is left in flight afterwards


def test_refuses_when_the_drive_is_below_the_floor(tmp_path):
    repo = make(tmp_path)
    recipe(repo, "echo VALUE v 7.05\n")
    assert replay.main(["--repo", str(repo), "--id", "p1", "--scratch", str(tmp_path / "s"),
                        "--min-free-gib", "999999"]) == 3


def test_only_reproduced_results_are_replayed(tmp_path):
    repo = make(tmp_path, claim={"text": "t", "values": [{"name": "v", "paper": 7.0, "tol_abs": 0.5, "ours": None}]},
                verdict="blocked")
    assert run(repo, tmp_path) == 3


def stamp(days_ago):
    return (NOW - datetime.timedelta(days=days_ago)).strftime("%Y-%m-%dT%H:%M:%SZ")


@pytest.mark.parametrize("replayed,expect", [
    ([], "never replayed clean"),
    ([{"utc": stamp(1), "ok": True}], "never replayed clean"),                  # not a clean replay
    ([{"utc": stamp(1), "kind": "clean", "ok": True}], None),
    ([{"utc": stamp(9), "kind": "clean", "ok": True}], "older than"),
    ([{"utc": stamp(1), "kind": "clean", "ok": False}], "CHANGED"),
    ([{"utc": stamp(3), "kind": "clean", "ok": False}, {"utc": stamp(1), "kind": "clean", "ok": True}], None),
])
def test_replay_due_detector(tmp_path, replayed, expect):
    repo = make(tmp_path, replayed=replayed)
    found = replay_due.findings(repo, NOW)
    assert (not found) if expect is None else any(expect in line for line in found)


def test_detector_ignores_results_that_are_not_reproduced(tmp_path):
    repo = make(tmp_path, claim={"text": "t", "values": [{"name": "v", "paper": 7.0, "tol_abs": 0.5, "ours": 9.0}]},
                verdict="not-reproduced")
    assert replay_due.findings(repo, NOW) == []
