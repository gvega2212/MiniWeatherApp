#!/bin/bash
set -euo pipefail

# Always run from repo root
cd "$(dirname "$0")"

echo "Submitting baseline job..."
sbatch slurm/run_baseline.sbatch

echo "Submitting STRONG scaling jobs..."
sbatch slurm/strong_scaling/strong_1n.sbatch
sbatch slurm/strong_scaling/strong_2n.sbatch
sbatch slurm/strong_scaling/strong_4n.sbatch

echo "Submitting WEAK scaling jobs..."
sbatch slurm/weak_scaling/weak_1n.sbatch
sbatch slurm/weak_scaling/weak_2n.sbatch
sbatch slurm/weak_scaling/weak_4n.sbatch

echo "Submitting Hybrid scaling jobs..."
sbatch slurm/hybrid/strong_scaling/strong_hybrid_1n.sbatch
sbatch slurm/hybrid/strong_scaling/strong_hybrid_2n.sbatch
sbatch slurm/hybrid/strong_scaling/strong_hybrid_4n.sbatch
sbatch slurm/hybrid/weak_scaling/weak_hybrid_1n.sbatch
sbatch slurm/hybrid/weak_scaling/weak_hybrid_2n.sbatch
sbatch slurm/hybrid/weak_scaling/weak_hybrid_4n.sbatch