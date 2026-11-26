# buckley1994-minimize-734: result (blocked on G2, measured values match)

Status: the measured values match the registered claim. The verdict is `blocked` (not `reproduced`) until gate G2
is satisfied. `result.json` carries `verdict: blocked`, resolver scout; the claim and tolerances are unchanged.

## Claim (registered in queue/buckley1994-minimize-734.json, not edited)
- Shipped reference run Drivers/Sp/res2 of driver2.f90 (Rosenbrock from (-1.2, 1), acc 0.001, EvalLimit 200).
- FEvals 59 (tol 0), iterations 36 (tol 0), least function value 2.0053597e-09 (tol 1e-8 absolute).

## Our value
- Run 1 (clean directory, same binary, gfortran -O2): least 0.20053597E-08, 59 evaluations, 36 iterations.
- Run 2 (clean directory, same binary): identical three lines.
- Supplementary: a -O0 build (evidence/pass-O0-stdout.txt, scratch only, not in the recipe): identical three lines.
- Difference from the claim: 0 for both counts; 0 for the least value at the printed precision.
- The per-iteration [Prnt] lines differ from res2 only in timings and in the last digit of the first f value.

## Basis: patched (G1 original attempt failed)
- Original attempt (evidence/original-attempt.log): the archive does not unpack as documented. Under `sh` the shar
  is a syntax error; under bash the heredoc for src.f90 is not written (a backtick in an unquoted heredoc). The
  driver2.f90 line 1 `C--**--CH2470...` is rejected by gfortran's free-form default. driver2 also calls i1mach(2),
  from the PORT library, which is not in the archive.
- Patches (all recorded by manifest, `patch.kind` = source):
  1. src.f90 extracted from the shar by line range (sed -n 2132,10106p): added file.
  2. driver2.f90 line 1: `C` replaced by `!`: modified file.
  3. impl/i1mach.f90: a stand-in for PORT's i1mach, returns 6 for unit 2, 0 otherwise: added file.
- Because these are source changes before the build, the build-only route does not apply; the full G2 check does.

## Gates
- G1: pass (original attempt logged, failed).
- G2: OPEN. Two things are missing: (a) the paper check for the patched pieces (the paper was not read; the i1mach
  stand-in is the PORT routine's documented role, and the extraction and line-1 fix are the archive's own text); (b) the
  queue entry has no `code.archive` sha256 to match. netlib 734.gz sha256 computed in the sandbox:
  bf1682045031a42610373d26367ccab037dcc2aada64e3f9ab033311a7d794b0.
  Resolver: scout (register the hash in a new commit, and state whether the i1mach stand-in is within the claim).
- G3, G5, G6: not yet (no verdict).

## Reproduce
`reports/buckley1994-minimize-734/recipe.sh` (fetches 734.gz, checks the sha256, runs everything through
tools/sandbox.sh, prints `VALUE` lines). Logs: evidence/recipe-run.log, evidence/build.log, evidence/run1-stdout.txt,
evidence/run2-stdout.txt. Manifests: evidence/manifest.{pre,mid,post}.

## Environment pins
- gfortran 16.2.0 (conda-forge, micromamba in the sandbox scratch, /work/fortran), Linux, glibc from the host image.
- Shipped reference: evidence/reference/res2, sha256 491800169ae10cfbc6b0b190e5f6d8147822d3f587062463bc864931edd25e1b.
