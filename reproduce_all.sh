#!/usr/bin/env bash
set -euo pipefail

DATASET="${1:-impl_d}"

mkdir -p results output_matlab MATLAB_exports

echo "[preflight] Checking Python dependencies"
python - <<'PY'
import importlib.util
import sys

required = ["papermill"]
missing = [m for m in required if importlib.util.find_spec(m) is None]
if missing:
    print("Missing required Python package(s): " + ", ".join(missing), file=sys.stderr)
    print("Install dependencies with: pip install -r requirements.txt", file=sys.stderr)
    sys.exit(2)
print("Papermill preflight check passed.")
PY

echo "[1/2] Running Python/Papermill pipeline for dataset=${DATASET}"
python run_artifact.py --dataset "${DATASET}"

module load matlab/R2024a

echo "[2/2] Running MATLAB pipeline in batch mode"
if command -v matlab >/dev/null 2>&1; then
  matlab -batch "run_matlab_pipeline"
else
  echo "ERROR: matlab executable not found in PATH." >&2
  exit 127
fi

echo "Reproduction complete. Outputs: results/, MATLAB_exports/, output_matlab/"
