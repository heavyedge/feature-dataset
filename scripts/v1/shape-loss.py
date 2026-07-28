import argparse
import pathlib

import pandas as pd

parser = argparse.ArgumentParser(description="Write shape loss.")
parser.add_argument("features", type=pathlib.Path, help="Shape feature csv file.")
parser.add_argument("--lambda_H", type=float, default=0.0, help="Weight for H")
parser.add_argument("--lambda_b", type=float, default=0.0, help="Weight for b")
parser.add_argument("--lambda_phi", type=float, default=0.0, help="Weight for phi")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file")
args = parser.parse_args()

df = pd.read_csv(args.features)
loss = (
    args.lambda_H * (df["H"] - 1) ** 2
    + args.lambda_b * df["b"] ** 2
    + args.lambda_phi * df["phi"].apply(lambda x: max(x, 0))
)
loss.to_csv(args.out, index=False, header=["shape_loss"])
