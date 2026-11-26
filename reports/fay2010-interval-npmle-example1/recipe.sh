#!/usr/bin/env bash
# Canonical rerun for fay2010-interval-npmle-example1 (basis: original).
# Fetch: archived CRAN tarball interval_0.9-9.6 (sha256 checked), micromamba, R with the
# interval dependencies (perm, survival, Icens, MLEcens) from conda-forge.
# Build: the authors' interval package with R CMD INSTALL (no edits). Driver: impl/run_original.R, twice (G3).
# Only --fetch steps touch the network. Log: evidence/recipe-run.log (LOG env overrides); the G1 original attempt
# is evidence/original-attempt.log and is never overwritten.
set -uo pipefail
ID=fay2010-interval-npmle-example1
SHA=93a73d61a9be5554eec24f773ea306ffbe0148860b1d45fc5385e8e076e72dc0
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W"; cp "$here/impl/run_original.R" "$W/run.R"
cd "$root"
URL=https://cran.r-project.org/src/contrib/Archive/interval/interval_0.9-9.6.tar.gz
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
exec > >(tee "$LOG") 2>&1
echo "== fetch: tarball, micromamba"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/interval.tar.gz '$URL' && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/interval.tar.gz' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }
echo "== fetch: R and dependencies"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/r -c conda-forge -c bioconda --override-channels r-base r-survival r-perm bioconductor-icens gcc_linux-64 gxx_linux-64 gfortran_linux-64 make" || { echo "R-INSTALL-FAILED"; exit 1; }
# MLEcens is CRAN-only (not on conda-forge): fetch its current CRAN release in the fetch step and record its version.
tools/sandbox.sh --fetch "$ID" -- sh -c "mkdir -p /work/Rlib && export PATH=/work/r/bin:\$PATH; Rscript -e 'install.packages(\"MLEcens\", lib=\"/work/Rlib\", repos=\"https://cloud.r-project.org\")' && Rscript -e 'cat(\"MLEcens\", as.character(packageVersion(\"MLEcens\", lib.loc=\"/work/Rlib\")), \"\n\")'" || { echo "MLECENS-INSTALL-FAILED"; exit 1; }
echo "== build interval 0.9-9.6 (authors' code) and run the paper listing"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src /work/Rlib && tar -xzf /work/interval.tar.gz -C /work/src && export PATH=/work/r/bin:\$PATH && R CMD INSTALL -l /work/Rlib /work/src/interval" || { echo "BUILD-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/r/bin:\$PATH; for i in 1 2; do echo \"== driver run \$i\"; R_LIBS=/work/Rlib:/work/r/lib/R/library Rscript --vanilla /work/run.R; done" || { echo "RUN-FAILED"; exit 1; }
echo "== done"
# G5 contract: P((2,3]) from the last driver run: the 12-digit summary line (single space before the number).
echo "VALUE P((2,3]) $(grep -E '^[0-9]+ +\(2,3\] [0-9.]+$' "$LOG" | tail -1 | awk '{print $NF}')"
