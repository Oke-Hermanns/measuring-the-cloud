# Storage Benchmarks

The storage runner provisions one benchmark VM per scenario, prepares the
available storage targets on that VM, runs `fio` benchmark files on the
discovered targets, fetches the raw artifacts, and then destroys the
infrastructure according to the selected destroy policy.

The supported cloud paths are STACKIT and AWS. STACKIT can also use the shared
persistent runner foundation in `infra/stackit-runner/`; when that runner is
used, the storage VM is controlled over private IPs only.

## Quick Start

Copy and edit the shared baseline tfvars:

```bash
cp storage/scenarios/stackit-baseline.tfvars.example \
  storage/scenarios/stackit-baseline.tfvars
```

For AWS, copy and edit the AWS baseline tfvars:

```bash
cp storage/scenarios/aws-baseline.tfvars.example \
  storage/scenarios/aws-baseline.tfvars
```

Run one scenario locally:

```bash
./storage/runner.sh \
  --scenario storage/scenarios/all/stackit_g2a.30d_storage_premium_perf6_standard.sh \
  --destroy always
```

Run AWS EBS or instance-store scenarios locally:

```bash
./storage/runner.sh \
  --scenario storage/scenarios/aws/aws_c6i.large_ebs-gp3_standard.sh \
  --benchmark fio-randread-4k-q32 \
  --destroy always

./storage/runner.sh \
  --scenario storage/scenarios/aws/aws_i4i.large_local_standard.sh \
  --benchmark fio-randread-4k-q32 \
  --destroy always
```

Run it through the shared runner:

```bash
./scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --workload storage \
  --scenario-dir storage/scenarios/all
```

Scenario folders under `storage/scenarios/` group explicit scenario files by
intent. Some folders run broad matrices, while others contain focused subsets
such as block-only or local-only storage. See each folder's README for the
current scope of that folder.

The default benchmark suite is:

```text
storage/benchmarks/full/
```

It covers:
- `psync` latency tests at 4 KiB for `randread`, `randwrite`, `seqread`, and `seqwrite`
- `io_uring` throughput-oriented tests at 4 KiB and 128 KiB for the same four access patterns

All files use the same raw-artifact contract and repetitions/cooldown defaults.

On `g2a.30d`, the setup script discovers both the instance-local disk and the
attached block volume, skips the root volume, and benchmarks the discovered
non-root targets. The current detection prefers udev metadata first:
the local disk is identified by the `ephemeral0` filesystem label and the
attached block volume by its device identity/serial, with size used only as a
fallback if metadata is incomplete.

On AWS, attached EBS volumes are discovered by EBS volume id through NVMe
by-id links. Instance-store NVMe disks are discovered by the AWS instance-store
device model and exposed as the `local` target.

## Scenario Contract

Storage scenarios are shell files and may define:

```bash
SCENARIO_NAME=stackit_g2a.30d_storage_premium_perf6_standard
PROVIDER=stackit
TOFU_DIR=storage/infra/stackit
TFVARS_FILE=storage/scenarios/stackit-baseline.tfvars
BENCHMARK_DIR=storage/benchmarks/full
OS_TUNING=standard
BENCHMARK_MACHINE_TYPE=g2a.30d
BENCHMARK_IMAGE_ID=7b10e105-295b-4369-b6e0-567ec940a02b
BLOCK_VOLUME_SIZE_GIB=300
BLOCK_VOLUME_PERFORMANCE_CLASS=storage_premium_perf6
LOCAL_FILESYSTEM=xfs
BLOCK_FILESYSTEM=ext4
SKIP=0
```

`SKIP=1` skips a whole scenario during discovery and dry-run reporting.
`BLOCK_VOLUME_SIZE_GIB=0` disables the additional benchmark block volume; the
root volume is still provisioned as the VM boot disk.

`LOCAL_FILESYSTEM` and `BLOCK_FILESYSTEM` make the formatted filesystem part of
the scenario contract. Supported values are `ext4` and `xfs`. Defaults preserve
the historical behavior: local storage uses `xfs`, and attached block storage
uses `ext4`.

## Benchmark Contract

Benchmark files are shell files under `storage/benchmarks/` and define `fio`
parameters. Required variables:

```bash
BENCHMARK_NAME=fio-randread-4k-psync
BENCHMARK_TOOL=fio
SKIP=0
```

Typical `fio` settings for the 4 KiB `io_uring` throughput tests:

```bash
FIO_IOENGINE=io_uring
FIO_RW=randread
FIO_BS=4k
FIO_IODEPTH=32
FIO_NUMJOBS=1
FIO_RUNTIME_SEC=60
FIO_DIRECT=1
FIO_GROUP_REPORTING=1
FIO_TIME_BASED=1
FIO_SIZE=1G
REPETITIONS=3
COOLDOWN_SEC=5
```

For the `psync` latency profiles, use the same shape with
`FIO_IOENGINE=psync` and `FIO_IODEPTH=1`.

The runner automatically wraps the command with `taskset`, uses all CPUs
except CPU 0 when possible, and skips the root volume. Storage targets are
discovered from the benchmark VM and written to a small env file on the host.
The selected target filesystem is copied into `storage.env`, `scenario.env`,
and each benchmark's `benchmark.env`.
