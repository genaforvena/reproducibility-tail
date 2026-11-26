#!/usr/bin/env bash
# Rebuilds the rerun verdict for berntsen1993-dcutet-720 (TOMS 720, DCUTET adaptive cubature over tetrahedra, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 720.gz (sha256 checked), gunzipped to /work/pre/720.shar;
# gfortran from conda-forge (micromamba) into the sandbox scratch at /work/fortran. Everything else runs through
# tools/sandbox.sh. The host only hashes source files with tools/verify_sources.py (read-only).
#
# The archive is NOT a shell archive: 720.shar is one Fortran file holding the double-precision code
# (lines 1-1866: D1MACH, DADTET, DCHTET, DCUTET, DORTET, DRLTET; lines 2288-2754: ATEST, FMONOM, FACTOR, MOMENT,
# FINVAR, DTRTET), the single-precision twin (from line 2755), and four PROGRAM units (DTEST1 at 1867, DTEST2 at
# 1908, STEST1 at 4194, STEST2 at 4235). The queue note's "extract with sh" does not apply.
#
# Original attempt (G1): compile the archive as shipped, as one Fortran file, `gfortran -O0 -o dtest 720.f`. It fails
# at compile: the Makefile fragment in the header is not Fortran ("Non-numeric character in statement label"). Log: evidence/original-attempt.log.
#
# The first 71 lines of 720.shar are a comment block and then a Makefile fragment (lines like `dtest1: dtest1.o ...`
# and `r1mach.o: r1mach.f` with the `77 -c` rules, unprefixed). gfortran rejects them ("Non-numeric character in
# statement label", "Non-numeric character in name"), so the shipped file does not compile as one unit. The
# Makefile fragment is not Fortran: it is the build file the one-file form carries in front of the code.
# Unpack (before the pre manifest): dcutet.f = lines 72-1866 and 2288-2754 (from D1MACH to the end of the
# double-precision code; DTEST2 at 1908-2287 and the single-precision code are left out) and dtest1.f = lines
# 1867-1907 (DTEST1 and F). No Fortran line is changed; the 71 header lines are left out, not edited.
# Judgment call, stated in result.md: this is treated as unpacking, not as a patch, so the build-only record
# applies to the code; a reviewer who reads the header removal as a patch needs the G2 paper check instead.
#
# Claim: DTEST1 RESULT, the integral of exp(x*x+y*y+z*z) over the reference tetrahedron (EPSREL 1e-5, EPSABS 0),
# against 0.22779999698986 (tol 1e-5, absolute), from the shipped 'Output produced on a SUN 3/50' comment.
# Two passes (G3): pass 1 is the verdict's build at -O0; pass 2 is a clean copy at -O2.
set -uo pipefail
ID=berntsen1993-dcutet-720
URL=https://netlib.org/toms/720.gz
SHA=dc7f045565f861b4561f76b55cc49596e435349847cebdc0e6e5de5230025deb
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 720.gz (sha256 checked), gunzipped to /work/pre/720.shar; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre /work/bin && cd /work/pre && curl -fsSL -o /work/720.gz '$URL'; echo '$SHA  /work/720.gz' | sha256sum -c -; gunzip -c /work/720.gz > /work/pre/720.shar; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the archive as shipped, one file"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && mkdir /work/g1 && cp /work/pre/720.shar /work/g1/720.f && cd /work/g1 && $G -O0 -o dtest 720.f; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|multiple definition|MAIN__' "$E/original-attempt.log" | head -5

echo "== unpack: split the single-file archive into dcutet.f and dtest1.f by line ranges (Fortran lines unchanged; the 71-line Makefile/comment header is left out)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre && sed -n '72,1866p;2288,2754p' 720.shar > dcutet.f && sed -n '1867,1907p' 720.shar > dtest1.f && wc -l dcutet.f dtest1.f && rm -f 720.shar.bak" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/pre" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== reference: the shipped sample output block (comment lines 1317-1321 of 720.shar), copied unedited"
tools/sandbox.sh "$ID" -- sed -n '1317,1321p' /work/pre/720.shar > "$E/reference/sun3-50-output.txt"
cat "$E/reference/sun3-50-output.txt"

echo "== pass 1: copy the unpacked units to the build directory (no edit), then manifest (mid)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"

echo "== pass 1 build (gfortran -O0, the two units)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -o dtest1 dtest1.f dcutet.f > /work/build-make.log 2>&1; echo build_exit=\$?; tail -3 /work/build-make.log" > "$E/pass1-build.log" 2>&1
cat "$E/pass1-build.log"

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: dtest1"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./dtest1 > /work/dtest1-pass1.out 2>&1; echo run_exit=\$?; cat /work/dtest1-pass1.out" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
tools/sandbox.sh "$ID" -- cat /work/dtest1-pass1.out > "$E/pass1-output.txt"

echo "== pass 2 (clean copy, gfortran -O2)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/pre /work/pass2 && cd /work/pass2 && $G -O2 -o dtest1 dtest1.f dcutet.f > /work/pass2-make.log 2>&1; echo build_exit=\$?; ./dtest1 > /work/dtest1-pass2.out 2>&1; echo run_exit=\$?; cat /work/dtest1-pass2.out" > "$E/pass2-run.log" 2>&1
grep -E '^(build_exit|run_exit)=' "$E/pass2-run.log"
tools/sandbox.sh "$ID" -- cat /work/dtest1-pass2.out > "$E/pass2-output.txt"

echo "== values: RESULT from each pass"
for p in pass1 pass2; do
  grep -m1 -oE 'RESULT[^0-9-]*[-0-9.]+' "$E/$p-output.txt" | grep -oE '[-0-9.]+$' > "$E/$p-result.txt" || true
done
echo "VALUE DTEST1 RESULT (integral of exp(x^2+y^2+z^2) over the reference tetrahedron) $(cat "$E/pass1-result.txt" 2>/dev/null)"
echo "PASS2 VALUE DTEST1 RESULT (integral of exp(x^2+y^2+z^2) over the reference tetrahedron) $(cat "$E/pass2-result.txt" 2>/dev/null)"
