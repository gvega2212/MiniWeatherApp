#!/bin/bash
set -euo pipefail

# Always run from repo root
cd "$(dirname "$0")"

submit_job() {
    local label="$1"
    local script="$2"
    echo ""
    echo "Submitting ${label} -> ${script}"
    sbatch "$script"
}

# CPU BASELINE
submit_job "CPU baseline (serial/OpenMP/MPI)" \
    "slurm/scaling/cpu/baseline/run_baseline.sbatch"


# CPU MPI — STRONG SCALING (1,2,4 nodes)
for nodes in 1 2 4; do
    submit_job "CPU MPI strong scaling (${nodes} node)" \
        "slurm/scaling/cpu/mpi/strong_scaling/strong_${nodes}n.sbatch"
done


# CPU MPI — WEAK SCALING (1,2,4 nodes)
for nodes in 1 2 4; do
    submit_job "CPU MPI weak scaling (${nodes} node)" \
        "slurm/scaling/cpu/mpi/weak_scaling/weak_${nodes}n.sbatch"
done


# CPU HYBRID MPI+OpenMP — STRONG SCALING
for nodes in 1 2 4; do
    submit_job "CPU hybrid strong scaling (${nodes} node)" \
        "slurm/scaling/cpu/hybrid/strong_scaling/strong_hybrid_${nodes}n.sbatch"
done


# CPU HYBRID MPI+OpenMP — WEAK SCALING
for nodes in 1 2 4; do
    submit_job "CPU hybrid weak scaling (${nodes} node)" \
        "slurm/scaling/cpu/hybrid/weak_scaling/weak_hybrid_${nodes}n.sbatch"
done


# GPU STRONG SCALING — ONLY 1 AND 2 GPUs
for gpus in 1 2; do
    submit_job "GPU strong scaling (${gpus} GPU)" \
        "slurm/scaling/gpu/strong_scaling/${gpus}_gpu.sbatch"
done


# GPU WEAK SCALING — ONLY 1 AND 2 GPUs
for gpus in 1 2; do
    submit_job "GPU weak scaling (${gpus} GPU)" \
        "slurm/scaling/gpu/weak_scaling/${gpus}_gpu.sbatch"
done

echo ""
echo "✨ All valid jobs submitted (no 4-GPU jobs — unsupported on this cluster)."
