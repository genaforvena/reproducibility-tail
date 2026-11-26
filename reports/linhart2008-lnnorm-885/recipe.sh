#!/usr/bin/env bash
# Rebuilds the rerun verdict for linhart2008-lnnorm-885 (TOMS 885, log of the normal distribution, C).
# Fetch (the only network step): netlib TOMS 885.zip (sha256 checked), unpacked inside the sandbox scratch.
# Everything else runs through tools/sandbox.sh.
# Original attempt (G1): the authors' Doc/makefile, run in a copy of the C tree as documented (`make -f ../Doc/makefile`
# in C/). It stops at the link step: the makefile puts -lm before the objects, which the default --as-needed linker of
# this host rejects ("undefined reference to log"). Log kept in evidence/original-attempt.log (first attempt, never
# overwritten; a later rebuild writes original-attempt-rebuild.log).
# Patch (the basis): the same makefile, run unchanged, with one linker flag, CFLAGS='-Wl,--no-as-needed -lm'.
# No source file and no makefile line is edited. Build-only proof: manifests of the unpacked archive (pre), the
# build tree right before the build (mid) and after the build (post), recorded by tools/verify_sources.py.
# The probe (impl/probe_lnnorm.c) is written by us: it calls the authors' lnnorm() at x = -5.0 and prints
# -lnnorm(-5.0), because the authors' driver prints only maxima and means over the table. It is compiled against the
# build tree and does not modify it. Its compile command is a recorded build command.
# Claim: -lnnorm(-5.0) against the tabulated 15.0649983939887257 (Sheppard 1939, row 5.0), tol_abs 1.5e-8.
# Two clean passes (G3): each pass runs the authors' driver (main, for the whole-table evidence) and the probe in its
# own clean directory, the binaries from the build tree.
set -uo pipefail
ID=linhart2008-lnnorm-885
URL=https://netlib.org/toms/885.zip
SHA=4415d85ac688c4f1882f5b6100d9e8243d525c13cd65c9a8d93f40b44e544205
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 885.zip (sha256 checked), unpacked in the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "rm -rf /work/pre /work/build /work/g1 /work/probe && mkdir /work/pre && cd /work && curl -fsSL -o 885.zip '$URL' && echo '$SHA  885.zip' | sha256sum -c - && unzip -q 885.zip -d pre && test -f pre/885/C/main.c && test -f pre/885/C/sheppard.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$here/impl/probe_lnnorm.c" "$W/probe_lnnorm.c"

# G2 build-only proof, manifest 1 of 3: the authors' bytes, right after unpacking, before any copy or build.
python3 -I tools/verify_sources.py manifest "$W/pre/885" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") files"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/885/C/sheppard.txt" > "$E/reference/sheppard.txt" || { echo "REF-FAILED"; exit 1; }
echo "sheppard.txt sha256: $(sha256sum "$E/reference/sheppard.txt" | cut -d' ' -f1)"

echo "== G1 original attempt: the authors' Doc/makefile as documented, in a copy of the C tree"
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r /work/pre/885 /work/g1 && cd /work/g1/C && make -f ../Doc/makefile 2>&1; echo make_exit=\$?" > "$ORIG" 2>&1
grep -v "warning\|note:\|^ *[0-9]* |\|^ *|" "$ORIG" | tail -4

# The build tree: a full copy of the authors' unpacked tree. Every build command runs here.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/885 /work/build" || { echo "COPY-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree, immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: the authors' makefile with one linker flag (CFLAGS='-Wl,--no-as-needed -lm'), then the probe"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/C && make -f ../Doc/makefile CFLAGS='-Wl,--no-as-needed -lm' 2>&1; echo make_exit=\$?; mkdir -p /work/probe && cd /work/probe && cc -O -I/work/build/C -o probe /work/probe_lnnorm.c /work/build/C/lnnorm.c /work/build/C/normal.c /work/build/C/log1px.c /work/build/C/anorm.c /work/build/C/enorm.c /work/build/C/lnanorm.c /work/build/C/lnenorm.c -Wl,--no-as-needed -lm 2>&1; echo probe_build_exit=\$?" > "$E/build.log" 2>&1
grep -v "warning\|note:\|^ *[0-9]* |\|^ *|" "$E/build.log" | tail -4

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "make -f ../Doc/makefile CFLAGS='-Wl,--no-as-needed -lm'" \
  --command "cc -O -I/work/build/C -o probe /work/probe_lnnorm.c /work/build/C/lnnorm.c /work/build/C/normal.c /work/build/C/log1px.c /work/build/C/anorm.c /work/build/C/enorm.c /work/build/C/lnanorm.c /work/build/C/lnenorm.c -Wl,--no-as-needed -lm" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: G2 hold stays (see the record's kind and the added/modified lists)"

# Runs, twice (G3): each pass in its own clean directory; the authors' driver (whole-table evidence) and the probe.
for pass in run1 run2; do
  echo "== $pass: clean directory, the driver (main) and the probe"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/build/C/main /work/build/C/sheppard.txt /work/probe/probe /work/$pass/ && cd /work/$pass && timeout 900 ./main > driver-stdout.txt 2> driver-stderr.txt; echo ${pass}_driver_exit=\$?; timeout 300 ./probe > probe-out.txt; echo ${pass}_probe_exit=\$?; cp driver-stdout.txt /work/$pass-driver.txt; cp probe-out.txt /work/$pass-value.txt" || echo "$pass: run command failed"
  tools/sandbox.sh "$ID" -- cat /work/$pass-driver.txt > "$E/$pass-driver-stdout.txt"
  tools/sandbox.sh "$ID" -- cat /work/$pass-value.txt > "$E/$pass-value.txt"
  echo "$pass probe value (17 significant digits): $(cat "$E/$pass-value.txt")"
done

echo "== claimed value per pass"
paste "$E/run1-value.txt" "$E/run2-value.txt"
echo "VALUE -lnnorm(-5.0) against Sheppard Table IV row 5.0 $(cat "$E/run2-value.txt")"
