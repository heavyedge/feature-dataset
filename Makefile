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

all: datasets examples

datasets: dataset-v1

examples: examples-v1

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

examples-v1: $(wildcard examples/v1/*.ipynb)

clean:
	rm -rf _temp benchmarks
	for dataset_dir in datasets/v*; do
		[ -d "$$dataset_dir" ] || continue
		find "$$dataset_dir" -mindepth 1 -maxdepth 1 ! -name datapackage.json -exec rm -rf -- {} +
	done
	for example_dir in examples/v*; do
		[ -d "$$example_dir" ] || continue
		find "$$example_dir" -mindepth 1 -maxdepth 1 ! -name '*.ipynb' -exec rm -rf -- {} +
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

_temp/v1/class_proba/mean_profiles.csv: $(foreach dataset,$(call DATASETS_v1,mean_profiles),_temp/v1/class_proba/mean_profiles/$(dataset).minirocket.sigmoid.csv)
	mkdir -p $(@D)
	python3 -c "import pandas as pd; dfs = [pd.read_csv(path) for path in '$^'.split()]; pd.concat(dfs).to_csv('$@', index=False)"

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

# Examples and Benchmarks

_temp/v1/mean_profiles.h5: $(foreach dataset,$(call DATASETS_v1,mean_profiles),_temp/v1/mean_profiles/$(dataset).h5)
	heavyedge merge $^ -o $@

_temp/v1/dimless.csv: scripts/v1/write-dimless.py $(shell ls _data/v1/process_variables/dataset*.csv) _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

_temp/v1/example_index.npy: scripts/v1/filter-dataset.py _temp/v1/dimless.csv
	python3 $^ -o $@

_temp/v1/shape_features/%.csv: $(foreach dataset,$(call DATASETS_v1,mean_profiles),_temp/v1/shape_features/mean_profiles/$(dataset).%.csv)
	mkdir -p $(@D)
	python3 -c "import pandas as pd; dfs = [pd.read_csv(path) for path in '$^'.split()]; pd.concat(dfs).to_csv('$@', index=False)"

_temp/v1/phi-index.npy: scripts/v1/phi-index.py _temp/v1/shape_features/minirocket.sigmoid.csv _temp/v1/class_proba/mean_profiles.csv
	python3 $^ -o $@

examples/v1/dimless.csv: _temp/v1/dimless.csv _temp/v1/example_index.npy
	python3 -c "import pandas as pd, numpy as np; df = pd.read_csv('$^'.split()[0]); idx = np.load('$^'.split()[1]); df.iloc[idx].to_csv('$@', index=False)"

examples/v1/shape_features/%.csv: _temp/v1/shape_features/%.csv _temp/v1/example_index.npy
	mkdir -p $(@D)
	python3 -c "import pandas as pd, numpy as np; df = pd.read_csv('$^'.split()[0]); idx = np.load('$^'.split()[1]); df.iloc[idx].to_csv('$@', index=False)"

examples/v1/phi-profiles.h5: _temp/v1/mean_profiles.h5 _temp/v1/phi-index.npy
	heavyedge filter $^ -o $@

examples/v1/classifier.ipynb: examples/v1/dimless.csv $(foreach method,$(CALIBRATION_METHODS_v1),examples/v1/shape_features/minirocket.$(method).csv) .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/phi.ipynb: .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/shape_features.ipynb: examples/v1/dimless.csv examples/v1/shape_features/minirocket.sigmoid.csv .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@
