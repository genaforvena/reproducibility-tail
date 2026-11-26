import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "checks"))
import build_ledger  # noqa: E402
import frame_sample  # noqa: E402

spec = importlib.util.spec_from_file_location("funnel", ROOT / "checks" / "funnel.py")
funnel = importlib.util.module_from_spec(spec)
spec.loader.exec_module(funnel)

ITEMS = ["cpc-a", "cpc-b", "cpc-c", "cpc-d", "cpc-e"]


def repo_with_frame(tmp_path, sampled=True, n=4, seed=3):
    repo = tmp_path / "r"
    (repo / "queue" / "frames").mkdir(parents=True)
    (repo / "reports").mkdir()
    (repo / "queue" / "frames" / "cpc.json").write_text(json.dumps({"name": "cpc", "items": ITEMS}))
    if sampled:
        assert frame_sample.main(["--repo", str(repo), "--frame", "cpc", "--n", str(n), "--seed", str(seed)]) == 0
    return repo


def order(repo):
    return json.loads((repo / "queue" / "frames" / "cpc.sample.json").read_text())["order"]


def line(i, outcome="rejected", **kw):
    d = {"frame": "cpc", "index": i, "item": ITEMS[i - 1], "utc": "2026-11-26T14:00:00Z", "outcome": outcome,
         "reason": "runtime", "detail": "needs 40 CPU hours", "stack": "Fortran", "year": 1998}
    d.update(kw)
    return d


def write(repo, *lines):
    (repo / "queue" / "funnel.jsonl").write_text("".join(json.dumps(x) + "\n" for x in lines))


def test_sampling_is_deterministic_and_cannot_be_redrawn(tmp_path):
    assert frame_sample.draw(ITEMS, 4, 3) == frame_sample.draw(ITEMS, 4, 3)
    repo = repo_with_frame(tmp_path)
    assert frame_sample.main(["--repo", str(repo), "--frame", "cpc", "--n", "4", "--seed", "99"]) == 3


def test_candidates_in_drawn_order_pass(tmp_path):
    repo = repo_with_frame(tmp_path)
    o = order(repo)
    write(repo, line(o[0]), line(o[1], outcome="unreachable", reason="unreachable-code", detail="library offline",
                                 checked=["software-heritage", "wayback"], evidence="404 on 2026-11-26"))
    assert funnel.violations(repo) == []


def test_skipping_a_drawn_candidate_is_caught(tmp_path):
    repo = repo_with_frame(tmp_path)
    o = order(repo)
    write(repo, line(o[1]))               # considered the second drawn item, never the first
    assert any("none skipped" in v for v in funnel.violations(repo))


def test_unreachable_needs_two_fallbacks_and_evidence(tmp_path):
    repo = repo_with_frame(tmp_path)
    o = order(repo)
    write(repo, line(o[0], outcome="unreachable", reason="unreachable-code", detail="gone", checked=["wayback"]))
    assert any("two fallbacks" in v for v in funnel.violations(repo))


def test_reason_must_come_from_the_list(tmp_path):
    repo = repo_with_frame(tmp_path)
    write(repo, line(order(repo)[0], reason="felt hard"))
    assert any("rejection reason" in v for v in funnel.violations(repo))


def test_item_must_match_the_frame(tmp_path):
    repo = repo_with_frame(tmp_path)
    write(repo, line(order(repo)[0], item="something-else"))
    assert any("do not match" in v for v in funnel.violations(repo))


def test_unsampled_frame_and_registered_without_entry(tmp_path):
    repo = repo_with_frame(tmp_path, sampled=False)
    write(repo, line(1))
    assert any("not been sampled" in v for v in funnel.violations(repo))
    repo2 = repo_with_frame(tmp_path / "b")
    write(repo2, line(order(repo2)[0], outcome="registered", id="nope"))
    assert any("does not exist" in v for v in funnel.violations(repo2))


def test_legacy_rejection_log_is_a_violation(tmp_path):
    repo = repo_with_frame(tmp_path)
    (repo / "queue" / "rejected.md").write_text("# Rejected\n\n- some paper: paywalled\n")
    assert any("rejected.md" in v for v in funnel.violations(repo))


def test_ledger_funnel_section_counts_and_lists_unreachable(tmp_path):
    repo = repo_with_frame(tmp_path)
    o = order(repo)
    (repo / "queue" / "p1.json").write_text("{}")
    write(repo, line(o[0], outcome="registered", id="p1", stack="R"),
          line(o[1], outcome="unreachable", reason="unreachable-code", detail="library offline",
               checked=["software-heritage", "wayback"], evidence="x", paper="Smith 1998"),
          line(o[2]))
    text = build_ledger.build(repo)
    assert "3 candidates considered from 1 of 1 frames: 1 attempted (33%), 1 unreachable, 1 rejected" in text
    assert "Smith 1998" in text and "| runtime | 1 |" in text
    assert "| cpc | 5 | 4 | 3 | 75% |" in text


def test_unknown_stack_is_a_violation_not_stated_is_fine(tmp_path):
    repo = repo_with_frame(tmp_path)
    write(repo, line(order(repo)[0], stack="unknown"))
    assert any("stack must be one of" in v for v in funnel.violations(repo))
    write(repo, line(order(repo)[0], stack="not-stated"))
    assert funnel.violations(repo) == []


def test_new_reasons_exist(tmp_path):
    repo = repo_with_frame(tmp_path)
    o = order(repo)
    write(repo, line(o[0], reason="stochastic-no-seed"), line(o[1], reason="no-code"))
    assert funnel.violations(repo) == []


def test_registered_claim_may_sit_in_withdrawn(tmp_path):
    repo = repo_with_frame(tmp_path)
    (repo / "queue" / "withdrawn").mkdir()
    (repo / "queue" / "withdrawn" / "p1.json").write_text("{}")
    write(repo, line(order(repo)[0], outcome="registered", id="p1"))
    assert funnel.violations(repo) == []


def test_extending_a_draw_keeps_the_old_order_and_adds_new_items(tmp_path):
    repo = repo_with_frame(tmp_path, n=2)
    before = order(repo)
    assert frame_sample.main(["--repo", str(repo), "--frame", "cpc", "--extend", "2"]) == 0
    after = order(repo)
    assert after[:2] == before and len(after) == 4 and len(set(after)) == 4
    # deterministic: the same extension of the same draw gives the same items
    assert frame_sample.extend(ITEMS, before, 3, 2) == frame_sample.extend(ITEMS, before, 3, 2)
    # the funnel check follows the extended order, still with none skipped
    write(repo, line(after[0]), line(after[1]), line(after[2]))
    assert funnel.violations(repo) == []
    write(repo, line(after[0]), line(after[1]), line(after[3]))
    assert any("none skipped" in v for v in funnel.violations(repo))


def test_extend_needs_an_existing_draw(tmp_path):
    repo = repo_with_frame(tmp_path, sampled=False)
    assert frame_sample.main(["--repo", str(repo), "--frame", "cpc", "--extend", "2"]) == 3
