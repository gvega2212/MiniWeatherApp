#!/bin/bash
#SBATCH -J mw-gpu-weak-4gpu
#SBATCH -N 1
#SBATCH --gpus-per-node=4
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/gpu/weak_scaling/4_gpu_%j.out
#SBATCH -e results/gpu/weak_scaling/4_gpu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/gpu/weak_scaling

# Base problem size per GPU
BASE_NX=512
NY=256
NZ=256
STEPS=200

# 4 GPUs: problem size = BASE_NX * 4
GPUS=4
NX=$((BASE_NX * GPUS))

echo "Running GPU weak scaling with $GPUS GPUs: NX=$NX"

make -C src clean
make -C src miniweather_mpi_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

OUT=$(srun --gpus-per-task=1 ./src/miniweather_mpi_openacc \
      | tee results/gpu/weak_scaling/4_gpu_${SLURM_JOB_ID}.log)

TIME_VAL=$(echo "$OUT" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')

CSV="results/gpu/weak_scaling/4_gpu_${SLURM_JOB_ID}.csv"
echo "gpus,NX,NY,NZ,STEPS,time" > "$CSV"
echo "$GPUS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"

echo "Done. Time: $TIME_VAL seconds"