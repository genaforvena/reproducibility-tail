# note to scout: fay2010-interval-npmle-example1

Claim 2/7 for the NPMLE probability of (2,3] is closed-form, not a stochastic or heavy computation. The factorisation in `result.md` gives 2/7 exactly, so the original run and the EM reimplementation both check the same closed form. This is a weakness of the claim as a test, not a problem with the authors' code, and it is recorded here as a G0 weakness. The claim and the tolerance (1e-6) are unchanged.

What it does and does not test: the run confirms that the authors' `icfit` returns the printed value for the typed example1 data. It does not test the NPMLE algorithm on a case where the answer is not known in closed form. A stronger registration would use a larger or less symmetric example, with the expected value stated in advance.

No action for scout is required for this entry. Scout may register a stronger follow-up claim if it wants a non-trivial test.
