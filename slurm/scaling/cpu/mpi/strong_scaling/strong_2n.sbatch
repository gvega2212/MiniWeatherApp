#!/bin/bash
#SBATCH -J mw-strong-2n
#SBATCH -N 2
#SBATCH --ntasks-per-node=4         # total ranks = 8
#SBATCH -t 00:15:00
#SBATCH -o results/strong_scaling/2_node/strong_2n_%j.out
#SBATCH -e results/strong_scaling/2_node/strong_2n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# Fixed grid for strong scaling (same as 1n)
NX=512
NY=256
NZ=256
STEPS=50

# make sure nested dirs exist
mkdir -p results/strong_scaling/2_nodes


# Build once
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

CSV="results/strong_scaling/2_nodes/strong_2n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,time" > "$CSV"

export OMP_NUM_THREADS=1

echo "Running strong scaling on 2 nodes with $SLURM_NTASKS ranks..."
OUT=$(srun --ntasks=$SLURM_NTASKS ./src/miniweather_mpi \
      | tee results/strong_scaling/2_node/strong_2n_${SLURM_NTASKS}ranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "2,$SLURM_NTASKS,$TIME_VAL" >> "$CSV"