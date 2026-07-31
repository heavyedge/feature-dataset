# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0a5] - UNRELEASED

Datasets:

- `heavyedge/profiles:v1.0.0rc3`

Classification model:

- `jeesoo9595/classifier-v1:v1.0.0a2`

### Changed

- Change dependent repo ids.

## [v1.0.0a4.post1] - 2026-07-31

### Fixed

- Developmental release is no longer blocked in `upload.py`.
- New Github app token is acquired before deployment.

## [v1.0.0a4.post0] - 2026-07-29

### Added

- `phi` example.
- Bayesian optimization example.

## [v1.0.0a4] - 2026-07-27

Feature extractor:

- `heavyedge-features==1.1.0a3`

### Added

- Dataset metadata.
- Feature visualization example.

## [v1.0.0a3] - 2026-07-27

Feature extractor:

- `heavyedge-features==1.1.0a2`

## [v1.0.0a2] - 2026-07-26

Feature extractor:

- `heavyedge-features==1.1.0a1`

## [v1.0.0a1] - 2026-07-26

Feature extractor:

- `heavyedge-features==1.1.0a0`

### Fixed

- Shape features from not-averaged profiles are now correctly computed by repeating the wet thickness by the number of profiles.

## [v1.0.0a0] - 2026-07-25

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
