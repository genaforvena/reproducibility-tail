#!/usr/bin/env bash
# Rebuilds the rerun record for dorrer1968-fdist-322 (TOMS 322, Dorrer's F-distribution: Fortran 77 PROB function, Weissman 1994 recoding).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py), parses text output and writes the report.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 322.gz (sha256 checked against the queue entry),
# gunzipped to /work/tree/322.txt (one text file: prose, the Fortran PROB and test driver PROGRAM tstprob, then a shar
# archive of a C version that is not used). gfortran (conda-forge, via micromamba) goes to /work/env if missing.
#
# Original attempt (G1): the file as shipped is compiled with gfortran -std=legacy. It fails at line 1 (prose).
#
# Patch (basis patched, kind source, NOT extraction): the Fortran code is lines 24-254, but lines 117-119 (a
# "-------------" separator and two blank lines) are not Fortran; gfortran stops there (line 117 in the archive). Those
# three lines are deleted. No statement, constant or DATA value is changed. The contiguous range 24:254 would
# not compile, so the record is a source change and gate G2 applies (see result.md).
# Build: gfortran -std=legacy -w -o tstprob DORRER.FOR
#
# Claim: two upper-tail probabilities from the shipped test driver's DATA tables (the 0.05 block), computed by
# p = 1 - PROB(nf1, nf2, f): entry 51 (F=161.45, df 1,1) and entry 63 (F=2.9782, df 10,10). Tol_abs 5e-4 (fixed in the queue entry).
# Two passes (G3): each is a clean rebuild from the unpacked tree, each run from the same inputs (the driver has none).
set -uo pipefail
ID=dorrer1968-fdist-322
URL=https://netlib.org/toms/322.gz
SHA=f90c21567ea61d9ad8fdc0b9faaf799f9f467417ed71b04852e445b8eb294ecd
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
PATCH="sed -n '24,116p;120,254p' 322.txt > DORRER.FOR"
BUILD='gfortran -std=legacy -w -o tstprob DORRER.FOR'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 322.gz (sha256 checked), gunzipped to /work/tree/322.txt; toolchain (gfortran, make) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/tree && cd /work/tree && curl -fsSL -o /work/322.gz '$URL'; echo '$SHA  /work/322.gz' | sha256sum -c -; gzip -dc /work/322.gz > /work/tree/322.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran make; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the file as shipped, compiled as documented"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/orig && mkdir -p /work/orig && cp /work/tree/322.txt /work/orig/322.f && cd /work/orig && gfortran -std=legacy -w -o asis 322.f; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|Error' "$E/original-attempt.log" | head -3

echo "== unpack listing (manifest pre: the authors' file as shipped, before any build)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && find . -type f | sort" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== pass 1: copy of the unpacked tree, patch step (drop the three separator lines), manifest (mid), then the build"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && cd /work/build && $PATCH && echo patched" > "$E/patch.log" 2>&1
cat "$E/patch.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && $BUILD; echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|Error' "$E/pass1-build.log" | head -5

echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the driver, stdin closed, output kept"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./tstprob < /dev/null > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-stdout.txt" 2>/dev/null || echo "pass1 produced no stdout"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same commands, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 /work/out-pass2.txt && cp -r /work/tree /work/pass2 && cd /work/pass2 && $PATCH && $BUILD && ./tstprob < /dev/null > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-stdout.txt" 2>/dev/null || echo "pass2 produced no stdout"

echo "== reference: the shipped DATA for the two registered points (322.txt lines 190-192 and 210)"
tools/sandbox.sh "$ID" -- sh -c "sed -n '190,192p;210p' /work/tree/322.txt" > "$E/reference-block.txt" 2>&1
cat "$E/reference-block.txt"

echo "== values: p = 1 - PROB as printed by report(), F block only, both passes"
python3 -I - "$E/pass1-stdout.txt" "$E/pass2-stdout.txt" <<'PY' > "$E/values.txt" || true
import re, sys
def f_block(path):
    text = open(path).read()
    return text[text.index("Testing F distribution"):]
def pick(path, n1, n2, x):
    rows = []
    for line in f_block(path).splitlines():
        m = re.match(r"^\s*(\d+)\s+(\d+)\s+(-?[0-9.]+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$", line)
        if m and int(m.group(1)) == n1 and int(m.group(2)) == n2 and abs(float(m.group(3)) - x) < 1e-9:
            rows.append(float(m.group(5)))  # p-calc column
    return rows[0] if len(rows) == 1 else None
for tag, path in (("pass1", sys.argv[1]), ("pass2", sys.argv[2])):
    a = pick(path, 1, 1, 161.45)
    b = pick(path, 10, 10, 2.9782)
    print(tag, "p(161.45; 1,1)", a, "p(2.9782; 10,10)", b)
PY
cat "$E/values.txt"

echo "== values for the record (VALUE lines are read by the G5 replay)"
V=$(python3 -I - "$E/pass1-stdout.txt" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
text = text[text.index("Testing F distribution"):]
def pick(n1, n2, x):
    for line in text.splitlines():
        m = re.match(r"^\s*(\d+)\s+(\d+)\s+(-?[0-9.]+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$", line)
        if m and int(m.group(1)) == n1 and int(m.group(2)) == n2 and abs(float(m.group(3)) - x) < 1e-9:
            return float(m.group(5))
    return float("nan")
print(f"{pick(1, 1, 161.45):.6e} {pick(10, 10, 2.9782):.6e}")
PY
)
read A B <<< "$V"
echo "VALUE p for F=161.45 with (1,1) df ${A}"
echo "VALUE p for F=2.9782 with (10,10) df ${B}"

echo "== manifests into the record (exit 0 means build-only; exit 2 means a source file was changed before the build, so G2 applies)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'gfortran -std=legacy -w -o tstprob DORRER.FOR' \
    --archive-file "$SCRATCH/tree/322.txt" --range "24:254" --extracted DORRER.FOR > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi
