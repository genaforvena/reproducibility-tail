#!/usr/bin/env bash
# Rebuilds the rerun record for gil2017-incgamneg-969 (TOMS 969, Gil, Ruiz-Antolin, Segura, Temme: incomplete gamma* for
# negative arguments; Fortran 90).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 969.zip (sha256 checked against the queue entry),
# unzipped to /work/tree/969 (Fortran90/Src: setprecision, cons, gammaError, incgamNEG, constants; Fortran90/Drivers:
# testgamstar.f90, Makefile, OutGammStar). gfortran (conda-forge, via micromamba) goes to /work/env if missing.
#
# G1 original attempt: the authors' Makefile as shipped, run in Fortran90/Drivers, stops with
# "No rule to make target 'setprecision.f90'" because the Makefile lists the sources in ../Src, not in its own directory
# (evidence/original-attempt.log).
#
# Patch (basis patched, build-only): no source file is touched. The patch step copies the unpacked tree to /work/build
# and the build runs the authors' own Makefile with one make variable on the command line, VPATH=../Src, so make finds the
# sources in ../Src. The manifests (pre, mid, post) prove that no source file changed before the build.
# Build: make VPATH=../Src (in Fortran90/Drivers; compiler gfortran -O, per the Makefile).
#
# Claim: gamma*(a,z) at a=-0.03, z=-0.03 (testgamstar.f90 DATA igams(11) = 0.98117651308252274, the shipped reference,
# also printed in OutGammStar), tol_abs 1e-9 (fixed in the queue entry). The driver writes testGammStar.dat; the value
# is row 11 of its table (a=-0.3000D-01, z=-0.3000D-01).
# Two passes (G3): each a clean rebuild from the unpacked tree, each run with the same inputs (the driver has none).
set -uo pipefail
ID=gil2017-incgamneg-969
URL=https://netlib.org/toms/969.zip
SHA=4d365512e230338da001de56c62cfc5b78aa74e4f3b9f1a32b1dabe93e5a3ce7
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
DRV=969/Fortran90/Drivers
BUILD='make VPATH=../Src'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 969.zip (sha256 checked), unzipped to /work/tree; toolchain (gfortran, make) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/tree && cd /work/tree && curl -fsSL -o /work/969.zip '$URL'; echo '$SHA  /work/969.zip' | sha256sum -c -; python3 -I -m zipfile -e /work/969.zip /work/tree; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack listing (manifest pre: the authors' files as shipped, before any build)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && find . -type f | sort" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== G1 original attempt: the authors' Makefile as shipped, in Drivers"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/tree/$DRV && make; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== pass 1: copy of the unpacked tree (no edit), manifest (mid), then the build"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied" > "$E/patch.log" 2>&1
cat "$E/patch.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build/$DRV && make VPATH=../Src; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|Error' "$E/pass1-build.log" | head -5

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the driver, stdin closed; its table is testGammStar.dat in the working directory"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/$DRV && rm -f testGammStar.dat && ./testgamstar < /dev/null > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/build/$DRV/testGammStar.dat" > "$E/pass1-testGammStar.dat" 2>&1

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same command, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2/$DRV && $BUILD && rm -f testGammStar.dat && ./testgamstar < /dev/null > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?; cat testGammStar.dat" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
sed -n '/^rc=/,$p' "$E/pass2-run.log" | tail -n +2 > "$E/pass2-testGammStar.dat"

echo "== reference: the shipped driver value (testgamstar.f90 DATA igams(11)) and OutGammStar row"
tools/sandbox.sh "$ID" -- sh -c "grep -n 'igams/' /work/tree/$DRV/testgamstar.f90 | head -2; grep -n '0.9811765130825' /work/tree/$DRV/OutGammStar" > "$E/reference.txt" 2>&1
cat "$E/reference.txt"

echo "== values: gamma*(-0.03,-0.03) from the table row (a=-0.3000D-01, z=-0.3000D-01), both passes"
python3 -I - "$E/pass1-testGammStar.dat" "$E/pass2-testGammStar.dat" <<'PY' > "$E/values.txt" || true
import re, sys
def val(path):
    for line in open(path):
        m = re.match(r"^\s*-\.3000D-01\s+-\.3000D-01\s+(-?[0-9.]+D[+-]\d+)", line)
        if m:
            return float(m.group(1).replace("D", "E"))
    return None
p1 = val(sys.argv[1]); p2 = val(sys.argv[2])
print("pass1 gamma*(-0.03,-0.03)", p1)
print("pass2 gamma*(-0.03,-0.03)", p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== manifests into the record (exit 0 means build-only; exit 2 means a source file was changed before the build, so G2 applies)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'make VPATH=../Src' > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
VAL=$(python3 -I - "$E/pass1-testGammStar.dat" <<'PY'
import re, sys
for line in open(sys.argv[1]):
    m = re.match(r"^\s*-\.3000D-01\s+-\.3000D-01\s+(-?[0-9.]+D[+-]\d+)", line)
    if m:
        print(float(m.group(1).replace("D", "E"))); break
else:
    print("nan")
PY
)
echo "VALUE gamma*(-0.03,-0.03) ${VAL}"
