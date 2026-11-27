#!/usr/bin/env bash
# Rebuilds the rerun record for kraft1994-tomp-733 (TOMS 733, TOMP: Fortran 77 modules for optimal control).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 733.gz (sha256 checked against the queue entry),
# gunzipped to /work/tree/733.f (a single file: the TOMP modules and the unnamed test driver). gfortran (conda-forge,
# via micromamba) goes to /work/env if missing.
#
# Patch (basis patched, not build-only): as shipped, 733.f is not a compilable Fortran file. Lines 1-555 are the
# archive's prose (TOMP.TXT, TOMP.OUT, TOMP.M, not comment-marked) and MATLAB data; gfortran stops at line 4
# (evidence/manual-prior-run and pass1-build.log). The Fortran code starts at line 556 (d_TOMP). The patch step
# is the extraction of lines 556 to the end into TOMP.FOR in the build copy, before the manifest (mid). No line of
# the code is changed. 733.f itself is never edited.
# Build: gfortran -std=legacy -w -o tomp TOMP.FOR (legacy extensions for the fixed-form code; no optimisation change).
#
# Claim: final cost of the constrained brachistochrone run (the driver's last optimiser line, iteration 27) against
# the shipped TOMP.OUT block (733.f lines 77-109: 0.17952392D+01), tol_abs 1e-5 (fixed in the queue entry).
# Two passes (G3): each is a clean rebuild from the unpacked tree, each run from the same inputs (the driver has none).
set -uo pipefail
ID=kraft1994-tomp-733
URL=https://netlib.org/toms/733.gz
SHA=cf49f88ca0138f774b7cabda7acd85f0e1c2d36cbc263eebb5d029f69e794c35
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
PATCH='tail -n +556 733.f > TOMP.FOR'
BUILD='gfortran -std=legacy -w -o tomp TOMP.FOR'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 733.gz (sha256 checked), gunzipped to /work/tree/733.f; toolchain (gfortran, make) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/tree && cd /work/tree && curl -fsSL -o /work/733.gz '$URL'; echo '$SHA  /work/733.gz' | sha256sum -c -; gzip -dc /work/733.gz > /work/tree/733.f; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack listing (manifest pre: the authors' file as shipped, before any build)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && find . -type f | sort" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1: copy of the unpacked tree, patch step (extract the code into TOMP.FOR), manifest (mid), then the build"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && cd /work/build && $PATCH && echo patched" > "$E/patch.log" 2>&1
cat "$E/patch.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && $BUILD; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|Error' "$E/pass1-build.log" | head -5

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the driver, stdin closed, output kept"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && rm -f /work/out-pass1.txt && ./tomp < /dev/null > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-stdout.txt" 2>/dev/null || echo "pass1 produced no stdout"
# The driver writes its iteration log to tomp.out in the working directory (stdout stays empty), so that file is the value source.
cp "$SCRATCH/build/tomp.out" "$E/pass1-tomp.out" 2>/dev/null || echo "pass1 wrote no tomp.out"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same command, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 /work/out-pass2.txt && cp -r /work/tree /work/pass2 && cd /work/pass2 && $PATCH && $BUILD && ./tomp < /dev/null > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-stdout.txt" 2>/dev/null || echo "pass2 produced no stdout"
cp "$SCRATCH/pass2/tomp.out" "$E/pass2-tomp.out" 2>/dev/null || echo "pass2 wrote no tomp.out"

echo "== reference: the shipped TOMP.OUT block (733.f lines 77-109)"
tools/sandbox.sh "$ID" -- sh -c "sed -n 77,109p /work/tree/733.f" > "$E/reference-block.txt" 2>&1
cat "$E/reference-block.txt"

echo "== values: final cost (last optimiser iteration line), both passes"
python3 -I - "$E/pass1-tomp.out" "$E/pass2-tomp.out" <<'PY' > "$E/values.txt" || true
import re, sys
def final(path):
    rows = re.findall(r"^\s+(\d+)\s+(-?[0-9.]+D[+-]\d+)\s+\S+\s*$", open(path).read(), re.M)
    return float(rows[-1][1].replace("D", "E")) if rows else None
p1 = final(sys.argv[1]); p2 = final(sys.argv[2])
print("pass1 final cost", p1)
print("pass2 final cost", p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== manifests into the record (exit 0 means build-only; exit 2 means a source file was changed before the build, so G2 applies)"
# record writes the patch field into result.json, so it runs only once result.json exists (written from the run).
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'gfortran -std=legacy -w -o tomp TOMP.FOR' > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
FC=$(python3 -I - "$E/pass1-tomp.out" <<'PY'
import re, sys
rows = re.findall(r"^\s+(\d+)\s+(-?[0-9.]+D[+-]\d+)\s+\S+\s*$", open(sys.argv[1]).read(), re.M)
print(float(rows[-1][1].replace("D", "E")) if rows else "nan")
PY
)
echo "VALUE value ${FC}"
