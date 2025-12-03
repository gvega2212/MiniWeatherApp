#!/bin/bash
#SBATCH -J mw-gpu-weak-2gpu
#SBATCH -N 2
#SBATCH --gpus-per-node=1
#SBATCH --ntasks-per-node=1
#SBATCH -t 00:20:00
#SBATCH -o results/gpu/weak_scaling/2_gpu_%j.out
#SBATCH -e results/gpu/weak_scaling/2_gpu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

module purge
module load nvhpc/23.9

export NVHPC_ROOT=/cvmfs/restricted.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/nvhpc/23.9/Linux_x86_64/23.9
export PATH=$NVHPC_ROOT/compilers/bin:$PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:$NVHPC_ROOT/compilers/lib

mkdir -p results/gpu/weak_scaling

# Base problem size per GPU
BASE_NX=512
NY=256
NZ=256
STEPS=200

# 2 GPUs: problem size = BASE_NX * 2
GPUS=2
NX=$((BASE_NX * GPUS))

echo "Running GPU weak scaling with $GPUS GPUs: NX=$NX"

make -C src clean
make -C src miniweather_mpi_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

OUT=$(srun --ntasks=$GPUS --ntasks-per-node=1 --gpus-per-task=1 ./src/miniweather_mpi_openacc \
      | tee results/gpu/weak_scaling/2_gpu_${SLURM_JOB_ID}.log)

TIME_VAL=$(echo "$OUT" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')

CSV="results/gpu/weak_scaling/2_gpu_${SLURM_JOB_ID}.csv"
echo "gpus,NX,NY,NZ,STEPS,time" > "$CSV"
echo "$GPUS,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"

echo "Done. Time: $TIME_VAL seconds"