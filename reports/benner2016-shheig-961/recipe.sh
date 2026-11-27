#!/usr/bin/env bash
# Rebuilds and reruns TOMS Algorithm 961 (Benner, Sima, Voigt 2016, SHHEIG: skew-Hamiltonian/Hamiltonian eigenproblems),
# Fortran 77, and compares the DGHFDF example's ALPHAR, ALPHAI and BETA with the shipped reference examples/DGHFDF.res.
# Claim and tolerance (abs 1e-3) are registered in queue/benner2016-shheig-961.json and are not edited here.
#
# The archive does not contain SLICOT, LAPACK or BLAS. make.inc (shipped, unedited) expects them at ../libs/ with
# 64-bit integers (-fdefault-integer-8). This recipe obtains them from pinned sources and places them where the
# authors' make.inc looks; no source file is changed.
#   SLICOT 5.9.1 source: Ubuntu noble pool slicot_5.9.1.orig.tar.gz (sha256 checked against its .dsc), built here as
#                        libslicot64.a with cmake -DSLICOT_INTEGER8=ON (ILP64).
#   LAPACK/BLAS ILP64:   Ubuntu noble liblapack64-dev/-3 and libblas64-dev/-3 3.12.0-3build1.1 (sha256 from the apt index).
#   gfortran:            conda-forge via micromamba, as in the deboor1980-solveblok-546 recipe.
#
# G1 original attempt: the authors' tree as shipped (make.inc unedited, no libraries placed) is built first, in a copy,
# and logged. It fails at link time for want of ../libs/slicot64.a. The basis is therefore `patched`: the authors' code
# is unchanged, and the dependency libraries the archive does not contain are supplied.
set -uo pipefail
ID=benner2016-shheig-961
URL=https://netlib.org/toms/961.zip
SHA=aaaf3abf3a23dbf7fe63c1f0cf66cc76a5bd671599d11787184004d51de745c1
UB=http://nl.archive.ubuntu.com/ubuntu/pool
SLDIR=SLICOT-SLICOT-Reference-163ee3a
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
PATHSET='export PATH=/work/env/bin:$PATH'

echo "== fetch: netlib 961.zip (sha256 checked); SLICOT 5.9.1 source (sha256 from its .dsc); ILP64 LAPACK/BLAS debs (sha256 from the apt index); gfortran into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/dl; cd /work/dl
  curl -fsSL -o 961.zip '$URL'; echo '$SHA  961.zip' | sha256sum -c -
  Q(){ curl -fsSL -o \"\$2\" '$UB/'\"\$1\"; }
  Q universe/s/slicot/slicot_5.9.1-2.dsc slicot.dsc
  Q universe/s/slicot/slicot_5.9.1.orig.tar.gz slicot_5.9.1.orig.tar.gz
  echo 'c059f82128bfb8848bf3ad4edf1f034d4d1910e79440f149861e90b7ad793efc  slicot_5.9.1.orig.tar.gz' | sha256sum -c -
  Q main/l/lapack/liblapack64-dev_3.12.0-3build1.1_amd64.deb liblapack64-dev.deb
  Q main/l/lapack/libblas64-dev_3.12.0-3build1.1_amd64.deb libblas64-dev.deb
  Q main/l/lapack/liblapack64-3_3.12.0-3build1.1_amd64.deb liblapack64-3.deb
  Q main/l/lapack/libblas64-3_3.12.0-3build1.1_amd64.deb libblas64-3.deb
  echo '78ca02368830758c0b1d08c1d58f0192045d2fa5841839d073ca6655f11ba58f  liblapack64-dev.deb
a5f0cf24fec2c029088036a1efbe6bac9900e5efeabeba9630fc9e11b928928c  libblas64-dev.deb
5fdd65cf0a8606f5ec3da9617019373ba1aa06882b5790051671ce46463de84f  liblapack64-3.deb
4570731d4b2e6f69eb7827f56fc3eef68ed936f74b42dff8705e5b130349978e  libblas64-3.deb' | sha256sum -c -
  sha256sum slicot.dsc
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }
  /work/env/bin/gfortran --version | head -1; echo fetch_ok" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -3 "$E/fetch.log"

echo "== dependencies (no network): unpack ILP64 LAPACK/BLAS, build SLICOT 5.9.1 with ILP64 integers"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && set -e; cd /work && rm -rf dep slicot sl-build pre orig && mkdir dep slicot pre
  for p in liblapack64-dev liblapack64-3 libblas64-dev libblas64-3; do dpkg-deb -x dl/\$p.deb dep; done
  tar -xzf dl/slicot_5.9.1.orig.tar.gz -C slicot
  D=/work/dep/usr/lib/x86_64-linux-gnu
  cmake -S slicot/$SLDIR -B sl-build -DSLICOT_TESTING=OFF -DSLICOT_INTEGER8=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_Fortran_COMPILER=/work/env/bin/gfortran -DBLA_VENDOR=Generic -DBLAS_LIBRARIES=\$D/blas64/libblas64.a -DLAPACK_LIBRARIES=\$D/lapack64/liblapack64.a -DCMAKE_INSTALL_PREFIX=/work/sl-install > sl-cmake.log 2>&1
  cmake --build sl-build -j4 > sl-build.log 2>&1
  test -f sl-build/lib/libslicot64.a && echo slicot_ok
  unzip -q dl/961.zip -d pre/961 2>/dev/null || python3 -c 'import zipfile; zipfile.ZipFile(\"dl/961.zip\").extractall(\"pre/961\")'
  ls pre/961/961/Src/make.inc" > "$E/deps.log" 2>&1 || { echo "DEPS-FAILED"; tail -30 "$E/deps.log"; exit 1; }
cat "$E/deps.log"

echo "== manifest.pre: the authors' tree right after unpacking, before any change"
python3 -I tools/verify_sources.py manifest "$SCR/pre/961/961" > "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt, in a copy: make.inc as shipped, no libraries placed"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/orig && cp -a /work/pre/961 /work/orig && cd /work/orig/961/Src && make lib > /work/orig-lib.log 2>&1; echo lib_exit=\$?; cd examples && make DGHFDF.exa > /work/orig-example.log 2>&1; echo example_exit=\$?; tail -3 /work/orig-example.log" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== patch step (not a source change): place the dependency libraries where make.inc expects them (../libs from examples/)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/pre/961/961/Src && mkdir -p libs && D=/work/dep/usr/lib/x86_64-linux-gnu && cp /work/sl-build/lib/libslicot64.a libs/slicot64.a && cp \$D/lapack64/liblapack64.a libs/lapack64.a && cp \$D/blas64/libblas64.a libs/blas64.a && ar rc libs/lpkaux64.a && ls -l libs"
echo "== manifest.mid: immediately before the build commands"
python3 -I tools/verify_sources.py manifest "$SCR/pre/961/961" > "$E/manifest.mid"

echo "== build (the authors' documented commands, make.inc unedited)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/pre/961/961/Src && make lib > /work/build-lib.log 2>&1; echo lib_exit=\$?" > "$E/build-lib.log" 2>&1
cat "$E/build-lib.log"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/pre/961/961/Src/examples && make DGHFDF.exa > /work/build-example.log 2>&1; echo example_exit=\$?; cat DGHFDF.exa" > "$E/build-example.log" 2>&1
cat "$E/build-example.log"
echo "== manifest.post: after the build"
python3 -I tools/verify_sources.py manifest "$SCR/pre/961/961" > "$E/manifest.post"

echo "== G3: a second pass from a clean directory (fresh unpack of the archive, the same placed libraries, the same commands)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && mkdir -p /work/pass2 && python3 -c 'import zipfile; zipfile.ZipFile(\"/work/dl/961.zip\").extractall(\"/work/pass2\")' && cd /work/pass2/961/Src && mkdir -p libs && D=/work/dep/usr/lib/x86_64-linux-gnu && cp /work/sl-build/lib/libslicot64.a libs/slicot64.a && cp \$D/lapack64/liblapack64.a libs/lapack64.a && cp \$D/blas64/libblas64.a libs/blas64.a && ar rc libs/lpkaux64.a && make lib > /work/pass2-lib.log 2>&1; echo lib_exit=\$?; cd examples && make DGHFDF.exa > /work/pass2-example.log 2>&1; echo example_exit=\$?; cat DGHFDF.exa" > "$E/pass2.log" 2>&1
cat "$E/pass2.log" | head -3
cp "$SCR/pass2/961/Src/examples/DGHFDF.exa" "$E/DGHFDF.pass2.exa" 2>/dev/null || echo "no pass-2 DGHFDF.exa"
cmp -s "$E/DGHFDF.exa" "$E/DGHFDF.pass2.exa" && echo "G3 pass: pass 2 output is byte-identical to pass 1" || echo "G3 FAIL: pass 2 output differs from pass 1"

echo "== values: ALPHAR, ALPHAI, BETA lines of the new run vs the shipped reference (host, text only)"
cp "$SCR/pre/961/961/Src/examples/DGHFDF.exa" "$E/DGHFDF.exa" 2>/dev/null || echo "no DGHFDF.exa produced"
cp "$SCR/pre/961/961/Src/examples/DGHFDF.res" "$E/DGHFDF.res.reference" 2>/dev/null
python3 -I - "$E/DGHFDF.exa" "$E/DGHFDF.res.reference" <<'PY'
import sys
def vecs(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    # shipped layout: the value line follows each "The vector NAME is" heading
    out = {}
    for i, ln in enumerate(lines):
        for name in ("ALPHAR", "ALPHAI", "BETA"):
            if ln.strip() == f"The vector {name} is":
                out[name] = [float(x) for x in lines[i + 1].split()]
    return out
ours, ref = vecs(sys.argv[1]), vecs(sys.argv[2])
tol = 1e-3
ok = True
for name in ("ALPHAR", "ALPHAI", "BETA"):
    for k, (r, o) in enumerate(zip(ref[name], ours[name]), 1):
        print(f"VALUE {name}_{k} {o!r}")
        if abs(r - o) > tol:
            ok = False
            print(f"DIFF {name}_{k} paper={r} ours={o}")
print("all_within_tol" if ok else "outside_tol")
PY

echo "== record the build-only proof (exit 0 means no source file changed before the build)"
python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifest.pre" --mid "$E/manifest.mid" --post "$E/manifest.post" --command 'cd /work/pre/961/961/Src && make lib' --command 'cd /work/pre/961/961/Src/examples && make DGHFDF.exa'
echo "recipe_done"
