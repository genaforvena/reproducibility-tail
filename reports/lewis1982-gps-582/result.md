# lewis1982-gps-582: TOMS 582 (GPS and GK bandwidth and profile reduction)

**Verdict: reproduced.** Basis `patched` (extraction). The shipped sample output reproduces exactly.

- Claim (shipped sample output, BCSPWR01, GPSKCA): BANDWIDTH 6, PROFILE 100, GPSKCA ERROR CODE 0 (exact).
- Our run: BANDWIDTH 6, PROFILE 100, GPSKCA ERROR CODE 0.
- Original attempt (G1): the listing as delivered is not Fortran (it also holds the sample input and the authors' output).
  `gfortran -x f77` stops with `Error: Two main PROGRAMs`. Kept in `evidence/original-attempt.log`.
- Extraction: lines 1 to 3762 (algorithms and driver) are copied verbatim from the archive to `gps.f`. The sample input
  (lines 3764 to 3947) is piped to the driver's standard input and is not a new file. No line is edited (manifests pre, mid
  and post recorded; one added file, `gps.f`, as the recorded range).
- Build: `gfortran -std=legacy -c gps.f`, `gfortran gps.o -o driver`. Warnings only (array bounds in GPSKCA's internals), exit 0.
- Replay (G5): clean rerun agrees with the record (`evidence/replay-2026-11-27T062056Z.log`).

Evidence: `evidence/` (fetch, original attempt, build, run logs, `shipped-output-block.txt` sha256 in result.json).
Command: `reports/lewis1982-gps-582/recipe.sh`. Pins: archive `582.gz` sha256 6b71e42f...; gfortran 16 (conda-forge) in the sandbox.
