# Copilot Instructions for MiniWeatherApp

## Project Overview
MiniWeatherApp is a high-performance computing (HPC) mini-application for weather simulation, supporting serial, OpenMP, MPI, and hybrid MPI+OpenMP parallelism. It is designed for benchmarking and educational use on clusters.

## Architecture & Components
- **Source Code**: All main C sources are in `src/`:
  - `miniweather_serial.c`: Serial version
  - `miniweather_openmp.c`: OpenMP parallel version
  - `miniweather_mpi.c`: MPI parallel version
  - `miniweather_hybrid.c`: Hybrid MPI+OpenMP version
- **Build System**: Uses a single `Makefile` in `src/`. Override problem size via `make miniweather_mpi NX=... NY=... NZ=... STEPS=...`.
- **Environment**: Module requirements and cluster settings in `env/` (`modules.txt`, `project.def`, `load_modules.sh`).
- **Job Scripts**: SLURM batch scripts in `slurm/` automate builds and runs for different scaling scenarios.
- **Results**: Output CSVs and logs in `results/`, organized by baseline, hybrid, strong/weak scaling.

## Developer Workflows
- **Build**: Run `make -C src clean && make -C src` (see SLURM scripts for typical parameters).
- **Run**: Use SLURM scripts in `slurm/` for reproducible runs. Example: `sbatch slurm/baseline/run_baseline.sbatch`.
- **Environment Setup**: Source `env/load_modules.sh` if needed. Most clusters work with system defaults, but see `env/modules.txt` for required modules.
- **Parameterization**: Problem size and steps are set via environment variables or Makefile overrides. SLURM scripts set these explicitly.

## Patterns & Conventions
- **Grid Initialization**: All versions initialize a 3D grid with deterministic values (`x + y + z`).
- **Output**: Results are written as CSV files to `results/baseline/` for serial/OpenMP, and as logs for MPI/hybrid runs.
- **Scaling**: Strong/weak scaling experiments are organized in `results/` and `slurm/` subfolders.
- **Hybrid Parallelism**: `miniweather_hybrid.c` uses both MPI and OpenMP. OpenMP parallel regions are guarded with `#pragma omp` and MPI calls are used for inter-node communication.

## Integration Points
- **External Dependencies**: Requires `gcc`, `openmpi`, and optionally `perf`/`likwid` for profiling (see `env/modules.txt`).
- **Cluster Environment**: Designed for Magic Castle (EESSI) but portable to other clusters with similar toolchains.

## Key Files & Examples
- `src/Makefile`: Build logic and parameter overrides
- `env/project.def`: Cluster and toolchain settings
- `slurm/baseline/run_baseline.sbatch`: End-to-end build/run workflow
- `results/baseline/output_serial.csv`: Example output format

## Tips for AI Agents
- Always check SLURM scripts for canonical build/run workflows and parameter settings.
- When adding new parallel versions, follow the grid initialization and output conventions.
- Place new results in the appropriate `results/` subfolder and update SLURM scripts as needed.
- Use environment files in `env/` to document new dependencies or cluster requirements.

---
*Update this file as project conventions evolve. Ask maintainers if any workflow or pattern is unclear.*
