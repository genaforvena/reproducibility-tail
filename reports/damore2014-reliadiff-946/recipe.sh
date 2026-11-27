#!/usr/bin/env bash
# Rebuilds the rerun record for damore2014-reliadiff-946 (ACM TOMS Algorithm 946, ReLIADiff, C++ with GSL,
# D'Amore, Campagna, Mele, Murli 2014). Everything that runs the authors' code goes through tools/sandbox.sh.
# The host only hashes sources (tools/verify_sources.py), reads text output and writes the report.
#
# Fetch (network, inside the sandbox): netlib TOMS 946.zip, sha256 checked against the queue entry's code.archive,
# unpacked to /work/pre (so the tree is /work/pre/946). The archive ships gsl-1.15.tar.gz.
#
# G1 original attempt: the authors' documented route, run in a copy (/work/orig-run): `make -f Makefile_gsl`
# (GSL 1.15 into demos-Linux_g++/GSL), then `make -f Makefile_gslloc` in DEMO2-Function_To_Give. The DEMO2 target
# util calls the utility directory's plain Makefile, which still points at /usr/local for GSL, so make stops with
# "No rule to make target '/usr/local/include/gsl/', needed by 'Util.o'". The log is kept.
#
# Build-only patch: no source file is edited. The build runs the authors' own Makefiles where they work
# (make -f Makefile_gsl; make -C src; make -C utility -f Makefile_gslloc) and then the DEMO2 compile and link
# lines with the GSL path set to ../GSL, as the DEMO2 Makefile writes them. The run is the authors' default script,
# TEST_default.sh. The manifests (pre, mid, post) prove that no source file changed.
#
# Claim: the f_comp value in the x = 5.00e+00 row of the default demo output, 1.29653819e+00, tolerance 2e-8.
# The claim is not edited.
set -uo pipefail
ID=damore2014-reliadiff-946
URL=https://netlib.org/toms/946.zip
SHA=23e42c6c0441575e12a1e4374747e3dab2c875ade6d2c6ffb58f4610cd67d55c
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

D=/work/pre/946/C++_files/demos-Linux_g++
DEMO=$D/DEMO2-Function_To_Give

echo "== fetch: 946.zip (sha256 checked), unpacked to /work/pre"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre && cd /work/dl && curl -fsSL -o 946.zip '$URL'; \
  echo \"sha256 \$(sha256sum 946.zip | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  946.zip' | sha256sum -c -; \
  unzip -q 946.zip -d /work/pre; find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -3 "$E/fetch.log"

echo "== manifest pre (right after unpack, before any build step)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the documented route in a copy (GSL 1.15 install, then DEMO2 make)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/946 /work/orig-run/ && \
  cd /work/orig-run/946/C++_files/demos-Linux_g++ && make -f Makefile_gsl > /work/orig-gsl.log 2>&1; echo gsl_make_exit=\$?; \
  cd DEMO2-Function_To_Give && make -f Makefile_gslloc > /work/orig-demo2.log 2>&1; echo demo2_make_exit=\$?; tail -5 /work/orig-demo2.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the authors' Makefiles where they work, then the DEMO2 compile and link lines (GSL at ../GSL)"
tools/sandbox.sh "$ID" -- sh -c "cd $D && make -f Makefile_gsl > /work/build-gsl.log 2>&1; echo gsl_exit=\$?"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/946/C++_files/src && make > /work/build-src.log 2>&1; echo src_exit=\$?"
tools/sandbox.sh "$ID" -- sh -c "cd $D/utility && make -f Makefile_gslloc > /work/build-util.log 2>&1; echo util_exit=\$?"
tools/sandbox.sh "$ID" -- sh -c "cd $DEMO && g++ -Wall -ansi -pedantic -g -I../GSL/include -I../../ -c TEST_FunctionToGive.c > /work/build-test.log 2>&1; echo compile_exit=\$?"
tools/sandbox.sh "$ID" -- sh -c "cd $DEMO && g++ -g -o test_functiontogive TEST_FunctionToGive.o -lm -L../../src -lreliadiff -L../utility -lutil -L../GSL/lib -lgsl -lgslcblas > /work/build-link.log 2>&1; echo link_exit=\$?"
# GSL is built as a shared library, so the run needs its lib directory on the loader path (no change to the binary).
tools/sandbox.sh "$ID" -- sh -c "cd $DEMO/scripts && LD_LIBRARY_PATH=$D/GSL/lib sh TEST_default.sh > /work/run.log 2>&1; echo run_exit=\$?; tail -3 /work/run.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== evidence: the row x = 5 against the shipped output"
cp "$SCR/pre/946/C++_files/demos-Linux_g++/DEMO2-Function_To_Give/scripts/output_demo2_default/output_demo2.txt" "$E/output_demo2.txt"
cp "$SCR/pre/946/C++_files/demos-Linux_g++/DEMO2-Function_To_Give/scripts/output_demo2_default_EXAMPLE/output_demo2.txt" "$E/output_demo2-shipped.txt"
sha256sum "$E/output_demo2-shipped.txt" | cut -d' ' -f1 > "$E/output_demo2-shipped.sha256"
cat "$E/output_demo2-shipped.sha256"
diff "$E/output_demo2.txt" "$E/output_demo2-shipped.txt" > "$E/output-diff.txt"; echo "diff_exit=$? (full file; the elapsed-time lines are expected to differ)"

echo "== values"
python3 -I - "$E/output_demo2.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^\|\s*5\.00e\+00\s*\|\s*(\S+)\s*\|", text, re.M)
if not m:
    print("no x = 5.00e+00 row"); sys.exit(0)
print(f"VALUE RELIADIFF_FCOMP_X5 {m.group(1)}")
PY
