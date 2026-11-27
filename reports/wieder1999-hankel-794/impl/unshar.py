"""Unpack a netlib shell archive WITHOUT executing it (CC0, rerun wrapper).

Only the layout the archive uses is handled: `cd 'DIR'` / `cd ..` move a directory
stack, and `cat << SHAR_EOF > 'NAME'` (quoted or unquoted marker, as the TOMS archives use either) ... `SHAR_EOF` writes one file. Every other
line (mkdir, the overwrite checks, `exit 0`) is ignored. Any path with a `..` component
or an absolute path is refused. Usage: python3 -I -c "$(cat unshar.py)" ARCHIVE DEST
"""
import os
import re
import sys

archive, dest = sys.argv[1], sys.argv[2]
cd_re = re.compile(r"^cd (?:'([^'/]+)'|\.\.)\s*$")
cat_re = re.compile(r"""^cat << "?SHAR_EOF"? > '([^'/]+)'\s*$""")
stack = []
written = []
with open(archive, "r", encoding="latin-1", newline="") as fh:
    lines = fh.read().split("\n")
i = 0
while i < len(lines):
    line = lines[i]
    m = cat_re.match(line)
    if m:
        name = m.group(1)
        parts = stack + [name]
        if any(p in ("", ".", "..") for p in parts):
            raise SystemExit("refused path " + "/".join(parts))
        target = os.path.join(dest, *parts)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        body = []
        i += 1
        while i < len(lines) and lines[i] != "SHAR_EOF":
            body.append(lines[i])
            i += 1
        if i >= len(lines):
            raise SystemExit("unterminated heredoc for " + name)
        with open(target, "w", encoding="latin-1", newline="") as out:
            out.write("\n".join(body) + "\n")
        written.append("/".join(parts) + " " + str(len("\n".join(body)) + 1))
    else:
        m = cd_re.match(line)
        if m:
            if m.group(1) is None:
                if not stack:
                    raise SystemExit("cd .. above archive root")
                stack.pop()
            else:
                stack.append(m.group(1))
    i += 1
print("\n".join(written))
