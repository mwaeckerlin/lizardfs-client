# LizardFS Client

Mount and access your LizardFS filesystems in Docker.

LizardFS is no longer supported in new Ubuntu versions. To still access an existing LizardFS installation, this Docker image provides `lizardfs-client` and `rsync` on Ubuntu 20.04. It is mainly intended to migrate data from LizardFS to a new [CephFS](https://docs.ceph.com/en/latest/cephfs/) setup.

See also my blog post: [Run a Stable LizardFS](https://marc.wäckerlin.ch/computer/run-a-stable-lizardfs)

I now recommend migrating to CephFS — that is also why I created this image, to bring my CephFS and my old LizardFS together.

## Mount Command

After starting the container, mount LizardFS with:

```sh
lfsmount -o rw,mfsmaster=universum,mfssubfolder=/volumes,mfsdelayedinit,nosuid,nodev,noatime,big_writes,mfschunkserverwriteto=40000,mfsioretries=120,mfschunkserverconnectreadto=20000,mfschunkserverwavereadto=5000,mfschunkservertotalreadto=20000 /mnt
```

`lizardfs-mount` runs the same command with the master, subfolder and mount options of the [configuration](#configuration), so with the defaults it mounts exactly as above:

```sh
lizardfs-mount
```

## Start the Container

My CephFS is mounted on `/srv`, so I mount it into the container to be able to back up LizardFS data to CephFS:

```sh
docker run -it --rm --name lizard --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined -v /srv:/srv mwaeckerlin/lizardfs-client:mrw-privat
```

Without a command, the container runs `lizardfs-sync`: it mounts the LizardFS on `/mnt` as `lizardfs-mount` does, then runs the rsync jobs of `SYNC_JOBS` one after the other. A job that fails does not stop the jobs after it, and the container exits with the status of the last job. When the mount fails, no job runs and the container exits with the error of `lfsmount`.

## Configuration

Every setting is an environment variable with a default; the defaults reproduce the mount and the jobs this image has always run. A value is checked before it reaches `lfsmount` or `rsync`, and a refused value stops the container with a message that names the variable, before anything is mounted.

| Variable | Default | Meaning |
| --- | --- | --- |
| `LFS_MASTER` | `universum` | Host name or IPv4 address of the LizardFS master, passed as `mfsmaster=`. |
| `LFS_SUBFOLDER` | `/volumes` | Absolute path inside the LizardFS that becomes the root of `/mnt`, passed as `mfssubfolder=`; letters, digits and `_ . / -`. |
| `LFS_MOUNT_OPTIONS` | `mfsdelayedinit,nosuid,nodev,noatime,big_writes,mfschunkserverwriteto=40000,mfsioretries=120,mfschunkserverconnectreadto=20000,mfschunkserverwavereadto=5000,mfschunkservertotalreadto=20000` | Further `lfsmount` options, separated by commas, appended after `rw,mfsmaster=…,mfssubfolder=…`; empty adds none. |
| `SYNC_JOBS` | the five jobs below | The rsync jobs of `lizardfs-sync`, separated by `;` or line breaks; each job is the argument list of one `rsync` call, separated by spaces. Empty runs no job, so the container only mounts. |

The default of `SYNC_JOBS`, one job per line:

```text
-avP --delete-after /srv/keller/ /srv/ceph/cloud/
-avP --delete-after --exclude=data/nextcloud.log /mnt/mrw-cloud/ /srv/ceph/lizardfs/mrw-cloud/
-avP --append-verify --inplace --delete-after /mnt/mrw-cloud/data/nextcloud.log /srv/ceph/lizardfs/mrw-cloud/data/nextcloud.log
-avP --delete-after /mnt/boar-mrw-sh/ /srv/ceph/lizardfs/boar-mrw-sh/
-avP --delete-after /mnt/boar-data/ /srv/ceph/lizardfs/boar-data/
```

The arguments of a job reach `rsync` without a shell: there is no quoting, no variable and no globbing by a shell, so a path cannot contain a space. An argument may carry letters, digits and `_ . / = , : + @ % ~ * ? [ ] -`; a pattern such as `--exclude=*.log` reaches rsync as it stands. Another LizardFS and other jobs:

```sh
docker run --rm --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined -v /srv:/srv -e LFS_MASTER=lfs-master -e LFS_SUBFOLDER=/ -e "SYNC_JOBS=-avP --delete-after /mnt/projects/ /srv/projects/; -avP /mnt/archive/ /srv/archive/" mwaeckerlin/lizardfs-client:mrw-privat
```

## Build and Run

Build the image locally:

```sh
npm run build
```

Run the container and connect to it interactively (my CephFS is mounted at `/srv`):

```sh
docker compose run --rm lizardfs-client bash
```

Alternatively, using `docker run` directly:

```sh
docker run -it --rm --name lizard --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined -v /srv:/srv mwaeckerlin/lizardfs-client:mrw-privat bash
```

Once inside the container, mount your LizardFS volume (see [Mount Command](#mount-command) above), then use `rsync` to copy data to your target path.

## Development

```bash
npm test
```

`npm test` runs the docs contract (every variable has a row in the configuration table), the image contract (the LizardFS client and rsync are installed, the default command line and the configured one, and the refusal of invalid values), and the end-to-end test in [tests/e2e](tests/e2e): a LizardFS master and chunk server from the Ubuntu 20.04 packages, and the image, which mounts the file system, writes and reads a file, copies it out with rsync, and then mounts and copies through `lizardfs-sync` with a configured master, subfolder, mount options and job. All features are listed in [FEATURES.md](FEATURES.md), all tests in [TESTS.md](TESTS.md). The image is published for `linux/amd64` only: the LizardFS master of Ubuntu 20.04 crashes with a segmentation fault on arm64, and no newer Ubuntu or Debian release carries LizardFS, so an arm64 client cannot be tested. It is published by the reusable workflow of [mwaeckerlin/scratch](https://github.com/mwaeckerlin/scratch#publishing-on-docker-hub).

## LizardFS History

LizardFS is a fork of [MooseFS](https://moosefs.com/), an open-source distributed file system. The fork was created to add new features and fix bugs that were not being addressed in the original project. LizardFS was developed and maintained by Skytechnology, a Polish company that built a community and commercial offering around the software.

In 2019, Skytechnology was acquired by [Seagate Technology](https://www.seagate.com/), the well-known hard drive manufacturer. Seagate initially continued development under the LizardFS brand, but over time the project received less attention and Ubuntu dropped it from their official repositories starting with Ubuntu 22.04.

A community fork called [SaunaFS](https://github.com/leil-io/saunafs) has emerged as a potential continuation of LizardFS. It is led by [Alexander Ragel](https://www.linkedin.com/in/ACoAAAFGScQBvoyVjykmiTDUk1T1XML9F05h47U) and the team at Leil IO, who are actively developing and maintaining the project. SaunaFS aims to modernize the codebase and keep the spirit of LizardFS alive. If you are looking for a community-driven successor to LizardFS, SaunaFS is worth evaluating — it appears to be a legitimate and serious continuation, though it is still maturing.

For anyone running a Docker Swarm or any production workload requiring a stable, distributed cloud filesystem, I recommend migrating to **CephFS**. CephFS is actively maintained, widely supported, and available in current Ubuntu releases. It provides comparable (and often superior) features to LizardFS, with a large community and long-term support from the Ceph Foundation.
