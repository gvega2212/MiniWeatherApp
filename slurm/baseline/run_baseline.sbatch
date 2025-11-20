#!/bin/bash
#SBATCH --job-name=miniweather_baseline
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:20:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -euo pipefail

# load modules
source ../env/load_modules.sh

# Example overrides (tune as needed)
NX=${NX:-64}
NY=${NY:-64}
NZ=${NZ:-64}
STEPS=${STEPS:-10}
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}

# Build serial and openmp targets
make -C src clean
make -C src miniweather_serial NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS
make -C src miniweather_openmp NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

mkdir -p results/baseline

echo "Running serial..."
TIME_SERIAL=$(./src/miniweather_serial 2>&1 | tee /dev/stderr | grep '^TIME:' | awk '{print $2}')
echo "serial,${TIME_SERIAL},${NX},${NY},${NZ},${STEPS}" > results/baseline/run_times_summary.csv

echo "Running openmp..."
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}
TIME_OPENMP=$(./src/miniweather_openmp 2>&1 | tee /dev/stderr | grep '^TIME:' | awk '{print $2}')
echo "openmp,${TIME_OPENMP},${NX},${NY},${NZ},${STEPS},${OMP_NUM_THREADS}" >> results/baseline/run_times_summary.csv

echo "Baseline jobs finished. CSVs in results/baseline/"