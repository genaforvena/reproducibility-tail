#!/usr/bin/env bash
# Rebuilds the evidence behind the blocked verdict: fetch the pinned replication
# repo and check whether its code (src/, experiments.py) contains any code that computes a Hopf bifurcation value.
# Octave is not run; the claim metric is absent from the artifact (see result.md).
set -euo pipefail
SHA=3ab84df2d34f67dd66929848fc154fef2185d10a
work="${1:-$(mktemp -d)}"
git clone -q https://github.com/baioc/re-multif "$work/repo"
git -C "$work/repo" checkout -q "$SHA"
test "$(git -C "$work/repo" rev-parse HEAD)" = "$SHA"
hits=$(grep -ril "hopf" "$work/repo/src" "$work/repo/experiments.py" || true)
doc=$(grep -ril "hopf" "$work/repo/doc" || true)
echo "prose mentions only (doc/): ${doc:-none}"
if [ -z "$hits" ]; then echo "no Hopf computation in pinned repo at $SHA"; else echo "$hits"; fi
