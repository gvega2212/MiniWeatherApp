#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <jobid> [jobid ...]" >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOG_DIR="$ROOT_DIR/results/logs"
mkdir -p "$LOG_DIR"

FMT="JobID%15,State%10,ElapsedRAW,AveCPU,TotalCPU,MaxRSS,MaxVMSize,NNodes,AllocCPUS,AllocGRES"

for job in "$@"; do
    outfile="$LOG_DIR/sacct_${job}.txt"
    echo "Collecting sacct data for job $job -> ${outfile#$ROOT_DIR/}"
    sacct -j "$job" --format="$FMT" --units=M -P > "$outfile"
    echo "  saved $(wc -l < "$outfile") lines"
    echo ""
done
