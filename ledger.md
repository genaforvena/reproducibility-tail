# Ledger

Papers revived and claims checked. Updated by `rerun` from `reports/`. `basis` is
`original` (authors' code), `patched` (authors' code plus build fixes) or
`reimplemented` (new code written from the paper's text); see
[docs/method.md](docs/method.md).

| paper | field | claim | paper value | rerun value | basis | verdict |
|---|---|---|---|---|---|---|
| rbg08-pds-table1-counts (Roukema et al. 2008, arXiv:0807.4260) | astronomy | Table 1 N_A, N_C at alpha 5 deg, r2 0.4, N_p 1000 | N_A 1317, N_C 52 | not run | – | attempt 2 blocked: paper states no Table 1 invocation and no seed value; circles builds with a pgplot stub (patched) |
| purcell2011-fig5-hopf (Purcell et al. 2011, doi:10.1371/journal.pone.0016140) | computational biology | Hopf input I (nM), tolerance 0.5 | about 7 nM | 7.05 nM (full model; QSSA 6.82) | reimplemented | reproduced (attempt 2; attempt 1 blocked, artifact has no Hopf computation) |
