# MiniWeatherApp Documentation

This folder tracks the human-facing artifacts that accompany the scaling experiments.

- `bottleneck_analysis.md` – current read on compute vs. communication/memory pressure based on the METRICS logs. Update this after each profiling pass.
- `README.md` – this file; keep it short so newcomers can navigate the docs quickly.
- (upcoming) EuroHPC proposal + short paper drafts. Drop them here so they version with the code.

**Where to look next**

- Raw logs & CSVs live under `results/` (git-ignored; regenerate via the provided Slurm scripts).
- Plot generation script: `scripts/plot_scaling.py` writes PNGs into `results/plots/` once Matplotlib is available (use the local `.venv` or load a Python module with matplotlib/pandas).
- Profiling job files (perf, Nsight Systems/Compute) are under `slurm/profiling/` and deposit their reports in `results/profiling/` when run.