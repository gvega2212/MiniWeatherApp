#!/bin/bash
#SBATCH -J mw-profile-gpu-nsys
#SBATCH -N 1
#SBATCH --gpus-per-node=1
#SBATCH -t 00:20:00
#SBATCH -o results/profiling/gpu/profile_gpu_nsys_%j.out
#SBATCH -e results/profiling/gpu/profile_gpu_nsys_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

# Load Nsight Systems (may be included in cuda module)
module load cuda

mkdir -p results/profiling/gpu

NX=512
NY=256
NZ=256
STEPS=50  # Fewer steps for profiling to keep file size manageable

echo "Building GPU version..."
make -C src clean
make -C src miniweather_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo "Running Nsight Systems profiling..."
nsys profile \
    -o results/profiling/gpu/gpu_profile_${SLURM_JOB_ID} \
    --stats=true \
    --force-overwrite=true \
    --trace=cuda,openacc,nvtx,osrt \
    ./src/miniweather_openacc \
    > results/profiling/gpu/gpu_profile_${SLURM_JOB_ID}.log 2>&1

echo ""
echo "========================================="
echo "Profiling complete!"
echo "========================================="
echo "Profile saved to:"
echo "  results/profiling/gpu/gpu_profile_${SLURM_JOB_ID}.nsys-rep"
echo ""
echo "To view:"
echo "  1. Download the .nsys-rep file to your local machine"
echo "  2. Open with Nsight Systems GUI"
echo ""
echo "Stats summary:"
cat results/profiling/gpu/gpu_profile_${SLURM_JOB_ID}.log | grep -A 20 "CUDA API Statistics" || true