# Draft (not sent; for human tone review): RES1 in TOMS 788 vs the analytic test function

Subject: Shipped RES1 output for NEUMAN (data1) differs from the analytic test solution at one point

Draft body:

We are checking the shipped driver output (Fortran77/Drivers/Dp/RES1, from the netlib 788.gz archive) against a fresh build of NEUMAN with the test driver and data1 as shipped.

For the boundary function 3 on curve 1 (ellipse A=1, B=4) with EPS=1e-7, NTHETA=5, NR=10, the shipped RES1 gives U(0.1112, 1.3695) = -7.7655693670D-01 with a reported true error of 7.77D-16. A build with gfortran 16.2.0 (-O2 -std=legacy; the shipped d1mach.f configured for the 8087/little-endian block) gives -7.7655687809D-01 with a true error of 5.55D-16.

At the point the driver actually computes (x = 0.111246117975, y = 1.369521383465), the test function exp(x)cos(y) - 1 equals -0.776556878092. Our build agrees with that to about 1e-11. The shipped value is about 6e-8 away from the analytic value, which is inside the requested EPS of 1e-7, but the shipped ERROR column reports 7.8e-16 for it.

We would like to know whether RES1 was produced with a different test function, point or build than the driver as shipped, or whether the difference reflects a platform effect on the HP machine described in the README. We have not tested the HP environment.

We have not sent this message to anyone.
