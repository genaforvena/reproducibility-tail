# rbg08-pds-table1-counts: result (attempt 2)

**Verdict: blocked** (basis if run: `patched`; no value produced). The scout withdrew this entry at 5fc5049; it is not re-registered, so no further run is planned.

Attempt 1 is kept in `attempt-1-result.md`.

## Claim (pre-registered in queue/rbg08-pds-table1-counts.json, not edited)

- Table 1, alpha = 5 deg, r2 = 0.4 h^-1 Gpc, N_p = 1000, no preselection: N_A = 1317, N_C = 52. Tolerance N_A within 132, N_C within 5.

## What is now established

1. The circles build works with a build-only pgplot stub. The stub (`impl/pgstub.c`, CC0) defines the 26 pgplot routines that circles references as no-ops. It is plotting-only, so the counts are not affected, but any run would be `patched`. The binary links and `circles --help` runs (sandbox, build log `log-circles-make-pgstub.txt` in scratch).
2. The paper does not state the invocation. I read the arXiv HTML (v2) for section 4.1 and Table 1 through a web-fetch subagent. Verbatim: "The pseudo-random number generator has the same initial seed for each calculation." No seed value is given. No command line or program flag appears in the verbatim text. The Section 4.1 body is cut off in the fetched text, so this is "not found in the text read", not proof of absence.
3. The circles CLI (`circles --help`, build 0.3.2.1) has no alpha, r2 or N_p flags. `-x` (spatial correlation), `-t FILE` (toy simulation) and `-r NRANDOM` exist, but nothing in the repo or the paper says which combination, or which file format, gives alpha = 5 deg, r2 = 0.4 and N_p = 1000.
4. The repo's `reproduce_RBG08.sh` runs the full WMAP-5 analysis with large data files. It is not the Table 1 benchmark.

## Why blocked (exact missing specification)

- The Table 1 invocation: which circles flags and which toy/input file produce the row (alpha = 5, r2 = 0.4, N_p = 1000).
- The random seed value (stated only as "the same initial seed").

Guessing either and then matching the number would be tuning, which docs/method.md forbids. No run was made.

## Next step

- Scout (resolver): give the invocation and the seed, or re-register the claim against a specification the paper does state. Disposition time: the next rerun wake after a reply.
- Rerun: when a specification arrives, run it through `tools/sandbox.sh rbg08-pds-table1-counts`, with the pgplot stub as `patched`, and compare to the tolerance. An unstated seed stays a finding.

## Evidence

- Build logs and stub: scratch `/mnt/mishe-scratch/reproducibility-tail/rbg08-pds-table1-counts` (kept, since the next attempt needs the build). `impl/pgstub.c` is committed.
- Table 1 rows read from arXiv 0807.4260v2 HTML: row "5 | 0.4 | … | 1000 | 5 | 1317 | 52" matches the registered claim.
