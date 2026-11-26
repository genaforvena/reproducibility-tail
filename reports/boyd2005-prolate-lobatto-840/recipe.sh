#!/usr/bin/env bash
# Rebuilds the rerun verdict for boyd2005-prolate-lobatto-840 (TOMS 840, prolate spheroidal spectral-element grids, MATLAB).
# Fetch (the only network step, inside the sandbox): netlib TOMS 840.gz (sha256 checked), unpacked with sh into /work/pre
# (Matlab/Dp/Drivers: TP_Lobptsts_MAIN.m, TP_LobptswtsPERT.m, Res; Matlab/Dp/Src: the rest). GNU Octave 10.3.0 from
# conda-forge (micromamba) into /work/octave. Everything else runs through tools/sandbox.sh.
# Original attempt (G1): the driver as shipped under Octave. It stops at line 9: 'clf' undefined. Log: evidence/original-attempt.log.
# Patch (basis patched, run-time, not build-only): four workarounds, kept outside the authors' tree in impl/shim/:
#   clf (no-op), TP_NewtonJac (alias for TP_NewtonJAC.m, a case mismatch), plot stubs (semilogy, set, title, xlabel,
#   ylabel, gca), and Octave's m library on the path (num2str, fieldnames). No authors' file is edited.
# Input: N=6 and c=5 on stdin (the driver's input() prompts). impl/print_values.m (our code) prints the two registered values.
# Claim: xprol(2) = -0.7456 and wprol(3) = 0.5305 for N=6, c=5 (the shipped Res reference), absolute tolerance 2e-4.
# Two passes (G3): each in its own clean directory.
set -uo pipefail
ID=boyd2005-prolate-lobatto-840
URL=https://netlib.org/toms/840.gz
SHA=b213f74e8eadba736256700f462906138d71615c29fefdbb871b5a3ba5703aff
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E/reference" "$W"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 840.gz (sha256 checked), shar unpacked with sh; Octave 10.3.0 (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre; mkdir /work/pre; cd /work; curl -fsSL -o 840.gz '$URL'; echo '$SHA  840.gz' | sha256sum -c -; gunzip -kf 840.gz; L=\$(grep -n '^#! /bin/sh' 840 | head -1 | cut -d: -f1); sed -n \"\$L,\\\$p\" 840 > pre/shar.sh; cd pre && sh shar.sh; test -f Matlab/Dp/Drivers/TP_Lobptsts_MAIN.m && test -f Matlab/Dp/Src/TP_NewtonJAC.m; \
  test -x /work/octave/bin/octave || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/octave -c conda-forge octave=10.3.0; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== shipped reference: Matlab/Dp/Drivers/Res, copied unedited"
tools/sandbox.sh "$ID" -- cat /work/pre/Matlab/Dp/Drivers/Res > "$E/reference/Res"
grep -m1 "^ *-0.7456\|-0.7456" "$E/reference/Res" || true

# Our code and the shim go into the scratch directory (outside the authors' tree).
rm -rf "$W/shim" && cp -r "$root/reports/$ID/impl/shim" "$W/shim" && cp "$root/reports/$ID/impl/print_values.m" "$W/print_values.m"

# G1 original attempt: the driver as shipped.
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -r /work/pre/Matlab/Dp /work/orig/Dp && cd /work/orig/Dp/Drivers && printf '6\n5\n' | /work/octave/bin/octave --no-gui --quiet TP_Lobptsts_MAIN.m; echo octave_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -2 "$E/original-attempt.log"

# G3: two passes, each in a clean directory: shim and Src on the path, the driver, then print_values.
for pass in pass-1 pass-2; do
  echo "== $pass: clean directory, driver (N=6, c=5) then print_values"
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/$pass && mkdir /work/$pass && cp -r /work/pre/Matlab/Dp /work/$pass/Dp && cp -r /work/shim /work/$pass/shim && cp /work/print_values.m /work/$pass/Dp/Drivers/ && cd /work/$pass/Dp/Drivers && printf '6\n5\n' | timeout 900 /work/octave/bin/octave --no-gui --quiet --eval \"addpath(genpath('/work/octave/share/octave/10.3.0/m')); addpath('/work/$pass/shim'); addpath('/work/$pass/Dp/Src'); TP_Lobptsts_MAIN; print_values\" > /work/$pass-stdout.txt 2>&1; s=\$?; cat /work/$pass-stdout.txt; echo ${pass}_exit=\$s" > "$E/$pass.log" 2>&1
  tail -1 "$E/$pass.log"
  grep '^VALUE ' "$E/$pass.log" | tee "$E/$pass-values.txt"
done

echo "== claimed values per pass (registered tolerance 2e-4)"
cat "$E/pass-1-values.txt"
cat "$E/pass-2-values.txt"
