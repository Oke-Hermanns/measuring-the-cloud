# Storage Local-Storage Scenarios

This folder contains focused scenarios for instance-local storage. These
scenarios set `BLOCK_VOLUME_SIZE_GIB=0`, so no additional benchmark block
volume is provisioned beyond the required root volume. They now default to
direct-device benchmarking with `LOCAL_FILESYSTEM=raw`.

Use this folder when you want to benchmark local disks only. Scenarios for
machine types without local storage will simply have no local target to run.
Use `../filesystem/` when you want explicit filesystem-backed comparison runs.
