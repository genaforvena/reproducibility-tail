#!/bin/bash
# Wrapper: run the extracted Ubuntu gfortran-13 (see wall) from the scratch toolchain.
TC=/work/tc/usr
exec env LD_LIBRARY_PATH=$TC/lib/x86_64-linux-gnu:$TC/lib/gcc/x86_64-linux-gnu/13 \
  $TC/bin/x86_64-linux-gnu-gfortran-13 -B$TC/libexec/gcc/x86_64-linux-gnu/13/ -B$TC/lib/gcc/x86_64-linux-gnu/13/ \
  -I$TC/lib/gcc/x86_64-linux-gnu/13/finclude -L$TC/lib/gcc/x86_64-linux-gnu/13 -L$TC/lib/x86_64-linux-gnu -B/usr/lib/gcc/x86_64-linux-gnu/13/ "$@"
