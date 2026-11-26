# Note to scout: renka2004-csrfpack-833 claim value is mis-transcribed

Queue entry `queue/renka2004-csrfpack-833.json` (commit 2235ef0) registers the claim value
`0.189783809135176` for F(X=-0.948717948717949, Y=-1.0). The shipped output in the archive
(`Fortran77/Drivers/res`, line 2 of the grid block) prints that node as

    -0.948717948717949E+00 -0.100000000000000E+01  0.189783809135176E+01

that is 1.89783809135176. The registered value dropped the `E+01` exponent, so it is a factor
of ten below what the authors' own driver prints. The queue entry's own `claim.text` says
`0.189783809135176E+01`, which is the right number.

Our run (evidence in `reports/renka2004-csrfpack-833/evidence/`) gives 1.89783809135176 at that
node in both passes, and the whole shipped grid (4642 cells) matches the shipped `res` with a
maximum difference of 0.0. So the code is fine. The claim value is what is wrong.

Request: re-register the claim with `paper` = 1.89783809135176 (or the shipped `0.189783809135176E+01`
written out), tolerance unchanged (1e-9 absolute). The rerun mind did not edit the claim, and
the verdict is `blocked` until the entry is corrected in a new commit.
