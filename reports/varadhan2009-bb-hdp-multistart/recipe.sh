#!/usr/bin/env bash
# Canonical rerun for varadhan2009-bb-hdp-multistart (basis: original).
# Fetch: the archived CRAN tarball BB_2009.9-1 (sha256 checked), micromamba, and R with the
# packages BB imports or the paper's listing needs (numDeriv, setRNG) from conda-forge.
# Build: the authors' BB package with R CMD INSTALL (no edits). hdp is taken from the authors' vignette
# source (the installed package does not export it). Run: impl/ml_original.R twice (G3).
# Only --fetch steps touch the network. Log: evidence/original-attempt.log (LOG env overrides).
set -uo pipefail
ID=varadhan2009-bb-hdp-multistart
SHA=e6b145bda50727838623442e1dc7985b1e9806c68371bf542c600209394ac88e
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W"; cp "$here/impl/ml_original.R" "$W/run.R"
cd "$root"
URL=https://cran.r-project.org/src/contrib/Archive/BB/BB_2009.9-1.tar.gz
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
LOG="${LOG:-$root/reports/$ID/evidence/original-attempt.log}"
exec > >(tee "$LOG") 2>&1
echo "== fetch: tarball, micromamba"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/BB.tar.gz '$URL' && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/BB.tar.gz' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }
echo "== fetch: R and dependencies"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/r -c conda-forge --override-channels r-base r-numderiv r-setrng gcc_linux-64 gxx_linux-64 gfortran_linux-64 make" || { echo "R-INSTALL-FAILED"; exit 1; }
echo "== build BB 2009.9-1 (authors' code) and run the paper listing"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src /work/Rlib && tar -xzf /work/BB.tar.gz -C /work/src && export PATH=/work/r/bin:\$PATH && R CMD INSTALL -l /work/Rlib /work/src/BB" || { echo "BUILD-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "tar -xOzf /work/BB.tar.gz BB/inst/doc/BBvignetteJSS.Stex | sed -n '/^hdp <- function/,/^  }\$/p' > /work/hdp.R && test -s /work/hdp.R && cat /work/hdp.R" || { echo "HDP-EXTRACT-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/r/bin:\$PATH; for i in 1 2; do echo \"== driver run \$i\"; R_LIBS=/work/Rlib:/work/r/lib/R/library Rscript --vanilla /work/run.R; done" || { echo "RUN-FAILED"; exit 1; }
echo "== done"
