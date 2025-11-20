#!/bin/bash
#SBATCH --job-name=miniweather_weak_2n
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --time=00:20:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

set -euo pipefail
source ../../env/load_modules.sh

NX=${NX:-64}
NY=${NY:-64}
NZ=${NZ:-64}
STEPS=${STEPS:-10}

make -C src clean
make -C src miniweather_mpi NX=$NX NY=$NY NZ=$NZ STEPS=$STEPS

mkdir -p results/weak_scaling/2_nodes

echo "Running MPI weak scaling 2 ranks..."
MPI_CMD="./src/miniweather_mpi"
TIME=$(srun -n 2 $MPI_CMD 2>&1 | tee /dev/stderr | grep '^TIME:' | awk '{print $2}')
echo "ranks,time_seconds,NX,NY,NZ,STEPS" > results/weak_scaling/2_nodes/summary.csv
echo "2,${TIME},${NX},${NY},${NZ},${STEPS}" >> results/weak_scaling/2_nodes/summary.csv
