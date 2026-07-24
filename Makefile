.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets dataset-v1 clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASETS_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/mean_profiles/dataset* | xargs -n 1 basename))
PROFILES_v1 = $(shell ls _data/v1/mean_profiles/$(1)/*.h5)

all: datasets

datasets: dataset-v1

dataset-v1:

clean:
	rm -rf _temp datasets/v*

_temp/v1/MeanProfiles.h5: $(foreach dataset,$(DATASETS_v1),$(call PROFILES_v1,$(dataset)))
	mkdir -p $(@D)
	heavyedge merge $^ -o $@
