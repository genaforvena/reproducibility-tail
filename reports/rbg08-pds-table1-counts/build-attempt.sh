#!/bin/bash
# Runs inside the sandbox (/work = paper scratch). No network.
set -euo pipefail
cd /work
PREFIX=/work/local
mkdir -p $PREFIX/lib $PREFIX/include $PREFIX/bin
export PATH=/work/bin:$PATH FC=gfortran F77=gfortran
cosmdist_pinned() { tar -x -f cosmdist-pinned.tgz; }
if [ ! -f /work/.gsl-done ]; then
  tar -x -f gsl-1.10.tar.gz
  (cd gsl-1.10 && ./configure --prefix=$PREFIX > /work/log-gsl-configure.txt 2>&1 && make -j2 > /work/log-gsl-make.txt 2>&1 && make install >> /work/log-gsl-make.txt 2>&1)
  touch /work/.gsl-done
fi
echo "gsl ok"
rm -rf /work/broukema-cosmdist-*
cosmdist_pinned
COS=$(ls -d /work/broukema-cosmdist-* | head -n1); echo "cosmdist dir=$COS"
(cd "$COS" && ./configure --prefix=$PREFIX LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" > /work/log-cosmdist-configure.txt 2>&1 && make MAKEINFO=true CFLAGS="-g -O2 -fcommon -I/work/local/include -L/work/local/lib" FCFLAGS="-g -O2 -fcommon" > /work/log-cosmdist-make.txt 2>&1 && make MAKEINFO=true CFLAGS="-g -O2 -fcommon -I/work/local/include -L/work/local/lib" FCFLAGS="-g -O2 -fcommon" install >> /work/log-cosmdist-make.txt 2>&1)
echo "cosmdist ok"
cd /work/src/circles-0.3.2.1
for d in $(find . -name Makefile.in -printf "%h\n"); do cp -f /usr/share/automake-1.16/depcomp "$d/depcomp"; done
./configure LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" FFLAGS="-fcheck=bounds -Wall" > /work/log-circles-configure.txt 2>&1
make MAKEINFO=true clean >/dev/null 2>&1 || true; make MAKEINFO=true CFLAGS="-g -O2 -fcommon -I/work/local/include" FFLAGS="-fcheck=bounds -Wall -fcommon" > /work/log-circles-make.txt 2>&1
echo "circles built"
ls -l /work/src/circles-0.3.2.1/circles
