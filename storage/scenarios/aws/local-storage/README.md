# AWS Local Storage Scenarios

These scenarios use c6id instance-store NVMe devices and disable the additional
EBS benchmark block volume with `BLOCK_VOLUME_SIZE_GIB=0`.

`c6id.8xlarge` and `c6id.32xlarge` are included as approximate local-storage
pairings for larger STACKIT `g2a` local-storage scenarios. They can be
expensive; use `--dry-run` first and check quota/cost before provisioning.
