#!/bin/bash
#SBATCH -J mw-weak-hybrid-2n
#SBATCH -N 2
#SBATCH --ntasks-per-node=2          # total ranks = 4
#SBATCH --cpus-per-task=2            # 4 OpenMP threads per rank
#SBATCH -t 00:20:00
#SBATCH --mem=4G
#SBATCH -o results/hybrid/weak_scaling/2_node/weak_hybrid_2n_%j.out
#SBATCH -e results/hybrid/weak_scaling/2_node/weak_hybrid_2n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source env/load_modules.sh

mkdir -p results/hybrid/weak_scaling/2_node

CSV="results/hybrid/weak_scaling/2_node/weak_hybrid_2n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,threads,NX,NY,NZ,STEPS,time_seconds" > "$CSV"

BASE_NX=256
BASE_NY=128
BASE_NZ=128
STEPS=50

RANKS=$SLURM_NTASKS
NX=$((BASE_NX * RANKS))
NY=$BASE_NY
NZ=$BASE_NZ

echo "Hybrid WEAK scaling 2 nodes:"
echo "  RANKS=$RANKS, THREADS_PER_RANK=$SLURM_CPUS_PER_TASK"
echo "  NX=$NX, NY=$NY, NZ=$NZ, STEPS=$STEPS"

make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

OUT=$(srun --mpi=pmix ./src/miniweather_hybrid \
       | tee results/hybrid/weak_scaling/2_node/weak_hybrid_2n_${RANKS}ranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "2,$RANKS,$SLURM_CPUS_PER_TASK,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
