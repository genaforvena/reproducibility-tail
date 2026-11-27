#!/usr/bin/env bash
# Rebuilds the rerun record for davis2010-klu-907 (ACM TOMS Algorithm 907, KLU sparse direct solver, C, Davis and
# Natarajan 2010). Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes
# sources (tools/verify_sources.py), copies text output and writes the report.
#
# Fetch (network, inside the sandbox): netlib TOMS 907.zip, sha256 pinned below (first observed 2026-11-27; the
# queue entry does not register a hash), unpacked to /work/pre (the tree is /work/pre/907). The same fetch step
# installs SuiteSparse 7.x (conda-forge, via micromamba) into /work/env, because the archive's kludemo.c reads the
# matrix with CHOLMOD and the archive ships no CHOLMOD. The archive's KLU library is still built from its own source.
#
# G1 original attempt: the authors' Makefile in a copy (/work/orig-run): `make kludemo` in Demo. It stops because
# kludemo.c includes cholmod.h and the archive has no CHOLMOD (../../CHOLMOD/Include is absent). The log is kept.
#
# Build-only route: no file in the archive tree is edited or added. The authors' Makefile builds the archive's
# KLU library (Lib) and the klu_simple demo. kludemo is compiled with the same compiler, flags and archive libraries
# as the Demo Makefile writes them, with the CHOLMOD include and library pointed at /work/env (the only change: the
# CHOLMOD headers and library are from a newer SuiteSparse, not the 2009 CHOLMOD). The manifests (pre, mid, post)
# show that no archive source file changed.
#
# Run: the authors' default driver is `./kludemo < ../Matrix/<name>.mtx`, one per matrix (the Demo Makefile's all
# target). The claim is the condest of w156.mtx. Five other matrices are run too, as a cross-check against the
# shipped kludemo.out: a read-path or build difference would show there first.
#
# Claim: condest 1.79787e+09 for ../Matrix/w156.mtx in the shipped Matlab/KLU/Demo/kludemo.out. Tolerance abs 5e4,
# registered and not edited.
set -uo pipefail
ID=davis2010-klu-907
URL=https://netlib.org/toms/907.zip
SHA=d01a10366cc289ea803b119ea5f62dfa548867fe12460f9e2c593bab6489dc31
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

K=/work/pre/907/Matlab/KLU
DEMO=$K/Demo
CHO=/work/env

echo "== fetch: 907.zip (sha256 checked), unpacked to /work/pre; SuiteSparse (CHOLMOD) into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre /work/bin && cd /work/dl && curl -fsSL -o 907.zip '$URL'; \
  echo \"sha256 \$(sha256sum 907.zip | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  907.zip' | sha256sum -c -; \
  unzip -q 907.zip -d /work/pre; \
  test -x /work/env/lib/libcholmod.so || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge suitesparse; }; \
  /work/bin/micromamba list -p /work/env | grep -i -E 'suitesparse|blas' > /work/env-pins.txt 2>/dev/null || true; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -3 "$E/fetch.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/env-pins.txt" > "$E/env-pins.txt" 2>&1 || true
cat "$E/env-pins.txt"

echo "== manifest pre (right after unpack, before any build step)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the authors' Makefile in a copy, target kludemo (needs CHOLMOD, absent from the archive)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/907 /work/orig-run/ && \
  cd /work/orig-run/907/Matlab/KLU/Demo && make kludemo > /work/orig-kludemo.log 2>&1; echo kludemo_make_exit=\$?; tail -6 /work/orig-kludemo.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (immediately before the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the authors' Makefile for KLU library and klu_simple, then kludemo with the Demo Makefile's compile line (CHOLMOD from /work/env)"
tools/sandbox.sh "$ID" -- sh -c "cd $DEMO && make -f Makefile klu_simple > /work/build-klu-simple.log 2>&1; echo klu_simple_exit=\$?"
tools/sandbox.sh "$ID" -- sh -c "cd $DEMO && cc -O3 -fexceptions -I../../UFconfig -I../../AMD/Include -I../../COLAMD/Include -I../../BTF/Include -I../Include -I$CHO/include/suitesparse kludemo.c -o kludemo ../Lib/libklu.a ../../BTF/Lib/libbtf.a ../../AMD/Lib/libamd.a ../../COLAMD/Lib/libcolamd.a -L$CHO/lib -lcholmod -lm > /work/build-kludemo.log 2>&1; echo kludemo_exit=\$?"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== run: the authors' driver on w156.mtx (claim) and five other matrices (cross-check), CHOLMOD and SuiteSparse on the loader path"
tools/sandbox.sh "$ID" -- sh -c "cd $DEMO && for m in w156 1c arrowc arrow impcol_a ctina; do echo \"./kludemo < ../Matrix/\$m.mtx\" > /work/run-\$m.txt; LD_LIBRARY_PATH=$CHO/lib ./kludemo < ../Matrix/\$m.mtx >> /work/run-\$m.txt 2>&1; echo \"\$m exit=\$?\"; done; cat /work/run-w156.txt" \
  > "$E/kludemo-run.log" 2>&1
cat "$E/kludemo-run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/907/Matlab/KLU/Demo/kludemo.out" > "$E/kludemo-shipped.out"
tools/sandbox.sh "$ID" -- sh -c "cd /work && for m in w156 1c arrowc arrow impcol_a ctina; do cat run-\$m.txt; done" > "$E/kludemo-run.out"
sha256sum "$E/kludemo-shipped.out" | cut -d' ' -f1 > "$E/kludemo-shipped.sha256"
cat "$E/kludemo-shipped.sha256"

echo "== cross-check: the condest and residual lines of each matrix against the shipped kludemo.out"
python3 -I - "$E/kludemo-shipped.out" "$E/kludemo-run.out" "$E/cross-check.txt" <<'PY'
import re, sys
def blocks(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    out = {}
    for m in re.finditer(r"\./kludemo < \.\./Matrix/(\w+)\.mtx\n(.*?)(?=\n\./|\Z)", text, re.S):
        body = m.group(2)
        n = re.search(r"n (\d+) nnz\(A\) (\d+) nnz\(L\+U\+F\) (\d+) resid (\S+)", body)
        c = re.search(r"condest (\S+)", body)
        if n and c:
            out[m.group(1)] = (n.groups(), c.group(1))
    return out
shipped = blocks(sys.argv[1])
run = blocks(sys.argv[2])
with open(sys.argv[3], "w") as f:
    for name in ["w156", "1c", "arrowc", "arrow", "impcol_a", "ctina"]:
        s = shipped.get(name); r = run.get(name)
        line = f"{name}: shipped {s} run {r} same_structure_and_condest={s is not None and r is not None and s[0][:3]==r[0][:3] and s[1]==r[1]}"
        print(line); f.write(line + "\n")
PY

echo "== values"
python3 -I - "$E/kludemo-run.out" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
blocks = re.split(r"\n(?=KLU: )", text)
# The w156 block is the one with n 156.
for b in blocks:
    if re.search(r"^n 156 ", b, re.M):
        m = re.search(r"condest (\S+)", b)
        if m:
            print(f"VALUE KLU_CONDEST_W156 {m.group(1)}")
            sys.exit(0)
print("no n 156 condest found")
PY
