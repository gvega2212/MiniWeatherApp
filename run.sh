#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  baseline)
    sbatch slurm/baseline/run_baseline.sbatch
    ;;
  strong)
    sbatch slurm/strong_scaling/run_strong_1node.sbatch
    sbatch slurm/strong_scaling/run_strong_2nodes.sbatch
    sbatch slurm/strong_scaling/run_strong_4nodes.sbatch
    ;;
  weak)
    sbatch slurm/weak_scaling/run_weak_1node.sbatch
    sbatch slurm/weak_scaling/run_weak_2nodes.sbatch
    sbatch slurm/weak_scaling/run_weak_4nodes.sbatch
    ;;
  hybrid)
    sbatch slurm/hybrid/strong_scaling/run_hybrid_strong.sbatch
    ;;
  all)
    "$0" baseline
    "$0" strong
    "$0" weak
    "$0" hybrid
    ;;
  *)
    echo "Usage: $0 {baseline|strong|weak|hybrid|all}"
    exit 1
    ;;
esac