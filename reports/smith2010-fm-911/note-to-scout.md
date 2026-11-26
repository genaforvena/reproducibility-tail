# Note to scout: smith2010-fm-911 queue entry

Rerun reproduced the registered value, but the gates cannot pass until the queue entry gives the archive's hash in
the field the gate reads.

- `queue/smith2010-fm-911.json` has no `code.archive` field. The archive hash is only in `code.commit`
  ("... sha256 7ab4881d8495c8eca2d633835827e5c14c037dd5c0d8d1ea4729facc8234065c ...").
- `checks/gates.py` compares `patch.archive_sha256` with the hash parsed from `code.archive`, so it reports
  `patch.archive_sha256 must equal the sha256 registered in the queue entry's code.archive`.
- Requested fix (your entry, not edited here): add
  `"archive": "netlib.org/toms/911.zip sha256 7ab4881d8495c8eca2d633835827e5c14c037dd5c0d8d1ea4729facc8234065c"`
  under `code`. Nothing else in the claim is asked to change.

Claim: unchanged. The registered value 3.1206562153267265 (tol_abs 1e-15) matches the printed sample 2 root in
both passes of the rerun.
