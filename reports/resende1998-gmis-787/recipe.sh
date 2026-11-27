#!/usr/bin/env bash
# Rebuilds the rerun record for resende1998-gmis-787 (TOMS 787, Fortran 77 GRASP heuristic for maximum independent
# set, gmis). Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 787.gz (sha256 checked against the queue entry),
# gunzipped to /work/pre/787.shar. The Fortran toolchain (gfortran and make from conda-forge, via micromamba) goes to
# /work/env if missing.
#
# Original attempt (G1): the shar unpacked as shipped (sh 787.shar), then the authors' Doc/Makefile run with make.
# The shar's heredoc is unquoted, so the shell expands $(FC) $(FFLAGS) $(OBJS_GMIS) while unpacking: the rule loses
# its prerequisites and its command, and make is left with `-o gmis` (no compiler). No gmis executable is produced.
# Log: evidence/original-attempt.log.
#
# Build (basis patched, build-only): nothing in the unpacked tree is edited before the build. The build copies the
# tree to /work/build and compiles the authors' driver.f and src.f with the rule the shipped Makefile intends:
# `$(FC) $(FFLAGS) driver.o src.o -o gmis` with FFLAGS=-O (from the Makefile) and FC=gfortran. The manifests pre, mid
# and post bracket exactly these three commands.
#
# Claim: "Size of indep set" printed by gmis on the sample instance (data = sample.dat, 50 nodes, 619 arcs) with the
# seed 270001 in the input, against the shipped RES output block, exact (tol_abs 0; fixed in the queue entry).
# Two passes (G3): both are clean rebuilds from the unpacked tree, each run on the data file.
set -uo pipefail
ID=resende1998-gmis-787
URL=https://netlib.org/toms/787.gz
SHA=dc7105e38d4dac8082ee6d010bd4c9a904d61b1a182532414ecd2c7dcf3768fe
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
DRV=Fortran77/Drivers/Sp
SRC=Fortran77/Src/Sp
BUILD='gfortran -O -c Fortran77/Drivers/Sp/driver.f -o driver.o && gfortran -O -c Fortran77/Src/Sp/src.f -o src.o && gfortran -O driver.o src.o -o gmis'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 787.gz (sha256 checked), gunzipped; toolchain (gfortran, make) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/787.gz '$URL'; echo '$SHA  /work/787.gz' | sha256sum -c -; gzip -dc /work/787.gz > /work/pre/787.shar; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the shar as shipped, unpacked and built with its own Doc/Makefile"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cd /work/orig && sh /work/pre/787.shar >/dev/null 2>&1; cd Doc && cat Makefile && $PATHSET && make; echo make_exit=\$?; if test -x /work/orig/Doc/gmis; then echo gmis_binary=yes; else echo gmis_binary=no; fi" > "$E/original-attempt.log" 2>&1
grep -E 'make_exit=|gmis_binary=|Error' "$E/original-attempt.log" | head -5

echo "== unpack: the authors' files from the shar, unedited, into /work/tree (manifest pre: before any build)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir /work/tree && cd /work/tree && sh /work/pre/787.shar >/dev/null 2>&1 && find . -type f | sort" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1: copy the unpacked tree to the build directory (no edit), then manifest (mid)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"

echo "== pass 1 build: the shipped Makefile rule as three gfortran commands (FFLAGS=-O)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && gfortran -O -c Fortran77/Drivers/Sp/driver.f -o driver.o && gfortran -O -c Fortran77/Src/Sp/src.f -o src.o && gfortran -O driver.o src.o -o gmis; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=' "$E/pass1-build.log"

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: sample.dat (data) through gmis, seed 270001 from the input"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./gmis < $DRV/data > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-output.txt"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same commands, run on the data file"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2 && $BUILD && ./gmis < $DRV/data > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-output.txt"

echo "== reference: the shipped RES output block (member of 787.gz)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && grep -A3 'output----' $DRV/RES" > "$E/reference-block.txt" 2>&1
cat "$E/reference-block.txt"

mkdir -p "$E/reference" && cp "$SCRATCH/tree/$DRV/RES" "$E/reference/RES"

echo "== values: size of the independent set, both passes"
python3 -I - "$E/pass1-output.txt" "$E/pass2-output.txt" <<'PY' > "$E/values.txt" || true
import re, sys
def size(path):
    m = re.search(r"Size of indep set :\s+(\d+)", open(path).read())
    return int(m.group(1)) if m else None
p1 = size(sys.argv[1]); p2 = size(sys.argv[2])
print("pass1 size", p1)
print("pass2 size", p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== manifests into the report and build-only record (exit 0 means build-only)"
# record writes the patch field into result.json, so it runs only once result.json exists (written from the run).
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'gfortran -O -c Fortran77/Drivers/Sp/driver.f -o driver.o' --command 'gfortran -O -c Fortran77/Src/Sp/src.f -o src.o' --command 'gfortran -O driver.o src.o -o gmis' > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
SZ=$(python3 -I - "$E/pass1-output.txt" <<'PY'
import re, sys
m = re.search(r"Size of indep set :\s+(\d+)", open(sys.argv[1]).read())
print(m.group(1) if m else "nan")
PY
)
echo "VALUE size of indep set, sample instance, seed 270001 ${SZ}"
