#!/bin/bash
# Minimal environment setup for MiniWeather on this cluster.
# We assume system-default compilers and MPI are already available.

# If your cluster uses Lmod, you *could* do:
# module purge
# module load gcc
# module load openmpi
# but on this system it appears to work without explicit modules.