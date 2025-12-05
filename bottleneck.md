# MiniWeather Bottleneck Analysis

This note consolidates the limiting factors observed while running MiniWeather on the Compute Canada teaching cluster and links each bottleneck to supporting measurements plus mitigation ideas.

## Experimental Context
- Grid: baseline `256 × 128 × 128` cells, 50 time steps unless otherwise noted.
- Platforms: serial, OpenMP, pure MPI, and hybrid MPI+OpenMP builds compiled with GCC/OpenMPI. OpenACC builds are planned but currently blocked.
- Data sources: CSVs under `results/`, METRICS lines inside `*.err` logs, and the group report dated December 2025.

## CPU MPI Strong Scaling
| Config | Time (s) | Notes |
| --- | --- | --- |
| 1 node, 1 rank | 2.98 | Reference serial-like runtime. |
| 1 node, 2 ranks | 2.08 | Best intra-socket speedup before bandwidth saturates. |
| 1 node, 4 ranks | 2.19 | Slight regression; DDR channels are fully utilized. |
| 2 nodes, 8 ranks | 1.12 | Fastest overall but requires inter-node communication. |
| 4 nodes, 8 ranks | 1.33 | Extra latency from going off-node again erases gains. |

**Root cause:** Each MPI rank owns a narrow pencil of the domain, so after two ranks the memory bandwidth per rank becomes the dominant limiter. When ranks span multiple nodes, halo exchanges add latency that grows faster than compute decreases.

## CPU MPI Weak Scaling
- 1-node sweep: 0.37 → 1.08 s (1 → 4 ranks)
- 2-node sweep: 0.46 → 1.09 s (2 → 8 ranks)
- 4-node sweep: 0.99 → 1.10 s (4 → 8 ranks)

**Root cause:** Weak scaling should hold runtime constant, yet MiniWeather’s fine-grain domain decomposition increases the surface-to-volume ratio as ranks grow. The halo exchanges dominate because each subdomain’s ghost cells are a large fraction of its total volume.

## Hybrid MPI+OpenMP Runs
| Scenario | Ranks × Threads | Time (s) | Observation |
| --- | --- | --- | --- |
| Strong scaling | 2 × 2 | 0.33 | Best result; threads keep data local while MPI count stays low. |
| Strong scaling | 4 × 2 | 0.37 | MPI overhead returns; cache pressure rises. |
| Weak scaling | (1 → 4 nodes) mixed thread counts | 0.85 → 3.88 | Runs using 1 thread/rank lose hybrid benefits entirely. |

**Root cause:** Thread counts are not held constant across runs, so some jobs effectively fall back to pure MPI. Additionally, the small per-rank workload means OpenMP regions have minimal work per thread, exacerbating scheduling and cache thrash.

## GPU / OpenACC Path
- `make gpu` requires `nvc`/`nvc++`, which are not present even though an `nvhpc` module stub exists.
- GPU sbatch scripts in `slurm/scaling/gpu/` and profiling jobs under `slurm/profiling/gpu/` therefore produce no artifacts.

**Impact:** Without GPU binaries the team cannot assess whether larger on-GPU subdomains would hide communication overhead or whether SM occupancy/memory stalls become the new limiter.

## System-Level Diagnostics
- METRICS logs indicate `COMP_TIME` accounts for **96–99%** of total wall time on CPU runs, highlighting that floating-point throughput and memory bandwidth dominate. Communication still dictates scaling because its share, though small, grows superlinearly with rank count.
- Scheduler stats (when captured via `scripts/save_sacct.sh`) show high CPU utilization but low memory usage, reinforcing that latency/bandwidth, not capacity, is the constraint.

## Mitigation Roadmap
1. **Increase per-rank work:** Scale `NX/NY/NZ` proportionally to the rank count so computation grows faster than halo communication.
2. **Stencil blocking:** Reorder loops or introduce tiling to improve cache reuse and reduce memory bandwidth pressure.
3. **Communication/computation overlap:** Use nonblocking MPI calls or pipelined halo exchanges so useful work hides latency.
4. **Hybrid tuning:** Fix `OMP_NUM_THREADS`, enable thread pinning, and rebalance MPI ranks per socket to maintain a consistent threads-per-rank ratio.
5. **GPU enablement:** Work with cluster admins to install the NVIDIA HPC SDK or build it locally; once available, re-run GPU sbatch and profiling scripts to determine whether accelerators mitigate the identified bottlenecks.
6. **Enhanced diagnostics:** Always collect `results/logs/` via `save_sacct.sh` and perf/Nsight traces to track future optimizations objectively.

This file should stay updated as new datasets (larger grids, GPU runs, profiling insights) arrive so the team can quickly spot whether the dominant bottleneck has shifted.
