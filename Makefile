.ONESHELL:
.SECONDEXPANSION:
.SECONDARY:
.PHONY: all datasets examples clean .FORCE
# Dummy target to ensure that prerequisite files are built.
.FORCE:

all: datasets examples

datasets: dataset-v1

examples: examples-v1

clean:
	rm -rf _temp benchmarks
	for dataset_dir in datasets/v*; do
		[ -d "$$dataset_dir" ] || continue
		find "$$dataset_dir" -mindepth 1 -maxdepth 1 ! -name datapackage.json -exec rm -rf -- {} +
	done

include make/v1.mk