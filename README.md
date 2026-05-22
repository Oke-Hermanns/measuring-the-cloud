# Cloud Measuring

Lean benchmark framework for comparing cloud network and storage performance.

The current implemented slice is the STACKIT network benchmark path, with a
persistent benchmark runner VM for private-IP execution:

- provision a small runner VM plus shared network/security plumbing with
  OpenTofu
- stage only the required repository assets to the runner with `rsync`
- generate a runner-local SSH key for the scenario VMs
- run the benchmark suite on the runner over private IPs
- bootstrap tools through cloud-init
- run all non-skipped network benchmark files on the scenario pair
- fetch raw artifacts back from the runner
- destroy infrastructure to control cost

## Network Quick Start

Copy and edit the STACKIT foundation tfvars:

```bash
cp network/infra/stackit-runner/basic-infra.tfvars.example network/infra/stackit-runner/basic-infra.tfvars
```

Then provision the runner and start a benchmark run:

```bash
./network/scripts/provision_runner.sh \
  --service-account-json /path/to/stackit-service-account.json \
  --scenario network/scenarios/stackit-baseline.sh
```

The helper prints a fetch command for the completed run. Use it to pull the
results back to your workstation once the run has finished:

```bash
./network/scripts/fetch_runner_results.sh \
  --runner-host <runner-public-ip> \
  --ssh-key ~/.ssh/id_ed25519 \
  --run-id run-YYYYMMDD-HHMMSS
```

The direct local runner is still available for ad-hoc execution:

```bash
./network/runner.sh --dry-run --scenario network/scenarios/stackit-baseline.sh
./network/runner.sh --scenario network/scenarios/stackit-baseline.sh --destroy always
```

Artifacts are downloaded to:

```text
artifacts/network/runner-control/<run-id>/
artifacts/network/<run-id>/<scenario-name>/
```

## Contracts

Infrastructure scenarios are shell files, for example
`network/scenarios/stackit-baseline.sh`. Required variables:

```bash
SCENARIO_NAME=stackit-baseline
PROVIDER=stackit
TOFU_DIR=network/infra/stackit
TFVARS_FILE=network/scenarios/stackit-baseline.tfvars
BENCHMARK_DIR=network/benchmarks
```

Benchmark files are shell files in `network/benchmarks/`. Required variables:

```bash
BENCHMARK_NAME=iperf3-tcp-1s
BENCHMARK_TOOL=iperf3
SKIP=0
```

Set `SKIP=1` to keep a benchmark file in the directory without running it.

Network scenario files may set:

```bash
OS_TUNING=standard
INSTANCE_AFFINITY=none
```

Supported `OS_TUNING` values are `standard` and `network-throughput`.
Supported `INSTANCE_AFFINITY` values are `none`, `co-located`, and `different-host`.

The scenario matrix under `network/scenarios/matrix/` encodes:

- affinity: `co-located` or `different-host`
- zone: `eu01-1` for both client and server
- instance type: `g2a.2d`, `g2a.8d`, `g2a.120d`
- OS profile: `standard` or `tuned`

The matrix scenarios are explicit files that source a shared constants file and
set the scenario-specific values directly. They reuse the baseline tfvars file
and the runner overlays the scenario-specific values before provisioning.

Cross-AZ cases are deferred for a later scenario family where both client and
server zones vary together.

The initial real network suite is:

- `sockperf-tcp-64b`
- `sockperf-udp-64b`
- `iperf3-tcp-1s`
- `iperf3-tcp-4s`
- `iperf3-udp-1g`
- `iperf3-udp-9g`
- `iperf3-udp-25g`
- `iperf3-udp-90g`

The UDP-oriented high-throughput scenario runs:

- `iperf3-udp-mtu-90g-4s`

That benchmark uses MTU-sized UDP payloads and the `network-throughput` OS profile.

Default runtimes and repetitions:

- `sockperf`: 30s runtime, 5 repetitions
- `iperf3` TCP: 30s runtime, 3 repetitions, default `IPERF3_TCP_LENGTH=128K`
- `iperf3` UDP: 30s runtime, 3 repetitions
