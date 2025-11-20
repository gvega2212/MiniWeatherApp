#!/bin/bash
#SBATCH --job-name=miniweather_hybrid_strong
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --time=00:20:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -euo pipefail
source ../../../env/load_modules.sh

NX=${NX:-128}
NY=${NY:-128}
NZ=${NZ:-64}
STEPS=${STEPS:-10}
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}

make -C src clean
make -C src miniweather_hybrid NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

mkdir -p results/hybrid/strong_scaling

echo "Running hybrid (MPI+OpenMP) on 2 ranks..."
MPI_CMD="./src/miniweather_hybrid"
TIME=$(srun -n 2 $MPI_CMD 2>&1 | tee /dev/stderr | grep '^TIME:' | awk '{print $2}')
echo "ranks,threads,time_seconds,NX,NY,NZ,STEPS" > results/hybrid/strong_scaling/summary.csv
echo "2,${OMP_NUM_THREADS},${TIME},${NX},${NY},${NZ},${STEPS}" >> results/hybrid/strong_scaling/summary.csv
