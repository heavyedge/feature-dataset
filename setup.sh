#!/bin/sh

pip install uv

uv tool install --force 'huggingface_hub[cli]'
export PATH="$(uv tool dir --bin):$PATH"
export HF_TOKEN="${HF_TOKEN:-$HUGGINGFACE_TOKEN}"

mkdir -p ./_data/v1/ ./_models

(
    uv pip install --system -r requirements.txt -r examples/requirements.txt
) &
requirements_pid=$!

(
  if [ "${HEAVYEDGE_TEST_MODE:-}" = "1" ]; then
      include="--include v1/profiles/all_profiles/dataset1.tar.gz --include v1/profiles/mean_profiles/dataset1.tar.gz --include v1/process_variables/mean_profiles/dataset1.csv --include v1/process_variables/all_profiles/dataset1.csv --include v1/datapackage.json"
  else
      include="--include v1/profiles/all_profiles/*.tar.gz --include v1/profiles/mean_profiles/*.tar.gz --include v1/process_variables/mean_profiles/*.csv --include v1/process_variables/all_profiles/*.csv --include v1/datapackage.json"
  fi
  hf download heavyedge/profiles --token "$HUGGINGFACE_TOKEN" --repo-type dataset --revision v1.0.0 $include --local-dir _data/
  for dataset in _data/v1/profiles/all_profiles/*.tar.gz; do
      stem=$(basename "$dataset" .tar.gz)
      dirname=_data/v1/profiles/all_profiles/"$stem"
      mkdir -p "$dirname"
      tar -xzf "$dataset" -C "$dirname"
  done
  for dataset in _data/v1/profiles/mean_profiles/*.tar.gz; do
      stem=$(basename "$dataset" .tar.gz)
      dirname=_data/v1/profiles/mean_profiles/"$stem"
      mkdir -p "$dirname"
      tar -xzf "$dataset" -C "$dirname"
  done
  rm -f _data/v1/profiles/all_profiles/*.tar.gz _data/v1/profiles/mean_profiles/*.tar.gz
) &
profiles_pid=$!

(
  hf download heavyedge/classifier-v1 --token "$HUGGINGFACE_TOKEN" --repo-type model --revision v1.0.0 --include "classifiers/*" --local-dir _models
) &
models_pid=$!

wait "$requirements_pid"
wait "$profiles_pid"
wait "$models_pid"

# Postprocess data

## Write dimensionless data

uv pip install --system -r libs/profile-dataset/requirements.txt -r libs/profile-dataset/examples/requirements.txt

mkdir -p _data/v1/dimless/mean_profiles
for f in _data/v1/process_variables/mean_profiles/*.csv; do
    out="_data/v1/dimless/mean_profiles/$(basename "$f")"
    papermill libs/profile-dataset/examples/v1/dimless.ipynb - -p pv_path "$f" -p metadata_path _data/v1/datapackage.json -p out_path "$out" > /dev/null 2>&1
done

mkdir -p _data/v1/dimless/all_profiles
for f in _data/v1/process_variables/all_profiles/*.csv; do
    out="_data/v1/dimless/all_profiles/$(basename "$f")"
    papermill libs/profile-dataset/examples/v1/dimless.ipynb - -p pv_path "$f" -p metadata_path _data/v1/datapackage.json -p out_path "$out" > /dev/null 2>&1
done
