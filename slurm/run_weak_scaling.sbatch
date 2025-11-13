#!/bin/bash
#SBATCH -J mw-weak-scaling
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/weak_scaling_%j.out
#SBATCH -e results/weak_scaling_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

mkdir -p results
echo "ranks,NX,NY,NZ,STEPS,time_seconds" > results/weak_scaling.csv

# Base problem per rank
BASE_NX=256
BASE_NY=128
BASE_NZ=128
STEPS=50

for RANKS in 1 2 4; do
  # Scale NX with RANKS to keep ~constant work per rank
  NX=$((BASE_NX * RANKS))
  NY=$BASE_NY
  NZ=$BASE_NZ

  echo "Building for weak scaling: RANKS=$RANKS NX=$NX NY=$NY NZ=$NZ"

  make -C src clean
  make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

  export OMP_NUM_THREADS=1
  OUT=$(srun --mpi=pmix --ntasks=$RANKS ./src/miniweather_mpi | tee results/weak_${RANKS}ranks_${SLURM_JOB_ID}.log)

  TIME_VAL=$(printf "%s\n" "$OUT" | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

  echo "$RANKS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> results/weak_scaling.csv
done