#!/bin/bash
#SBATCH -J mw-profile-serial
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 00:15:00
#SBATCH -o results/profiling/cpu/profile_serial_%j.out
#SBATCH -e results/profiling/cpu/profile_serial_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu

NX=256
NY=128
NZ=128
STEPS=100

echo "Building serial version..."
make -C src clean
make -C src miniweather_serial NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

echo "Running perf profiling on serial version..."
perf record -g -o results/profiling/cpu/perf_serial_${SLURM_JOB_ID}.data \
    ./src/miniweather_serial

# Generate report
perf report -i results/profiling/cpu/perf_serial_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/perf_serial_report_${SLURM_JOB_ID}.txt

# Generate annotated source (if available)
perf annotate -i results/profiling/cpu/perf_serial_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/perf_serial_annotate_${SLURM_JOB_ID}.txt 2>&1 || true

echo "=== Top 20 Functions by CPU Time ==="
perf report -i results/profiling/cpu/perf_serial_${SLURM_JOB_ID}.data --stdio | head -40

echo ""
echo "Full profiling report saved to:"
echo "  results/profiling/cpu/perf_serial_report_${SLURM_JOB_ID}.txt"