#!/bin/bash
#SBATCH -J mw-weak-2n
#SBATCH -N 2
#SBATCH --ntasks-per-node=4        # total ranks = 8
#SBATCH -t 00:20:00
#SBATCH -o results/weak_scaling/2_node/weak_2n_%j.out
#SBATCH -e results/weak_scaling/2_node/weak_2n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# make sure nested dirs exist
mkdir -p results/weak_scaling/2_node

BASE_NX=256
BASE_NY=128
BASE_NZ=128
STEPS=50

CSV="results/weak_scaling/2_node/weak_2n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,NX,NY,NZ,STEPS,time" > "$CSV"

RANKS=$SLURM_NTASKS
NX=$((BASE_NX * RANKS))
NY=$BASE_NY
NZ=$BASE_NZ

echo "Running weak scaling on 2 nodes: RANKS=$RANKS NX=$NX NY=$NY NZ=$NZ"

make -C src clean
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

JOB_BIN_DIR="$SLURM_SUBMIT_DIR/.job_bins_$SLURM_JOB_ID"
trap 'rm -rf "$JOB_BIN_DIR"' EXIT
mkdir -p "$JOB_BIN_DIR"

cp src/miniweather_mpi "$JOB_BIN_DIR/"
JOB_BIN="$JOB_BIN_DIR/miniweather_mpi"

export OMP_NUM_THREADS=1

OUT=$(srun --ntasks=$SLURM_NTASKS "$JOB_BIN" \
      | tee results/weak_scaling/2_node/weak_2n_${RANKS}ranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "2,$RANKS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"