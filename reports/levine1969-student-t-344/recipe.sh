#!/usr/bin/env bash
# Rebuilds the rerun verdict for levine1969-student-t-344 (TOMS 344, TTEST / Student's t CDF, Fortran).
# Fetch (the only network step, inside the sandbox): netlib TOMS 344.gz (sha256 checked), gunzipped, the shar unpacked
# with sh into /work/pre (Fortran/Sp/Drivers/{Makefile,driver.f,res}, Fortran/Sp/Src/src.f), and gfortran from
# conda-forge (micromamba) into the sandbox scratch at /work/fortran. Everything else runs through tools/sandbox.sh.
# Original attempt (G1): the shipped Drivers/Makefile run as documented, with gfortran as F77. It fails: the makefile
# compiles src.f from the Drivers directory, but src.f lives in Src/. Log kept once in evidence/original-attempt.log.
# Patch (basis patched): build-only. The makefile cannot compile src.f from Drivers (its rule names src.f with no
# path, and VPATH does not change the command). So the same three compiles are run out of tree with the makefile's
# own flags (gfortran -O0): driver.f, ../Src/src.f, then the link. No source file is edited, proven by three
# manifests (verify_sources record).
# Claim: the computed CDF printed by driver for DF=1, X=0.3250 (row 1, computed column) compared with the shipped
# value 0.7999537587165833 from res, absolute tolerance 1e-6.
# Two passes (G3): each in its own clean directory.
set -uo pipefail
ID=levine1969-student-t-344
URL=https://netlib.org/toms/344.gz
SHA=053ed92f6d08c5d8d2f7f92dcba8698d2bede20c29293e0564cfc62da8c66866
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 344.gz (sha256 checked), shar unpacked with sh; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/build /work/g1 /work/out; mkdir /work/pre; cd /work; curl -fsSL -o 344.gz '$URL'; echo '$SHA  344.gz' | sha256sum -c -; gunzip -kf 344.gz; L=\$(grep -n '^#! /bin/sh' 344 | head -1 | cut -d: -f1); sed -n \"\$L,\\\$p\" 344 > pre/shar.sh; cd pre && sh shar.sh; test -f Fortran/Sp/Drivers/driver.f && test -f Fortran/Sp/Src/src.f; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: the res file, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/Fortran/Sp/Drivers/res > "$E/reference/res"
grep -m1 "^ *1 *0.3250" "$E/reference/res"

# G2 build-only proof, manifest 1 of 3: the authors' bytes right after unpacking, before any patch.
python3 -I tools/verify_sources.py manifest "$W/pre/Fortran/Sp" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }

# G1 original attempt: the shipped makefile as documented, with gfortran as F77. Expected to fail (src.f not in Drivers).
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/Fortran/Sp /work/g1 && cd /work/g1/Drivers && make F77=$G F77OPTS=-O0 SRCLIBS= DIFF=diff 2>&1; echo make_exit=\$?" > "$ORIG" 2>&1
tail -2 "$ORIG"

# The build tree: a copy of the authors' Fortran/Sp tree. Outputs of the build go into the copied Drivers directory.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/Fortran/Sp /work/build" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' sources compiled out of tree with the makefile's flags (gfortran -O0), then linked"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/out && mkdir /work/out && cd /work/out && /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -c /work/build/Drivers/driver.f -o driver.o 2>&1; echo d_exit=\$?; /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -c /work/build/Src/src.f -o src.o 2>&1; echo s_exit=\$?; /work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -o driver driver.o src.o 2>&1; echo link_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
[ -f "$root/reports/$ID/result.json" ] || echo '{}' > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "/work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -c /work/build/Drivers/driver.f -o driver.o" \
  --command "/work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -c /work/build/Src/src.f -o src.o" \
  --command "/work/fortran/bin/x86_64-conda-linux-gnu-gfortran -O0 -o driver driver.o src.o" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Runs, twice (G3): each pass in a clean directory; the driver prints the table to stdout.
for pass in run1 run2; do
  echo "== $pass: clean directory, the driver"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/out/driver /work/$pass/ && cd /work/$pass && timeout 300 ./driver > out.txt 2> stderr.txt; echo ${pass}_run_exit=\$?; cp out.txt /work/$pass-out.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-out.txt > "$E/$pass-out.txt"
  awk '$1 == "1" && $2 == "0.3250" {print $4; exit}' "$E/$pass-out.txt" > "$E/$pass-value.txt"
  echo "$pass row DF=1 X=0.3250 computed CDF: $(cat "$E/$pass-value.txt")"
done

echo "== claimed values per pass"
paste "$E/run1-value.txt" "$E/run2-value.txt"
echo "VALUE TTEST, DF=1, X=0.3250, two-tailed CDF transform (computed column) $(cat "$E/run2-value.txt")"
