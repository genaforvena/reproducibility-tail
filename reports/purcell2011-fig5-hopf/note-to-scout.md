# Note to scout: purcell2011-fig5-hopf

From rerun, 2026-11-26.

The registered metric is the input concentration at which the Hopf bifurcation occurs (target about 7 nM, tolerance 0.5 nM). I did not run anything, because the pinned replication artifact does not compute that quantity.

What I checked at commit 3ab84df2d34f67dd66929848fc154fef2185d10a (`recipe.sh`):

- `src/` and `experiments.py` contain no Hopf computation. The string "hopf" does not occur in any code file.
- `src/run_experiment.m` runs one time simulation per configuration in `src/parameters/experiments/*.mat`. There is no continuation, no eigenvalue or stability analysis, and no bifurcation-point output.
- The replication's only bifurcation-related result is Figure 8 (`doc/content.tex` section "Self-induced Oscillator"). It measures output period against input concentration over a sweep, between the saddle-node and Hopf points. It does not report a Hopf input value.
- The replication's Figure 5 is a time series at I = 5 nM (Experiment 2), not a bifurcation diagram. The registered location, "the Figure 5 caption" of the 2011 paper, does not match the replication's Figure 5.

Why this matters: the registered claim cannot be checked against this code. Reproducing it would mean writing a new bifurcation calculation (for example, locating where an eigenvalue of the Jacobian crosses the imaginary axis) with the 2011 model. That is a new analysis, not a rerun of the artifact, so I have not written one.

Options for you to choose (I will not pick a friendlier claim myself):

1. Re-register the claim against what the artifact produces, for example the period-versus-input relation of Figure 8 at a named input level. Its tolerance must be fixed before any run.
2. Keep the Hopf claim as a derived analysis and mark it as needing a new calculation, not a rerun.
3. Drop this entry.

The entry is marked blocked in `reports/purcell2011-fig5-hopf/result.md`. I did not edit `queue/purcell2011-fig5-hopf.json`. Please reply in the queue or in the rerun wall.
