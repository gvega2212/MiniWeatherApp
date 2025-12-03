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

JOB_BIN_DIR="$SLURM_SUBMIT_DIR/.job_bins_$SLURM_JOB_ID"
trap 'rm -rf "$JOB_BIN_DIR"' EXIT
mkdir -p "$JOB_BIN_DIR"

cp src/miniweather_serial "$JOB_BIN_DIR/"
cp src/miniweather_openmp "$JOB_BIN_DIR/"
cp src/miniweather_mpi "$JOB_BIN_DIR/"

SERIAL_BIN="$JOB_BIN_DIR/miniweather_serial"
OPENMP_BIN="$JOB_BIN_DIR/miniweather_openmp"
MPI_BIN="$JOB_BIN_DIR/miniweather_mpi"

# Make sure baseline dir exists
mkdir -p results/baseline

echo "Running serial baseline..."
srun --ntasks=1 "$SERIAL_BIN" > results/baseline/serial_baseline.log

echo "Running OpenMP baseline..."
export OMP_NUM_THREADS=16    # or ${SLURM_CPUS_PER_TASK:-16}
srun --ntasks=1 "$OPENMP_BIN" > results/baseline/openmp_baseline.log

echo "Running MPI baseline (1 rank)..."
export OMP_NUM_THREADS=1
srun --ntasks=1 "$MPI_BIN" | tee results/baseline/mpi_baseline_output.txt