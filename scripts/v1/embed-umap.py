import argparse
import pathlib

import numpy as np
import pandas as pd
import umap
from aeon.transformations.collection.convolution_based import MiniRocket
from heavyedge import ProfileData
from sklearn.linear_model import RidgeClassifierCV
from sklearn.pipeline import Pipeline

parser = argparse.ArgumentParser()
parser.add_argument("profiles", type=pathlib.Path, help="Preprocessed profile data.")
parser.add_argument("class_proba", type=pathlib.Path, help="Class probability csv file")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file.")
args = parser.parse_args()

with ProfileData(args.profiles) as file:
    x = file.x()
    X, _, _ = file[:]
    X /= np.trapezoid(X, x, axis=1)[..., np.newaxis]

y = pd.read_csv(args.class_proba).values.argmax(axis=1)

pipeline = Pipeline(
    [
        ("minirocket", MiniRocket(random_state=42)),
        ("classifier", RidgeClassifierCV(class_weight="balanced")),
    ],
    verbose=True,
)
pipeline.fit(X, y)

X_features = pipeline.decision_function(X)

transformer = umap.UMAP(
    target_metric="categorical",
    random_state=42,
    n_jobs=1,
)
embedding = transformer.fit_transform(X_features, y=y)
pd.DataFrame(
    embedding, columns=[f"UMAP_{i}" for i in range(embedding.shape[1])]
).to_csv(args.out, index=False)
