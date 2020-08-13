### makefile for MakeStuff/test
#
#  	Note that makefile is found before Makefile, so it's safe to link
#	../Makefile here for use in the subdirectories.  It's needed there
#	because that's what we're testing.
#
# 	Pre-initialization:  this directory contains symlinks to both Makefile
#	and MakeStuff.  It should be recognized as BASEDIR in all subdirectories.

SUITES = $(basename $(wildcard *.tests))

# all just tells you what you can do.
all::
	@echo test suites available: $(SUITES)
	@echo targets available:  run, teardown, clean, SUITE.run SUITE.teardown
	@echo "make clean" tears down tests and removes logs

### targets:  run, teardown, clean
.PHONY:  all run teardown

run: $(addsuffix .run, $(SUITES))

teardown: $(addsuffix .teardown, $(SUITES))

clean:: teardown

clean::
	rm -f *.log

### rules for SUITE.run and SUITE.teardown

%.run:  %.tests
	$(MAKE) -f $< run 2>&1

%.teardown:  %.tests
	$(MAKE) -f $< teardown 2>&1

