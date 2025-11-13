#!/bin/bash
#SBATCH -J mw-strong-4n
#SBATCH -N 4
#SBATCH --ntasks-per-node=4         # total ranks = 16
#SBATCH -t 00:20:00
#SBATCH -o results/strong_4n_%j.out
#SBATCH -e results/strong_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

NX=512
NY=256
NZ=256
STEPS=50

mkdir -p results

make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

CSV="results/strong_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,time" > "$CSV"

export OMP_NUM_THREADS=1

echo "Running strong scaling on 4 nodes with $SLURM_NTASKS ranks..."
OUT=$(srun --mpi=pmix ./src/miniweather_mpi \
      | tee results/strong_4n_allranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "4,$SLURM_NTASKS,$TIME_VAL" >> "$CSV"