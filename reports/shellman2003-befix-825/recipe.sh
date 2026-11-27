#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 825 claim (Shellman and Sikorski 2003, BEFix, C): the "average number of evaluations"
# printed for the first BEFix block of the large test (65025 cases, epsilon = 0.0001, q = 1, residual criterion) in the
# shipped reference C/Drivers/bigtest.res (inside 825.gz), line 42, value 20.417255. Absolute tolerance 1e-6, registered
# and not edited. Everything that runs the archive's code goes through tools/sandbox.sh.
# The host only hashes sources (tools/verify_sources.py), copies text output and prints the VALUE line.
#
# Fetch (network, inside the sandbox): netlib CALGO 825.gz, sha256 pinned in the queue entry. The shar is unpacked
# with /bin/sh (its #! /bin/sh line onward) into /work/pre, which is the scratch directory's pre/ on the host.
#
# G1 original attempt: the readme's documented command, unchanged, `gcc -lm fp.c -o fp`, in a copy of C/Drivers.
# The archive ships no fp.c (it ships C/Src/src.c and C/Drivers/driver.c), so the documented command fails before
# any compile. The attempt is logged.
#
# Build-only route: the same documented compile (GNU C, -lm) on the archive's own files, C/Src/src.c and
# C/Drivers/driver.c, with the binary written to /work/build outside the archive. No archive file is edited or linked
# in place. Pass 1 uses -O2; pass 2 uses -O0 in a second build directory, to check the count does not depend on
# optimisation.
#
# Value: `./driver 1` (the large test) prints the BEFix block. The recipe takes the number after the first
# "BEFix residual criterion method, epsilon = 0.000100, q = 1.000000" header and prints
# `VALUE BEFIX_AVG_EVALS_EPS1E-4_Q1 <number>` for each pass (the claimed name, as in result.json).
set -uo pipefail
ID=shellman2003-befix-825
URL=https://netlib.org/toms/825.gz
SHA=b28e369b226302276dfb83188d493c3029ebfca1714f66123495015b5dbf9b07
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 825.gz (sha256 checked), shar unpacked with /bin/sh into /work/pre"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre && cd /work/dl && curl -fsSL -o 825.gz '$URL'; \
  echo '$SHA  825.gz' | sha256sum -c -; gunzip -c 825.gz > 825.shar; sed -n '/^#! \/bin\/sh/,\$p' 825.shar > unpack.sh; \
  cd /work/pre && sh /work/dl/unpack.sh; echo unpack_exit=\$?; find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== manifest pre (right after unpack, before any patch or build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the readme's documented command, unchanged, in a copy of C/Drivers (no fp.c in the archive)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -a /work/pre/C/Drivers/. /work/orig/ && cd /work/orig && gcc -lm fp.c -o fp > /work/orig-gcc.log 2>&1; echo gcc_exit=\$?; cat /work/orig-gcc.log; ls fp 2>&1" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (immediately before the build; the archive is used as shipped)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build pass 1: the readme's compile on the archive's own files, -O2; pass 2: -O0 in a second build directory"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build /work/build2 && mkdir /work/build /work/build2 && { \
  cd /work/build && gcc -O2 -o driver /work/pre/C/Src/src.c /work/pre/C/Drivers/driver.c -lm && \
  cd /work/build2 && gcc -O0 -o driver /work/pre/C/Src/src.c /work/pre/C/Drivers/driver.c -lm; } > /work/build.log 2>&1; echo build_exit=\$?; cat /work/build.log; ls -l /work/build/driver /work/build2/driver" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== record the patch as build-only (exit 0 = no source changed before the build)"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$SCR/manifest.pre" --mid "$SCR/manifest.mid" --post "$SCR/manifest.post" \
  --command "gcc -O2 -o driver /work/pre/C/Src/src.c /work/pre/C/Drivers/driver.c -lm" \
  --command "gcc -O0 -o driver /work/pre/C/Src/src.c /work/pre/C/Drivers/driver.c -lm"
echo "record_exit=$?"

echo "== run: the large test (argument 1, no prompt), each pass in its own directory; the shipped input is none"
tools/sandbox.sh "$ID" -- sh -c "for b in build build2; do cd /work/\$b && timeout 1500 ./driver 1 > /work/out.\$b.txt 2>&1; echo driver_exit_\$b=\$?; done; \
  cp /work/pre/C/Drivers/bigtest.res /work/bigtest.shipped.res" > "$E/run.log" 2>&1
cat "$E/run.log"
for f in out.build out.build2 bigtest.shipped; do
  tools/sandbox.sh "$ID" -- sh -c "cat /work/$f.txt 2>/dev/null || cat /work/$f.res" > "$E/$f.txt"
done
sha256sum "$E/bigtest.shipped.txt" | cut -d' ' -f1 > "$E/bigtest.shipped.sha256"

echo "== values: the first BEFix block (epsilon 0.0001, q 1, residual) in each pass and in the shipped reference"
python3 -I - "$E" <<'PY'
import sys, os, re
E = sys.argv[1]
HDR = "BEFix residual criterion method, epsilon = 0.000100, q = 1.000000"
AVG = re.compile(r"^average number of evaluations = (\S+)")
def first_block_avg(name):
    with open(os.path.join(E, name), encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()
    for i, line in enumerate(lines):
        if line.strip() == HDR:
            for later in lines[i + 1:]:
                m = AVG.match(later)
                if m:
                    return m.group(1), i + 1
    return None, None
ship_val, ship_line = first_block_avg("bigtest.shipped.txt")
print(f"bigtest.shipped.txt: avg={ship_val} header_line={ship_line}")
for name in ("out.build.txt", "out.build2.txt"):
    val, line = first_block_avg(name)
    print(f"{name}: avg={val} header_line={line}")
val, _ = first_block_avg("out.build.txt")
print(f"VALUE BEFIX_AVG_EVALS_EPS1E-4_Q1 {val}")
PY
