import argparse
import os
import sys

from huggingface_hub import HfApi
from packaging.version import InvalidVersion, Version

parser = argparse.ArgumentParser(description="Upload to Hugging Face Hub")
parser.add_argument("tag", help="Version tag (e.g., v1.0.0)")
args = parser.parse_args()

version_text = args.tag.removeprefix("v")

try:
    version = Version(version_text)
except InvalidVersion:
    print(f"Invalid version tag: {args.tag}", file=sys.stderr)
    sys.exit(1)

api = HfApi(token=os.getenv("HUGGINGFACE_TOKEN"))

VERSION = args.tag
REPO = "heavyedge/shape-features"

api.create_repo(
    repo_id=REPO,
    repo_type="dataset",
    private=True,
    exist_ok=True,
)
api.upload_folder(
    folder_path="datasets",
    path_in_repo=".",
    repo_id=REPO,
    repo_type="dataset",
    commit_message=f"Upload version {VERSION}",
)
api.create_tag(
    repo_id=REPO,
    repo_type="dataset",
    tag=VERSION,
)
