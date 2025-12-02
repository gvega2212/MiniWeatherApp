#!/bin/bash
# Minimal environment setup for MiniWeather on this cluster.

# Load NVIDIA HPC SDK for OpenACC GPU support
module load nvhpc/23.9

# Note: System-default MPI should work with NVHPC