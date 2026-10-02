#!/usr/bin/env bash
# Image contract: the client image carries the LizardFS client and rsync.
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

echo ""
echo "==> Image contract results: ${PASS} passed, ${FAIL} failed"
[[ ${FAIL} -eq 0 ]]
