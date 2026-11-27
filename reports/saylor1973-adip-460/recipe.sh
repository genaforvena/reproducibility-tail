#!/usr/bin/env bash
# Rebuilds and reruns TOMS Algorithm 460 (Saylor and Sebastian, ADIP, optimum ADI parameters), Fortran.
# The shipped archive 460.gz (a shell archive) holds Fortran/Dp/Src/src.f (ADIP) and Fortran/Dp/Drivers/driver.f
# (the test program) plus the authors' reference output Fortran/Dp/Drivers/res. Claim and tolerance (abs 1e-7) are
# registered in queue/saylor1973-adip-460.json and are not edited here.
#
# Fetch (network, inside the sandbox): netlib 460.gz, sha256 checked, unpacked with /bin/sh into /work/pre/460;
# gfortran (conda-forge, micromamba) into /work/env if missing (the host has no Fortran compiler).
#
# G1 original attempt: the authors' Makefile in Fortran/Dp/Drivers expects src.f in the same directory, but the
# archive ships it in Fortran/Dp/Src. The documented build (Src/src.f with Drivers/driver.f) is therefore run as
# one gfortran command on the archive's own files, with the binary written to a scratch directory. No archive
# file is edited, copied over or patched. Basis: original.
# Pass 1 compiles at the default optimisation level; pass 2 (G3) compiles the same unmodified files at -O2 in a
# clean directory. Both passes must print the same DMU for ITNS = 1.
set -uo pipefail
ID=saylor1973-adip-460
URL=https://netlib.org/toms/460.gz
SHA=542ae8263c1d41ae98a2d100713e8dc62555d50ee88446d28c2b608002c8982d
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
PATHSET='export PATH=/work/env/bin:$PATH'

echo "== fetch: 460.gz (sha256 checked), unpacked with /bin/sh into /work/pre/460; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/460.gz '$URL'; echo '$SHA  /work/460.gz' | sha256sum -c -; gzip -dc /work/460.gz > /work/pre/460.sh; rm -rf /work/pre/460 && mkdir -p /work/pre/460 && cd /work/pre/460 && /bin/sh /work/pre/460.sh > /work/unpack.log 2>&1; test -f /work/pre/460/Fortran/Dp/Src/src.f; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }; echo fetch_ok" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -1 "$E/fetch.log"

echo "== pass 1 (G1): the archive's files as shipped, gfortran default optimisation, then run the driver"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/p1 && mkdir /work/p1 && cd /work/p1 && S=/work/pre/460/Fortran/Dp; gfortran -o driver \$S/Src/src.f \$S/Drivers/driver.f > build.log 2>&1; echo build_exit=\$?; grep -ci error build.log; ./driver < /dev/null > out.txt 2>err.txt; echo run_exit=\$?; cat out.txt; echo '== diff vs shipped res'; diff out.txt \$S/Drivers/res && echo SAME_AS_SHIPPED_RES || echo DIFFERS_FROM_SHIPPED_RES" > "$E/pass1.log" 2>&1
cat "$E/pass1.log"
echo "== pass 2 (G3): the same unmodified files compiled -O2 in a clean directory, then run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/p2 && mkdir /work/p2 && cd /work/p2 && S=/work/pre/460/Fortran/Dp; gfortran -O2 -o driver \$S/Src/src.f \$S/Drivers/driver.f > build.log 2>&1; echo build_exit=\$?; grep -ci error build.log; ./driver < /dev/null > out.txt 2>err.txt; echo run_exit=\$?; cat out.txt; echo '== diff vs shipped res'; diff out.txt \$S/Drivers/res && echo SAME_AS_SHIPPED_RES || echo DIFFERS_FROM_SHIPPED_RES" > "$E/pass2.log" 2>&1
cat "$E/pass2.log"

echo "== values: DMU for ITNS = 1 as printed by the driver, both passes (host, text only)"
python3 -I - "$E/pass1.log" "$E/pass2.log" <<'PY'
import re, sys
vals = []
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8", errors="replace").read()
    m = re.search(r"^\s+1\s+(\S+E[+-]\d+)\s+0\s*$", text, re.M)
    assert m, ("no ITNS = 1 DMU line", path)
    vals.append(m.group(1))
assert vals[0] == vals[1], ("passes disagree", vals)
print(f"VALUE DMU_ITNS1 {vals[0]}")
PY
