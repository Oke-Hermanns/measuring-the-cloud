# Network Benchmarks

The network runner provisions a client/server pair for each infrastructure
scenario, runs benchmark files on that pair, fetches results, and then destroys
the infrastructure according to the selected destroy policy.

For unattended execution, there is a separate persistent STACKIT foundation
stack in `infra/stackit-runner/` which provisions a small runner VM,
shared network, and shared security group. The benchmark runner can be staged
onto that VM and then executed over private IPs only.

## Runner

```bash
./network/runner.sh \
  --scenario network/scenarios/stackit/baseline.sh \
  --out artifacts/network \
  --destroy always
```

The baseline scenarios are `stackit-baseline` and `aws-baseline`. Scenario
folders under `network/scenarios/` are organized provider-first, then by
intent, and are discovered recursively by `--scenario-dir`. See each folder's
README for the current scope of that folder.

Useful options:

```text
--scenario FILE          run one scenario file; may be repeated
--scenario-dir DIR       run all *.sh scenarios in sorted order
--benchmark NAME         run only one named benchmark; may be repeated
--access-mode MODE       public or private SSH control path
--destroy MODE           always, success, or never
--continue-on-error      continue with later scenarios after a failure
--dry-run                print the resolved plan without provisioning
```

## Dedicated Runner

Copy and edit the shared runner foundation tfvars file:

```bash
cp infra/stackit-runner/basic-infra.tfvars.example infra/stackit-runner/basic-infra.tfvars
```

Then provision the runner and launch the benchmark suite on it:

```bash
./scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --scenario-dir network/scenarios/stackit/all
```

The helper stages only the required repository assets to the runner via
`rsync`, creates a runner-local SSH key for the scenario VMs, writes the
baseline tfvars on the runner, and starts the detached benchmark run through
the runner-side launcher script.

In private runner mode, the generated benchmark tfvars set
`assign_public_ip = false`, so the benchmark client and server are reachable
only over private IPs. Their private IPs are auto-assigned by STACKIT and then
read back from `tofu output`.

After the run, fetch the full result tree back to the workstation:

```bash
./scripts/fetch_runner_results.sh --workload network \
  --runner-host <runner-public-ip> \
  --ssh-key ~/.ssh/id_ed25519 \
  --run-id run-YYYYMMDD-HHMMSS
```

To tear down the persistent foundation stack:

```bash
./scripts/destroy_runner.sh
```

## Scenario Files

Scenario files are sourced shell files:

```bash
SCENARIO_NAME=stackit-baseline
PROVIDER=stackit
TOFU_DIR=network/infra/stackit
TFVARS_FILE=network/scenarios/stackit/baseline.tfvars
BENCHMARK_DIR=network/benchmarks/full
PLACEMENT_MODE=single-az
OS_TUNING=standard
INSTANCE_AFFINITY=different-host
SKIP=0
```

The concrete cloud setup starts from the referenced tfvars file. The runner
overlays scenario-specific values before provisioning, such as client/server
machine types, availability zones, instance affinity, and OS tuning.

For AWS, copy the example tfvars before provisioning real infrastructure:

```bash
cp network/scenarios/aws/baseline.tfvars.example \
  network/scenarios/aws/baseline.tfvars
```

AWS credentials are resolved by the AWS provider. Set `aws_profile` in the
tfvars file, leave it empty to use environment credentials, or use the standard
AWS credential chain.

Supported OS tuning profiles:

```text
standard             no network tuning beyond the base image
network-throughput   BBR/fq, larger socket buffers, larger backlogs, and
                     best-effort NIC ring/tx queue tuning
```

Supported instance affinity profiles:

```text
none              provider default placement
co-located        hard-affinity, keep the client and server on the same host
different-host    hard-anti-affinity, force client and server onto different hosts
```

On AWS, `co-located` maps to an EC2 cluster placement group and
`different-host` maps to a spread placement group.

Approximate instance pairings used by the AWS scenario matrix:

```text
STACKIT g2a.2d    AWS c6id.large
STACKIT g2a.8d    AWS c6id.2xlarge
STACKIT g2a.120d  AWS c6id.32xlarge
```

## Benchmark Files

Benchmark files are sourced shell files in `network/benchmarks/`.

`iperf3` example:

```bash
BENCHMARK_NAME=iperf3-tcp-4s
BENCHMARK_TOOL=iperf3
SKIP=0

IPERF3_PROTOCOL=tcp
IPERF3_PORT=5201
IPERF3_RUNTIME_SEC=30
IPERF3_OMIT_SEC=3
IPERF3_PARALLEL=4
IPERF3_TCP_LENGTH=128K
REPETITIONS=3
COOLDOWN_SEC=5
SERVER_READY_TIMEOUT_SEC=30
```

`sockperf` example:

```bash
BENCHMARK_NAME=sockperf-udp-64b
BENCHMARK_TOOL=sockperf
SKIP=0

SOCKPERF_PROTOCOL=udp
SOCKPERF_MODE=pp
SOCKPERF_PORT=11111
SOCKPERF_MSG_SIZE=64
SOCKPERF_RUNTIME_SEC=30
REPETITIONS=5
COOLDOWN_SEC=5
SERVER_READY_TIMEOUT_SEC=30
```

Set `SKIP=1` to keep a file without executing it.
For scenario files, `SKIP=1` skips the whole scenario during discovery and
dry-run reporting.

Benchmark commands are automatically wrapped with `taskset`. The runner uses
all available CPUs except CPU 0 on each host, or CPU 0 if the host exposes only
one CPU. This is intentionally not part of the benchmark-file contract.
`sockperf` client runs write the raw `sockperf.log`.

When the runner is launched through `provision_runner.sh`, it uses private IPs
for all benchmark control traffic. The foundation stack only needs to be
provisioned once and can be reused across scenario runs.

## Result Layout

```text
artifacts/network/<run-id>/<scenario-name>/
  launcher.log
  commands.log
  remote-exec.log
  scenario.env
  node-meta.log
  server/node-meta.log
  benchmarks/<benchmark-name>/
    benchmark.env
    rep-1/
      client/client.cmd
      client/<tool>.log
      client/iperf3.json   # iperf3 only
      server/server.cmd
      server/server.log
```
