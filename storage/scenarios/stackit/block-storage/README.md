# Storage Block-Storage Scenarios

This folder contains focused scenarios for attached block storage. The
scenarios provision an additional benchmark block volume in addition to the VM
root volume. They now default to direct-device benchmarking with
`BLOCK_FILESYSTEM=raw`.

Use this folder when you want to benchmark block-volume performance classes
without running the broader storage matrix. Use `../filesystem/` when you want
explicit filesystem-backed comparison runs.
