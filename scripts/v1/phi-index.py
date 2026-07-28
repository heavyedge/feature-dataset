import argparse
import pathlib

import numpy as np
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("shape_metrics", type=pathlib.Path, help="Shape metrics CSV file.")
parser.add_argument("class_prob", type=pathlib.Path, help="Class probability CSV file.")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output index npy file.")
args = parser.parse_args()

phi = pd.read_csv(args.shape_metrics)["phi"].values
labels = np.argmax(pd.read_csv(args.class_prob), axis=1)


unique_labels = np.sort(np.unique(labels))

phi_candidates = {}  # label -> list of (global_idx, phi_value)
for lbl in unique_labels:
    mask = labels == lbl
    idxs_lbl = np.where(mask)[0]
    phi_candidates[int(lbl)] = [(int(idx), float(phi[idx])) for idx in idxs_lbl]

# Seed: pick the profile with the most extreme phi overall
remaining_labels = {int(lbl) for lbl in unique_labels}
selected = {}  # label -> (global_idx, phi_value)
best_seed = (None, None, -np.inf)
for lbl in remaining_labels:
    for idx, p in phi_candidates[lbl]:
        if abs(p) > abs(best_seed[2]):
            best_seed = (lbl, idx, p)
selected[best_seed[0]] = (best_seed[1], best_seed[2])
remaining_labels.discard(best_seed[0])

# Greedily pick from remaining labels
while remaining_labels:
    best_label, best_idx, best_phi, best_min_dist = None, None, None, -1.0
    selected_phis = [p for _, p in selected.values()]
    for lbl in remaining_labels:
        for idx, p in phi_candidates[lbl]:
            min_dist = min(abs(p - sp) for sp in selected_phis)
            if min_dist > best_min_dist:
                best_label, best_idx, best_phi, best_min_dist = lbl, idx, p, min_dist
    selected[best_label] = (best_idx, best_phi)
    remaining_labels.discard(best_label)

target_idxs = [selected[int(lbl)][0] for lbl in unique_labels]
target_phis = [selected[int(lbl)][1] for lbl in unique_labels]

# Sort everything by phi value
phi_order = np.argsort(target_phis)
unique_labels = unique_labels[phi_order]
target_idxs = [target_idxs[i] for i in phi_order]

np.save(args.out, np.sort(target_idxs[::2]))
