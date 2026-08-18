# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0rc3] - 2026-08-18

### Fixed

- `name` field in dataset csv files are now restored.

## [1.0.0rc2] - 2026-08-17

### Fixed

- Some recipes are fixed.

## [1.0.0rc1] - 2026-08-17

- Dataset: `heavyedge/profiles:v1.0.0`
- Classifier:
  - `heavyedge-classify==1.4.0`
  - `jeesoo9595/classifier-v1:v1.0.0`
- Feature extractor: `heavyedge-features==1.1.0`

## [1.0.0rc0] - 2026-08-17

CI/CD is enhanced.

## [1.0.0b1] - 2026-08-01

### Added

- Shape feature datasets now have `name` field.

### Fixed

- Shape feature order is fixed.

## [1.0.0b0] - 2026-07-31

Datasets:

- `heavyedge/profiles:v1.0.0rc3`

Classification model:

- `jeesoo9595/classifier-v1:v1.0.0a2`

### Changed

- Change dependent repo ids.
- Dataset repository is changed to `heavyedge/shape-features`.

## [1.0.0a4.post1] - 2026-07-31

### Fixed

- Developmental release is no longer blocked in `upload.py`.
- New Github app token is acquired before deployment.

## [1.0.0a4.post0] - 2026-07-29

### Added

- `phi` example.
- Bayesian optimization example.

## [1.0.0a4] - 2026-07-27

Feature extractor:

- `heavyedge-features==1.1.0a3`

### Added

- Dataset metadata.
- Feature visualization example.

## [1.0.0a3] - 2026-07-27

Feature extractor:

- `heavyedge-features==1.1.0a2`

## [1.0.0a2] - 2026-07-26

Feature extractor:

- `heavyedge-features==1.1.0a1`

## [1.0.0a1] - 2026-07-26

Feature extractor:

- `heavyedge-features==1.1.0a0`

### Fixed

- Shape features from not-averaged profiles are now correctly computed by repeating the wet thickness by the number of profiles.

## [1.0.0a0] - 2026-07-25

Shape features:

- `H`
- `b`
- `phi`

Datasets:

- `jeesoo9595/heavyedge-profiles:v1.0.0rc1`

Classification model:

- `heavyedge-classify==1.4.0`
- `jeesoo9595/heavyedge-classify-v1:v1.0.0a1`

Feature extractor:

- `heavyedge-features==1.0.1`
