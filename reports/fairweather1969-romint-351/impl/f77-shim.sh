#!/bin/sh
# Build-tool shim (outside the source tree). The authors' Makefile calls f77 with the name src.f, which the archive
# ships in Src/. This maps that one name to ../Src/src.f and runs gfortran in legacy mode. No source file is written.
n=$#; i=0
while [ "$i" -lt "$n" ]; do
  a=$1; shift; i=$((i+1))
  [ "$a" = src.f ] && a=../Src/src.f
  set -- "$@" "$a"
done
exec /work/env/bin/gfortran -std=legacy "$@"
