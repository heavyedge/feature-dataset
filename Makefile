.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets dataset-v1 clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASETS_v1 = $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/$(1)/dataset* | xargs -n 1 basename))
CALIBRATION_METHODS_v1 := sigmoid isotonic sigmoid_ovo isotonic_ovo temperature
HEAVYEDGE_BATCH_SIZE ?= 100
FEATURE_JOBS ?= 1

all: datasets

datasets: dataset-v1

dataset-v1: \
$(foreach \
	target, \
	$(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),mean_profiles,profiles mean_profiles), \
	$(foreach \
		dataset, \
		$(call DATASETS_v1,$(target)), \
		datasets/v1/shape_features/$(target)/$(dataset).csv \
	) \
)

clean:
	rm -rf _temp benchmarks
	for dataset_dir in datasets/v*; do
		[ -d "$$dataset_dir" ] || continue
		find "$$dataset_dir" -mindepth 1 -maxdepth 1 ! -name datapackage.json -exec rm -rf -- {} +
	done


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
		$(call DATASETS_v1,$(target)), \
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
		$(call DATASETS_v1,$(target)), \
		$(foreach \
			method, \
			$(CALIBRATION_METHODS_v1), \
			$(eval $(call CLASS_PROBABILITIES_v1,$(target),$(dataset),$(method))) \
		) \
	) \
)

# e.g., _temp/v1/wet_thickness/mean_profiles/dataset1.csv
define WET_THICKNESS_v1
_temp/v1/wet_thickness/$(1)/$(2).csv: scripts/v1/wet-thickness.py _data/v1/$(1)/$(2) _data/v1/process_variables/$(2).csv _data/v1/datapackage.json
	mkdir -p $$(@D)
	python3 $$^ -o $$@
endef
$(foreach \
	target, \
	profiles mean_profiles, \
	$(foreach \
		dataset, \
		$(call DATASETS_v1,$(target)), \
		$(eval $(call WET_THICKNESS_v1,$(target),$(dataset))) \
	) \
)

# e.g., _temp/v1/shape_features/mean_profiles/dataset1.minirocket.sigmoid.csv
define SHAPE_FEATURES_v1
_temp/v1/shape_features/$(1)/$(2).minirocket.$(3).csv: _temp/v1/$(1)/$(2).h5 _temp/v1/wet_thickness/$(1)/$(2).csv _temp/v1/class_proba/$(1)/$(2).minirocket.$(3).csv config/v1/shape-features.yml 
	mkdir -p $$(@D)
	heavyedge --log-level=INFO shape-features $$(wordlist 1,3,$$^) --config $$(lastword $$^) --n-jobs=$(FEATURE_JOBS) -o $$@
endef
$(foreach \
	target, \
	profiles mean_profiles, \
	$(foreach \
		dataset, \
		$(call DATASETS_v1,$(target)), \
		$(foreach \
			method, \
			$(CALIBRATION_METHODS_v1), \
			$(eval $(call SHAPE_FEATURES_v1,$(target),$(dataset),$(method))) \
		) \
	) \
)

datasets/v1/shape_features/%.csv: _temp/v1/shape_features/%.minirocket.sigmoid.csv
	mkdir -p $(@D)
	cp $< $@

benchmarks/v1/mean_profiles/shape_features.csv: datasets/v1/shape_features/mean_profiles/dataset1.csv datasets/v1/shape_features/mean_profiles/dataset2.csv datasets/v1/shape_features/mean_profiles/dataset3.csv datasets/v1/shape_features/mean_profiles/dataset4.csv datasets/v1/shape_features/mean_profiles/dataset5.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd; dfs = [pd.read_csv(path) for path in '$^'.split()]; pd.concat(dfs).to_csv('$@', index=False)"

examples/v1/shape_features.ipynb: benchmarks/v1/mean_profiles/shape_features.csv
