#!/bin/bash
#SBATCH -J mw-prof-mpi
#SBATCH -p cpubase_bycore_b1
#SBATCH -N 1
#SBATCH --ntasks=1             # single rank for profiling
#SBATCH --cpus-per-task=1
#SBATCH -t 00:05:00
#SBATCH --mem=4G
#SBATCH -o results/profiling/cpu/mpi/prof_mpi_%j.out
#SBATCH -e results/profiling/cpu/mpi/prof_mpi_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"
source env/load_modules.sh

mkdir -p results/profiling/cpu/mpi

NX=128
NY=64
NZ=64
STEPS=200

echo "[mpi] Building..."
make -C src clean
make -C src miniweather_mpi NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

cd src

echo "[mpi] perf stat (srun, 1 rank)..."
perf stat -o ../results/profiling/cpu/mpi/perf_stat_${SLURM_JOB_ID}.txt \
    srun ./miniweather_mpi

echo "[mpi] perf record..."
perf record -g \
    -o ../results/profiling/cpu/mpi/perf_data_${SLURM_JOB_ID}.data \
    srun ./miniweather_mpi

cd ..

echo "[mpi] perf report..."
perf report --stdio \
    -i results/profiling/cpu/mpi/perf_data_${SLURM_JOB_ID}.data \
    > results/profiling/cpu/mpi/perf_report_${SLURM_JOB_ID}.txt

echo "[mpi] Done. See results/profiling/cpu/mpi/"
