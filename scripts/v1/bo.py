import argparse
import pathlib
import warnings

import numpy as np
import pandas as pd
from bo_util import bo

warnings.filterwarnings("ignore")

parser = argparse.ArgumentParser()
parser.add_argument("X", type=pathlib.Path, help="Predictor csv file.")
parser.add_argument("ell", type=pathlib.Path, help="Shape loss csv file.")
parser.add_argument("--init", nargs="+", type=int, help="Initial indices.")
parser.add_argument("--iter", type=int, help="Number of BO iterations.")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file.")
args = parser.parse_args()

df = pd.read_csv(args.X)
df["slurry"] = df["slurry"].astype("category").cat.codes
X = df.drop(columns=["name", "cosine_of_contact_angle"]).to_numpy()
ell = pd.read_csv(args.ell)["shape_loss"].to_numpy()
initial_idxs = np.array(args.init, dtype=int)

bo_idxs = bo(X, ell, initial_idxs, min(args.iter, len(X) - len(initial_idxs)))
pd.DataFrame({"idxs": bo_idxs[len(args.init) :]}).to_csv(args.out, index=False)
