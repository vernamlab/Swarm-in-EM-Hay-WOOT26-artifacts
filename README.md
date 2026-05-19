# Swarm in EM Hay Artifact (WOOT'26)

This repository reproduces the EM-SCA mutual-information (MI) analysis pipeline and the MATLAB GMM/PSO probe-placement pipeline from:

> **Swarm in EM Hay: Particle Swarm-guided Probe Placement for EM SCA**  
> Dev Mehta, Seyedmohammad Nouraniboosjin, Maryam S. Safa, Shahin Tajik, Fatemeh Ganji  
> ePrint: https://eprint.iacr.org/2025/2244.pdf

## One-command reproduction (non-GUI)

Run from repository root:

```bash
./reproduce_all.sh impl_d
```

This command:
1. Executes `EMSCA_analysis_metrics.ipynb` via Papermill through `run_artifact.py`.
2. Writes notebook outputs to `results/` and MATLAB inputs to `MATLAB_exports/`.
3. Runs MATLAB in **batch mode** (`matlab -batch`) via `run_matlab_pipeline.m`.
4. Runs `GMM_gen.m` then `PSO.m` without manual GUI interaction.

If MATLAB is unavailable, the script exits with an explicit error.

## Environment and dependencies

### Python environment setup

Create a Python environment and install required packages:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Python side (MI pipeline)
- Python 3.x
- `papermill` (included in `requirements.txt`)
- Jupyter stack (for notebook execution backend)
- Notebook dependencies used by `EMSCA_analysis_metrics.ipynb`:
  - `numpy`, `matplotlib`, `scipy`
  - `chipwhisperer`
  - SCAPEgoat library (`WPI_SCA_LIBRARY` import path in notebook)

### MATLAB side (GMM + PSO pipeline)
- MATLAB (R2021+ recommended)
- **Statistics and Machine Learning Toolbox** (`fitgmdist`, `gmdistribution`, `lhsdesign`, etc.)
- **Optimization Toolbox** (`particleswarm`)

### Paid-license note
- MATLAB and its toolboxes typically require a paid MathWorks license.
- Python dependencies are open-source, but ChipWhisperer hardware/software setup may be required depending on capture/analysis mode.

## Base setup (automated run entrypoint)

Use `./reproduce_all.sh impl_d` as the top-level automated entrypoint.

Expected local data layout for the supported demo dataset:
- Public dataset `impl_d` must be accessible using the existing notebook assumptions.
- The notebook will create/update `MATLAB_exports/` automatically.

## Claims-to-evaluation mapping

| Claim | Evaluation step | Expected output |
|---|---|---|
| C1: MI analysis pipeline can be reproduced non-interactively for `impl_d`. | `python run_artifact.py --dataset impl_d` (called by `reproduce_all.sh`) | `results/output.ipynb`, `MATLAB_exports/MI_*.mat`, `MATLAB_exports/TVLA_tstat_*.mat`, `MATLAB_exports/data_100_121_impl_d.csv` |
| C2: GMM preprocessing runs from exported notebook traces without GUI/manual edits. | `matlab -batch "run_matlab_pipeline"` runs `GMM_gen.m` first | `output_matlab/GM_noiseless_pca_impl_d_new.mat` |
| C3: PSO optimization runs from MI export + GMM in batch mode. | Same MATLAB batch command then runs `PSO.m` | `output_matlab/exp_MI_fpga_impl_d_para_3_5.txt`, `output_matlab/PSO_SwarmSize_t_*.fig`, `output_matlab/PSO_SwarmSize_t_*.png`, `output_matlab/pso_visualization_10*.gif` |

## Python-to-MATLAB artifact flow

1. `run_artifact.py` executes `EMSCA_analysis_metrics.ipynb` with `PUBLIC_DATASET=impl_d` (or CLI-specified dataset).
2. Notebook export cells write:
   - MI matrix: `MATLAB_exports/MI_<...>.mat` (variable `MI`)
   - TVLA matrix: `MATLAB_exports/TVLA_tstat_<...>.mat`
   - Trace matrix CSV for GMM: `MATLAB_exports/data_100_121_impl_d.csv`
3. `GMM_gen.m` reads `data_100_121_impl_d.csv` and writes `output_matlab/GM_noiseless_pca_impl_d_new.mat`.
4. `PSO.m` loads:
   - Latest `MATLAB_exports/MI_*.mat`
   - `output_matlab/GM_noiseless_pca_impl_d_new.mat`
   and writes PSO outputs to `output_matlab/`.

## Expected output files/folders

- `results/output.ipynb`
- `MATLAB_exports/MI_*.mat`
- `MATLAB_exports/TVLA_tstat_*.mat`
- `MATLAB_exports/data_100_121_impl_d.csv`
- `output_matlab/GM_noiseless_pca_impl_d_new.mat`
- `output_matlab/exp_MI_fpga_impl_d_para_3_5.txt`
- `output_matlab/PSO_SwarmSize_t_*.fig`
- `output_matlab/PSO_SwarmSize_t_*.png`
- `output_matlab/pso_visualization_10*.gif`

## Restricted/offline environments

- `git clone --recurse-submodules` requires access to GitHub for the `SCAPEgoat` submodule (or a locally mirrored copy).
- Install Python dependencies before running the artifact: `pip install -r requirements.txt`.
- MATLAB is required for the GMM/PSO stage (`matlab -batch`).

## Notes

- Supported demo dataset remains `impl_d` by default.
- Scientific core logic in `GMM_gen.m` and `PSO.m` is intentionally unchanged except minimal automation hooks for batch execution.
