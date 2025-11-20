#!/bin/bash
#SBATCH -J mw-hybrid-1n
#SBATCH -N 1
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=2
#SBATCH -t 00:10:00
#SBATCH --mem=4G
#SBATCH -o results/hybrid/strong_scaling/1_node/hybrid_1n_%j.out
#SBATCH -e results/hybrid/strong_scaling/1_node/hybrid_1n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/hybrid/strong_scaling/1_node

NX=256
NY=128
NZ=128
STEPS=50

make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

OUT=$(srun ./src/miniweather_mpi \
      | tee results/hybrid/strong_scaling/1_node/hybrid_1n_allranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(echo "$OUT" | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

CSV="results/hybrid/strong_scaling/1_node/hybrid_1n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,NX,NY,NZ,STEPS,time" > "$CSV"
echo "1,2,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"

