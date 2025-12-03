#!/bin/bash
#SBATCH -J mw-profile-multigpu
#SBATCH -N 1
#SBATCH --gpus-per-node=4
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/profiling/gpu/profile_multigpu_%j.out
#SBATCH -e results/profiling/gpu/profile_multigpu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

module purge
module load nvhpc/23.9

export NVHPC_ROOT=/cvmfs/restricted.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/nvhpc/23.9/Linux_x86_64/23.9
export PATH=$NVHPC_ROOT/compilers/bin:$PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}:$NVHPC_ROOT/compilers/lib

module load cuda

mkdir -p results/profiling/gpu

NX=1024
NY=512
NZ=512
STEPS=50

echo "Building multi-GPU version..."
make -C src clean
make -C src miniweather_mpi_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo "Running Nsight Systems profiling on multi-GPU (4 GPUs)..."

# Profile only rank 0 to keep file size manageable
srun --ntasks=4 --gpus-per-task=1 bash -c '
if [ $SLURM_PROCID -eq 0 ]; then
    nsys profile \
        -o results/profiling/gpu/multigpu_profile_rank0_'${SLURM_JOB_ID}' \
        --stats=true \
        --force-overwrite=true \
        --trace=cuda,openacc,mpi,nvtx \
        ./src/miniweather_mpi_openacc
else
    ./src/miniweather_mpi_openacc
fi
' > results/profiling/gpu/multigpu_profile_${SLURM_JOB_ID}.log 2>&1

echo ""
echo "========================================="
echo "Multi-GPU profiling complete!"
echo "========================================="
echo "Profile saved to:"
echo "  results/profiling/gpu/multigpu_profile_rank0_${SLURM_JOB_ID}.nsys-rep"
echo ""
echo "This shows GPU-GPU communication, MPI overhead, and kernel execution"