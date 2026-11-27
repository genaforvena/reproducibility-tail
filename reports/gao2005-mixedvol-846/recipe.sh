#!/usr/bin/env bash
# Rebuilds the rerun record for gao2005-mixedvol-846 (TOMS 846, MixedVol: mixed volume of a polynomial system, C++).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes source files
# (tools/verify_sources.py) and parses text output.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 846.zip (sha256 checked against the queue entry),
# unzipped to /work/tree (top directory 846/). g++ is on the sandbox's /usr/bin.
#
# Original attempt (G1): the authors' Doc/makefile (the manual says to run 'build' in the main directory; the archive
# has no such script). Run from the main directory it fails (no rule for MixedVolDriver.o, whose source is in Src/);
# run from Src/ it fails at MixedVolDriver.cpp:209 (INT_MAX not declared with the current g++). Both logs are kept.
#
# Build (build-only): the makefile's own commands (g++ -c -O2 -ansi, then the link), unedited sources, with ONE
# compiler flag added, '-include climits', which supplies the declaration the source lacks. The link line and the
# object paths are the makefile's (objects in PolyReader/ are linked by their paths here). Nothing in the unpacked
# tree is edited; only .o files and the binary are produced.
#
# Claim: the manual's worked example (Doc/userman.tex, 'Call Sequence and Output'): the three-polynomial system typed
# into MyPolynomials outside the archive, run as 'mixedvol -p MyPolynomials', must print a mixed volume of 119.
# Tolerance 0 (integer invariant, fixed in the queue entry). Two passes (G3).
set -uo pipefail
ID=gao2005-mixedvol-846
URL=https://netlib.org/toms/846.zip
SHA=c1a8045a45878744ac58078c696f54b1166d8c3a7fdca00ff0a66c41bca9acdb
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 846.zip (sha256 checked), unzipped to /work/tree"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/846.zip '$URL'; echo '$SHA  /work/846.zip' | sha256sum -c -; rm -rf /work/tree && mkdir /work/tree && cd /work/tree && unzip -q /work/846.zip; echo unpacked" > "$E/fetch-toolchain.log" 2>&1 || { echo "FETCH-FAILED"; tail -20 "$E/fetch-toolchain.log"; exit 1; }
tail -1 "$E/fetch-toolchain.log"

echo "== unpack listing (manifest pre: the authors' files as shipped, before any build)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/tree && find . -type f | sort" > "$E/unpack.log" 2>&1
wc -l < "$E/unpack.log"
python3 tools/verify_sources.py manifest "$SCRATCH/tree" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"

echo "== original attempt (G1): the authors' Doc/makefile, from the main directory and from Src/, in a copy"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && cp -r /work/tree /work/orig && cd /work/orig/846 && make -f Doc/makefile mixedvol > /work/make-root.log 2>&1; echo make_root_rc=\$?; cat /work/make-root.log" > "$E/original-attempt-root.log" 2>&1
tools/sandbox.sh "$ID" -- sh -c "cd /work/orig/846/Src && make -f ../Doc/makefile mixedvol > /work/make-src.log 2>&1; echo make_src_rc=\$?; cat /work/make-src.log" > "$E/original-attempt-src.log" 2>&1
grep -E 'make_(root|src)_rc=' "$E/original-attempt-root.log" "$E/original-attempt-src.log"
grep -m2 -E 'No rule|error:' "$E/original-attempt-root.log" "$E/original-attempt-src.log"

echo "== the manual's input, typed from Doc/userman.tex and written outside the archive (scratch input directory)"
tools/sandbox.sh "$ID" -- sh -c "mkdir -p /work/input && printf '%s\n' '{' '(x1^2+x2^2+x3^2-1)*(x1-0.5)*(x2-x1^2);' '(x1^2+x2^2+x3^2-1)*(x2-0.5)*(x3-x1^3);' '(x1^2+x2^2+x3^2-1)*(x3-0.5)*(x3-x1^2)*(x2-x1^2);' '}' > /work/input/MyPolynomials && cat /work/input/MyPolynomials"

echo "== pass 1 (G1 patched build): copy of the unpacked tree, manifest (mid), then the makefile's commands with -include climits"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && cp -r /work/tree /work/build && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build/846 && (cd Src && g++ -c -O2 -ansi -include climits MixedVolDriver.cpp -o MixedVolDriver.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/GenericPolynomial.cpp -o PolyReader/GenericPolynomial.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/PolynomialException.cpp -o PolyReader/PolynomialException.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/ExpandedPolynomial.cpp -o PolyReader/ExpandedPolynomial.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/PolynomialSystemReader.cpp -o PolyReader/PolynomialSystemReader.o) && (cd Src && g++ -O2 MixedVolDriver.o PolyReader/GenericPolynomial.o PolyReader/PolynomialException.o PolyReader/ExpandedPolynomial.o PolyReader/PolynomialSystemReader.o -o /work/build/mixedvol); echo build_exit=\$?" > "$E/pass1-build.log" 2>&1
grep -E 'build_exit=|error' "$E/pass1-build.log" | head -5
echo "== manifest (post): after the build"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== pass 1 run: the manual's example"
tools/sandbox.sh "$ID" -- sh -c "cd /work/input && timeout 600 /work/build/mixedvol -p MyPolynomials > /work/out-pass1.txt 2>&1; echo run_exit=\$?" > "$E/pass1-run.log" 2>&1
grep -E '^run_exit=' "$E/pass1-run.log"
cp "$SCRATCH/out-pass1.txt" "$E/pass1-output.txt"; cat "$E/pass1-output.txt"

echo "== pass 2: clean copy of the unpacked tree, rebuilt with the same commands, run"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/pass2 && cp -r /work/tree /work/pass2 && cd /work/pass2/846 && (cd Src && g++ -c -O2 -ansi -include climits MixedVolDriver.cpp -o MixedVolDriver.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/GenericPolynomial.cpp -o PolyReader/GenericPolynomial.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/PolynomialException.cpp -o PolyReader/PolynomialException.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/ExpandedPolynomial.cpp -o PolyReader/ExpandedPolynomial.o) && (cd Src && g++ -c -O2 -ansi -include climits PolyReader/PolynomialSystemReader.cpp -o PolyReader/PolynomialSystemReader.o) && (cd Src && g++ -O2 MixedVolDriver.o PolyReader/GenericPolynomial.o PolyReader/PolynomialException.o PolyReader/ExpandedPolynomial.o PolyReader/PolynomialSystemReader.o -o /work/pass2/mixedvol-bin) && cd /work/input && timeout 600 /work/pass2/mixedvol-bin -p MyPolynomials > /work/out-pass2.txt 2>&1; echo rc=\$?" > "$E/pass2-run.log" 2>&1
grep -E '^rc=' "$E/pass2-run.log"
cp "$SCRATCH/out-pass2.txt" "$E/pass2-output.txt"; cat "$E/pass2-output.txt"

echo "== reference: the manual's stated value (Doc/userman.tex)"
tools/sandbox.sh "$ID" -- sh -c "grep -n 'namely 119' /work/tree/846/Doc/userman.tex" > "$E/reference-block.txt" 2>&1
cat "$E/reference-block.txt"

echo "== values: the mixed volume printed by each pass"
python3 -I - "$E/pass1-output.txt" "$E/pass2-output.txt" <<'PY' > "$E/values.txt" || true
import re, sys
def mv(path):
    m = re.search(r"mixed volume of this system is\s+(-?\d+)", open(path).read())
    return int(m.group(1)) if m else None
p1 = mv(sys.argv[1]); p2 = mv(sys.argv[2])
print("pass1 mixed volume", p1)
print("pass2 mixed volume", p2)
print("agree", p1 == p2)
PY
cat "$E/values.txt"

echo "== build-only record (exit 0 means build-only; only once result.json exists)"
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command '(cd Src && g++ -c -O2 -ansi -include climits MixedVolDriver.cpp -o MixedVolDriver.o)' \
    --command '(cd Src && g++ -c -O2 -ansi -include climits PolyReader/GenericPolynomial.cpp -o PolyReader/GenericPolynomial.o)' \
    --command '(cd Src && g++ -c -O2 -ansi -include climits PolyReader/PolynomialException.cpp -o PolyReader/PolynomialException.o)' \
    --command '(cd Src && g++ -c -O2 -ansi -include climits PolyReader/ExpandedPolynomial.cpp -o PolyReader/ExpandedPolynomial.o)' \
    --command '(cd Src && g++ -c -O2 -ansi -include climits PolyReader/PolynomialSystemReader.cpp -o PolyReader/PolynomialSystemReader.o)' \
    --command '(cd Src && g++ -O2 MixedVolDriver.o PolyReader/GenericPolynomial.o PolyReader/PolynomialException.o PolyReader/ExpandedPolynomial.o PolyReader/PolynomialSystemReader.o -o /work/build/mixedvol)' > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
N=$(python3 -I - "$E/pass1-output.txt" <<'PY'
import re, sys
m = re.search(r"mixed volume of this system is\s+(-?\d+)", open(sys.argv[1]).read())
print(m.group(1) if m else "nan")
PY
)
echo "VALUE mixed volume of the manual's 3-polynomial system (manual: 119) ${N}"
