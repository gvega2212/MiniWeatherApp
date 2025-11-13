#!/bin/bash
#SBATCH -J mw-strong-scaling
#SBATCH -N 1
#SBATCH --ntasks-per-node=4       # assume 16 cores/node; adjust to your machine
#SBATCH -t 00:15:00
#SBATCH -o results/strong_scaling_%j.out
#SBATCH -e results/strong_scaling_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# Fixed grid for strong scaling
NX=512
NY=256
NZ=256
STEPS=50

# Build once with this problem size
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

mkdir -p results
echo "ranks,time_seconds" > results/strong_scaling.csv

# List of MPI ranks to test (must not exceed ntasks-per-node * N)
for RANKS in 1 2 4; do
  echo "Running strong scaling with $RANKS ranks..."
  export OMP_NUM_THREADS=1

  # Run and capture output, including TIME=... line from miniweather_mpi
  OUT=$(srun --mpi=pmix --ntasks=$RANKS ./src/miniweather_mpi | tee results/strong_${RANKS}ranks_${SLURM_JOB_ID}.log)

  # Extract time from the GLOBAL_SUM line: ... TIME=0.010299 s
  TIME_VAL=$(printf "%s\n" "$OUT" | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

  echo "$RANKS,$TIME_VAL" >> results/strong_scaling.csv
done