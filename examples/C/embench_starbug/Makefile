# Only directories that actually contain a benchmark. Filtering just common/
# swept logs/ and presentation_assets/ into the build and made every top-level
# target report two spurious failures.
BENCHMARK_DIRS := $(patsubst %/Makefile,%,$(filter-out common/Makefile,$(wildcard */Makefile)))

.PHONY: all scalar-wally empty-wally vliw-wally starbug-compile empty-starbug seed-vliw-asm dump clean verify verify-vliw verify-starbug questa-vliw-check

all: scalar-wally empty-wally starbug-compile empty-starbug

scalar-wally empty-wally vliw-wally starbug-compile empty-starbug seed-vliw-asm dump clean:
	@for bench in $(BENCHMARK_DIRS); do \
		$(MAKE) -C $$bench $@ || exit $$?; \
	done

# Unlike the build targets, keep going after a failure: the point of a verify
# sweep is to see every illegal bundle in the tree, not just the first one.
verify verify-vliw verify-starbug:
	@rc=0; for bench in $(BENCHMARK_DIRS); do \
		$(MAKE) --no-print-directory -C $$bench $@ || rc=1; \
	done; \
	if [ $$rc -ne 0 ]; then echo "verify: at least one binary has illegal bundles"; fi; \
	exit $$rc

questa-vliw-check:
	python3 ./run_questa_vliw.py $(ARGS)
