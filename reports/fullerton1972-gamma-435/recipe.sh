#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 435 claim (Fullerton 1972, modified incomplete gamma, Fortran): the computed value
# 0.92250806 in row A = 11.0, X = 16.0 of the shipped driver's own reference table (Fortran/Sp/Drivers/res), absolute
# tolerance 1e-6, registered and not edited. Everything that runs the archive's code goes through tools/sandbox.sh.
# The host only hashes sources (tools/verify_sources.py) and copies text output.
#
# Fetch (network, inside the sandbox): netlib CALGO 435.gz, sha256 pinned in the queue entry, gunzipped and unpacked
# with /bin/sh (a shell archive) into /work/pre. The same step installs gfortran 16.2.0 (conda-forge, micromamba)
# into /work/env and checks that it writes an object file.
#
# G1 original attempt: the archive Makefile, unchanged, in a copy: `make Res` with the default F77 (f77).
# Neither the sandbox nor the archive has f77, so it stops at the first compile.
#
# Build-only route: the Makefile compiles with $(F77) and links with $(F77), both f77 by default. Passing F77 on the
# make command line selects the sandbox's gfortran. No archive file is edited, so manifests pre and mid match.
#
# Run: the driver writes its table to stdout (the Makefile's own Res rule: ./driver > Res). The VALUE line is the
# Computed column of the row A = 11.0000, X = 16.0000.
set -uo pipefail
ID=fullerton1972-gamma-435
URL=https://netlib.org/toms/435.gz
SHA=07b19a251af345c24a92e380bf7831375dd6e65340353350e25f8836d1894a8d
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

GF=/work/env/bin/x86_64-conda-linux-gnu-gfortran
D=/work/pre/Fortran/Sp/Drivers

echo "== fetch: 435.gz (sha256 checked), unpacked to /work/pre; gfortran 16.2.0 into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre /work/bin && cd /work/dl && curl -fsSL -o 435.gz '$URL'; \
  echo \"sha256 \$(sha256sum 435.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  435.gz' | sha256sum -c -; \
  gunzip -c 435.gz > 435.sh; cd /work/pre && /bin/sh /work/dl/435.sh; \
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
  cd /work/orig-run/Fortran/Sp/Drivers && make Res > /work/orig-make.log 2>&1; echo make_exit=\$?; cat /work/orig-make.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (immediately before the build; no patch step: the Makefile is used as shipped)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the archive's Makefile object list (driver.o src.o, link to driver), with the sandbox gfortran. The Makefile"
echo "   expects src.f beside it (src.o: src.f) but the archive ships it in Fortran/Sp/Src/, so src.f is compiled from"
echo "   ../Src/ with the same compiler and no flags added. No file is copied or edited, so the manifests pre and mid match."
tools/sandbox.sh "$ID" -- sh -c "cd $D && rm -f *.o driver Res && { /work/env/bin/x86_64-conda-linux-gnu-gfortran -c ../Src/src.f -o src.o && /work/env/bin/x86_64-conda-linux-gnu-gfortran -c driver.f -o driver.o && /work/env/bin/x86_64-conda-linux-gnu-gfortran -o driver driver.o src.o; } > /work/build.log 2>&1; echo build_exit=\$?; cat /work/build.log; ls -l driver" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== record the patch as build-only (exit 0 = nothing changed before the build; the G2 paper check is not needed)"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$SCR/manifest.pre" --mid "$SCR/manifest.mid" --post "$SCR/manifest.post" \
  --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -c ../Src/src.f -o src.o" --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -c driver.f -o driver.o" --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -o driver driver.o src.o"
echo "record_exit=$?"

echo "== run: the archive's driver, stdout to Res (the Makefile's Res rule), compared with the shipped res"
tools/sandbox.sh "$ID" -- sh -c "cd $D && ./driver > /work/Res 2>/work/run.err; echo driver_exit=\$?; cat /work/run.err; cp res /work/res.shipped; diff /work/Res res > /work/diff.txt; echo diff_exit=\$?; head -c 4000 /work/diff.txt" \
  > "$E/driver-run.log" 2>&1
cat "$E/driver-run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/Res" > "$E/Res"
tools/sandbox.sh "$ID" -- sh -c "cat $D/res" > "$E/res.shipped"
sha256sum "$E/res.shipped" | cut -d' ' -f1 > "$E/res.shipped.sha256"

echo "== values: the Computed column at A = 11.0000, X = 16.0000 (the claim)"
python3 -I - "$E/Res" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^\s+11\.0000\s+16\.0000\s+(\S+)\s+(\S+)", text, re.M)
if m:
    print(f"VALUE computed_A11_X16 {m.group(2)}")
else:
    print("row A = 11.0000, X = 16.0000 not found")
PY
