#!/usr/bin/env bash
# Superseded as canonical by recipe.sh (basis original). Kept as the cross-check: a Python port of BB (impl/bb_port.py).
# 1. fetch the pinned CRAN archive BB_2009.9-1.tar.gz and check its sha256 (the source
#    the port was read from; the tarball is NOT executed);
# 2. copy impl/*.py into the scratch dir and run it only through tools/sandbox.sh.
set -euo pipefail
ID=varadhan2009-bb-hdp-multistart
SHA=e6b145bda50727838623442e1dc7985b1e9806c68371bf542c600209394ac88e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W/src" "$W/impl"
if [ ! -f "$W/src/BB.tar.gz" ]; then
  curl -sL -o "$W/src/BB.tar.gz" https://cran.r-project.org/src/contrib/Archive/BB/BB_2009.9-1.tar.gz
fi
echo "$SHA  $W/src/BB.tar.gz" | sha256sum -c -
cp "$here/impl/bb_port.py" "$here/impl/check_roots.py" "$W/impl/"
cd "$root"
tools/sandbox.sh "$ID" -- python3 -I /work/impl/bb_port.py --self-test
tools/sandbox.sh "$ID" -- python3 -I /work/impl/bb_port.py
