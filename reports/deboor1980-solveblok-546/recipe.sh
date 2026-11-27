#!/usr/bin/env bash
# Rebuilds and reruns TOMS Algorithm 546 (de Boor and Weiss 1980, SOLVEBLOK: almost block diagonal systems), Fortran.
# The shipped single file 546.f (inside netlib 546.gz) holds SLVBLK, DTBLOK and the test program; its own DATA
# constant 2.418821899E6 is the determinant reference. Claim and tolerance (abs 5.0) are registered in
# queue/deboor1980-solveblok-546.json and are not edited here.
#
# Fetch (network, inside the sandbox): netlib 546.gz, sha256 checked, gunzipped to /work/pre/546/546.f;
# gfortran (conda-forge, micromamba) into /work/env if missing (the host has no Fortran compiler).
#
# G1 original attempt: the file as shipped is compiled with gfortran with no patch. It compiles with warnings only
# (Fortran 2018 deleted-feature warnings for shared DO labels) and runs as documented. Basis: original.
# Pass 1 compiles at the default optimisation level; pass 2 (G3) compiles the same unmodified file at -O2 in a
# clean directory. Both passes must print the same DETERMINANT.
set -uo pipefail
ID=deboor1980-solveblok-546
URL=https://netlib.org/toms/546.gz
SHA=dec187cff28bdce0de6c53439e6562fbf9748a86e3a379a66296456b357bb524
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
PATHSET='export PATH=/work/env/bin:$PATH'

echo "== fetch: 546.gz (sha256 checked), gunzipped to /work/pre/546/546.f; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre/546 && cd /work/pre/546 && curl -fsSL -o /work/546.gz '$URL'; echo '$SHA  /work/546.gz' | sha256sum -c -; gzip -dc /work/546.gz > /work/pre/546/546.f; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }; echo fetch_ok" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -1 "$E/fetch.log"

echo "== pass 1 (G1): the file as shipped, gfortran default optimisation, then run the test program"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/p1 && mkdir /work/p1 && cp /work/pre/546/546.f /work/p1/ && cd /work/p1 && gfortran -o solveblok 546.f > build.log 2>&1; echo build_exit=\$?; grep -c Warning build.log; ./solveblok < /dev/null > out.txt 2>err.txt; echo run_exit=\$?; cat out.txt" > "$E/pass1.log" 2>&1
cat "$E/pass1.log"
echo "== pass 2 (G3): clean copy of the same file, compiled -O2, run"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && rm -rf /work/p2 && mkdir /work/p2 && cp /work/pre/546/546.f /work/p2/ && cd /work/p2 && gfortran -O2 -o solveblok 546.f > build.log 2>&1; echo build_exit=\$?; ./solveblok < /dev/null > out.txt 2>err.txt; echo run_exit=\$?; cat out.txt" > "$E/pass2.log" 2>&1
cat "$E/pass2.log"

echo "== values: DETERMINANT as printed by the program, both passes (host, text only)"
python3 -I - "$E/pass1.log" "$E/pass2.log" <<'PY'
import re, sys
vals = []
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8", errors="replace").read()
    m = re.search(r"DETERMINANT\s*=\s*(\S+)E([+-]\d+)", text)
    assert m, ("no DETERMINANT line", path)
    vals.append(float(m.group(1) + "E" + m.group(2)))
assert vals[0] == vals[1], ("passes disagree", vals)
print(f"VALUE DETERMINANT_546_TEST {vals[0]!r}")
PY
