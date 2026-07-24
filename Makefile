.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets dataset-v1 clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASETS_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/profiles/dataset* | xargs -n 1 basename))
HEAVYEDGE_BATCH_SIZE ?= 100

all: datasets

datasets: dataset-v1

dataset-v1:

clean:
	rm -rf _temp datasets/v*

define MERGE_PROFILES_v1
_temp/v1/$(1)/$(2).h5: $(shell ls _data/v1/$(1)/$(2)/*.h5)
	mkdir -p $$(@D)
	heavyedge merge $$^ -o $$@
endef
$(foreach \
	target, \
	profiles mean_profiles, \
	$(foreach \
		dataset, \
		$(DATASETS_v1), \
		$(eval $(call MERGE_PROFILES_v1,$(target),$(dataset))) \
	) \
)

_temp/v1/class_probabilities/%.csv: _temp/v1/%.h5 _models/classifiers/minirocket.sigmoid.pkl
	mkdir -p $(@D)
	heavyedge --log-level=INFO classify-predict --batch-size=$(HEAVYEDGE_BATCH_SIZE) $^ -o $@
