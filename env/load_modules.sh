#!/bin/bash
# Minimal environment setup for MiniWeather on this cluster.

# Use the Compute Canada recommended GCC toolchain.
module load StdEnv/2023 >/dev/null 2>&1 || module load gcc