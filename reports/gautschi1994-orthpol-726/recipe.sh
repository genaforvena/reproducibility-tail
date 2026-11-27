#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 726 claim (Gautschi 1994, ORTHPOL, Fortran): DBETA(1) for om2 = 0.100 with
# modified moments, from the shipped test1 driver's own reference output. Everything that runs the archive's code
# goes through tools/sandbox.sh. The host only hashes sources (tools/verify_sources.py) and copies text output.
#
# Fetch (network, inside the sandbox): netlib CALGO 726.gz, sha256 pinned in the queue entry, gunzipped and unpacked
# with /bin/sh (a shell archive) into /work/pre. The same step installs gfortran 16.2.0 (conda-forge, micromamba)
# into /work/env and checks that it writes an object file.
#
# G1 original attempt: the archive Makefile, unchanged, in a copy: `make test1.out.local` with the default F77 (f77).
# Neither the sandbox nor the archive has f77, so it stops.
#
# Build-only route: the Makefile compiles with F77 and links with LD, both f77 by default. Passing F77 and LD on the
# make command line selects the sandbox's gfortran. No archive file is edited, so manifests pre and mid match.
#
# Run: ./test1 writes its output to stdout. The VALUE line is the first DBETA(K) row with K = 1 in the first block
# (om2 = 0.100, modmom = .true.), with the Fortran D exponent turned into E so Python reads it as double precision.
# Claim: DBETA(1) = 0.5065840806382684475158495727 (shipped test1.out), tolerance abs 1e-12, registered and not edited.
set -uo pipefail
ID=gautschi1994-orthpol-726
URL=https://netlib.org/toms/726.gz
SHA=b229159f0bd9b38948f32ccb5f2d958c80f0a95c1706f88c03284aef5b0fa186
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

D=/work/pre
GF=/work/env/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 726.gz (sha256 checked), unpacked to /work/pre; gfortran 16.2.0 into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre /work/bin && cd /work/dl && curl -fsSL -o 726.gz '$URL'; \
  echo \"sha256 \$(sha256sum 726.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  726.gz' | sha256sum -c -; \
  gunzip -c 726.gz > 726.sh; cd /work/pre && /bin/sh /work/dl/726.sh; \
  test -x $GF || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran_linux-64=16.2.0; }; \
  printf '      program t\n      end\n' > /work/t.f; \
  rm -f /work/t.o; $GF -c /work/t.f -o /work/t.o && test -s /work/t.o && echo gfortran_object=ok; \
  /work/bin/micromamba list -p /work/env 2>/dev/null | grep -i -E 'gfortran|gcc_linux' > /work/env-pins.txt || true; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -4 "$E/fetch.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/env-pins.txt" > "$E/env-pins.txt" 2>&1 || true
cat "$E/env-pins.txt"

echo "== manifest pre (right after unpack, before any patch or build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the archive Makefile, unchanged, default F77 (f77)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/. /work/orig-run/ && \
  cd /work/orig-run && make test1.out.local > /work/orig-make.log 2>&1; echo make_exit=\$?; cat /work/orig-make.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (immediately before the build; no patch step: the Makefile is used as shipped)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the archive's own object list (TEST1 in its Makefile), compiled by make with the sandbox gfortran as F77 and FC, then linked by hand"
# The shipped Makefile's link rules are empty: the archive is a shell archive whose heredoc expands $(LD) and $(TEST1) to nothing
# when /bin/sh unpacks it (the Makefile line reads `test1  :   ;  -o $@`). So the link line is run from the TEST1 list itself.
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre && rm -f *.o test1 && make F77=/work/env/bin/x86_64-conda-linux-gnu-gfortran FC=/work/env/bin/x86_64-conda-linux-gnu-gfortran FFLAGS=-fallow-invalid-boz test1.o r1mach.o d1mach.o recur.o drecur.o cheb.o dcheb.o > /work/build-objects.log 2>&1; echo make_exit=\$?; /work/env/bin/x86_64-conda-linux-gnu-gfortran -fallow-invalid-boz -o test1 test1.o r1mach.o d1mach.o recur.o drecur.o cheb.o dcheb.o >> /work/build-objects.log 2>&1; echo link_exit=\$?; cat /work/build-objects.log; ls -l test1" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== run: the archive's test1 driver (stdout to Res), compared with the shipped test1.out"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre && ./test1 > /work/Res 2>/work/run.err; echo test1_exit=\$?; cat /work/run.err; cp test1.out /work/test1.out.shipped; diff /work/Res test1.out > /work/diff.txt; echo diff_exit=\$?; head -c 4000 /work/diff.txt" \
  > "$E/driver-run.log" 2>&1
cat "$E/driver-run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/Res" > "$E/Res"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/test1.out" > "$E/test1.out.shipped"
sha256sum "$E/test1.out.shipped" | cut -d' ' -f1 > "$E/test1.out.shipped.sha256"

echo "== values: DBETA(1) in the first block (om2 = 0.100, modmom = .true.), the claim"
python3 -I - "$E/Res" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# the driver prints the om2 = 0.100 block first (its K = 0 line carries OM2 = 0.100), so the first K = 1 row is the claimed one
m = re.search(r"^\s+1\s+(-?[0-9.]+)D([+-][0-9]+)", text, re.M)
if m:
    print(f"VALUE DBETA1_OM2_0p1 {m.group(1)}E{m.group(2)}")
else:
    print("no K=1 row found in the first block")
PY
