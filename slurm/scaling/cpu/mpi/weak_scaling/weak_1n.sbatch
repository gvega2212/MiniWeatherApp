#!/bin/bash
#SBATCH -J mw-weak-scaling
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/weak_scaling/1_node/weak_1n_%j.out
#SBATCH -e results/weak_scaling/1_node/weak_1n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# make sure nested dirs exist
mkdir -p results/weak_scaling/1_node

CSV="results/weak_scaling/1_node/weak_1n_${SLURM_JOB_ID}.csv"
echo "ranks,NX,NY,NZ,STEPS,time_seconds" > "$CSV"

BASE_NX=256
BASE_NY=128
BASE_NZ=128
STEPS=50

JOB_BIN_DIR="$SLURM_SUBMIT_DIR/.job_bins_$SLURM_JOB_ID"
trap 'rm -rf "$JOB_BIN_DIR"' EXIT
mkdir -p "$JOB_BIN_DIR"
JOB_BIN="$JOB_BIN_DIR/miniweather_mpi"

for RANKS in 1 2 4; do
  NX=$((BASE_NX * RANKS))
  NY=$BASE_NY
  NZ=$BASE_NZ

  echo "Building for weak scaling: RANKS=$RANKS NX=$NX NY=$NY NZ=$NZ"

  make -C src clean
  make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

      cp src/miniweather_mpi "$JOB_BIN"

  export OMP_NUM_THREADS=1
      OUT=$(srun --ntasks=$RANKS "$JOB_BIN" \
        | tee results/weak_scaling/1_node/weak_1n_${RANKS}ranks_${SLURM_JOB_ID}.log)

  TIME_VAL=$(printf "%s\n" "$OUT" \
        | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

  echo "$RANKS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
done