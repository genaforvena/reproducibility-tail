#!/usr/bin/env bash
# Rebuilds the rerun record for miminis1995-eigassign-747 (TOMS 747, Fortran 77 staircase reduction and eigenvalue
# assignment by state feedback). Everything that runs the authors' code goes through tools/sandbox.sh. The host only
# hashes source files (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 747.gz (sha256 checked), gunzipped to
# /work/pre/747.shar. The Fortran toolchain (gfortran and make from conda-forge, via micromamba) goes to /work/env
# if missing.
#
# Original attempt (G1): the shar split into its 36 files, the authors' makefile run as shipped. The makefile calls
# `f77`, which is not installed on this host or in the sandbox, so make stops at the first compile. Log:
# evidence/original-attempt.log.
#
# Build (basis patched, build-only): the only change is a compiler alias, f77 -> gfortran, placed in /work/bin
# outside the unpacked tree. No source or build file is edited or added. The makefile's own rules are run as written
# (`make ddemo`). Nothing in the tree changes between the pre manifest, the mid manifest and the build.
#
# Claim: F(1,1) and F(1,2) of test01 (the first row of the computed gain matrix, ddemo, double precision), against
# the shipped dlog.ref block, tolerance 5e-5 (fixed in the queue entry). Two passes (G3): both pass are clean
# rebuilds from the same unpacked tree, each run on test01.dat.
set -uo pipefail
ID=miminis1995-eigassign-747
URL=https://netlib.org/toms/747.gz
SHA=b24ab9b2ef2de1cd45f4448c47cb891d7ab4c9ab7bae004e9da3e1d4cb2cacc2
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 747.gz (sha256 checked), gunzipped; toolchain (gfortran, make) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre /work/bin && cd /work/pre && curl -fsSL -o /work/747.gz '$URL'; echo '$SHA  /work/747.gz' | sha256sum -c -; gzip -dc /work/747.gz > /work/pre/747.shar; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }
cat > "$SCRATCH/pre/split.awk" <<'AWK'
/^C\*\*\* /{out=$2; next}
{ if (out != "") print > out }
AWK

echo "== original attempt (G1): the archive as shipped, split and built with its own makefile, no f77 alias"
tools/sandbox.sh "$ID" -- sh -c "rm -f /work/bin/f77 && rm -rf /work/orig && mkdir /work/orig && cd /work/orig && awk -f /work/pre/split.awk /work/pre/747.shar && $PATHSET && make ddemo; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|f77' "$E/original-attempt.log" | head -5

echo "== unpack: the authors' files split from the shar, unedited, into /work/tree (manifest pre: before any patch)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir /work/tree && cd /work/tree && awk -f /work/pre/split.awk /work/pre/747.shar && ls" > "$E/unpack.log" 2>&1
tail -3 "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== patch (build-only): compiler alias f77 -> gfortran in /work/bin, outside the tree"
tools/sandbox.sh "$ID" -- sh -c "ln -sf /work/env/bin/gfortran /work/bin/f77 && ls -l /work/bin/f77"

echo "== pass 1: copy the unpacked tree to the build directory (no edit), then manifest (mid)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"

echo "== pass 1 build: the authors' makefile target"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && make ddemo; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=' "$E/pass1-build.log"

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: test01.dat through ddemo.x"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./ddemo.x < test01.dat > /work/test01-pass1.out 2>/work/test01-pass1.err; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/test01-pass1.out" "$E/pass1-test01.out"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same target, run on test01.dat"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2 && make ddemo && ./ddemo.x < test01.dat > /work/test01-pass2.out 2>/work/test01-pass2.err; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/test01-pass2.out" "$E/pass2-test01.out"

echo "== reference: the first row of the shipped dlog.ref block for test01"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && awk '/computed gain matrix F/{n=2} n&&n-->0{print}' dlog.ref | head -3" > "$E/reference-row.txt" 2>&1
cat "$E/reference-row.txt"

echo "== values: first two entries of the computed gain matrix F, both passes"
python3 -I - "$E/pass1-test01.out" "$E/pass2-test01.out" <<'PY' > "$E/values.txt" || true
import sys
def f_row(path):
    lines = open(path).read().splitlines()
    i = [k for k, l in enumerate(lines) if "computed gain matrix F" in l][0]
    row = lines[i + 1].split()
    return row[0], row[1]
p1 = f_row(sys.argv[1]); p2 = f_row(sys.argv[2])
print("pass1 F(1,1) F(1,2)", *p1)
print("pass2 F(1,1) F(1,2)", *p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== manifests into the report and build-only record (exit 0 means build-only)"
# record writes the patch field into result.json, so it runs only once result.json exists (written from the run).
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" --command 'make ddemo' > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
F11=$(python3 -I - "$E/pass1-test01.out" <<'PY'
import sys
lines = open(sys.argv[1]).read().splitlines()
i = [k for k, l in enumerate(lines) if "computed gain matrix F" in l][0]
print(lines[i + 1].split()[0])
PY
)
F12=$(python3 -I - "$E/pass1-test01.out" <<'PY'
import sys
lines = open(sys.argv[1]).read().splitlines()
i = [k for k, l in enumerate(lines) if "computed gain matrix F" in l][0]
print(lines[i + 1].split()[1])
PY
)
echo "VALUE F(1,1) of test01, ddemo double precision (dlog.ref) ${F11:-nan}"
echo "VALUE F(1,2) of test01 (dlog.ref) ${F12:-nan}"
