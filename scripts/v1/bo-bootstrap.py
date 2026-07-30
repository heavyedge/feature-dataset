import argparse
import pathlib

import numpy as np
import pandas as pd
from bootstrap import AF, EF, Top5p, bootstrap_median

parser = argparse.ArgumentParser()
parser.add_argument("MC", type=pathlib.Path, help="MC csv file.")
parser.add_argument("ell", type=pathlib.Path, help="Loss csv file.")
parser.add_argument(
    "--num-bootstrap", type=int, required=True, help="Number of bootstrap samples."
)
parser.add_argument(
    "--bootstrap-chunk-size",
    type=int,
    default=256,
    help="Number of bootstrap samples processed per chunk (default: 256).",
)
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file.")
args = parser.parse_args()

mc = pd.read_csv(args.MC).to_numpy().T
ell = pd.read_csv(args.ell)["shape_loss"]

D_5p = np.where(ell <= np.percentile(ell, 5))[0]
top5p = Top5p(mc, D_5p)
ef = EF(top5p)
af = AF(top5p)

B = args.num_bootstrap
ci = [2.5, 97.5]
random_state = 0

chunk_size = args.bootstrap_chunk_size
boot_top5p = bootstrap_median(top5p, B, ci, random_state, chunk_size)  # (3, N)
boot_ef = bootstrap_median(ef, B, ci, random_state, chunk_size)  # (3, N)
boot_af = bootstrap_median(af, B, ci, random_state, chunk_size)  # (3, M)

statistic_names = ["mean", "ci_low", "ci_high"]
frames = []
for metric, values, axis_name in [
    ("top5p", boot_top5p, "bo_step"),
    ("ef", boot_ef, "bo_step"),
    ("af", boot_af, "percentile"),
]:
    frame = pd.DataFrame(values, index=statistic_names)
    frame.index.name = "statistic"
    frame = frame.stack().rename("value").reset_index()
    frame = frame.rename(columns={"level_1": axis_name})
    frame.insert(0, "metric", metric)
    frames.append(frame)

result = pd.concat(frames, ignore_index=True)
if args.out is not None:
    result.to_csv(args.out, index=False)
