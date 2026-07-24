.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets dataset-v1 clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASETS_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/profiles/dataset* | xargs -n 1 basename))
CALIBRATION_METHODS_v1 := sigmoid isotonic sigmoid_ovo isotonic_ovo temperature
HEAVYEDGE_BATCH_SIZE ?= 100

all: datasets

datasets: dataset-v1

dataset-v1:

clean:
	rm -rf _temp datasets/v*


# e.g., _temp/v1/mean_profiles/dataset1.h5
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

# e.g., _temp/v1/class_proba/mean_profiles/dataset1.minirocket.sigmoid.csv
define CLASS_PROBABILITIES_v1
_temp/v1/class_proba/$(1)/$(2).minirocket.$(3).csv: _temp/v1/$(1)/$(2).h5 _models/classifiers/minirocket.$(3).pkl
	mkdir -p $$(@D)
	heavyedge --log-level=INFO classify-predict --batch-size=$(HEAVYEDGE_BATCH_SIZE) $$^ -o $$@
endef
$(foreach \
	target, \
	profiles mean_profiles, \
	$(foreach \
		dataset, \
		$(DATASETS_v1), \
		$(foreach \
			method, \
			$(CALIBRATION_METHODS_v1), \
			$(eval $(call CLASS_PROBABILITIES_v1,$(target),$(dataset),$(method))) \
		) \
	) \
)

# e.g., _temp/v1/global-features/mean_profiles/dataset1.minirocket.sigmoid.csv
_temp/v1/global-features/%.csv: _temp/v1/class_proba/%.csv config/v1/features-global.yml
	mkdir -p $(@D)
	heavyedge --log-level=INFO features-global $< --config $(lastword $^) -o $@

# e.g., _temp/v1/wet-thickness/dataset1.npy
_temp/v1/wet-thickness/%.npy: scripts/v1/wet-thickness.py _data/v1/process_variables/%.csv _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@
