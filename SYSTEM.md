# SYSTEM.md — MiniWeatherApp Execution Stack

This file documents the hardware and software environment used to generate the MiniWeather results referenced in the report.

## Hardware & Scheduler
- **Cluster:** Compute Canada teaching cluster (Magic Castle / EESSI layout)
- **Node types:**
  - *CPU nodes:* Dual-socket x86_64, 32 hardware cores total, 256 GiB RAM, DDR4 @ 3200 MT/s
  - *GPU nodes (reserved for future work):* 1× NVIDIA A100 40GB per node, 64 GiB system RAM (no usable NVHPC compilers yet)
- **Interconnect:** HDR Infiniband (fat-tree).
- **Scheduler:** Slurm 23.x with accounting enabled (use `sacct`).

## Operating System & Drivers
- **OS image:** Rocky Linux 9.2 (Compute Canada StdEnv/2023)
- **Kernel:** 5.14.x-std
- **GPU drivers:** NVIDIA 535.xx (loaded but unused until OpenACC builds succeed)
- **CUDA runtime:** 12.2 (preinstalled on GPU nodes)

## Compilers & Toolchains
- **GCC:** 12.2.0 (via `module load gcc/12.2.0` or `StdEnv/2023`)
- **OpenMPI:** 4.1.5 (MPI C compiler exposed as `mpicc`)
- **NVIDIA HPC SDK:** not present; `module load nvhpc` succeeds but `nvc`/`nvc++`/`nvfortran` binaries are missing from `$PATH`.
- **Profiling tools:** `perf` (module), `likwid` optional when available.

## Required Modules (see `env/modules.txt`)
```text
gcc/12.2.0
openmpi/4.1.5
perf
# likwid (optional)
```
Activate them via `source env/load_modules.sh` (loads `StdEnv/2023` or falls back to GCC) or manually using cluster-specific commands.

## Containers
- **Apptainer/ Singularity recipe:** `env/project.def` (MiniWeather-HPC). Default parameters: `GRID_SIZE_X=128`, `GRID_SIZE_Y=128`, `GRID_SIZE_Z=64`, `TIMESTEPS=100`.
- Build command:
  ```bash
  apptainer build miniweather.sif env/project.def
  ```
  Use when site-provided toolchains drift from the tested versions.

## Runtime Conventions
- **Default MPI tasks:** `NUM_NODES_DEFAULT=1`, `TASKS_PER_NODE_DEFAULT=4` (see `project.def`).
- **Environment variables:** Slurm scripts export `NX/NY/NZ/STEPS`, `OMP_NUM_THREADS`, `SLURM_CPUS_PER_TASK`.
- **Diagnostics:** Scheduler stats via `scripts/save_sacct.sh`; METRICS emitted in stdout/err for each job.

Keep this file updated when the cluster images, modules, or hardware change so future teams can reproduce results with matching environments.
