#!/usr/bin/env bash
# Run one untrusted command for one paper inside a sandbox.
#
# Usage: tools/sandbox.sh [--fetch] PAPER_ID -- COMMAND [ARGS...]
#
# - Root filesystem is read-only; the only writable path is /work, which is the
#   per-paper scratch directory on the spare drive
#   (/mnt/mishe-scratch/reproducibility-tail/PAPER_ID).
# - No network unless --fetch (use it only for the dependency/data fetch step).
# - No access to the home directory, keys, other plants or the host's /tmp.
# - Memory, task, CPU and wall-time caps via a transient systemd user scope.
# Disk cap: no kernel quota is available on this host; the per-file size limit
# below bounds one write, and checks/disk-floor.py bounds the plant as a whole.
set -euo pipefail

net=--unshare-net
if [ "${1:-}" = "--fetch" ]; then net=--share-net; shift; fi
id="${1:?paper id}"; shift
[ "${1:-}" = "--" ] && shift || { echo "sandbox: expected -- before the command" >&2; exit 2; }
[ $# -gt 0 ] || { echo "sandbox: no command" >&2; exit 2; }
case "$id" in *[!A-Za-z0-9._-]*|"") echo "sandbox: bad paper id" >&2; exit 2;; esac

root=/mnt/mishe-scratch/reproducibility-tail
work="$root/$id"
mkdir -p "$work"

mem="${SANDBOX_MEMORY_MAX:-3G}"
wall="${SANDBOX_WALL_SECONDS:-3600}"
fsize_kb="${SANDBOX_FILE_KB:-2097152}"   # 2 GiB per file

exec systemd-run --user --scope --quiet --collect \
  -p MemoryMax="$mem" -p MemorySwapMax=0 -p TasksMax=256 -p CPUQuota=200% \
  -p RuntimeMaxSec="$wall" \
  bwrap --die-with-parent --unshare-user --unshare-pid --unshare-ipc --unshare-uts \
        --unshare-cgroup-try "$net" \
        --ro-bind /usr /usr --symlink usr/bin /bin --symlink usr/sbin /sbin \
        --symlink usr/lib /lib --symlink usr/lib64 /lib64 \
        --ro-bind /etc/resolv.conf /etc/resolv.conf \
        --ro-bind /etc/ssl /etc/ssl --ro-bind /etc/ca-certificates /etc/ca-certificates \
        --ro-bind /etc/alternatives /etc/alternatives \
        --ro-bind /etc/passwd /etc/passwd --ro-bind /etc/group /etc/group \
        --proc /proc --dev /dev --tmpfs /tmp \
        --bind "$work" /work --chdir /work \
        --setenv HOME /work --setenv TMPDIR /tmp --setenv LANG C.UTF-8 \
        --setenv PATH /work/bin:/usr/local/bin:/usr/bin:/bin \
        bash -c "ulimit -f $fsize_kb; exec \"\$@\"" sandbox "$@"
