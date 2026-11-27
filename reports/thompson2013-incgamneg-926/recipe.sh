#!/usr/bin/env bash
# Rebuilds the rerun record for thompson2013-incgamneg-926 (ACM TOMS 926, incomplete gamma functions with negative
# arguments, Fortran 90, Ian Thompson). Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 926.zip, sha256 checked against the queue entry's
# code.commit, unpacked to /work/pre/926. gfortran (conda-forge, micromamba) into /work/fortran if missing.
#
# Build and run (basis original): the authors' documented flags from Doc/manual.tex for gfortran,
# `gfortran -c -std=f2003 -cpp in_gamma_sequence.f90`, then the driver in_gamma_test.f90 against that module. No source
# file is edited. The driver's menu is answered by `printf "2\n1\n"`: menu choice 2 (compare with the shipped Maple data),
# then summary mode 1. The output is compared with the shipped Fortran/Driver/RES.
set -uo pipefail
ID=thompson2013-incgamneg-926
URL=https://netlib.org/toms/926.zip
SHA=673f9f6ef6a8f7b563d8869d4dff95bda88c246cd08eac15ca66474afda2b3fe
G=/work/fortran/bin/x86_64-conda-linux-gnu-gfortran
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1

echo "== fetch: 926.zip (sha256 checked), unpacked to /work/pre/926; gfortran (conda-forge) if missing"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; rm -rf /work/pre && mkdir -p /work/pre && curl -fsSL -o /work/926.zip '$URL'; \
  echo \"sha256 \$(sha256sum /work/926.zip | cut -d' ' -f1) expected $SHA\"; \
  echo \"$SHA  /work/926.zip\" | sha256sum -c -; \
  python3 -c 'import zipfile;zipfile.ZipFile(\"/work/926.zip\").extractall(\"/work/pre\")'; \
  test -x $G || { curl -fsSL -o /work/mm.tar.bz2 https://micro.mamba.pm/api/micromamba/linux-64/latest; mkdir -p /work/bin; tar -xjf /work/mm.tar.bz2 -C /work/bin --strip-components=1 bin/micromamba; MAMBA_ROOT_PREFIX=/work/mamba /work/bin/micromamba create -y -q -p /work/fortran -c conda-forge gfortran_linux-64; }; \
  mkdir -p /work/bin && ln -sf $G /work/bin/gfortran && gfortran --version | head -1" > "$E/fetch.log" 2>&1 || { echo "FETCH-FAILED"; cat "$E/fetch.log"; exit 1; }
cat "$E/fetch.log"

echo "== original (basis original): the authors' documented gfortran flags, the shipped driver, menu answered as documented"
tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/orig && mkdir /work/orig && cp -a /work/pre/926/Fortran/. /work/orig/ && cd /work/orig/Src && gfortran -c -std=f2003 -cpp in_gamma_sequence.f90 && echo src_ok && cd ../Driver && gfortran -std=f2003 -cpp -I../Src in_gamma_test.f90 ../Src/in_gamma_sequence.o -o drv && echo drv_ok && printf '2\n1\n' | timeout 900 ./drv > run.out 2>&1; echo run_exit=\$?; echo ---; cat run.out; echo ---; cat RES" > "$E/original-attempt.log" 2>&1
cat "$E/original-attempt.log"

echo "== values"
python3 -I - "$E/original-attempt.log" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
run = text.split("---")[1] if text.count("---") >= 2 else text
m53 = re.search(r"53 correct digits :\s+(\d+) occurrences", run)
mt = re.search(r"A total of\s+(\d+) evaluations were performed", run)
if not m53 or not mt:
    print("no summary printed")
    sys.exit(0)
print(f"VALUE OCCURRENCES_53_DIGITS {m53.group(1)}")
print(f"VALUE TOTAL_EVALUATIONS {mt.group(1)}")
PY
