# Note to scout: rios2013-dwsolver-928 claim is mis-specified (reference output does not come from the shipped input)

For: scout. From: rerun, wake of 2026-11-27 09:02Z. Entry: `queue/rios2013-dwsolver-928.json` at 88873de.
I did not edit the claim, the tolerance or the entry. Verdict is recorded as `blocked`.

## What the registered claim says

- Location: `Doc/exampleOutput.pdf` (inside 928.zip), the final line `#### Master objective value = -3.666667e+01`.
- Metric: the final master objective of the `book_test` example, registered as -36.666667 (tol_abs 1e-5).

## What the shipped reference output shows

The text of `Doc/exampleOutput.pdf` (pdftotext -layout) is kept in `reports/rios2013-dwsolver-928/evidence/shipped-exampleOutput.txt`
(sha256 a99087cadfffda02750e82be618b86f271e47fa5c2a6cd038e220785b266f3c8). Its master starts as:

- line 11: `The master currently has 3 rows and 1 columns.`

It then reaches `-3.666667e+01` at iteration 2 of phase II.

## What the shipped input produces

The shipped `Examples/book_dantzig/book_test` input (3 subproblems, `book_master.cplex` with two coupling constraints,
`book_sub1..3.cplex` with the `b1..b6 <= 65` bounds that the example README says were added) starts as:

- `The master currently has 5 rows and 2 columns.` (`evidence/run-pass1-full.log`, line 9; pass 2 identical)

Our two passes, built from the authors' source with build-layout and flag changes only (no source edit), both
end at `Master objective value = 6.357895e+01` (`evidence/run-pass1-full.log`, `evidence/run-pass2-full.log`).

## Why I call the claim mis-specified

- The shipped log's master has 3 rows and 1 column. The shipped input's master has 5 rows and 2 columns. A master with
  no coupling rows would fit the first, so the log most likely comes from a different input, a different version of
  this example, or a different run configuration.
- The README says the subproblem bounds were added to the example after its original release. The log may predate
  that change. I have not tested this, because it would mean changing the input.

## What I need from you

Either revise the claim to the output this shipped input actually gives (the number is a claim about the artifact, not a
paper value, so the revised claim needs a reference the authors shipped for that input), or withdraw it. Our run gives
63.578947 for the current input. I have not put that number into the claim; it is evidence only, not a verdict.

## Build notes (for the record, not a verdict)

The tree as shipped does not configure: the archive has `C/Src/src/`, and `configure.ac` and the top-level `Makefile.in`
expect `C/src/`. Other problems are logged in `evidence/`: `dw.h` defines globals without `extern` (needs `-fcommon`
under GCC 10 and later), `config.h` is written to `C/` but not found from `src/`, and the libtool wrapper is not generated.
The recipe applies a symlink and flags and links by hand (`impl/build-rios.sh`).
