#!/usr/bin/env bash
# Canonical rerun for waki2008-sparsepop-883 (TOMS 883 SparsePOP, POP.objValue of example1.gms at relaxOrder 3).
# Fetch (network, sha256-checked): the archive 883.zip from netlib, SeDuMi 1.3 master (GPL) from GitHub,
# micromamba and Octave 10.3 from conda-forge. Everything else runs inside tools/sandbox.sh without network.
# Basis: patched. The authors' SparsePOP200 code runs unmodified; the patches are the environment only:
#  - SeDuMi installer: its computer-type string and its mkoctfile call (the conda Octave's compiler is not
#    at its build path), the openblas include flag; a f77blas.h shim (blasint, BLASFUNC) for the ATLAS header;
#  - pkg.m (no package list, so ver() finds no Symbolic Math Toolbox) and findstr.m (removed in Octave 10).
# Log: evidence/recipe-run.log (LOG env overrides). evidence/original-attempt.log is the first attempt, not overwritten.
set -uo pipefail
ID=waki2008-sparsepop-883
ZIP_SHA=2c05deedb393a2959240791cf94d27ebd8e3617eb7bed620415d31b8b2b4123e
SEDUMI_SHA=13ca113297c89d34eab132d45f92db68753fe92a8751452aa88262064033a119
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
W=/mnt/mishe-scratch/reproducibility-tail/$ID
rm -rf "$W"; mkdir -p "$W"
cd "$root"
MM=https://micro.mamba.pm/api/micromamba/linux-64/latest
LOG="${LOG:-$root/reports/$ID/evidence/recipe-run.log}"
mkdir -p "$(dirname "$LOG")"
exec > >(tee "$LOG") 2>&1
cp "$here/impl/"* "$W/"
echo "== fetch: archive 883.zip, SeDuMi master, micromamba (sha256 checked where pinned)"
tools/sandbox.sh --fetch "$ID" -- sh -c "curl -fsSL -o /work/883.zip https://netlib.org/toms/883.zip && curl -fsSL -o /work/sedumi.zip https://github.com/sqlp/sedumi/archive/refs/heads/master.zip && curl -fsSL -o /work/mm.tar.bz2 '$MM' && mkdir -p /work/mm && tar -xjf /work/mm.tar.bz2 -C /work/mm bin/micromamba" || { echo "FETCH-FAILED"; exit 1; }
tools/sandbox.sh "$ID" -- sh -c "echo '$ZIP_SHA  /work/883.zip' | sha256sum -c - && echo '$SEDUMI_SHA  /work/sedumi.zip' | sha256sum -c -" || { echo "SHA-FAILED"; exit 1; }
echo "== fetch: Octave 10.3 (conda-forge)"
tools/sandbox.sh --fetch "$ID" -- sh -c "/work/mm/bin/micromamba create -y -r /work/mm/root -p /work/octave -c conda-forge --override-channels octave" || { echo "OCTAVE-INSTALL-FAILED"; exit 1; }
echo "== unpack (authors' archive, unmodified) and SeDuMi"
tools/sandbox.sh "$ID" -- sh -c "cd /work && python3 -m zipfile -e 883.zip pre && python3 -m zipfile -e sedumi.zip sedumi-src && find pre -name '*.m' | wc -l" || { echo "UNPACK-FAILED"; exit 1; }
echo "== build SeDuMi (dependency; environment edits to its installer only)"
tools/sandbox.sh "$ID" -- sh -c '
export PATH=/work/octave/bin:$PATH CC=/usr/bin/gcc CXX=/usr/bin/g++
cd /work/sedumi-src/sedumi-master
sed -i "s/^COMPUTER = computer ();/COMPUTER = \"x86_64-pc-linux-gnu\";/" install_sedumi.m
sed -i "s|        mkoctfile(flags{:}, files{:}, libs{:});|        [st,out] = system([\"mkoctfile \" strjoin(flags,\" \") \" \" strjoin(files,\" \") \" \" strjoin(libs,\" \")]); if st, disp(out), error(\"mkoctfile failed\"), end|" install_sedumi.m
sed -i "s|flags{end+1} = \x27-I/usr/include/openblas\x27;|flags{end+1} = \x27-I/work/shim/include -I/usr/include/x86_64-linux-gnu\x27; libs{end+1} = \x27-L/work/octave/lib -lblas\x27;|" install_sedumi.m
mkdir -p /work/shim/include && cp /work/f77blas.h /work/shim/include/ && cp /work/pkg.m /work/findstr.m /work/shim/
M=/work/octave/share/octave/10.3.0/m
cat > /work/inst.m <<EOM
addpath("$M/strings");
addpath("$M/general");
addpath("$M/elfun");
addpath("$M/set");
addpath("$M/linear-algebra");
addpath("$M/specfun");
addpath("$M/sparse");
addpath("$M/miscellaneous");
cd /work/sedumi-src/sedumi-master
install_sedumi("-rebuild", "mkoctfile --mex -O2 -DOCTAVE %s");
EOM
cd /work && octave-cli --no-gui --quiet /work/inst.m > /work/sedumi-install.log 2>&1; grep -q "successfully installed" /work/sedumi-install.log' || { echo "SEDUMI-BUILD-FAILED"; exit 1; }
echo "== run: authors' sparsePOP on example1.gms (relaxOrder 3, SeDuMi eps 1e-9), twice (G3)"
tools/sandbox.sh "$ID" -- sh -c '
export PATH=/work/octave/bin:$PATH
mkdir -p /work/run && cp /work/pre/883/Doc/example1.gms /work/run/ && cp /work/run_sparsepop.m /work/run/
for i in 1 2; do echo "== driver run $i"; octave-cli --no-gui --quiet /work/run/run_sparsepop.m > /work/run/run$i.log 2>&1; grep -E "^VALUE|^SDPobjValue" /work/run/run$i.log || { echo "NO-VALUE"; exit 1; }; done'

echo "== done"
