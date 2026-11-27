#!/usr/bin/env bash
# Rebuilds the rerun record for cabay1997-vecpade-766 (TOMS 766, Pade'-Hermite and simultaneous Pade' approximants,
# Fortran 90). Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes sources
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 766.gz (sha256 checked), gunzipped, the shar header
# above the '#! /bin/sh' line removed, and the shar run with /bin/sh into /work/pre. gfortran (conda-forge, micromamba)
# into /work/fortran if missing.
#
# Original attempt (G1): the authors' readme build set (driver1.f90, vector_pade.f90, linpack.f) as shipped. It fails
# to link: linpack.f calls the BLAS routines isamax, sscal, saxpy, sdot, which live in Src/Sp/blas1.f and are not in
# the readme's list. Log: evidence/original-attempt.log.
#
# Build (basis patched, build-only): no source file is edited. The one change is to the build: blas1.f is compiled
# separately with -ffree-form, because its continuation lines use free-form '&' in a file named .f. Nothing in the
# unpacked tree changes between the mid manifest and the post manifest.
#
# Claim: entry (2,3) of the z**1 coefficient matrix of Pade'-Hermite System S printed by driver1 (multiplied by 37;
# RES1 prints -131), tol_abs 0.5. Two passes (G3): pass 1 in /work/out1 and pass 2 in /work/out2, same commands.
set -uo pipefail
ID=cabay1997-vecpade-766
URL=https://netlib.org/toms/766.gz
SHA=f62245620e2f3c48b7c5555c266adfbb9a496fc3d74d5cc9941cf96cb8d40acd
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 766.gz (sha256 checked), shar unpacked to /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- bash -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/766.gz '$URL'; echo '$SHA  /work/766.gz' | sha256sum -c -; gunzip -c /work/766.gz > /work/766.shar; sed '1,/^#! \/bin\/sh/{/^#! \/bin\/sh/!d;}' /work/766.shar > /work/pre/766.sh; cd /work/pre && sh 766.sh > /work/unpack.log 2>&1; test -f /work/pre/Src/Sp/blas1.f; test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the readme build set as shipped (no blas1.f)"
tools/sandbox.sh "$ID" -- bash -c "rm -rf /work/orig && mkdir /work/orig && cd /work/orig && $G -o driver1 /work/pre/Drivers/Sp/driver1.f90 /work/pre/Src/Sp/vector_pade.f90 /work/pre/Src/Sp/linpack.f; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|undefined reference' "$E/original-attempt.log" | head -4

echo "== manifest pre: the unpacked tree, before any build step"
python3 tools/verify_sources.py manifest "$SCRATCH/pre" > "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== manifest mid: no patch step (none needed); immediately before the build"
python3 tools/verify_sources.py manifest "$SCRATCH/pre" > "$E/manifest.mid"

echo "== build commands (no editing of the tree): pass 1 in /work/out1, pass 2 in /work/out2"
tools/sandbox.sh "$ID" -- bash -c "rm -rf /work/out1 /work/out2 && mkdir /work/out1 /work/out2 && cd /work/out1 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -ffree-form -c /work/pre/Src/Sp/blas1.f -o blas1.o && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -o driver1 /work/pre/Drivers/Sp/driver1.f90 /work/pre/Src/Sp/vector_pade.f90 /work/pre/Src/Sp/linpack.f blas1.o; echo pass1_build_exit=\$?; cd /work/out2 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -ffree-form -c /work/pre/Src/Sp/blas1.f -o blas1.o && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -o driver1 /work/pre/Drivers/Sp/driver1.f90 /work/pre/Src/Sp/vector_pade.f90 /work/pre/Src/Sp/linpack.f blas1.o; echo pass2_build_exit=\$?" > "$E/build.log" 2>&1
grep -E 'build_exit=' "$E/build.log"

echo "== manifest post: after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/pre" > "$E/manifest.post"
wc -l < "$E/manifest.post"

echo "== record the build-only check (G2 exemption, exit 0 means build-only)"
python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifest.pre" --mid "$E/manifest.mid" --post "$E/manifest.post" \
  --command "$G -ffree-form -c /work/pre/Src/Sp/blas1.f -o blas1.o" \
  --command "$G -o driver1 /work/pre/Drivers/Sp/driver1.f90 /work/pre/Src/Sp/vector_pade.f90 /work/pre/Src/Sp/linpack.f blas1.o"
echo "record_exit=$?"

echo "== runs: pass 1 and pass 2 (driver1 takes no input)"
tools/sandbox.sh "$ID" -- bash -c "cd /work/out1 && ./driver1 > /work/run1.txt 2>&1; echo run1_exit=\$?; cd /work/out2 && ./driver1 > /work/run2.txt 2>&1; echo run2_exit=\$?" > "$E/run.log" 2>&1
grep -E 'run[12]_exit=' "$E/run.log"
tools/sandbox.sh "$ID" -- cat /work/run1.txt > "$E/pass1-output.txt" 2>/dev/null
tools/sandbox.sh "$ID" -- cat /work/run2.txt > "$E/pass2-output.txt" 2>/dev/null
tools/sandbox.sh "$ID" -- cat /work/pre/Drivers/Sp/RES1 > "$E/reference/RES1" 2>/dev/null

echo "== values: System S, z**1 coefficient matrix, entry (row 2, col 3), times 37, from each pass"
python3 -I - "$E" <<'PY' > "$E/values.txt"
import os, sys
E = sys.argv[1]
def entry(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    start = next(i for i, l in enumerate(lines) if "Pade'-Hermite System S" in l)
    z1 = next(i for i in range(start, len(lines)) if "Coefficient matrix of z**1" in lines[i])
    row2 = lines[z1 + 2].split()
    return float(row2[2])
name = "System S, z**1 coefficient matrix, entry (2,3), times 37 (RES1 value -131)"
v1 = entry(os.path.join(E, "pass1-output.txt"))
v2 = entry(os.path.join(E, "pass2-output.txt"))
print(f"pass1 {v1!r}")
print(f"pass2 {v2!r}")
print(f"VALUE {name} {v1!r}")
PY
cat "$E/values.txt"
