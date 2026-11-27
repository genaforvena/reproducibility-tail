#!/usr/bin/env bash
# Rebuilds and reruns TOMS Algorithm 832 (Davis 2004, UMFPACK V4.3 with AMD V1.1), C with a Fortran helper.
# Claim: the "numeric factorization flops" value for the west0067 matrix in the shipped reference output
# UMFPACK/Demo/umf4.out (printed 1.41920e+04, tolerance abs 0.05), registered in queue/davis2004-umfpack-832.json.
# The claim and tolerance are not edited here.
#
# The archive ships UMFPACK and AMD with a stock Make/Make.include: CONFIG = -DNBLAS (no BLAS needed), CFLAGS = -O,
# and F77 = f77. The host and sandbox have no f77 and no gfortran. This recipe:
#   - installs gfortran into the sandbox during the --fetch step (micromamba, conda-forge), as deboor1980 and benner2016;
#   - runs the authors' documented target `make hb` in UMFPACK/Demo, with the Makefile and Make/ include files unchanged;
#     the only build choice passed is F77=gfortran, because readhb*.f are Fortran and the stock F77 name is f77.
# No source file is changed before the build (see the build-only manifests below).
#
# G1 original attempt: stock `make hb`, no F77 override, in a copy: it is logged and expected to fail at readhb
# ("f77: not found"). The basis is therefore `patched`: the authors' code is unchanged, the Fortran compiler is supplied.
set -uo pipefail
ID=davis2004-umfpack-832
URL=https://netlib.org/toms/832.zip
SHA=c0149f87f95678435f0363c84689975cad5814ac3a6912bdb4c6894dbb74debd
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
PATHSET='export PATH=/work/env/bin:$PATH'
DEMO=832/UMFPACK/Demo

echo "== fetch: netlib 832.zip (sha256 checked); gfortran into /work/env (micromamba, conda-forge)"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/dl; cd /work/dl
  curl -fsSL -o 832.zip '$URL'; echo '$SHA  832.zip' | sha256sum -c -
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }
  /work/env/bin/gfortran --version | head -1; ls /work/env/bin | grep -x 'f77' || echo no_f77_in_env; echo fetch_ok" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -3 "$E/fetch.log"

echo "== unpack the archive into pre/ (no network)"
tools/sandbox.sh "$ID" -- sh -c "set -e; cd /work && rm -rf pre orig pass2 && mkdir pre && python3 -I -c 'import zipfile; zipfile.ZipFile(\"dl/832.zip\").extractall(\"pre\")' && ls pre/$DEMO/Makefile pre/832/UMFPACK/Make/Make.include && echo unpack_ok" || { echo "UNPACK-FAILED"; exit 1; }
cp "$SCR/pre/$DEMO/umf4.out" "$E/umf4.out.reference"
sha256sum "$E/umf4.out.reference"

echo "== manifest.pre: the authors' tree right after unpacking, before any change"
python3 -I tools/verify_sources.py manifest "$SCR/pre/832" > "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt, in a copy: stock make hb, no F77 override, no gfortran alias"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && cp -a /work/pre /work/orig && cd /work/orig/$DEMO && mkdir -p tmp && make hb > /work/orig-hb.log 2>&1; echo hb_exit=\$?; tail -4 /work/orig-hb.log" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== patch step (no source change): create the demo's output directory, which make hb writes tmp/A into"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/$DEMO && mkdir -p tmp && ls Makefile ../Make/Make.include >/dev/null && echo patch_step_ok"
echo "== manifest.mid: immediately before the build commands"
python3 -I tools/verify_sources.py manifest "$SCR/pre/832" > "$E/manifest.mid"

echo "== build (the authors' documented 'make hb' in UMFPACK/Demo; F77 names gfortran)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && cd /work/pre/832/UMFPACK/Demo && make hb F77=gfortran > /work/build-hb.log 2>&1; echo hb_exit=\$?" > "$E/build-hb.exit" 2>&1
cat "$E/build-hb.exit"
tools/sandbox.sh "$ID" -- sh -c "cat /work/build-hb.log" > "$E/build-hb.log" 2>&1
echo "== manifest.post: after the build"
python3 -I tools/verify_sources.py manifest "$SCR/pre/832" > "$E/manifest.post"

echo "== G3: a second pass from a clean directory (fresh unpack, the same make hb command)"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/pass2 && mkdir -p /work/pass2 && python3 -I -c 'import zipfile; zipfile.ZipFile(\"/work/dl/832.zip\").extractall(\"/work/pass2\")' && cd /work/pass2/$DEMO && mkdir -p tmp && make hb F77=gfortran > /work/pass2-hb.log 2>&1; echo hb_exit=\$?" > "$E/pass2.exit" 2>&1
cat "$E/pass2.exit"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pass2-hb.log" > "$E/pass2-hb.log" 2>&1

echo "== values: the first 'numeric factorization flops' line after the west0067 run, pass 1, pass 2 and the shipped reference (host, text only)"
python3 -I - "$E/build-hb.log" "$E/pass2-hb.log" "$E/umf4.out.reference" <<'PY'
import re, sys
PAT = re.compile(r"numeric factorization flops\s+([0-9.eE+-]+)")
def flops_west0067(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    start = [i for i, l in enumerate(lines) if "readhb_nozeros < HB/west0067.rua" in l]
    if not start:
        return None, "no west0067 run in log"
    for l in lines[start[0] + 1:]:
        m = PAT.search(l)
        if m:
            return float(m.group(1)), l.strip()
    return None, "no flops line after west0067 run"
p1, l1 = flops_west0067(sys.argv[1])
p2, l2 = flops_west0067(sys.argv[2])
ref, lr = flops_west0067(sys.argv[3])
print(f"REFERENCE flops_west0067 {ref!r}   # {lr}")
print(f"PASS1 flops_west0067 {p1!r}   # {l1}")
print(f"PASS2 flops_west0067 {p2!r}   # {l2}")
if p1 is None:
    print("NO_VALUE")
else:
    print(f"VALUE flops_west0067 {p1!r}")
    print("G3 value agree" if p1 == p2 else "G3 value DIFFER")
PY
echo "== G3 log comparison: the west0067 block, timing lines removed, pass 1 vs pass 2"
python3 -I - "$E/build-hb.log" "$E/pass2-hb.log" <<'PY'
import sys
def block(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    s = [i for i, l in enumerate(lines) if "readhb_nozeros < HB/west0067.rua" in l][0]
    out = []
    for l in lines[s:s + 400]:
        if "time" in l or " wall " in l or "cpu" in l.lower() or "CPU" in l:
            continue
        out.append(l)
    return out
a, b = block(sys.argv[1]), block(sys.argv[2])
print("G3 block identical (timing lines removed)" if a == b else "G3 block DIFFERS")
PY

echo "== record the build-only proof (exit 0 means no source file changed before the build)"
python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifest.pre" --mid "$E/manifest.mid" --post "$E/manifest.post" --command 'cd /work/pre/832/UMFPACK/Demo && make hb F77=gfortran'
echo "recipe_done"
