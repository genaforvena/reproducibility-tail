# pardalos1997-grasp-769: result

**Verdict: reproduced.** Basis: **patched** (build-only: the compiler is substituted, no source edit).

## Claim

The cost of the best permutation found by GRASP for the 6-by-6 QAP test instance in the archive (seed 270001, 1000 iterations, alpha 0.25, beta 0.50, look4 -1), as printed in the shipped reference output `RES` (block `output`, line "cost of best permutation found"). Registered value 4490, tolerance abs 0.5 (the cost is an integer, so only the exact integer passes). Neither the claim nor the tolerance was edited.

## Values

| name | paper (shipped RES) | ours pass 1 | ours pass 2 | tol_abs | result |
|---|---|---|---|---|---|
| best QAP cost (GRASP, seed 270001) | 4490 | 4490 | 4490 | 0.5 | match |

Best permutation: shipped `1 5 4 2 6 3`; ours `1 5 4 2 6 3` in both passes (`evidence/run-pass1.txt`, `evidence/run-pass2.txt`).

## Original attempt (G1)

The authors' `Doc/Makefile` as shipped sets `FC=epcf90` with PGI-only flags (`-sloppy -C -d5 -g -temp=/tmp -u`). `epcf90` is not installed in the sandbox and is not a conda-forge package, so the original build failed: `make: epcf90: No such file or directory`, make_exit=2, no binary. The log is `evidence/original-attempt-build.log`. The verdict is therefore not `original`.

## Patch (build-only)

The build substitutes `gfortran` for `epcf90` and drops the PGI-only flags. Three commands, no edit to any source file:

- `gfortran -c .../Drivers/Sp/driver.f -o driver.o`
- `gfortran -c .../Src/Sp/src.f -o src.o`
- `gfortran -o gqaps driver.o src.o`

Manifests `pre`, `mid` and `post` (`evidence/manifests/`) show no source change. The `patch` record in `result.json` is `kind: build-only` (compared 3, modified 0, removed 0, added 0).

## Commands and pins

- Exact command: `bash reports/pardalos1997-grasp-769/recipe.sh` (fetch, unpack, original attempt, build, manifests, two runs, value line).
- Archive: netlib TOMS `769.gz`, sha256 `431c74438646c4f82fa52b2ffc6979bb899adad0825b61cae9466e5d3f2f6b98`, fetched inside the sandbox (`evidence/archive-sha256-check.txt`). Shell archive unpacked verbatim with `extract-tree.awk`, not executed.
- Compiler: GNU Fortran 16.2.0 (conda-forge gcc 16.2.0-7) (`evidence/gfortran-version.txt`).
- Shipped reference `RES`: sha256 `d51fe3f48eb47743988e6ded8bc581fc5b61f800ee026a3b6d3799627087a14f` (`evidence/shipped-res.txt`).
- Run: the driver reads its problem on unit 5 (stdin) and prints to stdout; the recipe feeds `data` on stdin, bounded by `timeout 120`, inside `tools/sandbox.sh`.

## Passes

Two passes, each in a fresh run directory with the same built binary and the same fixed seed (270001, set in `driver.f`). The seed is part of the authors' code, not chosen by us. Both passes print 4490.

## Open gate items

Resolved at queue commit 0cdfc8e (scout provenance registration, message #182): `code.archive` and `claim.reference.sha256` are now in `queue/pardalos1997-grasp-769.json`. The recipe was re-run at 0cdfc8e: fetched archive sha256 matches 431c7443...b98, the build-only record has archive_sha256 populated, and both passes print 4490.

## Scratch

Scratch: `/mnt/mishe-scratch/reproducibility-tail/pardalos1997-grasp-769`, deleted at the end of the wake that ran it (the record needs only the evidence copies in this report).
