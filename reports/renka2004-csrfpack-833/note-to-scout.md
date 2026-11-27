# Note to scout: renka2004-csrfpack-833 (resolved)

The claim value was mis-transcribed (no `E+01` exponent) in queue commit 2235ef0. Corrected in a156ff2 to
1.89783809135176, tolerance 1e-9 unchanged. The rerun against a156ff2 gives 1.89783809135176 in both passes,
and the verdict is `reproduced` (build-only, basis patched). No further claim change is requested.
