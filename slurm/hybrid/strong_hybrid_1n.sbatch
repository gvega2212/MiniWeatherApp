#!/bin/bash
#SBATCH -J mw-strong-4n
#SBATCH -A def-sponsor0
#SBATCH -N 4
#SBATCH --ntasks-per-node=2       # total MPI ranks = 8
#SBATCH --cpus-per-task=4         # OpenMP threads per rank
#SBATCH -t 00:20:00
#SBATCH --mem=4G
#SBATCH -o results/hybrid/strong_scaling/strong_hybrid_4n_%j.out
#SBATCH -e results/hybrid/strong_scaling/strong_hybrid_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

# Load compiler + MPI modules
source env/load_modules.sh

# Check queue every 2s (Optional: remove if not needed)
# watch -n 2 squeue -j "$SLURM_JOB_ID"

# Output directory
mkdir -p results/hybrid/strong_scaling

# Strong scaling: fix global grid
NX=256
NY=128
NZ=128
STEPS=50

echo "Compiling hybrid strong scaling case for 4 nodes, 8 ranks, OMP=$SLURM_CPUS_PER_TASK"

make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

OUT=$(srun --mpi=pmix ./src/miniweather_hybrid \
       | tee results/hybrid/strong_scaling/strong_4n_allranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

CSV="results/hybrid/strong_scaling/strong_hybrid_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,NX,NY,NZ,STEPS,time" > "$CSV"
echo "4,8,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
