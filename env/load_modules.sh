#!/usr/bin/env bash
# Purge modules and load required toolchain for MiniWeatherApp
set -euo pipefail

# If environment has module command available
if command -v module >/dev/null 2>&1; then
	module purge
	# Load required modules (adjust names for your cluster if needed)
	module load gcc/12.2.0
	module load openmpi/4.1.5
	module load perf
else
	echo "module command not found; ensure toolchain is available in PATH"
fi

# Recommended runtime env
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-8}