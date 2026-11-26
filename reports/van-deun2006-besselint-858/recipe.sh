#!/usr/bin/env bash
# Rebuilds the rerun verdict for van-deun2006-besselint-858 (basis: patched).
# Fetch (--fetch steps only touch the network): netlib TOMS 858.zip (sha256 checked), micromamba, and
# GNU Octave 10.3.0 from conda-forge into the sandbox scratch. Everything else runs through tools/sandbox.sh.
# The authors' experiments.m and besselint.m / igamma.m are run unmodified (no edits, no new code).
# Patch (the basis): the relocated conda Octave does not find its own m-library, so `repmat` is undefined
# (original attempt, kept in evidence/original-attempt.log). The fix is a search path to Octave's m/ tree.
# Claim: the printed I for Example 5.1, compared with the shipped reference (evidence/reference/experiments.out).
set -uo pipefail
ID=van-deun2006-besselint-858
URL=https://netlib.org/toms/858.zip
SHA=63ed546d228e687e54ceed3dfeeb5d0bd82497477ddf545db6c7a8458af57431
REFSHA=0d7e39866c8d4c2b3fac3013fb30da94fb583762743cd292710e24ff82e2b4f0
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
mkdir -p "$root/reports/$ID/evidence/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 858.zip, micromamba, Octave"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/858.zip '$URL' && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba && /work/mm/bin/micromamba create -y -r /work/mm/root -p /work/oct -c conda-forge --override-channels octave unzip" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/858.zip' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src && /work/oct/bin/unzip -oq /work/858.zip -d /work/src" || { echo "UNZIP-FAILED"; exit 1; }

echo "== shipped reference (the oracle), copied into the report and hash-checked"
tools/sandbox.sh "$ID" -- sh -c "/work/oct/bin/unzip -p /work/858.zip 858/Matlab/Dp/Drivers/experiments.out" > "$root/reports/$ID/evidence/reference/experiments.out" || { echo "REF-FAILED"; exit 1; }
echo "$REFSHA  reports/$ID/evidence/reference/experiments.out" | sha256sum -c - || { echo "REF-SHA-FAILED"; exit 1; }

DRV="cd /work/src/858/Matlab/Dp/Drivers && export PATH=/work/oct/bin:\$PATH"
PATCH="addpath(genpath('/work/oct/share/octave/10.3.0/m')); addpath('../Src'); experiments"

# G1: the authors' artifact as documented, unpatched. The first attempt's log is kept and never overwritten.
ORIG="$root/reports/$ID/evidence/original-attempt.log"
if [ ! -s "$ORIG" ]; then
  echo "== G1 original attempt (unpatched driver under Octave)"
  tools/sandbox.sh "$ID" -- sh -c "$DRV && timeout 900 octave --no-gui --no-window-system --quiet --eval \"addpath('../Src'); experiments\" > /work/original-run.log 2>&1; echo exit=\$?; cat /work/original-run.log" > "$ORIG" 2>&1
  tail -4 "$ORIG"
fi

# Patched run, twice (G3): the authors' driver with the Octave m-library on the path.
for i in 1 2; do
  echo "== driver run $i (patched search path)"
  tools/sandbox.sh "$ID" -- sh -c "$DRV && timeout 1500 octave --no-gui --no-window-system --quiet --eval \"$PATCH\" > /work/run$i.log 2>&1; echo exit=\$?"
  cp "$W/run$i.log" "$root/reports/$ID/evidence/run$i.log" && gzip -f "$root/reports/$ID/evidence/run$i.log"
done

# G5 contract: the VALUE line comes from the second driver run; Ex. 5.1 is the I printed after its header.
val=$(awk '/^Ex\. 5\.1:/{f=1} f && /^I =/{print $3; exit}' "$W/run2.log")
echo "VALUE I_Ex5_1 ${val:-NONE}"
