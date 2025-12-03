#!/bin/bash
#SBATCH -J mw-prof-openmp
#SBATCH -p cpubase_bycore_b1
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2       # 2 OpenMP threads
#SBATCH -t 00:05:00
#SBATCH --mem=4G
#SBATCH -o results/profiling/cpu/openmp/prof_openmp_%j.out
#SBATCH -e results/profiling/cpu/openmp/prof_openmp_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu/openmp

NX=128
NY=64
NZ=64
STEPS=200

echo "[openmp] Building..."
make -C src clean
make -C src miniweather_openmp NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd src

echo "[openmp] perf stat..."
perf stat -o ../results/profiling/cpu/openmp/perf_stat_${SLURM_JOB_ID}.txt \
    ./miniweather_openmp

echo "[openmp] perf record..."
perf record -g \
    -o ../results/profiling/cpu/openmp/perf_data_${SLURM_JOB_ID}.data \
    ./miniweather_openmp

cd ..

echo "[openmp] perf report..."
perf report --stdio \
    -i results/profiling/cpu/openmp/perf_data_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/openmp/perf_report_${SLURM_JOB_ID}.txt

echo "[openmp] Done. See results/profiling/cpu/openmp/"
