# alhargan2006-mathieu-855: result

**Claim.** TOMS 855 (Alhargan, Mathieu characteristic numbers), shipped reference output
`CPP/Dp/Drivers/Res`, Table 2 (nu = 10.5), row t = 1.50, column c = 130.971685, absolute tolerance 1e-6.
Source: artifact-reference (netlib.org/toms/855.zip, sha256 3ed63d43...).

**Our value.** 130.971685 in pass 1 (g++ -O0) and pass 2 (g++ -O2, separate directory). The shipped Res
row prints the same 6-decimal value (`1.50 & 128.651417 & 130.971685 & 131.316300 & ...`).

**Verdict.** reproduced. **Basis:** patched (build-only). Gates G1, G2, G3 pass; G5 not yet run.

**Original attempt (G1).** The authors' `Doc/Makefile` includes `makefile.inc`, which is not in the
archive, so `make` stops with "No rule to make target 'makefile.inc'". Log: `evidence/original-attempt.log`.

**Build-only patch (G2).** The archive has no compiler settings. The authors' `driver.cpp`, `mcnr.cpp`
and `mcnf.cpp` are compiled with `g++ -O0` out of tree, then linked. No source file is edited. Three
manifests (`evidence/manifest.{pre,mid,post}`) and `verify_sources record` give build-only, exit 0.

**Exact command.** `bash reports/alhargan2006-mathieu-855/recipe.sh` (fetch, sha check, build, two passes).
It prints `VALUE Table 2, nu=10.5, t=1.50, c 130.971685`.

**Environment pins.** g++ 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1); archive sha256 3ed63d43...;
sources: mcnf.cpp 5020de67..., mcnr.cpp 7ff384c1..., driver.cpp 894f7f71... (from the manifest).

**Evidence.** `reports/alhargan2006-mathieu-855/evidence/`: fetch log, original attempt, build log,
pass-1 and pass-2 logs (full driver `data.txt`), value files, the shipped `Res`, and the manifests.

**Queue note.** The registration put the archive digest only in `code.commit`, which the G2 gate
does not read. Commit `5fd665a` adds `code.archive` with the same digest. The claim value and tolerance
are unchanged.
