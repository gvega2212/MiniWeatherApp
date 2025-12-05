# MiniWeather Reproduction Guide

This document captures how to rebuild the MiniWeather binaries, submit the full Slurm experiment sweep, and regenerate every artifact discussed in the accompanying report. The instructions assume access to the Compute Canada–style teaching cluster used by the project team; adapt queue or module names to your site as needed.

## 1. Cluster Prerequisites
- Slurm account with permission to run on 1–4 CPU nodes (and optionally 1–2 GPUs, once OpenACC builds are available).
- GCC toolchain plus OpenMPI. The repo ships a helper script: `env/load_modules.sh` loads `StdEnv/2023` or falls back to `gcc`.
- Optional NVIDIA HPC SDK (`nvc`, `nvc++`, `nvfortran`) for GPU/OpenACC builds. These compilers are currently **absent** on the teaching cluster, so GPU jobs are placeholders until the modules appear.
- Python 3.10+ with `matplotlib` and `pandas` (install in a local `.venv`) for plot regeneration.

## 2. Repository Checkout
```bash
git clone https://github.com/gvega2212/MiniWeatherApp.git
cd MiniWeatherApp
```
All paths in this guide are relative to the repo root.

## 3. Environment Setup
```bash
# reuse the helper script
source env/load_modules.sh

# Optional: build the documented Apptainer image
apptainer build miniweather.sif env/project.def
```
If your site requires additional performance tools (e.g., `perf`, `likwid`), load them here. Confirm `mpicc` and `mpirun` resolve to the desired MPI stack before compiling.

## 4. Build the Binaries
```bash
cd src
make clean            # optional but ensures a fresh build
make cpu              # builds serial, OpenMP, MPI, and hybrid targets
make gpu              # requires NVIDIA HPC SDK (will fail without nvc)

# Override the grid when exploring other problem sizes
make cpu NX=512 NY=256 NZ=256 STEPS=100
```
Executables remain in `src/`. Use `make run_serial`, `make run_openmp`, or `make run_mpi_local N=4` for quick smoke tests on login nodes (short runs only).

## 5. Submit the Experiment Suite
The `run.sh` wrapper dispatches every supported sbatch script with descriptive labels:
```bash
./run.sh
```
It covers:
- CPU baseline (serial, OpenMP, MPI)
- MPI strong/weak scaling on 1, 2, and 4 nodes
- Hybrid MPI+OpenMP strong/weak runs
- GPU strong/weak templates for 1–2 GPUs (pending functional compilers)

Need a subset? Call `sbatch` on individual files under `slurm/`—for example, `sbatch slurm/scaling/cpu/mpi/strong_scaling/strong_2n.sbatch`. Update partition names, walltimes, or account strings directly inside the `.sbatch` headers to match your cluster policy.

## 6. Collect Logs and Metrics
- Each job writes CSVs and stdio logs into `results/<experiment>/...` (mirrors the slurm directory structure).
- Capture scheduler statistics after completion:
	```bash
	./scripts/save_sacct.sh <jobid1> <jobid2>
	```
	Outputs land in `results/logs/sacct_<jobid>.txt`.
- Profiling jobs under `slurm/profiling/{cpu,gpu}` store their artifacts in `results/profiling/`.

## 7. Generate Plots
Activate your Python environment (with Matplotlib/Pandas) and run:
```bash
source .venv/bin/activate    # if using a local venv
python scripts/plot_scaling.py
```
PNG files such as `results/plots/cpu_strong_scaling.png` will be regenerated. Pass explicit names (e.g., `python scripts/plot_scaling.py cpu_strong hybrid_weak`) to limit the build.

## 8. Expected Outputs
- `results/baseline/` — serial/OpenMP/MPI reference logs and CSVs.
- `results/strong_scaling/<nodes>/strong_<nodes>n_<jobid>.csv` — MPI strong-scaling timers with `ranks,time` columns.
- `results/weak_scaling/<nodes>/weak_<nodes>n_<jobid>.csv` — per-rank weak-scaling measurements.
- `results/hybrid/...` — hybrid CSVs plus `*.err` files containing METRICS lines (`TIME`, `COMM_TIME`, `COMP_TIME`, throughput, checksum).
- `results/gpu/...` — placeholder directories; expect empty CSVs until OpenACC builds succeed.

## 9. Known Limitations & Troubleshooting
- **GPU builds fail** while `nvc`, `nvc++`, and `nvfortran` are missing from `$PATH`. Either install the NVIDIA HPC SDK locally or request the module from cluster admins.
- **Bandwidth-limited scaling** — small grids (`256×128×128, 50 steps`) make MPI runs sensitive to interconnect latency. Increase `NX/NY/NZ` for more work per rank when reproducing results.
- **Results directory is git-ignored** — archive `results/` manually if you need to share raw data.
- **Module mismatches** — ensure `mpicc --version` matches the MPI runtime on compute nodes; inconsistent stacks can crash at launch.
- **Job quota errors** — submit strong/weak sweeps in smaller batches if Slurm enforces strict per-user job limits.

Following the steps above yields the same CSVs, logs, and plots that informed the MiniWeather scaling report. Adjust parameters cautiously and document any deviations so future readers can compare apples to apples.