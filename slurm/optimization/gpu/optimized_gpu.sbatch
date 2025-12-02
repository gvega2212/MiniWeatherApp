#!/bin/bash
#SBATCH -J mw-optimized-gpu
#SBATCH -p gpu-node
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
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
echo "  GPU OPTIMIZATION COMPARISON"
echo "========================================="
echo ""
echo "Configuration: 1 node, 1 GPU, 1 MPI rank"
echo "Total GPUs: 1"
echo "Problem size: ${NX}x${NY}x${NZ}, Steps: ${STEPS}"
echo ""
echo "Optimization applied:"
echo "  1. Added OpenACC async clauses to overlap GPU-CPU transfers"
echo "  2. Used async(1) and async(2) queues for left/right halo exchanges"
echo "  3. Added gang/vector_length(128) clauses for better GPU utilization"
echo "  4. Allows GPU transfers to pipeline with MPI communication"
echo ""

# Build both versions
echo "=== Building baseline and optimized versions ==="
make -C src clean
make -C src miniweather_mpi_openacc miniweather_mpi_openacc_optimized NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo ""
echo "========================================="
echo "  Running BASELINE (no optimization)"
echo "========================================="
OUT_BASELINE=$(srun --gpus-per-task=1 ./src/miniweather_mpi_openacc 2>&1 \
      | tee results/optimization/gpu/baseline_gpu_${SLURM_JOB_ID}.log)

echo "$OUT_BASELINE"
echo ""

# Parse baseline metrics
TIME_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')
COMM_TIME_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'COMM_TIME=' '{print $2}' | awk '{print $1}')
COMP_TIME_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'COMP_TIME=' '{print $2}' | awk '{print $1}')
THROUGHPUT_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'THROUGHPUT_CELLS=' '{print $2}' | awk '{print $1}')

echo "Baseline results:"
echo "  Total time:        $TIME_BASELINE seconds"
echo "  Communication time: $COMM_TIME_BASELINE seconds"
echo "  Computation time:   $COMP_TIME_BASELINE seconds"
echo "  Throughput:         $THROUGHPUT_BASELINE cells/s"
echo ""

echo "========================================="
echo "  Running OPTIMIZED (async + tuning)"
echo "========================================="
OUT_OPTIMIZED=$(srun --gpus-per-task=1 ./src/miniweather_mpi_openacc_optimized 2>&1 \
      | tee results/optimization/gpu/optimized_gpu_${SLURM_JOB_ID}.log)

echo "$OUT_OPTIMIZED"
echo ""

# Parse optimized metrics
TIME_OPTIMIZED=$(echo "$OUT_OPTIMIZED" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')
COMM_TIME_OPTIMIZED=$(echo "$OUT_OPTIMIZED" | grep "METRICS:" | awk -F'COMM_TIME=' '{print $2}' | awk '{print $1}')
COMP_TIME_OPTIMIZED=$(echo "$OUT_OPTIMIZED" | grep "METRICS:" | awk -F'COMP_TIME=' '{print $2}' | awk '{print $1}')
THROUGHPUT_OPTIMIZED=$(echo "$OUT_OPTIMIZED" | grep "METRICS:" | awk -F'THROUGHPUT_CELLS=' '{print $2}' | awk '{print $1}')

echo "Optimized results:"
echo "  Total time:         $TIME_OPTIMIZED seconds"
echo "  Communication time:  $COMM_TIME_OPTIMIZED seconds"
echo "  Computation time:    $COMP_TIME_OPTIMIZED seconds"
echo "  Throughput:          $THROUGHPUT_OPTIMIZED cells/s"
echo ""

# Calculate speedup
SPEEDUP=$(echo "scale=4; $TIME_BASELINE / $TIME_OPTIMIZED" | bc)
COMM_SPEEDUP=$(echo "scale=4; $COMM_TIME_BASELINE / $COMM_TIME_OPTIMIZED" | bc)
COMP_SPEEDUP=$(echo "scale=4; $COMP_TIME_BASELINE / $COMP_TIME_OPTIMIZED" | bc)
IMPROVEMENT=$(echo "scale=2; ($SPEEDUP - 1.0) * 100" | bc)

echo "========================================="
echo "  PERFORMANCE COMPARISON"
echo "========================================="
echo "Overall speedup:        ${SPEEDUP}x (${IMPROVEMENT}% improvement)"
echo "Communication speedup:  ${COMM_SPEEDUP}x"
echo "Computation speedup:    ${COMP_SPEEDUP}x"
echo ""

# Save results to CSV
CSV="results/optimization/gpu/optimization_summary_${SLURM_JOB_ID}.csv"
echo "version,nodes,gpus,time,comm_time,comp_time,throughput,speedup,improvement_pct" > "$CSV"
echo "baseline,1,1,$TIME_BASELINE,$COMM_TIME_BASELINE,$COMP_TIME_BASELINE,$THROUGHPUT_BASELINE,1.0,0.0" >> "$CSV"
echo "optimized,1,1,$TIME_OPTIMIZED,$COMM_TIME_OPTIMIZED,$COMP_TIME_OPTIMIZED,$THROUGHPUT_OPTIMIZED,$SPEEDUP,$IMPROVEMENT" >> "$CSV"

echo "Results saved to: $CSV"
echo ""
echo "========================================="
echo "  SUMMARY"
echo "========================================="
cat "$CSV"
echo ""
echo "Optimization techniques applied:"
echo "  • OpenACC async clauses for overlapping GPU-CPU transfers"
echo "  • Separate async queues (1 & 2) for concurrent halo transfers"
echo "  • gang/vector_length(128) tuning for GPU kernel optimization"
echo "  • Reduced synchronization points between GPU operations"
echo ""