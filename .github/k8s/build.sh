#!/bin/sh

set -eu

if ! ./setup.sh; then
  exit 1
fi
if ! curl -LsSf https://hf.co/cli/install.sh | bash; then
  exit 1
fi

make_targets="dataset-v1"
case "${BUILD_MODE:-test}" in
  build)
    if ! HEAVYEDGE_TEST_MODE=0 make -j ${CPU_REQUEST} ${make_targets}; then
      exit 2
    fi
    ;;
  pull)
    overlay_dir="$(mktemp -d)"
    trap 'rm -rf "$overlay_dir"' EXIT INT TERM
    cp -a datasets/. "$overlay_dir/"
    if ! "$HOME/.local/bin/hf" download "${UPSTREAM_REPO_ID}" \
        --repo-type dataset \
        --revision "${UPSTREAM_REVISION}" \
        --token "${HUGGINGFACE_TOKEN}" \
        --local-dir datasets; then
      exit 2
    fi
    cp -a "$overlay_dir/." datasets/
    rm -rf datasets/.cache/huggingface
    ;;
  test)
    if ! HEAVYEDGE_TEST_MODE=1 make -j ${CPU_REQUEST} ${make_targets}; then
      exit 2
    fi
    ;;
  *)
    echo "::error::Unsupported build mode: ${BUILD_MODE}" >&2
    exit 2
    ;;
esac
