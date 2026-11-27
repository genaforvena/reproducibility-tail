# toms1991-colvi2-689: result (blocked)

**Claim.** TOMS Algorithm 689 (COLVI2, Blom and Brunner's nonlinear Volterra solver, Fortran, 1991). PASS 1 of the shipped
test program (DEFOPT=21, REQTOL=1e-3, step 1.0, 50 steps): GLOB.ERR. for the first component at t = 50 is
`-.1165398569E-06` as printed by the driver, i.e. -1.165398569e-07. Tolerance 1e-9 absolute, fixed in the queue entry.

**Verdict: blocked.** The working precision of the build (the Fortran REAL kind) is not stated by the archive, and the
claim's value depends on it. Two measured passes:

| pass | build | GLOB.ERR. (PASS 1) | difference from claim | inside 1e-9? |
|---|---|---|---|---|
| 1 | default gfortran REAL (4 bytes) | -1.147389412e-06 | 9.8e-07 | no |
| 2 | `-fdefault-real-8` (8 bytes) | -1.165395988e-07 | 2.6e-13 | yes |

Pass 2 was run after pass 1 missed, to test the precision hypothesis. It is not a registered pass, and the method
forbids choosing an unstated value until the number matches. So it is recorded, not used as the verdict. The archive
says "MACHINE PRECISION APPROXIMATELY 14 DIGITS" (CYBER 750), which does not name a Fortran kind. The verdict stays
blocked until someone with the authors' build settings (or a person who accepts REAL*8 as the documented precision)
settles it. Once that is settled, the numbers above decide: REAL*8 reproduces, and the default build does not.

**Blocking specification.** Working REAL kind of the authors' build. Second, G2 for the patches: the article text is
not readable from this sandbox (ACM page 403, as for smith1991-fmpack-693), and gate G2 needs the paper's own text.

**Why these patches (all before the build; none in the build step).**
1. Selection of one file from 689.txt: the header (lines 1-132) is removed. The CYBER NCPJOB (lines 6761-6786, which calls
   SECOND) is removed; the VAX NCPJOB is kept. The IMSL block (FILE_7, lines 6873-7054) is removed; the no-IMSL FILE_8 is
   kept. Drivers 2-12 and later outputs are removed (8732 to end). Nothing else is changed.
2. MACHAR: the archive says "THE PROGRAM AS GIVEN HERE MUST BE MODIFIED BEFORE COMPILING" and "CHANGE ALL OCCURRENCES OF
   CS (CD) IN COLUMNS 1 AND 2 TO BLANKS". Without it EPS, EPSNEG, XMIN and XMAX are typed INTEGER (their REAL declaration
   is on a CS line), and INICMC's call fails to compile. The CS prefix is blanked and the CD lines are commented.
3. ETIME: the VAX NCPJOB calls an external ETIME that gfortran does not supply. `impl/etime_shim.f` (written for this
   rerun) supplies it from CPU_TIME. It feeds only the CPU-time limit check.

**Evidence** (in `reports/toms1991-colvi2-689/evidence/`):
- `original-attempt.log`: the archive as shipped, `gfortran -c 689.f`, fails (header text, duplicate definitions, two DRIVER programs).
- `g1-unmodified-machar-attempt.log`: the selection with MACHAR unmodified, fails on the INTEGER/REAL argument mismatch.
- `OUTPUT`: pass 1, default REAL. `OUTPUT-real8`: pass 2, REAL*8.
- `shipped-reference.txt`: the archive's own PASS 1 block (lines 9486-9500 of 689.txt), hash in result.json.
- `fetch.log`, `recipe-run.log`, `manifest.pre/mid/post`.

**Exact commands.** `bash reports/toms1991-colvi2-689/recipe.sh` (it fetches 689.gz, checks sha256
beaa7e6b...085df and the text sha256 048cd1e...087f, installs gfortran by micromamba if missing, makes the selection,
applies the MACHAR patch, builds, and runs PASS 1; pass 2 is a second build with `-fdefault-real-8`). The sandbox is
`tools/sandbox.sh`.

**Environment.** gfortran 16.2.0 (conda-forge gfortran_linux-64, `/work/fortran`), sandbox with no network after fetch.
The archive is netlib.org/toms/689.gz, 81813 bytes, decompressed 450359 bytes.

**Caveats.**
- The count fields (KEV, corrector iterations) and CP seconds are not claimed; CP seconds show 0 in our run.
- Pass 1 SUMMARY has IERROR=0 for PASS 1; PASS 4 prints IERROR=12. Not claimed.
- `manifest.pre` is empty: the manifest tool does not hash `.txt` files, so the archive is checked by its sha256 in the
  fetch step only.
- Pass 2's precision was chosen after pass 1 missed. That is the main reason the verdict is not `reproduced`.

**What would change the verdict.**
- The authors' settings or a documented build confirm REAL*8. Then rerun as a registered second pass, and with the
  article text the G2 check on the patches can be done.
- A G2 check that the authors' own text supports the MACHAR patch and the ETIME shim.
