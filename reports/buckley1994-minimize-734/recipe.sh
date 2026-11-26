#!/usr/bin/env bash
# Rebuilds and reruns the rerun verdict for buckley1994-minimize-734 (TOMS 734, Buckley, Rosenbrock minimiser, Fortran 90, single precision).
# Fetch (the only network step): netlib TOMS 734.gz (sha256 checked). The archive is a shell archive whose
# unshar fails under this host's bash on src.f90 (a backtick in an unquoted heredoc), so the Src/Sp/src.f90 member is
# extracted by line range instead (patch step, see result.md). Everything else runs through tools/sandbox.sh.
# Patches (basis patched, not build-only): src.f90 extracted by sed; driver2.f90 line 1 'C--**--' fixed-form ID line
# changed to '!'; i1mach.f90 supplied for the PORT routine the driver calls (impl/i1mach.f90, returns 6 for unit 2).
# Claim: the shipped driver2 run (res2): least function value 0.20053597E-08, 59 evaluations, 36 iterations.
# Two clean-directory runs of the same binary (G3).
set -uo pipefail
ID=buckley1994-minimize-734
URL=https://netlib.org/toms/734.gz
SHA=bf1682045031a42610373d26367ccab037dcc2aada64e3f9ab033311a7d794b0
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 734.gz (sha256 checked), unpacked in the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "rm -rf /work/pre /work/build /work/run1 /work/run2 && cd /work && curl -fsSL -o 734.gz '$URL' && echo '$SHA  734.gz' | sha256sum -c - && gunzip -kf 734.gz && mkdir pre && cd pre && bash ../734 > /dev/null 2>&1; test -f Fortran90/Drivers/Sp/driver2.f90 && test -f Fortran90/Drivers/Sp/res2" || { echo "FETCH-FAILED"; exit 1; }

# G2 build-only proof, manifest 1 of 3: the unpacked tree, before any patch.
python3 -I tools/verify_sources.py manifest "$W/pre/Fortran90" > "$W/manifest.pre" || { echo "MANIFEST-PRE-FAILED"; exit 1; }
echo "manifest.pre: $(wc -l < "$W/manifest.pre") source files"
tools/sandbox.sh "$ID" -- sh -c "cat /work/pre/Fortran90/Drivers/Sp/res2" > "$E/reference/res2" || { echo "REF-FAILED"; exit 1; }
cp "$here/impl/i1mach.f90" "$W/i1mach.f90"

echo "== patch step (in the build copy): src.f90 by line range, driver2 line 1 fixed, i1mach supplied"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/pre/Fortran90 /work/build && sed -n '2132,10106p' /work/734 > /work/build/Src/Sp/src.f90 && sed '1s/^C/!/' /work/pre/Fortran90/Drivers/Sp/driver2.f90 > /work/build/Drivers/Sp/driver2.f90 && cp /work/i1mach.f90 /work/build/Src/Sp/i1mach.f90" || { echo "PATCH-FAILED"; exit 1; }

# G2 build-only proof, manifest 2 of 3: the build tree, immediately before the build commands.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.mid" || { echo "MANIFEST-MID-FAILED"; exit 1; }
echo "== build: gfortran -O2, authors' module order (src.f90, i1mach, driver2)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/Src/Sp && $G -O2 -c src.f90 -o src.o && $G -O2 -c i1mach.f90 -o i1mach.o && $G -O2 -I. -c ../../Drivers/Sp/driver2.f90 -o driver2.o && $G -O2 -o drv src.o i1mach.o driver2.o; echo build_exit=\$?" | tee "$E/build.log"

# G2 build-only proof, manifest 3 of 3: the build tree after the build.
python3 -I tools/verify_sources.py manifest "$W/build" > "$W/manifest.post" || { echo "MANIFEST-POST-FAILED"; exit 1; }
python3 -I tools/verify_sources.py record --repo "$root" --id "$ID" --pre "$W/manifest.pre" --mid "$W/manifest.mid" --post "$W/manifest.post" \
  --command "cd Src/Sp && $G -O2 -c src.f90 -o src.o" \
  --command "cd Src/Sp && $G -O2 -c i1mach.f90 -o i1mach.o" \
  --command "cd Src/Sp && $G -O2 -I. -c ../../Drivers/Sp/driver2.f90 -o driver2.o" \
  --command "cd Src/Sp && $G -O2 -o drv src.o i1mach.o driver2.o" \
  && echo "BUILD-ONLY: exit 0" || echo "NOT BUILD-ONLY: the source edits are a patch, the full G2 check applies (see the record)"

# Runs, twice (G3): each pass in its own clean directory, the binary copied from the build tree.
for pass in run1 run2; do
  echo "== $pass: clean directory, ./drv"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/build/Src/Sp/drv /work/$pass/ && cd /work/$pass && ./drv > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?"
  cp "$W/$pass/stdout.txt" "$E/$pass-stdout.txt"
  grep -E 'Least function value|Function evaluation count|Iteration count' "$E/$pass-stdout.txt"
done

python3 -I -c '
import re, sys
text = open(sys.argv[1]).read()
least = re.search(r"Least function value:\s*([0-9.E+-]+)\.", text).group(1)
fevals = re.search(r"Function evaluation count:\s*(\d+)\.", text).group(1)
its = re.search(r"Iteration count:\s*(\d+)\.", text).group(1)
print("VALUE function evaluation count (FEvals) " + fevals)
print("VALUE iteration count (it) " + its)
print("VALUE least function value " + least)
' "$E/run2-stdout.txt"
echo "== shipped res2 (the claim): the three lines"
grep -E 'Least function value|Function evaluation count|Iteration count' "$E/reference/res2"
