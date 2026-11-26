#!/usr/bin/env bash
# Rebuilds the rerun verdict for grun2012-gasoline-loglik (basis: reimplemented).
# Fetches the archived betareg 3.0-0 tarball (sha256 checked), extracts the bundled
# GasolineYield.rda, parses it with impl/rda_to_csv.py and fits impl/betareg_ml.py.
# Every untrusted step runs only through tools/sandbox.sh; the fetch is the only
# step with network access.
set -euo pipefail
ID=grun2012-gasoline-loglik
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$W"
cp "$here/impl/rda_to_csv.py" "$here/impl/betareg_ml.py" "$W/"
cd "$root"
URL=https://cran.r-project.org/src/contrib/Archive/betareg/betareg_3.0-0.tar.gz
SHA=8e021999a8647ee5d7b23cf1e6be3f60a68a2b72102d0f7852c23a3568831df3
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/betareg_3.0-0.tar.gz '$URL'"
tools/sandbox.sh "$ID" -- sh -c "echo '$SHA  /work/betareg_3.0-0.tar.gz' | sha256sum -c -"
tools/sandbox.sh "$ID" -- sh -c 'mkdir -p /work/src && tar -xzf /work/betareg_3.0-0.tar.gz -C /work/src && python3 -I /work/rda_to_csv.py /work/src/betareg/data/GasolineYield.rda > /work/gasoline.csv'
tools/sandbox.sh "$ID" -- python3 -I /work/betareg_ml.py /work/gasoline.csv
