#!/bin/sh

mkdir -p ./_data/v1/ ./_models
curl -LsSf https://hf.co/cli/install.sh | bash

(
  if [ "${HEAVYEDGE_TEST_MODE:-}" = "1" ]; then
      include="--include v1/profiles/dataset1.tar.gz --include v1/mean_profiles/dataset1.tar.gz --include v1/process_variables/dataset1.csv"
  else
      include="--include v1/profiles/*.tar.gz --include v1/mean_profiles/*.tar.gz --include v1/process_variables/*.csv"
  fi
  "$HOME/.local/bin/hf" download jeesoo9595/heavyedge-profiles --token "$HUGGINGFACE_TOKEN" --repo-type dataset --revision v1.0.0rc2 $include --local-dir _data/
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
  "$HOME/.local/bin/hf" download jeesoo9595/heavyedge-classify-v1 --token "$HUGGINGFACE_TOKEN" --repo-type model --revision v1.0.0a1 --include "classifiers/*" --local-dir _models
) &
models_pid=$!

wait "$profiles_pid"
wait "$models_pid"
