#!/bin/bash
#SBATCH -J mw-profile-hybrid
#SBATCH -N 1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=8
#SBATCH -t 00:20:00
#SBATCH -o results/profiling/cpu/profile_hybrid_%j.out
#SBATCH -e results/profiling/cpu/profile_hybrid_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu

NX=512
NY=256
NZ=256
STEPS=100

echo "Building Hybrid (MPI+OpenMP) version..."
make -C src clean
make -C src miniweather_hybrid NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=8

echo "Running perf profiling on Hybrid version (2 ranks × 8 threads)..."

# Profile rank 0 only
srun --ntasks=2 --cpus-per-task=8 bash -c '
if [ $SLURM_PROCID -eq 0 ]; then
    perf record -g -o results/profiling/cpu/perf_hybrid_rank0_'${SLURM_JOB_ID}'.data ./src/miniweather_hybrid
else
    ./src/miniweather_hybrid
fi
'

# Generate report
perf report -i results/profiling/cpu/perf_hybrid_rank0_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/perf_hybrid_report_${SLURM_JOB_ID}.txt

echo "=== Top 20 Functions by CPU Time (Rank 0) ==="
perf report -i results/profiling/cpu/perf_hybrid_rank0_${SLURM_JOB_ID}.data --stdio | head -40

echo ""
echo "Full profiling report saved to:"
echo "  results/profiling/cpu/perf_hybrid_report_${SLURM_JOB_ID}.txt"