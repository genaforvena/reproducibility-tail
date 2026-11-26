# akima1996-sdbi3p-761: Algorithm 761 (SDBI3P scattered-data interpolation)

**Verdict: reproduced** (basis: original). Claim source: the authors' shipped result file `res` (artifact-reference), six registered `ZI1(XI,YI)` values, tolerance 0.011 absolute.

| value | paper (shipped res) | ours | difference |
|---|---|---|---|
| ZI1(XI=5, YI=5) | 39.37 | 39.37 | 0.00 |
| ZI1(XI=10, YI=10) | 16.36 | 16.36 | 0.00 |
| ZI1(XI=15, YI=10) | 12.98 | 12.98 | 0.00 |
| ZI1(XI=20, YI=15) | 6.95 | 6.95 | 0.00 |
| ZI1(XI=10, YI=15) | 22.34 | 22.34 | 0.00 |
| ZI1(XI=15, YI=5) | 20.17 | 20.17 | 0.00 |

## Method

- Archive: `https://netlib.org/toms/761.gz`, sha256 `373f9524...` (matches the queue entry). It is a shell archive with leading text; the part from `#! /bin/sh` on is unpacked in the sandbox.
- Toolchain: conda-forge gfortran installed in the sandbox fetch step (`x86_64-conda-linux-gnu-gfortran`). No source file was changed.
- Pass 1: `gfortran -O2` build of `driver.f`, `src.f`, `tripack.f`, run in a scratch directory.
- Pass 2: clean directory, `gfortran -O0` rebuild. Pass 1 and pass 2 outputs are byte-identical.
- The whole reproduced `res` matches the shipped reference (`evidence/reference/res`, sha256 `ceb003ed...`) except the first byte of the two page-title lines (carriage control: 0x80 in the shipped file, form feed from our run).
- Exact command: `reports/akima1996-sdbi3p-761/recipe.sh`. Pins: GNU Fortran (conda-forge gcc 16.2.0-7) 16.2.0, from conda-forge via micromamba (`evidence/gfortran-version.txt`); the sandbox root is read-only.

## Caveats

- Four of the six registered values (16.36, 22.34, 12.98, 20.17) also equal the driver's expected table ZIE to two decimals. The other two differ from ZIE (39.37 vs 39.32, 6.95 vs 7.52), and ZI1 is computed by SDBI3P, not copied from the input.
- The shipped `res` shows non-zero DZI differences (up to 0.57), where the driver comment says they should be zero. These are reproduced exactly and are not part of the claim.
- The shipped reference is the authors' own output: this shows the old code still does what its authors saw, not that the paper's broader claims hold.

## Attempt log

- `evidence/attempt0-wrong-compiler-path.log`: the first recipe run used the wrong compiler binary name (`gfortran`, not installed in the micromamba env). Fixed to the installed `x86_64-conda-linux-gnu-gfortran`; this is a fetch-step path error, not a result.
- `evidence/original-attempt.log`: compile of the shipped sources, exit 0.

## Gates

G1 pass (original, succeeded), G3 pass (two passes identical), G5 not yet (scheduled replay), G6 not applicable (reproduced).
