# thompson2013-incgamneg-926: result (reproduced, against the shipped reference)

**Claim.** TOMS 926 (I. Thompson, incomplete gamma functions with negative arguments, ACM TOMS 39(2), 2013). The artifact's
own summary (`Fortran/Driver/RES`, menu 2 with the shipped Maple data, summary mode 1): 30540 evaluations with 53 correct
binary digits (tol +/-100), out of 51051 evaluations in total (exact). The claim is the shipped reference output, not a
table read from the article (ACM refuses it from this sandbox).

**Verdict: reproduced, basis original.** The authors' documented build ran as shipped, and its summary matches the
reference line for line.

| value | paper | tol | ours |
|---|---|---|---|
| occurrences at 53 correct digits | 30540 | 100 | 30540 |
| total evaluations | 51051 | 0 | 51051 |

**Original attempt (G1) succeeded.** `Doc/manual.tex` gives the gfortran flags `-c -std=f2003 -cpp` for
`in_gamma_sequence.f90`. The driver was built with the same flags against that module and run with `printf '2\n1\n'`.
The gfortran warning "Illegal preprocessor directive" concerns the `#endif` lines, which `-cpp` handles.
No source file was changed. Log: `evidence/original-attempt.log`.

**Replays.** The recipe run (14:15:20Z) and two clean `tools/replay.py` runs (14:15:35Z, 14:16:57Z) agree with the record.
Logs: `evidence/replay-2026-11-27T141535Z.log`, `evidence/replay-2026-11-27T141657Z.log`.

**Environment.** Sandbox `tools/sandbox.sh`; gfortran 16.2.0 (conda-forge `gfortran_linux-64`, micromamba);
archive `netlib.org/toms/926.zip` sha256 `673f9f6ef6a8f7b563d8869d4dff95bda88c246cd08eac15ca66474afda2b3fe`;
the shipped `RES` sha256 `b50daeaa260d4bcf26e56d72f5b76dbf00f388ef99baea87e37aa057f79b870e`.

**Exact command.** `bash reports/thompson2013-incgamneg-926/recipe.sh` (writes the `VALUE` lines the replay reads).
