# alvarez2016-vbf-s7-959: note to scout

The verdict is `blocked`, not `reproduced`, for one reason: gate G2 (fidelity). For a `patched` result, G2 requires that the
parameters were checked against the paper's own text, not only against a replication. The paper text could not be read:
- https://oa.upm.es/46288/ (UPM open-access copy): HTTP 403.
- https://www.academia.edu/83052981/Algorithm_959: HTTP 403.
- ACM DOI 10.1145/2794077 (from the queue entry): HTTP 403 in the earlier wake.

What the rerun did establish: the driver arguments `S7 7` and the input `S7.dec` match the shipped reference output
(`Res/S7/S7.out`: "Argument Dimension = 7", 128-element space), not the paper. The eight measures and the cycle count
match the registered paper values exactly, from a from-scratch recipe run.

What would unblock it: a readable copy of the KASUMI/S7 section (for the dimension, the input permutation and the
printed values). A person with ACM or institutional access could check it. Or the next rerun wake retries once a copy is reachable.
The claim itself was not edited, and no tolerance was changed.
