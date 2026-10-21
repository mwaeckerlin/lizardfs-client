#!/usr/bin/env bash
# Image contract: the client image carries the LizardFS client and rsync, and
# its default command builds the mount and the rsync jobs from the environment.
#
# Usage: tests/image-contract.sh IMAGE

set -uo pipefail

IMAGE="${1:-mwaeckerlin/lizardfs-client:mrw-privat}"
PASS=0
FAIL=0

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); echo "  FAIL  $1: $2"; }

echo "==> Image contract: ${IMAGE}"
if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    echo "  FAIL  image_exists: run 'npm run build' first"
    exit 1
fi
for program in lfsmount rsync; do
    if docker run --rm --pull=never --network none "${IMAGE}" "command -v ${program}" > /dev/null 2>&1; then
        _pass "${program}_installed"
    else
        _fail "${program}_installed" "${program} is missing"
    fi
done

# runs lizardfs-sync with lfsmount and rsync replaced by programs that print
# the command line they receive; arguments before the image are docker options
_effective() {
    docker run --rm --pull=never --network none "$@" "${IMAGE}" '
        mkdir -p /tmp/shim
        for p in lfsmount rsync; do
            printf "#!/bin/sh\necho %s \"\$*\"\n" "$p" > /tmp/shim/$p
            chmod +x /tmp/shim/$p
        done
        PATH=/tmp/shim:$PATH lizardfs-sync' 2>&1
}

_expect() {
    local name="$1" expected="$2" out="$3"
    if [[ "${out}" == "${expected}" ]]; then
        _pass "${name}"
    else
        _fail "${name}" "expected:"$'\n'"${expected}"$'\n'"got:"$'\n'"${out}"
    fi
}

# a refused value stops the container before anything is mounted, and the
# message names the variable
_refused() {
    local name="$1" variable="$2"
    shift 2
    local out rc
    out=$(_effective "$@")
    rc=$?
    if [[ ${rc} -ne 0 && "${out}" == *"${variable}"* && "${out}" != *"lfsmount -o"* ]]; then
        _pass "${name}"
    else
        _fail "${name}" "exit ${rc}: ${out}"
    fi
}

CMD=$(docker image inspect -f '{{json .Config.Cmd}}' "${IMAGE}")
_expect "default_command_runs_lizardfs_sync" '["lizardfs-sync"]' "${CMD}"

_expect "default_mount_and_sync_jobs" "lfsmount -o rw,mfsmaster=universum,mfssubfolder=/volumes,mfsdelayedinit,nosuid,nodev,noatime,big_writes,mfschunkserverwriteto=40000,mfsioretries=120,mfschunkserverconnectreadto=20000,mfschunkserverwavereadto=5000,mfschunkservertotalreadto=20000 /mnt
rsync -avP --delete-after /srv/keller/ /srv/ceph/cloud/
rsync -avP --delete-after --exclude=data/nextcloud.log /mnt/mrw-cloud/ /srv/ceph/lizardfs/mrw-cloud/
rsync -avP --append-verify --inplace --delete-after /mnt/mrw-cloud/data/nextcloud.log /srv/ceph/lizardfs/mrw-cloud/data/nextcloud.log
rsync -avP --delete-after /mnt/boar-mrw-sh/ /srv/ceph/lizardfs/boar-mrw-sh/
rsync -avP --delete-after /mnt/boar-data/ /srv/ceph/lizardfs/boar-data/" "$(_effective)"

_expect "configured_mount_and_sync_jobs" "lfsmount -o rw,mfsmaster=lfs.example.org,mfssubfolder=/backup,mfsdelayedinit,noexec /mnt
rsync -a --delete /mnt/one/ /srv/one/
rsync -a --exclude=*.log /mnt/two/ /srv/two/" "$(_effective \
    -e LFS_MASTER=lfs.example.org \
    -e LFS_SUBFOLDER=/backup \
    -e LFS_MOUNT_OPTIONS=mfsdelayedinit,noexec \
    -e 'SYNC_JOBS=-a --delete /mnt/one/ /srv/one/;  -a --exclude=*.log /mnt/two/ /srv/two/ ;')"

_expect "empty_mount_options_and_sync_jobs" "lfsmount -o rw,mfsmaster=universum,mfssubfolder=/volumes /mnt" "$(_effective \
    -e LFS_MOUNT_OPTIONS= \
    -e SYNC_JOBS=)"

_refused "invalid_lfs_master_refused" LFS_MASTER -e 'LFS_MASTER=universum,mfsport=1'
_refused "empty_lfs_master_refused" LFS_MASTER -e LFS_MASTER=
_refused "invalid_lfs_subfolder_refused" LFS_SUBFOLDER -e LFS_SUBFOLDER=volumes
_refused "invalid_lfs_mount_options_refused" LFS_MOUNT_OPTIONS -e 'LFS_MOUNT_OPTIONS=noatime, nodev'
_refused "invalid_sync_jobs_refused" SYNC_JOBS -e 'SYNC_JOBS=-a /mnt/ /srv/$(id)/'

echo ""
echo "==> Image contract results: ${PASS} passed, ${FAIL} failed"
[[ ${FAIL} -eq 0 ]]
