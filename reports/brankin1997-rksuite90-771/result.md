# brankin1997-rksuite90-771: result

**Verdict: reproduced.** Basis: **patched (build-only)**.

## Claim

TOMS 771 (RKSUITE_90, Fortran 90). The shipped example `eg_simple_c0_a` prints
"The cost of the integration in calls to F was" with the value **117** in its reference
output `eg_simple_c0_a.r`. Registered as an integer count with `tol_abs` 2, fixed in the
queue entry before any run. The article was not read (paywalled); the claim rests on the
shipped reference output.

## Our value

- Pass 1: **117**
- Pass 2: **117** (clean rebuild from the unpacked archive)
- Shipped reference: **117**
- Difference 0, inside tol_abs 2.

## Basis and why

The authors' README procedure ran without any source edit: `make_rk c0` in `Src/Base`
(with its helper scripts on PATH) generated `rksuite_90.f90`. The README gives no
compile, link or run command for the module or the example, so the gfortran lines that
compile and link `eg_simple_c0_a` are ours. That is why the basis is `patched`, and the
build-only record (`verify_sources record`, exit 0) shows no shipped source changed; the
only file added was `Src/Base/rksuite_90.f90`, produced by the authors' own `make_rk`.
The original attempt is `partial` (make_rk ran, nothing documented compiles the example).

## Exact command

    bash reports/brankin1997-rksuite90-771/recipe.sh

It fetches `netlib.org/toms/771.gz` (sha256 checked), unpacks it with `sh`, runs the build
through `tools/sandbox.sh`, runs each pass through the sandbox, and prints the
`VALUE calls to F, eg_simple_c0_a 117` line.

## Environment pins

- Archive: `netlib.org/toms/771.gz`, sha256 `e1babc0304d142e28b54e6fe10c54824db27c08950a2b404426e23a97d2dab46`.
- Toolchain: GNU Fortran (conda-forge gcc 16.2.0-7), version 16.2.0, via micromamba from conda-forge
  (`evidence/toolchain-version.log`).
- Sandbox: `tools/sandbox.sh`, read-only root, no network after the fetch step.

## Caveats

- The count is an integer from an adaptive step-size scheme on a fixed problem. Only the
  count is compared. The printed solution table and error estimates are not part of the
  claim.
- The article was not read, so no paper value is used.
- G5 replay not yet run (`replay-due` will be RED for this result until a replay runs).

## Evidence

`reports/brankin1997-rksuite90-771/evidence/`: `fetch-toolchain.log`, `unpack.log`,
`pass1-build.log`, `pass1-run.log`, `pass2-run.log`, `pass1-output.txt`, `pass2-output.txt`,
`reference-block.txt`, `reference/eg_simple_c0_a.r`, `values.txt`, `record.log`,
`toolchain-version.log`, `recipe-run.log`, and the manifests `manifest.pre`, `manifest.mid`,
`manifest.post`.

Stack class `Fortran`, field class `numerics`.
