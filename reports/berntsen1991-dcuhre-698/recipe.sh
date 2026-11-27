#!/usr/bin/env bash
# Rebuilds and reruns the DCUHRE sample driver (TOMS Algorithm 698, Berntsen, Espelid & Genz 1991, Fortran 77) from
# the netlib shell archive. All execution goes through tools/sandbox.sh; the host only hashes and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 698.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/698.txt; gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Unpack (sandbox): the shell archive (cut from its '#!/bin/sh' line) is run with sh into /work/orig/tree.
#
# Original attempt (G1): the authors' makefile calls f77, which this sandbox does not have. Run as documented, it fails.
# That attempt is kept in evidence/original-attempt.log.
#
# Patch (build-only): the only change is outside the source tree. A one-line f77 shim in /work/bin runs gfortran
# -std=legacy. No source file is edited; manifest.pre, mid and post prove it.
set -uo pipefail
ID=berntsen1991-dcuhre-698
URL=https://netlib.org/toms/698.gz
SHA=27d891c14cabaefddd7c9cd6d3a6a2ae5b60eafa70901c32914f019363fda501
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/manifests"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 698.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/698.gz '$URL'; echo '$SHA  /work/698.gz' | sha256sum -c -; gzip -dc /work/698.gz > /work/pre/698.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack the authors' shell archive (sandbox)"
tools/sandbox.sh "$ID" -- sh -c "set -e; rm -rf /work/orig && mkdir -p /work/orig/tree && cd /work/orig/tree && \
  sed -n '/^#!\/bin\/sh/,\$p' /work/pre/698.txt > /work/orig/unpack.sh && sh /work/orig/unpack.sh; echo unpack_exit=\$?" > "$E/unpack.log" 2>&1
tail -2 "$E/unpack.log"

echo "== original attempt (G1): make dtest1 as documented, f77 not present in the sandbox"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree && env PATH=/usr/local/bin:/usr/bin:/bin make dtest1; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"

MAN="$E/manifests"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.pre"

echo "== patch (build-only): f77 shim outside the source tree, gfortran -std=legacy"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/bin && printf '#!/bin/sh\nexec /work/env/bin/gfortran -std=legacy \"\$@\"\n' > /work/bin/f77 && chmod +x /work/bin/f77 && /work/bin/f77 --version | head -1"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.mid"

echo "== build the authors' makefile target (sandbox; no editing in this step)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree && env PATH=/work/bin:/work/env/bin:/usr/bin:/bin make dtest1; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.post"

echo "== run DTEST1 (sandbox, no network)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree && ./dtest1; echo run_exit=\$?" > "$E/run.txt" 2>&1
cat "$E/run.txt"

echo "== values (host, text only)"
python3 -I - "$E/run.txt" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
m = re.search(r"FTEST CALLS\s*=\s*(\d+),\s*IFAIL\s*=\s*(\d+)", t)
print(f"VALUE FTEST CALLS {int(m.group(1))}")
print(f"VALUE IFAIL {int(m.group(2))}")
rows = re.findall(r"^\s*(\d+)\s+([0-9.]+)\s+([0-9.]+)\s*$", t, re.M)
for n, err, val in rows:
    print(f"VALUE integral {n} {val}")
PY
echo "== done; scratch kept at $SCRATCH"
