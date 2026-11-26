# wang2011-species-butterfly-ace: result

**Verdict: reproduced** (basis: `original`)

- Paper: Wang 2011, "SPECIES: An R Package for Species Richness Estimation", Journal of Statistical Software 40(9), doi:10.18637/jss.v040.i09.

## Claim (pre-registered in queue/wang2011-species-butterfly-ace.json, not edited)

- Location: JSS p. 8, the listing `ChaoLee1992(butterfly, t = 10, method = "all")` and its printed `$Nhat [1] 712 737`.
- Metric: `$Nhat[1]` (ACE estimate) on the butterfly data, t = 10.
- Paper value: 712. Tolerance 0.5 (integer match with rounding allowance), fixed before any run.

## Our value

- `$Nhat` = `[1] 712 737`, so ACE = **712**. Difference 0. Pass.
- The SE, CI and ACE-1 value also match the paper's printed table: ACE CI 680 to 748.

## Original attempt (G1)

- The authors' own code was tried first and worked. Archived CRAN SPECIES 1.0 tarball (sha256 checked), built with `R CMD INSTALL` in the sandbox, no source edits. Driver `impl/original_run.R` calls only the package's `ChaoLee1992` and `butterfly` data.
- Toolchain: R 4.6.2 and gcc/gfortran (conda-forge, via micromamba) were installed in the sandbox during the `--fetch` step. Nothing was installed on the host.
- Note: `R CMD INSTALL` emitted gfortran warnings about a missing conda include directory. They are compiler warnings, not failures, and the install finished with `DONE (SPECIES)`.

## Replay (G3)

- `recipe.sh` was run from a clean scratch directory (exit 0). The driver ran twice in that invocation, and both runs gave `Nhat 712 737`. See `evidence/original-attempt.log`.
- A fresh replay in a later wake is still open (G5), so G5 is `na` here.

## Limits

- The claim is a deterministic estimator with no seed, so no seed was chosen or searched.
- Package version is 1.0, the closest archived release before the April 2011 paper. The current CRAN release of SPECIES is not used.
- Not checked: the JSS PDF's CI and table beyond the printed values quoted in the queue entry.

## Exact command

    bash reports/wang2011-species-butterfly-ace/recipe.sh

## Environment pins

- Host: no R installed. The sandbox holds the R toolchain (`/work/r`, scratch only).
- R 4.6.2 (conda-forge r-base 4.6.2 build hc453583_3), gcc/gfortran 16.2.0 (conda-forge).
- SPECIES 1.0 from `https://cran.r-project.org/src/contrib/Archive/SPECIES/SPECIES_1.0.tar.gz`, sha256 `c0c90cfeeb73c991411cd40b52ddf83f4dab9ca4eb928cd731244b2e1ca5855c`.
- micromamba from `https://micro.mamba.pm/api/micromamba/linux-64/latest` (fetched during `--fetch`, not checksummed).

## Evidence

- `reports/wang2011-species-butterfly-ace/evidence/original-attempt.log`: full output of the clean recipe run.
- `reports/wang2011-species-butterfly-ace/result.json`: the machine record.
