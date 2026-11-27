#!/usr/bin/env bash
# Rebuilds and reruns the ROMINT driver (TOMS Algorithm 351, Fairweather 1969, Fortran) from the netlib shell archive.
# All execution goes through tools/sandbox.sh; the host only hashes and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 351.gz (sha256 checked against the queue entry), gunzipped;
# gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Unpack (sandbox): the shell archive (cut from its '#! /bin/sh' line) is run with sh into /work/orig/tree.
#
# Original attempt (G1): the Makefile uses $(F77), which make defaults to f77; the sandbox has no f77. Run as documented,
# it fails. That attempt is kept in evidence/original-attempt.log.
#
# Patch (build-only): nothing in the source tree changes. The Makefile expects src.f in Drivers/, but the archive ships it
# in Src/; make VPATH=../Src finds it, and a small f77 shim in /work/bin (outside the tree) maps the name src.f to
# ../Src/src.f and runs gfortran -std=legacy. manifest.pre, mid and post prove that no source file is edited.
set -uo pipefail
ID=fairweather1969-romint-351
URL=https://netlib.org/toms/351.gz
SHA=afeb019f1e28e0a2315b7c6a73bce6b302766961b55a3d4a58179465a7e01998
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/manifests"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 351.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/351.gz '$URL'; echo '$SHA  /work/351.gz' | sha256sum -c -; gzip -dc /work/351.gz > /work/pre/351.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack the authors' shell archive (sandbox)"
tools/sandbox.sh "$ID" -- sh -c "set -e; rm -rf /work/orig && mkdir -p /work/orig/tree && cd /work/orig/tree && \
  sed -n '/^#! \/bin\/sh/,\$p' /work/pre/351.txt > /work/orig/unpack.sh && sh /work/orig/unpack.sh; echo unpack_exit=\$?" > "$E/unpack.log" 2>&1
tail -2 "$E/unpack.log"

MAN="$E/manifests"
echo "== original attempt (G1): make Res as documented, f77 not present in the sandbox"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && env PATH=/usr/local/bin:/usr/bin:/bin make Res; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && rm -f *.o driver Res"

python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.pre"

echo "== patch (build-only): f77 shim outside the source tree, gfortran -std=legacy"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/bin && cat > /work/bin/f77 && chmod +x /work/bin/f77 && /work/bin/f77 --version | head -1" < "$root/reports/$ID/impl/f77-shim.sh"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.mid"

echo "== build the authors' makefile target (sandbox; no editing in this step)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && env PATH=/work/bin:/work/env/bin:/usr/bin:/bin make VPATH=../Src driver; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.post"

echo "== run the driver (sandbox, no network), output to Res as the Makefile does"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/Fortran/Sp/Drivers && ./driver > Res; echo run_exit=\$?; cat Res" > "$E/run.txt" 2>&1
cat "$E/run.txt"

echo "== values (host, text only)"
python3 -I - "$E/run.txt" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
block = t.split("TEST02", 1)[1]
rows = re.findall(r"^\s*0\.0000\s+4\.3000\s+(\d+)\s+(\d+)\s+(\d+)\s+([0-9.E+-]+)\s+([0-9.]+)\s*$", block, re.M)
maxe_in5 = [r for r in rows if r[0] == "5"]
assert maxe_in5, "no TEST02 row with MAXE in = 5"
_, _, n, _, val = maxe_in5[0]
print(f"VALUE VAL {float(val)}")
print(f"VALUE N {int(n)}")
PY
echo "== done; scratch kept at $SCRATCH"
