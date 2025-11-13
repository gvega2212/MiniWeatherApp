#!/bin/bash
#SBATCH -J mw-strong-scaling
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:15:00
#SBATCH -o results/strong_1n_%j.out
#SBATCH -e results/strong_1n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# Fixed grid for strong scaling
NX=512
NY=256
NZ=256
STEPS=50

mkdir -p results

# Build once with this problem size
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

CSV="results/strong_1n_${SLURM_JOB_ID}.csv"
echo "ranks,time" > "$CSV"

for RANKS in 1 2 4; do
  echo "Running strong scaling with $RANKS ranks..."
  export OMP_NUM_THREADS=1

  OUT=$(srun --ntasks=$RANKS ./src/miniweather_mpi \
        | tee results/strong_1n_${RANKS}ranks_${SLURM_JOB_ID}.log)

  TIME_VAL=$(printf "%s\n" "$OUT" \
        | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

  echo "$RANKS,$TIME_VAL" >> "$CSV"
done