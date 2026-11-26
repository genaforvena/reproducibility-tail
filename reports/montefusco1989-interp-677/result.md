# montefusco1989-interp-677: Algorithm 677 (MASUB scattered-data interpolation, self-check), TOMS 677, Fortran 77

**Claim (pre-registered, unchanged):** the self-check PROGRAM MAIN of TOMS 677 prints ERMAX and ERMEAN for the 10x10
reconstruction (IEX=1, TP=10). Built-in references ANS2 = 0.6059994 (max) and ANS1 = 0.06695094 (mean), relative
tolerance 1e-5 on each.

**Measured:** ERMAX 0.6059995 (pass 1, gfortran -O2) and 0.6059992 (pass 2, clean directory, -O0 rebuild);
ERMEAN 0.06695094 on both. Both are inside the registered tolerance.

**Verdict: `blocked` at G2.** Not `reproduced` yet. Basis would be `patched`.

## Why it is blocked

- The archive as shipped does not compile: four test PROGRAMs in one file (`Error: Two main PROGRAMs`). Original attempt
  failed; log in `evidence/original-attempt.log`.
- The build compiles two units cut from that file by line range: `677main.f` (lines 1-162, the first PROGRAM MAIN with
  its MACEPS and MMERR) and `masub.f` (lines 634 to the end, the MASUB package). The text is verbatim, but the compiled
  files are not the authors' file, so this is a source patch, not a build-only one.
- The build-only manifest record correctly exits 2: `kind: source`, `677.f` removed, `677main.f` and `masub.f` added
  (`evidence/manifest.*`). Under the method, G2 needs a paper check (the extraction and the MASUB package against the paper).
- Resolver: scout (paper check). Nothing else is waiting on it.

## What changed in this wake

- Archive sha256 `d4d94e7a...` is now registered by scout (queue commit 9d5f485), and the recipe's fetch check passes.
- The recipe's mid manifest now covers the compiled units (`$W/src`) rather than the authors' tree; before, the record
  said `build-only` while the compiler read different files. Corrected here.

## Command

`reports/montefusco1989-interp-677/recipe.sh` (fetches 677.gz and gfortran via micromamba into the sandbox scratch,
rebuilds, runs two passes; logs in `evidence/`).

## What would change the verdict

- Scout's paper check passes the two extracted units as faithful to the paper's MASUB and the self-check: then `reproduced`,
  basis `patched`, G2 `pass`.
- Scout finds the extraction changes what the claim measures: then the verdict is `blocked` with the reason.
