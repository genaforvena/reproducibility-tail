#!/usr/bin/env bash
# Rebuilds the rerun record for goano1995-fermi-745 (TOMS 745, Goano, Fermi-Dirac integral, Fortran 77).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes and parses text.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 745.gz (sha256 checked against the queue entry),
# gunzipped to /work/pre/745.txt; gfortran (conda-forge, via micromamba) into /work/env if missing.
#
# Split: the archive's members are separated by 'C*** NAME' lines (FERTST.IN, FERTST.OUT, src.f). Each member's
# lines are copied byte-for-byte into /work/tree; nothing is edited.
#
# Original attempt (G1): src.f compiled exactly as shipped (gfortran -O0; the archive's own main program FERTST is in
# src.f) and run on the shipped FERTST.IN. It runs, but FERMID(0.5, 5.0) does not match the reference. Log:
# evidence/original-attempt.log. The claimed value is therefore NOT reproduced as shipped under this toolchain.
#
# Build (basis patched, build-only): src.f is not edited. The authors' FERTST driver is compiled with the flag
# -finit-local-zero, which zero-initializes local variables the source leaves uninitialized (see the diagnosis in
# evidence/diagnostic-uninit.txt). Two optimisation levels (-O0, -O2) are built from the same unedited src.f, to show
# the result does not depend on the optimisation level. The manifests pre, mid and post bracket the two build commands.
#
# Claim: FERMID(0.5, 5.0) printed by the authors' FERTST run (row 17 of the FERMID block of FERTST.IN) against the
# shipped reference 8.8442088952430, relative tolerance 1e-10 (fixed in the queue entry).
set -uo pipefail
ID=goano1995-fermi-745
URL=https://netlib.org/toms/745.gz
SHA=575d82e32dfdbe780834f0d7cfb49bfd82f8394fd25c50c9c40cc7daccf89ae0
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
SPLIT="awk '/^C\\*\\*\\* [A-Za-z_.]+\$/ { f = \$2; next } f { print > f }'"
BUILD1='gfortran -O0 -finit-local-zero src.f -o fertst_O0'
BUILD2='gfortran -O2 -finit-local-zero src.f -o fertst_O2'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 745.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/745.gz '$URL'; echo '$SHA  /work/745.gz' | sha256sum -c -; gzip -dc /work/745.gz > /work/pre/745.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack: the three members split from the archive, unedited, into /work/tree (manifest pre)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree && mkdir /work/tree && cd /work/tree && $SPLIT < /work/pre/745.txt && ls -l && sha256sum FERTST.IN FERTST.OUT src.f" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
mkdir -p "$E/reference" && cp "$SCRATCH/tree/FERTST.IN" "$E/reference/FERTST.IN"
wc -l < "$SCRATCH/manifest.pre"

echo "== original attempt (G1): src.f as shipped, gfortran -O0 and -O2, run on FERTST.IN (no build edits)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp /work/tree/FERTST.IN /work/tree/src.f /work/orig/ && cd /work/orig && $PATHSET && gfortran -O0 src.f -o fertst_O0 && ./fertst_O0 >/dev/null 2>&1; echo run_O0_exit=\$?; cp FERTST.OUT out_O0.txt; gfortran -O2 src.f -o fertst_O2 && ./fertst_O2 >/dev/null 2>&1; echo run_O2_exit=\$?; cp FERTST.OUT out_O2.txt; cat out_O0.txt out_O2.txt" > "$E/original-attempt.log" 2>&1
grep -E 'run_.*_exit=' "$E/original-attempt.log"

echo "== build: copy of the tree (no edit), manifest mid immediately before the build commands"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && gfortran -O0 -finit-local-zero src.f -o fertst_O0 && echo build1_ok; gfortran -O2 -finit-local-zero src.f -o fertst_O2 && echo build2_ok" > "$E/build.log" 2>&1
cat "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== runs: each binary on the shipped FERTST.IN (pass 1 = -O0, pass 2 = -O2)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./fertst_O0 >/dev/null 2>&1; echo run1_exit=\$?; cp FERTST.OUT pass1-out.txt; ./fertst_O2 >/dev/null 2>&1; echo run2_exit=\$?; cp FERTST.OUT pass2-out.txt; cat pass1-out.txt > /work/pass1-out.txt; cat pass2-out.txt > /work/pass2-out.txt" > "$E/runs.log" 2>&1
cat "$E/runs.log"
cp "$SCRATCH/pass1-out.txt" "$E/pass1-run.txt"; cp "$SCRATCH/pass2-out.txt" "$E/pass2-run.txt"

echo "== values: the 17th FERMID row of FERTST.IN, and how many FERMID rows match their reference (host parse of text)"
python3 -I - "$E" <<'PY' | tee "$E/values.txt"
import re, sys, pathlib
e = pathlib.Path(sys.argv[1])
for p in (1, 2):
    txt = (e / f"pass{p}-run.txt").read_text()
    blocks = txt.split("Test on FERINC")[0]
    rows = re.findall(r"ORD =\s*(\S+)\s+X =\s*(\S+)\s+RELERR.*?Reference value =\s*(\S+)\s+Computed result =\s*(\S+)", blocks, re.S)
    hit = [r for r in rows if float(r[0]) == 0.5 and float(r[1]) == 5.0]
    if len(hit) != 1:
        raise SystemExit(f"pass {p}: expected one ORD=0.5 X=5.0 row, found {len(hit)}")
    ok = sum(1 for r in rows if abs(float(r[3].replace('D','E')) - float(r[2].replace('D','E'))) <= 1e-10 * abs(float(r[2].replace('D','E'))))
    print(f"pass {p}: FERMID rows {len(rows)}, matching reference to 1e-10 rel: {ok}; ORD=0.5 X=5.0 computed={hit[0][3]} reference={hit[0][2]}")
v1 = float(re.findall(r"Computed result =\s*(\S+)", (e / 'pass1-run.txt').read_text().split('Test on FERINC')[0])[16].replace('D','E'))
v2 = float(re.findall(r"Computed result =\s*(\S+)", (e / 'pass2-run.txt').read_text().split('Test on FERINC')[0])[16].replace('D','E'))
print(f"VALUE FERMID(0.5, 5.0) {v1!r}")
print(f"VALUE FERMID(0.5, 5.0) {v2!r}")
PY

echo "== manifests into the report and build-only record (exit 0 means build-only)"
cp "$SCRATCH/manifest.pre" "$SCRATCH/manifest.mid" "$SCRATCH/manifest.post" "$E/" 2>/dev/null
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command "$BUILD1" --command "$BUILD2" > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi
