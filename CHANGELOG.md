# Changelog

- 2026-10-02 **1.0.1**
    - Published for amd64 only: the LizardFS master of Ubuntu 20.04 crashes on arm64, so no arm64 image can be tested against a LizardFS

- 2026-10-02 **1.0.0**
    - The LizardFS client and rsync on Ubuntu 20.04, to mount an existing LizardFS and copy its data to another file system
    - Published for amd64 and arm64, built and published automatically on every change and every week
    - Tested on every build against a real LizardFS: mount, write, read back, and copy out with rsync
