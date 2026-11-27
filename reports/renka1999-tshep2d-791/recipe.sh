#!/usr/bin/env bash
# Rebuilds the rerun record for renka1999-tshep2d-791 (TOMS 791, TSHEP2D: Fortran 77 cosine-series Shepard interpolation).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 791.gz (sha256 checked against the queue entry),
# gunzipped to /work/dl/791.txt; the text above '#! /bin/sh' is dropped and the shell archive is run with /bin/sh in
# /work/tree. gfortran (conda-forge, via micromamba) goes to /work/env if missing.
#
# Build: the authors' PackingList, unedited: driver1.f and src_792.f (Drivers/Sp) with the TSHEP2 sources (Src/Sp/src.f).
# The PackingList names no compiler: gfortran with -std=legacy -w is ours. Nothing in the unpacked tree is edited;
# the build copy is only compiled.
# Run: ts2tst reads the driver's input from stdin (PackingList: stdin=data1) and prints the prompts on stdout. Its result table
# goes to the file res1_2 in the working directory (OPEN(LOUT, FILE='res1_2')). The shipped res1_2 is deleted from the build
# copy before each run, so the value below can only come from this run (checked: the file must be written again).
#
# Claim: average SSE/SSM over the ten test functions for node set 1, NC = 17, NW = 30, NR = 6 (the shipped res1_2),
# value 0.006063, tol_abs 1e-5 (fixed in the queue entry). The first record of data1 is that case.
# Two passes (G3): each is a clean copy of the unpacked tree, rebuilt with the same command and run.
set -uo pipefail
ID=renka1999-tshep2d-791
URL=https://netlib.org/toms/791.gz
SHA=733ee80b3ec4d9b5a6dcf443bb4053924f25b3339486bb3e3df6b91cf31793ac
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
DRV='Fortran77/Drivers/Sp'
BUILD="gfortran -std=legacy -w -o ts2tst driver1.f src_792.f ../../Src/Sp/src.f"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 791.gz (sha256 checked), unpacked text to /work/dl/791.txt; toolchain (gfortran) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/dl && cd /work/dl && curl -fsSL -o 791.gz '$URL'; echo '$SHA  791.gz' | sha256sum -c -; gzip -dc 791.gz > 791.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack: the shell archive run with /bin/sh (no patch: this is the authors' own unpacking)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir -p /work/tree && sed -n '4,\$p' /work/dl/791.txt > /work/dl/791.sh && cd /work/tree && sh /work/dl/791.sh" > "$E/unpack.log" 2>&1
echo "unpack_exit=$?"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && find . -type f | sort" > "$E/unpack-listing.log" 2>&1
cat "$E/unpack-listing.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1: copy of the unpacked tree, manifest (mid), then the build"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied" > "$E/copy-pass1.log" 2>&1
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build/$DRV && gfortran -std=legacy -w -o ts2tst driver1.f src_792.f ../../Src/Sp/src.f; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|Error' "$E/pass1-build.log" | head -5

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the driver with data1 on stdin"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/$DRV && rm -f res1_2 && ./ts2tst < data1 > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?; test -s res1_2 && echo res1_2_written=yes" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=|res1_2_written' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-stdout.txt" 2>/dev/null || echo "pass1 produced no stdout"
cp "$SCRATCH/build/$DRV/res1_2" "$E/pass1-res1_2.txt" 2>/dev/null || echo "pass1 wrote no res1_2"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same command, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 /work/out-pass2.txt && cp -r /work/tree /work/pass2 && cd /work/pass2/$DRV && rm -f res1_2 && $BUILD && ./ts2tst < data1 > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?; test -s res1_2 && echo res1_2_written=yes" > "$E/pass2-run.log" 2>&1
grep -E '^rc=|res1_2_written' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-stdout.txt" 2>/dev/null || echo "pass2 produced no stdout"
cp "$SCRATCH/pass2/$DRV/res1_2" "$E/pass2-res1_2.txt" 2>/dev/null || echo "pass2 wrote no res1_2"

echo "== values: average SSE/SSM of the first case (node set 1, NC 17, NW 30, NR 6), both passes"
python3 -I - "$E/pass1-res1_2.txt" "$E/pass2-res1_2.txt" <<'PY' > "$E/values.txt" || true
import re, sys
def first(path):
    m = re.search(r"Average SSE/SSM over the test functions =\s*([0-9.]+)", open(path).read())
    return float(m.group(1)) if m else None
p1 = first(sys.argv[1]); p2 = first(sys.argv[2])
print("pass1 average SSE/SSM", p1)
print("pass2 average SSE/SSM", p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== manifests into the record (exit 0 means build-only)"
# record writes the patch field into result.json, so it runs only once result.json exists (written from the run).
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command "gfortran -std=legacy -w -o ts2tst driver1.f src_792.f ../../Src/Sp/src.f" > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
AV=$(python3 -I - "$E/pass1-res1_2.txt" <<'PY'
import re, sys
m = re.search(r"Average SSE/SSM over the test functions =\s*([0-9.]+)", open(sys.argv[1]).read())
print(m.group(1) if m else "nan")
PY
)
echo "VALUE TSHEP2D driver1, node set 1, NC 17, NW 30, NR 6: average SSE/SSM ${AV}"
