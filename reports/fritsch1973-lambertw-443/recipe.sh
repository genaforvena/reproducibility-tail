#!/usr/bin/env bash
# Rebuilds the rerun record for fritsch1973-lambertw-443 (CACM Algorithm 443, Lambert's W function, Fortran, Fritsch,
# Shafer, Crowley 1973). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (network, inside the sandbox): netlib TOMS 443.gz, sha256 checked against the queue entry's code.archive,
# decompressed, and the shell archive (text from '#! /bin/sh' on) run in /work/pre to create Fortran/Sp/{Drivers,Src}.
# gfortran (conda-forge, micromamba) into /work/fortran if missing.
#
# G1: the authors' Makefile in the shipped layout (run in a copy, /work/orig-run). The Makefile compiles src.f from
# its own directory, but the archive puts src.f in ../Src, so make stops at once. The log is kept.
#
# Build-only patch: no source file is edited. The build runs the Makefile's own rules, with the path to src.f
# pointing at ../Src. The manifests (pre, mid, post) prove that no .f, Makefile or other source changed.
#
# Run: the authors' driver writes TEST01 (WEW_A) and TEST02 (WEW_B) to Res. The claim is the WEW_A value at x = 1.0.
set -uo pipefail
ID=fritsch1973-lambertw-443
URL=https://netlib.org/toms/443.gz
SHA=bf664e74f2700a5c8a2f6c27b4cbc9e1d7b37c19a792764fd73c6941f642026f
TXTSHA=b0ad6d705c4ca2ca094039f176486720d0a39a5d732185f789ae4b9a628da4e1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 443.gz (sha256 checked), shell archive unpacked to /work/pre; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/443.gz '$URL'; \
  echo \"sha256 \$(sha256sum /work/443.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  /work/443.gz' | sha256sum -c -; \
  gunzip -c /work/443.gz > /work/443.txt; \
  echo \"text sha256 \$(sha256sum /work/443.txt | cut -d' ' -f1) expected $TXTSHA\"; \
  sed -n '/^#! \/bin\/sh/,\$p' /work/443.txt > /work/443.sh; \
  (cd /work/pre && sh /work/443.sh); \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  mkdir -p /work/bin && ln -sf $G /work/bin/gfortran && gfortran --version | head -1; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== manifest pre (right after unpack, before any build step)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$E/manifest.pre"
cat "$E/manifest.pre"

echo "== G1 original attempt: the authors' Makefile in the shipped layout, run in a copy"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/Fortran /work/orig-run/ && cd /work/orig-run/Fortran/Sp/Drivers && make F77=gfortran F77OPTS= SRCLIBS= DIFF=diff Res; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (after the patch step, which is none to any source file; immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$E/manifest.mid"

echo "== build (the Makefile's rules, with src.f taken from ../Src) and run"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Sp/Drivers && gfortran -c ../Src/src.f"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Sp/Drivers && gfortran -c driver.f"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Sp/Drivers && gfortran -o driver driver.o src.o"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/Fortran/Sp/Drivers && ./driver > Res; echo run_exit=\$?"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$E/manifest.post"

echo "== evidence: Res against the shipped res"
cp "$SCR/pre/Fortran/Sp/Drivers/Res" "$E/Res"
cp "$SCR/pre/Fortran/Sp/Drivers/res" "$E/res-shipped"
diff "$E/Res" "$E/res-shipped" > "$E/res-diff.txt"; echo "diff_exit=$? (0 = identical to the shipped res)"

echo "== values"
python3 -I - "$E/Res" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
t1 = text.split("TEST01", 1)[1].split("TEST02", 1)[0]
m = re.search(r"^\s+1\.0000\s+\S+\s+(\S+)\s*$", t1, re.M)
if not m:
    print("no x=1.0 row in TEST01")
    sys.exit(0)
print(f"VALUE W_WEW_A_AT_1 {m.group(1)}")
PY
