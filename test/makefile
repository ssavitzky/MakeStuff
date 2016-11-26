### makefile for test
#
#  	Note that makefile is found before Makefile, so it's safe to link
#	../Makefile here for use in the subdirectories.
#
# 	Pre-initialization:  this directory contains symlinks to both Makefile
#	and MakeStuff.  It should be recognized as BASEDIR in all subdirectories.

SUITES = $(wildcard *.tests)
.PHONY:  $(SUITES) # $(subst .tests,.run, $(SUITES))

all::
	@echo suites available: $(SUITES)
	@echo run with "make NAME.run"

%.run:  %.tests
	$(MAKE) -f $< teardown 2>&1 | tee `basename $< tests`.log
	$(MAKE) -f $< run 2>&1 | tee -a `basename $< tests`.log

