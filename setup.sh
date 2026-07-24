#!/bin/sh

mkdir -p ./_data/v1/

curl -LsSf https://hf.co/cli/install.sh | bash
"$HOME/.local/bin/hf" auth login --token "$HUGGINGFACE_TOKEN"
if [ "${HEAVYEDGE_TEST_MODE:-}" = "1" ]; then
    profiles="v1/mean_profiles/dataset5.tar.gz"
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
