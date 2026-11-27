#!/usr/bin/env bash
# Rebuilds and reruns the GPS/GK bandwidth and profile reduction (TOMS Algorithm 582, Lewis 1982, Fortran 77) from the
# netlib archive. The archive is one plain listing: algorithms, driver, sample input and the authors' sample output, in four
# sections separated by 'C === SEPARATOR ===' cards. All execution goes through tools/sandbox.sh; the host only hashes and parses text.
#
# Fetch (network, inside the sandbox): netlib TOMS 582.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/582.txt; gfortran (conda-forge, micromamba) into /work/env if missing.
#
# Original attempt (G1): the listing as delivered is not Fortran (it holds the sample input and the output as well), so
# the compiler stops on it. That attempt is kept in evidence/original-attempt.log.
#
# Patch (extraction): the compilable part is lines 1 to 3762 (algorithms and driver), cut from the archive into
# /work/orig/tree/gps.f. The sample input (lines 3764 to 3947) is piped to the driver's standard input and is not a new file.
# No line is edited. The recorded range and the mid manifest prove it.
set -uo pipefail
ID=lewis1982-gps-582
URL=https://netlib.org/toms/582.gz
SHA=6b71e42fd18c836c260133ae293d6cf00f5a7df6e3b64af1641aaf5319e48d1b
RANGE_END=3762
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E/manifests"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 582.gz (sha256 checked), gunzipped; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/582.gz '$URL'; echo '$SHA  /work/582.gz' | sha256sum -c -; gzip -dc /work/582.gz > /work/pre/582.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba; /work/mm/bin/micromamba create -y -q -r /work/mm/root -p /work/env -c conda-forge --override-channels gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): compile the listing as delivered"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre && env PATH=/work/env/bin:/usr/bin:/bin gfortran -std=legacy -x f77 -c 582.txt; echo compile_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -3 "$E/original-attempt.log"

MAN="$E/manifests"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir -p /work/orig/tree"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.pre"

echo "== patch (extraction): lines 1-$RANGE_END of the archive listing copied to gps.f"
tools/sandbox.sh "$ID" -- sh -c "sed -n '1,${RANGE_END}p' /work/pre/582.txt > /work/orig/tree/gps.f; wc -l /work/orig/tree/gps.f"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.mid"

echo "== build (sandbox; no editing in this step)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree && env PATH=/work/env/bin:/usr/bin:/bin gfortran -std=legacy -c gps.f && env PATH=/work/env/bin:/usr/bin:/bin gfortran gps.o -o driver; echo build_exit=\$?" > "$E/build.log" 2>&1
tail -3 "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/orig/tree" > "$MAN/manifest.post"

echo "== run the driver on the sample input (lines 3764-3947 of the listing, piped to stdin; sandbox, no network)"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/run && cd /work/orig/tree && sed -n '3764,3947p' /work/pre/582.txt | ./driver > /work/run/out.txt; echo run_exit=\$?; cat /work/run/out.txt" > "$E/run.txt" 2>&1
head -c 4000 "$E/run.txt"; echo

echo "== values (host, text only)"
python3 -I - "$E/run.txt" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
block = t.split("(SCALAR RESULTS FROM GPSKCA)", 1)[1]
bw = re.search(r"BANDWIDTH\s+(\d+)", block).group(1)
pr = re.search(r"PROFILE\s+(\d+)", block).group(1)
ec = re.search(r"GPSKCA ERROR CODE\s+(\d+)", block).group(1)
print(f"VALUE BANDWIDTH {int(bw)}")
print(f"VALUE PROFILE {int(pr)}")
print(f"VALUE GPSKCA ERROR CODE {int(ec)}")
PY
echo "== done; scratch kept at $SCRATCH"
