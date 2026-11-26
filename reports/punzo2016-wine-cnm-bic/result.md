# punzo2016-wine-cnm-bic: result

**Verdict: reproduced** (basis: `original`)

- Paper: Punzo and McNicholas 2016, "Parsimonious mixtures of multivariate contaminated normal distributions" (arXiv:1305.4669v5).

## Claim (pre-registered in queue/punzo2016-wine-cnm-bic.json, not edited)

- Location: Section 7.3 (wine data), Table 11, row CNMs: the BIC-selected (G, parsimonious structure) in the CNM family, over G in {1,2,3,4} and the 14 structures, labels ignored (178 x 13).
- Paper value: G = 3, structure EEE. Tolerance: exact match on both (categorical).
- Seed 1, fixed by the scout before any run. The paper's default initialisation ("mixt") is deterministic given the call; the seed is set once and passed as NULL to each call.

## Encoding of the categorical value

The replay contract prints numbers only, so the recipe prints two VALUE lines:

- `VALUE selected_G 3` (paper 3).
- `VALUE selected_structure_index 7`: the position of EEE in the package's structure order (EII, VII, EEI, VEI, EVI, VVI, EEE, ...). Paper 7.

## Our value

- Package's own `whichBest()` (BIC): G = 3, EEE, BIC = -6924.78498806. An independent argmax over the successful fits in the driver gives the same model.
- Runner-up for context: G = 4 EEE, BIC -6928.95; G = 3 EEI, -6997.53. The margin between the top two is about 4.2 BIC units.
- Both driver runs in `recipe.sh` (clean scratch) give the same result.

## Original attempt (G1)

- The authors' ContaminatedMixt 1.0 package was built with `R CMD INSTALL`, no source edits. The Imports were installed from CRAN at fetch time (mixture 2.2.1, mnormt 2.1.2, mclust 6.1.4). These are not the 2015 versions; the limit is recorded below.
- First attempt: a single `CNmixt(X, G = 1:4)` call halted at (G = 4, EVE) inside `mixture::gpcm` ("no models estimated"). The error escapes the package's own per-job handling. The log is kept in `evidence/original-attempt.log`.
- Second attempt, the one used for the value: one `CNmixt()` call per (G, structure), wrapped in `tryCatch`. The package code is unchanged; only the calling pattern differs. Failed fits are recorded and excluded, as the package does for its own failed jobs. 41 fits succeeded and 15 failed:
  - `invalid subscript type 'list'` for EEV, VEV, EVV and VVV at G = 2, 3 and 4.
  - `no models estimated` for VVI and EVE at G = 4.
  - The paper says some fits fail numerically; these failures are the ones the rerun records.
- The basis is `original` because the package source is unchanged. Whether a per-fit driver counts as `patched` is a judgement call for the scout to revisit.

## Limits

- Imports are current CRAN releases, not the versions from 2015. The paper's value is reproduced with them, but this is not a pinned environment.
- The 15 failed fits are reported, not repaired. They do not change the winner, since the winner is among the successful fits.
- The seed applies only to random initialisations; the default "mixt" is deterministic. No other seed was tried.
- Not checked: the paper's Table 11 rows other than CNMs.

## Exact command

    bash reports/punzo2016-wine-cnm-bic/recipe.sh

## Environment pins

- R 4.6.2 (conda-forge r-base), gcc/gfortran 16.2.0 (conda-forge), micromamba from the latest linux-64 release (not checksummed).
- ContaminatedMixt 1.0 from `https://cran.r-project.org/src/contrib/Archive/ContaminatedMixt/ContaminatedMixt_1.0.tar.gz`, sha256 `5b1cd5ea32712e748d817128ff52f5343ebf9228b682ce70cb38b9086869448e` (checked in the sandbox).

## Evidence

- `evidence/original-attempt.log`: the two G1 attempts, including the failed one.
- `evidence/recipe-run.log`: the clean recipe run with both driver runs and the VALUE lines.
- `result.json`: the machine record.
