#!/usr/bin/env bash
# Rebuilds the rerun verdict for wang2011-species-butterfly-ace (basis: original).
# Fetches the archived CRAN SPECIES 1.0 tarball (sha256 checked), installs R 4.6.2 and
# gfortran/gcc into the sandbox scratch with micromamba (fetch step only), builds the
# authors' package with R CMD INSTALL and calls its ChaoLee1992 on the bundled butterfly data.
# Every untrusted step runs only through tools/sandbox.sh; only --fetch steps use network.
# The driver run is executed twice (replay, G3).
set -euo pipefail
ID=wang2011-species-butterfly-ace
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W"
cp "$here/impl/original_run.R" "$W/"
cd "$root"
URL=https://cran.r-project.org/src/contrib/Archive/SPECIES/SPECIES_1.0.tar.gz
SHA=c0c90cfeeb73c991411cd40b52ddf83f4dab9ca4eb928cd731244b2e1ca5855c
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest

# Fetch: tarball, micromamba, then R and compilers into /work/r (inside the sandbox scratch).
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/SPECIES_1.0.tar.gz '$URL' && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba"
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/SPECIES_1.0.tar.gz' | sha256sum -c -"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/r -c conda-forge --override-channels r-base && /work/mm/bin/micromamba install -y -r /work/mm/root -p /work/r -c conda-forge --override-channels gcc_linux-64 gxx_linux-64 gfortran_linux-64 make"

# Build the authors' package (original code, no edits) and run the driver twice.
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/src /work/Rlib && tar -xzf /work/SPECIES_1.0.tar.gz -C /work/src && export PATH=/work/r/bin:\$PATH && R CMD INSTALL -l /work/Rlib /work/src/SPECIES"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/r/bin:\$PATH; R_LIBS=/work/Rlib Rscript --vanilla /work/original_run.R > /work/run1.log 2>&1; R_LIBS=/work/Rlib Rscript --vanilla /work/original_run.R > /work/run2.log 2>&1; cat /work/run1.log; echo ---; cat /work/run2.log"
