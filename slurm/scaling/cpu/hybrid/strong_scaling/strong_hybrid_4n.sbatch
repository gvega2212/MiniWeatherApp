#!/bin/bash
#SBATCH -J mw-hybrid-4n
#SBATCH -p node
#SBATCH -N 4
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
export OMP_NUM_THREADS = 1
#SBATCH -t 00:20:00
#SBATCH --mem=4G
#SBATCH -o results/hybrid/strong_scaling/4_node/hybrid_4n_%j.out
#SBATCH -e results/hybrid/strong_scaling/4_node/hybrid_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/hybrid/strong_scaling/4_node

NX=256
NY=128
NZ=128
STEPS=50

make -C src clean
make -C src miniweather_hybrid NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

JOB_BIN_DIR="$SLURM_SUBMIT_DIR/.job_bins_$SLURM_JOB_ID"
trap 'rm -rf "$JOB_BIN_DIR"' EXIT
mkdir -p "$JOB_BIN_DIR"

cp src/miniweather_hybrid "$JOB_BIN_DIR/"
JOB_BIN="$JOB_BIN_DIR/miniweather_hybrid"

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

OUT=$(srun "$JOB_BIN" \
      | tee results/hybrid/strong_scaling/4_node/hybrid_4n_allranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(echo "$OUT" | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

CSV="results/hybrid/strong_scaling/4_node/hybrid_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,NX,NY,NZ,STEPS,time" > "$CSV"
echo "4,8,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
