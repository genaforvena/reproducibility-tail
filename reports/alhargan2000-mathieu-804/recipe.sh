#!/usr/bin/env bash
# Rebuilds and reruns the TOMS 804 claim (Alhargan 2000, Mathieu functions of integer order, C++): the value
# printed by the shipped driver in CPP/Dp/Drivers/res1 at row x = 19.790, column 4 (h = 9, Sn of order 3),
# +2.750024, absolute tolerance 1e-6, registered and not edited. Everything that runs the archive's code goes
# through tools/sandbox.sh. The host only hashes sources (tools/verify_sources.py) and copies text output.
#
# Fetch (network, inside the sandbox): netlib CALGO 804.gz, sha256 pinned in the queue entry, gunzipped and unpacked
# with /bin/sh (a shell archive) into /work/pre.
#
# G1 original attempt: the archive Makefile, unchanged, in a copy: `make res1`. The Makefile begins with
# `include makefile.inc`, and makefile.inc is NOT in the archive (the shar ships no such file), so make stops
# before the first compile. The log is kept as evidence/original-attempt.log.
#
# Build-only route: the archive's Makefile rules are run by hand, command by command, with the same compile and
# link lines and the same include directory (-I../Src), with g++ 13.3.0 (host, /usr/bin/g++, run inside the
# sandbox) and -O2. The modern libstdc++ fails on bsslr.cpp as shipped: its global `abs(double)` clashes with the
# `using std::abs` that the C++ wrapper <stdlib.h> injects (bsslr.cpp:19, evidence/build-original-abs.log; -std=gnu++98
# does not help). The workaround is a compiler include path, not an edit: /work/shim/stdlib.h (outside the archive)
# includes the C library's /usr/include/stdlib.h directly, and -I/work/shim is passed to every compile. No archive
# file is created, edited or copied, so manifests pre and mid match.
#
# Run: the driver reads data1 on stdin and writes its table to stdout (the Makefile's res1 rule: driver < data1).
# The VALUE line is the column-4 entry of the row with x = 19.790.
set -uo pipefail
ID=alhargan2000-mathieu-804
URL=https://netlib.org/toms/804.gz
SHA=d6cb0600a2257bb2f935d370e0d5140a7d57120fafbe39b446fb0fba98b0dd02
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
SCR=/mnt/mishe-scratch/reproducibility-tail/$ID
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E" "$SCR"
cd "$root"
exec > >(tee "$LOG") 2>&1

D=/work/pre/CPP/Dp/Drivers
S=/work/pre/CPP/Dp/Src

echo "== fetch: 804.gz (sha256 checked), unpacked to /work/pre"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre /work/dl && mkdir -p /work/dl /work/pre && cd /work/dl && curl -fsSL -o 804.gz '$URL'; \
  echo \"sha256 \$(sha256sum 804.gz | cut -d' ' -f1) expected $SHA\"; \
  echo '$SHA  804.gz' | sha256sum -c -; \
  gunzip -c 804.gz > 804.sh; cd /work/pre && /bin/sh /work/dl/804.sh; \
  find /work/pre -type f | sort; g++ --version | head -1" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
tail -3 "$E/fetch.log"

echo "== manifest pre (right after unpack, before any patch or build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.pre"
cp "$SCR/manifest.pre" "$E/manifest.pre"
wc -l < "$E/manifest.pre"

echo "== G1 original attempt: the archive Makefile, unchanged, in a copy: make res1"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig-run && mkdir /work/orig-run && cp -a /work/pre/. /work/orig-run/ && \
  cd /work/orig-run/CPP/Dp/Drivers && make res1 > /work/orig-make.log 2>&1; echo make_exit=\$?; cat /work/orig-make.log" \
  > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== patch step (outside the archive): the stdlib.h shim, written before the mid manifest"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/shim && printf '%s\\n' '/* build shim: the C library stdlib.h directly, not the C++ wrapper that injects std::abs */' '#include </usr/include/stdlib.h>' > /work/shim/stdlib.h && cat /work/shim/stdlib.h" \
  > "$E/shim.log" 2>&1
cat "$E/shim.log"

echo "== manifest mid (immediately before the build; the archive sources are unchanged since pre)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.mid"
cp "$SCR/manifest.mid" "$E/manifest.mid"

echo "== build: the Makefile's rules, one command each (g++ -O2; driver.cpp with -I../Src)"
tools/sandbox.sh "$ID" -- sh -c "cd $D && rm -f *.o driver res1.new && { \
  g++ -O2 -I/work/shim -I../Src -c driver.cpp -o driver.o && \
  g++ -O2 -I/work/shim -c ../Src/bsslr.cpp -o bsslr.o && \
  g++ -O2 -I/work/shim -c ../Src/mathur.cpp -o mathur.o && \
  g++ -O2 -I/work/shim -c ../Src/mbsslr.cpp -o mbsslr.o && \
  g++ -O2 -I/work/shim -c ../Src/mcnr.cpp -o mcnr.o && \
  g++ -O2 -I/work/shim -c ../Src/mmathur.cpp -o mmathur.o && \
  g++ -O2 -o driver driver.o bsslr.o mathur.o mbsslr.o mcnr.o mmathur.o; } > /work/build.log 2>&1; echo build_exit=\$?; cat /work/build.log; ls -l driver" \
  > "$E/build.log" 2>&1
cat "$E/build.log"

echo "== manifest post (after the build)"
python3 -I tools/verify_sources.py manifest "$SCR/pre" > "$SCR/manifest.post"
cp "$SCR/manifest.post" "$E/manifest.post"

echo "== record the patch (build-only: the only patch is the shim outside the archive; exit 0). record reads result.json,"
echo "   so a placeholder is written first when absent; the full result.json is written from the record by hand, keeping its patch key"
test -f "$root/reports/$ID/result.json" || echo "{}" > "$root/reports/$ID/result.json"
python3 -I tools/verify_sources.py record --repo . --id "$ID" --pre "$SCR/manifest.pre" --mid "$SCR/manifest.mid" --post "$SCR/manifest.post" \
  --command "g++ -O2 -I/work/shim -I../Src -c driver.cpp -o driver.o" \
  --command "g++ -O2 -I/work/shim -c ../Src/bsslr.cpp -o bsslr.o" \
  --command "g++ -O2 -I/work/shim -c ../Src/mathur.cpp -o mathur.o" \
  --command "g++ -O2 -I/work/shim -c ../Src/mbsslr.cpp -o mbsslr.o" \
  --command "g++ -O2 -I/work/shim -c ../Src/mcnr.cpp -o mcnr.o" \
  --command "g++ -O2 -I/work/shim -c ../Src/mmathur.cpp -o mmathur.o" \
  --command "g++ -O2 -o driver driver.o bsslr.o mathur.o mbsslr.o mcnr.o mmathur.o"
echo "record_exit=$?"

echo "== run: the archive's driver on data1 (the Makefile's res1 rule), output compared with the shipped res1"
tools/sandbox.sh "$ID" -- sh -c "cd $D && ./driver < data1 > /work/Res1 2>/work/run.err; echo driver_exit=\$?; cat /work/run.err; \
  diff /work/Res1 res1 > /work/diff.txt; echo diff_exit=\$?; head -c 4000 /work/diff.txt" \
  > "$E/driver-run.log" 2>&1
cat "$E/driver-run.log"
tools/sandbox.sh "$ID" -- sh -c "cat /work/Res1" > "$E/Res1"
tools/sandbox.sh "$ID" -- sh -c "cat $D/res1" > "$E/res1.shipped"
sha256sum "$E/res1.shipped" | cut -d' ' -f1 > "$E/res1.shipped.sha256"

echo "== values: column 4 at x = 19.790 (the claim)"
python3 -I - "$E/Res1" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^\s*19\.790\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$", text, re.M)
if m:
    print(f"VALUE col4_x19790 {m.group(4)}")
else:
    print("row x = 19.790 not found")
PY
