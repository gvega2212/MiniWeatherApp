#!/bin/bash
#SBATCH -J mw-optimized-mpi
#SBATCH -N 4
#SBATCH --ntasks-per-node=4
#SBATCH -t 00:20:00
#SBATCH -o results/optimization/cpu/optimized_mpi_%j.out
#SBATCH -e results/optimization/cpu/optimized_mpi_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/optimization/cpu

NX=1024
NY=512
NZ=512
STEPS=200

echo "========================================="
echo "  OPTIMIZATION: MPI Version"
echo "========================================="
echo ""
echo "Optimization applied: [DESCRIBE YOUR OPTIMIZATION HERE]"
echo "Examples:"
echo "  - Non-blocking MPI (MPI_Isend/Irecv instead of MPI_Sendrecv)"
echo "  - Overlapping computation with communication"
echo "  - Better domain decomposition"
echo "  - Cache blocking in stencil computation"
echo ""

# Build optimized version
make -C src clean
make -C src miniweather_mpi NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=1

# Run BASELINE (for comparison)
echo "=== Running BASELINE (before optimization) ==="
OUT_BASELINE=$(srun --ntasks=16 ./src/miniweather_mpi \
      | tee results/optimization/cpu/baseline_mpi_${SLURM_JOB_ID}.log)

TIME_BASELINE=$(echo "$OUT_BASELINE" | grep "METRICS:" | awk -F'TIME=' '{print $2}' | awk '{print $1}')

echo "Baseline time: $TIME_BASELINE seconds"
echo ""

# TODO: Build and run OPTIMIZED version
# For now, this is a placeholder - you'll implement the optimization later
echo "=== Running OPTIMIZED version ==="
echo "NOTE: Implement your optimization in src/miniweather_mpi_optimized.c"
echo "      Then compile and run here"
echo ""

# Calculate speedup (when you have optimized version)
# TIME_OPTIMIZED=$(...)
# SPEEDUP=$(echo "scale=2; $TIME_BASELINE / $TIME_OPTIMIZED" | bc)
# echo "Speedup: ${SPEEDUP}x"

CSV="results/optimization/cpu/optimization_summary_${SLURM_JOB_ID}.csv"
echo "version,time,speedup" > "$CSV"
echo "baseline,$TIME_BASELINE,1.0" >> "$CSV"
# echo "optimized,$TIME_OPTIMIZED,$SPEEDUP" >> "$CSV"

echo ""
echo "Results saved to: $CSV"