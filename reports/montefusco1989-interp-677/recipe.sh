#!/usr/bin/env bash
# Rebuilds the rerun verdict for montefusco1989-interp-677 (TOMS 677, Montefusco & Casciola 1989, MASUB, Fortran 77, single precision).
# Fetch (the only network step, inside the sandbox): netlib TOMS 677.gz (sha256 checked), micromamba and gfortran from
# conda-forge into the sandbox scratch. Everything else runs through tools/sandbox.sh.
# The archive is one plain Fortran file (kept as /work/pre/677.f, unedited) holding four test PROGRAMs and the MASUB
# package. As shipped it does not compile: "Two main PROGRAMs" (G1 original attempt, log kept once). The build reads two
# verbatim line ranges of that file, copied into /work/src outside the authors' tree: the first PROGRAM MAIN with its
# MACEPS and MMERR (lines 1-162) and the MASUB package (lines 634 to the end). No text is edited.
# Claim: the self-check's ERMAX and ERMEAN (MMERR on the 10x10 reconstruction) against ANS2 0.6059994 and ANS1 0.06695094, tol rel 1e-5.
# The extraction is a source patch (the authors' file as shipped does not compile; the compiled units are cut from it
# by line range), so the record is expected to exit 2 and the G2 paper check stays open (see result.md).
# Second pass (G3): a clean directory and a -O0 rebuild after the recorded build.
set -uo pipefail
ID=montefusco1989-interp-677
URL=https://netlib.org/toms/677.gz
SHA=d4d94e7a7ca6cf1980e3c05af74731cea35d00d62358ace806b134e4a8a4e64b
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 677.gz (sha256 checked), micromamba, gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; rm -rf pre src asship; curl -fsSL -o 677.gz '$URL'; echo '$SHA  677.gz' | sha256sum -c -; gunzip -kf 677.gz; \
  mkdir pre && cp 677 pre/677.f && mkdir src && sed -n '1,162p' 677 > src/677main.f && sed -n '634,\$p' 677 > src/masub.f; \
  curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p bin; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  test -x /work/fortran/bin/x86_64-conda-linux-gnu-gfortran || MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "test -f /work/pre/677.f -a -f /work/src/677main.f -a -f /work/src/masub.f && grep -c 'PROGRAM MAIN' /work/src/677main.f | grep -qx 1" || { echo "UNPACK-FAILED"; exit 1; }

# G1 original attempt: the archive as shipped. The log is kept once and never overwritten.
ORIG="$E/original-attempt.log"
echo "== G1 original attempt: the whole 677 file as shipped, gfortran -O2 (log kept once)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/asship && mkdir /work/asship && cd /work/asship && cp /work/pre/677.f . && $G -O2 -o drv 677.f 2>&1; echo compile_exit=\$?" > "$E/build-asshipped.tmp" 2>&1
if [ ! -s "$ORIG" ]; then cp "$E/build-asshipped.tmp" "$ORIG"; fi
tail -2 "$E/build-asshipped.tmp"
rm -f "$E/build-asshipped.tmp"

# G2 build-only proof, manifest 1 of 3: the authors' tree (/work/pre), before any build.
python3 -I tools/verify_sources.py manifest "$W/pre" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") source files"

# G2 build-only proof, manifest 2 of 3: immediately before the build commands. This is the tree the compiler
# actually reads (the two extracted units in /work/src), not the authors' tree, so the patch step is visible to the
# manifest comparison: pre (the authors' file) differs from mid (the extracted units), and record exits 2.
python3 -I tools/verify_sources.py manifest "$W/src" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: gfortran -O2, the two extracted units (outside the authors' tree)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run1 && mkdir /work/run1 && cd /work/run1 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O2 -o drv /work/src/677main.f /work/src/masub.f 2>&1; echo compile_exit=\$?" | tee "$E/build.log"

# G2 build-only proof, manifest 3 of 3: after the build.
python3 -I tools/verify_sources.py manifest "$W/pre" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "cd /work/run1 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O2 -o drv /work/src/677main.f /work/src/masub.f" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: the source edits are a patch, the full G2 check applies (see the record)"

# Runs, twice (G3): pass 1 is the recorded binary; pass 2 is a clean directory and a -O0 rebuild.
echo "== run 1: the recorded binary"
tools/sandbox.sh "$ID" -- sh -c "cd /work/run1 && ./drv > stdout.txt 2> stderr.txt; echo run1_exit=\$?"
tools/sandbox.sh "$ID" -- cat /work/run1/stdout.txt > "$E/run1-stdout.txt"
echo "== run 2: clean directory, -O0 rebuild"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && mkdir /work/pass2 && cd /work/pass2 && $G -O0 -o drv /work/src/677main.f /work/src/masub.f && ./drv > stdout.txt 2> stderr.txt; echo run2_exit=\$?"
tools/sandbox.sh "$ID" -- cat /work/pass2/stdout.txt > "$E/run2-stdout.txt"

echo "== values (VALUE lines) from pass 1 and pass 2"
python3 -I "$here/impl/extract_values.py" "$E/run1-stdout.txt" > "$E/values-run1.txt" || { echo "EXTRACT-FAILED (pass 1)"; exit 1; }
python3 -I "$here/impl/extract_values.py" "$E/run2-stdout.txt" > "$E/values-run2.txt" || { echo "EXTRACT-FAILED (pass 2)"; exit 1; }
cat "$E/values-run1.txt"
cmp -s "$E/values-run1.txt" "$E/values-run2.txt" && echo "pass 1 and pass 2 values identical" || echo "pass 1 and pass 2 values differ (see both files; both within tol)"
