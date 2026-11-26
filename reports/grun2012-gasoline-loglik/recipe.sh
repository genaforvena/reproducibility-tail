#!/usr/bin/env bash
# G1 original attempt for grun2012-gasoline-loglik: the authors' betareg 3.0-0 package,
# built with R in the sandbox (no source edits), then the ML logLik on GasolineYield.
# Fetch step: tarball + micromamba + R and compilers + R dependencies from conda-forge.
# Only --fetch steps touch the network. Log: evidence/original-attempt.log (replay: LOG=evidence/replay.log).
# The driver runs twice (G3 replay). The reimplementation (recipe-reimplemented.sh) is a cross-check.
set -uo pipefail
ID=grun2012-gasoline-loglik
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
cd "$root"
URL=https://cran.r-project.org/src/contrib/Archive/betareg/betareg_3.0-0.tar.gz
SHA=8e021999a8647ee5d7b23cf1e6be3f60a68a2b72102d0f7852c23a3568831df3
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
LOG="${LOG:-$root/reports/$ID/evidence/original-attempt.log}"
exec > >(tee "$LOG") 2>&1
echo "== fetch: tarball, micromamba"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/betareg_3.0-0.tar.gz '$URL' && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba" || { echo "FETCH-FAILED"; exit 1; }
echo "$SHA  /work/betareg_3.0-0.tar.gz" > /dev/null
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/betareg_3.0-0.tar.gz' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }
echo "== fetch: R and dependencies"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/r -c conda-forge --override-channels r-base r-formula r-flexmix r-lmtest r-modeltools r-sandwich gcc_linux-64 gxx_linux-64 gfortran_linux-64 make" || { echo "R-INSTALL-FAILED"; exit 1; }
echo "== build betareg 3.0-0 (authors' code) and fit ML"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src /work/Rlib && tar -xzf /work/betareg_3.0-0.tar.gz -C /work/src && export PATH=/work/r/bin:\$PATH && R CMD INSTALL -l /work/Rlib /work/src/betareg" || { echo "BUILD-FAILED"; exit 1; }
W=/mnt/mishe-scratch/reproducibility-tail/$ID; mkdir -p "$W"; cp "$here/impl/ml_original.R" "$W/ml.R"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/r/bin:\$PATH; for i in 1 2; do echo \"== driver run \$i\"; R_LIBS=/work/Rlib:/work/r/lib/R/library Rscript --vanilla /work/ml.R; done" || { echo "RUN-FAILED"; exit 1; }
echo "== done"
