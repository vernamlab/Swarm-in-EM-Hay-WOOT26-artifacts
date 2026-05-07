# EM for Good

This repository contains a compact EM-SCA workflow built around four edited files:

- `CEMA_capture_FPGA_UC.ipynb` for capture on FPGA or microcontroller targets
- `CEMA_analysis_metrics.ipynb` for TVLA, CEMA, MI, CSV/MAT export, and GMM preparation
- `emtraces_noiseremoval_pca_discrete.m` for PCA-based trace denoising and GMM sample generation
- `final_PSO_em_clean.m` for the MATLAB PSO driver

The current flow is:

1. Download the public data to the same folder structure used by the notebooks.
2. Capture new traces, or load the public datasets in the analysis notebook.
3. Export MI and TVLA matrices from the analysis notebook.
4. Use the MATLAB scripts for denoising, GMM preparation, and PSO optimization.

## Base Setup

1. Install ChipWhisperer following the [official documentation](https://chipwhisperer.readthedocs.io/en/latest/).
   - This is required for capture and for notebook imports.

2. Clone the SCAPEgoat library into the ChipWhisperer workspace.
   - Keep the import path aligned with the notebook paths used in the notebooks.

3. Download the trace data from the same location as before:
   - [EMSCA Traces](https://app.box.com/v/EMSCA-for-good)
   - Keep the existing folder structure when downloading partially.
   - The `CEMA` folder should remain the parent container for the experiments and metadata.
   - If you only need some experiments, partial download is fine as long as the experiment folder structure is preserved.

4. Keep the notebooks and data together in the same workspace root.
   - Place `CEMA_analysis_metrics.ipynb` alongside the `CEMA` folder that contains the experiments.
   - Place `CEMA_capture_FPGA_UC.ipynb` in the same workspace so it can write into the same experiment tree.
   - Keep `emtraces_noiseremoval_pca_discrete.m` and `final_PSO_em_clean.m` in the same root so the exported files are easy to find.

5. Verify import and data paths before running.
   - Confirm the SCAPEgoat import path is correct in the notebooks.
   - Confirm the `CEMA` folder sits where the notebooks expect it.
   - If the notebooks are moved later, update the paths instead of changing the data layout.

## Workflow Overview

The base setup above stays the same. The new flow is layered on top of it.

### 1. Capture

Use `CEMA_capture_FPGA_UC.ipynb` when you want to generate new experiments.

- Select `TARGET = "FPGA"` or `TARGET = "UC"`.
- The notebook handles the target-specific setup and experiment naming.
- The capture output is written into the SCAPEgoat experiment structure.

### 2. Analysis

Use `CEMA_analysis_metrics.ipynb` for either captured data or public datasets.

- `CAPTURE` mode loads locally captured experiments.
- `PUBLIC` mode loads the fixed public datasets:
  - `impl_d`
  - `impl_1`
  - `impl_3`
  - `uc`
- The notebook computes TVLA, CEMA, and MI.
- The notebook exports `.mat` and `.csv` files into `MATLAB_exports/`.

### 3. Trace Matrix Export

The analysis notebook also includes a helper cell that builds a trace matrix for downstream MATLAB work.

- `uc` uses the fixed trace window.
- `impl_d`, `impl_1`, and `impl_3` export the full trace.
- The output is a CSV file used for the PCA/GMM preprocessing script.

### 4. MATLAB Processing

Use the MATLAB files after analysis exports are ready.

- `emtraces_noiseremoval_pca_discrete.m` reads `data_100_121_*.csv`, builds the PCA/GMM model, and saves `GM_noiseless_pca_*.mat`.
- `final_PSO_em_clean.m` loads the MI matrix and runs the PSO search.

## Outputs

The analysis notebook produces these artifacts in `MATLAB_exports/`:

- `MI_*.mat` and `MI_*.csv`
- `TVLA_tstat_*.mat` and `TVLA_tstat_*.csv`
- `CEMA_*.mat` and `CEMA_*.csv`

The MATLAB preprocessing script produces:

- `data_100_121_*.csv`
- `GM_noiseless_pca_*.mat`

The PSO script expects the MI matrix and the GMM initialization file created from the preprocessing step.

## Notes

- The notebook flow now prefers MI as the primary metric for optimization.
- SNR is no longer part of the main analysis/export path.
- The public datasets are fixed inputs; only the dataset selector changes.

## License

This project is licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

## Contact

If you have questions or want to report a bug, email [dmmehta2@wpi.edu](mailto:dmmehta2@wpi.edu).
