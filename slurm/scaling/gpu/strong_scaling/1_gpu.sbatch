#!/bin/bash
#SBATCH -J mw-gpu-1gpu
#SBATCH -N 1
#SBATCH --gpus-per-node=1
#SBATCH -t 00:15:00
#SBATCH -o results/gpu/strong_scaling/1_gpu_%j.out
#SBATCH -e results/gpu/strong_scaling/1_gpu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

module purge
module load nvhpc/23.9

export NVHPC_ROOT=/cvmfs/restricted.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/nvhpc/23.9/Linux_x86_64/23.9
export PATH=$NVHPC_ROOT/compilers/bin:$PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:$NVHPC_ROOT/compilers/lib

mkdir -p results/gpu/strong_scaling

# Fixed problem size for strong scaling
NX=1024
NY=512
NZ=512
STEPS=200

make -C src clean
make -C src miniweather_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

OUT=$(./src/miniweather_openacc | tee results/gpu/strong_scaling/1_gpu_${SLURM_JOB_ID}.log)

TIME_VAL=$(echo "$OUT" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')

CSV="results/gpu/strong_scaling/1_gpu_${SLURM_JOB_ID}.csv"
echo "gpus,NX,NY,NZ,STEPS,time" > "$CSV"
echo "1,$NX,$NY,$NZ,$STEPS,$TIME_VAL" >> "$CSV"