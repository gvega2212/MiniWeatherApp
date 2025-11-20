#!/bin/bash
#SBATCH -J mw-gpu-baseline
#SBATCH -N 1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH -t 00:15:00
#SBATCH -o results/gpu/baseline/gpu_baseline_%j.out
#SBATCH -e results/gpu/baseline/gpu_baseline_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/gpu/baseline

NX=512
NY=256
NZ=256
STEPS=100

make -C src clean
make -C src miniweather_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo "Running single GPU baseline..."
./src/miniweather_openacc | tee results/gpu/baseline/gpu_baseline.log