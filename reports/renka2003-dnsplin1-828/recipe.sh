#!/usr/bin/env bash
# Rebuilds the rerun verdict for renka2003-dnsplin1-828 (TOMS 828, DNSPLIN1 discrete nonlinear spline interpolation, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 828.gz (sha256 checked), unpacked as a shell archive
# inside the sandbox scratch; micromamba and gfortran from conda-forge into the sandbox scratch. Everything else runs
# through tools/sandbox.sh.
# Original attempt (G1): the authors' Makefile as documented (make Res1), in a copy, kept once. The archive has no
# makefile.inc, which the Makefile includes and which names the compiler and the BLAS/LAPACK objects; so the authors'
# documented build fails at the first line. The log is kept.
# Build-only patch: a makefile.inc written from the authors' own Makefile variable names (F77, F77OPTS, F77LINK,
# F77LINKOPTS, INCSRC, LAPACK, BLAS), with gfortran and the two object rules for lapack.f and dblas.f. No source file is
# edited. The build tree is a copy of the authors' Dp tree; verify_sources proves the build-only status from bytes.
# Claim: driver on data1 (Res1), the second value after the count 241 in the output (row 3 of the file, the
# first interpolated value being row 2): shipped 0.565126291685656D-01, tolerance 1e-12 absolute.
# Two passes (G3): run 1 is the build's Res1 output (make Res1 runs ./driver < data1); run 2 copies the driver binary to
# a clean directory and runs it on data1 again.
set -uo pipefail
ID=renka2003-dnsplin1-828
URL=https://netlib.org/toms/828.gz
SHA=86c0c495cda5ec8c8f49d394c78e53d8df4c765b0398135556b7762e78f3d7fd
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
W="/mnt/mishe-scratch/reproducibility-tail/$ID"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
GF=$G
DP=Fortran77/Dp

echo "== fetch: 828.gz (sha256 checked), unpacked in the sandbox scratch; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; rm -rf pre build g1; mkdir pre; curl -fsSL -o 828.gz '$URL'; echo '$SHA  828.gz' | sha256sum -c -; gunzip -kf 828.gz; \
  sed -n '/^#! \/bin\/sh/,\$p' 828 > pre/828.sh; cd pre && sh 828.sh >/dev/null 2>&1; test -f $DP/Drivers/driver.f; \
  test -x /work/fortran/bin/x86_64-conda-linux-gnu-gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: Drivers/res1, copied unedited"
tools/sandbox.sh "$ID" -- cat "/work/pre/$DP/Drivers/res1" > "$E/reference/res1" || { echo "REF-FAILED"; exit 1; }
sed -n 3p "$E/reference/res1"

# G2 build-only proof, manifest 1 of 3: the authors' bytes, right after unpacking, before any copy or patch.
python3 -I tools/verify_sources.py manifest "$W/pre/$DP" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") source files"

# G1 original attempt: the authors' Makefile as documented, in a copy (kept once, never overwritten).
ORIG="$E/original-attempt.log"
if [ ! -s "$ORIG" ]; then
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre /work/g1 && cd /work/g1/$DP/Drivers && make Res1 2>&1; echo make_exit=\$?" > "$ORIG" 2>&1
fi
tail -3 "$ORIG"

# The build tree: a full copy of the authors' Dp tree, then the build-only patch (one new file, makefile.inc, from the
# host-side scratch). The patch step ends before manifest 2 of 3.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre /work/build" || { echo "COPY-FAILED"; exit 1; }
mkdir -p "$W/patch"
printf '%s\n' \
  "F77=$GF" 'F77LINK=$(F77)' 'F77OPTS=-O2 -std=legacy' 'F77LINKOPTS=-O2' \
  "FC=$GF" 'FFLAGS=-O2 -std=legacy' 'INCSRC=../Src' 'LAPACK=lapack.o' 'BLAS=dblas.o' '' \
  'lapack.o: lapack.f' '	$(F77) $(F77OPTS) -c lapack.f' \
  'dblas.o: dblas.f' '	$(F77) $(F77OPTS) -c dblas.f' \
  'driver: lapack.o dblas.o' > "$W/patch/makefile.inc"
tools/sandbox.sh "$ID" -- sh -c "cp /work/patch/makefile.inc /work/build/$DP/Drivers/makefile.inc" || { echo "PATCH-FAILED"; exit 1; }

# The record tool reads result.json; create an empty one if it is not there yet (the final result is written after).
[ -f "$root/reports/$ID/result.json" ] || echo '{}' > "$root/reports/$ID/result.json"

# G2 build-only proof, manifest 2 of 3: the build tree, immediately before the build command.
python3 -I tools/verify_sources.py manifest "$W/build/$DP" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' documented target, make Res1, in the build tree (compiles driver, src, lapack, dblas)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/$DP/Drivers && make Res1; echo make_exit=\$?" | tee "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build/$DP" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "make Res1" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Runs, twice (G3). Run 1: the Res1 output the build's make target wrote. Run 2: the driver binary in a clean directory.
tools/sandbox.sh "$ID" -- sh -c "cat /work/build/$DP/Drivers/Res1_1" > "$E/run1-Res1_1.txt" || echo "run1: no output"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run2 && mkdir /work/run2 && cp /work/build/$DP/Drivers/driver /work/run2/ && cp /work/build/$DP/Drivers/data1 /work/run2/ && cd /work/run2 && timeout 900 ./driver < data1 > Res1_1 2> stderr.txt; echo run2_exit=\$? >&2; cat Res1_1" > "$E/run2-Res1_1.txt" 2> "$E/run2-exit.txt"
cat "$E/run2-exit.txt"

# Second environment (diagnostic, not the recorded build): the same tree, a fresh copy, compiled at -O0 with the
# same authors' sources and the same make target. Written to its own evidence file; the verdict is decided below.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build0 && cp -r /work/build /work/build0 && cd /work/build0/$DP/Drivers && rm -f *.o driver Res1_1 Res1_2 && make Res1 F77OPTS='-O0 -std=legacy' FFLAGS='-O0 -std=legacy' 2>&1; echo make_exit=\$?" > "$E/env2-O0-build.log" 2>&1
tools/sandbox.sh "$ID" -- sh -c "cat /work/build0/$DP/Drivers/Res1_1" > "$E/env2-Res1_1.txt" || echo "env2: no output"

# Value: the second value after the count, row 3 of the output, printed with a D exponent; converted for the parser.
for pass in run1 run2 env2; do
  sed -n 3p "$E/$pass-Res1_1.txt" | tr 'Dd' 'Ee' | awk '{print $1}' > "$E/$pass-value.txt"
done
echo "== claimed value per pass (run1, run2 = -O2 recorded build; env2 = -O0 diagnostic)"
paste "$E/run1-value.txt" "$E/run2-value.txt" "$E/env2-value.txt"
echo "VALUE driver on data1, row 2 of res1 $(cat "$E/run2-value.txt")"
