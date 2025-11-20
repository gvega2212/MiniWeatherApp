#!/bin/bash
#SBATCH -J mw-profile-openmp
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH -t 00:15:00
#SBATCH -o results/profiling/cpu/profile_openmp_%j.out
#SBATCH -e results/profiling/cpu/profile_openmp_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu

NX=256
NY=128
NZ=128
STEPS=100

echo "Building OpenMP version..."
make -C src clean
make -C src miniweather_openmp NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=16

echo "Running perf profiling on OpenMP version (16 threads)..."
perf record -g -o results/profiling/cpu/perf_openmp_${SLURM_JOB_ID}.data \
    ./src/miniweather_openmp

# Generate report
perf report -i results/profiling/cpu/perf_openmp_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/perf_openmp_report_${SLURM_JOB_ID}.txt

# Cache statistics
echo "=== Cache Statistics ==="
perf stat -e cache-references,cache-misses,L1-dcache-loads,L1-dcache-load-misses \
    ./src/miniweather_openmp 2>&1 | tee results/profiling/cpu/perf_openmp_cache_${SLURM_JOB_ID}.txt

echo "=== Top 20 Functions by CPU Time ==="
perf report -i results/profiling/cpu/perf_openmp_${SLURM_JOB_ID}.data --stdio | head -40

echo ""
echo "Full profiling report saved to:"
echo "  results/profiling/cpu/perf_openmp_report_${SLURM_JOB_ID}.txt"