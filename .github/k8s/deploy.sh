#!/bin/sh

set -eu

deploy_status=0

if [ "${DEPLOY_MODE:-false}" = "true" ]; then
  if [ -z "${GITHUB_REF_NAME:-}" ] || [ -z "${HUGGINGFACE_TOKEN:-}" ]; then
    echo "::error::GITHUB_REF_NAME and HUGGINGFACE_TOKEN are required." >&2
    deploy_status=$((deploy_status | 1))
  elif ! uv pip install --system huggingface_hub; then
    deploy_status=$((deploy_status | 1))
  elif ! python upload.py "${GITHUB_REF_NAME}"; then
    deploy_status=$((deploy_status | 1))
  fi
else
  echo "Skipping huggingface upload."
fi
