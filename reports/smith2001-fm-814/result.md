# smith2001-fm-814: result

**Verdict:** reproduced
**Basis:** patched (build-only: an `f90` one-line wrapper around gfortran; sources unedited)
**Paper:** Algorithm 814, Fortran 90 multiple-precision package FM (sample driver). The article was not read; the claim is the shipped `SAMPLE.CHK` sample 3 value.

## Claim

`SampleFM` (sample 3, Zeta(3) by Gosper's series at 60 digits in the FM package) prints Zeta(3) = 1.202056903159594285...; the value rounded to double, 1.2020569031595942, must agree within absolute tolerance 1e-15 (registered in the queue entry).

| Value | Paper (reference) | Ours | Tolerance | Result |
|---|---|---|---|---|
| Zeta(3) sample 3 | 1.2020569031595942 | 1.2020569031595942 | 1e-15 abs | agrees |

## Original attempt (G1, kept)

The ReadMe's build uses `f90`, which is absent on the host and in the sandbox. The first build command stops with `f90: not found` (build_exit 127). Log: `reports/smith2001-fm-814/evidence/original-attempt.txt`.

## Patch

`f90` was supplied as a one-line wrapper to gfortran, translating the ReadMe's `-f free` to `-ffree-form`. All five ReadMe commands were run unchanged, in one flat build directory (the Src modules and the driver must share it for the `USE` statements to find the `.mod` files). The wrapper is outside the source tree. Build-only check: 4 files compared, no modification, removal or addition in the manifests (`evidence/manifest.pre`, `manifest.mid`, `manifest.post`).

## Command and pins

- Recipe: `reports/smith2001-fm-814/recipe.sh`
- Build commands: `f90 FMSAVE.f90 -c -f free -o FMSAVE.o`, `f90 FMZM90.f90 -c -f free -o FMZM90.o`, `f90 FM.f90 -O -c -f free -o FM.o`, `f90 SampleFM.f90 -c -f free -o SampleFM.o`, `f90 SampleFM.o FMSAVE.o FMZM90.o FM.o -o SampleFM`
- Archive: `netlib.org/toms/814.gz`, sha256 `033afcb275570c5fdfd47c18e717523dd5c3b70b740ef2ad0e6daac24a25da22`

## Passes and replay

- Two clean rebuild-and-run passes both print `Zeta(3) = 1.2020569031595942` and the program's last line `All results were ok.` (`evidence/SAMPLE.LOG`, `evidence/values.txt`, `evidence/runs.log`).
- G5 clean replay, 2026-11-27T01:21:42Z: agrees with the record (`evidence/replay-2026-11-27T012142Z.log`).

## Evidence

`reports/smith2001-fm-814/evidence/`: `original-attempt.txt`, `unpack.log`, `build.log`, `runs.log`, `SAMPLE.LOG`, `values.txt`, `reference/SAMPLE.CHK`, manifests, and the replay log. The machine-readable record is `result.json`.

Result written 2026-11-27 from the committed `result.json` and evidence (the prose had not been written when the entry was first reproduced).
