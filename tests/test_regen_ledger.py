import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_gates import git, make  # noqa: E402


def setup(tmp_path):
    repo = make(tmp_path)
    (repo / "tools").mkdir()
    for f in ("regen-ledger.sh", "build_ledger.py"):
        (repo / "tools" / f).write_text((ROOT / "tools" / f).read_text())
    (repo / "tools" / "regen-ledger.sh").chmod(0o755)
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", "tools")
    return repo


def run(repo):
    return subprocess.run(["sh", str(repo / "tools" / "regen-ledger.sh"), str(repo)], capture_output=True, text=True,
                          env={"PATH": "/usr/bin:/bin", "HOME": str(repo), "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
                               "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"})


def head(repo):
    return subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()


def test_stale_ledger_is_regenerated_and_committed_once(tmp_path):
    repo = setup(tmp_path)
    before = head(repo)
    assert run(repo).returncode == 0
    after = head(repo)
    assert after != before
    assert (repo / "ledger.md").read_text().startswith("# Ledger")
    assert "ledger: regenerate" in subprocess.run(["git", "-C", str(repo), "log", "-1", "--format=%s"],
                                                  capture_output=True, text=True).stdout
    assert run(repo).returncode == 0 and head(repo) == after       # current: no second commit


def test_does_nothing_when_the_index_is_locked(tmp_path):
    repo = setup(tmp_path)
    before = head(repo)
    (repo / ".git" / "index.lock").write_text("")
    assert run(repo).returncode == 0 and head(repo) == before


def test_only_the_ledger_is_committed(tmp_path):
    repo = setup(tmp_path)
    (repo / "reports" / "p1" / "note.md").write_text("uncommitted work of a mind")
    run(repo)
    files = subprocess.run(["git", "-C", str(repo), "show", "--stat", "--format=", "HEAD"], capture_output=True,
                           text=True).stdout
    assert "ledger.md" in files and "note.md" not in files
