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

echo "[2/2] Running MATLAB pipeline in batch mode"
MATLAB_BIN="$(command -v matlab || true)"

if [[ -z "${MATLAB_BIN}" ]]; then
  shopt -s nullglob
  matlab_candidates=(
    /Applications/MATLAB_*.app/bin/matlab
    /usr/local/MATLAB/*/bin/matlab
    /opt/MATLAB/*/bin/matlab
  )
  shopt -u nullglob

  if ((${#matlab_candidates[@]} > 0)); then
    MATLAB_BIN="${matlab_candidates[0]}"
  fi
fi

if [[ -n "${MATLAB_BIN}" ]] && [[ -x "${MATLAB_BIN}" ]]; then
  "${MATLAB_BIN}" -batch "run_matlab_pipeline"
else
  echo "ERROR: matlab executable not found in PATH." >&2
  exit 127
fi

echo "Reproduction complete. Outputs: results/, MATLAB_exports/, output_matlab/"
