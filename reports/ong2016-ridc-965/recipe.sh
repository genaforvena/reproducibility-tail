#!/usr/bin/env bash
# Rebuilds the rerun record for ong2016-ridc-965 (CALGO Algorithm 965, RIDC parallel time integrators, C++, Ong, Haynes, Ladd 2016).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (network, inside the sandbox): netlib TOMS 965.zip, sha256 checked against the queue entry's code.archive,
# unzipped into /work/pre. Toolchain: the sandbox's own g++, autotools and make (present on this host).
#
# G1 (original): the authors' own ./configure, make, make check, run in a copy (/work/orig-run). make check runs
# examples/explicit/run.sh, which diffs the order-4 outputs for nt = 10..160 against ref/n*.ref.
#
# No source file is edited; the basis is original. The claim is sol[0] printed by ./explicit 4 10 (n1 case).
#
# Run: VALUE line for the claimed value, SOL0_RIDC4_NT10.
set -uo pipefail
ID=ong2016-ridc-965
URL=https://netlib.org/toms/965.zip
SHA=a05c08deacd16436d180e8fe7e29557732b852a089785692eac07594158560c5
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 965.zip (sha256 checked), unzipped to /work/pre"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && cd /work && curl -fsSL -o /work/965.zip '$URL'; \
  echo \"sha256 \$(sha256sum /work/965.zip | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  /work/965.zip' | sha256sum -c -; \
  cd /work/pre && unzip -q /work/965.zip; g++ --version | head -1; make --version | head -1" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== G1 original: the authors' configure, make and make check, in a copy"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/965 /work/orig-run/ && cd /work/orig-run/965 && (./configure > /work/orig-configure.log 2>&1; echo configure_exit=\$?) && (make > /work/orig-make.log 2>&1; echo make_exit=\$?); (make check > /work/orig-check.log 2>&1; echo check_exit=\$?); tail -15 /work/orig-check.log; cat examples/explicit/explicit.trs 2>/dev/null; cat examples/explicit/diff.log 2>/dev/null; echo diff_log_end" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== run: ./explicit 4 10 from the authors' build (the n1 case), output compared with ref/n1.ref"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig-run/965/examples/explicit && ./explicit 4 10 > /work/explicit-4-10.out; echo run_exit=\$?; cmp /work/explicit-4-10.out ref/n1.ref && echo identical_to_n1_ref" > "$E/run.log" 2>&1
cat "$E/run.log"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig-run/965/examples/explicit && ./explicit 4 10" > "$E/Res" 2>/dev/null
cp "$E/Res" "$E/Res.copy" 2>/dev/null; rm -f "$E/Res.copy"

echo "== values"
python3 -I - "$E/Res" <<'PY'
import sys
first = open(sys.argv[1], encoding="utf-8").readline().strip()
print(f"VALUE SOL0_RIDC4_NT10 {first}")
PY
