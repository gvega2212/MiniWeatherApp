# MiniWeatherApp

Parallel performance exploration of the MiniWeather mini-application across serial, OpenMP, MPI, hybrid MPI+OpenMP, and (planned) OpenACC GPU implementations on a CPU-focused teaching cluster.

## Project Goals
- Provide portable CPU and GPU-ready builds in `src/` using a single Makefile and tunable grid macros (`NX`, `NY`, `NZ`, `STEPS`).
- Automate baseline, strong-scaling, weak-scaling, and hybrid studies through Slurm batch scripts under `slurm/` and the umbrella `run.sh` launcher.
- Capture timing CSVs, verbose logs, and scheduler traces under `results/` so they can feed reproducible plots from `scripts/plot_scaling.py`.
- Summarize bottlenecks and scaling ceilings to guide future optimization efforts.

## Repository Layout
| Path | Purpose |
| --- | --- |
| `src/` | MiniWeather sources (`miniweather_*.c`) plus the Makefile that drives serial, OpenMP, MPI, hybrid, and OpenACC builds. |
| `slurm/` | Batch scripts for baseline, scaling, hybrid, GPU, and profiling campaigns (perf and Nsight). |
| `scripts/` | Utility helpers such as `plot_scaling.py` (Matplotlib/Pandas plots) and `save_sacct.sh` (scheduler stats). |
| `results/` | Job outputs. Each experiment type writes CSVs + logs into matching subfolders; plots land in `results/plots/`. |
| `env/` | `project.def` Apptainer recipe plus `load_modules.sh` and `modules.txt` describing the Compute Canada software stack. |
| `docs/` | Short paper, proposal, and supporting documentation. |
| `reproduce.md` | Placeholder for cluster-specific reproduction notes (extend with site-specific steps when available). |

## Prerequisites & Environment
1. **Modules / Compilers**
   - CPU runs: GCC-based `StdEnv/2023` toolchain with `openmpi` (or cluster equivalent) and `make`.
   - GPU (OpenACC) runs: NVIDIA HPC SDK (`nvhpc`) providing `nvc`, `nvc++`, or `nvfortran`. The campus cluster currently lacks these binaries, preventing GPU builds.
2. **Python plotting stack**
   - Create a local `.venv` (not versioned) and install `matplotlib` + `pandas` to regenerate plots.
3. **Optional containers**
   - `env/project.def` describes the Apptainer image used for deterministic builds on Compute Canada; adjust for other HPC sites.

## Building MiniWeather
```bash
# From repo root
eval "$(./env/load_modules.sh)"   # or source the equivalent module loads
cd src
make cpu      # builds serial + OpenMP + MPI + hybrid targets
make gpu      # requires NVIDIA HPC SDK; currently blocked on the teaching cluster
# Override grid via "make NX=512 NY=256 NZ=256 STEPS=100 cpu"
```
Artifacts are placed in `src/` alongside the sources. Use the provided `run_*` Make targets for quick local smoke tests before submitting Slurm jobs.

## Running the Experiment Suite
`run.sh` orchestrates every supported batch job. It sweeps baseline CPU, MPI strong/weak scaling (1–4 nodes), hybrid strong/weak, and 1–2 GPU placeholders.

```bash
./run.sh
# -> emits "Submitting <label>" lines as it calls sbatch on each script
```
Each Slurm script encodes the grid, ranks-per-node, threading, and output destinations under `results/`. Edit the `.sbatch` files if you need different queue names, partitions, or walltime limits.

### Individual scripts
- `slurm/scaling/cpu/baseline/run_baseline.sbatch` — serial, OpenMP, and MPI baselines on a single node.
- `slurm/scaling/cpu/mpi/{strong,weak}_scaling/strong|weak_{1,2,4}n.sbatch` — MPI scaling sweeps.
- `slurm/scaling/cpu/hybrid/...` — MPI+OpenMP strong/weak studies; set `OMP_NUM_THREADS` to `SLURM_CPUS_PER_TASK`.
- `slurm/scaling/gpu/...` — GPU strong/weak templates (currently disabled because OpenACC builds fail without `nvc`).
- `slurm/profiling/{cpu,gpu}/*.sbatch` — perf + Nsight Systems/Compute jobs.

## Data, Logs, and Plotting
- Each job writes `*.csv` timing files plus `.err`/`.out` logs beneath `results/<experiment>/...`. CSV schema is consistent (`ranks,time` or `gpus,time`).
- Scheduler metadata can be captured via `scripts/save_sacct.sh <jobid>`; outputs live under `results/logs/` once run.
- `scripts/plot_scaling.py` parses the CSVs and emits PNGs (e.g., `results/plots/cpu_strong_scaling.png`). Activate the local Python environment before running the script.

## Key Findings (50-step, 256×128×128 baseline)
### CPU MPI Strong Scaling
| Configuration | Time (s) | Notes |
| --- | --- | --- |
| 1 node, 1 rank | 2.98 | Baseline serial-equivalent. |
| 1 node, 2 ranks | 2.08 | Strongest intra-node speedup (compute still dominant). |
| 1 node, 4 ranks | 2.19 | Slight slowdown; memory bandwidth saturates. |
| 2 nodes, 8 ranks | 1.12 | Best runtime, but relies on inter-node comms. |
| 4 nodes, 8 ranks | 1.33 | Extra hop penalties erase benefit. |

**Takeaway:** Work per rank is too small to hide MPI communication once leaving a single socket; scaling plateaus quickly.

### CPU MPI Weak Scaling
Runtime should stay flat as ranks grow, yet the measurements rise steadily:
- 1-node sweep: 0.37 → 1.08 s from 1 → 4 ranks.
- 2-node sweep: 0.46 → 1.09 s from 2 → 8 ranks.
- 4-node sweep: 0.99 → 1.10 s from 4 → 8 ranks.

**Takeaway:** Halo exchanges dominate as the grid expands; network latency outweighs marginal compute growth.

### Hybrid MPI + OpenMP
| Experiment | Best time (s) | Observation |
| --- | --- | --- |
| Strong scaling (2 ranks, 2 threads) | 0.33 | Sweet spot; additional ranks reintroduce MPI overhead. |
| Weak scaling (1 → 4 nodes) | 0.85 → 3.88 | Thread count mismatches (1 thread/run at 4 nodes) undercut hybrid benefits. |

**Takeaway:** Hybridism only helps at modest core counts; inconsistent thread provisioning plus low per-thread work limits gains.

### GPU Status
OpenACC binaries (`miniweather_openacc`, `miniweather_mpi_openacc`) could not be produced because the teaching cluster lacks the NVIDIA HPC compilers even though the `nvhpc` module nominally loads. GPU experiments remain placeholders until those compilers become available.

## Bottlenecks & Future Work
1. **Communication vs compute** — METRICS logs show `COMP_TIME` consumes ~96–99% of wall time, implying global performance hinges on floating-point throughput and memory bandwidth rather than messaging. Optimize by blocking the stencil, improving cache reuse, or raising arithmetic intensity.
2. **MPI scaling limits** — Explore larger grids (increase `NX/NY/NZ`) so each rank performs more work, delaying the communication cliff. Consider hierarchical domain decompositions or overlapping computation/communication.
3. **Hybrid consistency** — Align `OMP_NUM_THREADS` with physical cores, ensure thread pinning, and revisit MPI rank counts per node to avoid oversubscription.
4. **GPU enablement** — Once `nvc` / `nvc++` are available, enable the OpenACC targets and re-run the GPU sbatch jobs; profile with Nsight Systems/Compute to inspect SM occupancy versus memory stalls.
5. **Diagnostics completeness** — Populate `results/logs/` via `save_sacct.sh`, refresh perf / Nsight captures, and document reproduction notes in `reproduce.md`.


