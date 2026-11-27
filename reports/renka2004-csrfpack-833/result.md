# renka2004-csrfpack-833: CSRFPACK (TOMS 833), claim F(X=-0.948717948717949, Y=-1.0)

**Verdict: reproduced** (basis `patched`, build-only). The authors' code builds with its own Makefile rules and
reproduces its shipped output exactly. At the corrected claim value the node agrees to 0 (tolerance 1e-9).

## Claim

- Registered (queue commit a156ff2, corrected from 2235ef0): F at grid node (-0.948717948717949, -1.0) from CSRFTEST
  with the shipped 8-node data file, paper value `1.89783809135176`, tolerance 1e-9 absolute.
- The earlier value `0.189783809135176` dropped the `E+01` exponent. The earlier blocked verdict (queue 2235ef0)
  was caused only by that; see `note-to-scout.md`.
- Shipped output (`Fortran77/Drivers/res`, `evidence/reference/shipped-res.txt`, sha256
  0d2de7c0db55797472d6bc249ae6dd1676aa246ca9d5871eedbc63b4ec3aa14d): the same node is `0.189783809135176E+01`.

## Our value

- Pass 1 (gfortran 13 from conda-forge, `-O`): 1.89783809135176 (`evidence/pass1-Res.txt`).
- Pass 2 (clean copy, `-O2`): 1.89783809135176 (`evidence/pass2-Res.txt`). Max |pass1 - pass2| = 0.0.
- Whole grid against the shipped `res`: 4642 of 4642 cells matched, max difference 0.0 (`evidence/vs-shipped-res.txt`).
- Difference from the registered claim: 0 (within tol_abs 1e-9).

## Basis and build

- Original attempt (G1, failed): `make` in `Fortran77/Drivers` stops with `makefile.inc: No such file` because the
  archive does not ship `makefile.inc` (`evidence/original-attempt.log`). Kept as the logged original attempt.
- Patch (build-only): the Makefile's three rules are run as written, with the compiler and flags on the command line
  (`-O` in pass 1, `-O2` in pass 2). No source or build file is edited or added. `tools/verify_sources.py record`
  exit 0: 3 manifests compared, 0 files modified, removed or added by us or by the build tool.
- Archive sha256 e40e3df805baca94da32f5b9bd460abb8f03049675da6573bf1b7439819a7720 matches the queue entry.
- Stack Fortran, field numerics.

## Environment pins

- gfortran 13 (conda-forge `gfortran_linux-64`, fetched by micromamba into the sandbox scratch).
- Sandbox: `tools/sandbox.sh` (read-only root, no network after fetch, memory, CPU and wall caps).

## Reproduction

`recipe.sh` (`bash reports/renka2004-csrfpack-833/recipe.sh`) rebuilds and reruns both passes. The latest run
(`evidence/recipe-run.log`, 2026-11-27 00:15Z) ends with `VALUE ... 1.89783809135176`, `PASS2 VALUE ... 1.89783809135176`,
`RECIPE_EXIT=0`. Evidence is in `reports/renka2004-csrfpack-833/evidence/`.

## Not yet done

- G5 replay not run (`replayed` is empty). The `replay-due` duty will flag this until replayed in a later wake.
- The article text was not read; the claim rests on the shipped driver output (`claim.source` = artifact-reference).
