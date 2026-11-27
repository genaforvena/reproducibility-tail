#!/usr/bin/env bash
# Rebuilds the rerun record for brankin1997-rksuite90-771 (TOMS 771, rksuite_90 v1.2, Fortran 90 ODE solver).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 771.gz (sha256 checked against the queue entry),
# gunzipped to /work/pre/771.shar and unpacked into /work/tree. gfortran (conda-forge, via micromamba) goes to
# /work/env if missing.
#
# Build: the authors' README procedure, unedited: in Src/Base, `make_rk c0` (the do_* helper scripts must be on PATH)
# writes rksuite_90.f90 for the complex-scalar dependent variable; then gfortran compiles the module and the example
# eg_simple_c0_a.f90 (Drivers/) and links it. Nothing in the unpacked tree is edited; the only file produced is the
# generated rksuite_90.f90 (and the .o and .mod files), by the authors' own make_rk.
#
# Claim: "The cost of the integration in calls to F was" printed by the example, against the shipped eg_simple_c0_a.r
# (117), tol_abs 2 (fixed in the queue entry). Two passes (G3): each is a clean rebuild from the unpacked tree.
set -uo pipefail
ID=brankin1997-rksuite90-771
URL=https://netlib.org/toms/771.gz
SHA=e1babc0304d142e28b54e6fe10c54824db27c08950a2b404426e23a97d2dab46
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
# The build, relative to the unpacked tree; the same text is passed to verify_sources record.
B1='(cd Src/Base && PATH="$PWD:$PATH" ./make_rk c0)'
B2='(cd Src/Base && gfortran -c rksuite_90.f90 -o rksuite_90.o)'
B3='gfortran -c -ISrc/Base Drivers/eg_simple_c0_a.f90 -o eg_simple_c0_a.o'
B4='gfortran Src/Base/rksuite_90.o eg_simple_c0_a.o -o eg_simple_c0_a'
BUILD="$B1 && $B2 && $B3 && $B4"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 771.gz (sha256 checked), gunzipped and unpacked; gfortran (micromamba, conda-forge) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/771.gz '$URL'; echo '$SHA  /work/771.gz' | sha256sum -c -; gzip -dc /work/771.gz > /work/pre/771.shar; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }; \
  rm -rf /work/tree && mkdir /work/tree && cd /work/tree && sh /work/pre/771.shar >/dev/null 2>&1; echo unpacked" > "$E/fetch-toolchain.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch-toolchain.log" | tail -20; exit 1; }
tail -3 "$E/fetch-toolchain.log"

echo "== unpack listing (manifest pre: the authors' files as shipped, before any build)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && find . -type f | sort" > "$E/unpack.log" 2>&1
wc -l < "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1 (original attempt, G1): copy of the unpacked tree, manifest (mid), then the README build"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && "'(cd Src/Base && PATH="$PWD:$PATH" ./make_rk c0) && (cd Src/Base && gfortran -c rksuite_90.f90 -o rksuite_90.o) && gfortran -c -ISrc/Base Drivers/eg_simple_c0_a.f90 -o eg_simple_c0_a.o && gfortran Src/Base/rksuite_90.o eg_simple_c0_a.o -o eg_simple_c0_a'"; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|Error' "$E/pass1-build.log" | head -5
echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the example, output kept"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./eg_simple_c0_a > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-output.txt"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same commands, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2 && $BUILD && ./eg_simple_c0_a > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-output.txt"

echo "== reference: the shipped eg_simple_c0_a.r (member of 771.gz), tail"
tools/sandbox.sh "$ID" -- sh -c "tail -4 /work/tree/Drivers/eg_simple_c0_a.r" > "$E/reference-block.txt" 2>&1
cat "$E/reference-block.txt"
mkdir -p "$E/reference" && cp "$SCRATCH/tree/Drivers/eg_simple_c0_a.r" "$E/reference/eg_simple_c0_a.r"

echo "== values: calls to F, both passes"
python3 -I - "$E/pass1-output.txt" "$E/pass2-output.txt" <<'PY' > "$E/values.txt" || true
import re, sys
def calls(path):
    m = re.search(r"calls to F was\s+(\d+)", open(path).read())
    return int(m.group(1)) if m else None
p1 = calls(sys.argv[1]); p2 = calls(sys.argv[2])
print("pass1 calls", p1)
print("pass2 calls", p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== build-only record (exit 0 means build-only; only once result.json exists)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command "$B1" --command "$B2" --command "$B3" --command "$B4" > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
N=$(python3 -I - "$E/pass1-output.txt" <<'PY'
import re, sys
m = re.search(r"calls to F was\s+(\d+)", open(sys.argv[1]).read())
print(m.group(1) if m else "nan")
PY
)
echo "VALUE calls to F, eg_simple_c0_a ${N}"
