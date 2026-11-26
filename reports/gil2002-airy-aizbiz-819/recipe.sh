#!/usr/bin/env bash
# Rebuilds the rerun verdict for gil2002-airy-aizbiz-819 (TOMS 819, AIZ/BIZ complex Airy functions, Fortran 77).
# Fetch (the only network step, inside the sandbox): netlib TOMS 819.gz (sha256 checked), unpacked as a shell archive
# inside the sandbox scratch; micromamba and gfortran from conda-forge into the sandbox scratch. Everything else runs
# through tools/sandbox.sh.
# Original attempt (G1): the authors' Fortran sources compiled exactly as shipped (Fortran77/Dp/Drivers/driver.f with
# Fortran77/Dp/Src/src.f and Fortran77/Dp/Src/port.f), no edits, flags -O2 only. The archive has no Makefile, so this is
# the authors' documented source set. Log kept once in evidence/original-attempt.log.
# Claim: the four maxima WRTEST prints for scaled functions (IFAC=2), one per res1..res4 file, each within 1e-13 absolute
# of the shipped maximum. The shipped res1..res4 are the reference (copied to evidence/reference unedited).
# The driver writes res1..res4 into its working directory, not to stdout.
# Two passes (G3): run 1 is the original binary in its build directory; run 2 is the same binary in a clean directory.
set -uo pipefail
ID=gil2002-airy-aizbiz-819
URL=https://netlib.org/toms/819.gz
SHA=26af2205d9c0d935ca5612d0ec4696d0045e5e6b09429b1d553b898ca0d3cb92
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
D=/work/pre/Fortran77/Dp

echo "== fetch: 819.gz (sha256 checked), unpacked in the sandbox scratch; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; rm -rf pre; mkdir pre; curl -fsSL -o 819.gz '$URL'; echo '$SHA  819.gz' | sha256sum -c -; gunzip -kf 819.gz; \
  sed -n '/^#! \/bin\/sh/,\$p' 819 > pre/819.sh; cd pre && sh 819.sh >/dev/null 2>&1; test -f Fortran77/Dp/Drivers/driver.f; \
  test -x /work/fortran/bin/x86_64-conda-linux-gnu-gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: Drivers/res1..res4, copied unedited"
for r in res1 res2 res3 res4; do
  tools/sandbox.sh "$ID" -- cat "$D/Drivers/$r" > "$E/reference/$r" || { echo "REF-FAILED $r"; exit 1; }
  tail -1 "$E/reference/$r"
done

# G1 original attempt: the authors' sources, as shipped. The first log is kept and never overwritten; the build is
# always redone, because the sandbox scratch (/work/g1, the binary the runs need) does not persist between recipe runs.
ORIG="$E/original-attempt.log"
[ -s "$ORIG" ] && ORIG="$E/original-attempt-rebuild.log"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/g1 && cp -r $D /work/g1 && mkdir /work/g1/run && cd /work/g1 && $G -O2 -o run/wrtest Drivers/driver.f Src/src.f Src/port.f 2>&1; echo compile_exit=\$?" > "$ORIG" 2>&1
tail -3 "$ORIG"

# Runs, twice (G3): run 1 executes the original binary in its build directory; run 2 copies it to a clean directory.
for pass in run1 run2; do
  echo "== $pass: the original binary, $( [ $pass = run1 ] && echo in the build directory || echo in a clean directory )"
  if [ $pass = run1 ]; then
    tools/sandbox.sh "$ID" -- sh -c "cd /work/g1/run && timeout 1500 ./wrtest > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?; for r in res1 res2 res3 res4; do cp \$r /work/$pass-\$r; done; cp stdout.txt /work/$pass-stdout.txt"
  else
    tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp /work/g1/run/wrtest /work/$pass/ && cd /work/$pass && timeout 1500 ./wrtest > stdout.txt 2> stderr.txt; echo ${pass}_exit=\$?; for r in res1 res2 res3 res4; do cp \$r /work/$pass-\$r; done; cp stdout.txt /work/$pass-stdout.txt"
  fi
  for r in res1 res2 res3 res4; do
    tools/sandbox.sh "$ID" -- cat /work/$pass-$r > "$E/$pass-$r.txt" || echo "$pass $r: no output"
    grep -m1 "MAXIMUM VALUE OF THE WRONSKIAN CHECK" "$E/$pass-$r.txt" | awk '{print $NF}' > "$E/$pass-$r-value.txt"
  done
done

echo "== claimed values per pass (res1..res4)"
for r in res1 res2 res3 res4; do paste "$E/run1-$r-value.txt" "$E/run2-$r-value.txt"; done
echo "VALUE res1 CHECK1 maximum (shipped) $(cat "$E/run2-res1-value.txt")"
echo "VALUE res2 CHECK2 maximum (shipped) $(cat "$E/run2-res2-value.txt")"
echo "VALUE res3 CHECK3 maximum (shipped) $(cat "$E/run2-res3-value.txt")"
echo "VALUE res4 CHECK4 maximum (shipped) $(cat "$E/run2-res4-value.txt")"
