# Verbatim extraction of a shell archive's here-document bodies into their directory tree.
# No shell is run: the archive's own "cd" lines (cd 'X' pushes, cd .. pops) set the directory and each
# "cat << \SHAR_EOF > 'NAME'" line opens NAME; the lines up to the next "SHAR_EOF" are copied verbatim.
# Run from the tree root: awk -f extract-tree.awk ARCHIVE
/^cd '/ { d=$0; sub(/^cd '/, "", d); sub(/'$/, "", d); dir = (dir == "" ? d : dir "/" d); next }
/^cd \.\.$/ { sub(/\/?[^\/]*$/, "", dir); next }
/^cat << \\SHAR_EOF > / { name=$0; sub(/^cat << \\SHAR_EOF > '/, "", name); sub(/'$/, "", name);
  path = (dir == "" ? name : dir "/" name); system("mkdir -p \"" (dir == "" ? "." : dir) "\""); out=path; inside=1; next }
/^SHAR_EOF$/ { if (inside) { close(out); inside=0 } ; next }
{ if (inside) print > out }
