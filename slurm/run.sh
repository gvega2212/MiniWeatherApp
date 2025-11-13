# Helper wrapper that builds/executes the app (can run inside Apptainer if needed)
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

sbatch slurm/run_baseline.sbatch
sbatch slurm/run_strong_scaling.sbatch
sbatch slurm/run_weak_scaling.sbatch