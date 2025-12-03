#!/usr/bin/env python3
"""Generate scaling plots from CSV logs under results/."""
from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib
import pandas as pd

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402  (import after backend)

ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "results"
PLOT_DIR = RESULTS_DIR / "plots"
PLOT_DIR.mkdir(parents=True, exist_ok=True)


def _load_series(patterns, xcol, y_candidates):
    frames = []
    for pattern in patterns:
        for path in RESULTS_DIR.glob(pattern):
            if not path.is_file():
                continue
            try:
                df = pd.read_csv(path)
            except Exception as exc:  # pragma: no cover - logging helper
                print(f"⚠️  Skipping {path}: {exc}")
                continue
            if xcol not in df.columns:
                continue
            ycol = next((c for c in y_candidates if c in df.columns), None)
            if not ycol:
                continue
            subset = df[[xcol, ycol]].dropna().copy()
            subset.rename(columns={ycol: "value"}, inplace=True)
            frames.append(subset)
    if not frames:
        return None
    data = (
        pd.concat(frames, ignore_index=True)
        .groupby(xcol, as_index=False)["value"].median()
        .sort_values(xcol)
    )
    return data


def _plot_series(df, xcol, xlabel, ylabel, title, output):
    if df is None or df.empty:
        print(f"⚠️  No data for {title}; skipping plot")
        return
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(df[xcol], df["value"], marker="o", linewidth=2)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.grid(True, linestyle=":", linewidth=0.7)
    fig.tight_layout()
    fig.savefig(output, dpi=160)
    plt.close(fig)
    print(f"✅ Wrote {output.relative_to(ROOT)}")


def main(selected: list[str] | None = None):
    configs = [
        {
            "name": "cpu_strong",
            "patterns": ["strong_scaling/*/strong_*_*.csv"],
            "xcol": "ranks",
            "ycandidates": ["time", "time_seconds"],
            "xlabel": "MPI ranks",
            "ylabel": "Time (s)",
            "title": "CPU MPI Strong Scaling",
            "filename": PLOT_DIR / "cpu_strong_scaling.png",
        },
        {
            "name": "cpu_weak",
            "patterns": ["weak_scaling/*/weak_*_*.csv"],
            "xcol": "ranks",
            "ycandidates": ["time", "time_seconds"],
            "xlabel": "MPI ranks",
            "ylabel": "Time (s)",
            "title": "CPU MPI Weak Scaling",
            "filename": PLOT_DIR / "cpu_weak_scaling.png",
        },
        {
            "name": "hybrid_strong",
            "patterns": ["hybrid/strong_scaling/*/hybrid_*_*.csv"],
            "xcol": "ranks",
            "ycandidates": ["time"],
            "xlabel": "MPI ranks",
            "ylabel": "Time (s)",
            "title": "Hybrid MPI+OpenMP Strong Scaling",
            "filename": PLOT_DIR / "hybrid_strong_scaling.png",
        },
        {
            "name": "hybrid_weak",
            "patterns": ["hybrid/weak_scaling/*/weak_hybrid_*_*.csv"],
            "xcol": "ranks",
            "ycandidates": ["time"],
            "xlabel": "MPI ranks",
            "ylabel": "Time (s)",
            "title": "Hybrid MPI+OpenMP Weak Scaling",
            "filename": PLOT_DIR / "hybrid_weak_scaling.png",
        },
        {
            "name": "gpu_strong",
            "patterns": ["gpu/strong_scaling/*_gpu_*.csv"],
            "xcol": "gpus",
            "ycandidates": ["time", "time_seconds"],
            "xlabel": "GPUs",
            "ylabel": "Time (s)",
            "title": "GPU Strong Scaling",
            "filename": PLOT_DIR / "gpu_strong_scaling.png",
        },
        {
            "name": "gpu_weak",
            "patterns": ["gpu/weak_scaling/*_gpu_*.csv"],
            "xcol": "gpus",
            "ycandidates": ["time", "time_seconds"],
            "xlabel": "GPUs",
            "ylabel": "Time (s)",
            "title": "GPU Weak Scaling",
            "filename": PLOT_DIR / "gpu_weak_scaling.png",
        },
    ]

    selected = set(selected or [cfg["name"] for cfg in configs])
    for cfg in configs:
        if cfg["name"] not in selected:
            continue
        data = _load_series(cfg["patterns"], cfg["xcol"], cfg["ycandidates"])
        _plot_series(
            data,
            cfg["xcol"],
            cfg["xlabel"],
            cfg["ylabel"],
            cfg["title"],
            cfg["filename"],
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate scaling plots from CSV logs")
    parser.add_argument(
        "names",
        nargs="*",
        help="Subset of plot names to build (default: all).",
    )
    args = parser.parse_args()
    main(args.names)
