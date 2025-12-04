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
NODES=4
RANK_SET=(4 8)

CSV="results/weak_scaling/4_node/weak_4n_${SLURM_JOB_ID}.csv"
echo "nodes,ranks,NX,NY,NZ,STEPS,time" > "$CSV"

JOB_BIN_DIR="$SLURM_SUBMIT_DIR/.job_bins_$SLURM_JOB_ID"
trap 'rm -rf "$JOB_BIN_DIR"' EXIT
mkdir -p "$JOB_BIN_DIR"

BUILD_LOCK="$SLURM_SUBMIT_DIR/src/.build.lock"

build_and_stage() {
  local nx="$1"
  local dest="$2"
  (
    flock 9
    make -C src clean
    make -C src miniweather_mpi NX=$nx NY=$BASE_NY NZ=$BASE_NZ STEPS=$STEPS
    cp src/miniweather_mpi "$dest"
  ) 9>"$BUILD_LOCK"
}

for RANKS in "${RANK_SET[@]}"; do
  NX=$((BASE_NX * RANKS))
  NY=$BASE_NY
  NZ=$BASE_NZ
  BIN="$JOB_BIN_DIR/miniweather_mpi_${RANKS}r"

  echo "Running weak scaling on 4 nodes: RANKS=$RANKS NX=$NX"
  build_and_stage "$NX" "$BIN"

  TPN=$((RANKS / NODES))
  OUT=$(srun --ntasks=$RANKS --ntasks-per-node=$TPN "$BIN" \
        | tee results/weak_scaling/4_node/weak_4n_${RANKS}ranks_${SLURM_JOB_ID}.log)

  TIME_VAL=$(printf "%s\n" "$OUT" \
        | awk -F'TIME=' '/TIME=/{print $2}' | awk '{print $1}')

  echo "$NODES,$RANKS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"
done