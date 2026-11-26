# renka2004-csrfpack-833: CSRFPACK (TOMS 833), claim F(X=-0.948717948717949, Y=-1.0)

**Verdict: blocked.** The authors' code builds and runs, and reproduces its own shipped output exactly.
The registered claim value is wrong by a factor of ten, so no verdict is computed from it. The
note to the scout is `note-to-scout.md`.

## Claim

- Registered (queue commit 2235ef0): F at grid node (-0.948717948717949, -1.0) from CSRFTEST with the
  shipped 8-node data file, paper value `0.189783809135176`, tolerance 1e-9 absolute.
- Shipped output (`Fortran77/Drivers/res`, copied to `evidence/reference/shipped-res.txt`, sha256
  0d2de7c0db55797472d6bc249ae6dd1676aa246ca9d5871eedbc63b4ec3aa14d): the same node is
  `0.189783809135176E+01` = 1.89783809135176.

## Our value

- Pass 1 (gfortran 13 from conda-forge, -O): 1.89783809135176 (`evidence/pass1-Res.txt`).
- Pass 2 (clean copy, -O2): 1.89783809135176 (`evidence/pass2-Res.txt`). Max |pass1 - pass2| = 0.0.
- Whole grid against the shipped `res`: 4642 of 4642 cells matched, max difference 0.0
  (`evidence/vs-shipped-res.txt`).
- Difference from the registered value: 1.89783809135176 - 0.189783809135176 = 1.7 (not a rounding
  question; a dropped exponent).

## Basis and build

- Original attempt (G1, failed): `make` in `Fortran77/Drivers` stops with `makefile.inc: No such file`
  because the archive does not ship `makefile.inc` (`evidence/original-attempt.log`).
- Patch (build-only): the Makefile's three rules are run as written, with the compiler and flags on the
  command line (`-O`; `-O2` in pass 2). No source or build file is edited or added; the manifests
  before, at and after the build are identical (`evidence/manifest.{pre,mid,post}`, 3 files compared).
- Archive sha256 e40e3df805baca94da32f5b9bd460abb8f03049675da6573bf1b7439819a7720 matches the queue entry.
- Fortran source extracted with the authors' own `archive.sh`, cut from the `#! /bin/sh` line.

## Environment pins

- gfortran 13 (conda-forge `gfortran_linux-64`, fetched by micromamba into the sandbox scratch).
- Sandbox: `tools/sandbox.sh` (read-only root, no network after fetch, memory, CPU and wall caps).

## Where the evidence lives

`reports/renka2004-csrfpack-833/evidence/`: original-attempt.log, unpack.log, pass1-build.log,
pass1-run.log, pass2-run.log, pass1-Res.txt, pass2-Res.txt, values.txt, vs-shipped-res.txt, manifests,
recipe-run.log, and reference/shipped-res.txt. The rebuild is `recipe.sh`.

## What would change the verdict

If the scout re-registers the value as 1.89783809135176 (same tolerance), this run is the evidence for a
`reproduced` verdict, and a fresh replay is needed for G5. Nothing here tests the authors' article text: the
G2 paper check is not needed for a build-only patch, and the claim rests on the shipped driver output
(`claim.source` = artifact-reference).
