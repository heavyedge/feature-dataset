# Edge Profile Dataset
[![HuggingFace](https://img.shields.io/badge/HuggingFace-Dataset-orange?logo=huggingface)](https://huggingface.co/datasets/jeesoo9595/heavyedge-features)
[![GitHub repository](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/heavyedge/feature-dataset)

Edge profile shape feature dataset.

## Usage

This repository provides scripts to perform feature extraction from each version of profile dataset.

### Cloning the repository

You need:

- `git`
- Python runtime with `pip`

Run the following commands to clone the repository and install the necessary requirements.

```sh
git clone git@github.com:heavyedge/feature-dataset.git
cd feature-dataset
pip install -r requirements.txt
```

### Downloading the profile dataset (Optional)

Run the following commands to download the profile dataset in the `_data` directory.

```sh
export HUGGINGFACE_TOKEN="..."
./setup.sh
```

## Contributing

### Configuring git

Configure the local git filter (run once after cloning):

```sh
nbstripout --install --attributes .gitattributes
git config filter.nbstripout.clean "nbstripout"
git config filter.nbstripout.smudge cat
git config filter.nbstripout.required true
```

### Versioning policy

This repository follows semantic versioning with [Python version specifiers](https://packaging.python.org/en/latest/specifications/version-specifiers/):

```
N.N.N[{a|b|rc}N][.postN][.devN]
```

- Final release and pre-release (`N.N.N[{a|b|rc}N]`):
  - Dataset is re-built and deployed to HuggingFace.
  - Examples are re-built using the new dataset and uploaded as release artifacts.
- Post-release (`*.postN`):
  - Dataset is deployed to HuggingFace without re-building.
    This means that only the metadata will change.
  - Examples are re-built using the previous dataset and uploaded as release artifacts.
- Developmental release (`*.devN`):
  - Dataset is not built and not deployed to HuggingFace.
  - Examples are not built and not uploaded as release artifacts.

> **NOTE**: The major version is raised only when the dataset is changed in a backward-incompatible way.
> When new data is added, minor version is raised with new `datasets/v*` directory.
