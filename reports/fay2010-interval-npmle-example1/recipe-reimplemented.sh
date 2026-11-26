#!/usr/bin/env bash
# Superseded as canonical by recipe.sh (basis original). Kept as the cross-check: a Turnbull EM reimplementation.
# Rebuilds the rerun verdict for fay2010-interval-npmle-example1 (basis: reimplemented).
# No data download: the seven rows are typed in the paper (JSS p. 29) and in impl/npmle_em.py.
# Copies impl/npmle_em.py into the scratch dir and runs it only through tools/sandbox.sh.
set -euo pipefail
ID=fay2010-interval-npmle-example1
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W/impl"
cp "$here/impl/npmle_em.py" "$W/impl/"
cd "$root"
tools/sandbox.sh "$ID" -- python3 -I /work/impl/npmle_em.py
