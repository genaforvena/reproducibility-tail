#!/usr/bin/env bash
# Rebuilds and reruns the jonasson2008-varma-878 attempt (TOMS 878, exact VARMA likelihood, MATLAB/Octave).
# Everything that runs the authors' code goes through tools/sandbox.sh; the host only hashes and copies text.
#
# Fetch (network, inside the sandbox): netlib TOMS 878.zip (sha256 checked), unzipped to /work/pre/878;
# micromamba and conda-forge octave into /work/env if missing (octave 10.3.0 was used).
#
# Run: the authors' Matlab/Src files unedited, copied to /work/run/Src. The wrapper impl/run_varma_llc.m sits beside
# them (it must, because testcase.m is a private function) and replays the authors' test_varma_llc loop without the
# as311 column: randn('state',1), then testcase(j), varma_sim(A,B,Sig,10), varma_llc(X,A,B,Sig,'res').
# The wrapper also adds Octave's m-file library to the path. Stdout lines "VALUE varma_llc NAME log-likelihood X".
#
# Claim: the ten varma_llc values in queue/jonasson2008-varma-878.json, absolute tolerance 1e-6. Known limit: the
# registered values were produced with MATLAB's randn stream; this run uses Octave's, so the data differ (see result.md).
set -uo pipefail
ID=jonasson2008-varma-878
URL=https://netlib.org/toms/878.zip
SHA=cbf6aec91cef72ae3c71af66c31274d4c76ac5c88f68acd2fef69a1001afd337
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E" "$SCRATCH/impl"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 878.zip (sha256 checked), unzipped; octave into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/878.zip '$URL'; echo '$SHA  /work/878.zip' | sha256sum -c -; python3 -c 'import zipfile;zipfile.ZipFile(\"/work/878.zip\").extractall(\"/work/pre\")'; \
  test -x /work/env/bin/octave || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels octave; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== run: authors' Src unedited beside the wrapper; Octave runs the authors' test loop"
cp "$here/impl/run_varma_llc.m" "$SCRATCH/impl/run_varma_llc.m"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/run && mkdir /work/run && cp -r /work/pre/878/Matlab/Src /work/run/Src && cp /work/impl/run_varma_llc.m /work/run/Src/ && cd /work/run/Src && /work/env/bin/octave --no-gui -q /work/run/Src/run_varma_llc.m" > "$E/original-attempt.log" 2>&1
echo "exit=$?"
grep '^VALUE' "$E/original-attempt.log"
