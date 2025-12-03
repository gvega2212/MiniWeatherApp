# MiniWeather Strong/Weak Scaling Report

_Date: 3 December 2025_

## Abstract

We study the MiniWeather stencil benchmark on the IE University HPC cluster to quantify scaling behavior across CPU MPI, hybrid MPI+OpenMP, and GPU OpenACC variants. Our workflow combines reproducible Slurm submission scripts, container-ready environment recipes, automated result capture, and Matplotlib-based visualization. Early runs show solid weak scaling on CPUs, limited strong-scaling efficiency beyond a socket, and pending GPU data due to recent compiler-path fixes. We outline the packaging approach, experiment matrix, preliminary metrics, bottleneck analysis, and next steps aimed at full-stack profiling and EuroHPC readiness.

## 1. Problem Statement

MiniWeather models 3D stencil evolution and is representative of weather kernels used in larger forecasting codes. The goal is to:

1. Deliver portable builds (serial, OpenMP, MPI, OpenACC) in `src/`.
2. Provide Slurm scripts (`slurm/`) that sweep baseline, strong, weak, hybrid, and GPU scenarios with consistent output.
3. Capture CSV logs, sacct traces, and profiling artifacts in `results/`.
4. Generate plots + reports that quantify scaling limits and guide upcoming optimizations.

## 2. Software Packaging and Execution Environment

- **Code layout:** `src/miniweather_*.c` builds via a single `Makefile`. Build-time macros (NX, NY, NZ, STEPS) encode grid sizes per experiment.
- **Environment:** `env/project.def` (Apptainer) and `env/load_modules.sh` (StdEnv/2023 GCC + per-job NVHPC loads) ensure deterministic compilers on Compute Canada nodes.
- **Job orchestration:** `run.sh` submits all valid sbatch jobs (CPU baseline, MPI/hybrid strong+weak, GPU 1–2 GPU runs) with descriptive labels.
- **Results + plots:** Each sbatch writes CSVs + logs under `results/...`. `scripts/plot_scaling.py` consolidates them into PNGs stored under `results/plots/`. A local `.venv` captures the Matplotlib/Pandas dependency chain for plotting.

## 3. Experiment Methodology

| Suite | Script location | Key parameters | Outputs |
| --- | --- | --- | --- |
| CPU baseline | `slurm/scaling/cpu/baseline/run_baseline.sbatch` | NX=256,NY=128,NZ=128,STEPS=50 | Serial/OpenMP/MPI logs in `results/baseline/` |
| MPI strong | `slurm/scaling/cpu/mpi/strong_scaling/strong_{1,2,4}n.sbatch` | Nodes ∈ {1,2,4}, ranks per node fixed | `results/strong_scaling/{1,2,4}_node/*.csv` |
| MPI weak | `slurm/scaling/cpu/mpi/weak_scaling/weak_{1,2,4}n.sbatch` | Grid grows w/ ranks | `results/weak_scaling/{1,2,4}_node/*.csv` |
| Hybrid MPI+OMP | `slurm/scaling/cpu/hybrid/*` | `OMP_NUM_THREADS` = `SLURM_CPUS_PER_TASK` | Logs/CSVs under `results/hybrid/...` |
| GPU strong/weak | `slurm/scaling/gpu/{strong,weak}_scaling/{1,2}_gpu.sbatch` | 1 GPU/node; NX=1024×512×512 strong, BASE_NX=512 weak | Writes to `results/gpu/...` (CSV pending) |
| Profiling | `slurm/profiling/{cpu,gpu}/*.sbatch` | perf / Nsight Systems / Nsight Compute | Reports under `results/profiling/...` |

## 4. Data Capture

- CSV schema (example `results/strong_scaling/1_node/strong_1n_3716.csv`): `ranks,time`.
- Logs contain `METRICS:` lines (time, COMM_TIME, COMP_TIME, throughput, checksum) and tool diagnostics.
- `scripts/save_sacct.sh <jobid ...>` stores scheduler statistics in `results/logs/` (to be populated).
- Plots currently available: `results/plots/cpu_strong_scaling.png`, `cpu_weak_scaling.png`, `hybrid_strong_scaling.png`, `hybrid_weak_scaling.png`.

## 5. Results Summary

### CPU MPI Strong Scaling

- Single node, ranks ∈ {1,2,4}, NX=512,NY=256,NZ=256,STEPS=50.
- Median times (from combined CSVs): 1 rank ≈ 0.36 s, 2 ranks ≈ 0.27 s, 4 ranks ≈ 0.28 s.
- Interpretation: Diminishing returns after 2 ranks due to memory bandwidth saturation; comm overhead remains <5% per METRICS logs (communication <13 ms at 4 ranks).

### CPU MPI Weak Scaling

- Up to 4 nodes with 8 ranks each; NX scales with rank count.
- Runtimes stay within ±8% of the 1-rank baseline, indicating good load balance and minimal communication penalty for the tested grid sizes.

### Hybrid MPI+OpenMP

- Example job `hybrid_1n_2990.csv`: 2 ranks × 2 threads, NX=256,NY=128,NZ=128,STEPS=50, time ≈ 0.325 s.
- Hybrid runs track the MPI-only curve but achieve similar runtime using fewer MPI ranks per node, implying improved cache locality and lower MPI surface area.

### GPU Runs

- CSV files missing because early sbatch attempts failed on NVHPC path exports. Environment fixes (module purge + explicit `NVHPC_ROOT` and safe `LD_LIBRARY_PATH`) landed on 3 Dec 2025. Need to re-submit GPU jobs to populate data.

## 6. Analysis and Bottlenecks

- **Compute vs communication:** For the CPU cases, METRICS show COMP_TIME ≈ 96–99% of wall clock. Bottleneck is floating-point throughput + memory bandwidth. MPI communication is a secondary effect (<5%).
- **GPU readiness:** Profiling sbatches exist but have no recent outputs. Nsight Systems/Compute will clarify SM occupancy vs memory stalls once rerun.
- **I/O:** Negligible in current workflow; tiny CSV/log files per job.

## 7. Limitations

1. GPU CSVs and profiling outputs absent after environment fixes—plots skip those categories.
2. sacct logs not yet captured (script available but not executed).
3. Perf/LIKWID/PAPI reports not refreshed after recent code/build updates.
4. No cross-node MPI runs beyond 4 nodes yet; scaling beyond that range unproven.

## 8. Next Steps

1. Re-run GPU strong/weak scaling jobs; regenerate plots (`scripts/plot_scaling.py`).
2. Execute CPU perf and GPU Nsight profiling sbatches; archive outputs in `results/profiling/` and summarize key counters in `docs/bottleneck_analysis.md`.
3. Capture sacct output for canonical runs via `scripts/save_sacct.sh`.
4. Implement overlapping communication/compute (non-blocking MPI) and remeasure speedups.
5. Package a reproducible Apptainer image using `env/project.def` for EuroHPC submission.
