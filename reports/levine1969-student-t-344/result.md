# levine1969-student-t-344: result

**Paper:** TOMS 344, Student's t distribution (TTEST), a Fortran routine for the Student t CDF.
Stack: Fortran. Field: statistics.

**Claim (artifact-reference, registered 2026-11-26T20:14Z):** the computed CDF printed by TOMS344_PRB for DF=1,
X=0.3250 (row 1, computed column) is 0.7999537587165833, as in the shipped reference output `res`. Absolute
tolerance 1e-6.

## Verdict

- **Verdict:** reproduced
- **Basis:** patched (build-only)
- **Our value:** 0.7999537587165833 in both passes. The difference from the registered value is 0.

## Original attempt (G1)

The shipped `Drivers/Makefile` compiles `src.f` from the Drivers directory, with no path in the rule. `src.f` ships in
`Src/`, so the documented make stops: `make: *** No rule to make target 'src.f', needed by 'src.o'. Stop.` (after
driver.f compiles). Log: `evidence/original-attempt.log`.

## Patch (build-only, G2)

`VPATH=../Src` does not help, because the compile command still names `src.f` bare. The same three compiles run out
of tree with the makefile's own flags (`gfortran -O0`):

    gfortran -O0 -c /work/build/Drivers/driver.f -o driver.o
    gfortran -O0 -c /work/build/Src/src.f -o src.o
    gfortran -O0 -o driver driver.o src.o

Three manifests were taken (`evidence/manifest.{pre,mid,post}`). The record has `kind: build-only`, with nothing
modified, removed or added between pre and mid.

## Runs (G3)

Two passes, each in a clean sandbox directory. Both print row 1 as `0.7999537587165833`. Evidence:
`evidence/run1-out.txt`, `evidence/run2-out.txt`, and `evidence/reference/res` (the shipped file, copied unedited and
hash-checked in `result.json`).

## Environment

- Archive: `netlib.org/toms/344.gz`, sha256 `053ed92f6d08c5d8d2f7f92dcba8698d2bede20c29293e0564cfc62da8c66866`.
- Compiler: gfortran from conda-forge (micromamba, installed in the sandbox scratch during fetch).
- Licence: the netlib TOMS code is under the ACM licence. The licence text is not recorded here.

## Reproduce

    bash reports/levine1969-student-t-344/recipe.sh

The recipe fetches and hash-checks the archive, installs gfortran into the sandbox scratch on first run, builds
out of tree, runs twice, and prints `VALUE` lines. G5 replay has not been run yet (no `replayed` entries).

## Limits

The paper was not read; the claim rests on the shipped `res` output. This shows the shipped code reproduces its
own reference at one row, not that the routine is correct against an independent reference.
