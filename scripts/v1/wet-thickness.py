import argparse
import json
import pathlib

import pandas as pd
import pint

parser = argparse.ArgumentParser(description="Write wet thickness data.")
parser.add_argument("pv", type=pathlib.Path, help="Process variable csv file")
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

    df = pd.read_csv(pv_csv_path)
    ureg = pint.UnitRegistry()
    for field, unit_name in field_units.items():
        if field not in df.columns:
            raise ValueError(f"PV CSV is missing unit-bearing field: {field}")
        unit = ureg.Unit(unit_name)
        df[field] = df[field].map(lambda value: value * unit)

    return df


df = read_pv(args.pv, args.metadata)
wt = df["flow_rate_per_width"] / df["coating_speed"]
wt = wt.apply(lambda x: x.to("mm").magnitude).rename("wet_thickness [mm]")

wt.to_csv(args.out, index=False)
