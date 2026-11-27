#!/usr/bin/env bash
# Rebuilds and reruns the rerun record for goldstein1973-chisqd-451 (TOMS 451, CHISQD: chi-square quantile,
# Goldstein 1973). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 451.gz, sha256 checked against the value below,
# then gunzip. gfortran 16 from conda-forge via micromamba into /work/env16 when missing.
# Unpack: the archive is a shell archive; it is NOT executed. extract-tree.awk (this directory) copies the text of each
# here-document body into Fortran/Sp/Drivers and Fortran/Sp/Src verbatim. The archive quotes its delimiter as "SHAR_EOF",
# which the stock extract-tree.awk of bai1997 does not match; this directory's copy does.
# Original attempt (G1): the authors' Drivers/Makefile, as shipped, is run first with no compiler variables. The
# Makefile expects F77/F77OPTS/DIFF/SRCLIBS from the environment and does not define them. Log kept in
# evidence/original-attempt-make.log.
# Build (patched, compiler substitution only): the authors' single-precision sources are compiled unmodified with
# gfortran -O2 (no source edit). Pass 1 and pass 2 run the same binary, each in a fresh run directory.
# Run: the driver takes no input and writes its table to stdout. Each pass is bounded by timeout 120.
# Basis: patched (the authors' Makefile is not usable as shipped; the compiler is substituted). Build-only: no
# source file changes before the build, so the paper check of G2 is not needed (verify_sources record exit 0).
# Value: VALUE line prints the computed CHISQD(0.5, 10) from the first (computed) row for N = 10, column P = 0.5.
set -uo pipefail
ID=goldstein1973-chisqd-451
URL=https://netlib.org/toms/451.gz
SHA=5bb6f1b1fe499f96d326188e5502977a1b190e2dcc40ed29a3b18fcb53c55a88
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 451.gz (sha256 checked, gunzip); gfortran 16 into /work/env16 if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "cd /work; \
  test -s /work/451.gz || curl -fsSL -o /work/451.gz '$URL'; echo '$SHA  /work/451.gz' | sha256sum -c - > /work/sha.txt 2>&1; \
  gunzip -kf /work/451.gz; \
  test -x /work/bin/micromamba || { mkdir -p /work/bin; curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; }; \
  test -x /work/env16/bin/gfortran || /work/bin/micromamba create -y -q -p /work/env16 -r /work/mamba -c conda-forge gfortran; \
  /work/env16/bin/gfortran --version | head -1 > /work/gfortran-version.txt"
cp "$SCR/sha.txt" "$E/archive-sha256-check.txt" && cat "$E/archive-sha256-check.txt"
cp "$SCR/gfortran-version.txt" "$E/" && cat "$E/gfortran-version.txt"
cp "$here/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the archive's directory tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/451 > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
cp "$SCR/tree/Fortran/Sp/Drivers/res" "$E/shipped-res.txt"

echo "== G1 original attempt: the authors' Drivers/Makefile as shipped (no compiler variables), before any substitution"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && cp /work/tree/Fortran/Sp/Drivers/Makefile /work/tree/Fortran/Sp/Drivers/driver.f . && \
  cp /work/tree/Fortran/Sp/Src/src.f . && make 2>&1; echo make_exit=$?' > "$E/original-attempt-make.log" 2>&1
tail -1 "$E/original-attempt-make.log"
echo "== G1 retry after the toolchain is in the sandbox: the same authors' Makefile, with F77 set to gfortran (compiler name only)"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/orig2 && mkdir -p /work/orig2 && cd /work/orig2 && cp /work/tree/Fortran/Sp/Drivers/Makefile /work/tree/Fortran/Sp/Drivers/driver.f . && \
  cp /work/tree/Fortran/Sp/Src/src.f . && make F77=gfortran 2>&1; echo make_exit=$?' > "$E/retry-make-f77-gfortran.log" 2>&1
tail -1 "$E/retry-make-f77-gfortran.log"

echo "== manifest pre (right after unpack, before any patch)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step: none (no authors' source file is edited; the compiler is gfortran, not the Makefile default)"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

echo "== build pass 1: gfortran -O2 on the authors' single-precision driver and CHISQD"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env16/bin:$PATH && rm -rf /work/build && mkdir -p /work/build && cd /work/build && \
  gfortran -O2 -c /work/tree/Fortran/Sp/Src/src.f -o src.o && gfortran -O2 -c /work/tree/Fortran/Sp/Drivers/driver.f -o driver.o && \
  gfortran -O2 driver.o src.o -o driver && echo build_exit=$?' > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifests/manifest.pre" --mid "$E/manifests/manifest.mid" --post "$E/manifests/manifest.post" \
  --command 'gfortran -O2 -c /work/tree/Fortran/Sp/Src/src.f -o src.o' \
  --command 'gfortran -O2 -c /work/tree/Fortran/Sp/Drivers/driver.f -o driver.o' \
  --command 'gfortran -O2 driver.o src.o -o driver' || exit 1

echo "== run pass 1 (-O2 build): timeout 120, stdout is the driver's table"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir -p /work/run1 && cd /work/run1 && \
  timeout 120 /work/build/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass1.txt" 2> "$E/run-pass1.log"
tail -1 "$E/run-pass1.log"

echo "== run pass 2: fresh run directory, same built binary (environment: new directory, new process)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run2 && mkdir -p /work/run2 && cd /work/run2 && \
  timeout 120 /work/build/driver > stdout.txt 2> stderr.txt; echo run_exit=$?; cat stdout.txt' > "$E/run-pass2.txt" 2> "$E/run-pass2.log"
tail -1 "$E/run-pass2.log"

# Observed values: the computed CHISQD(0.5, 10) is the first row whose N column is 10 (the writeup row follows it),
# and P = 0.5 is the third column. The name is the one in result.json.
val() { awk '$1==10 {print $4; exit}' "$1"; }
echo "OBSERVED pass1 CHISQD_0.5_10_computed $(val "$E/run-pass1.txt")"
echo "OBSERVED pass2 CHISQD_0.5_10_computed $(val "$E/run-pass2.txt")"
echo "VALUE CHISQD(0.5, 10) $(val "$E/run-pass1.txt")"
