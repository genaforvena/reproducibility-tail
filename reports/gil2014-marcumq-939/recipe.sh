#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 939 claim (Gil, Segura, Temme 2014, Marcum-Q, Fortran 90): the Marcum-Q value
# Q_8(13, 15) = 0.8516869957363 (the reference DATA q(5) of the shipped testmarq.f90), absolute tolerance 1e-10,
# registered and not edited. Everything that runs the archive's code goes through tools/sandbox.sh.
# The host only hashes sources (tools/verify_sources.py) and copies text output.
#
# Fetch (network, inside the sandbox): netlib CALGO 939.zip, sha256 pinned in the queue entry, unzipped to /work/pre.
# The same step installs gfortran 16.2.0 (conda-forge, micromamba) into /work/env and checks that it writes an object.
#
# G1 original attempt: the archive Makefile (Doc/Makefile), unchanged, in a copy: `make` with its default FC = g95.
# Neither the sandbox nor the archive has g95, so the first compile fails.
#
# Build-only route: the Makefile compiles with $(FC) and links with $(FC). Passing FC and VPATH on the make command line
# selects the sandbox's gfortran and finds the sources in Fortran90/Src and Fortran90/Drivers. No archive file is edited
# and the build writes its objects into /work/build (outside the archive tree).
#
# Value: the shipped driver prints only relative errors. impl/valq8.f90 calls the authors' marcum(8, 13, 15) and prints
# `VALUE Q_mu8_x13_y15 <number>`. It is compiled and linked against the authors' modules.
set -uo pipefail
ID=gil2014-marcumq-939
URL=https://netlib.org/toms/939.zip
SHA=dbf77461a9c02c603f8eb2bfcfcef6e3d1cfbb7d628b54b18f79c4a7e62af9e4
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

GF=/work/env/bin/x86_64-conda-linux-gnu-gfortran
DOC=/work/pre/939/Doc
SRC=/work/pre/939/Fortran90/Src
DRV=/work/pre/939/Fortran90/Drivers

echo "== fetch: 939.zip (sha256 checked), unzipped to /work/pre; gfortran 16.2.0 into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre /work/bin && cd /work/dl && curl -fsSL -o 939.zip '$URL'; \
  echo \"sha256 \$(sha256sum 939.zip | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  939.zip' | sha256sum -c -; \
  python3 -m zipfile -e 939.zip /work/pre; \
  test -x /work/env/bin/x86_64-conda-linux-gnu-gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran_linux-64=16.2.0; }; \
  printf '      program t\n      end\n' > /work/t.f; \
  rm -f /work/t.o; /work/env/bin/x86_64-conda-linux-gnu-gfortran -c /work/t.f -o /work/t.o && test -s /work/t.o && echo gfortran_object=ok; \
  /work/bin/micromamba list -p /work/env 2>/dev/null | grep -i -E 'gfortran|gcc_linux' > /work/env-pins.txt || true; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -4 "$E/fetch.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/env-pins.txt" > "$E/env-pins.txt" 2>&1 || true
cat "$E/env-pins.txt"

echo "== manifest pre (right after unpack, before any patch or build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the archive Makefile, unchanged (copy of Doc), default FC = g95"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -a $DOC/. /work/orig/ && cd /work/orig && make > /work/orig-make.log 2>&1; echo make_exit=\$?; cat /work/orig-make.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== impl driver copied into the scratch dir (the sandbox sees only /work)"
cp "$here/impl/valq8.f90" "$SCR/valq8.f90"

echo "== manifest mid (immediately before the build; the Makefile is used as shipped)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the archive's Makefile with FC = sandbox gfortran, sources found through VPATH, objects in /work/build;"
echo "   then the value driver is compiled and linked against the authors' modules."
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && mkdir /work/build && cd /work/build && { make -f /work/pre/939/Doc/Makefile FC=/work/env/bin/x86_64-conda-linux-gnu-gfortran VPATH=/work/pre/939/Fortran90/Src:/work/pre/939/Fortran90/Drivers FFLAGS=-O && /work/env/bin/x86_64-conda-linux-gnu-gfortran -O -c /work/valq8.f90 -o valq8.o && /work/env/bin/x86_64-conda-linux-gnu-gfortran -o valq8 valq8.o cons.o incgam.o marcumq.o; } > /work/build.log 2>&1; echo build_exit=\$?; cat /work/build.log; ls -l testmarq valq8" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== record the patch as build-only (exit 0 = no source changed before the build; the G2 paper check is not needed)"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$SCR/manifest.pre" --mid "$SCR/manifest.mid" --post "$SCR/manifest.post" \
  --command "make -f /work/pre/939/Doc/Makefile FC=/work/env/bin/x86_64-conda-linux-gnu-gfortran VPATH=/work/pre/939/Fortran90/Src:/work/pre/939/Fortran90/Drivers FFLAGS=-O" --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -O -c /work/valq8.f90 -o valq8.o" --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -o valq8 valq8.o cons.o incgam.o marcumq.o"
echo "record_exit=$?"

echo "== run: the value driver (claimed point) and the archive's own test (relative errors, compared with the shipped outputQP.dat)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./valq8 > /work/valq8.out 2>/work/valq8.err; echo valq8_exit=\$?; cat /work/valq8.err; cat /work/valq8.out; ./testmarq > /work/testmarq.out 2>&1; echo testmarq_exit=\$?; cat /work/testmarq.out | head -40; cp testQP.dat /work/testQP.dat" \
  > "$E/run.log" 2>&1
cat "$E/run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/valq8.out" > "$E/valq8.out"
tools/sandbox.sh "$ID" -- sh -c "cat /work/testQP.dat" > "$E/testQP.dat"
tools/sandbox.sh "$ID" -- sh -c "cat $DRV/outputQP.dat" > "$E/outputQP.shipped"
sha256sum "$E/outputQP.shipped" | cut -d' ' -f1 > "$E/outputQP.shipped.sha256"

echo "== values"
python3 -I - "$E/valq8.out" <<'PY'
import sys
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    if line.startswith("VALUE "):
        print(line.rstrip())
PY
