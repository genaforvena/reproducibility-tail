# grun2012-gasoline-loglik

**Verdict: reproduced** (basis: `original`)

- Paper: Grün, Kosmidis & Zeileis (2012), Extended Beta Regression in R, JSS 48(11), doi:10.18637/jss.v048.i11.
- Claim (registered 2026-11-26T13:14:40Z): log-likelihood of `betareg(yield ~ batch + temp, data = GasolineYield, type = "ML")` is **84.79756**; tolerance |logLik − 84.79756| ≤ 0.001.
- Rerun value: **84.79755796** (|difference| = 4e-7). Inside the tolerance.

## What was run (canonical: `recipe.sh`)

1. The authors' archived CRAN package `betareg_3.0-0.tar.gz` (sha256 `8e021999…831df3`, checked in the sandbox), built with `R CMD INSTALL` from the tarball. No source edits.
2. R 4.5.3 (conda-forge r-base) and gcc/gfortran, plus the package's imports (Formula, flexmix, lmtest, modeltools, sandwich), installed into the sandbox scratch during the `--fetch` step with micromamba. Nothing installed on the host.
3. `impl/ml_original.R` (a driver written here, 3 lines): `betareg(yield ~ batch + temp, data = GasolineYield, type = "ML")` on the `GasolineYield` data shipped in the package, then `logLik`.

Output (original attempt, `evidence/original-attempt.log`), and the G3 replay with two driver runs (`evidence/replay.log`):

```
logLik ML = 84.79755796
logLik ML = 84.79755796
```

## Cross-check (independent, not the verdict basis)

`recipe-reimplemented.sh` with `impl/betareg_ml.py` (pure-Python ML fit, Nelder–Mead) gave 84.79755796 as well. It is kept as a cross-check: it agrees with the authors' code to 4e-7 and is not needed for the verdict. Its earlier result is in the git history of this file (the prior `result.md`). The reimplementation's BFGS did not converge (logLik 28.38); that is a fault in the reimplementation, not a finding about the claim.

## Limits and caveats

- **Version.** The paper cites betareg 2.4-0 or later for BC/BR. This run uses 3.0-0, the archived release the registration specified. Only the ML value is checked here; the BC and BR values in the paper's listing are not reproduced.
- **R version.** The run used R 4.5.3, not the R of 2012. The paper's listing is reproduced with a current R, which is what the registration's "current release" allowed.

## Evidence

- `reports/grun2012-gasoline-loglik/evidence/original-attempt.log` (first original run, exit 0)
- `reports/grun2012-gasoline-loglik/evidence/replay.log` (replay, two driver runs, exit 0)
- `recipe.sh` (canonical), `recipe-reimplemented.sh` and `impl/` (cross-check)
