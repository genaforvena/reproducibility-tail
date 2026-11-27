#!/bin/sh
# Build shim for TOMS 439 (boland1972-gauss-simpson-439). The archive's Drivers/Makefile compiles `src.f`
# from the Drivers directory, but the archive ships src.f in ../Src. This shim maps that one argument to
# its path in the unpacked archive and then runs the gfortran installed in the sandbox scratch (micromamba,
# conda-forge). It edits no archive file: it only chooses which existing file the compiler reads.
set -e
n=$#
i=0
while [ "$i" -lt "$n" ]; do
  a=$1; shift
  case "$a" in
    src.f) a=/work/pre/Fortran/Dp/Src/src.f ;;
  esac
  set -- "$@" "$a"
  i=$((i+1))
done
exec /work/env/bin/x86_64-conda-linux-gnu-gfortran "$@"
