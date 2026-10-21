# Tests

Register of all tests, sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything after `npm run build`. The guard `tests/docs-contract.sh` fails when a feature has no test entry here or a test carries a skip marker.

## Image contract

The configuration tests run `lizardfs-sync` with `lfsmount` and `rsync` replaced by programs that print the command line they receive, and compare it with the expected one.

- **F1** `tests/image-contract.sh` › lfsmount_installed.
- **F2** `tests/image-contract.sh` › rsync_installed.
- **F4, F5** `tests/image-contract.sh` › default_command_runs_lizardfs_sync: the image starts `lizardfs-sync` when no command is given.
- **F4, F5** `tests/image-contract.sh` › default_mount_and_sync_jobs: without configuration the mount and the five rsync jobs are byte for byte the command lines the image ran before they became configurable.
- **F4, F5** `tests/image-contract.sh` › configured_mount_and_sync_jobs: a set master, subfolder, mount options and two jobs (with extra spaces, a trailing `;` and an `--exclude=*.log` pattern) reach `lfsmount` and `rsync` exactly.
- **F4, F5** `tests/image-contract.sh` › empty_mount_options_and_sync_jobs: empty mount options mount with master and subfolder alone, and an empty job list runs no rsync.
- **F4** `tests/image-contract.sh` › invalid_lfs_master_refused, empty_lfs_master_refused, invalid_lfs_subfolder_refused, invalid_lfs_mount_options_refused: a master with a comma, an empty master, a relative subfolder and options with a space stop the container with a non-zero exit and the variable's name, before `lfsmount` runs.
- **F5** `tests/image-contract.sh` › invalid_sync_jobs_refused: a job carrying `$(id)` stops the container with a non-zero exit and the variable's name, before `lfsmount` runs.

## Docs contract

- **F4, F5** `tests/docs-contract.sh` › every_variable_documented: every variable the Dockerfile sets has a row in the configuration table of the README.

## End-to-end

`npm run test:e2e` starts `tests/e2e/docker-compose.yml`: a LizardFS master and a chunk server from the LizardFS packages of Ubuntu 20.04 on an internal network, and the client image with `/dev/fuse` and `SYS_ADMIN`, as the README starts it.

- **F1** `tests/run-e2e.sh` › lfsmount_mounts_lizardfs, file_written_and_read_back: the client mounts the file system, writes a file and reads it back.
- **F2** `tests/run-e2e.sh` › rsync_copies_out_of_lizardfs: rsync copies the tree out of the mounted file system, and the copy holds the file.
- **F4, F5** `tests/run-e2e.sh` › lizardfs_sync_mounts_configured_master: `lizardfs-sync` with the master `master` of the stack, which the default `universum` would not reach, mounts and exits 0.
- **F4** `tests/run-e2e.sh` › configured_mount_options_reach_the_mount: the configured option `noexec` stands on the mount in `/proc/mounts`.
- **F4, F5** `tests/run-e2e.sh` › configured_subfolder_and_sync_job_copy_out: with the subfolder `/e2e` and one configured job from `/mnt/` to `/tmp/copy/`, the file of the first run lands directly in `/tmp/copy`.

## Workflow contract

- **F3** `tests/workflow-contract.sh` of `mwaeckerlin/scratch`: the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
