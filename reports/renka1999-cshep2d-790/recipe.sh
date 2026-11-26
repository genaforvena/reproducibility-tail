#!/usr/bin/env bash
# Rebuilds the rerun verdict for renka1999-cshep2d-790 (TOMS 790, CSHEP2D test program CS2TST, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 790.gz (sha256 checked), gunzipped, the shar unpacked
# with sh into /work/pre (Fortran77/Drivers/Sp: driver1.f, driver2.f, src_792.f, data1, res1, res1_2, res2;
# Fortran77/Src/Sp/src.f), and gfortran from conda-forge (micromamba) into the sandbox scratch at /work/fortran.
# Everything else runs through tools/sandbox.sh.
# The archive ships no build command. Original attempt (G1): driver1.f compiled alone, as shipped. It fails at link:
# the test routines TESTDT and TSTFN1 (src_792.f) and CSHEP2D (src.f) are not in it. Log: evidence/original-attempt.log.
# Patch (basis patched): build-only. The authors' own sources are compiled together, out of tree, with gfortran -O0;
# no source file is edited. Proven by three manifests (verify_sources record).
# Claim: the Max Error for function 1, node set 1 (N=100, NI=33, NC=17, NW=30, NR=6), as printed to res1_2 by driver1,
# against the shipped 0.0451, absolute tolerance 5e-5 (half of the last printed unit).
# Input: the first six lines of data1 (node set 1: KS, first function, last function, NC, NW, NR).
# Two passes (G3): each in its own clean directory.
set -uo pipefail
ID=renka1999-cshep2d-790
URL=https://netlib.org/toms/790.gz
SHA=ac71fab09b7dd3715c0b1bb79bc77d3d95bcfd46141935a2cd9e2df1837718ff
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 790.gz (sha256 checked), shar unpacked with sh; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/build /work/g1 /work/out; mkdir /work/pre; cd /work; curl -fsSL -o 790.gz '$URL'; echo '$SHA  790.gz' | sha256sum -c -; gunzip -kf 790.gz; L=\$(grep -n '^#! /bin/sh' 790 | head -1 | cut -d: -f1); sed -n \"\$L,\\\$p\" 790 > pre/shar.sh; cd pre && sh shar.sh; test -f Fortran77/Drivers/Sp/driver1.f && test -f Fortran77/Src/Sp/src.f && test -f Fortran77/Drivers/Sp/src_792.f && test -f Fortran77/Drivers/Sp/res1_2; \
  test -x /work/fortran/bin/x86_64-conda-linux-gnu-gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: res1_2, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/Fortran77/Drivers/Sp/res1_2 > "$E/reference/res1_2"
grep -m1 "^ *1 *0.0451" "$E/reference/res1_2"

# G2 build-only proof, manifest 1 of 3: the authors' bytes right after unpacking, before any patch.
python3 -I tools/verify_sources.py manifest "$W/pre/Fortran77" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }

# G1 original attempt: driver1.f compiled alone, as shipped. Expected to fail at link (external routines absent).
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && mkdir /work/g1 && cd /work/g1 && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -o driver1 /work/pre/Fortran77/Drivers/Sp/driver1.f 2>&1; echo link_exit=\$?" > "$ORIG" 2>&1
tail -2 "$ORIG"

# The build tree: a copy of the authors' Fortran77 tree. Outputs go to /work/out, outside the tree.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/Fortran77 /work/build && mkdir -p /work/out" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' driver1.f, src_792.f and src.f compiled together out of tree (gfortran -O0)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/out && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -o cs2tst /work/build/Drivers/Sp/driver1.f /work/build/Drivers/Sp/src_792.f /work/build/Src/Sp/src.f 2>&1; echo link_exit=\$?" > "$E/build.log" 2>&1
tail -2 "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
[ -f "$root/reports/$ID/result.json" ] || echo '{}' > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "/work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -o cs2tst /work/build/Drivers/Sp/driver1.f /work/build/Drivers/Sp/src_792.f /work/build/Src/Sp/src.f" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Runs, twice (G3): each pass in a clean directory; driver1 reads node set 1 from the first six lines of data1.
for pass in run1 run2; do
  echo "== $pass: clean directory, cs2tst with the node set 1 input"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/out/cs2tst /work/$pass/ && cd /work/$pass && head -6 /work/build/Drivers/Sp/data1 | timeout 600 ./cs2tst > stdout.txt 2> stderr.txt; echo ${pass}_run_exit=\$?; cp res1_2 /work/$pass-res1_2; cp stdout.txt /work/$pass-stdout.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-res1_2 > "$E/$pass-res1_2"
  awk '$1 == "1" && NF == 4 {print $2; exit}' "$E/$pass-res1_2" > "$E/$pass-value.txt"
  echo "$pass function 1 Max Error: $(cat "$E/$pass-value.txt")"
done

echo "== claimed values per pass"
paste "$E/run1-value.txt" "$E/run2-value.txt"
echo "VALUE CS2TST node set 1, function 1, Max Error (4 decimal print) $(cat "$E/run2-value.txt")"
