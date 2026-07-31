import argparse
import pathlib

import pandas as pd
from heavyedge import ProfileData

parser = argparse.ArgumentParser(description="Write shape feature data with name.")
parser.add_argument("profiles", type=pathlib.Path, help="Profile data directory.")
parser.add_argument("feat", type=pathlib.Path, help="Shape feature csv file")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file")
args = parser.parse_args()


def count_profiles(profiles_dir):
    paths = sorted(profiles_dir.glob("*.h5"))
    num_profiles = []
    names = []
    for path in paths:
        with ProfileData(path) as profiles:
            num_profiles.append(profiles.shape()[0])
        names.append(path.stem)
    return num_profiles, names


num_profiles, names = count_profiles(args.profiles)
names = pd.Series(names, name="name").repeat(num_profiles).reset_index(drop=True)
features = pd.read_csv(args.feat).reset_index(drop=True)
pd.concat([names, features], axis=1).to_csv(args.out, index=False)
