#!/usr/bin/env bash
# Rebuilds the rerun record for houstis1972-product-438 (CACM Algorithm 438, product-type two-point
# Gauss-Legendre-Simpson integration, Fortran, Houstis/Mitchell/Rice 1972). Everything that runs the authors'
# code goes through tools/sandbox.sh. The host only hashes sources (tools/verify_sources.py), parses text output
# and writes the report.
#
# Fetch (network, inside the sandbox): netlib TOMS 438.gz, sha256 checked against the queue entry's code.archive,
# decompressed, and the shell archive (text from '#! /bin/sh' on) run in /work/pre to create Fortran/Dp/{Drivers,Src}.
# gfortran (conda-forge, micromamba) into /work/fortran if missing.
#
# G1 original attempt: the authors' Makefile in the shipped layout (run in a copy, /work/orig-run). The Makefile
# compiles src.f from its own directory, but the archive puts src.f in ../Src, so make stops at once. The log is kept.
#
# Build-only patch: no source file is edited. The build runs the Makefile's own rules as separate commands, with the
# path to src.f set to ../Src. The manifests (pre, mid, post) prove that no .f, Makefile or other source changed.
#
# Run: the authors' driver prints TEST01 (integral of 1/(1+x**2) over [-4,4] by P2PGS, the header's "-1 to 1" is a
# mislabel; the driver's own Exact line, 2*atan(4) = 2.65164, uses [-4,4]). The claim is VINT at N = 10, 2.65082,
# tolerance 2e-5. The claim is not edited to fit the header or the Exact line.
set -uo pipefail
ID=houstis1972-product-438
URL=https://netlib.org/toms/438.gz
SHA=bda38a3451fc5c7f11334fcd459802c5eb895b69b6c27c4fc9fe3527237a74e7
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 438.gz (sha256 checked), shell archive unpacked to /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/438.gz '$URL'; \
  echo \"sha256 \$(sha256sum /work/438.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  /work/438.gz' | sha256sum -c -; \
  gunzip -c /work/438.gz > /work/438.txt; \
  sed -n '/^#! \/bin\/sh/,\$p' /work/438.txt > /work/438.sh; \
  (cd /work/pre && sh /work/438.sh); \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  mkdir -p /work/bin && ln -sf $G /work/bin/gfortran && gfortran --version | head -1; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== manifest pre (right after unpack, before any build step)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
cat "$E/manifest.pre"

echo "== G1 original attempt: the authors' Makefile in the shipped layout, run in a copy"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/Fortran /work/orig-run/ && cd /work/orig-run/Fortran/Dp/Drivers && make F77=gfortran F77OPTS= SRCLIBS= DIFF=diff Res; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (no patch step touches a source file; immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build (the Makefile's rules, with src.f taken from ../Src) and run"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Dp/Drivers && gfortran -c ../Src/src.f"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Dp/Drivers && gfortran -c driver.f"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Dp/Drivers && gfortran -o driver driver.o src.o"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Dp/Drivers && ./driver > Res; echo run_exit=\$?"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== evidence: Res against the shipped res"
cp "$SCR/pre/Fortran/Dp/Drivers/Res" "$E/Res"
cp "$SCR/pre/Fortran/Dp/Drivers/res" "$E/res-shipped"
diff "$E/Res" "$E/res-shipped" > "$E/res-diff.txt"; echo "diff_exit=$? (0 = identical to the shipped res)"

echo "== values"
python3 -I - "$E/Res" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = text.split("TEST01")
if len(blocks) < 2:
    print("no TEST01 block"); sys.exit(0)
test01 = blocks[1].split("TEST02")[0]
m = re.search(r"^\s*10\s+(\S+)\s*$", test01, re.M)
if not m:
    print("no N = 10 row in TEST01"); sys.exit(0)
print(f"VALUE VINT_TEST01_N10 {m.group(1)}")
PY

echo "== manifests into the record (exit 0 means build-only; exit 2 means a source file was changed before the build)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCR/manifest.pre" --mid "$SCR/manifest.mid" --post "$SCR/manifest.post" \
    --command 'gfortran -c ../Src/src.f' --command 'gfortran -c driver.f' --command 'gfortran -o driver driver.o src.o' --command './driver > Res' \
    > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi
