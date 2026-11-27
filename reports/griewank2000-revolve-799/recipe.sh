#!/usr/bin/env bash
# Rebuilds and reruns the record for griewank2000-revolve-799 (ACM TOMS Algorithm 799, Revolve, checkpointing for
# reverse-mode AD, C version). Everything that runs the authors' code goes through tools/sandbox.sh; the host only
# hashes, splits and parses text (tools/verify_sources.py never executes anything).
#
# Fetch (network, inside the sandbox): netlib TOMS 799.gz (sha256 checked against the queue entry), gunzipped to
# /work/pre/799.txt (sha256 53a9259e...).
#
# Unpack: the archive's own shell archive (cut from its '#! /bin/sh' line) is run with sh into /work/orig/tree.
# The authors' C makefile (Doc/makefile_c) is then run unedited in a copy of the tree (G1 original attempt). The
# archive's unpacking expands the makefile's $(CC) and $(LIBS) variables inside an unquoted here-document, so the
# makefile as unpacked has no compiler; the attempt FAILS and its log is kept.
#
# Build (basis patched, kind build-only): no authors' file is edited. The build runs the makefile's own compile
# and link lines by hand in the unpacked tree: gcc -c -O3 src.c, gcc -c -O3 driver.c, gcc -o driver src.o driver.o -lm.
# The three manifests (pre, mid, post) of the authors' tree prove that no source changed before or during the build.
#
# Run: the driver reads STEPS SNAPS INFO from stdin (data: 14 3 3) and prints the action trace; it is compared with
# the shipped C/Drivers/res (evidence/shipped-res.txt).
#
# Claim: advances, takeshots, commands (exact) and slowdown factor (absolute tolerance 5e-5), from the queue entry.
set -uo pipefail
ID=griewank2000-revolve-799
URL=https://netlib.org/toms/799.gz
SHA=8587175531d158f0c6f95f3bd507f149f04bbe0f1928810819c913d2c773a657
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
TREE="$SCRATCH/orig/tree"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 799.gz (sha256 checked), gunzipped"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/799.gz '$URL'; echo '$SHA  /work/799.gz' | sha256sum -c -; gzip -dc /work/799.gz > /work/pre/799.txt" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack the authors' shell archive into /work/orig/tree"
tools/sandbox.sh "$ID" -- sh -c "set -e; rm -rf /work/orig && mkdir -p /work/orig/tree && cd /work/orig/tree && \
  sed -n '/^#! \/bin\/sh/,\$p' /work/pre/799.txt > /work/orig/unpack.sh && sh /work/orig/unpack.sh && ls -R /work/orig/tree" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
python3 tools/verify_sources.py manifest "$TREE" > "$E/manifest.pre"
echo "manifest.pre: $(wc -l < "$E/manifest.pre") source files"

echo "== original attempt (G1): the authors' Doc/makefile_c run unedited with make, in a copy of the tree"
tools/sandbox.sh "$ID" -- sh -c "set -e; rm -rf /work/orig/orig-make && cp -r /work/orig/tree /work/orig/orig-make && cd /work/orig/orig-make && \
  cp C/Src/src.c C/Src/revolve.h C/Drivers/driver.c C/Drivers/data Doc/ && cd Doc && make -f makefile_c; echo make_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== build (patched, build-only): compile and link with the makefile's own lines; no authors' file is edited"
python3 tools/verify_sources.py manifest "$TREE" > "$E/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "set -e; cd /work/orig/tree/C/Src && gcc -c -O3 src.c; cd /work/orig/tree/C/Drivers && gcc -c -O3 -I/work/orig/tree/C/Src driver.c; cd /work/orig/tree/C/Drivers && gcc -o driver /work/orig/tree/C/Src/src.o driver.o -lm; echo build_exit=\$?" > "$E/build.log" 2>&1
cat "$E/build.log"
python3 tools/verify_sources.py manifest "$TREE" > "$E/manifest.post"

echo "== run the built driver (stdin: data), keep its stdout"
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/tree/C/Drivers && ./driver < data; echo run_exit=\$?" > "$E/run-C.txt" 2>&1
cat "$E/run-C.txt" | tail -12
cp "$SCRATCH/orig/tree/C/Drivers/res" "$E/shipped-res.txt" 2>/dev/null

echo "== values: advances, takeshots, commands, slowdown factor (host parse of text)"
python3 -I - "$E" "$root/queue/$ID.json" <<'PY' | tee "$E/values.txt"
import json, pathlib, re, sys
e = pathlib.Path(sys.argv[1])
claim = json.load(open(sys.argv[2]))["claim"]["values"]
txt = (e / "run-C.txt").read_text()
def num(label):
    m = re.search(label + r"\s*:?\s*(-?[0-9.]+)", txt)
    if not m: raise SystemExit(f"{label} not found")
    return float(m.group(1))
vals = {
  "revolve steps=14 snaps=3 advances": num(r"advances"),
  "revolve steps=14 snaps=3 takeshots": num(r"takeshots"),
  "revolve steps=14 snaps=3 commands": num(r"commands"),
  "revolve steps=14 snaps=3 slowdown factor": num(r"slowdown factor"),
}
for c in claim:
    d = abs(vals[c["name"]] - c["paper"])
    print(f"{c['name']}: ours {vals[c['name']]!r} paper {c['paper']!r} |diff| {d:.3g} tol {c['tol_abs']} ok={d <= c['tol_abs']}")
for c in claim:
    print(f"VALUE {c['name']} {vals[c['name']]!r}")
PY
echo "== record the build-only patch proof (verify_sources record)"
python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$E/manifest.pre" --mid "$E/manifest.mid" --post "$E/manifest.post" \
  --command 'cd /work/orig/tree/C/Src && gcc -c -O3 src.c' \
  --command 'cd /work/orig/tree/C/Drivers && gcc -c -O3 -I/work/orig/tree/C/Src driver.c' \
  --command 'cd /work/orig/tree/C/Drivers && gcc -o driver /work/orig/tree/C/Src/src.o driver.o -lm'
echo "== done; scratch kept at $SCRATCH (delete after the record is committed)"
