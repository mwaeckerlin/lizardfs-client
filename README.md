# lizardfs-client

LizardFS is no longer supported in new Ubuntu versions. To still access an existing LizardFS installation, this Docker image provides `lizardfs-client` and `rsync` on Ubuntu 20.04. It is mainly intended to migrate data from LizardFS to a new [CephFS](https://docs.ceph.com/en/latest/cephfs/) setup.

See also my blog post: [Run a Stable LizardFS](https://marc.wäckerlin.ch/computer/run-a-stable-lizardfs)

I now recommend migrating to CephFS — that is also why I created this image, to bring my CephFS and my old LizardFS together.

## Mount Command

After starting the container, mount LizardFS with:

```sh
lfsmount -o rw,mfsmaster=universum,mfssubfolder=/volumes,mfsdelayedinit,nosuid,nodev,noatime,big_writes,mfschunkserverwriteto=40000,mfsioretries=120,mfschunkserverconnectreadto=20000,mfschunkserverwavereadto=5000,mfschunkservertotalreadto=20000 /mnt
```

## Start the Container

My CephFS is mounted on `/srv`, so I mount it into the container to be able to back up LizardFS data to CephFS:

```sh
docker run -it --rm --name lizard --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined -v /srv:/srv mwaeckerlin/lizardfs-client
```

## Build

```sh
docker compose build
docker compose push
```

## LizardFS History

LizardFS is a fork of [MooseFS](https://moosefs.com/), an open-source distributed file system. The fork was created to add new features and fix bugs that were not being addressed in the original project. LizardFS was developed and maintained by Skytechnology, a Polish company that built a community and commercial offering around the software.

In 2019, Skytechnology was acquired by [Seagate Technology](https://www.seagate.com/), the well-known hard drive manufacturer. Seagate initially continued development under the LizardFS brand, but over time the project received less attention and Ubuntu dropped it from their official repositories starting with Ubuntu 22.04.

For anyone running a Docker Swarm or any production workload requiring a stable, distributed cloud filesystem, I recommend migrating to **CephFS**. CephFS is actively maintained, widely supported, and available in current Ubuntu releases. It provides comparable (and often superior) features to LizardFS, with a large community and long-term support from the Ceph Foundation.
