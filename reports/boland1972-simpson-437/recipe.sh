#!/usr/bin/env bash
# Rebuilds the rerun verdict for boland1972-simpson-437 (TOMS 437, product Simpson; see result.md).
# Fetch (the only network step, inside the sandbox): netlib TOMS 437.gz, sha256 checked, gunzipped.
# The shell archive is unpacked by impl/extract-tree.awk (verbatim here-document bodies; nothing is executed).
# gfortran (conda-forge, micromamba) goes to /work/env if missing.
# Claim: VINT for TEST02 at N = 10 printed by Fortran/Dp/Drivers/driver.f, against the shipped reference
# output Drivers/res (0.521610), tolerance abs 1e-6.
# Original attempt (G1): the archive's Drivers/Makefile as shipped. The Makefile looks for src.f in Drivers/,
# but the archive ships src.f in Src/; make stops with "No rule to make target 'src.f'" (kept in
# evidence/original-attempt-2-build.log). Build-only patch: the build copy places src.f next to the Makefile.
# No source file is edited, and the manifests prove it (pre = mid = post for the tree).
# Pass 1: the Makefile (with the build-copy layout) run with gfortran -O2. Pass 2: driver.f and src.f compiled
# directly with gfortran in a clean directory, no optimisation flag.
set -uo pipefail
ID=boland1972-simpson-437
URL=https://netlib.org/toms/437.gz
SHA=3d5d67394e0a50131e5eaf60cdfff518c41e7e70b86e01f27e9eeaf65090f3ce
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1
D=/work/tree/Fortran/Dp/Drivers
S=/work/tree/Fortran/Dp/Src

echo "== fetch: 437.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/raw && cd /work/raw; \
  curl -fsSL -o 437.gz '$URL'; echo '$SHA  437.gz' | sha256sum -c - ; gzip -dc 437.gz > /work/raw/437.sh; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }; \
  /work/env/bin/gfortran --version | head -1 > /work/gfortran-version.txt" || { echo "FETCH-FAILED"; exit 1; }
cp "$SCR/raw/../gfortran-version.txt" "$E/" 2>/dev/null || true
tools/sandbox.sh "$ID" -- cat /work/gfortran-version.txt > "$E/gfortran-version.txt" && cat "$E/gfortran-version.txt"
cp "$here/impl/extract-tree.awk" "$SCR/extract-tree.awk"

echo "== unpack: verbatim here-document bodies into the tree (no shell archive is executed)"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/tree && mkdir -p /work/tree && cd /work/tree && awk -f /work/extract-tree.awk /work/raw/437.sh > /work/unpack.log 2>&1; echo rc=$? >> /work/unpack.log; find /work/tree -type f | sort > /work/listing.txt'
cp "$SCR/listing.txt" "$E/unpack-listing.txt" && cat "$E/unpack-listing.txt"
tools/sandbox.sh "$ID" -- cat /work/tree/Fortran/Dp/Drivers/res > "$E/reference/res" || { echo "REF-FAILED"; exit 1; }
sha256sum "$E/reference/res" | tee "$E/reference/res.sha256"

ORIG1="$E/original-attempt-build.log"
ORIG2="$E/original-attempt-2-build.log"
if [ ! -s "$ORIG2" ]; then
  echo "== G1 original attempt 2: the archive's Makefile as shipped, toolchain present (the first attempt, with no gfortran, is in $ORIG1)"
  tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env/bin:\$PATH; rm -rf /work/orig && mkdir /work/orig && cd /work/orig && cp $D/* . && \
    make F77=gfortran F77OPTS=-O2 DIFF=diff SRCLIBS= 2>&1; echo make_exit=\$?" > "$ORIG2" 2>&1
  cat "$ORIG2"
fi

echo "== manifest pre (right after unpack, before any build step)"
rm -rf "$E/manifests"; mkdir -p "$E/manifests"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.pre" || exit 1
echo "== patch step (build copy only): the Makefile and driver go to /work/build, and src.f next to them; the tree is not edited"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && mkdir /work/build && cp $D/* /work/build/ && cp $S/src.f /work/build/"
echo "== manifest mid (immediately before the build commands)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.mid" || exit 1

BUILD=('make F77=gfortran F77OPTS=-O2 DIFF=diff SRCLIBS= driver')
echo "== build: the archive's Makefile, in the build copy, with the toolchain at /work/env/bin"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH && cd /work/build && for c in "$@"; do sh -c "$c" || exit 1; done; echo build_exit=$?' sh "${BUILD[@]}" > "$E/build.log" 2>&1
tail -1 "$E/build.log"
echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/tree" > "$E/manifests/manifest.post" || exit 1

echo "== run pass 1: the built driver, fresh run directory"
tools/sandbox.sh "$ID" -- sh -c 'rm -rf /work/run1 && mkdir /work/run1 && cd /work/run1 && timeout 120 /work/build/driver > run.out 2>&1; echo run_exit=$?; cat run.out' > "$E/run-pass1.txt" 2>&1
head -1 "$E/run-pass1.txt"
echo "== run pass 2: clean directory, driver.f and src.f compiled directly, no optimisation flag"
tools/sandbox.sh "$ID" -- sh -c 'export PATH=/work/env/bin:$PATH; rm -rf /work/build2 && mkdir /work/build2 && cd /work/build2 && \
  gfortran -c /work/tree/Fortran/Dp/Src/src.f && gfortran -c /work/tree/Fortran/Dp/Drivers/driver.f && gfortran -o driver driver.o src.o && timeout 120 ./driver > run.out 2>&1; echo run_exit=$?; cat run.out' > "$E/run-pass2.txt" 2>&1
head -1 "$E/run-pass2.txt"

echo "== values (VALUE lines) from pass 1 and pass 2"
python3 -I "$here/impl/extract_value.py" "$E/run-pass1.txt" | tee "$E/values-run1.txt"
python3 -I "$here/impl/extract_value.py" "$E/run-pass2.txt" | tee "$E/values-run2.txt"
cmp -s "$E/values-run1.txt" "$E/values-run2.txt" && echo "pass 1 and pass 2 values identical" || echo "pass 1 and pass 2 values differ"
echo "== comparison with the shipped reference output (res), driver stdout after the run_exit line"
tail -n +2 "$E/run-pass1.txt" > "$E/driver-pass1.txt"; tail -n +2 "$E/run-pass2.txt" > "$E/driver-pass2.txt"
cmp -s "$E/driver-pass1.txt" "$E/reference/res" && echo "pass 1 output identical to res" || echo "pass 1 output differs from res (diff: evidence/diff-pass1-vs-res.txt)"
diff "$E/driver-pass1.txt" "$E/reference/res" > "$E/diff-pass1-vs-res.txt"; true
cmp -s "$E/driver-pass2.txt" "$E/reference/res" && echo "pass 2 output identical to res" || echo "pass 2 output differs from res (diff: evidence/diff-pass2-vs-res.txt)"
diff "$E/driver-pass2.txt" "$E/reference/res" > "$E/diff-pass2-vs-res.txt"; true
