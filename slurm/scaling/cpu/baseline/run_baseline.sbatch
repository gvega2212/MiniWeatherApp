#!/bin/bash
#SBATCH -J mw-baseline
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -t 00:05:00
#SBATCH -o results/baseline/baseline_%j.out
#SBATCH -e results/baseline/baseline_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# Baseline problem size
NX=256
NY=128
NZ=128
STEPS=50

# Build all three versions with these sizes (from repo root)
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

# Make sure baseline dir exists
mkdir -p results/baseline

# Now run from src/, so ../results points to the right place
cd src

echo "Running serial baseline..."
srun --ntasks=1 ./miniweather_serial > ../results/baseline/serial_baseline.log

echo "Running OpenMP baseline..."
export OMP_NUM_THREADS=16    # or ${SLURM_CPUS_PER_TASK:-16}
srun --ntasks=1 ./miniweather_openmp > ../results/baseline/openmp_baseline.log

echo "Running MPI baseline (1 rank)..."
export OMP_NUM_THREADS=1
srun --ntasks=1 ./miniweather_mpi | tee ../results/baseline/mpi_baseline_output.txt