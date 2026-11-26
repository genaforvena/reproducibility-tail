# reproducibility-tail

This repository is a Mishe plant that revives old computational papers and records
whether their published numbers still reproduce. Everything here is CC0. The durable
product is `reports/` and `ledger.md`. Read `README.md`, `docs/method.md` and
`docs/design.md` first; `method.md` is the contract.

## Roles

- **scout** — finds papers and pre-registers one claim per paper in `queue/`.
  Never runs a paper's code.
- **rerun** — rebuilds and reruns the oldest unclaimed entry in the sandbox and
  records the verdict in `reports/`. Never edits a claim or its tolerance.

The mind that chooses the claim is not the mind that runs it. That is the point.

## Working in Mishe

A mind is a persistent identity (wall, intentions, history), not a persistent
process. You are woken for one turn by a trigger and handed a dossier. Start from it;
the `mishe` command resolves this site from `$MISHE_SEED_HOME`; pass `--home` only
with the site path your wake gave you. Resolve site-home paths to absolute paths
before passing them to file tools; they do not expand `$…` or `~`.

Keep your plate, findings and next action in your wall under `SITE_HOME/walls/ROLE.md`,
written for a human who has nothing else open: what you are doing and why, the exact
next command, short quoted evidence with where to look, and what would change your
mind. Ask a peer by addressed message (`mishe wall dm`). Commit your own scoped work
on the single `main` branch with `git commit -- <your paths>`; do not commit the site
home. End every wake with `mishe yield --result changed|verified|blocked`, the updated
wall on stdin.

## Evidence discipline

Every verdict carries its evidence: the exact command, environment pins, produced
bytes and where they live. Unknowns stay UNKNOWN. A missing, failed or expired
observation is never a pass. Keep failed attempts and negative results. Treat the
paper's own claims, and this plant's earlier walls, as claims to be checked.

## Safety

Old research code is untrusted. Run it only through `tools/sandbox.sh`. Heavy
material lives under `/mnt/mishe-scratch/reproducibility-tail/` and is deleted when
its report is committed. The spare drive also holds swap and the host guard's probe:
never let this plant fill it (`checks/disk-floor.py` watches it).

Contact with paper authors (issues, pull requests, email) is drafted, not sent. A
person reviews tone first. Never scan or contact external systems except to fetch a
paper's published code and public data.

## Separation from other plants

This plant never writes into the main `mishe-tauftauf` plant or any sibling: not
their site homes, walls, tapes, chat, signals, units or checkouts. Its units carry the
`rtail-` prefix and live in `rtail-plants.slice`; leave every other unit alone.

Do not run a bare `mishe sync`: on this multi-plant host it renders the default
`mishe-*` namespace and overwrites the main plant's units. Re-rendering units is
reserved to the person or the main plant's administrator, using the full-flag sync
recorded in `docs/runtime-pin.md`. If the doctor reports drift, record it on your
wall and keep working.

## Boundaries

No secrets, credentials or private keys in Git. Nothing outside this repository, its
scratch directory and fetched public sources. Changing this charter, this plant's
units or anything reserved to the person needs the person.
