#!/usr/bin/env bash
# Rebuilds the rerun verdict for macleod1998-fermi-dirac-779 (basis: original).
# Fetch (the only network step, inside the sandbox): netlib TOMS 779.gz (sha256 checked), micromamba, and
# gfortran from conda-forge into the sandbox scratch (/work/fortran). Everything else runs through tools/sandbox.sh.
# The archive is a shell archive: Drivers/Dp/{fdtestdp.f,RES}, Drivers/Sp/{fdtestsp.f,RES}, Src/Dp/src.f, Src/Sp/src.f.
# The archive has no Makefile and no build command. The double-precision driver is built from the shipped sources as
# they are (no source edit, no conversion needed: Src/Dp/src.f is already double precision).
# G1 original attempt: fdtestdp.f + Src/Dp/src.f compiled with plain gfortran (-O2 for pass 1). It compiles and runs
# without any change: evidence/original-attempt.log.
# Claim: the 8 registered reference points (row 8 of each half-range block, the 8th argument listed in the driver's DATA)
# against the COMP. VALUE column printed by the driver.
# Second pass (G3): a clean directory and a -O0 rebuild. Both passes are compared with the shipped RES on columns 1-3.
set -uo pipefail
ID=macleod1998-fermi-dirac-779
URL=https://netlib.org/toms/779.gz
SHA=da2c0d3ea7b69028124524bcc886e8335bf288c2f20107c556a05d19b491da0e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
mkdir -p "$root/reports/$ID/evidence/reference"
cd "$root"
exec > >(tee "$LOG") 2>&1
G=x86_64-conda-linux-gnu-gfortran
D=/work/src/Drivers/Dp
S=/work/src/Src/Dp

echo "== fetch: 779.gz (sha256 checked), unshar, micromamba, gfortran (conda-forge) into the sandbox scratch"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; cd /work; curl -fsSL -o 779.gz '$URL'; echo '$SHA  779.gz' | sha256sum -c -; gunzip -kf 779.gz; \
  mkdir -p /work/src && cp /work/779 /work/src/779.shar && cd /work/src && sh 779.shar 2>/dev/null; \
  curl -fsSL -o mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p bin; tar -xjf mm.tar.bz2 -C bin --strip-components=1 bin/micromamba; \
  MAMBA_ROOT_PREFIX=/work/mamba ./bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- test -f $D/fdtestdp.f || { echo "UNPACK-FAILED"; exit 1; }

echo "== shipped reference output (RES), copied into the report"
tools/sandbox.sh "$ID" -- cat $D/RES > "$root/reports/$ID/evidence/reference/RES" || { echo "REF-FAILED"; exit 1; }
grep -q "TESTING FDM0P5" "$root/reports/$ID/evidence/reference/RES" || { echo "REF-CHECK-FAILED"; exit 1; }

# G1: the shipped sources, as they are. The first attempt's log is kept and never overwritten.
ORIG="$root/reports/$ID/evidence/original-attempt.log"
echo "== build (G1 attempt, shipped sources, plain gfortran -O2; the log is kept once and never overwritten)"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/fortran/bin:\$PATH; cd $D && $G -O2 -o fdtest fdtestdp.f ../../Src/Dp/src.f 2>&1; echo compile_exit=\$?" > /tmp/macleod-build-$$.log 2>&1
if [ ! -s "$ORIG" ]; then cp /tmp/macleod-build-$$.log "$ORIG"; fi
tail -2 /tmp/macleod-build-$$.log
rm -f /tmp/macleod-build-$$.log

echo "== run 1: the driver built above, run from its directory"
tools/sandbox.sh "$ID" -- sh -c "cd $D && ./fdtest > /work/run1.txt 2>/work/err1.txt; echo run1_exit=\$?"
tools/sandbox.sh "$ID" -- cat /work/run1.txt > "$root/reports/$ID/evidence/run1-output.txt"

echo "== run 2: clean directory, -O0 rebuild"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && mkdir /work/pass2 && cp $D/fdtestdp.f $S/src.f /work/pass2/ && cd /work/pass2 && export PATH=/work/fortran/bin:\$PATH && $G -O0 -o fdtest fdtestdp.f src.f && ./fdtest > /work/run2.txt; echo run2_exit=\$?"
tools/sandbox.sh "$ID" -- cat /work/run2.txt > "$root/reports/$ID/evidence/run2-output.txt"

echo "== compare each pass to the shipped RES on columns 1-3 (X, EXACT, COMP); column 4 is rounding noise"
cd "$root/reports/$ID/evidence"
for p in 1 2; do
  if cmp -s <(cut -c1-52 run$p-output.txt) <(cut -c1-52 reference/RES); then echo "pass $p: columns 1-3 identical to shipped RES"; else echo "pass $p: columns 1-3 differ from shipped RES"; fi
done
cd "$root"

echo "== VALUE lines: row 8 of the M block (x=-4 for FDM0P5, FDP0P5, FDP1P5, FDP2P5 use the P block) and row 23 (x=3, P block)"
awk '/TESTING/{f=$2; n=0; next} /^ +-?[0-9.]+ +[0-9.]+D/{n++; if(n==8||n==23) print f, n, $1, $3}' "$root/reports/$ID/evidence/run1-output.txt" > "$root/reports/$ID/evidence/values.txt"
cat "$root/reports/$ID/evidence/values.txt"
# The printed COMP. VALUE is Fortran D notation (0.1808192D-01): convert it to a plain number for the ledger.
dnum() { echo "$1" | sed 's/D/e/'; }
echo "VALUE FDM0P5(-4) $(dnum "$(awk -v f=FDM0P5 '$1==f && $2==8 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDM0P5(3) $(dnum "$(awk -v f=FDM0P5 '$1==f && $2==23 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDP0P5(-4) $(dnum "$(awk -v f=FDP0P5 '$1==f && $2==8 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDP0P5(3) $(dnum "$(awk -v f=FDP0P5 '$1==f && $2==23 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDP1P5(-4) $(dnum "$(awk -v f=FDP1P5 '$1==f && $2==8 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDP1P5(3) $(dnum "$(awk -v f=FDP1P5 '$1==f && $2==23 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDP2P5(-4) $(dnum "$(awk -v f=FDP2P5 '$1==f && $2==8 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
echo "VALUE FDP2P5(3) $(dnum "$(awk -v f=FDP2P5 '$1==f && $2==23 {print $4}' "$root/reports/$ID/evidence/values.txt")")"
