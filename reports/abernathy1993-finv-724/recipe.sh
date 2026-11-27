#!/usr/bin/env bash
# Rebuilds the rerun record for abernathy1993-finv-724 (ACM TOMS 724, Collected Algorithms from ACM: FINV,
# F-distribution percentage points, Fortran, Abernathy and Smith 1993). Everything that runs the authors' code goes
# through tools/sandbox.sh. The host only hashes sources (tools/verify_sources.py), parses text output and writes the report.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 724.gz, sha256 checked against the queue entry's
# code.archive, gunzipped to /work/tree/724.txt (one plain Fortran file, 917 lines; no shell wrapper). gfortran
# (conda-forge, micromamba) into /work/fortran if the sandbox has none.
#
# G1 original attempt: the archive compiled as shipped (gfortran defaults), no edit. It fails: lines 646-917 are the
# authors' printed test output, pasted WITHOUT comment markers, so the compiler stops at line 653. The log is kept.
#
# Patch (basis patched, kind extraction): the code is lines 1-645 of the archive (the program TEST and the FINV
# package, ending with END at line 643; lines 644-645 are comment rules). The patch step copies that one verbatim
# range into 724.f with sed and changes nothing else. record checks the range byte for byte against the archive.
#
# Claim: FINV(10, 10, 0.9) from the P = 0.90 table of the driver's TESTDATA output, row N = 10, column M = 10. The
# shipped printed value in the archive's comments is 0.23226039E+001. Tolerance 2e-7 absolute (queue entry).
set -uo pipefail
ID=abernathy1993-finv-724
URL=https://netlib.org/toms/724.gz
SHA=c63388b4b9ec6b2d662e9ea6d772fcf2707e028c9e99a7455db37dccd9111ac2
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 724.gz (sha256 checked), gunzipped to /work/tree/724.txt; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/tree && mkdir -p /work/tree && curl -fsSL -o /work/724.gz '$URL'; \
  echo \"sha256 \$(sha256sum /work/724.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  /work/724.gz' | sha256sum -c -; \
  gunzip -c /work/724.gz > /work/tree/724.txt; wc -l /work/tree/724.txt; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  mkdir -p /work/bin && ln -sf $G /work/bin/gfortran && gfortran --version | head -1" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== G1 original attempt: the archive as shipped, compiled with gfortran defaults, in a copy"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp /work/tree/724.txt /work/orig/724.f && cd /work/orig && gfortran -o asis 724.f; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|Error' "$E/original-attempt.log" | head -3

echo "== manifest pre: the unpacked archive (the .txt is not source), before the patch step"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== patch step (extraction): archive lines 1-645 copied to 724.f; nothing else changed"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && mkdir /work/build && cp /work/tree/724.txt /work/build/ && sed -n '1,645p' /work/tree/724.txt > /work/build/724.f && echo patched && wc -l /work/build/724.f" > "$E/patch.log" 2>&1
cat "$E/patch.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"

echo "== build: the authors' file, gfortran defaults"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && gfortran -o test724 724.f; echo build_exit=\$?" > "$E/build.log" 2>&1
grep -E 'build_exit=|Error' "$E/build.log" | head -3

echo "== manifest post: after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== run: the driver writes TESTDATA in its working directory"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./test724 > run.out 2>&1; echo run_exit=\$?; cat run.out" > "$E/run.log" 2>&1
grep -E '^run_exit=' "$E/run.log"
cp "$SCRATCH/build/TESTDATA" "$E/TESTDATA" 2>/dev/null || echo "no TESTDATA produced"
sed -n '646,690p' "$SCRATCH/tree/724.txt" > "$E/shipped-block.txt" 2>/dev/null || true
cp "$SCRATCH/tree/724.txt" "$E/archive-724.txt"
sha256sum "$E/archive-724.txt" > "$E/archive-724.sha256"

echo "== values (VALUE lines are read by the G5 replay)"
python3 -I - "$E/TESTDATA" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
if " P =  0.90000" not in text:
    print("no P = 0.90 block")
    sys.exit(0)
block = text.split(" P =  0.90000", 1)[1].split(" P =  0.99000", 1)[0]
m = re.search(r"^\s+10\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$", block, re.M)   # first N = 10 row: M = 1, 2, 3, 10
if not m:
    print("no N = 10 row in the P = 0.90 block")
    sys.exit(0)
print(f"VALUE FINV_M10_N10_P090 {float(m.group(4)):.8f}")
PY

echo "== manifests into the record (exit 0 means build-only; exit 2 means a source file was changed before the build)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'gfortran -o test724 724.f' \
    --archive-file "$SCRATCH/tree/724.txt" --range "1:645" --extracted 724.f > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi
