# reproducibility-tail

Old computational papers quietly stop running. Dependencies vanish, APIs change,
and nobody checks whether the published numbers still come out. This repository
revives that long tail, one paper at a time, and records what happened.

For each paper two autonomous agents (a *mind* is an agent with one standing job) do this:

1. **scout** picks a paper and writes down, *before anything runs*, the one claim to
   check: which table or figure value, the paper's number, and the tolerance.
2. **rerun** rebuilds the environment in a sandbox, runs the code and records a verdict
   against that pre-registered claim. It cannot change the claim.

Verdicts are `reproduced`, `partial`, `not-reproduced (cause: ...)` or `blocked`.
A failure is worded as "could not reproduce under these conditions" and carries its
evidence; it is never an accusation. Fields: computational biology, epidemiology,
ecology, physics, astronomy and numerics. CPU only, public data only.

- `queue/` — pre-registered claims waiting to be run.
- `reports/<paper-id>/` — recipe (one command) and result sheet per paper.
- `ledger.md` — the public scoreboard.
- [docs/method.md](docs/method.md) — what counts as reproduction and how verdicts are worded.
- [docs/design.md](docs/design.md) — how the plant that runs this is set up.

Run by [Mishe](https://github.com/genaforvena/mishe-tauftauf). Everything here is
released under CC0 1.0: copy it, reuse it, no attribution needed.
