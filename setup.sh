#!/bin/sh

mkdir -p ./_data/v1/ ./_models
curl -LsSf https://hf.co/cli/install.sh | bash
"$HOME/.local/bin/hf" auth login --token "$HUGGINGFACE_TOKEN"

(
  if [ "${HEAVYEDGE_TEST_MODE:-}" = "1" ]; then
      profiles="v1/mean_profiles/dataset1.tar.gz"
  else
      profiles="v1/mean_profiles/*.tar.gz"
  fi
  "$HOME/.local/bin/hf" download jeesoo9595/heavyedge-profiles --repo-type dataset --revision v1.0.0rc1 --include "$profiles" --local-dir _data/
  for dataset in _data/v1/mean_profiles/*.tar.gz; do
      stem=$(basename "$dataset" .tar.gz)
      dirname=_data/v1/mean_profiles/"$stem"
      mkdir -p "$dirname"
      tar -xzf "$dataset" -C "$dirname"
  done
  rm -f _data/v1/mean_profiles/*.tar.gz
) &
profiles_pid=$!

(
  "$HOME/.local/bin/hf" download jeesoo9595/heavyedge-classify-v1 --repo-type model --revision v1.0.0a1 --include "classifiers/*" --local-dir _models
) &
models_pid=$!

wait "$profiles_pid"
wait "$models_pid"
