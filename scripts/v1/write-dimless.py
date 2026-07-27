import argparse
import json
import pathlib

import numpy as np
import pandas as pd
import pint

parser = argparse.ArgumentParser(description="Write dimensionless process variables.")
parser.add_argument(
    "pv", type=pathlib.Path, nargs="+", help="Process variable csv files."
)
parser.add_argument("metadata", type=pathlib.Path, help="datapackage.json file")
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output csv file")
args = parser.parse_args()


def read_pv(pv_csv_path, datapackage_json_path):
    with open(datapackage_json_path) as file:
        datapackage = json.load(file)

    resource = next(
        (
            item
            for item in datapackage["resources"]
            if item["name"] == "Process variables"
        ),
        None,
    )
    if resource is None:
        raise ValueError(f"No resource found in {datapackage_json_path}")

    field_units = {
        field["name"]: field["unit"]
        for field in resource["schema"]["fields"]
        if "unit" in field
    }

    df = pd.read_csv(pv_csv_path, dtype={"name": str})
    df["name"] = df["name"].apply(lambda x: f"{pv_csv_path.stem}/{x}")
    ureg = pint.UnitRegistry()
    for field, unit_name in field_units.items():
        if field not in df.columns:
            raise ValueError(f"PV CSV is missing unit-bearing field: {field}")
        unit = ureg.Unit(unit_name)
        df[field] = df[field].map(lambda value: value * unit)

    return df


df = pd.concat([read_pv(path, args.metadata) for path in args.pv], ignore_index=True)

wet_thickness = df["flow_rate_per_width"] / df["coating_speed"]
H_g = df["coating_gap"]
Rgt = (H_g / wet_thickness).apply(lambda x: x.to_reduced_units())
Ca = (df["viscosity"] * df["coating_speed"] / df["surface_tension"]).apply(
    lambda x: x.to_reduced_units()
)
cos_theta = df["contact_angle"].apply(lambda x: np.cos(x.to("radian").magnitude))
H_F = (df["shim_thickness"] / H_g).apply(lambda x: x.to_reduced_units())
L_d = (df["downstream_lip_length"] / H_g).apply(lambda x: x.to_reduced_units())
L_u = (df["upstream_lip_length"] / H_g).apply(lambda x: x.to_reduced_units())


dimless = pd.DataFrame(
    {
        "name": df["name"],
        "slurry": df["slurry"],
        "gap_to_thickness_ratio": Rgt.apply(lambda x: x.magnitude),
        "capillary_number": Ca.apply(lambda x: x.magnitude),
        "cosine_of_contact_angle": cos_theta,
        "feed_slot_height_ratio": H_F.apply(lambda x: x.magnitude),
        "downstream_lip_length_ratio": L_d.apply(lambda x: x.magnitude),
        "upstream_lip_length_ratio": L_u.apply(lambda x: x.magnitude),
    }
)
dimless.to_csv(args.out, index=False)
