# Verbatim extraction of a shell archive's here-document bodies (TOMS 835 style: cat << "SHAR_EOF" > 'NAME').
# Same rules as reports/bai1997-srrit-776/extract-tree.awk, plus the quoted delimiter form. No shell is run.
# Run from the tree root: awk -f extract-tree.awk ARCHIVE
/^cd '/ { d=$0; sub(/^cd '/, "", d); sub(/'$/, "", d); dir = (dir == "" ? d : dir "/" d); next }
/^cd \.\.$/ { sub(/\/?[^\/]*$/, "", dir); next }
/^cat << "?\\?SHAR_EOF"? > / { name=$0; sub(/^cat << "?\\?SHAR_EOF"? > '/, "", name); sub(/'$/, "", name);
  path = (dir == "" ? name : dir "/" name); system("mkdir -p \"" (dir == "" ? "." : dir) "\""); out=path; inside=1; next }
/^SHAR_EOF$/ { if (inside) { close(out); inside=0 } ; next }
{ if (inside) print > out }
