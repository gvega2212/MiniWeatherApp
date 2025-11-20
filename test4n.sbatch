#!/bin/bash
#SBATCH -J test-4n
#SBATCH -N 4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH -t 00:05:00
#SBATCH --mem=2000M
#SBATCH -o test_4n_%j.out
#SBATCH -e test_4n_%j.err

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

echo "SLURM_NNODES = $SLURM_NNODES"
echo "SLURM_JOB_NODELIST = $SLURM_JOB_NODELIST"

srun hostname
