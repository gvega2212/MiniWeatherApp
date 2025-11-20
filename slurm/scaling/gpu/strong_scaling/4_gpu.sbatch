#!/bin/bash
#SBATCH -J mw-gpu-4gpu
#SBATCH -N 1
#SBATCH --gpus-per-node=4
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/gpu/strong_scaling/4_gpu_%j.out
#SBATCH -e results/gpu/strong_scaling/4_gpu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/gpu/strong_scaling

# SAME problem size as 1 GPU (strong scaling)
NX=1024
NY=512
NZ=512
STEPS=200

make -C src clean
make -C src miniweather_mpi_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo "Running 4 GPU strong scaling..."
OUT=$(srun --gpus-per-task=1 ./src/miniweather_mpi_openacc \
      | tee results/gpu/strong_scaling/4_gpu_${SLURM_JOB_ID}.log)

TIME_VAL=$(echo "$OUT" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')

CSV="results/gpu/strong_scaling/4_gpu_${SLURM_JOB_ID}.csv"
echo "gpus,NX,NY,NZ,STEPS,time" > "$CSV"
echo "4,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"

echo "Done. Time: $TIME_VAL seconds"