#!/bin/bash
#SBATCH -J mw-prof-serial
#SBATCH -p cpu-node
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 00:05:00
#SBATCH --mem=4G
#SBATCH -o results/profiling/serial/prof_serial_%j.out
#SBATCH -e results/profiling/serial/prof_serial_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

# Create output folder
mkdir -p results/profiling/serial

# Small grid for profiling
NX=128
NY=64
NZ=64
STEPS=20

echo "Building serial profiling version..."
make -C src clean
# Add profiling flags (-g -fno-omit-frame-pointer)
make -C src miniweather_serial \
     NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS \
     CFLAGS_EXTRA="-g -fno-omit-frame-pointer"

cd src

echo "Running perf stat..."
perf stat -o ../results/profiling/serial/perf_stat_${SLURM_JOB_ID}.txt \
    ./miniweather_serial

echo "Running perf record..."
perf record -g -o ../results/profiling/serial/perf_data_${SLURM_JOB_ID}.data \
    ./miniweather_serial

# Convert binary perf.data → human-readable text
cd ..
perf report --stdio \
    -i results/profiling/serial/perf_data_${SLURM_JOB_ID}.data \
    > results/profiling/serial/perf_report_${SLURM_JOB_ID}.txt

echo "Profiling complete!"
echo "Saved:"
echo "  perf_stat_${SLURM_JOB_ID}.txt"
echo "  perf_data_${SLURM_JOB_ID}.data"
echo "  perf_report_${SLURM_JOB_ID}.txt"
