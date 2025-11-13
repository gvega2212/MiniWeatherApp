#!/bin/bash
#SBATCH -J mw-baseline
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -t 00:05:00
#SBATCH -o results/baseline_%j.out
#SBATCH -e results/baseline_%j.err

set -euo pipefail
cd "$(dirname "$0")/.."

source env/load_modules.sh

# Baseline problem size (can match strong/weak scaling)
NX=256
NY=128
NZ=128
STEPS=50

# Build all three versions with these sizes
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

mkdir -p results

echo "Running serial baseline..."
srun --ntasks=1 ./src/miniweather_serial > results/serial_baseline.log

echo "Running OpenMP baseline..."
export OMP_NUM_THREADS=16          # or $SLURM_CPUS_PER_TASK if your cluster sets it
srun --ntasks=1 ./src/miniweather_openmp > results/openmp_baseline.log

echo "Running MPI baseline (1 rank)..."
export OMP_NUM_THREADS=1
srun --ntasks=1 ./src/miniweather_mpi | tee results/mpi_baseline_output.txt