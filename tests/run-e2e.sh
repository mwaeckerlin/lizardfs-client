#!/usr/bin/env bash
# End to end: the client image mounts a real LizardFS (master and chunk
# server of tests/e2e) with lfsmount, writes a file into it, reads it back,
# and copies the tree out with rsync, the migration the image exists for.
#
# Usage: tests/run-e2e.sh   (after `npm run build`)

set -uo pipefail
cd "$(dirname "$0")/e2e"

COMPOSE=(docker compose -f docker-compose.yml)
PASS=0
FAIL=0

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); echo "  FAIL  $1: $2"; }

cleanup() { "${COMPOSE[@]}" down -v --remove-orphans > /dev/null 2>&1; }
trap cleanup EXIT
cleanup

echo "==> LizardFS client end to end"
"${COMPOSE[@]}" build || exit 1
"${COMPOSE[@]}" up -d master chunkserver || exit 1

# the chunk server needs a moment to register; the mount is repeated until the
# file system takes a file
OUT=$("${COMPOSE[@]}" run --rm -T client '
    set -u
    for attempt in $(seq 1 30); do
        if lfsmount -o rw,mfsmaster=master,mfsdelayedinit /mnt > /dev/null 2>&1 \
            && mkdir -p /mnt/e2e && echo "written through lizardfs" > /mnt/e2e/file.txt 2> /dev/null; then
            break
        fi
        umount /mnt > /dev/null 2>&1
        sleep 2
    done
    echo "MOUNTED: $(grep -c " /mnt " /proc/mounts)"
    echo "READ: $(cat /mnt/e2e/file.txt 2>&1)"
    mkdir -p /tmp/copy
    rsync -a --delete-after /mnt/e2e/ /tmp/copy/ && echo "COPIED: $(cat /tmp/copy/file.txt 2>&1)"
    umount /mnt
' 2>&1)

grep -q "^MOUNTED: 1$" <<< "${OUT}" && _pass "lfsmount_mounts_lizardfs" || _fail "lfsmount_mounts_lizardfs" "$(tail -n 20 <<< "${OUT}")"
grep -q "^READ: written through lizardfs$" <<< "${OUT}" && _pass "file_written_and_read_back" || _fail "file_written_and_read_back" "$(tail -n 20 <<< "${OUT}")"
grep -q "^COPIED: written through lizardfs$" <<< "${OUT}" && _pass "rsync_copies_out_of_lizardfs" || _fail "rsync_copies_out_of_lizardfs" "$(tail -n 20 <<< "${OUT}")"

echo ""
echo "==> LizardFS client end to end: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    # the state and exit code of every container: on the arm64 runner the
    # master stopped after loading its configuration without a log line
    "${COMPOSE[@]}" ps -a
    "${COMPOSE[@]}" logs --tail 40 master chunkserver
    exit 1
fi
