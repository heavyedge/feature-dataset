# Edge Feature Dataset
[![HuggingFace](https://img.shields.io/badge/HuggingFace-Dataset-orange?logo=huggingface)](https://huggingface.co/datasets/heavyedge/shape-features)
[![GitHub repository](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/heavyedge/feature-dataset)

Edge profile shape feature dataset.

Provides:
  - Shape feature dataset.
  - Benchmark results of shape features.
  - Example notebooks.

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

### Downloading the prerequisites (Optional)

Run the following commands to download the prerequisites in the `_data` directory.

```sh
export HUGGINGFACE_TOKEN="..."
./setup.sh
```

### Acquiring the shape feature data

The shape feature data built by this project can be acquired by downloading it directly from the [dataset repository](https://huggingface.co/datasets/heavyedge/shape-features).
Alternatively, you can perform the feature extraction yourself if you have downloaded the prerequisites.

Either approach creates the feature data in the `datasets` directory.

#### Direct download

You need:

- [Hugging Face CLI](https://huggingface.co/docs/transformers/en/installation)

Run the following command:

```sh
hf download heavyedge/shape-features --repo-type dataset --local-dir datasets
```

#### Building the dataset

You need:

- `make`

Run the following command:

```sh
make datasets
```

Each `datasets/v*` directory stores shape feature data from the corresponding major version of profile dataset.

Feature extraction can be done in parallel by setting the `FEATURE_JOBS` argument.

### Acquiring the built examples

The shape feature data and benchmark results are visualized as notebooks in the `examples` directory.

The notebook outputs are stripped before being stored in this repository.
To check their outputs, you must acquire the built example notebooks.

You can either download the built notebooks from the [GitHub release](https://github.com/heavyedge/feature-dataset/releases) artifacts, or build the notebooks yourself if you have acquired the feature data.

#### Building the notebooks

You need:

- `make`

```sh
pip install -r examples/requirements.txt
make examples
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

### Testing

Setting the `HEAVYEDGE_TEST_MODE` environment variable to `1` downloades and buildxs only a small subset of data for testing purposes.

```sh
export HEAVYEDGE_TEST_MODE=1
./setup.sh
make
```

### Building the container image

The `Dockerfile` is provided to facilitate data distribution without sharing secrets.

After downloading the prerequisites and building the dataset and examples, build the image with one of the following targets:

- `base` (default)
  - Includes the dataset (`datasets`).
  - Includes the benchmarks and built examples (`benchmarks`, `examples`).
  - Includes non-hidden source files.
- `dev`
  - Includes the prerequisites (`_data`, `_model`).
  - Includes the dataset (`datasets`).
  - Includes the benchmarks and built examples (`benchmarks`, `examples`).
  - Includes all source files.

### Versioning policy

This repository follows semantic versioning with [Python version specifiers](https://packaging.python.org/en/latest/specifications/version-specifiers/):

```
N.N.N[{a|b|rc}N][.postN][.devN]
```

- Major version is raised when the dataset API is changed in a backwards-incompatible way.
- Minor version is raised when new dataset is added.
- Patch version is raised when bugs are fixed.

> **NOTE**: The major version is raised only when the dataset is changed in a backward-incompatible way.
> When new data is added, minor version is raised with new `datasets/v*` directory.
