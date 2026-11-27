#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 439 record (Boland 1972, product-type three-point Gauss-Legendre Simpson
# integration, Fortran). Everything that runs the archive's code goes through tools/sandbox.sh. The host only
# copies the build shim, hashes sources (tools/verify_sources.py) and copies text output.
#
# Fetch (network, inside the sandbox): netlib CALGO 439.gz, sha256 pinned in the queue entry, unpacked (a shell
# archive, run with /bin/sh) into /work/pre. The same step installs gfortran 16.2.0 (conda-forge, micromamba) into
# /work/env. If that gfortran driver cannot compile a file (it must write an object), the conda gcc driver is linked
# under the gfortran name; the choice is logged in fetch.log.
#
# G1 original attempt: the archive Makefile, unchanged, in a copy: `make` in Drivers with the default F77 (f77).
# Neither the sandbox nor the archive has f77, so it stops. The shim is not yet on the PATH at that step.
#
# Build-only route: the archive's Drivers Makefile compiles `src.f` from the Drivers directory, but the archive ships
# src.f in ../Src. `VPATH=../Src` lets make find the prerequisite, and the build shim impl/f77-shim.sh maps the
# compiler's single argument `src.f` to its path in ../Src. The shim is in /work/bin, outside the archive tree; no
# archive file is edited, so the manifests (pre, mid) match. SRCLIBS passes the gfortran runtime and libm to the
# archive's own link line, which has no library argument by default.
#
# Claim: TEST01 VINT at N = 10 = 2.65082 (the shipped Fortran/Dp/Drivers/res), tolerance abs 1e-5, registered and not
# edited.
set -uo pipefail
ID=boland1972-gauss-simpson-439
URL=https://netlib.org/toms/439.gz
SHA=81cfd10dead980d26565450b9f98bac46566f3d9da7b70552086feb4fd314407
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR/bin"
cd "$root"
exec > >(tee "$LOG") 2>&1

D=/work/pre/Fortran/Dp/Drivers
GF=/work/env/bin/x86_64-conda-linux-gnu-gfortran

echo "== fetch: 439.gz (sha256 checked), unpacked to /work/pre; gfortran 16.2.0 into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre /work/bin && cd /work/dl && curl -fsSL -o 439.gz '$URL'; \
  echo \"sha256 \$(sha256sum 439.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  439.gz' | sha256sum -c -; \
  gunzip -c 439.gz > 439.sh; cd /work/pre && /bin/sh /work/dl/439.sh; \
  test -x $GF || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran_linux-64=16.2.0; }; \
  printf '      program t\n      end\n' > /work/t.f; \
  if $GF -c /work/t.f -o /work/t.o 2>/dev/null && test -f /work/t.o; then echo gfortran_driver=ok; else echo gfortran_driver=broken-linked-to-gcc; ln -sf x86_64-conda-linux-gnu-gcc $GF; $GF -c /work/t.f -o /work/t.o && test -f /work/t.o; fi; \
  /work/bin/micromamba list -p /work/env 2>/dev/null | grep -i -E 'gfortran|gcc_linux' > /work/env-pins.txt || true; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -4 "$E/fetch.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/env-pins.txt" > "$E/env-pins.txt" 2>&1 || true
cat "$E/env-pins.txt"

echo "== manifest pre (right after unpack, before any patch or build)"
rm -f "$SCR/bin/f77"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the archive Makefile, unchanged, default F77 (no shim on the PATH yet)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/Fortran /work/orig-run/ && \
  cd /work/orig-run/Fortran/Dp/Drivers && make > /work/orig-make.log 2>&1; echo make_exit=\$?; cat /work/orig-make.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== build shim: copied to the scratch bin (maps the one argument src.f; edits no archive file)"
cp "$here/impl/f77-shim.sh" "$SCR/bin/f77" && chmod +x "$SCR/bin/f77"

echo "== manifest mid (immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the archive's Drivers Makefile, driver target"
tools/sandbox.sh "$ID" -- sh -c "cd $D && rm -f *.o driver && make F77=/work/bin/f77 VPATH=../Src SRCLIBS='-L/work/env/lib -lgfortran -lm' driver > /work/build-driver.log 2>&1; echo make_exit=\$?; cat /work/build-driver.log" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== run: the archive's driver (stdout to Res), and the shipped reference res"
tools/sandbox.sh "$ID" -- sh -c "cd $D && LD_LIBRARY_PATH=/work/env/lib ./driver > /work/Res 2>/work/run.err; echo driver_exit=\$?; cat /work/run.err; cp res /work/res.shipped; diff /work/Res res > /work/diff.txt; echo diff_exit=\$?; cat /work/diff.txt" \
  > "$E/driver-run.log" 2>&1
cat "$E/driver-run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/Res" > "$E/Res"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/Fortran/Dp/Drivers/res" > "$E/res.shipped"
sha256sum "$E/res.shipped" | cut -d' ' -f1 > "$E/res.shipped.sha256"

echo "== values: the TEST01 table row N = 10 (the claim)"
python3 -I - "$E/Res" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
block = text.split("TEST01", 1)[1].split("TEST02", 1)[0]
m = re.search(r"^\s*10\s+(\S+)\s*$", block, re.M)
print(f"VALUE TEST01_VINT_N10 {m.group(1)}" if m else "no N=10 row found in TEST01")
PY
