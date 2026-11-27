#!/usr/bin/env bash
# Rebuilds and reruns the JCONSX complex-method driver (TOMS Algorithm 454, Richardson & Kuester 1973, Fortran) from the
# netlib shell archive. All execution goes through tools/sandbox.sh; the host only hashes and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 454.gz (sha256 checked against the queue entry), gunzipped;
# gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Unpack (sandbox): the shell archive (cut from its '#! /bin/sh' line) is run with sh into /work/orig/tree.
#
# Original attempt (G1): the Makefile uses $(F77), which make defaults to f77; the sandbox has no f77. Kept in evidence/original-attempt.log.
#
# Patch (build-only): nothing in the source tree changes. The Makefile expects src.f in Drivers/, but the archive ships it in
# Src/; make VPATH=../Src finds it, and a small f77 shim in /work/bin (impl/f77-shim.sh, outside the tree) maps the name
# src.f to ../Src/src.f and runs gfortran -std=legacy. manifest.pre, mid and post prove that no source file is edited.
set -uo pipefail
ID=richardson1973-jconsx-454
URL=https://netlib.org/toms/454.gz
SHA=62edf4cce130c6e7ccce05b9da7908b3446ac74ce5ae74ca1fe9fe80087cf9f0
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/manifests"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 454.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/454.gz '$URL'; echo '$SHA  /work/454.gz' | sha256sum -c -; gzip -dc /work/454.gz > /work/pre/454.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack the authors' shell archive (sandbox)"
tools/sandbox.sh "$ID" -- sh -c "set -e; rm -rf /work/orig && mkdir -p /work/orig/tree && cd /work/orig/tree && \
  sed -n '/^#! \/bin\/sh/,\$p' /work/pre/454.txt > /work/orig/unpack.sh && sh /work/orig/unpack.sh; echo unpack_exit=\$?" > "$E/unpack.log" 2>&1
tail -2 "$E/unpack.log"

MAN="$E/manifests"
echo "== original attempt (G1): make Res as documented, f77 not present in the sandbox"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && env PATH=/usr/local/bin:/usr/bin:/bin make Res; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && rm -f *.o driver1 driver2 driver3 Res1 Res2 Res3"

python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.pre"

echo "== patch (build-only): VPATH to Src and the f77 shim outside the source tree"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/bin && cat > /work/bin/f77 && chmod +x /work/bin/f77 && /work/bin/f77 --version | head -1" < "$root/reports/$ID/impl/f77-shim.sh"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.mid"

echo "== build the authors' makefile target (sandbox; no editing in this step)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && env PATH=/work/bin:/work/env/bin:/usr/bin:/bin make VPATH=../Src driver1; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.post"

echo "== run driver1 (sandbox, no network), output to Res1 as the Makefile does"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && ./driver1 > Res1; echo run_exit=\$?; cat Res1" > "$E/run.txt" 2>&1
tail -12 "$E/run.txt"

echo "== values (host, text only)"
python3 -I - "$E/run.txt" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
it = list(re.finditer(r"ITERATION\s+(\d+)", t))
last = int(it[-1].group(1))
blk = t[it[[int(m.group(1)) for m in it].index(20)].end():]
pt = re.search(r"CORRECTED POINT\s+([-0-9.]+)\s+([-0-9.]+)", blk)
print(f"VALUE x1 at ITERATION 20 {float(pt.group(1))}")
print(f"VALUE x2 at ITERATION 20 {float(pt.group(2))}")
print(f"VALUE ITERATION count {last}")
PY
echo "== done; scratch kept at $SCRATCH"
