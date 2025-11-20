#!/bin/bash
#SBATCH -J mw-optimized-gpu
#SBATCH -N 1
#SBATCH --gpus-per-node=4
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/optimization/gpu/optimized_gpu_%j.out
#SBATCH -e results/optimization/gpu/optimized_gpu_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/optimization/gpu

NX=2048
NY=1024
NZ=1024
STEPS=200

echo "========================================="
echo "  OPTIMIZATION: GPU Version"
echo "========================================="
echo ""
echo "Optimization applied: [DESCRIBE YOUR OPTIMIZATION HERE]"
echo "Examples:"
echo "  - GPU-aware MPI (direct GPU-GPU communication)"
echo "  - Asynchronous GPU kernels with streams"
echo "  - Optimized block sizes for stencil kernels"
echo "  - Minimizing CPU-GPU transfers"
echo "  - Loop tiling/blocking for better cache usage"
echo ""

# Build current version
make -C src clean
make -C src miniweather_mpi_openacc NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

# Run BASELINE (for comparison)
echo "=== Running BASELINE (before optimization) ==="
OUT_BASELINE=$(srun --gpus-per-task=1 ./src/miniweather_mpi_openacc \
      | tee results/optimization/gpu/baseline_gpu_${SLURM_JOB_ID}.log)

TIME_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')
COMM_TIME_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'COMM_TIME=' '{print $2}' | awk '{print $1}')

echo "Baseline time: $TIME_BASELINE seconds"
echo "Baseline comm time: $COMM_TIME_BASELINE seconds"
echo ""

# TODO: Build and run OPTIMIZED version
echo "=== Running OPTIMIZED version ==="
echo "NOTE: Implement your optimization in src/miniweather_mpi_openacc_optimized.c"
echo "      Or modify compiler flags / OpenACC directives"
echo ""

# Example optimization ideas to implement:
echo "Optimization ideas to try:"
echo "  1. Add 'async' clauses to OpenACC directives"
echo "  2. Use GPU-aware MPI (if available)"
echo "  3. Tune OpenACC gang/vector/worker clauses"
echo "  4. Overlap communication with computation"
echo ""

CSV="results/optimization/gpu/optimization_summary_${SLURM_JOB_ID}.csv"
echo "version,time,comm_time,speedup" > "$CSV"
echo "baseline,$TIME_BASELINE,$COMM_TIME_BASELINE,1.0" >> "$CSV"

echo ""
echo "Results saved to: $CSV"