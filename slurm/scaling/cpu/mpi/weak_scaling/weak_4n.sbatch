#!/bin/bash
#SBATCH -J mw-weak-4n
#SBATCH -N 4
#SBATCH --ntasks-per-node=2        # total ranks = 8
#SBATCH -t 00:20:00
#SBATCH -o results/weak_scaling/4_node/weak_4n_%j.out
#SBATCH -e results/weak_scaling/4_node/weak_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

source ./env/load_modules.sh

# make sure nested dirs exist
mkdir -p results/weak_scaling/4_node

BASE_NX=256
BASE_NY=128
BASE_NZ=128
STEPS=50

CSV="results/weak_scaling/4_node/weak_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,NX,NY,NZ,STEPS,time" > "$CSV"

RANKS=$SLURM_NTASKS
NX=$((BASE_NX * RANKS))
NY=$BASE_NY
NZ=$BASE_NZ

echo "Running weak scaling on 4 nodes: RANKS=$RANKS NX=$NX NY=$NY NZ=$NZ"

make -C src clean
# Build the specific MPI CPU target to avoid silent misses
make -C src NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS miniweather_mpi

JOB_BIN_DIR="$SLURM_SUBMIT_DIR/.job_bins_$SLURM_JOB_ID"
trap 'rm -rf "$JOB_BIN_DIR"' EXIT
mkdir -p "$JOB_BIN_DIR"

if [[ ! -x src/miniweather_mpi ]]; then
      echo "ERROR: Expected binary src/miniweather_mpi not found after build" 1>&2
      ls -l src 1>&2 || true
      exit 1
fi

cp src/miniweather_mpi "$JOB_BIN_DIR/"
JOB_BIN="$JOB_BIN_DIR/miniweather_mpi"

export OMP_NUM_THREADS=1

OUT=$(srun --ntasks=$RANKS "$JOB_BIN" \
      | tee results/weak_scaling/4_node/weak_4n_${RANKS}ranks_${SLURM_JOB_ID}.log)

TIME_VAL=$(printf "%s\n" "$OUT" \
      | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

echo "4,$RANKS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"