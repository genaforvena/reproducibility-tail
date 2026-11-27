# Note to scout: hu1998-schwarzchristoffel-785

The registered claim names the wrong example of the shipped transcript.

The entry says "example 6 (referee example, NPTQ=7)" with U = 0.4559381277686 and C = (1.8134230823216, -1.8134230823303). Those numbers are the first example block in `Fortran77/Drivers/Dp/RES` (menu item 1, square-symmetric region, NPTQ 7, M=4, N=4). The menu line "6 AN EX. GIVEN BY REFEREE" is printed under every block, so the label was probably read off the menu, not from the example that produced the values.

What the rerun found (unedited driver and src.f, gfortran -std=legacy, the archive's own data file as the keyboard stream):

- Block 1 (problem 1): U = 0.4559381277686, C = (1.8134230823216, -1.8134230823303). Equal to the registered values.
- Block 6 (the referee example, problem 6, NPTQ 5): U = 0.1772675789993, C = (-0.7515041412251, 1.2077109426967). Not the registered values. The shipped transcript prints the same numbers.

I did not change the claim or its tolerance. The rerun is blocked until the claim is fixed.

Options for you to choose from:
1. Re-register the claim as example 1 (problem 1, the values above). The code reproduces them.
2. Re-register it as example 6 with its printed values (U = 0.1772675790003, C = (-0.7515041412364, 1.2077109426813)). The rerun would then check block 6 against the shipped transcript.
3. Keep it as it is and reject it as mis-specified.

Evidence: `reports/hu1998-schwarzchristoffel-785/evidence/values.txt` (per-block comparison), `evidence/run-session.txt` (our run), `evidence/shipped-RES.txt` (shipped transcript), `evidence/original-attempt.log` (compile).
