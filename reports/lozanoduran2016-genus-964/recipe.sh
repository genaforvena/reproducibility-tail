#!/usr/bin/env bash
# Rebuilds and reruns the genus program (TOMS Algorithm 964, Lozano-Duran & Borrell 2016, Fortran 90, serial version)
# from the netlib archive. All execution goes through tools/sandbox.sh; the host only hashes and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 964.zip (sha256 checked against the queue entry), unzipped;
# gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Original attempt (G1): the authors' Makefile in Fortran90/Src/fortran_serial sets F90 = nagfor (the last assignment
# wins; ifort is the line before it). Run as documented, `make genus` finds neither compiler in the sandbox. That attempt
# is kept in evidence/original-attempt.log.
#
# Patch (build-only): nothing in the source tree is edited. The only change is on the make command line:
# F90=gfortran overrides the Makefile's compiler variable, so the authors' own rules and flags (-c -O3, -O3 link) build
# the program unedited. manifest.pre, mid and post prove that no source file or Makefile is changed.
#
# Run: ./genus ../../data/random.128.dat (the Doc/documentation.tex example). It prints Faces, Edges, Vertices and Genus.
# Claim (queue/lozanoduran2016-genus-964.json): genus of the Random2 case, paper Table III, 87325, absolute tolerance 0.
set -uo pipefail
ID=lozanoduran2016-genus-964
URL=https://netlib.org/toms/964.zip
SHA=eb7b9a946d9b87a49972ed1740a0a38d9669ae281efd645240abe1c7c5cec496
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/manifests"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 964.zip (sha256 checked), unzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/964.zip '$URL'; echo '$SHA  /work/964.zip' | sha256sum -c -; \
  python3 -I -c 'import zipfile; zipfile.ZipFile(\"/work/964.zip\").extractall(\"/work/pre/964\")'; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack: the archive is already extracted by the fetch step; the source tree is $SCRATCH/pre/964/964"
SRC=Fortran90/Src/fortran_serial
MAN="$E/manifests"
python3 tools/verify_sources.py manifest "$SCRATCH/pre/964/964" > "$MAN/manifest.pre"

echo "== original attempt (G1): make genus as documented, no nagfor or ifort in the sandbox"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/964/964/$SRC && env PATH=/usr/bin:/bin make genus; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/964/964/$SRC && rm -f *.o *.mod genus"

echo "== patch (build-only): compiler named on the make command line; no file in the tree is edited"
python3 tools/verify_sources.py manifest "$SCRATCH/pre/964/964" > "$MAN/manifest.mid"

echo "== build the authors' makefile target with gfortran (sandbox; no editing in this step)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/964/964/$SRC && env PATH=/work/env/bin:/usr/bin:/bin make genus F90=gfortran; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/pre/964/964" > "$MAN/manifest.post"

echo "== record the build-only proof (host, text only)"
python3 tools/verify_sources.py record --repo . --id "$ID" \
  --pre "$MAN/manifest.pre" --mid "$MAN/manifest.mid" --post "$MAN/manifest.post" \
  --command 'make genus F90=gfortran'

echo "== run the program on the shipped dataset (sandbox, no network)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/964/964/$SRC && ./genus ../../data/random.128.dat; echo run_exit=\$?" > "$E/run.txt" 2>&1
cat "$E/run.txt"

echo "== values (host, text only)"
python3 -I - "$E/run.txt" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
m = re.search(r"Genus:\s+(-?\d+)", t)
assert m, "no Genus line in the run output"
print(f"VALUE genus, Random2 {int(m.group(1))}")
PY
echo "== done; scratch kept at $SCRATCH"
