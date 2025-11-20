#!/bin/bash
#SBATCH -J mw-weak-hybrid-4n
#SBATCH -A def-sponsor00
#SBATCH -p node
#SBATCH -N 4
#SBATCH --ntasks-per-node=1        # total MPI ranks = 4
#SBATCH --cpus-per-task=2          # threads per rank
#SBATCH -t 00:20:00
#SBATCH --mem=2G
#SBATCH -o results/hybrid/weak_scaling/4_node/weak_hybrid_4n_%j.out
#SBATCH -e results/hybrid/weak_scaling/4_node/weak_hybrid_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source env/load_modules.sh

mkdir -p results/hybrid/weak_scaling/4_node

BASE_NX=256
NY=128
NZ=128
STEPS=50

RANKS=$SLURM_NTASKS
NX=$((BASE_NX * RANKS))

CSV="results/hybrid/weak_scaling/4_node/weak_hybrid_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,threads,NX,NY,NZ,STEPS,time" > "$CSV"

echo "Running HYBRID weak scaling on 4 nodes: RANKS=$RANKS THREADS=$SLURM_CPUS_PER_TASK NX=$NX"

make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

OUT=$(srun --mpi=pmi2 ./src/miniweather_hybrid \
       | tee results/hybrid/weak_scaling/4_node/weak_hybrid_4n_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "4,$RANKS,$SLURM_CPUS_PER_TASK,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
