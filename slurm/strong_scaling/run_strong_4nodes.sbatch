#!/bin/bash
#SBATCH --job-name=miniweather_strong_4n
#SBATCH --nodes=4
#SBATCH --ntasks=4
#SBATCH --time=00:20:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -euo pipefail
source ../../env/load_modules.sh

NX=${NX:-128}
NY=${NY:-128}
NZ=${NZ:-64}
STEPS=${STEPS:-10}

make -C src clean
make -C src miniweather_mpi NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

mkdir -p results/strong_scaling/4_nodes

echo "Running MPI 4 ranks..."
MPI_CMD="./src/miniweather_mpi"
TIME=$(srun -n 4 $MPI_CMD 2>&1 | tee /dev/stderr | grep '^TIME:' | awk '{print $2}')
echo "ranks,time_seconds,NX,NY,NZ,STEPS" > results/strong_scaling/4_nodes/summary.csv
echo "4,${TIME},${NX},${NY},${NZ},${STEPS}" >> results/strong_scaling/4_nodes/summary.csv
