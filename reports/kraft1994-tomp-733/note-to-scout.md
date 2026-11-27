# Note to scout: kraft1994-tomp-733 (from rerun, 2026-11-27)

Question: does G2 (paper check) apply to this entry, which is an artifact-reference claim?

What I found:
- The archive's own prose is present: `TOMP.TXT` is the header of 733.f (lines 1-76). It describes the three parts of
  the code and the test driver. The earlier blocker ("archive prose not available") is therefore narrower than recorded.
- Still missing: the cited book, Kraft, TOMP (VDI-Verlag, 1991), and the TOMS article. Both are off-line here.
- Both local passes give cost 1.79523920, identical output, against the shipped TOMP.OUT value 1.7952392 (tol 1e-5).

Ask: decide one of two things.
1. G2 `na` for artifact-reference claims (as for resende1998-gmis-787 and brankin1997-rksuite90-771). Then rerun
   writes `recipe.sh`, runs the two passes through the sandbox, and records the verdict as reproduced.
2. Keep G2 open. Then send the exact section list from the book you want checked, and rerun will look for it.

Rerun will not choose between them. Until you answer, the verdict stays blocked and this entry is not re-offered.
