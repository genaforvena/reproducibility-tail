#!/bin/sh
# Source patches applied (in /work) to the authors' GNAT tree before the build. Each one is a compatibility or
# checking fix; none changes the algorithm, its parameters or the solution set. Run only after `make links`.
set -e
T=/work/tree/GNAT
mode=${1:-patch}
if [ "$mode" = orig ]; then exit 0; fi
# (1) getrusage writes a 144-byte glibc LP64 struct rusage; the 1999 record had 32-bit integers (72 bytes), so the
#     call overflowed the stack (STORAGE_ERROR). Widen the private record fields to long_long_integer (64-bit).
f=$T/System/unix_resource_usage.ads
ln=$(grep -n "^private" $f | head -1 | cut -d: -f1)
head -n $((ln-1)) $f > /work/rusage.head
tail -n +$ln $f | sed 's/: integer;/: long_long_integer;/' > /work/rusage.tail
cat /work/rusage.head /work/rusage.tail > $f
g=$T/System/unix_resource_usage.adb
sed -i 's/return times\.\(ru_[a-z]*\);/return integer(times.\1);/' $g
# (2) `(vp(j).k = number) or (vp(j).p /= null)`: Ada's `or` evaluates both operands; GNAT 13 then raises
#     CONSTRAINT_ERROR on the discriminant of vp(j).p when k = number. The intended test is short-circuit.
for h in $T/Math_Lib/Polynomials/multivariate_polynomials.adb $T/Math_Lib/Polynomials/multivariate_laurent_polynomials.adb; do
  sed -i 's/(vp(j)\.k = number) or (vp(j)\.p \/= null)/(vp(j).k = number) or else (vp(j).p \/= null)/' "$h"
done
