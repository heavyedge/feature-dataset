#!/bin/sh

set -eu

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT INT TERM

if ! ./setup.sh; then
  exit 1
fi
if ! curl -LsSf https://hf.co/cli/install.sh | bash; then
  exit 1
fi

make_targets="dataset-v1"
case "${BUILD_MODE:-test}" in
  build)
    if ! HEAVYEDGE_TEST_MODE=0 make -j ${MAKE_JOBS} ${make_targets}; then
      exit 2
    fi
    ;;
  pull)
    overlay_dir="${work_dir}/dataset-overlay"
    mkdir -p "$overlay_dir"
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
    if ! HEAVYEDGE_TEST_MODE=1 make -j ${MAKE_JOBS} ${make_targets}; then
      exit 2
    fi
    ;;
  *)
    echo "::error::Unsupported build mode: ${BUILD_MODE}" >&2
    exit 2
    ;;
esac

make_targets="examples-v1"
case "${DOC_BUILD_MODE:-test}" in
  build)
    if ! HEAVYEDGE_TEST_MODE=0 make -j ${MAKE_JOBS} ${make_targets}; then
      exit 3
    fi
    ;;
  pull)
    required_vars="
    DOC_UPSTREAM_REVISION
    GITHUB_APP_TOKEN
    GITHUB_REPOSITORY
    "
    for var_name in ${required_vars}; do
      eval "var_value=\${${var_name}:-}"
      if [ -z "${var_value}" ]; then
        echo "::error::Missing ${var_name} for benchmark artifact download." >&2
        exit 3
      fi
    done

    release_response="${work_dir}/release.json"
    artifact_file="${work_dir}/results.tar.gz"
    asset_name="results-${DOC_UPSTREAM_REVISION}.tar.gz"
    release_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/${DOC_UPSTREAM_REVISION}"
    http_status="$(
      curl -sS -o "${release_response}" -w '%{http_code}' \
        -H 'Accept: application/vnd.github+json' \
        -H "Authorization: Bearer ${GITHUB_APP_TOKEN}" \
        -H 'X-GitHub-Api-Version: 2022-11-28' \
        "${release_url}"
    )" || {
      echo "::error::Failed to find release ${DOC_UPSTREAM_REVISION}; GitHub API request failed." >&2
      exit 3
    }
    if [ "${http_status}" -lt 200 ] || [ "${http_status}" -ge 300 ]; then
      echo "::error::Failed to find release ${DOC_UPSTREAM_REVISION}; GitHub API returned HTTP ${http_status}." >&2
      exit 3
    fi

    asset_id="$(
      python -c 'import json, sys; name = sys.argv[1]; print(next((asset["id"] for asset in json.load(sys.stdin)["assets"] if asset["name"] == name), ""))' \
        "${asset_name}" < "${release_response}"
    )"
    if [ -z "${asset_id}" ]; then
      echo "::error::Release ${DOC_UPSTREAM_REVISION} does not contain ${asset_name}." >&2
      exit 3
    fi

    asset_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/assets/${asset_id}"
    http_status="$(
      curl -sS -L -o "${artifact_file}" -w '%{http_code}' \
        -H 'Accept: application/octet-stream' \
        -H "Authorization: Bearer ${GITHUB_APP_TOKEN}" \
        -H 'X-GitHub-Api-Version: 2022-11-28' \
        "${asset_url}"
    )" || {
      echo "::error::Failed to download ${asset_name}; GitHub API request failed." >&2
      exit 3
    }
    if [ "${http_status}" -lt 200 ] || [ "${http_status}" -ge 300 ]; then
      echo "::error::Failed to download ${asset_name}; GitHub API returned HTTP ${http_status}." >&2
      exit 3
    fi

    if ! tar -xzf "${artifact_file}" benchmarks; then
      echo "::error::Failed to extract benchmarks from ${asset_name}." >&2
      exit 3
    fi
    if [ ! -d benchmarks ]; then
      echo "::error::${asset_name} does not contain a benchmarks directory." >&2
      exit 3
    fi

    set -- -j "${MAKE_JOBS}"
    benchmark_list="${work_dir}/benchmarks.list"
    find benchmarks -type f -print > "${benchmark_list}"
    while IFS= read -r benchmark_file; do
      set -- "$@" "--assume-old=${benchmark_file}"
    done < "${benchmark_list}"
    if ! HEAVYEDGE_TEST_MODE=0 make "$@" ${make_targets}; then
      exit 3
    fi
    ;;
  test)
    if ! HEAVYEDGE_TEST_MODE=1 make -j ${MAKE_JOBS} ${make_targets}; then
      exit 3
    fi
    ;;
  *)
    echo "::error::Unsupported doc build mode: ${DOC_BUILD_MODE}" >&2
    exit 3
    ;;
esac
