#!/usr/bin/env bash
# Rebuilds and reruns Kuki's complex gamma / log-gamma with error control (TOMS Algorithm 421, Fortran 90 package from 2005)
# from the netlib archive. The archive is a shell archive (shar) of a Makefile, a driver, the algorithm source, a data file
# and the authors' reference output Drivers/res. All execution goes through tools/sandbox.sh; the host only hashes and
# parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 421.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/421.shar; gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Unpack: the shar is run with /bin/sh in an empty directory (/work/orig). It creates Doc/Makefile, Fortran90/Dp/Drivers
# (driver.f90, data, res) and Fortran90/Dp/Src (src.f90).
#
# Original attempt (G1): the authors' Makefile as documented (make in Drivers, with the Makefile in Doc/). It names no
# compiler (F77 is empty). Kept in evidence/original-attempt.log.
#
# Patch (build-only): no source file is edited. The Makefile's rules are run by hand with gfortran: it expects driver.f90 and
# src.f90 in one directory, and the archive keeps them in sibling directories (Drivers, Src), so src.f90 is compiled from Src
# into Drivers/src.o. The recorded manifests prove no source byte changed between pre, mid and post.
set -uo pipefail
ID=kuki1972-cgamma-421
URL=https://netlib.org/toms/421.gz
SHA=cea2d06751db06aa54dbe7ec6d75b7ce16d24d09c0a260069f37c9eefa0d1ff1
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
DRV=/work/orig/Fortran90/Dp/Drivers
mkdir -p "$E/manifests"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 421.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/421.gz '$URL'; echo '$SHA  /work/421.gz' | sha256sum -c -; gzip -dc /work/421.gz > /work/pre/421.shar; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack: the archive's own shell script, run with /bin/sh in an empty directory (sandbox)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir -p /work/orig && cd /work/orig && /bin/sh /work/pre/421.shar; echo unshar_exit=\$?" > "$E/unshar.log" 2>&1
tail -2 "$E/unshar.log"
MAN="$E/manifests"
python3 tools/verify_sources.py manifest "$SCRATCH/orig" > "$MAN/manifest.pre"

echo "== original attempt (G1): make RES as the authors' Makefile documents, no compiler named"
tools/sandbox.sh "$ID" -- sh -c "cd $DRV && env PATH=/usr/bin:/bin make -f /work/orig/Doc/Makefile VPATH=../Src RES; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"

echo "== patch (build-only): compiler named on the make command line; Src reached by VPATH; no file edited"
python3 tools/verify_sources.py manifest "$SCRATCH/orig" > "$MAN/manifest.mid"

echo "== build the authors' rules with gfortran, spelled out (sandbox; no editing in this step)"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env/bin:/usr/bin:/bin; cd /work/orig/Fortran90/Dp/Drivers && gfortran -c driver.f90 && cd /work/orig/Fortran90/Dp/Src && gfortran -c src.f90 -o /work/orig/Fortran90/Dp/Drivers/src.o && cd /work/orig/Fortran90/Dp/Drivers && gfortran -o driver driver.o src.o; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/orig" > "$MAN/manifest.post"

echo "== run the driver on the authors' data file (sandbox, no network); output to scratch, not the tree"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/run && cd $DRV && ./driver < data > /work/run/RES; echo run_exit=\$?; cat /work/run/RES" > "$E/run.txt" 2>&1
head -c 3000 "$E/run.txt"; echo

echo "== values (host, text only): the five loggamma entries named in the claim, printed by the driver"
python3 -I - "$E/run.txt" "$SCRATCH/orig/Fortran90/Dp/Drivers/res" <<'PY'
import re, sys
pat = re.compile(r"loggamma\(\s*(\S+?),\s*(\S+?)\)\s*=\s*\(\s*(\S+?),\s*(\S+?)\)")
def entries(text):
    out = {}
    for m in pat.finditer(text):
        r, i = float(m.group(1)), float(m.group(2))
        out[f"loggamma({r:g},{i:g})"] = (float(m.group(3)), float(m.group(4)))
    return out
ours = entries(open(sys.argv[1]).read())
ref = entries(open(sys.argv[2]).read())
want = ["loggamma(1,5)", "loggamma(2.5,5)", "loggamma(5,10)", "loggamma(2.5,-5)", "loggamma(5,-10)"]
for name in want:
    re_, im_ = ours[name]
    print(f"VALUE {name} real {re_:.8g}")
    print(f"VALUE {name} imag {im_:.8g}")
    print(f"# {name}: shipped res = {ref[name][0]:.8g}, {ref[name][1]:.8g}; "
          f"abs diff = {max(abs(re_-ref[name][0]), abs(im_-ref[name][1])):.3g}", file=sys.stderr)
PY
echo "== done; scratch kept at $SCRATCH"
