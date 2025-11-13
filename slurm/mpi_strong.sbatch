#!/bin/bash
#SBATCH -J mw-strong
#SBATCH -N 1                      # change to 1,2,4,8 for your sweep
#SBATCH --ntasks-per-node=16      # match cores per node on your cluster
#SBATCH -t 00:15:00
#SBATCH -o ../results/strong_%j.out

set -euo pipefail
cd "$(dirname "$0")/.."

source env/load_modules.sh

# Fixed grid for strong scaling
NX=512 NY=256 NZ=256 STEPS=50

# Pure MPI first (set to 1); switch to hybrid later
export OMP_NUM_THREADS=1

# Build with chosen sizes
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

# Run and capture log
srun --mpi=pmix --cpu-bind=cores ./src/miniweather_mpi | tee results/strong_${SLURM_JOB_ID}.log
