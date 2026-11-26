# Splits the TOMS 748 shell-style archive into its members (CC0 helper, rerun).
# Usage: python3 -I split_748.py ARCHIVE OUTDIR. Member markers are lines 'C*** NAME'.
import os, re, sys

archive, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
members, cur = {}, None
for line in open(archive, encoding="latin-1").read().split("\n"):
    m = re.match(r"^C\*\*\* (\S+)$", line)
    if m:
        cur = m.group(1)
        members[cur] = []
        continue
    if cur is not None:
        members[cur].append(line)
for name, body in members.items():
    with open(os.path.join(outdir, name), "w", encoding="latin-1") as f:
        f.write("\n".join(body).rstrip("\n") + "\n")
    print(name, len(body))
