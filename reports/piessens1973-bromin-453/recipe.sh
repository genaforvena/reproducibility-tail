#!/usr/bin/env bash
# Rebuilds and reruns the record for piessens1973-bromin-453 (CACM Algorithm 453, BROMIN, Gaussian quadrature for
# Bromwich's integral; Fortran 77). Everything that runs the authors' code goes through tools/sandbox.sh.
# The host only hashes, splits and parses text.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 453.gz (sha256 checked against the queue entry),
# gunzipped to /work/pre/453.txt; gfortran (conda-forge, via micromamba) into /work/env if missing.
#
# Unpack: the archive is a plain shell archive (heredocs). Everything above its '#! /bin/sh' line is dropped and the
# rest is run with sh inside /work/tree, which creates Fortran/Sp/Drivers/{Makefile,driver.f,res} and
# Fortran/Sp/Src/src.f. Nothing is edited afterwards.
#
# Original run (G1, basis original): the authors' driver.f and src.f compiled exactly as shipped with gfortran -O0
# (the Makefile's F77 role) and run; stdout is compared byte-for-byte with the shipped res file. A second pass at -O2
# is a cross-check. No patch is applied, so no build-only manifests are needed.
#
# Claim: the first TEST01 block (N = 6, S = 0.00000) of the driver's output, 12 numbers (XR, XI, WR, WI for three
# abscissas), against the registered values in queue/piessens1973-bromin-453.json, absolute tolerance 1e-3.
set -uo pipefail
ID=piessens1973-bromin-453
URL=https://netlib.org/toms/453.gz
SHA=57563056450e03c510b778971d7539577da3f3e962cf5ce1650507466121b9f7
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
UNPACK='sed -n "/^#! \/bin\/sh/,\$p" /work/pre/453.txt > /work/tree/unpack.sh && cd /work/tree && sh /work/tree/unpack.sh && rm /work/tree/unpack.sh'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 453.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/453.gz '$URL'; echo '$SHA  /work/453.gz' | sha256sum -c -; gzip -dc /work/453.gz > /work/pre/453.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack: the authors' shell archive run inside /work/tree (manifest pre taken after unpack, before any change)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir /work/tree && $UNPACK && cd /work/tree && find . -type f | sort && sha256sum Fortran/Sp/Drivers/* Fortran/Sp/Src/*" > "$E/unpack.log" 2>&1 || { echo "UNPACK-FAILED"; cat "$E/unpack.log"; exit 1; }
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
mkdir -p "$E/reference" && cp "$SCRATCH/tree/Fortran/Sp/Drivers/res" "$E/reference/res"
wc -l < "$SCRATCH/manifest.pre"

echo "== original run (G1): driver.f and src.f as shipped, gfortran -O0, then -O2 (cross-check); stdout vs shipped res"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/orig && mkdir /work/orig && cd /work/orig && cp /work/tree/Fortran/Sp/Drivers/driver.f /work/tree/Fortran/Sp/Src/src.f . && \
  gfortran -O0 -c src.f && gfortran -O0 -c driver.f && gfortran -O0 -o driver_O0 driver.o src.o && ./driver_O0 > out_O0.txt; echo run_O0_exit=\$?; \
  gfortran -O2 -c src.f && gfortran -O2 -c driver.f && gfortran -O2 -o driver_O2 driver.o src.o && ./driver_O2 > out_O2.txt; echo run_O2_exit=\$?; \
  cmp out_O0.txt /work/tree/Fortran/Sp/Drivers/res && echo O0_identical_to_res; cmp out_O2.txt /work/tree/Fortran/Sp/Drivers/res && echo O2_identical_to_res" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"
cp "$SCRATCH/orig/out_O0.txt" "$E/run-O0.txt" 2>/dev/null
cp "$SCRATCH/orig/out_O2.txt" "$E/run-O2.txt" 2>/dev/null

echo "== values: the first TEST01 block (N = 6, S = 0) of each pass against the registered claim (host parse of text)"
python3 -I - "$E" "$root/queue/$ID.json" <<'PY' | tee "$E/values.txt"
import json, pathlib, re, sys
e = pathlib.Path(sys.argv[1])
claim = json.load(open(sys.argv[2]))["claim"]["values"]
def first_block(p):
    txt = p.read_text()
    m = re.search(r"N =\s+6\s+S =\s+0\.00000\s+XR\s+XI\s+WR\s+WI\s+(.*?)\n\s*\n\s+N =", txt, re.S)
    if not m:
        raise SystemExit(f"{p}: first N=6 S=0 block not found")
    rows = [r.split() for r in m.group(1).strip().splitlines() if r.strip()]
    if len(rows) != 3 or any(len(r) != 4 for r in rows):
        raise SystemExit(f"{p}: unexpected block shape {rows}")
    return [float(x) for r in rows for x in r]
worst = {}
for name in ("run-O0.txt", "run-O2.txt"):
    vals = first_block(e / name)
    diffs = [abs(v - c["paper"]) for v, c in zip(vals, claim)]
    ok = all(d <= c["tol_abs"] for d, c in zip(diffs, claim))
    print(f"{name}: all 12 values within tol_abs 1e-3 of the registered claim: {ok}; max |diff| {max(diffs):.3g}")
    worst[name] = vals
for name, vals in worst.items():
    for c, v in zip(claim, vals):
        print(f"VALUE {c['name']} {v!r}")
    break
PY
echo "== done; scratch kept at $SCRATCH (delete after the record is committed)"
