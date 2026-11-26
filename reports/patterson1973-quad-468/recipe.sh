#!/usr/bin/env bash
# Rebuilds the rerun verdict for patterson1973-quad-468 (basis: patched).
# Fetch (the only network step, inside the sandbox): netlib TOMS 468.gz (sha256 checked), micromamba, and
# gfortran from conda-forge into the sandbox scratch (/work/fortran). Everything else runs through tools/sandbox.sh.
# The archive 468.gz is a shell archive (shar) of four files: Fortran/Sp/Drivers/{Makefile,driver.f,res} and Fortran/Sp/Src/src.f.
# Original attempt (G1): the shipped Makefile, as documented, with its default compiler (f77). It stops because f77 is absent
# and, once a compiler is given, because src.f is not beside driver.f. Log kept in evidence/original-attempt.log (never overwritten).
# Patch (the basis): the compiler is passed as the Makefile's F77 variable (gfortran from conda-forge) and src.f is copied
# beside driver.f. No source is changed.
# Claim: the TEST01 QUAD results for f07, f08, f12, f13 printed by ./driver, against the registered paper values and tolerances.
# The shipped reference output (res) is kept in evidence/reference/res and is reproduced byte for byte by the patched build.
set -uo pipefail
ID=patterson1973-quad-468
URL=https://netlib.org/toms/468.gz
SHA=1891044f1acedad241f46b6e1a16b0803ab3a2c54b37fbab333665a755d82319
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
mkdir -p "$root/reports/$ID/evidence/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
D=/work/src/Fortran/Sp/Drivers
G=x86_64-conda-linux-gnu-gfortran

echo "== fetch: 468.gz (sha256 checked), micromamba, gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 468.gz '$URL'; echo '$SHA  468.gz' | sha256sum -c -; gunzip -kf 468.gz; \
  curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p bin; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack the shar (the archive's own shell script, run in the sandbox)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/src && mkdir -p /work/src && cp /work/468 /work/src/468.shar && cd /work/src && sh 468.shar 2>/dev/null; test -f $D/driver.f" || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped reference output (res), copied into the report and hash-checked"
tools/sandbox.sh "$ID" -- cat /work/src/Fortran/Sp/Drivers/res > "$root/reports/$ID/evidence/reference/res" || { echo "REF-FAILED"; exit 1; }
grep -q "TEST01" "$root/reports/$ID/evidence/reference/res" || { echo "REF-CHECK-FAILED"; exit 1; }

# G1: the shipped Makefile as documented, default compiler. The first attempt's log is kept and never overwritten.
ORIG="$root/reports/$ID/evidence/original-attempt.log"
if [ ! -s "$ORIG" ]; then
  echo "== G1 original attempt: make, as shipped"
  tools/sandbox.sh "$ID" -- sh -c "cd $D && make 2>&1; echo exit=\$?" > "$ORIG" 2>&1
  tail -3 "$ORIG"
fi

echo "== patched build: F77 set to conda-forge gfortran; src.f copied beside driver.f (no source edits)"
tools/sandbox.sh "$ID" -- sh -c "cd $D && export PATH=/work/fortran/bin:\$PATH && cp ../Src/src.f . && make F77=$G F77OPTS='-std=legacy -w' > /work/build-patched.log 2>&1; echo build_exit=\$?; ls -l driver" || { echo "BUILD-FAILED"; exit 1; }

# G3: two passes. Pass 1 is the Makefile's own run target (./driver > Res); pass 2 is a clean directory at -O0.
echo "== run 1: make's own target (./driver > Res)"
tools/sandbox.sh "$ID" -- sh -c "cd $D && ./driver > /work/Res1 2>/work/err1; echo run_exit=\$?; cp /work/Res1 $D/Res"
cp "$W/Res1" "$root/reports/$ID/evidence/run1-output.txt"
echo "== run 2: clean directory, -O0 rebuild"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && mkdir /work/pass2 && cp /work/src/Fortran/Sp/Src/src.f /work/src/Fortran/Sp/Drivers/driver.f /work/pass2/ && cd /work/pass2 && export PATH=/work/fortran/bin:\$PATH && $G -O0 -std=legacy -w -o driver driver.f src.f && ./driver > /work/pass2/Res2 && cp /work/pass2/Res2 /work/Res2"
cp "$W/Res2" "$root/reports/$ID/evidence/run2-output.txt"

echo "== compare each pass to the shipped res (byte equality)"
for p in 1 2; do
  if cmp -s "$root/reports/$ID/evidence/reference/res" "$root/reports/$ID/evidence/run$p-output.txt"; then echo "pass $p identical to shipped res"; else echo "pass $p differs from shipped res"; fi
done

echo "== VALUE lines: TEST01 RESULT(K) for the registered integrands (rows 7, 8, 12, 13 of TEST01) and their ICHECK"
for p in 1 2; do
  awk -v pass="$p" '
    /^TEST01/ {in01=1; next}
    /^TEST02/ {in01=0}
    in01 && /^ +-?[0-9.]+ +-?[0-9.]+ +[01] +[0-9]+ +[0-9]+ +/ {
      k++;
      if (k==7)  printf "ICHECK_pass%s f07 %s\n", pass, $3;
      if (k==8)  printf "ICHECK_pass%s f08 %s\n", pass, $3;
      if (k==12) printf "ICHECK_pass%s f12 %s\n", pass, $3;
      if (k==13) printf "ICHECK_pass%s f13 %s\n", pass, $3;
      if (k==7)  printf "RES_pass%s f07 %s\n", pass, $6;
      if (k==8)  printf "RES_pass%s f08 %s\n", pass, $6;
      if (k==12) printf "RES_pass%s f12 %s\n", pass, $6;
      if (k==13) printf "RES_pass%s f13 %s\n", pass, $6;
    }' "$root/reports/$ID/evidence/run$p-output.txt"
done | tee "$root/reports/$ID/evidence/values.txt"

# VALUE lines use the names in result.json. Pass 1 is the value of record; pass 2 is in values.txt.
val() { grep "^RES_pass$1 $2 " "$root/reports/$ID/evidence/values.txt" | awk '{print $3}'; }
echo "VALUE QUAD integral of f07 on [0, 1] $(val 1 f07)"
echo "VALUE QUAD integral of f08 on [0.1, 1] $(val 1 f08)"
echo "VALUE QUAD integral of f12 on [0, 1] $(val 1 f12)"
echo "VALUE QUAD integral of f13 on [0, 1] $(val 1 f13)"
