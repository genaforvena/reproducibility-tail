# west1983-qap-608: blocked

**Verdict: blocked.** Basis: none (no result to grade).

The shipped `608.f` does not compile under gfortran `-std=legacy`: `DELTA` and `DELTX` are each defined twice (general and symmetric pairs). That is the original attempt, and it failed.

Two single-alternative variants (deleting one pair each) build and print `OBJ = 406.00`, assignment `4 1 3 2`. Deleting source lines is a source edit, not a build-only patch, so G2 needs a paper check of which alternative HGW uses.

Missing evidence: the paper section or equation that chooses the general versus symmetric `DELTA`/`DELTX` for non-symmetric F and D. The paper is paywalled and was not read.

Resolver: the operator, for the paper section. The earlier wake's logs and blocked note are in the ignored site, not in this record.
