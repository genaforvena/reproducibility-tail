#!/usr/bin/env bash
# Rebuilds the rerun verdict for wise2000-polsys-plp-801 (TOMS 801, POLSYS_PLP, Fortran 90).
# Fetch (the only network step, inside the sandbox): netlib TOMS 801.gz (sha256 checked), gunzipped to /work/801.txt,
# the shell archive (lines 4..end) unpacked with sh into /work/pre (Fortran90/Dp/...); micromamba, gfortran 13 (conda-forge
# latest, /work/fortran) and gfortran 9.5 (conda-forge, pinned, /work/gf9) into the sandbox scratch.
# Original attempt (G1): the authors' sources as the README describes, with gfortran 13. It FAILS: polsys_plp.f90 is
# rejected with "Index variable 'iter' redefined" (ITER is modified inside ROOT_PLP while a caller DO loop uses it).
# Log: evidence/original-attempt.log. -std=legacy does not lift the error (evidence/legacy-attempt.log).
# Patch (basis patched): build-only toolchain change. The same unedited sources are compiled with gfortran 9.5 and the
# README's flags, out of tree. No source file is edited; three manifests prove it (verify_sources record).
# Pass 1 (the proof build): -O0, run of the archive's INPUT.DAT with main_template (writes OUTPUT.DAT).
# Pass 2: -O2 in a separate tree, same sources (copied from /work/pre), a second compile environment.
# Claim: Re X(2) of the first problem's real finite solution (X(1) near 2342.3), against the shipped OUTPUT.DAT value
# -7.88344824094120E-01, absolute tolerance 1e-6.
set -uo pipefail
ID=wise2000-polsys-plp-801
URL=https://netlib.org/toms/801.gz
SHA=ea179f8d264d8130755145cfe02f51a2d789ae7d6d3fde55bddbd725d9ff78ad
G13=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
G9=/work/gf9/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 801.gz (sha256 checked), unpacked into /work/pre; micromamba + gfortran 13 and 9.5 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 801.gz '$URL'; echo '$SHA  801.gz' | sha256sum -c -; gunzip -c 801.gz > 801.txt; \
  rm -rf pre && mkdir pre && cd pre && sed -n '4,\$p' ../801.txt > ../shar.sh && sh ../shar.sh; test -f /work/pre/Fortran90/Dp/Src/polsys_plp.f90; \
  test -x $G13 || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  test -x $G9 || MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/gf9 -c conda-forge 'gfortran_linux-64=9'" || { echo "FETCH-FAILED"; exit 1; }

# G2 build-only proof, manifest 1 of 3: the authors' bytes right after unpacking, before any patch.
python3 -I tools/verify_sources.py manifest "$W/pre/Fortran90/Dp" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }

echo "== shipped reference: OUTPUT.DAT of the archive, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/Fortran90/Dp/Drivers/OUTPUT.DAT > "$E/reference/OUTPUT.DAT"
grep -m1 "TWO REAL SOLUTIONS" "$E/reference/OUTPUT.DAT"

echo "== original attempt (G1): authors' sources with the latest gfortran (gfortran 13), as the README describes"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/Fortran90/Dp /work/g1 && cd /work/g1/Src && $G13 -O0 -c -ffree-form polsys_plp.f90 && $G13 -O0 -c -ffixed-form -ffixed-line-length-none lapack_plp.f && cd /work/g1/Drivers && $G13 -O0 -I/work/g1/Src -c main_template.f90 && $G13 -O0 -o main_template main_template.o ../Src/polsys_plp.o ../Src/lapack_plp.o; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -1 "$E/original-attempt.log"
echo "== legacy-standard experiment (not a verdict): -std=legacy with gfortran 13"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/t2 && cp -r /work/pre/Fortran90/Dp /work/t2 && cd /work/t2/Src && $G13 -O0 -std=legacy -c -ffree-form polsys_plp.f90; echo build_exit=\$?" > "$E/legacy-attempt.log" 2>&1
tail -1 "$E/legacy-attempt.log"

echo "== build tree: a copy of the authors' Fortran90/Dp (outputs stay in the scratch build tree)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/Fortran90/Dp /work/build" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build pass 1 (gfortran 9.5, -O0): the authors' sources, compiled and linked out of tree"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Src && /work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -c -ffree-form polsys_plp.f90 && /work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -c -ffixed-form -ffixed-line-length-none lapack_plp.f && cd /work/build/Drivers && /work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -I/work/build/Src -c main_template.f90 && /work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -o main_template main_template.o ../Src/polsys_plp.o ../Src/lapack_plp.o; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -1 "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
[ -f "$root/reports/$ID/result.json" ] || echo '{}' > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "/work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -c -ffree-form polsys_plp.f90" \
  --command "/work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -c -ffixed-form -ffixed-line-length-none lapack_plp.f" \
  --command "/work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -I/work/build/Src -c main_template.f90" \
  --command "/work/gf9/bin/x86_64-conda-linux-gnu-gfortran -O0 -o main_template main_template.o ../Src/polsys_plp.o ../Src/lapack_plp.o" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

echo "== run pass 1: the archive's INPUT.DAT through main_template (sandbox, writes OUTPUT.DAT in /work/build/Drivers)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Drivers && (timeout 900 ./main_template; echo run_exit=\$?)" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log" || echo "pass1: run did not finish"
tools/sandbox.sh "$ID" -- cat /work/build/Drivers/OUTPUT.DAT > "$E/pass1-OUTPUT.DAT"

echo "== pass 2 (gfortran 9.5, -O2, separate tree from the same copied sources)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/pre/Fortran90/Dp /work/pass2 && cd /work/pass2/Src && $G9 -O2 -c -ffree-form polsys_plp.f90 && $G9 -O2 -c -ffixed-form -ffixed-line-length-none lapack_plp.f && cd /work/pass2/Drivers && $G9 -O2 -I/work/pass2/Src -c main_template.f90 && $G9 -O2 -o main_template main_template.o ../Src/polsys_plp.o ../Src/lapack_plp.o && (timeout 900 ./main_template; echo run_exit=\$?)" > "$E/pass2-run.log" 2>&1
grep -E '^run_exit=' "$E/pass2-run.log" || echo "pass2: run did not finish"
tools/sandbox.sh "$ID" -- cat /work/pass2/Drivers/OUTPUT.DAT > "$E/pass2-OUTPUT.DAT"

echo "== value: first REAL, FINITE solution (X(1) real part near 2342.3) and its X(2) real part"
for p in pass1 pass2; do
  awk '/^REAL, FINITE SOLUTION/{f=1} f && /^X\( 2\) = \(/{gsub(/[(),]/,""); print $(NF-1); exit}' "$E/$p-OUTPUT.DAT" > "$E/value-$p.txt"
done
echo "VALUE TWO QUADRICS real finite solution, Re X(2) $(cat "$E/value-pass1.txt")"
echo "PASS2 VALUE TWO QUADRICS real finite solution, Re X(2) $(cat "$E/value-pass2.txt")"
