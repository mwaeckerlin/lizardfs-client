# lizardfs-client
LizardFS is no more supported in new Ubuntu - To still access an existing Lizardfs, I need an old Ubuntu version and work there. Mainly intended to move all data to my new CephFS. After starting the container, I mount using: `lfsmount -o rw,mfsmaster=universum,mfssubfolder=/volumes,mfsdelayedinit,nosuid,nodev,noatime,big_writes /mnt`
