# AWS PostgreSQL WAL Scenarios

This folder contains AWS storage scenarios for WAL-shaped fio workloads. The
current scenario pairs a large c6id instance-store target with a high-profile
gp3 EBS target. It now inherits the repo-wide raw-default target config unless
explicitly overridden; when filesystem-backed representative runs are needed,
the repo aligns them on `xfs`.
