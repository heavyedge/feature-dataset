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
      include="--include v1/profiles/dataset1.tar.gz --include v1/mean_profiles/dataset1.tar.gz --include v1/process_variables/dataset1.csv --include v1/datapackage.json"
  else
      include="--include v1/profiles/*.tar.gz --include v1/mean_profiles/*.tar.gz --include v1/process_variables/*.csv --include v1/datapackage.json"
  fi
  hf download heavyedge/profiles --token "$HUGGINGFACE_TOKEN" --repo-type dataset --revision v1.0.0 $include --local-dir _data/
  for dataset in _data/v1/profiles/*.tar.gz; do
      stem=$(basename "$dataset" .tar.gz)
      dirname=_data/v1/profiles/"$stem"
      mkdir -p "$dirname"
      tar -xzf "$dataset" -C "$dirname"
  done
  for dataset in _data/v1/mean_profiles/*.tar.gz; do
      stem=$(basename "$dataset" .tar.gz)
      dirname=_data/v1/mean_profiles/"$stem"
      mkdir -p "$dirname"
      tar -xzf "$dataset" -C "$dirname"
  done
  rm -f _data/v1/profiles/*.tar.gz _data/v1/mean_profiles/*.tar.gz
) &
profiles_pid=$!

(
  hf download heavyedge/classifier-v1 --token "$HUGGINGFACE_TOKEN" --repo-type model --revision v1.0.0 --include "classifiers/*" --local-dir _models
) &
models_pid=$!

wait "$requirements_pid"
wait "$profiles_pid"
wait "$models_pid"
