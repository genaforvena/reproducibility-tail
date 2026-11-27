#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 903 claim (Celledoni and Zanna 2010, FRB, Fortran 77): the first component of the
# output angular momentum after one exact step (Np = 0, h = 0.1) of the free rigid body, which is line 14 of the
# shipped Fortran77/Drivers/out_example0.dat. Claim -0.7088447919224319, absolute tolerance 1e-10, registered and not edited.
# Everything that runs the archive's code goes through tools/sandbox.sh.
# The host only hashes sources (tools/verify_sources.py), copies text output and prints the VALUE line.
#
# Fetch (network, inside the sandbox): netlib CALGO 903.zip, sha256 pinned in the queue entry, unzipped to /work/pre.
# The same step installs gfortran 16.2.0 (conda-forge, micromamba) into /work/env and checks that it writes an object.
#
# G1 original attempt: the archive Makefile (Doc/Makefile), unchanged, in a copy: `make` with its default FC =
# /opt/NAGWare/bin/f95 (NAG, absent here) and sources expected beside Doc/ (they are in Fortran77/Src and Drivers).
#
# Build-only route: the Makefile's only rule for the driver is `$(FC) $(FOPTS) -o driver_example0 driver_example0.f frb_step.f`.
# make's VPATH does not rewrite that command text, so the recipe runs the same command with FC = the sandbox gfortran
# (FOPTS = -O, not the NAG flags) and the two sources' absolute paths in Fortran77/Drivers and Fortran77/Src. No archive
# file is edited or linked; the binary is written to /work/build (outside the archive).
# Pass 1 uses -O; pass 2 uses -O2 in a second build directory, to check the value does not depend on the optimisation level.
#
# Value: the driver writes out_example0.dat into its working directory. Line 14 is PIOUT(1). The recipe copies that
# file out and prints `VALUE PIOUT1_h0p1 <number>` for each pass (the claimed name, as in result.json).
set -uo pipefail
ID=celledoni2010-frb-903
URL=https://netlib.org/toms/903.zip
SHA=b3be3b3a7ed19cbcfd7869b11285b531a7329ea90c98cfccc298a4f5a661ef14
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

GF=/work/env/bin/x86_64-conda-linux-gnu-gfortran
PKG=/work/pre/903
DOC=$PKG/Doc
SRC=$PKG/Fortran77/Src
DRV=$PKG/Fortran77/Drivers

echo "== fetch: 903.zip (sha256 checked), unzipped to /work/pre; gfortran 16.2.0 into /work/env"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre /work/bin && cd /work/dl && curl -fsSL -o 903.zip '$URL'; \
  echo \"sha256 \$(sha256sum 903.zip | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  903.zip' | sha256sum -c -; \
  python3 -m zipfile -e 903.zip /work/pre; \
  test -x $GF || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran_linux-64=16.2.0; }; \
  printf '      program t\n      end\n' > /work/t.f; \
  rm -f /work/t.o; $GF -c /work/t.f -o /work/t.o && test -s /work/t.o && echo gfortran_object=ok; \
  /work/bin/micromamba list -p /work/env 2>/dev/null | grep -i -E 'gfortran|gcc_linux' > /work/env-pins.txt || true; \
  find /work/pre -type f | sort" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -4 "$E/fetch.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/env-pins.txt" > "$E/env-pins.txt" 2>&1 || true
cat "$E/env-pins.txt"

echo "== manifest pre (right after unpack, before any patch or build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the archive Makefile, unchanged (copy of Doc), default FC = NAG f95 (absent)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -a $DOC/. /work/orig/ && cd /work/orig && make > /work/orig-make.log 2>&1; echo make_exit=\$?; cat /work/orig-make.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== manifest mid (immediately before the build; the Makefile is used as shipped)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build pass 1: the archive's Makefile with FC = sandbox gfortran, FOPTS = -O, sources through VPATH"
echo "   build pass 2: the same, FOPTS = -O2, in a second build directory"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build /work/build2 && mkdir /work/build /work/build2 && { \
  cd /work/build && /work/env/bin/x86_64-conda-linux-gnu-gfortran -O -o driver_example0 /work/pre/903/Fortran77/Drivers/driver_example0.f /work/pre/903/Fortran77/Src/frb_step.f && \
  cd /work/build2 && /work/env/bin/x86_64-conda-linux-gnu-gfortran -O2 -o driver_example0 /work/pre/903/Fortran77/Drivers/driver_example0.f /work/pre/903/Fortran77/Src/frb_step.f; } > /work/build.log 2>&1; echo build_exit=\$?; cat /work/build.log; ls -l /work/build/driver_example0 /work/build2/driver_example0" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== record the patch as build-only (exit 0 = no source changed before the build; the G2 paper check is not needed)"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$SCR/manifest.pre" --mid "$SCR/manifest.mid" --post "$SCR/manifest.post" \
  --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -O -o driver_example0 /work/pre/903/Fortran77/Drivers/driver_example0.f /work/pre/903/Fortran77/Src/frb_step.f" \
  --command "/work/env/bin/x86_64-conda-linux-gnu-gfortran -O2 -o driver_example0 /work/pre/903/Fortran77/Drivers/driver_example0.f /work/pre/903/Fortran77/Src/frb_step.f"
echo "record_exit=$?"

echo "== run: each pass in its own directory, with the shipped input init_example0.dat (copied, the archive is not used as cwd)"
tools/sandbox.sh "$ID" -- sh -c "for b in build build2; do cd /work/\$b && cp $DRV/init_example0.dat . && ./driver_example0; echo driver_exit_\$b=\$?; cp out_example0.dat /work/out_example0.\$b.dat; done; \
  cd /work && cp $DRV/out_example0.dat /work/out_example0.shipped.dat" > "$E/run.log" 2>&1
cat "$E/run.log"
for f in out_example0.build out_example0.build2 out_example0.shipped; do
  tools/sandbox.sh "$ID" -- sh -c "cat /work/$f.dat" > "$E/$f.dat"
done
cp "$E/out_example0.shipped.dat" "$E/out_example0.shipped"
sha256sum "$E/out_example0.shipped" | cut -d' ' -f1 > "$E/out_example0.shipped.sha256"

echo "== values: line 14 of each pass, and the largest difference from the shipped file over its 25 lines"
python3 -I - "$E" <<'PY'
import sys, os
E = sys.argv[1]
def lines(name):
    with open(os.path.join(E, name), encoding="utf-8") as f:
        return [float(x.split()[0]) for x in f if x.strip()]
ship = lines("out_example0.shipped.dat")
for name in ("out_example0.build.dat", "out_example0.build2.dat"):
    ours = lines(name)
    worst = max(abs(a - b) for a, b in zip(ours, ship))
    print(f"{name}: line14={ours[13]!r} max_abs_diff_vs_shipped_25_lines={worst:.3e} n={len(ours)}")
ours = lines("out_example0.build.dat")
print(f"VALUE PIOUT1_h0p1 {ours[13]!r}")
PY
