# Design: the reproducibility-tail plant

Approved 2026-11-26. This is the design for the Mishe *plant* (one running Mishe
installation in one checkout) that does the work described in the README. It is
not installed yet; installing follows review of this document.

## Shape

- Public repo, CC0, tracked content is the work product: `queue/`, `reports/`,
  `ledger.md`, `docs/`. Runs, caches and the plant's local site home are gitignored.
- Plant checkout at `/home/mesh-home/reproducibility-tail` with its own unit prefix,
  unit directory and systemd slice, so it cannot rewrite or squeeze the main plant.
- Starts **held** (`mishe hold on`): no model call until a human has read the first
  3–5 verdicts and released it.

## Two minds

- **scout** — finds candidate papers and writes pre-registered queue entries (see
  [method](method.md)). Woken when the open queue falls below a threshold (about 5).
  Keeps the older-work quota and logs every rejection.
- **rerun** — takes the oldest unclaimed entry, builds the environment, runs it in the
  sandbox and records the verdict under `reports/<paper-id>/`. Woken by a new queue
  entry. May record a result or a diagnosed failure, and may not edit the claim.
  Drafts upstream issues or pull requests but does not send them.

The queue directory is the interface: an entry without a report directory is owed
work. The split gives independence: the mind that chooses the claim is not the mind
that runs it.

## Sandbox

`bwrap` (user namespaces, no root) per run; Docker only when an image is unavoidable,
since docker-group membership is root-equivalent on this host. Read-only root, writes
only to the per-run scratch directory, network only for the dependency-fetch step,
`systemd-run --user` caps on memory, CPU, time and disk, no access to the home
directory, keys or other plants. Old R, Fortran or conda environments come from pinned
images or a micromamba environment inside the sandbox, not from the host.

## Resources and placement

- Heavy, disposable material (environments, caches, scratch) lives under
  `/mnt/mishe-scratch/reproducibility-tail/` on the spare drive (234 GB, 120 GB free at
  design time; it also holds swap and the host guard's `/var/tmp` probe, so it must not
  fill). Plant-wide cap 20 GB, per-run cap 5 GB; a scratch directory is deleted when
  its report is committed and the recipe alone must rebuild it.
- Checkout and site home stay on `/` (small).
- Own slice `reproducibility-tail-plants.slice`: `MemoryHigh=3G`, `MemoryMax=5G`,
  `CPUQuota=200%`, modelled on the existing sibling plant's slice.
- Haiku-class engine for both roles with a daily wake cap; rerun is event-driven, so
  there is no polling loop.

## Observation (duties)

Each reading that is missing, stale or broken stays UNKNOWN or RED.

- `queue-depth` — low means the scout is owed a wake.
- `stale-claims` — an entry claimed but unresolved too long returns to the queue.
- `disk-floor` — RED when the spare drive's free space is below 60 GB; rerun then takes
  no new entries and only cleans up.
- `scoreboard-fresh` — `ledger.md` matches `reports/`.

## Open items before install

- Choose the first 3–5 seed papers by hand.
- Confirm the sandbox runs a representative old R and Fortran case end to end.
- Write the two charters and a minimal `duties.json` whose resolvers are only these two
  roles.
