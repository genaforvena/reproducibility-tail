#!/bin/sh
# Keep ledger.md equal to what tools/build_ledger.py generates. Runs after every commit (from the
# post-commit hook): if the ledger is stale it is regenerated and committed on its own, so no mind
# is woken, and none needs to remember, to rebuild it. Silent no-op when the ledger is current,
# when a commit or rebase is in progress, or when the index is locked (the next commit retries).
# Usage: tools/regen-ledger.sh [REPO]
set -u
root=${1:-$(git rev-parse --show-toplevel 2>/dev/null)} || exit 0
cd "$root" || exit 0
git="$(git rev-parse --git-dir)"
[ -e "$git/index.lock" ] || [ -d "$git/rebase-merge" ] || [ -d "$git/rebase-apply" ] || [ -e "$git/MERGE_HEAD" ] && exit 0
python3 tools/build_ledger.py --repo "$root" --check >/dev/null 2>&1 && exit 0     # current: nothing to do
python3 tools/build_ledger.py --repo "$root" >/dev/null 2>&1 || exit 0              # cannot build: leave it to the gates
[ -n "$(git status --porcelain -- ledger.md)" ] || exit 0
git add -- ledger.md && git commit -q -m "ledger: regenerate from reports and funnel (post-commit hook)" -- ledger.md 2>/dev/null
exit 0
