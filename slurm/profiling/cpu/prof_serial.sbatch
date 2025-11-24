#!/bin/bash
#SBATCH -J mw-prof-serial
#SBATCH -p cpubase_bycore_b1
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 00:05:00
#SBATCH --mem=4G
#SBATCH -o results/profiling/cpu/serial/prof_serial_%j.out
#SBATCH -e results/profiling/cpu/serial/prof_serial_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu/serial

NX=128
NY=64
NZ=64
STEPS=200

echo "[serial] Building..."
make -C src clean
make -C src miniweather_serial NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

cd src

echo "[serial] perf stat..."
perf stat -o ../results/profiling/cpu/serial/perf_stat_${SLURM_JOB_ID}.txt \
    ./miniweather_serial

echo "[serial] perf record..."
perf record -g \
    -o ../results/profiling/cpu/serial/perf_data_${SLURM_JOB_ID}.data \
    ./miniweather_serial

cd ..

echo "[serial] perf report..."
perf report --stdio \
    -i results/profiling/cpu/serial/perf_data_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/serial/perf_report_${SLURM_JOB_ID}.txt

echo "[serial] Done. See results/profiling/cpu/serial/"
