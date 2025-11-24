#!/bin/bash
#SBATCH -J mw-prof-hybrid
#SBATCH -p cpubase_bycore_b1
#SBATCH -N 1
#SBATCH --ntasks=1              # 1 MPI rank for profiling
#SBATCH --cpus-per-task=4       # 4 threads; tweak as you like
#SBATCH -t 00:05:00
#SBATCH --mem=4G
#SBATCH -o results/profiling/cpu/hybrid/prof_hybrid_%j.out
#SBATCH -e results/profiling/cpu/hybrid/prof_hybrid_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu/hybrid

NX=128
NY=64
NZ=64
STEPS=200

echo "[hybrid] Building..."
make -C src clean
make -C src miniweather_hybrid NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd src

echo "[hybrid] perf stat (1 rank, $OMP_NUM_THREADS threads)..."
perf stat -o ../results/profiling/cpu/hybrid/perf_stat_${SLURM_JOB_ID}.txt \
    srun ./miniweather_hybrid

echo "[hybrid] perf record..."
perf record -g \
    -o ../results/profiling/cpu/hybrid/perf_data_${SLURM_JOB_ID}.data \
    srun ./miniweather_hybrid

cd ..

echo "[hybrid] perf report..."
perf report --stdio \
    -i results/profiling/cpu/hybrid/perf_data_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/hybrid/perf_report_${SLURM_JOB_ID}.txt

echo "[hybrid] Done. See results/profiling/cpu/hybrid/"
