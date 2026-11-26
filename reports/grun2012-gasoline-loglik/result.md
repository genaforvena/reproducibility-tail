# grun2012-gasoline-loglik

**Verdict: reproduced** (basis: `reimplemented`)

- Paper: Grün, Kosmidis & Zeileis (2012), Extended Beta Regression in R, JSS 48(11), doi:10.18637/jss.v048.i11.
- Claim (registered 2026-11-26T13:14:40Z): log-likelihood of `betareg(yield ~ batch + temp, data = GasolineYield, type = "ML")` is **84.79756**; tolerance |logLik − 84.79756| ≤ 0.001.
- Rerun value: **84.79755796** (|difference| = 4e-7). Inside the tolerance.

## What was run

1. The archived CRAN tarball `betareg_3.0-0.tar.gz` (fetched inside the sandbox, `--fetch`). sha256 `8e021999…831df3` matches the queue entry.
2. `GasolineYield.rda` from the tarball (`data/`), read by `impl/rda_to_csv.py`, a small RDX2 (XDR) reader written for this report. It yields 32 rows (yield, batch factor with 10 levels, temp). The values were eyeballed against the paper's data description; no external check.
3. `impl/betareg_ml.py`: maximum likelihood for y ~ Beta(μφ, (1−μ)φ), logit(μ) = Xβ, constant φ (betareg's default precision model). 12 parameters: intercept, nine batch contrasts, temp (scaled by 1/100), log φ.
   - Analytic gradient checked against central differences at the start point: max difference 4.5e-8.
   - Nelder–Mead from the moment-based start: logLik 84.79755796. Nelder–Mead restarted from the BFGS point: 84.79755796 (same optimum).
   - Maximum gradient at the optimum: 7.4e-5 (stationary within the optimiser's tolerance).
   - Fitted φ = 440.28.

## Limits and caveats

- **R was not run.** R is not installed on this host. The value comes from a pure-Python reimplementation. The verdict basis is therefore `reimplemented`, not `original`.
- **Version.** The paper cites betareg 2.4-0 or later for BC/BR. This run uses 3.0-0, the archived release closest to the 2012 paper, as the registration specified. The ML value does not depend on the bias-correction code, so this matters little for this claim, but it is still a different release from the paper's.
- **BFGS did not converge.** The BFGS run in `betareg_ml.py` stopped at logLik 28.38 (line search lost the admissible region). That is a fault in my BFGS, not a finding about the claim, and it is kept in the output. The verdict rests on Nelder–Mead, which agreed from two starts and has a vanishing gradient at the optimum.
- Only the ML fit is checked. The BC and BR values in the paper's listing are not reproduced here.
- `reimplemented` matches show the paper's model description is sufficient for this value. They do not show the shipped betareg code works as published.

## Evidence

- Sandbox output, one full run (exit 0): `impl/` and this file; output reproduced below.
```
n = 32  parameters = 12
max |analytic - finite-difference| gradient at start: 4.45e-08
BFGS          logLik = 28.38256704
Nelder-Mead   logLik = 84.79755796 (restarted from BFGS optimum)
Nelder-Mead   logLik = 84.79755796 (from the moment start)
best logLik = 84.79755796
max |gradient| at best = 7.36e-05
phi = 440.278554
```
- Recipe: `recipe.sh` was run end to end through the sandbox (exit 0), reproducing the output above from the CRAN archive.
