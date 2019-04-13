### makefile for test
#
#  	Note that makefile is found before Makefile, so it's safe to link
#	../Makefile here for use in the subdirectories.
#
# 	Pre-initialization:  this directory contains symlinks to both Makefile
#	and MakeStuff.  It should be recognized as BASEDIR in all subdirectories.

SUITES = $(subst .tests,, $(shell ls *.tests))
.PHONY:  all run

all::
	@echo test suites available: $(SUITES)
	@echo run one suite with "make NAME.run"
	@echo run all suites with "make run"

run: $(addsuffix .run, $(SUITES))

%.run:  %.tests
	$(MAKE) -f $< teardown 2>&1 | tee `basename $< tests`.log
	$(MAKE) -f $< run 2>&1 | tee -a `basename $< tests`.log

