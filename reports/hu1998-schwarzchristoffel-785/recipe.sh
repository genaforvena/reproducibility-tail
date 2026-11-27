#!/usr/bin/env bash
# Rebuilds and runs the Schwarz-Christoffel driver (DSCPACK, ACM TOMS Algorithm 785, Hu 1998, Fortran 77) from the
# archive. All execution goes through tools/sandbox.sh; the host only hashes and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 785.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/785.txt; gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Unpack and compile (G1 original attempt): the archive's shell archive (cut from its '#! /bin/sh' line) is run with
# sh into /work/orig/tree. The authors' driver.f and src.f are compiled unedited with gfortran -std=legacy (no build
# file ships with this archive).
#
# Run: the driver reads all answers from stdin. The archive's own data file is that keyboard stream: per problem the
# answers are IPOLY, NPTQ, ISOLV, ISPRT, INV (then points if INV=1), ITRY. Feeding it reproduces the shipped RES
# transcript, which prints the examples in order (block 1 = problem 1 ... block 7 = problem 7).
#
# Claim (as registered, scout 73030b9): "ex1" U and C (real and imaginary parts, block 1 of the shipped transcript),
# absolute tolerance 1e-7.
set -uo pipefail
ID=hu1998-schwarzchristoffel-785
URL=https://netlib.org/toms/785.gz
SHA=55965a41f823fb161c5df7b59933092f3879b7a8b57636859511be5c3f4f9175
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 785.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/785.gz '$URL'; echo '$SHA  /work/785.gz' | sha256sum -c -; gzip -dc /work/785.gz > /work/pre/785.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack the authors' shell archive (sandbox; no compile yet)"
tools/sandbox.sh "$ID" -- sh -c "set -e; rm -rf /work/orig && mkdir -p /work/orig/tree && cd /work/orig/tree && \
  sed -n '/^#! \/bin\/sh/,\$p' /work/pre/785.txt > /work/orig/unpack.sh && sh /work/orig/unpack.sh; echo unpack_exit=\$?" > "$E/unpack.log" 2>&1
tail -2 "$E/unpack.log"

# Build-only proof (docs/method.md): manifests of the authors' source tree, before and after the build. Nothing is
# edited between pre and mid; the build is the authors' sources compiled with -std=legacy (the archive ships no build file).
MAN="$E/manifests"; mkdir -p "$MAN"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.pre"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.mid"

echo "== compile the unedited driver and src (build; G1 original attempt)"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/env/bin:\$PATH; cd /work/orig/tree/Fortran77/Drivers/Dp && \
  gfortran -std=legacy -o /work/orig/driver driver.f /work/orig/tree/Fortran77/Src/Dp/src.f; echo compile_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log" | tail -5
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.post"

echo "== run the whole session: the archive's data file is the keyboard stream"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig && ./driver < /work/orig/tree/Fortran77/Drivers/Dp/data > session.txt; echo run_exit=\$?; cat session.txt" > "$E/run-session.txt" 2>&1
grep -E "run_exit|runtime error" "$E/run-session.txt" | head -3
cp "$SCRATCH/orig/tree/Fortran77/Drivers/Dp/RES" "$E/shipped-RES.txt" 2>/dev/null

echo "== parse U and C of every example block, in order (host, text only)"
python3 -I - "$E" "$root/queue/$ID.json" <<'PY' | tee "$E/values.txt"
import json, pathlib, re, sys
e = pathlib.Path(sys.argv[1])
claim = json.load(open(sys.argv[2]))["claim"]["values"]
def blocks(name):
    t = (e / name).read_text()
    found = re.findall(r"U=\s*(-?[0-9.]+)\s*\n\s*C=\(\s*(-?[0-9.]+),\s*(-?[0-9.]+)\)", t)
    return [tuple(float(x) for x in b) for b in found]
ours = blocks("run-session.txt")
shipped = blocks("shipped-RES.txt")
print("blocks in our session run:", len(ours), "; in shipped RES:", len(shipped))
for i, (o, s) in enumerate(zip(ours, shipped), 1):
    same = all(abs(a - b) <= 5e-13 for a, b in zip(o, s))
    print(f"block {i}: ours U={o[0]} C=({o[1]},{o[2]}); shipped U={s[0]} C=({s[1]},{s[2]}); equal: {same}")
print("registered claim (example 1):", [c["paper"] for c in claim])
# G5 contract: one VALUE line per claimed value, from block 1 (the registered example 1).
for c, v in zip(claim, ours[0]):
    print(f"VALUE {c['name']} {v}")
hit = [i for i, o in enumerate(ours, 1) if all(abs(a - c["paper"]) <= c["tol_abs"] for a, c in zip(o, claim))]
print("our blocks within the registered tolerance of the registered claim:", hit)
PY
echo "== done; scratch kept at $SCRATCH"
