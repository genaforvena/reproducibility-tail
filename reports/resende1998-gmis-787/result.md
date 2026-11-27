# resende1998-gmis-787 (TOMS 787, gmis: GRASP for maximum independent set, Fortran 77)

**Verdict:** reproduced. **Basis:** patched (build-only, once the scout's `code.archive` provenance field is added; see Status).

## Claim (registered, not edited)

`gmis` on the shipped sample instance (`data`: 50 nodes, 619 arcs), seed 270001, look4 50, maxitr 1000, prints
`Size of indep set : 7`, as in the shipped `RES` output block. Exact tolerance (tol_abs 0). The value 7 is the known
optimum stated in `read.me`.

## Values

| value | paper (shipped RES) | pass 1 | pass 2 | verdict |
|---|---|---|---|---|
| size of indep set, sample instance, seed 270001 | 7 | 7 | 7 | match |

Both passes also report the same independent set as the shipped RES block, {5, 15, 16, 27, 31, 32, 45}, found on
tuple 1, iteration 1. That extra agreement is evidence, not part of the registered claim.

## What happened

1. **Original attempt (G1), failed.** The archive unpacks with `sh 787.shar`, but its heredoc is unquoted, so the shell
   expands `$(FC) $(FFLAGS) $(OBJS_GMIS)` at unpack time. The `gmis` rule loses its prerequisites and compiler, and make
   is left with `-o gmis`. make reports `o: No such file or directory` and exits 0 only because the error is ignored.
   No `gmis` executable is produced (`gmis_binary=no`). Log: `evidence/original-attempt.log`.
2. **Build.** Nothing in the unpacked tree is edited. The build copies the tree and runs three gfortran commands that
   carry out the rule the Makefile intends (`FFLAGS=-O` from the Makefile):
   - `gfortran -O -c Fortran77/Drivers/Sp/driver.f -o driver.o`
   - `gfortran -O -c Fortran77/Src/Sp/src.f -o src.o`
   - `gfortran -O driver.o src.o -o gmis`
   The compile emitted no warnings (`evidence/trial-compile.log`, `evidence/pass1-build.log`).
3. **Two passes (G3).** Both are clean rebuilds from the unpacked tree, each run on `data`. Outputs:
   `evidence/pass1-output.txt`, `evidence/pass2-output.txt`.
4. **Manifests.** `manifest.pre`, `manifest.mid` and `manifest.post` are in `evidence/`. Pre and mid agree.

## Environment pins

- Archive: netlib `787.gz`, sha256 `dc7105e38d4dac8082ee6d010bd4c9a904d61b1a182532414ecd2c7dcf3768fe` (checked at fetch).
- Compiler: GNU Fortran (conda-forge gcc 16.2.0-7), installed in the sandbox with micromamba (`evidence/fetch-toolchain.log`).
- Sandbox: `tools/sandbox.sh` (read-only root, scratch on the spare drive, memory, CPU and time caps).

## Caveats

- The claim is weak. The integer 7 is the known optimum and is reached on the first GRASP iteration, so any run that
  finds an optimum would pass it.
- The build is not the authors' `make` target. Their Makefile cannot build as shipped, so the three gfortran commands
  stand in for its rule. This is why the basis is `patched`, and it is why the build-only label rests on the
  manifests, not on the Makefile.

## Status

The build-only record needs `code.archive` in the queue entry (the gate reads that field). The sha256 is only in
`code.commit`. The first record run returned `kind: source` with `archive_sha256` empty, so `record_exit=2`. I asked the
scout (chat, 00:54Z) to add `code.archive`, as in `72a55d5` for miminis. When it lands I rerun the recipe, which
rewrites `patch` and `queue_commit` in `result.json`. The ledger and gates run after that.

## Reproduce

`bash reports/resende1998-gmis-787/recipe.sh`
