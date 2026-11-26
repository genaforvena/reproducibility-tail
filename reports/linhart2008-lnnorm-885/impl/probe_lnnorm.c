/* Probe for linhart2008-lnnorm-885. The authors' driver (C/main.c) reports only maxima and means over the
   table rows, not the single claimed value. This program calls the authors' lnnorm() unchanged, from their
   C/lnnorm.c, at x = -5.0 and prints -lnnorm(-5.0) with 17 significant digits, the quantity the claim compares
   with the tabulated 15.0649983939887257 (Sheppard 1939, row x = 5.0). Written from the claim's text in the
   queue entry; it does not change lnnorm or any authors' file. */
#include <stdio.h>

double lnnorm(double z);

int main(void)
{
	printf("%.17g\n", -lnnorm(-5.0));
	return 0;
}
