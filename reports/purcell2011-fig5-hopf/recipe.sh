#!/usr/bin/env bash
# Rebuilds the rerun verdict for purcell2011-fig5-hopf (basis: reimplemented; original attempt not-possible, see attempt-1-result.md).
# 1. fetch the pinned replication repo and read its parameters (src/parameters/network.mat);
#    the replication's code is NOT executed.
# 2. install numpy outside the sandbox (fetch step only), copy it into the scratch dir;
# 3. run the reimplementation (impl/*.py, CC0) only through tools/sandbox.sh.
set -euo pipefail
ID=purcell2011-fig5-hopf
SHA=3ab84df2d34f67dd66929848fc154fef2185d10a
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID   # the sandbox binds this as /work
mkdir -p "$W"

if [ ! -d "$W/recipe-check/repo" ]; then
  git clone -q https://github.com/baioc/re-multif "$W/recipe-check/repo"
fi
git -C "$W/recipe-check/repo" checkout -q "$SHA"
test "$(git -C "$W/recipe-check/repo" rev-parse HEAD)" = "$SHA"
cp "$W/recipe-check/repo/src/parameters/network.mat" "$W/network.mat"

if [ ! -d "$W/pylib/numpy" ]; then
  python3 -m venv "$W/venv"
  "$W/venv/bin/pip" install -q numpy
  sp=$(ls -d "$W"/venv/lib/python3*/site-packages)
  mkdir -p "$W/pylib"
  cp -r "$sp/numpy" "$sp/numpy.libs" "$W"/pylib/
  cp -r "$sp"/numpy-*.dist-info "$W/pylib/"
fi
mkdir -p "$W/impl"
cp "$here"/impl/*.py "$W/impl/"

S="$root/tools/sandbox.sh $ID -- /usr/bin/env PYTHONPATH=/work/pylib /usr/bin/python3 /work/impl"
# Table 1 of the paper (PLOS ONE, doi:10.1371/journal.pone.0016140.t001) gives the exact activator and
# repressor constants as (1E-10)^(1/1.3) and (1E-12)^(1/1.3) M; network.mat stores them rounded (2e-8, 6e-10).
# The registered spec is the paper's Table 1, so the exact values are the primary run; the rounded
# network.mat values are kept as a sensitivity run.
KA=$(python3 -c "print(repr((1e-10)**(1/1.3)))"); KR=$(python3 -c "print(repr((1e-12)**(1/1.3)))")
sed -e "/name: k_a/{n;s/.*/$KA/}" -e "/name: k_r/{n;s/.*/$KR/}" "$W/network.mat" > "$W/network_exact.mat"
{
  echo "## PRIMARY (paper Table 1 exact kA, kR): Hopf, full model, continuation from I=9 nM downward"
  $S/continue_branch.py /work/network_exact.mat full 9 12 0.005 -1
  echo "## sensitivity (network.mat rounded kA, kR): Hopf, full model, from I=9 nM downward"
  echo "## Hopf, full model: continuation from I=9 nM downward"
  $S/continue_branch.py /work/network.mat full 9 12 0.005 -1
  echo "## Hopf, full model: continuation from I=9 nM upward"
  $S/continue_branch.py /work/network.mat full 9 12 0.005 1
  echo "## Hopf, QSSA model (secondary): from I=9 nM downward"
  $S/continue_branch.py /work/network.mat qssa 9 12 0.005 -1
  echo "## fold check, full model: from I=0 nM upward (paper's saddle-node ~0.4 nM)"
  $S/continue_branch.py /work/network.mat full 0 1.5 0.002 1
  echo "## time-domain check, full model: 6.5 and 7.5 nM, 1.5e6 s"
  $S/check_time_domain.py /work/network.mat 6.5 7.5 1.5e6
} 2>&1 | grep -v Warn | tee "$W/sandbox-run.log"
echo "log: $W/sandbox-run.log"
