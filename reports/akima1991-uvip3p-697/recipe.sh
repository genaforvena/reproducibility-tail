#!/usr/bin/env bash
# Rebuilds and reruns TOMS Algorithm 697 (Akima 1991, UVIP3P univariate interpolation, Fortran 77) and records the
# shipped test driver's comparison of its one-call result YI2 with the driver's own expected values YIE (NP = 3 and 6).
# All execution of the authors' code goes through tools/sandbox.sh. The host only hashes source text, parses printed
# output and writes the report.
#
# Fetch (network, inside the sandbox): netlib TOMS 697.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/697/697.f. gfortran (conda-forge, micromamba) goes to /work/env if missing.
#
# Original attempt (G1): the file as shipped is compiled with gfortran -std=legacy. The file holds the program
# TTUVIP and the subroutine UVIP3P twice (lines 1-538 and 539-1073; the second copy differs only in a comment and
# in an uncommented OPEN statement, label 10). The duplicate PROGRAM and SUBROUTINE names make the shipped file fail
# to compile. That attempt is kept in evidence/original-attempt.log.
#
# Patch (basis patched, kind extraction): the build uses one verbatim line range of the archive, lines 1-538 (the
# first copy: the ACM notice, the test driver TTUVIP and UVIP3P), copied into UVIP.f in the build copy. No statement,
# DATA value or comment is changed. The copy is taken by this recipe from the archive bytes on every run.
# Build: gfortran -std=legacy -w -o ttuvip UVIP.f
#
# Claim (queue/akima1991-uvip3p-697.json): the one-call result YI2 of UVIP3P agrees with the driver's expected values
# YIE(31,2) at all 31 abscissas for NP = 3 and NP = 6, absolute tolerance 0.0005. The driver prints DYI2 = YI2 - YIE
# in F9.3, so a printed difference of 0.000 means |YI2 - YIE| < 0.0005. VALUE lines give the largest printed |DYI2|.
# Two passes (G3): each builds from a clean copy of the unpacked file with the same commands, runs, and the two
# passes must print the same table.
set -uo pipefail
ID=akima1991-uvip3p-697
URL=https://netlib.org/toms/697.gz
SHA=4ffb55563069643e621b7142134398e4a8c2fb4364e4472ede2bb455cf5d5e22
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/env/bin:$PATH'
PATCH="sed -n '1,538p' 697.f > UVIP.f"
BUILD='gfortran -std=legacy -w -o ttuvip UVIP.f'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 697.gz (sha256 checked), gunzipped to /work/pre/697/697.f; toolchain (gfortran) into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre/697 && cd /work/pre/697 && curl -fsSL -o /work/697.gz '$URL'; echo '$SHA  /work/697.gz' | sha256sum -c -; gzip -dc /work/697.gz > /work/pre/697/697.f; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== manifest pre: the unpacked tree as shipped (one file, 697.f), before any patch"
python3 tools/verify_sources.py manifest "$SCRATCH/pre/697" > "$SCRATCH/manifest.pre"
cat "$SCRATCH/manifest.pre"

echo "== original attempt (G1): the file as shipped, compiled as documented (no build file ships; gfortran -std=legacy)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/orig && mkdir -p /work/orig && cp /work/pre/697/697.f /work/orig/697.f && cd /work/orig && gfortran -std=legacy -w -o asis 697.f; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
grep -E 'build_exit=|Error|Duplicate|already' "$E/original-attempt.log" | head -6

echo "== pass 1: copy of the unpacked tree, patch step (extract lines 1-538), manifest mid, then the build"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/697 /work/build && cd /work/build && $PATCH && echo patched" > "$E/patch.log" 2>&1
cat "$E/patch.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/build && gfortran -std=legacy -w -o ttuvip UVIP.f; echo build_exit=\$?" > "$E/build.log" 2>&1
grep -E 'build_exit=|Error' "$E/build.log" | head -5
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"

echo "== record the patch proof (host, text only; exit 0 is build-only, 2 means a source changed before the build; kind must be extraction)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'gfortran -std=legacy -w -o ttuvip UVIP.f' \
    --archive-file "$SCRATCH/pre/697/697.f" --range "1:538" --extracted UVIP.f > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

echo "== pass 1 run: the driver, stdin closed, output kept"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./ttuvip < /dev/null > /work/out-pass1.txt 2>/work/err-pass1.txt; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-stdout.txt" 2>/dev/null || echo "pass1 produced no stdout"

echo "== pass 2 (G3): clean copy of the unpacked tree, same patch and build commands, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 /work/out-pass2.txt && cp -r /work/pre/697 /work/pass2 && cd /work/pass2 && $PATCH && $BUILD && ./ttuvip < /dev/null > /work/out-pass2.txt 2>/work/err-pass2.txt; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-stdout.txt" 2>/dev/null || echo "pass2 produced no stdout"

echo "== values (host, text only): largest |DYI2| as printed (YI2 - YIE, F9.3), per NP block, both passes"
python3 -I - "$E/pass1-stdout.txt" "$E/pass2-stdout.txt" <<'PY' > "$E/values.txt" || true
import re, sys

def blocks(path):
    out = []
    for line in open(path):
        m = re.search(r"NP =\s*(\d+)", line)
        if m:
            out.append([int(m.group(1)), []])
            continue
        s = line.rstrip("\n")
        if not out or not s.strip() or not re.fullmatch(r"[\s\-0-9.]+", s):
            continue
        out[-1][1].append(s.split())
    return out

def dyi2(path):
    res = {}
    for np_, rows in blocks(path):
        # 8 tokens: XD1 YD1 XI1 YIE YI1 DYI1 DYI2 DYI3 (II <= ND); 6 tokens: XI1 YIE YI1 DYI1 DYI2 DYI3
        vals = [float(r[6]) if len(r) == 8 else float(r[4]) for r in rows if len(r) in (6, 8)]
        assert len(vals) == 31, (path, np_, len(vals))
        res[np_] = max(abs(v) for v in vals)
    assert sorted(res) == [3, 6], (path, res)
    return res

a, b = dyi2(sys.argv[1]), dyi2(sys.argv[2])
for np_ in (3, 6):
    assert a[np_] == b[np_], ("passes disagree", np_, a[np_], b[np_])
    print(f"VALUE YI2 vs YIE, NP={np_}, all 31 points {a[np_]:.3f}")
PY
cat "$E/values.txt"
echo "== done; scratch kept at $SCRATCH"
