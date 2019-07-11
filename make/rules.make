#!/usr/bin/make  ### rules.make - basic rule set for makefiles
#
# This file is meant to be included by Tools/Makefile, and defines a
# generally-useful collection of rules that should cover most cases.
#


### music specific rules and defines ###
#
#	We need this first because rule inference appears to be order-
#	dependent.  If we see the %.pdf: $.ps first, we won't try to
#	use %pdf: %flk.  This is not how I always thought it worked,
#	but there you have it.

ifdef MUSIC_D
  musicIncludes = $(addprefix $(MUSIC_D)/,$(MUSIC_D_INCLUDES))
  -include $(musicIncludes)
endif

### .tex to various output formats
# 	the "echo q" bit quits out of the error dialog if necessary;
# 	running latex for a  second time makes sure the most recent 
#	auxiliary file has been included -- we only need it if the 
#	.aux file is nontrivial.

%.pdf:	%.tex
	echo q | pdflatex $*
	if [ -f $*.aux ] && [ `wc -l $*.aux | cut -d " " -f 1` -gt 0 ];\
		then echo q|pdflatex $*; fi
	-rm -f $*.aux $*.log

%.dvi:	%.tex
	echo q | pdflatex $*
	if [ -f $*.aux ] && [ `wc -l $*.aux | cut -d " " -f 1` -gt 0 ];\
		then echo q|pdflatex $*; fi
	-rm -f $*.aux $*.log

# dvi to ps

%.ps:	%.dvi
	dvips -q -o $*.ps $*.dvi 

# ps to pdf

%.pdf:	%.ps
	ps2pdf $*.ps $*.pdf

%.eps: %.ps
	rm -f $@
	ps2eps $<

%.pdf: %.eps
	 ps2pdf $<

###### end of rules.make ######
