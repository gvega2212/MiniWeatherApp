# MiniWeather Bottleneck Notes

_Last updated: 2025-12-03_

## Data Sources

- CPU MPI strong-scaling job `strong_1n_3716` (NX=512, NY=256, NZ=256, STEPS=50) – METRICS lines captured in `results/strong_scaling/1_node/*3716.log`.
- Hybrid 1-node logs (e.g., `results/hybrid/strong_scaling/1_node/hybrid_1n_2990.csv`) for combined MPI+OpenMP timing.
- GPU runs are pending (CSV generation was blocked earlier by missing NVHPC paths); rerun the GPU jobs to populate `results/gpu/.../*.csv` before extending this analysis to accelerators.

## Quick Metrics Snapshot

| Config | Ranks/GPUs | Time (s) | Comm % | Comp % |
| --- | --- | --- | --- | --- |
| MPI strong scaling (job 3716) | 1 rank | 0.364 | 0.01 | 99.99 |
|  | 2 ranks | 0.272 | 3.09 | 98.91 |
|  | 4 ranks | 0.279 | 4.36 | 97.85 |
| Hybrid strong scaling (job 2990) | 2 ranks × 2 threads | 0.325 | ~5 (from METRICS) | ~95 |

### Interpretation

- **Compute-bound on CPUs:** Even at 4 MPI ranks on a single node, compute time still accounts for >95% of the wall clock. Memory bandwidth is the likely limiter (stencil kernels are streaming), not communication.
- **Communication overhead emerges when scaling out:** Comm% jumps from 0.01 → ~4% as we move from 1 → 4 ranks, but absolute time savings plateau (0.364s → 0.279s). Expect diminishing returns beyond a single socket without overlapping halos.
- **Hybrid runs recover some locality:** Hybrid 2r×2t shows latency similar to pure MPI (0.325s) with fewer MPI ranks touching the network. This hints that threading per rank helps hide comm costs but we still need more data points (threads=4/8).

## What’s Missing

- **GPU insight:** Nsight Systems/Compute jobs haven’t been re-run since fixing the NVHPC module exports, so we lack updated accelerator diagnostics.
- **Perf/LIKWID/PAPI captures:** The CPU profiling sbatch scripts exist (`slurm/profiling/cpu/*`), but the latest runs aren’t in `results/profiling/`. Re-run them and archive the generated reports for any future paper/proposal.
- **sacct accounting logs:** Save `sacct -j <jobid> --format=JobID,Elapsed,AveCPU,MaxRSS` results into `results/logs/` so we can correlate scheduler-reported resource use with in-app timing.

## Next Steps

1. Re-run the perf + Nsight sbatch jobs now that environment issues are solved; push their text reports under `results/profiling/...`.
2. Capture sacct output for the canonical runs (baseline, strong/weak scaling) and store them in `results/logs/`.
3. Add additional hybrid configurations (threads 4/8) and GPU CSVs so the plotting script can emit complete figures.
4. Once GPU data exists, extend this document with compute vs. memory vs. PCIe/communication observations from Nsight kernels (occupancy, dram util, SM efficiency).
