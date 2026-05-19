#!/usr/bin/env bash
set -euo pipefail

DATASET="${1:-impl_d}"

mkdir -p results output_matlab MATLAB_exports

echo "[preflight] Checking Python dependency: papermill"
if ! python -c "import papermill" >/dev/null 2>&1; then
  echo "ERROR: Python package 'papermill' is not available." >&2
  echo "Please run: pip install -r requirements.txt" >&2
  exit 1
fi

echo "[1/2] Running Python/Papermill pipeline for dataset=${DATASET}"
python run_artifact.py --dataset "${DATASET}"

echo "[2/2] Running MATLAB pipeline in batch mode"
if command -v matlab >/dev/null 2>&1; then
  matlab -batch "run_matlab_pipeline"
else
  echo "ERROR: matlab executable not found in PATH." >&2
  exit 127
fi

echo "Reproduction complete. Outputs: results/, MATLAB_exports/, output_matlab/"
