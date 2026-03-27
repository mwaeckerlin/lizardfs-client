# lizardfs-client is not available in Ubuntu 22.04+, so ubuntu:20.04 is required
FROM ubuntu:20.04

RUN apt-get update \
     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
     rsync \
     lizardfs-client \
     && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["set -e; \
     lfsmount -o rw,mfsmaster=universum,mfssubfolder=/volumes,mfsdelayedinit,nosuid,nodev,noatime,big_writes,mfschunkserverwriteto=40000,mfsioretries=120,mfschunkserverconnectreadto=20000,mfschunkserverwavereadto=5000,mfschunkservertotalreadto=20000 /mnt; \
     set +e; \
     rsync -avP --delete-after /srv/keller/ /srv/ceph/cloud/; \
     rsync -avP --delete-after /mnt/mrw-cloud/ /srv/ceph/lizardfs/mrw-cloud/; \
     rsync -avP --delete-after /mnt/boar-mrw-sh/ /srv/ceph/lizardfs/boar-mrw-sh/; \
     rsync -avP --delete-after /mnt/boar-data/ /srv/ceph/lizardfs/boar-data/"]
