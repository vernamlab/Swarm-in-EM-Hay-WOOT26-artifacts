# Reproducing Figures 1 and 2

This repository contains the notebooks and scripts needed to regenerate the results shown in **Figure 1** and **Figure 2** of the paper:

> **Swarm in EM Hay: Particle Swarm-guided Probe Placement for EM SCA**  
> Dev Mehta, Seyedmohammad Nouraniboosjin, Maryam S. Safa, Shahin Tajik, Fatemeh Ganji  
> ePrint: https://eprint.iacr.org/2025/2244.pdf

## Overview

The paper studies automated probe placement for electromagnetic side-channel analysis (EM SCA). In particular, it uses information-theoretic leakage metrics such as mutual information (MI) to identify informative leakage regions and guide probe placement. Figures 1 and 2 compare different MI estimators, including KSG, histogram-based MI, matrix-based Rényi entropy (MRE), and Nyström-accelerated MRE.

This repository provides the files required to reproduce these figures.

## Datasets

After cloning this repository, the required datasets are already included.

The experiments use the **ASCAD dataset**, originally available from:

https://github.com/ANSSI-FR/ASCAD

No separate dataset download is required if you cloned this repository with the provided data files.

## Required Python Package

The notebooks require the `npeet` entropy-estimation library.

Install it using:

```bash
pip install git+https://github.com/gregversteeg/NPEET.git
```

You may also need the standard scientific Python stack:

```bash
pip install numpy scipy matplotlib scikit-learn jupyter
```

## Reproducing Figure 1

Figure 1 compares MI estimation methods on the ASCAD fixed-key dataset. Each ASCAD trace contains 700 time samples, and MI is computed between each sample point and the AES S-box output.

To regenerate Figure 1, run:

```bash
jupyter notebook fig_1_final.ipynb
```

or:

```bash
jupyter lab fig_1_final.ipynb
```

## Reproducing Figure 2(a)

Figure 2(a) evaluates MI estimation on synthetic Gaussian samples under increasing noise. It compares the stability of different MI estimators when the noise level increases.

To regenerate Figure 2(a), run:

```bash
jupyter notebook fig2_a.ipynb
```

or:

```bash
jupyter lab fig2_a.ipynb
```

## Reproducing Figure 2(b)

Figure 2(b) studies the effect of Nyström sampling on matrix-based Rényi entropy estimation. Nyström sampling approximates the full kernel matrix using a smaller number of landmark samples, reducing computation while preserving the MI trend.

To regenerate the Nyström-based result, run the MATLAB script:

```matlab
nystrumASCAD
```

or from the terminal, depending on your MATLAB setup:

```bash
matlab -batch "nystrumASCAD"
```

## Repository Files

| File | Purpose |
|---|---|
| `fig_1_final.ipynb` | Regenerates Figure 1: MI estimation on ASCAD |
| `fig2_a.ipynb` | Regenerates Figure 2(a): MI estimation under Gaussian noise |
| `nystrumASCAD.m` | Regenerates Figure 2(b): Nyström approximation for MRE |
| ASCAD data files | Required traces and labels for the ASCAD-based experiments |

## Suggested Workflow

```bash
git clone <repo-url>
cd <repo-folder>

pip install git+https://github.com/gregversteeg/NPEET.git
pip install numpy scipy matplotlib scikit-learn jupyter

jupyter notebook fig_1_final.ipynb
jupyter notebook fig2_a.ipynb
```

Then run the MATLAB script:

```bash
matlab -batch "nystrumASCAD"
```

## Notes

- Make sure the dataset paths inside the notebooks match the repository structure.
- If a notebook cannot find the data, check the relative path used for loading ASCAD traces and labels.
- The results may vary slightly depending on package versions and random seeds.
- For full methodological details, refer to the paper linked above.
