# abernathy1993-finv-724: reproduced (patched, extraction)

Paper: Abernathy and Smith, "Algorithm 724: FINV, F-percentage points", ACM TOMS 19(4), pp. 481-483 (December 1993).
Stack: Fortran (the authors' code). Field: numerics (F-distribution percentage points).

## Claim

FINV(M = 10, N = 10, P = 0.9) = 0.23226039E+001 (2.3226039), the row N = 10, column M = 10 cell of the P = 0.90 table
in the archive's printed TEST driver output (archive lines 646-690). Registered by scout from the artifact's own
printed output, not from a paper table. Tolerance 2e-7 absolute, fixed in the queue entry before any run.

## Result

| value | paper | tolerance | ours | difference | verdict | basis |
|---|---|---|---|---|---|---|
| FINV_M10_N10_P090 | 2.3226039 | 2e-7 | 2.32260390 | 0 (at printed precision) | reproduced | patched (extraction) |

Our value is the driver's own output, written to TESTDATA by the authors' FINV and TEST code. The cell matches the
shipped printed value to all eight printed digits.

## What was run

1. Fetch (sandbox, network only here): netlib.org/toms/724.gz, sha256 c63388b4b9ec6b2d662e9ea6d772fcf2707e028c9e99a7455db37dccd9111ac2,
   the queue entry's archive hash. gunzipped to 917 lines. gfortran 16.2.0 from conda-forge (micromamba).
2. G1 original attempt: the archive as shipped does not compile. Lines 646-917 are the authors' printed test
   output, pasted without comment markers, so gfortran stops at line 653 with "Non-numeric character in statement
   label". Log: `evidence/original-attempt.log`.
3. Patch (extraction): archive lines 1-645 are copied verbatim into `724.f` (the program TEST, the FINV package,
   END at line 643, and two comment rules). Nothing inside the code is edited. `verify_sources.py record` checks
   that the new file's hash equals the hash of the kept range, and that the archive file's hash is
   aa1998859f9cb66ddf2d730199e990228c541b8d89e09c34de196aaa65e6c635 (the file's sha256 as registered in the
   claim's reference).
4. Build: `gfortran -o test724 724.f` with gfortran defaults (warnings only: shared DO labels, a Fortran 2018
   deleted feature). Exit 0.
5. Run: `./test724` writes `TESTDATA` in its working directory. Exit 0.
6. The P = 0.90 first table, row N = 10, fourth column (M = 10), is 0.23226039E+001.

Command: `reports/abernathy1993-finv-724/recipe.sh` (it runs everything above through `tools/sandbox.sh`).

## Environment pins

- Archive: netlib.org/toms/724.gz, sha256 c63388b4b9ec6b2d662e9ea6d772fcf2707e028c9e99a7455db37dccd9111ac2.
- Code extraction (lines 1-645): sha256 c55d2ff894ba1f7cf019e9b4c7006594be1bcd05461959b5794e387479c569d9.
- gfortran 16.2.0 (conda-forge gcc 16.2.0-7), default flags, no `-std` option.
- Sandbox: `tools/sandbox.sh`, read-only root, scratch on the spare drive, no network after fetch.

## Evidence

- `evidence/fetch.log`, `evidence/fetch-probe.log`: archive hash and layout.
- `evidence/original-attempt.log`: the failed G1 compile.
- `evidence/patch.log`, `evidence/build.log`, `evidence/run.log`: patch, build and run.
- `evidence/TESTDATA`: the driver's output.
- `evidence/shipped-block.txt`: archive lines 646-690, the printed output the claim comes from.
- `evidence/manifest.pre`, `manifest.mid`, `manifest.post`, `record.log`: the patch record (manifests show only the
  added file 724.f; the .txt archive is not a source file).

## Gates

- G1: pass. The authors' artifact was tried first and failed on its own output block; the extraction is the
  smallest change that lets the code compile.
- G2: n/a. The patch is an extraction of one verbatim range, so no paper-text check is needed (method.md, extraction
  patches). The archive hash equals the queued one.
- G3: pass. One run; the claim is deterministic (no random input).
- G5: not yet. The replay has not been run; this result is not a replayed result.

## Limits

- The claim value comes from the archive's printed output, not from the paper text (the ACM article was not
  fetched). The paper value therefore reproduces the authors' own printed value, not an independent figure.
- One pass only. Nothing here is "not reproduced", so the second pass in method item 5 is not required.
- The printed claim has eight significant figures; the comparison is at that precision, with a tolerance of 2e-7.
