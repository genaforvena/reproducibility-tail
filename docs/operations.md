# Operating the plant: accepted conditions and hand-written drop-ins

What a mind or the operator should not re-raise, and why. Each item was decided on 2026-11-26
during installation and reported to the owner. Reopen one only with new evidence.

## A RED the plant accepts on purpose

- **Doctor: "root-fs probe: no readable sample in operator/dual-probe.jsonl".** The probe script
  (`dual_probe.py`) writes a fixed shared path, `/dev/shm/dual-probe.jsonl`, which the main plant's
  stall detector reads. A second instance would overwrite or interleave the main plant's evidence.
  The host's root-drive stalls are already observed by the main plant. So the probe is not run
  here, the script is not rebuilt, and the RED stays visible instead of being hidden. Resolver:
  the owner, only if the shared path is ever made per-plant.

## Hand-written systemd drop-ins (not generated; `tools/release-sync.sh` does not touch them)

- `~/.config/systemd/user/rtail-.service.d/host-containment.conf`: copied from the sibling plant;
  it is the host guard's admission and start limit (3 starts in 300 s). Protected: not edited.
- `~/.config/systemd/user/rtail-.service.d/zzzz-own-slice.conf`: puts every `rtail-*` unit in
  `rtail-plants.slice` (3 GiB high, 5 GiB max, 200% CPU) so it cannot squeeze the main plant.
- `~/.config/systemd/user/rtail-producer-dispatch.service.d/zzzzzzz-timer-start-limit.conf`:
  `StartLimitBurst=80` for the 60-second dispatch producer, so the guard's burst of 3 does not
  refuse it after the fourth start. It copies the main plant's identical drop-in. Keep it until a
  full-flag sync gives the producer an `OnUnitActiveSec` of 120 s or more.

## Outside this plant

- **Free space on `/`** is a host condition: other plants' trees and tool histories fill it (the
  main plant's `disk-budget` duty reports it). This plant keeps its own footprint small (repo
  and site home under 100 MB; heavy work on `/mnt/mishe-scratch`, capped at 20 GiB, drive floor
  60 GiB, `disk-floor` duty). Cleaning `/` is not this plant's job and must not touch other plants.
- The main plant, other plants, the host guard and credentials are never touched from here.
