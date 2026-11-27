# renka1999-tshep2d-791: result

**Verdict:** reproduced
**Basis:** patched (build-only: the compiler is gfortran, which the PackingList does not name; sources unedited)
**Paper:** Algorithm 791, TSHEP2D (cosine-series Shepard method for bivariate scattered-data interpolation, Renka, 1999). The article was not read; the claim is the shipped `res1_2` output.

## Claim

Average SSE/SSM over the ten test functions, node set 1, NC 17, NW 30, NR 6, is 0.006063 (shipped `res1_2`), tolerance 1e-5 absolute.

| Value | Paper (shipped) | Ours | Tolerance | Result |
|---|---|---|---|---|
| average SSE/SSM, node set 1, NC 17, NW 30, NR 6 | 0.006063 | 0.006063 | 1e-5 abs | agrees |

## Original attempt (G1, kept)

The PackingList's build (`driver1.f`, `src_792.f`, `Src`) and `data1` on stdin were followed with gfortran. The PackingList names no compiler, so the run is recorded as partial in the strict sense, as with `watson1997-hompack90-777`. No step of the authors' procedure failed. Log: `reports/renka1999-tshep2d-791/evidence/pass1-build.log`.

## Command and pins

- Recipe: `reports/renka1999-tshep2d-791/recipe.sh`
- Build: `gfortran -std=legacy -w -o ts2tst driver1.f src_792.f ../../Src/Sp/src.f` in `Drivers/Sp`
- Run: `ts2tst` with `data1` on stdin; the shipped `res1_2` is deleted from the build copy before each run and rewritten by the run.
- Archive: `netlib.org/toms/791.gz`, sha256 `733ee80b3ec4d9b5a6dcf443bb4053924f25b3339486bb3e3df6b91cf31793ac`
- Build-only check: 4 files compared, none modified, removed or added (`evidence/manifest.pre`, `manifest.mid`, `manifest.post`).

## Passes and replay

- Pass 1 and pass 2 `res1_2` are byte-identical to the shipped `res1_2` (`evidence/pass1-res1_2.txt`, `evidence/pass2-res1_2.txt`, `evidence/values.txt`).
- Printed precision is 6 decimals, so agreement is at the printed value, within the registered tolerance.
- G5 clean replay, 2026-11-27T03:08:55Z: agrees with the record (`evidence/replay-2026-11-27T030855Z.log`).

## Evidence

`reports/renka1999-tshep2d-791/evidence/`: the pass logs, `values.txt`, `reference/res1_2`, manifests, and the replay log. The machine-readable record is `result.json`.

Result written 2026-11-27 from the committed `result.json` and evidence (the prose had not been written when the entry was first reproduced).
