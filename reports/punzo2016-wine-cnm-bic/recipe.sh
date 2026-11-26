#!/usr/bin/env bash
# Rebuilds the rerun verdict for punzo2016-wine-cnm-bic (basis: original).
# Fetches the archived CRAN ContaminatedMixt 1.0 tarball (sha256 checked), installs R 4.6.2 and
# gfortran/gcc into the sandbox scratch with micromamba, and the Imports (mixture, mnormt, mclust)
# from CRAN (fetch step only). Builds the authors' package with R CMD INSTALL and runs the driver
# (one CNmixt call per G and structure, seed 1) twice. Every untrusted step runs only through tools/sandbox.sh.
set -euo pipefail
ID=punzo2016-wine-cnm-bic
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
# Log: evidence/recipe-run.log by default (replay: LOG=...). The G1 original attempts stay in evidence/original-attempt.log.
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
exec > >(tee "$LOG") 2>&1
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W"
cp "$here/impl/original_run.R" "$W/"
cd "$root"
URL=https://cran.r-project.org/src/contrib/Archive/ContaminatedMixt/ContaminatedMixt_1.0.tar.gz
SHA=5b1cd5ea32712e748d817128ff52f5343ebf9228b682ce70cb38b9086869448e
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest

# Fetch: tarball, micromamba, then R and compilers into /work/r (inside the sandbox scratch).
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/CM.tar.gz '$URL' && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba"
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/CM.tar.gz' | sha256sum -c -"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/r -c conda-forge --override-channels r-base && /work/mm/bin/micromamba install -y -r /work/mm/root -p /work/r -c conda-forge --override-channels gcc_linux-64 gxx_linux-64 gfortran_linux-64 make"
# Imports from CRAN (versions as installed today are recorded by the driver's PKG lines).
tools/sandbox.sh --fetch "$ID" -- sh -c "export PATH=/work/r/bin:\$PATH && mkdir -p /work/Rlib && Rscript -e 'options(repos=c(CRAN=\"https://cloud.r-project.org\")); install.packages(c(\"mixture\",\"mnormt\",\"mclust\"), lib=\"/work/Rlib\")'"

# Build the authors' package (original code, no edits) and run the driver twice.
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src && tar -xzf /work/CM.tar.gz -C /work/src && export PATH=/work/r/bin:\$PATH && R CMD INSTALL -l /work/Rlib /work/src/ContaminatedMixt"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/r/bin:\$PATH; R_LIBS=/work/Rlib Rscript --vanilla /work/original_run.R > /work/run1.log 2>&1; R_LIBS=/work/Rlib Rscript --vanilla /work/original_run.R > /work/run2.log 2>&1; echo '== driver run 1'; cat /work/run1.log; echo '== driver run 2'; cat /work/run2.log"
# G5 contract: the VALUE lines come from the second driver run.
echo "VALUE selected_G $(grep '^SELECTED_G ' "$LOG" | tail -1 | awk '{print $NF}')"
echo "VALUE selected_structure_index $(grep '^SELECTED_STRUCTURE_INDEX ' "$LOG" | tail -1 | awk '{print $NF}')"
