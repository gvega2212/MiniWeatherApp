#!/bin/bash
#SBATCH -J mw-profile-gpu-ncu
#SBATCH -N 1
#SBATCH --gpus-per-node=1
#SBATCH -t 00:30:00
#SBATCH -o results/profiling/gpu/profile_gpu_ncu_%j.out
#SBATCH -e results/profiling/gpu/profile_gpu_ncu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

# Load Nsight Compute (may be included in cuda module)
module load cuda

mkdir -p results/profiling/gpu

NX=256
NY=128
NZ=128
STEPS=5  # VERY few steps - Nsight Compute is VERY slow

echo "Building GPU version..."
make -C src clean
make -C src miniweather_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo "Running Nsight Compute kernel profiling..."
echo "WARNING: This will be SLOW (5-10 minutes)"

ncu \
    --set full \
    --target-processes all \
    --export results/profiling/gpu/kernel_analysis_${SLURM_JOB_ID} \
    --force-overwrite \
    ./src/miniweather_openacc \
    > results/profiling/gpu/kernel_analysis_${SLURM_JOB_ID}.log 2>&1

echo ""
echo "========================================="
echo "Kernel profiling complete!"
echo "========================================="
echo "Profile saved to:"
echo "  results/profiling/gpu/kernel_analysis_${SLURM_JOB_ID}.ncu-rep"
echo ""
echo "To view:"
echo "  1. Download the .ncu-rep file to your local machine"
echo "  2. Open with Nsight Compute GUI"
echo ""
echo "Key metrics:"
grep -E "(Compute|Memory|Occupancy)" results/profiling/gpu/kernel_analysis_${SLURM_JOB_ID}.log | head -20 || true