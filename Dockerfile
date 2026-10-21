# lizardfs-client is not available in Ubuntu 22.04+, so ubuntu:20.04 is required
FROM ubuntu:20.04

RUN apt-get update \
     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
     rsync \
     lizardfs-client \
     && rm -rf /var/lib/apt/lists/*

ENV LFS_MASTER="universum" \
    LFS_SUBFOLDER="/volumes" \
    LFS_MOUNT_OPTIONS="mfsdelayedinit,nosuid,nodev,noatime,big_writes,mfschunkserverwriteto=40000,mfsioretries=120,mfschunkserverconnectreadto=20000,mfschunkserverwavereadto=5000,mfschunkservertotalreadto=20000" \
    SYNC_JOBS="-avP --delete-after /srv/keller/ /srv/ceph/cloud/; -avP --delete-after --exclude=data/nextcloud.log /mnt/mrw-cloud/ /srv/ceph/lizardfs/mrw-cloud/; -avP --append-verify --inplace --delete-after /mnt/mrw-cloud/data/nextcloud.log /srv/ceph/lizardfs/mrw-cloud/data/nextcloud.log; -avP --delete-after /mnt/boar-mrw-sh/ /srv/ceph/lizardfs/boar-mrw-sh/; -avP --delete-after /mnt/boar-data/ /srv/ceph/lizardfs/boar-data/"

COPY --chmod=0755 bin/ /usr/local/bin/

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["lizardfs-sync"]
