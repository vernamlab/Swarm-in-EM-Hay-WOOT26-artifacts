# Swarm in EM Hay Artifact WOOT'26
This repository provides the source code to reproduce results from the paper:
> **Swarm in EM Hay: Particle Swarm-guided Probe Placement for EM SCA**  
> Dev Mehta, Seyedmohammad Nouraniboosjin, Maryam S. Safa, Shahin Tajik, Fatemeh Ganji  
> ePrint: https://eprint.iacr.org/2025/2244.pdf

## Overview

The paper studies automated probe placement for electromagnetic side-channel analysis (EM SCA). In particular, it uses information-theoretic leakage metrics such as mutual information (MI) to identify informative leakage regions and guide probe placement. Figures 1 and 2 compare different MI estimators, including KSG, histogram-based MI, matrix-based Rényi entropy (MRE), and Nyström-accelerated MRE.

This repository contains a compact EM-SCA workflow built around the following notebooks and scripts:

- `EMSCA_capture_FPGA_UC.ipynb` for capture on FPGA or microcontroller targets
- `EMSCA_analysis_metrics.ipynb` for TVLA, CEMA, MI, CSV/MAT export, and GMM preparation
- `EMSCA_functions.ipynb` for helper functions and utilities
- `GMM_gen.m` for MATLAB GMM generation and processing
- `PSO.m` for the MATLAB PSO optimization driver

The workflow is as follows:

1. Download the public data to the same folder structure used by the notebooks.
2. Capture new traces, or load the public datasets in the analysis notebook.
3. Export MI and TVLA matrices from the analysis notebook.
4. Use the MATLAB scripts for GMM preparation and PSO optimization.
   - If you use the notebook outputs, point the MATLAB scripts to `MATLAB_exports/` and set the correct file and folder names.
   - If you use the Box downloads, point the MATLAB scripts to `input_matlab/` and update the file and folder paths accordingly.
   - If you want to skip a step, you can use the intermediate files provided in the Box download, as long as the MATLAB paths match those files.

## Base Setup

1. Install ChipWhisperer following the [official documentation](https://chipwhisperer.readthedocs.io/en/latest/).
   - This is required for capture and for notebook imports.

2. Clone the SCAPEgoat library into the ChipWhisperer home directory.
   - This creates `scapegoat-main/` alongside the artifacts folder.
   - Keep the import path aligned with the notebook paths used in the notebooks.

3. Download the trace data from the same location as before:
   - [EMSCA Traces](https://app.box.com/v/EMSCA-for-good)
   - Download the `CEMA` folder and place it inside the artifacts folder (Swarm-in-EM-Hay-WOOT26-artifacts/).
   - Download the `input_matlab` folder and place it at the same level as the CEMA folder.
   - The `CEMA` folder contains `metadata_holder.json` and an `experiments/` subfolder with datasets.
   - If you only need some experiments, partial download is fine as long as the experiment folder structure is preserved.

4. Keep the notebooks and data together in the artifacts folder.
   - The artifacts folder should be placed in the ChipWhisperer home directory alongside `scapegoat-main/`.
   - Place `EMSCA_analysis_metrics.ipynb` in the root of the artifacts folder.
   - Place `EMSCA_capture_FPGA_UC.ipynb` in `Capture_scripts/`.
   - Keep `GMM_gen.m` and `PSO.m` in the root so the exported files are easy to find.

5. Verify import and data paths before running.
   - Confirm the SCAPEgoat import path is correct in the notebooks.
   - Confirm the `CEMA` folder sits inside the artifacts folder.
   - If paths are moved later, update the notebook paths instead of changing the data layout.

## Directory Structure

The recommended workspace structure is:

```
ChipWhisperer_home/
├── scapegoat-main/                 # SCAPEgoat library
└── Swarm-in-EM-Hay-WOOT26-artifacts/
    ├── README.md
    ├── EMSCA_functions.ipynb          # Helper functions and utilities
    ├── EMSCA_analysis_metrics.ipynb   # Main analysis notebook
    ├── AES_model.ipynb                # AES implementation model
    ├── GMM_gen.m                      # MATLAB script for GMM generation
    ├── PSO.m                          # MATLAB script for PSO optimization
    ├── Capture_scripts/
    │   ├── EMSCA_capture_FPGA_UC.ipynb
    │   ├── Setup_script.ipynb
    │   └── impl_3.bit
    ├── Figure1_and_2/                 # Notebooks and data for paper figures
    │   ├── readme.md
    │   ├── Fig1/
    │   │   ├── ASCAD.h5
    │   │   ├── discrete_random_variable.py
    │   │   ├── fig_1_final.ipynb
    │   │   └── MRE.py
    │   └── fig2/
    │       ├── fig2a/
    │       │   ├── fig2_a.ipynb
    │       │   ├── mi_vals_r.csv
    │       │   └── mi_vals.csv
    │       └── fig2b/
    │           ├── [MATLAB analysis files]
    │           └── [utility files]
    ├── CEMA/                          # Downloaded from box
    │   ├── metadata_holder.json
    │   └── experiments/
    │       └── [datasets]
    └── input_matlab/                  # Downloaded from box
        └── [MATLAB input files and data]
```

## Workflow Overview

The base setup above stays the same. The new flow is layered on top of it.

### 1. Capture

Use `EMSCA_capture_FPGA_UC.ipynb` when you want to generate new experiments.

- Select `TARGET = "FPGA"` or `TARGET = "UC"`.
- The notebook handles the target-specific setup and experiment naming.
- The capture output is written into the SCAPEgoat experiment structure.

### 2. Analysis

Use `EMSCA_analysis_metrics.ipynb` for either captured data or public datasets.

- `CAPTURE` mode loads locally captured experiments.
- `PUBLIC` mode loads the fixed public datasets:
  - `impl_d` - `FPGA_1 in the paper`
  - `impl_3` - `FPGA_2 in the paper`
  - `uc`
- The notebook computes TVLA, CEMA, and MI.
- The notebook exports `.mat` and `.csv` files into `MATLAB_exports/`.

### 3. Trace Matrix Export

The analysis notebook also includes a helper cell that builds a trace matrix for downstream MATLAB work.

- `uc` uses the fixed trace window.
- `impl_d`, and `impl_3` export the full trace.
- The output is a CSV file used for the PCA/GMM preprocessing script.

### 4. MATLAB Processing

Use the MATLAB scripts after analysis exports are ready.

- Run `GMM_gen.m` first to build the GMM model from the available trace input file.
- Run `PSO.m` after that, using the MI matrix and the generated GMM model.
- If you skip either step, use the intermediate files from the Box download and point the MATLAB scripts to those files instead.

## Outputs

The analysis notebook produces these artifacts in `MATLAB_exports/`:

- `MI_*.mat` and `MI_*.csv`
- `TVLA_tstat_*.mat` and `TVLA_tstat_*.csv`
- `CEMA_*.mat` and `CEMA_*.csv`

The GMM generation script produces:

- Processed trace data and GMM model files in the configured output folder

The PSO script uses the MI or TVLA matrix and the GMM initialization file from the preceding steps.

If you use the Box-provided intermediate files instead of regenerating them, update the MATLAB input folder to point to `input_matlab/`.

The `input_matlab/` folder contains three file types:

- GMM training files: `Data*.csv`
- GMM model files: `GM*.mat`
- Heatmap inputs: `*_heatmap.mat`, `MI*.mat`

Use files from the same dataset together and avoid mixing datasets.

## Notes

- The notebook flow now prefers MI as the primary metric for optimization.
- SNR is no longer part of the main analysis/export path.
- The public datasets are fixed inputs; only the dataset selector changes.

## License

This project is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

## Contact

If you have questions or want to report a bug, email [dmmehta2@wpi.edu](mailto:dmmehta2@wpi.edu).
