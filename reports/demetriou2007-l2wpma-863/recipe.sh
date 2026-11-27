#!/usr/bin/env bash
# Canonical rerun for demetriou2007-l2wpma-863 (TOMS 863 L2WPMA, DRIVER1 on the Appendix B data set, Fortran 77).
# Claim: artifact-reference. The shipped reference is Data/Appndx_B/WIVAPP inside 863.zip (column 2 = ITHETA,
# the data indices of the extrema at the optimum, KSECTN = 5). Tolerance 0, integers: exact match.
# Fetch (network, sha256-checked): 863.zip from netlib; micromamba and gfortran from conda-forge.
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes and parses text.
#
# Original attempt (G1): the authors' Fortran with the host's toolchain (no gfortran on PATH). Log:
# evidence/original-attempt.log. The shipped Doc/Makefile has every FC/FFLAGS choice commented out, so the
# authors' documented build needs a compiler named by the builder.
#
# Build (basis patched, build-only): the authors' sources are copied, not edited (manifests pre, mid, post). The
# only build choices are the compiler (conda-forge gfortran) and its flags (-std=legacy -O2), the same two rules as
# the authors' Makefile (driver1.o and src.o linked into driver1). The sources are unchanged, so the build-only
# proof holds.
#
# Run (G3): DRIVER1 reads XFWDAT from the cwd, KSECTN from stdin (5), then two pauses (READ *). Twice from clean dirs.
set -uo pipefail
ID=demetriou2007-l2wpma-863
ZIP_SHA=5947abcafb61ea258152d11ba98f8c81e28fcdfbcef832144362c7ca6d5f7657
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
rm -rf "$W"; mkdir -p "$W"

echo "== fetch: archive 863.zip (sha256 checked), micromamba (no compiler yet)"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/863.zip https://netlib.org/toms/863.zip && echo '$ZIP_SHA  /work/863.zip' | sha256sum -c - && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): authors' Fortran with the sandbox toolchain as shipped (no gfortran yet)"
tools/sandbox.sh "$ID" -- sh -c "command -v gfortran || echo 'gfortran: not on PATH'; echo 'attempt: gfortran -std=legacy -O2 -o driver1 Drivers/driver1.f Src/src.f'; unzip_tmp=/work/orig; rm -rf \$unzip_tmp; mkdir \$unzip_tmp && cd \$unzip_tmp && python3 -m zipfile -e /work/863.zip . && cd 863/Fortran/Dp && (gfortran -std=legacy -O2 -o driver1 Drivers/driver1.f Src/src.f; echo \"exit=\$?\")" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== fetch: gfortran (conda-forge, via micromamba) into /work/gf"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/gf -c conda-forge --override-channels gfortran_linux-64 && ln -sf /work/gf/bin/x86_64-conda-linux-gnu-gfortran /work/gf/bin/gfortran" || { echo "GFORTRAN-INSTALL-FAILED"; exit 1; }

echo "== unpack: authors' archive, unedited (manifest pre)"
tools/sandbox.sh "$ID" -- sh -c "cd /work && rm -rf pre && mkdir pre && python3 -m zipfile -e 863.zip pre && find pre/863/Fortran/Dp -type f | sort" || { echo "UNPACK-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/pre/863" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") source files"

echo "== build tree: copy of the authors' tree (no edit) (manifest mid taken immediately before the build)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/863 /work/build && echo copied" || { echo "COPY-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "manifest.mid: $(wc -l < "$W/manifest.mid") source files"

echo "== build: DRIVER1 (authors' sources, flags only)"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/gf/bin:\$PATH && cd /work/build/Fortran/Dp && gfortran -std=legacy -O2 -o driver1 Drivers/driver1.f Src/src.f && echo build_ok && ls -l driver1" || { echo "BUILD-FAILED"; exit 1; }
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" --command 'gfortran -std=legacy -O2 -o driver1 Drivers/driver1.f Src/src.f' || { echo "RECORD-FAILED"; exit 1; }

echo "== run: DRIVER1 on the Appendix B XFWDAT, KSECTN 5, from clean dirs, twice (G3)"
tools/sandbox.sh "$ID" -- bash -c '
for i in 1 2; do
  rm -rf /work/run$i && mkdir -p /work/run$i && cp /work/pre/863/Data/Appndx_B/XFWDAT /work/run$i/ && cd /work/run$i
  printf "5\n\n\n" | /work/build/Fortran/Dp/driver1 > stdout.txt 2>&1 || { echo "DRIVER-FAILED pass $i"; exit 1; }
  [ -s WIVAPP ] || { echo "NO-WIVAPP pass $i"; exit 1; }
  echo "== pass $i WIVAPP (I ITHETA):"; cat WIVAPP
  awk '"'"'{ print "VALUE extremum index " $1 " " $2 }'"'"' WIVAPP > values.txt
done
diff /work/run1/values.txt /work/run2/values.txt && echo "PASSES AGREE"
cat /work/run1/values.txt
' || { echo "RUN-FAILED"; exit 1; }

echo "== compare with the shipped reference (Data/Appndx_B/WIVAPP, column 2)"
tools/sandbox.sh "$ID" -- bash -c 'diff <(awk "{ print \$2 }" /work/pre/863/Data/Appndx_B/WIVAPP) <(awk "{ print \$2 }" /work/run1/WIVAPP) && echo "SHIPPED REFERENCE MATCHES"' || echo "REFERENCE-DIFFERS"
echo "== done"
