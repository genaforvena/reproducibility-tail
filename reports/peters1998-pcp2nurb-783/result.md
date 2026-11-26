# peters1998-pcp2nurb-783: result

**Paper:** Peters, J. (1998). Algorithm 783: Pcp2Nurb, smooth free-form surfacing with linearly trimmed bicubic
B-splines. ACM TOMS 24(3), 261-267. Stack: C. Field: numerics (surface modelling, NURBS).

**Claim (artifact-reference, registered 2026-11-26T20:00Z):** the first control point of the first NurbsSurface
printed by `driver1` with blend ratio 0.5 is (0.493056, 1.868056, 0.972222), as in the shipped reference output
`C/Drivers/Sp/RES1` (first Coordinate3 block, point 1). Absolute tolerance 1e-5 per component.

The queue entry holds the three values as one list. The gate needs one numeric paper value per entry, so the
result records them as three scalar values (x, y, z) with the same numbers and the same tolerance. The queue entry
was not edited.

## Verdict

- **Verdict:** reproduced
- **Basis:** patched (build-only)
- **Our value:** 0.493056, 1.868056, 0.972222 (both passes), each within 1e-5 of the registered value. The differences are 0.

## Original attempt (G1)

The header's documented commands name `nurb_iv1.c` and `pcp2nurb.c`. The shar ships `driver1.c` and `src.c`. The
documented compile therefore fails at once: `cc: pcp2nurb.c: No such file or directory`. Log:
`evidence/original-attempt.log` (a second log, `original-attempt-rebuild.log`, comes from the rerun).

## Patch (build-only, G2)

Nothing in the source was edited. The same files are compiled under their shipped names, out of tree:

    cc -g -c /work/build/Drivers/Sp/driver1.c -o driver1.o
    cc -g -c /work/build/Src/Sp/src.c -o src.o
    cc -g -o nurb_iv1 driver1.o src.o -lm

Three manifests (pre, mid, post) were taken: `evidence/manifest.{pre,mid,post}`. The record has
`kind: build-only`, with nothing modified, removed or added between pre and mid, so the paper check of G2 was not
needed.

## Runs (G3)

Two passes, each in its own clean directory in the sandbox (`nurb_iv1 0.5`). Both print point 1 as
`0.493056 1.868056 0.972222`. Evidence: `evidence/run1-out.iv`, `evidence/run2-out.iv`, and the point files.
`evidence/reference/RES1` is the shipped reference, copied unedited and hash-checked in `result.json`.

## Environment

- Archive: `netlib.org/toms/783.gz`, sha256 `11691adb9b362f2232d25883a1a74b809698f158a27e9a26f910d56d04e2dd87`.
- Compiler: the sandbox's `cc` (gcc from the host `/usr`, read-only bind). The version is not pinned in the recipe.
- Licence: the netlib TOMS code is under the ACM licence. The licence text is not recorded here.

## Reproduce

    bash reports/peters1998-pcp2nurb-783/recipe.sh

The recipe fetches and hash-checks the archive, builds it, runs it twice, and prints `VALUE` lines. G5 replay has
not been run yet (no `replayed` entries).

## Limits

The paper was not read; the claim rests on the shipped RES1 output, which the authors' code must print. Nothing
here shows the printed geometry is correct, only that the shipped code reproduces its own reference.
