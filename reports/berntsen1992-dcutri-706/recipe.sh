#!/usr/bin/env bash
# Rebuilds and reruns the DCUTRI sample (TOMS Algorithm 706, Berntsen & Espelid 1992, Fortran 77) from the
# netlib archive. All execution goes through tools/sandbox.sh; the host only hashes, extracts text and parses output.
#
# Fetch (network, inside the sandbox): netlib TOMS 706.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/706.txt; gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Original attempt (G1): the listing as shipped, compiled as one unit with gfortran -std=legacy. It is not a
# compilable unit (a makefile fragment and several PROGRAM units in one file), so this attempt fails and is kept.
#
# Patch (basis patched): impl/extract.py copies the subprograms the DTEST1 sample needs (D1MACH, DCUTRI, DCHTRI,
# DADTRI, DRLTRI, DTRTRI, DTEST1, F) verbatim from the listing into /work/build/dtest.f. Nothing is edited inside them.
#
# Run: the live DTEST1 prints RESULT, ERROR, NEVAL and IFAIL. Claim: RESULT (tol 1e-9), NEVAL and IFAIL exact.
set -uo pipefail
ID=berntsen1992-dcutri-706
URL=https://netlib.org/toms/706.gz
SHA=c67596047b71b0642323a2593ceea4949d5782cc4df6518efcdfb05ed8fc97bc
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 706.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/706.gz '$URL'; echo '$SHA  /work/706.gz' | sha256sum -c -; gzip -dc /work/706.gz > /work/pre/706.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the listing as shipped, one unit, -std=legacy"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env/bin:\$PATH; rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && \
  cp /work/pre/706.txt dtest.f && gfortran -std=legacy -c dtest.f; echo compile_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"

echo "== patch: extract the needed subprograms verbatim (host, text only)"
mkdir -p "$SCRATCH/build"
python3 -I "$here/impl/extract.py" "$SCRATCH/pre/706.txt" "$SCRATCH/build/dtest.f" | tee "$E/extract.txt"
sha256sum "$SCRATCH/build/dtest.f" | tee "$E/extract-sha256.txt"

echo "== build the extracted sample (sandbox)"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env/bin:\$PATH; cd /work/build && \
  gfortran -std=legacy -o dtest1 dtest.f; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"

echo "== run DTEST1 (sandbox, no network)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./dtest1; echo run_exit=\$?" > "$E/run.txt" 2>&1
cat "$E/run.txt"

echo "== values (host, text only)"
python3 -I - "$E/run.txt" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
def grab(label, cast):
    m = re.search(label + r"\s*=\s*(-?[0-9.E+\-D]+)", t)
    return cast(m.group(1).replace("D", "E")) if m else None
res = grab(r"RESULT", float)
neval = grab(r"NEVAL", int)
ifail = grab(r"IFAIL", int)
print(f"VALUE RESULT {res!r}")
print(f"VALUE NEVAL {neval!r}")
print(f"VALUE IFAIL {ifail!r}")
PY
echo "== done; scratch kept at $SCRATCH"
