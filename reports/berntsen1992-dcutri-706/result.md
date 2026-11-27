# berntsen1992-dcutri-706: TOMS 706 (DCUTRI)

**Verdict: blocked.** The sample reproduces its shipped output, but the program only compiles after a
multi-range extraction, and G2 for that patch needs a paper check that cannot be done (the paper is not accessible).

- Our RESULT 11.181284417019187 against the registered 11.181284417019 (difference 1.9e-13, tol 1e-9).
- NEVAL 185 and IFAIL 0 match exactly.
- Basis: `patched`. The listing does not compile as one unit (two PROGRAM units). The extraction copies eight
  subprograms verbatim from six non-contiguous ranges (`evidence/extract.txt`, `impl/extract.py`).
- `docs/method.md` ('Extraction patches') covers one verbatim range only, so this is a `source` patch and the full G2
  check applies. `checks/gates.py` is not changed to accept a list of ranges (operator decision, DM #148).

**Missing to unblock:** a paper check of the extracted program (or a single-range extraction). Resolver: operator.
Disposition: re-check when the paper or a single-range source is available; no timer.

Evidence: `evidence/` (build and run logs, `extract-sha256.txt`, `original-attempt.log`), `recipe.sh`, `result.json`.
Pins: archive `706.gz` sha256 `c67596047b71b0642323a2593ceea4949d5782cc4df6518efcdfb05ed8fc97bc`; gfortran via the sandbox.
