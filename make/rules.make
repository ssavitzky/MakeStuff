#!/usr/bin/make  ### rules.make - basic rule set for makefiles
#
# This file is meant to be included by Tools/Makefile, and defines a
# generally-useful collection of rules that should cover most cases.
#


### .tex to various output formats
# 	the "echo q" bit quits out of the error dialog if necessary;
# 	running latex for a  second time makes sure the most recent 
#	auxiliary file has been included -- we only need it if the 
#	.aux file is nontrivial.

%.dvi:	%.tex
	echo q | latex $*
	@if [ -f $*.aux ] && [ `wc -l $*.aux` -gt 1 ]; then \
	    echo q | latex $*; fi

# dvi to ps

%.ps:	%.dvi
	dvips -o $*.ps $*.dvi 

# ps to pdf

%.pdf:	%.ps
	ps2pdf $*.ps $*.pdf

%.eps: %.ps
	rm -f $@
	ps2eps $<

%.pdf: %.eps
	 ps2pdf $<

###### end of rules.make ######
