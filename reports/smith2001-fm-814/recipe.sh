#!/usr/bin/env bash
# Rebuilds the rerun record for smith2001-fm-814 (TOMS 814, Smith, FM package for multiple-precision arithmetic, Fortran 90).
# Everything that runs the authors' code goes through tools/sandbox.sh. The host only hashes and parses text.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 814.gz (sha256 checked against the queue entry),
# gunzipped to /work/pre/814.txt; gfortran (conda-forge, via micromamba) into /work/env if missing.
#
# Unpack: the shar is the part of 814.txt from its '#! /bin/sh' line; it is run with sh into /work/tree (its heredocs
# are quoted, so the files are written unedited). The authors' files are Fortran90/Sp/Src/{FMSAVE,FMZM90,FM}.f90 and
# Fortran90/Sp/Drivers/{SampleFM.f90,SAMPLE.CHK}.
#
# Original attempt (G1): the ReadMe's build as shipped, with its own 'f90' command (the ReadMe's compiler wrapper).
# The host has no f90 and the sandbox has none; the build stops at the first command. Log: evidence/original-attempt.log.
#
# Build (basis patched, build-only): the ReadMe's five commands, unchanged, with 'f90' provided by a one-line
# wrapper script that calls gfortran (a compiler alias, as for miminis1995-eigassign-747). No source file is edited;
# manifests pre, mid and post bracket the commands. Flags are the ReadMe's (-c, -O on FM.f90, -f free).
#
# Claim: Zeta(3) printed by SampleFM (sample 3, Gosper's series at 60 digits) against 1.2020569031595942 (the shipped
# SAMPLE.CHK value rounded to double), absolute tolerance 1e-15 (fixed in the queue entry).
set -uo pipefail
ID=smith2001-fm-814
URL=https://netlib.org/toms/814.gz
SHA=033afcb275570c5fdfd47c18e717523dd5c3b70b740ef2ad0e6daac24a25da22
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
PATHSET='export PATH=/work/alias:/work/env/bin:$PATH'
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 814.gz (sha256 checked), shar extracted; gfortran into /work/env if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre && cd /work/pre && curl -fsSL -o /work/814.gz '$URL'; echo '$SHA  /work/814.gz' | sha256sum -c -; gzip -dc /work/814.gz > /work/pre/814.txt; \
  test -x /work/env/bin/gfortran || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; tar -xjf /work/mm.tar.bz2 -C /work bin/micromamba; /work/bin/micromamba create -y -q -p /work/env -r /work/mamba -c conda-forge gfortran; }" || { echo "FETCH-FAILED"; exit 1; }

echo "== unpack: the shar from 814.txt, run with sh into /work/tree (manifest pre)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/tree /work/shar && mkdir /work/tree && sed -n '/^#! \/bin\/sh/,\$p' /work/pre/814.txt > /work/shar.sh && cd /work/tree && sh /work/shar.sh >/dev/null 2>&1; find . -type f | sort && sha256sum Fortran90/Sp/Src/*.f90 Fortran90/Sp/Drivers/SampleFM.f90 Fortran90/Sp/Drivers/SAMPLE.CHK" > "$E/unpack.log" 2>&1
cat "$E/unpack.log"
rm -rf "$SCRATCH/pre-flat" && mkdir -p "$SCRATCH/pre-flat" && cp "$SCRATCH/tree/Fortran90/Sp/Src/"*.f90 "$SCRATCH/tree/Fortran90/Sp/Drivers/SampleFM.f90" "$SCRATCH/pre-flat/"
# manifest pre is taken over the same flat layout the build uses (the mid manifest is over the flat build directory)
python3 tools/verify_sources.py manifest "$SCRATCH/pre-flat" > "$SCRATCH/manifest.pre"
wc -l < "$SCRATCH/manifest.pre"
mkdir -p "$E/reference" && cp "$SCRATCH/tree/Fortran90/Sp/Drivers/SAMPLE.CHK" "$E/reference/SAMPLE.CHK"

echo "== original attempt (G1): the ReadMe's f90 commands as shipped (no wrapper on PATH)"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && cp -r /work/tree /work/orig && cd /work/orig/Fortran90/Sp/Src && export PATH=/work/env/bin:/usr/bin:/bin && f90 FMSAVE.f90 -c -f free -o FMSAVE.o; echo build_exit=\$?" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== wrapper: f90 -> gfortran (outside the tree; no source touched)"
mkdir -p "$SCRATCH/alias" && cat > "$SCRATCH/alias/f90" <<'WRAP'
#!/bin/sh
# ReadMe-style f90 driver for gfortran: '-f free' becomes -ffree-form; everything else is passed through.
args=
skip=0
for x in "$@"; do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  if [ "$x" = "-f" ]; then args="$args -ffree-form"; skip=1; continue; fi
  args="$args \"$x\""
done
eval exec gfortran $args
WRAP
chmod +x "$SCRATCH/alias/f90"
tools/sandbox.sh "$ID" -- sh -c "$PATHSET && command -v f90 && f90 --version 2>/dev/null | head -1; gfortran --version | head -1"

echo "== build: the Src and driver files copied flat into one build directory (no edit; the ReadMe builds them in one place), manifest mid before the build commands"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/build && mkdir -p /work/build && cp /work/tree/Fortran90/Sp/Src/*.f90 /work/tree/Fortran90/Sp/Drivers/SampleFM.f90 /work/build/ && echo copied"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.mid"
wc -l < "$SCRATCH/manifest.mid"
tools/sandbox.sh "$ID" -- sh -c "export PATH=/work/alias:/work/env/bin:\$PATH && cd /work/build && f90 FMSAVE.f90 -c -f free -o FMSAVE.o && f90 FMZM90.f90 -c -f free -o FMZM90.o && f90 FM.f90 -O -c -f free -o FM.o && f90 SampleFM.f90 -c -f free -o SampleFM.o && f90 SampleFM.o FMSAVE.o FMZM90.o FM.o -o SampleFM; echo build_exit=\$?" > "$E/build.log" 2>&1
cat "$E/build.log"
python3 tools/verify_sources.py manifest "$SCRATCH/build" > "$SCRATCH/manifest.post"
wc -l < "$SCRATCH/manifest.post"

echo "== run: SampleFM on the sandbox (writes SAMPLE.LOG)"
tools/sandbox.sh "$ID" -- sh -c "cd /work/build && ./SampleFM > /work/run.out 2>&1; echo run_exit=\$?; cat /work/run.out | tail -3; cp SAMPLE.LOG /work/SAMPLE.LOG 2>/dev/null; cp /work/run.out /work/run-out.txt" > "$E/runs.log" 2>&1
cat "$E/runs.log"
cp "$SCRATCH/build/SAMPLE.LOG" "$E/SAMPLE.LOG"

echo "== values: Zeta(3) from the program's log (host parse of text)"
python3 -I - "$E" <<'PY' | tee "$E/values.txt"
import re, sys, pathlib
e = pathlib.Path(sys.argv[1])
log = (e / "SAMPLE.LOG").read_text()
m = re.search(r"Zeta\(3\)\s*=\s*([0-9.]+)", log)
if not m:
    raise SystemExit("no Zeta(3) line in SAMPLE.LOG")
v = float(m.group(1))
print(f"Zeta(3) digits printed: {m.group(1)[:40]}...")
print(f"VALUE Zeta(3) sample 3 {v!r}")
last = log.strip().splitlines()[-1]
print("last line:", last)
PY

echo "== manifests into the report and build-only record (exit 0 means build-only)"
cp "$SCRATCH/manifest.pre" "$SCRATCH/manifest.mid" "$SCRATCH/manifest.post" "$E/" 2>/dev/null
if [ -f reports/$ID/result.json ]; then
  python3 tools/verify_sources.py record --repo . --id "$ID" --pre "$SCRATCH/manifest.pre" --mid "$SCRATCH/manifest.mid" --post "$SCRATCH/manifest.post" \
    --command 'f90 FMSAVE.f90 -c -f free -o FMSAVE.o' --command 'f90 FMZM90.f90 -c -f free -o FMZM90.o' --command 'f90 FM.f90 -O -c -f free -o FM.o' \
    --command 'f90 SampleFM.f90 -c -f free -o SampleFM.o' --command 'f90 SampleFM.o FMSAVE.o FMZM90.o FM.o -o SampleFM' > "$E/record.log" 2>&1
  echo "record_exit=$?"
  cat "$E/record.log"
else
  echo "record skipped: reports/$ID/result.json not yet written"
fi
