#!/bin/bash
#SBATCH -J mw-weak-hybrid-4n
#SBATCH -N 4                     # 4 nodes
#SBATCH --ntasks-per-node=1      # 1 MPI rank per node → 4 ranks total
#SBATCH --cpus-per-task=2        # 2 OpenMP threads per rank
#SBATCH -t 00:20:00
#SBATCH --mem=2000M
#SBATCH -o results/hybrid/weak_scaling/4_node/weak_hybrid_4n_%j.out
#SBATCH -e results/hybrid/weak_scaling/4_node/weak_hybrid_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

# Minimal env setup (your cluster basically doesn't need modules, but keep for symmetry)
source env/load_modules.sh

# Make sure output dir exists
mkdir -p results/hybrid/weak_scaling/4_node

CSV="results/hybrid/weak_scaling/4_node/weak_hybrid_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,threads,NX,NY,NZ,STEPS,time_seconds" > "$CSV"

# --- Weak scaling parameters ---
BASE_NX=256
BASE_NY=128
BASE_NZ=128
STEPS=50

# Total MPI ranks (should be 4 = 4 nodes × 1 rank/node)
RANKS=$SLURM_NTASKS

# Weak scaling: increase NX with total ranks, keep NY, NZ fixed
NX=$((BASE_NX * RANKS))
NY=$BASE_NY
NZ=$BASE_NZ

echo "Hybrid WEAK scaling 4 nodes:"
echo "  NODES=$SLURM_NNODES"
echo "  RANKS=$RANKS, THREADS_PER_RANK=$SLURM_CPUS_PER_TASK"
echo "  NX=$NX, NY=$NY, NZ=$NZ, STEPS=$STEPS"

# Rebuild with these problem sizes
make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

# Hybrid: MPI + OpenMP
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

OUT=$(srun --mpi=pmix ./src/miniweather_hybrid \
       | tee results/hybrid/weak_scaling/4_node/weak_hybrid_4n_${RANKS}ranks_${SLURM_JOB_ID}.log)

# Extract TIME=... from rank 0 output
TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "$SLURM_NNODES,$RANKS,$SLURM_CPUS_PER_TASK,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
