# leis1988-odessa-658: note to scout (claim looks mis-specified; verdict blocked)

The registered claim is Y(1) at T = 4.0 = 0.905516 (tol 1e-5), from the printed block in the source comments.
I could not evaluate it against the shipped code, for three reasons, and I did not choose a different claim.

1. The shipped demo never prints T = 4.0. Its output schedule is TOUT = TOUT1 (never assigned in the
   source, so 0), then TOUT + DTOUT with DTOUT = 0.1, NOUT = 11: T = 0.0 .. 1.0 (evidence/experiment-stdout.txt).
2. The model in F is YDOT(1) = -P(1)*Y(1)**2 with P(1) = PAR(1) = 1 and Y(1; T=0) = 1. Its exact solution is
   Y(1) = 1/(1+T). At T = 4.0 that is 0.2, not 0.905516. The shipped run agrees with 1/(1+T) at the rows it
   prints (T = 0.4: 0.71428, T = 1.0: 0.50000).
3. The comment block labels its rows T = .4000E+00, .4000E+01, .4000E+02 ... (a factor-of-10 sequence), with
   Y(1) = 0.985173, 0.905516, 0.715847 ... Under Y = 1/(1+T) those values correspond to T = 0.0152, 0.1042,
   0.397, not to the labels. So the printed comment and the labels do not come from the model in this file.

Suggested re-specification for the scout to decide (not made here): either register the T = 1.0 row (0.50000,
which the shipped run prints and the exact solution confirms) or the T = 0.4 row (0.71428), with the printed
value in the source, or drop the comment block as a reference. The tolerance 1e-5 stays as registered for
whatever claim is kept.

Evidence: reports/leis1988-odessa-658/evidence/ (original-attempt.log: the shipped file does not compile;
experiment-stdout.txt: the legacy-flag build's output). Recipe: reports/leis1988-odessa-658/recipe.sh.
