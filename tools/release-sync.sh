#!/bin/sh
# Carry this plant's own files into its pinned release and re-render ONLY its units.
# The running code, duties.json and check scripts are read from the release, not the
# checkout, so a committed change goes live only through this step.
# Never run a bare `mishe sync` on this host: it renders the default mishe-* namespace.
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
site=$repo/.mishe-tauftauf
rel=$site/runtime/current
cp "$repo/duties.json" "$rel/duties.json"
cp "$repo"/checks/*.py "$rel/checks/"
cp "$repo/tools/build_ledger.py" "$repo/tools/frame_sample.py" "$repo/tools/verify_sources.py" "$rel/tools/"
env -u MISHE_TAUFTAUF_HOME MISHE_SEED_HOME="$site" MISHE_REPO="$repo" PYTHONPATH="$rel/src" \
  /home/mesh-home/mishe-tauftauf/.venv/bin/python -m mishe_tauftauf --home "$site" \
  sync --repo "$repo" --pythonpath "$rel/src" --prefix rtail --unit-dir "$HOME/.config/systemd/user"
systemctl --user daemon-reload
