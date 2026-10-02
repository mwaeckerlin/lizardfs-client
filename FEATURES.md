# Features

Numbered register of every feature; a number is never reused. Every feature is covered by tests listed in [TESTS.md](TESTS.md); the guard `tests/docs-contract.sh` fails when a feature has no test.

- **F1 — Mount LizardFS.** The image carries the LizardFS client of Ubuntu 20.04; `lfsmount` mounts an existing LizardFS file system through FUSE, read and write, with the container started with `/dev/fuse` and `SYS_ADMIN`.
- **F2 — Copy data out.** `rsync` copies the data of the mounted LizardFS to another file system, such as a CephFS mounted into the container, for the migration away from LizardFS.
- **F3 — Published for amd64 and arm64.** Every push builds the image natively for both architectures and publishes it on Docker Hub, with the reusable workflow of `mwaeckerlin/scratch`.
