import argparse
import papermill as pm
import os

parser = argparse.ArgumentParser()

parser.add_argument("--dataset", type=str, required=True)
parser.add_argument("--nyst", action="store_true",help="Enable Nyström mode")
parser.add_argument("--landmarks", type=int, required=False, default=700)


args = parser.parse_args()

os.makedirs("results", exist_ok=True)

pm.execute_notebook(
    "EMSCA_analysis_metrics.ipynb",                 # input notebook
    "results/output.ipynb",          # executed notebook
    parameters=dict(
        PUBLIC_DATASET=args.dataset,
        nyst=args.nyst,
        landmarks=args.landmarks
    )
)

print("Execution finished.")
print("Results saved in results/")