#!/bin/bash
# Load all modules required for the miniWeather project

# Compiler and MPI
module load gcc/12.2.0
module load openmpi/4.1.5

# Profiling tools
module load perf
# (Optional: module load likwid if available on your cluster)

# Confirm environment setup
echo "=== miniWeather environment loaded ==="
which gcc
which mpicc
which mpirun
