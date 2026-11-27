#!/usr/bin/env bash
# Rebuilds the rerun record for benner2006-hapack-854 (ACM TOMS 854, HAPACK 1.1, Fortran 77, Benner and Kressner).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes and reads text.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 854.zip, sha256 checked against the value in the
# queue entry, unpacked to /work/pre/854. gfortran (conda-forge, micromamba) into /work/fortran if missing.
# LAPACK and BLAS are the system's reference libraries (liblapack.so, libblas.so), read-only in the sandbox.
#
# Original attempt (G1): the authors' documented make, as shipped. The Src and Drivers makefiles include ../make.inc,
# which the archive does not ship; the template is Doc/make.inc, whose compiler is f77 (not installed here). The
# attempt copies the template and runs make: it fails at the compiler. Log: evidence/original-attempt.log.
#
# Build (basis patched, build-only): the authors' own source files are compiled by gfortran with the authors'
# documented options (their make.inc macros, OPTS -O2 with -std=legacy and -fallow-argument-mismatch for gfortran),
# archived into hapack.a, and TDHAESU is linked against the system LAPACK and BLAS. No make.inc is written and no
# source file is edited: the manifests pre, mid and post show it (verify_sources record), and the build commands are
# the ones between the second and third manifest calls below.
#
# Run: TDHAESU reads dhaesu.dat from stdin and prints the stable eigenvalues; WR(1) is compared with the shipped
# reference dhaesu.res (row i=1, -3.1941) with the registered tolerance 1e-4.
set -uo pipefail
ID=benner2006-hapack-854
URL=https://netlib.org/toms/854.zip
SHA=dc9ab3fb0bc12bd5c7d5b8ea8b5805bb7a8b6c38b0926f519632be4cdb580c66
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 854.zip (sha256 checked), unpacked to /work/pre/854; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/854.zip '$URL'; \
  echo \"sha256 \$(sha256sum /work/854.zip | cut -d' ' -f1) expected $SHA\"; \
  echo \"$SHA  /work/854.zip\" | sha256sum -c -; \
  python3 -c 'import zipfile;zipfile.ZipFile(\"/work/854.zip\").extractall(\"/work/pre\")'; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  mkdir -p /work/bin && ln -sf $G /work/bin/gfortran && gfortran --version | head -1" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== original attempt (G1): the authors' documented make with the template's compiler (f77)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -a /work/pre/854/. /work/orig/ && cd /work/orig && cp Doc/make.inc Fortran77/Dp/make.inc && cd Fortran77/Dp/Src && make; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -5 "$E/original-attempt.log"

echo "== pre: the unpacked archive, before any change"
python3 -I tools/verify_sources.py manifest "$SCR/pre/854" > "$E/manifest.pre"

echo "== prepare: copy the unpacked tree to /work/build (no edits)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && mkdir /work/build && cp -a /work/pre/854/. /work/build/ && echo copied" > "$E/prepare.log" 2>&1
cat "$E/prepare.log"

echo "== mid: immediately before the build commands"
python3 -I tools/verify_sources.py manifest "$SCR/build" > "$E/manifest.mid"

echo "== build: library from the Src files (46 .f), then TDHAESU from tdhaesu.f, against system LAPACK and BLAS"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && cd Fortran77/Dp/Src && gfortran -O2 -std=legacy -w -fallow-argument-mismatch -c *.f && ar crs ../hapack.a *.o; echo src_exit=\$?; cd /work/build && cd Fortran77/Dp/Drivers && gfortran -O2 -std=legacy -w -fallow-argument-mismatch tdhaesu.f -o tdhaesu ../hapack.a -L/usr/lib/x86_64-linux-gnu -llapack -lblas; echo drv_exit=\$?; ls -l tdhaesu ../hapack.a" > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== post: after the build"
python3 -I tools/verify_sources.py manifest "$SCR/build" > "$E/manifest.post"

echo "== record: the patch record from the three manifests and the build commands"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifest.pre" --mid "$E/manifest.mid" --post "$E/manifest.post" \
  --command "cd Fortran77/Dp/Src && gfortran -O2 -std=legacy -w -fallow-argument-mismatch -c *.f && ar crs ../hapack.a *.o" \
  --command "cd Fortran77/Dp/Drivers && gfortran -O2 -std=legacy -w -fallow-argument-mismatch tdhaesu.f -o tdhaesu ../hapack.a -L/usr/lib/x86_64-linux-gnu -llapack -lblas"

echo "== run: TDHAESU on the authors' dhaesu.dat (stdin), output compared with the shipped dhaesu.res"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Fortran77/Dp/Drivers && timeout 300 ./tdhaesu < dhaesu.dat > /work/build/dhaesu.out 2>&1; echo run_exit=\$?; cat /work/build/dhaesu.out" > "$E/run.out" 2>&1
cat "$E/run.out"

echo "== values"
python3 -I - "$E/run.out" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^\s*1\s+(-?[0-9.]+)\s+(-?[0-9.]+)\s*$", text, re.M)
if not m:
    print("no WR(1) row printed")
    sys.exit(0)
print(f"VALUE WR(1), DHAESU example first stable eigenvalue {m.group(1)}")
PY
