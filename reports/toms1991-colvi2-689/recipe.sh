#!/usr/bin/env bash
# Rebuilds the rerun record for toms1991-colvi2-689 (ACM TOMS Algorithm 689, COLVI2, nonlinear Volterra integral
# equations of the second kind, Fortran; Blom and Brunner 1991). Everything that runs the authors' code goes through
# tools/sandbox.sh.
#
# Fetch (network, inside the sandbox): netlib TOMS 689.gz, sha256 checked against the queue entry's code.archive,
# decompressed to /work/pre/689.txt and checked against the reference text sha256. gfortran (conda-forge, micromamba)
# into /work/fortran if missing.
#
# The archive is one text file with no shell archive and no Makefile. Its header (FILE_1..FILE_12) lists the units.
# G1: the archive as shipped is compiled first (gfortran -c 689.txt), and the log is kept.
#
# Selection (before the mid manifest): one file, colvi2.f, made of 689.txt's lines with these deleted, nothing changed:
#   1..132        header text (FILE_1 list), not Fortran
#   6761..6786    NCPJOB, CDC CYBER version (calls SECOND, not standard); the VAX version (ETIME, lines 6787..) is kept
#   6873..7054    FILE_7, the IMSL version of DECLUF, SOLLUF, ZERPOL (needs IMSL); FILE_8 (no IMSL, 7055..) is kept
#   8732..end     DRIVER 2 onward, later problem and output routines (not PASS 1)
# What remains: COLDOC through the FILE_8 routines, RPOLY, FILE_9 MACHAR (unmodified), utilities, the problem and
# output routines, and DRIVER 1 (PASS 1-6 block; PASS 1 is DEFOPT=21).
# MACHAR is used as shipped; the archive says "MUST BE MODIFIED BEFORE COMPILING" and that is NOT done here.
#
# Run: the driver's first summary block (PASS 1, DEFOPT=21, REQTOL=1E-3) is written to OUTPUT. The claim is its
# GLOB.ERR. value for the first component (t = 50).
set -uo pipefail
ID=toms1991-colvi2-689
URL=https://netlib.org/toms/689.gz
SHA=beaa7e6b4954ae0eb92c8ab58f2e606975cbc1e1ebe06910271f1d73b5a085df
TXTSHA=048cd1e16d7de7d27a4d87092fbcd0bd989fe816c3759058eeb362dbc0cb087f
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="${E:-$root/.mishe-tauftauf/artifacts/$ID/evidence}"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$E/recipe-run.log") 2>&1

echo "== fetch: 689.gz (sha256 checked), 689.txt unpacked to /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/build /work/orig && mkdir -p /work/pre /work/build /work/orig; \
  curl -fsSL -o /work/689.gz '$URL'; \
  echo \"sha256 \$(sha256sum /work/689.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  /work/689.gz' | sha256sum -c -; \
  gunzip -c /work/689.gz > /work/pre/689.txt; \
  echo \"text sha256 \$(sha256sum /work/pre/689.txt | cut -d' ' -f1) expected $TXTSHA\"; \
  echo '$TXTSHA  /work/pre/689.txt' | sha256sum -c -; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  mkdir -p /work/bin && ln -sf $G /work/bin/gfortran && gfortran --version | head -1; \
  ls -l /work/pre" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== manifest pre (right after unpack, before any extraction or build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$E/manifest.pre"
cat "$E/manifest.pre"

echo "== G1 original attempt: the archive text compiled as shipped (no split, no edit)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig && cp /work/pre/689.txt 689.f && gfortran -c -o 689.o 689.f; echo gfortran_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== selection: 689.txt minus the lines listed in the header comment above (no line changed)"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/pre/src && sed -e '1,132d' -e '6761,6786d' -e '6873,7054d' -e '8732,\$d' /work/pre/689.txt > /work/pre/src/colvi2.f && wc -l /work/pre/src/colvi2.f && sha256sum /work/pre/src/colvi2.f"

echo "== patch (single precision, the archive's own instruction in MACHAR's header: change CS (CD) in columns 1-2 to"
echo "   blanks, CD lines become comments). Applied to the MACHAR routine only, in the selected file, before the mid manifest."
echo "   Without it the REAL outputs EPS, EPSNEG, XMIN, XMAX are typed INTEGER (their REAL declaration is the CS line)."
tools/sandbox.sh "$ID" -- sh -c "sed -i '/SUBROUTINE MACHAR/,/^ *END *\$/{s/^CS/  /;s/^CD/C /}' /work/pre/src/colvi2.f && sha256sum /work/pre/src/colvi2.f && grep -n '^  *REAL\\|^C \\+DOUBLE' /work/pre/src/colvi2.f | sed -n 1,5p"

echo "== manifest mid (after the extraction, immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$E/manifest.mid"

echo "== build (authors' driver and routines, gfortran, default flags) and run PASS 1"
echo "   ETIME: the VAX NCPJOB calls an external ETIME that gfortran does not supply; impl/etime_shim.f (CPU_TIME) is"
echo "   copied into the build directory and linked. It feeds the CPU-time limit check only."
cp "$here/impl/etime_shim.f" "$SCR/build/etime_shim.f" 2>/dev/null || { mkdir -p "$SCR/build" && cp "$here/impl/etime_shim.f" "$SCR/build/etime_shim.f"; }
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && gfortran -c -o colvi2.o ../pre/src/colvi2.f && gfortran -c -o etime_shim.o etime_shim.f && gfortran -o driver colvi2.o etime_shim.o; echo build_exit=\$?"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./driver > run.stdout 2>&1; echo run_exit=\$?; ls -l OUTPUT"

echo "== second pass (environment: REAL = 8 bytes, -fdefault-real-8, a precision closer to the CYBER's 14 digits"
echo "   the archive documents). Same source, same shim, same driver; run in /work/build2. Its value is not a VALUE line."
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/build2 && cd /work/build2 && gfortran -fdefault-real-8 -c -o colvi2.o ../pre/src/colvi2.f && gfortran -fdefault-real-8 -c -o etime_shim.o ../build/etime_shim.f && gfortran -o driver colvi2.o etime_shim.o; echo build2_exit=\$?; ./driver > run.stdout 2>&1; echo run2_exit=\$?"
cp "$SCR/build2/OUTPUT" "$E/OUTPUT-real8" 2>/dev/null || echo "no real8 OUTPUT"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$E/manifest.post"

echo "== evidence: OUTPUT of the run"
cp "$SCR/build/OUTPUT" "$E/OUTPUT" 2>/dev/null || echo "no OUTPUT file"
cp "$SCR/build/run.stdout" "$E/run.stdout" 2>/dev/null || true

echo "== values"
python3 -I - "$E/OUTPUT" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"GLOB\.ERR\.EST\.=\s*(\S+)\s+GLOB\.ERR\.=\s*(\S+)\s+SD\s*=", text)
if not m:
    print("no GLOB.ERR. line in OUTPUT")
    sys.exit(0)
print(f"VALUE GLOB_ERR_PASS1 {float(m.group(2))!r}")
import os
r8 = os.path.join(os.path.dirname(sys.argv[1]), "OUTPUT-real8")
if os.path.exists(r8):
    t8 = open(r8, encoding="utf-8", errors="replace").read()
    m8 = re.search(r"GLOB\.ERR\.EST\.=\s*(\S+)\s+GLOB\.ERR\.=\s*(\S+)\s+SD\s*=", t8)
    print(f"PASS1_REAL8_GLOB_ERR {float(m8.group(2))!r}" if m8 else "PASS1_REAL8 no GLOB line")
PY
