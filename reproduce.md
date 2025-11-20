# Reproduce MiniWeatherApp: environment, build, and runs

## Environment
Option A — Modules (recommended on HPC cluster)
1. Source the module loader:
   source ./env/load_modules.sh
   This purges modules and loads gcc/12.2.0, openmpi/4.1.5 and perf. OMP_NUM_THREADS defaults to 8.

Option B — Apptainer / Singularity
1. Build the container (requires apptainer/singularity on host):
   apptainer build env/miniweather.sif env/project.def
2. Run inside container:
   apptainer exec env/miniweather.sif /bin/bash

## Build
From repo root:
make -C src clean
make -C src
You can override problem sizes at build time. Example:
make -C src miniweather_serial NX=128 NY=128 NZ=64 STEPS=20

## Slurm job submission
Use run.sh or sbatch directly.
Examples:
./run.sh baseline
./run.sh strong
./run.sh weak
./run.sh hybrid

Or submit a single script:
sbatch slurm/baseline/run_baseline.sbatch

Scripts:
- slurm/baseline/run_baseline.sbatch builds and runs serial/openmp.
- slurm/strong_scaling/*.sbatch runs MPI strong-scaling experiments and writes results into results/strong_scaling/{1_node,2_nodes,4_nodes}.
- slurm/weak_scaling/*.sbatch runs weak-scaling experiments and writes results into results/weak_scaling/{1_node,2_nodes,4_nodes}.
- slurm/hybrid/strong_scaling/run_hybrid_strong.sbatch runs hybrid experiments and writes results/hybrid/strong_scaling.

## Monitoring
Slurm job logs are written to logs/ by default (see SBATCH directives). Use `squeue -u $USER` to check job status and `sacct` for job accounting.

## Results interpretation
- All structured results are CSV files under results/.
- Baseline CSVs: results/baseline/output_serial.csv, results/baseline/output_openmp.csv and results/baseline/run_times_summary.csv.
- Strong scaling: results/strong_scaling/{1_node,2_nodes,4_nodes}/summary.csv
- Weak scaling: results/weak_scaling/{1_node,2_nodes,4_nodes}/summary.csv
- Hybrid strong scaling: results/hybrid/strong_scaling/summary.csv

CSV fields typically include: run, time_seconds, NX, NY, NZ, STEPS, and additional metadata (threads, ranks, checksum).