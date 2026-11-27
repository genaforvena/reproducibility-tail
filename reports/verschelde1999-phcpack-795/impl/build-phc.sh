#!/bin/sh
# Build PHCpack's GNAT tree (the authors' GNAT/ dirs, after their own `make links`) into the directory $1 (phc inside).
set -e
OUT=${1:-/work/phc}
R=/work/root
export PATH=$R/usr/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=$R/usr/lib/x86_64-linux-gnu
cd /work/tree/GNAT
INC=""
for d in $(find . -type d | sort); do
  ls "$d"/*.ads >/dev/null 2>&1 && INC="$INC -aI/work/tree/GNAT/${d#./}"
done
mkdir -p "$OUT" && cd "$OUT"
gnatmake -j2 -q -O1 -B$R/usr/libexec/gcc/x86_64-linux-gnu/13/ -B$R/usr/lib/gcc/x86_64-linux-gnu/13/ $INC -aO"$OUT" /work/tree/GNAT/Main/dispatch.adb -o "$OUT/phc"
