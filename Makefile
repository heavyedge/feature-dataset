.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets dataset-v1 clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

DATASETS_v1 = $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls -d _data/v1/$(1)/dataset* | xargs -n 1 basename))
PROCESS_VARIABLES_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),dataset1,$(shell ls _data/v1/process_variables/dataset*.csv | xargs -n 1 basename -s .csv))
CALIBRATION_METHODS_v1 := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),sigmoid,sigmoid isotonic sigmoid_ovo isotonic_ovo temperature)
HEAVYEDGE_BATCH_SIZE ?= 100
ACQUISITION_METHODS := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),EI,EI LCB_kappa_0.1 LCB_kappa_1 LCB_kappa_10 PI)
RF_N_ESTIMATORS := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),2,300)
BO_N_SIM := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),1,1000)
BO_N_BOOTSTRAP := $(if $(filter 1,$(HEAVYEDGE_TEST_MODE)),1,10000)
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

examples/v1/class_proba.csv: $(foreach dataset,$(call DATASETS_v1,mean_profiles),_temp/v1/class_proba/mean_profiles/$(dataset).minirocket.sigmoid.csv)
	mkdir -p $(@D)
	python3 -c "import pandas as pd; dfs = [pd.read_csv(path) for path in '$^'.split()]; pd.concat(dfs).to_csv('$@', index=False)"

_temp/v1/mean_profiles.h5: $(foreach dataset,$(call DATASETS_v1,mean_profiles),_temp/v1/mean_profiles/$(dataset).h5)
	heavyedge merge $^ -o $@

_temp/v1/phi-index.npy: scripts/v1/phi-index.py _temp/v1/shape_features/minirocket.sigmoid.csv examples/v1/class_proba.csv
	python3 $^ -o $@

_temp/v1/dimless.csv: scripts/v1/write-dimless.py $(foreach dataset,$(PROCESS_VARIABLES_v1),_data/v1/process_variables/$(dataset).csv) _data/v1/datapackage.json
	mkdir -p $(@D)
	python3 $^ -o $@

_temp/v1/example_index.npy: scripts/v1/filter-dataset.py _temp/v1/dimless.csv
	python3 $^ -o $@

_temp/v1/shape_features/%.csv: $(foreach dataset,$(call DATASETS_v1,mean_profiles),_temp/v1/shape_features/mean_profiles/$(dataset).%.csv)
	mkdir -p $(@D)
	python3 -c "import pandas as pd; dfs = [pd.read_csv(path) for path in '$^'.split()]; pd.concat(dfs).to_csv('$@', index=False)"

_temp/v1/shape_loss/%.csv: scripts/v1/shape-loss.py _temp/v1/shape_features/%.csv
	mkdir -p $(@D)
	python3 $^ --lambda_H=0.05 --lambda_b=0.01 --lambda_phi=1 -o $@

benchmarks/v1/MC.BO.EI.csv: scripts/v1/bo-simulate.py _temp/v1/dimless.csv _temp/v1/shape_loss/minirocket.sigmoid.csv
	mkdir -p $(@D)
	python3 $^ --acquisition=EI --n-estimators=$(RF_N_ESTIMATORS) --n-sim=$(BO_N_SIM) --n-jobs=$(FEATURE_JOBS) -o $@

benchmarks/v1/MC.BO.LCB_kappa_%.csv: scripts/v1/bo-simulate.py _temp/v1/dimless.csv _temp/v1/shape_loss/minirocket.sigmoid.csv
	mkdir -p $(@D)
	python3 $^ --acquisition=LCB --kappa=$* --n-estimators=$(RF_N_ESTIMATORS) --n-sim=$(BO_N_SIM) --n-jobs=$(FEATURE_JOBS) -o $@

benchmarks/v1/MC.BO.PI.csv: scripts/v1/bo-simulate.py _temp/v1/dimless.csv _temp/v1/shape_loss/minirocket.sigmoid.csv
	mkdir -p $(@D)
	python3 $^ --acquisition=PI --n-estimators=$(RF_N_ESTIMATORS) --n-sim=$(BO_N_SIM) --n-jobs=$(FEATURE_JOBS) -o $@

benchmarks/v1/Bootstrap.BO.%.csv: scripts/v1/bo-bootstrap.py benchmarks/v1/MC.BO.%.csv _temp/v1/shape_loss/minirocket.sigmoid.csv
	python3 $^ --num-bootstrap=$(BO_N_BOOTSTRAP) -o $@

examples/v1/phi-profiles.h5: _temp/v1/mean_profiles.h5 _temp/v1/phi-index.npy
	heavyedge filter $^ -o $@

examples/v1/phi-features.csv: _temp/v1/shape_features/minirocket.sigmoid.csv _temp/v1/phi-index.npy
	mkdir -p $(@D)
	python3 -c "import pandas as pd, numpy as np; df = pd.read_csv('$^'.split()[0]); idx = np.load('$^'.split()[1]); df.iloc[idx].to_csv('$@', index=False)"

examples/v1/phi-hist.csv: _temp/v1/shape_features/minirocket.sigmoid.csv
	mkdir -p $(@D)
	python3 -c "import pandas as pd, numpy as np; df = pd.read_csv('$^'); counts, edges = np.histogram(df['phi'], bins=40); pd.DataFrame({'counts': np.concatenate([counts, [np.nan]]), 'edges': edges}).to_csv('$@', index=False)"

examples/v1/dimless.csv: _temp/v1/dimless.csv _temp/v1/example_index.npy
	python3 -c "import pandas as pd, numpy as np; df = pd.read_csv('$^'.split()[0]); idx = np.load('$^'.split()[1]); df.iloc[idx].to_csv('$@', index=False)"

examples/v1/shape_features/%.csv: _temp/v1/shape_features/%.csv _temp/v1/example_index.npy
	mkdir -p $(@D)
	python3 -c "import pandas as pd, numpy as np; df = pd.read_csv('$^'.split()[0]); idx = np.load('$^'.split()[1]); df.iloc[idx].to_csv('$@', index=False)"

examples/v1/umap-embedding.csv: scripts/v1/embed-umap.py _temp/v1/mean_profiles.h5 examples/v1/class_proba.csv
	python3 $^ -o $@

# Notebooks

examples/v1/phi.ipynb: examples/v1/phi-profiles.h5 examples/v1/phi-features.csv examples/v1/phi-hist.csv .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/classifier.ipynb: examples/v1/dimless.csv $(foreach method,$(CALIBRATION_METHODS_v1),examples/v1/shape_features/minirocket.$(method).csv) .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/shape_features.ipynb: examples/v1/dimless.csv examples/v1/shape_features/minirocket.sigmoid.csv .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@

examples/v1/bo.ipynb: examples/v1/umap-embedding.csv $(foreach method,$(ACQUISITION_METHODS),benchmarks/v1/Bootstrap.BO.$(method).csv) .FORCE
	jupyter nbconvert --to notebook --execute --inplace $@
