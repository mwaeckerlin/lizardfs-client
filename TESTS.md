# Tests

Register of all tests, sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything after `npm run build`. The guard `tests/docs-contract.sh` fails when a feature has no test entry here or a test carries a skip marker.

## Image contract

- **F1** `tests/image-contract.sh` › lfsmount_installed.
- **F2** `tests/image-contract.sh` › rsync_installed.

## End-to-end

`npm run test:e2e` starts `tests/e2e/docker-compose.yml`: a LizardFS master and a chunk server from the LizardFS packages of Ubuntu 20.04 on an internal network, and the client image with `/dev/fuse` and `SYS_ADMIN`, as the README starts it.

- **F1** `tests/run-e2e.sh` › lfsmount_mounts_lizardfs, file_written_and_read_back: the client mounts the file system, writes a file and reads it back.
- **F2** `tests/run-e2e.sh` › rsync_copies_out_of_lizardfs: rsync copies the tree out of the mounted file system, and the copy holds the file.

## Workflow contract

- **F3** `tests/workflow-contract.sh` of `mwaeckerlin/scratch`: the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
