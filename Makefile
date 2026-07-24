.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets dataset-v1 clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASETS_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/profiles/dataset* | xargs -n 1 basename))
PROFILES_v1 = $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),001,$(shell ls _data/v1/profiles/$(1)/*.tar.gz | xargs -n 1 basename -s .tar.gz))

all: datasets

datasets: dataset-v1

dataset-v1:

clean:
	rm -rf _temp datasets/v*
