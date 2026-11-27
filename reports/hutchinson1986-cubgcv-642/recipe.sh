#!/usr/bin/env bash
# Rebuilds and reruns the record for hutchinson1986-cubgcv-642 (CACM/TOMS Algorithm 642, CUBGCV, cubic smoothing
# spline, Fortran). Everything that runs the authors' code goes through tools/sandbox.sh; the host only hashes,
# splits and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 642.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/642.txt (its sha256 is the claim's reference sha, 7d30...); gfortran (conda-forge, via micromamba) into
# /work/env if missing.
#
# Original run (G1): the source is lines 1..628 of the gunzipped file (CUBGCV, its subroutines, the TEST DRIVER and
# GGRAND, as shipped). Lines 630 onward are the printed output and are never compiled. Compiled unedited with
# gfortran -std=legacy -O0 (cross-check -O2), run, and the printed table rows I = 1, 21, 41 and the summary are parsed.
#
# Claim: VAR, GCV, MSR and Y, SE at I = 1, 21, 41 from the shipped printed output (queue entry), absolute tolerance 1e-4.
set -uo pipefail
ID=hutchinson1986-cubgcv-642
URL=https://netlib.org/toms/642.gz
SHA=fea2d2ad84a7883c2a45f04844cfb56b6112992cda5e485d6c47e01c0ae58f19
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 642.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/642.gz '$URL'; echo '$SHA  /work/642.gz' | sha256sum -c -; gzip -dc /work/642.gz > /work/pre/642.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original run (G1): lines 1..628 as shipped; gfortran -O0, then -O2 as a cross-check"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env/bin:\$PATH; rm -rf /work/orig && mkdir /work/orig && cd /work/orig && sed -n 1,628p /work/pre/642.txt > cubgcv.f && \
  gfortran -std=legacy -O0 -o t_O0 cubgcv.f && ./t_O0 > out_O0.txt; echo run_O0_exit=\$?; \
  gfortran -std=legacy -O2 -o t_O2 cubgcv.f && ./t_O2 > out_O2.txt; echo run_O2_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"
cp "$SCRATCH/orig/out_O0.txt" "$E/run-O0.txt" 2>/dev/null
cp "$SCRATCH/orig/out_O2.txt" "$E/run-O2.txt" 2>/dev/null

echo "== values: VAR, GCV, MSR and Y, SE at I = 1, 21, 41 (host parse of text)"
python3 -I - "$E" "$root/queue/$ID.json" <<'PY' | tee "$E/values.txt"
import json, pathlib, re, sys
e = pathlib.Path(sys.argv[1])
claim = json.load(open(sys.argv[2]))["claim"]["values"]
def values(p):
    txt = p.read_text()
    def num(label):
        m = re.search(label + r"\s*=\s*(-?[0-9.]+)", txt)
        if not m: raise SystemExit(f"{p}: {label} not found")
        return float(m.group(1))
    out = [num(r"VAR"), num(r"GENERALIZED CROSS VALIDATION"), num(r"MEAN SQUARE RESIDUAL")]
    rows = {}
    for line in txt.splitlines():
        f = line.split()
        if len(f) >= 5 and f[0].isdigit() and int(f[0]) in (1, 21, 41):
            try:
                rows[int(f[0])] = (float(f[3]), float(f[4]))   # I, X, F, Y, SE
            except ValueError:
                pass
    for i in (1, 21, 41):
        if i not in rows: raise SystemExit(f"{p}: row I={i} not found")
        out += [rows[i][0], rows[i][1]]
    return out
ok_all = True
for name in ("run-O0.txt", "run-O2.txt"):
    vals = values(e / name)
    diffs = [abs(v - c["paper"]) for v, c in zip(vals, claim)]
    ok = all(d <= c["tol_abs"] for d, c in zip(diffs, claim))
    ok_all = ok_all and ok
    print(f"{name}: all 9 values within tol_abs 1e-4 of the registered claim: {ok}; max |diff| {max(diffs):.3g}")
vals = values(e / "run-O0.txt")
for c, v in zip(claim, vals):
    print(f"VALUE {c['name']} {v!r}")
PY
echo "== done; scratch kept at $SCRATCH (delete after the record is committed)"
