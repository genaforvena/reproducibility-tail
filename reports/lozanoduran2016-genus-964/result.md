# lozanoduran2016-genus-964: reproduced (basis: patched, build-only)

**Claim (registered, queue commit 14192c5):** genus of the Random2 case, paper Table III, 87325, absolute tolerance 0.
The dataset is the shipped `Fortran90/data/random.128.dat` (128 x 128 x 128). The claim cannot move: it is an integer count.

**Our value:** genus 87325 (faces 2744830, edges 5489660, vertices 2570182). The first three are extra observations; the
queue entry's Table III row lists the same numbers. Only genus is a claimed value.

**Verdict:** reproduced. **Basis:** patched, build-only.

## What was done

1. **Original attempt (G1).** `make genus` as the Makefile documents it stops at the first compile with
   `nagfor: not found` (the Makefile sets `F90 = nagfor`; ifort is the line before it). The sandbox has neither.
   Log: `evidence/original-attempt.log`.
2. **Patch (build-only).** Nothing in the source tree is edited. The build names gfortran on the make command line:
   `make genus F90=gfortran`. The authors' rules and flags (`-c -O3`, link `-O3`) are unchanged. The manifests
   before the patch, before the build and after the build are identical across 7 source and build-configuration
   files (`evidence/manifest.{pre,mid,post}`), so the patch is build-only under `docs/method.md`.
3. **Run.** `./genus ../../data/random.128.dat` inside the sandbox. Output in `evidence/run.txt`.
4. **Replay (G5).** A clean run from an empty scratch directory agrees with the record: `evidence/replay-2026-11-27T063628Z.log`.

## Environment pins

- Archive: netlib `964.zip`, sha256 `eb7b9a946d9b87a49972ed1740a0a38d9669ae281efd645240abe1c7c5cec496` (matches the queue entry).
- Compiler: gfortran from conda-forge through micromamba, installed inside the sandbox (`/work/env`). The recipe does not record its version number; `evidence/build.log` shows the build only.
- Sandbox: `tools/sandbox.sh` with read-only root, no network after fetch, memory, CPU and time caps.

## Exact command

`reports/lozanoduran2016-genus-964/recipe.sh` (rebuilds and reruns everything). The build command is `make genus F90=gfortran`.

## Where the evidence lives

`reports/lozanoduran2016-genus-964/evidence/`: `original-attempt.log`, `build.log`, `recipe-run.log`, `run.txt`,
the manifests, and the replay log. Full record: `result.json`.

## Caveats

- The paper check of G2 is not needed (build-only). The claim is an integer from Table III of the arXiv read copy. The
  published TOMS version may differ; this record compares against the arXiv text, as the queue entry says.
- The run used the dataset the archive ships. The documentation says that dataset reproduces Random2.
