# SYSTEM — MiniWeatherApp environment & job configuration

- Node types: Generic cluster nodes (tunable via SBATCH --nodes). Adjust node counts in slurm scripts.
- Compiler: gcc/12.2.0 (loaded by env/load_modules.sh)
- MPI: OpenMPI 4.1.5 (loaded by env/load_modules.sh)
- Profiling: perf (module loaded)
- Container: Apptainer image target is Ubuntu 22.04 (env/project.def)
- Build flags (Makefile controlled): default flags use compiler from environment. Override problem size macros via:
  make -C src <target> NX=... NY=... NZ=... STEPS=...
- OpenMP: OMP_NUM_THREADS default = 8 (container and env script). Scripts set OMP_NUM_THREADS appropriately before running.
- Job configuration: scripts use standardized result directories:
  - results/strong_scaling/{1_node,2_nodes,4_nodes}
  - results/weak_scaling/{1_node,2_nodes,4_nodes}
  - results/hybrid/strong_scaling
- Logs: Slurm logs go to logs/ (not into results/) to keep results/ containing only structured CSVs.
