#!/usr/bin/env bash
# Rebuilds and reruns the kim2012-sfsdp-920 check (TOMS 920, SFSDP: MATLAB sensor network localization; SDP via SDPA).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes, copies drivers and parses text.
#
# Prerequisites staged in the scratch directory by earlier --fetch steps (see evidence/env-notes.md):
#   /work/src/920          the netlib 920.zip archive, unzipped (sha256 checked here)
#   /work/oct8             conda-forge Octave 8.4 (Octave 10.3 fails: "No SOVERSION found in .mex file")
#   /work/fetch/root       Debian noble SDPA 7.3.16 + sdpam mex, scotch-int32 libs, extracted from the debs
#   /work/shim/spones.m    compatibility shim: MATLAB's spones (missing in conda Octave); basis patched
# The Octave run preloads the system reference BLAS/LAPACK: the conda liblapack (OpenBLAS) crashes inside the
# Debian sdpam mex (dscal_ -> dsdot_k_ZEN). OMP_NUM_THREADS=1.
#
# Two drivers (copied from impl/ into the scratch run/ directory, then run in the sandbox):
#   driver-manual-printed.m : the manual's printed inputs (distanceMatrix0, xMatrix0, eps 1e-7, minDegree 4, objSW 1, free 0)
#   driver-example1-shipped.m : shipped examples/example1.mat with noisyFac 0, eps 1e-5 (the manual's stated command)
# Claim (registered): SDP-stage 'rmsd = 6.21e-02' on the printed inputs, tol_abs 5e-4 (queue entry, fixed).
# Two passes (G3): the printed-input driver runs twice from fresh Octave processes (same inputs, no seed).
set -uo pipefail
ID=kim2012-sfsdp-920
ARCHIVE_URL=https://netlib.org/toms/920.zip
ARCHIVE_SHA=3399a98e19e9b57b8a20b6f087d677764e11eea6730abdd88c818b5bb5cffc3b
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
ENV='export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libblas.so.3:/usr/lib/x86_64-linux-gnu/liblapack.so.3 LD_LIBRARY_PATH=/work/fetch/root/usr/lib/x86_64-linux-gnu OMP_NUM_THREADS=1 PATH=/work/fetch/root/usr/bin:/work/oct8/bin:$PATH'
OCT='/work/oct8/bin/octave-cli --no-gui -q'
mkdir -p "$E" "$SCRATCH/run"
cd "$root"
exec > >(tee "$E/recipe-run.log") 2>&1

echo "== fetch: archive (sha256 checked) if absent from the scratch directory"
if [ ! -f "$SCRATCH/920.zip" ]; then
  tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/920.zip '$ARCHIVE_URL'" || { echo "FETCH-FAILED"; exit 1; }
fi
echo "$ARCHIVE_SHA  $SCRATCH/920.zip" | sha256sum -c - || { echo "ARCHIVE-SHA-MISMATCH"; exit 1; }
if [ ! -d "$SCRATCH/src/920" ]; then
  tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src && cd /work/src && python3 -c \"import zipfile;zipfile.ZipFile('/work/920.zip').extractall('.')\" && mv 920 920 2>/dev/null; ls /work/src" > "$E/unzip.log" 2>&1
fi

echo "== toolchain check: the staged env must be present (not rebuilt here)"
for p in "$SCRATCH/oct8/bin/octave-cli" "$SCRATCH/fetch/root/usr/share/sdpa/mex" "$SCRATCH/shim/spones.m"; do
  test -e "$p" && echo "present $p" || { echo "MISSING $p"; exit 1; }
done

echo "== copy drivers from impl/ into the scratch run directory"
cp "$here/impl/driver-manual-printed.m" "$here/impl/driver-example1-shipped.m" "$SCRATCH/run/"
cp "$here/impl/spones.m" "$SCRATCH/shim/spones.m"

echo "== pass 1: manual's printed inputs"
tools/sandbox.sh "$ID" -- sh -c "$ENV && $OCT /work/run/driver-manual-printed.m" > "$E/pass1-manual-printed.log" 2>&1
echo "pass1_exit=$?"
echo "== pass 2: same driver, fresh process"
tools/sandbox.sh "$ID" -- sh -c "$ENV && $OCT /work/run/driver-manual-printed.m" > "$E/pass2-manual-printed.log" 2>&1
echo "pass2_exit=$?"
echo "== shipped example1.mat (manual's stated command, noisyFac 0, eps 1e-5)"
tools/sandbox.sh "$ID" -- sh -c "$ENV && $OCT /work/run/driver-example1-shipped.m" > "$E/shipped-example1.log" 2>&1
echo "shipped_exit=$?"

echo "== values: first 'rmsd = ' line of each log (SDP stage)"
for f in pass1-manual-printed pass2-manual-printed shipped-example1; do
  printf '%s: ' "$f"; grep -m1 -o 'rmsd = [0-9.e+-]*' "$E/$f.log" || echo "no rmsd line"
done
P1=$(grep -m1 -o 'rmsd = [0-9.e+-]*' "$E/pass1-manual-printed.log" | awk '{print $3}')
P2=$(grep -m1 -o 'rmsd = [0-9.e+-]*' "$E/pass2-manual-printed.log" | awk '{print $3}')
SH=$(grep -m1 -o 'rmsd = [0-9.e+-]*' "$E/shipped-example1.log" | awk '{print $3}')
echo "VALUE sdp_rmsd_printed ${P1:-nan}"
echo "VALUE sdp_rmsd_pass2 ${P2:-nan}"
echo "VALUE sdp_rmsd_shipped ${SH:-nan}"
