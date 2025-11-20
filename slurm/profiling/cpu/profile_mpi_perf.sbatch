#!/bin/bash
#SBATCH -J mw-profile-mpi
#SBATCH -N 1
#SBATCH --ntasks=4
#SBATCH -t 00:20:00
#SBATCH -o results/profiling/cpu/profile_mpi_%j.out
#SBATCH -e results/profiling/cpu/profile_mpi_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu

NX=512
NY=256
NZ=256
STEPS=100

echo "Building MPI version..."
make -C src clean
make -C src miniweather_mpi NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=1

echo "Running perf profiling on MPI version (4 ranks)..."

# Profile rank 0 only (you can't easily profile all ranks with perf)
srun --ntasks=4 bash -c '
if [ $SLURM_PROCID -eq 0 ]; then
    perf record -g -o results/profiling/cpu/perf_mpi_rank0_'${SLURM_JOB_ID}'.data ./src/miniweather_mpi
else
    ./src/miniweather_mpi
fi
'

# Generate report for rank 0
perf report -i results/profiling/cpu/perf_mpi_rank0_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/perf_mpi_report_${SLURM_JOB_ID}.txt

echo "=== Top 20 Functions by CPU Time (Rank 0) ==="
perf report -i results/profiling/cpu/perf_mpi_rank0_${SLURM_JOB_ID}.data --stdio | head -40

# Also run with perf stat to get communication overhead estimates
echo ""
echo "=== Performance Statistics ==="
srun --ntasks=4 perf stat ./src/miniweather_mpi 2>&1 | tee results/profiling/cpu/perf_mpi_stats_${SLURM_JOB_ID}.txt

echo ""
echo "Full profiling report saved to:"
echo "  results/profiling/cpu/perf_mpi_report_${SLURM_JOB_ID}.txt"