# rbg08-pds-table1-counts: result

**Verdict: blocked** (not yet run; no value produced).

## Claim (pre-registered in queue/rbg08-pds-table1-counts.json, not edited)

- Paper: Roukema, Buliński & Gaudin 2008, A&A 492, 673 (arXiv:0807.4260), Table 1, alpha = 5 deg, r2 = 0.4 h^-1 Gpc, N_p = 1000, no preselection.
- Paper values: N_A = 1317, N_C = 52.
- Tolerance (fixed before any run): N_A within 132 (10 percent), N_C within 5.

## Where it stopped

1. Claim committed (d6cfd2f, 2026-11-26T12:29:24Z).
2. Source fetched in the sandbox with network (`tools/sandbox.sh --fetch`) at the pinned commit `5b90a7b0d56dc2ff1c6fa8b2449b5355d7d15f84` (checked with `git rev-parse`).
3. Pinned dependency checks: GSL 1.10 tarball SHA-512 prefix `11ebd2f5…` matches the script's expected value. cosmdist commit `d17caed98cc6` SHA-512 prefix `bbe55a9e…` matches the script's expected value. (A `master` tarball was fetched first; it is a different commit, `4bb81e16e504`, and was discarded.)
4. Built inside the sandbox (no network): GSL 1.10 and cosmdist d17caed built and installed to the scratch prefix.
5. circles-0.3.2.1 configured and compiled, then **link fails**: `cannot find -lpgplot`. The Makefile hard-codes `-L/usr/local/pgplot -lpgplot` for plotting. pgplot is not installed on this host, and apt has no pgplot package here (only giza-based replacements).

## Build-environment deviations (all build-only, source not edited)

- gfortran: the host has no gfortran. I extracted Ubuntu gfortran-13 (13.3.0) debs into scratch with `apt-get download` + `dpkg-deb -x` (`gfortran-wrapper.sh`). Host /usr is untouched.
- `depcomp` is absent from the source tarball; copied from `/usr/share/automake-1.16/depcomp` into each Makefile.in directory.
- `makeinfo` is absent; built with `MAKEINFO=true` (docs only).
- Old C/Fortran code needs `-fcommon` with gfortran 10+ (`p_chain` in cosmdist, `language`/`want_C` in isolat).
- The Table 1 invocation is not in the repo. `reproduce_RBG08.sh` runs the full WMAP analysis (large data files), not the Table 1 benchmark. circles has `--toy-simulation` and `--nrandom`; neither is confirmed as the Table 1 calculation.

## Caveats

- The paper does not state the random seed; the scout flagged this. Even with a working build, a count mismatch would have to be recorded as a finding, with the tolerance unchanged.

## Exact commands (what was run)

    tools/sandbox.sh --fetch rbg08-pds-table1-counts -- git clone https://codeberg.org/boud/0807.4260 /work/src
    tools/sandbox.sh --fetch rbg08-pds-table1-counts -- (curl gsl-1.10 and cosmdist d17caed from upstream)
    tools/sandbox.sh rbg08-pds-table1-counts -- /work/build.sh   (see build-attempt.sh; currently ends at the -lpgplot link)

Logs: `logs/` (tails of each configure and make step). Scratch: `/mnt/mishe-scratch/reproducibility-tail/rbg08-pds-table1-counts` (kept for the next attempt, not deleted, because the blocked state needs it; see note-to-scout.md).

## Next step (bounded)

- Scout: confirm the exact Table 1 invocation and the seed (see note-to-scout.md), or confirm that the claim is still the right one.
- Rerun: decide on pgplot (a no-op plotting stub for the benchmark, or a giza-backed build), then run the confirmed invocation in the sandbox.
- Recipe (`recipe.sh`) is not written yet: the run has not reached a value. It will be added when the run completes.
