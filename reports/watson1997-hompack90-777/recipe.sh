#!/usr/bin/env bash
# Rebuilds the rerun record for watson1997-hompack90-777 (TOMS 777, HOMPACK90, Fortran 90 homotopy solvers).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 777.gz (sha256 checked against the queue entry),
# gunzipped to /work/pre/777.shar; the shar header above '#! /bin/sh' is dropped and the shar is run with /bin/sh in
# /work/tree. gfortran (conda-forge, via micromamba) goes to /work/env if missing.
#
# Build: the authors' Doc/README order, unedited: compile hompack90.f (the four modules), then lapack.f, blas1.f,
# blas2.f, blas3.f, then driver3.f, and link driver3. The README gives no compiler command: gfortran with default
# flags is ours, as in the brankin1997 record. Nothing in the unpacked tree is edited; only .o and .mod files are
# produced.
#
# Claim: the shipped RES3 block 'TESTING FIXPQS WITH STORAGE MODE = 1', first component Y(1) at lambda = 1
# (4.00864019E-01), compared to the value printed by this rebuild with tol_abs 1e-8 (fixed in the queue entry).
# Two passes (G3): each is a clean rebuild from the unpacked tree. Timing lines are not used.
set -uo pipefail
ID=watson1997-hompack90-777
URL=https://netlib.org/toms/777.gz
SHA=a86547e59ee7b090691b1db16e9e4d07ab018334a28f60ae13ca11e7cfd46498
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
# The build, relative to the unpacked tree; the same text is passed to verify_sources record.
B1='(cd Src && gfortran -c hompack90.f)'
B2='(cd Src && gfortran -c lapack.f blas1.f blas2.f blas3.f)'
B3='(cd Drivers && gfortran -I../Src -c driver3.f)'
B4='(cd Drivers && gfortran ../Src/hompack90.o ../Src/lapack.o ../Src/blas1.o ../Src/blas2.o ../Src/blas3.o driver3.o -o driver3)'
BUILD="$B1 && $B2 && $B3 && $B4"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 777.gz (sha256 checked), shar header dropped, unpacked; gfortran (micromamba, conda-forge) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/777.gz '$URL'; echo '$SHA  /work/777.gz' | sha256sum -c -; gzip -dc /work/777.gz > /work/pre/777.shar; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }; \
  rm -rf /work/tree && mkdir /work/tree && awk '/^#! \/bin\/sh/{f=1} f' /work/pre/777.shar > /work/pre/777.sh && cd /work/tree && sh /work/pre/777.sh >/dev/null 2>&1; echo unpacked" > "$E/fetch-toolchain.log" 2>&1 || { echo "FETCH-FAILED"; tail -20 "$E/fetch-toolchain.log"; exit 1; }
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
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && (cd Src && gfortran -c hompack90.f) && (cd Src && gfortran -c lapack.f blas1.f blas2.f blas3.f) && (cd Drivers && gfortran -I../Src -c driver3.f) && (cd Drivers && gfortran ../Src/hompack90.o ../Src/lapack.o ../Src/blas1.o ../Src/blas2.o ../Src/blas3.o driver3.o -o driver3); echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|Error' "$E/pass1-build.log" | head -5
echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the driver, output kept"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Drivers && ./driver3 > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-output.txt"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same commands, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2 && $BUILD && cd Drivers && ./driver3 > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-output.txt"

echo "== reference: the shipped Drivers/RES3 (member of 777.gz), FIXPQS storage mode 1 block"
mkdir -p "$E/reference" && cp "$SCRATCH/tree/Drivers/RES3" "$E/reference/RES3"
sed -n 3,8p "$E/reference/RES3" > "$E/reference-block.txt"
cat "$E/reference-block.txt"

echo "== values: Y(1) at lambda = 1 from the FIXPQS storage-mode-1 block, both passes"
python3 -I - "$E/pass1-output.txt" "$E/pass2-output.txt" <<'PY' > "$E/values.txt" || true
import sys
def y1(path):
    lines = open(path).read().splitlines()
    i = next(k for k, l in enumerate(lines) if "TESTING FIXPQS WITH STORAGE MODE = 1" in l)
    for l in lines[i + 1:]:
        t = l.split()
        if not t or "LAMBDA" in l or "EXECUTION" in l:
            continue
        return float(t[0])
    return None
p1 = y1(sys.argv[1]); p2 = y1(sys.argv[2])
print("pass1 Y(1)", repr(p1))
print("pass2 Y(1)", repr(p2))
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
import sys
lines = open(sys.argv[1]).read().splitlines()
i = next(k for k, l in enumerate(lines) if "TESTING FIXPQS WITH STORAGE MODE = 1" in l)
print(next(l.split()[0] for l in lines[i + 1:] if l.split() and "LAMBDA" not in l and "EXECUTION" not in l))
PY
)
echo "VALUE FIXPQS storage mode 1, solution component Y(1) at lambda=1 ${N}"
