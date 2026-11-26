# The plant's pinned release is a fork

The plant runs Mishe code from a snapshot under its site home (`.mishe-tauftauf/runtime/current`),
not from the main checkout, so main's live edits cannot reach it. The snapshot is patched in a few
places. A fresh snapshot (`git archive` of main) must be patched the same way, then
`tools/release-sync.sh` re-renders this plant's units.

| file in the snapshot | patch | why |
|---|---|---|
| `src/mishe_tauftauf/units.py` | `MARKER` is `# rtail-generated: ...`; default `prefix` is `rtail` | main's `sync` and `doctor` must not read this plant's units as theirs |
| `src/mishe_tauftauf/wake.py`, `runtime_cli.py`, `discovery.py` | unit name `rtail-wake@` | wakes start this plant's template |
| `src/mishe_tauftauf/arm.py` | `TIMER_UNIT = "rtail-next-due"` | its own next-due timer |
| `src/mishe_tauftauf/release_promotion.py` | `prefix="rtail"` | a promotion must not render `mishe-*` units |
| `src/mishe_tauftauf/duties.py` | a duty's `signal.reoffer` (seconds) is passed through | the default re-offer is an hour; an empty queue must return the scout in 15 minutes. Candidate for main. |
| `duties.json`, `checks/*.py`, `tools/build_ledger.py`, `tools/frame_sample.py` | copied from the checkout | duties and checks are read from the release |

Never run a bare `mishe sync` on this host; `tools/release-sync.sh` passes the prefix and unit directory.
