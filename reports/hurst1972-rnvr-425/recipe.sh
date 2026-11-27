#!/usr/bin/env bash
# Canonical rerun for hurst1972-rnvr-425 (TOMS/CALGO 425, RNVR, the TEST02 block of the shipped driver).
# Claim: artifact-reference. The shipped reference is Fortran/Sp/Drivers/res inside 425.gz (TEST02: 10 samples,
# 2 components, format g14.6, covariance [1 0.3; 0.3 1]). 20 values, tolerance 1e-5 absolute.
# Fetch (network, sha256-checked): 425.gz from netlib; micromamba and gfortran from conda-forge.
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes and parses text.
#
# Original attempt (G1): the authors' Makefile with the sandbox toolchain as shipped (no gfortran yet). Log:
# evidence/original-attempt.log. The shipped Makefile names no compiler (F77 and F77OPTS are empty) and its
# src.o rule looks for src.f next to the Drivers directory, where the archive does not put it.
#
# Build (basis patched, build-only): the authors' tree is copied, not edited (manifests pre, mid, post). The only
# build choices are make variables: F77=gfortran, F77OPTS=-O2, and VPATH=../Src so make finds the authors'
# Src/src.f without copying it. Run is a separate step; the Makefile's Res target is not used so that the
# driver's output is captured by this recipe.
#
# Run (G3): the driver takes no input. Twice from clean directories; the TEST02 values are printed as
# "VALUE <name> <number>" lines, parsed from the printed table.
set -uo pipefail
ID=hurst1972-rnvr-425
GZ_SHA=000dc68c060cad2f2941ebf85edb2f762f653b5ed6ed7783e39b53109ec9852b
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
rm -rf "$W"/pre "$W"/build "$W"/orig "$W"/run1 "$W"/run2; mkdir -p "$W"

echo "== fetch: archive 425.gz (sha256 checked), micromamba, gfortran (conda-forge); skipped when /work/env16 already has gfortran"
tools/sandbox.sh --fetch "$ID" -- sh -c "test -x /work/env16/bin/gfortran || { curl -fsSL -o /work/425.gz https://netlib.org/toms/425.gz && echo '$GZ_SHA  /work/425.gz' | sha256sum -c - && mkdir -p /work/bin && curl -fsSL -o /work/mm.tar.bz2 '$MM' && tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba && /work/bin/micromamba create -y -r /work/mamba -p /work/env16 -c conda-forge --override-channels gfortran_linux-64 make; }; test -x /work/env16/bin/gfortran" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "echo '$GZ_SHA  /work/425.gz' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }

echo "== original attempt (G1): authors' Makefile as shipped, no compiler named"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && gunzip -c /work/425.gz | sed -n '/^#! \/bin\/sh/,\$p' > unpack.sh && sh unpack.sh && cd Fortran/Sp/Drivers && echo 'attempt: make Res (as shipped)' && (command -v gfortran || echo 'gfortran: not on PATH'); (make Res 2>&1; echo make_exit=\$?)" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== unpack: authors' archive, unedited (manifest pre)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pre && mkdir -p /work/pre && cd /work/pre && gunzip -c /work/425.gz | sed -n '/^#! \/bin\/sh/,\$p' > /work/unpack.sh && sh /work/unpack.sh && find Fortran -type f | sort" || { echo "UNPACK-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/pre" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") source files"

echo "== build tree: copy of the authors' tree (no edit) (manifest mid taken immediately before the build)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre /work/build && echo copied" || { echo "COPY-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "manifest.mid: $(wc -l < "$W/manifest.mid") source files"

echo "== build: driver (the Makefile rules by hand: its src.o rule expects src.f beside the driver; the archive puts it in Src)"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env16/bin:\$PATH && cd /work/build/Fortran/Sp/Drivers && gfortran -O2 -c driver.f && gfortran -O2 -c ../Src/src.f -o src.o && gfortran -O2 -o driver driver.o src.o && echo build_ok && ls -l driver" || { echo "BUILD-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
[ -f "$root/reports/$ID/result.json" ] || echo "{\"paper\": {\"short\": \"$ID\"}}" > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" --command 'gfortran -O2 -c driver.f' --command 'gfortran -O2 -c ../Src/src.f -o src.o' --command 'gfortran -O2 -o driver driver.o src.o' || { echo "RECORD-FAILED"; exit 1; }

echo "== run: driver twice from clean directories (G3); TEST02 block parsed on the host from the captured stdout"
for i in 1 2; do
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run$i && mkdir -p /work/run$i && cd /work/run$i && /work/build/Fortran/Sp/Drivers/driver > stdout.txt 2>&1; echo driver_exit=\$?" || { echo "RUN-FAILED pass $i"; exit 1; }
  python3 -I "$here/impl/parse_hurst.py" "$W/run$i/stdout.txt" > "$W/run$i/values.txt" || { echo "PARSE-FAILED pass $i"; exit 1; }
  echo "== pass $i TEST02 values:"; cat "$W/run$i/values.txt"
done
diff "$W/run1/values.txt" "$W/run2/values.txt" && echo "PASSES AGREE"

echo "== done"
