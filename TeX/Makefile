# Makefile for filksongs
#	$Id: Makefile,v 1.1 1996-02-18 16:38:56 steve Exp $
#
# Targets:  
#	all:		*.flk -> *.lj  (or all PR=.ps for postscript)
#	1song:		older way to print a song or group
#	zongbook:	the whole songbook
#
PR = .lj

# Wildcard expansion requires GNU make.
 
SONGS = $(wildcard [a-z]*.flk)
PRINT = $(subst .flk,$(PR),$(wildcard [a-z]*.flk))

EXAMPLE = alphabet.flk

########################################################################
###
### Rules:
###

.SUFFIXES: .tex .dvi .flk .txt .lj .ps

# tex to dvi:
# 	the "echo q" bit quits out of the error dialog if necessary;
# 	running latex twice makes sure the auxiliary files are up to date.
.tex.dvi:
	echo q |  latex $*
	if [ -f $*.toc ]; then echo q | latex $*; fi
	rm $*.log

.dvi.lj:
	dvilj $*.dvi 

.dvi.ps:
	dvips -o $*.ps $*.dvi 

# flk to tex:
#	Strictly speaking this isn't necessary; you shouldn't rebuild
#	foo.tex every time foo.flk changes.  But it's much simpler.
#	The style stuff should be in a header file.
.flk.tex:	
	echo '\documentstyle[12pt,song,twocolumns,zongbook]{article}' > $@
	echo '\begin{document}'		>> $@
	echo '\file{'$*.flk'}'		>> $@
	echo '\end{document}'		>> $@

.flk.txt:	
	chord < $*.flk > $@

########################################################################
###
### Targets
###

all:	$(PRINT) 

1song.dvi: song.sty $(SONGS)
zongbook.dvi: song.sty zongbook.sty $(SONGS)

texclean:
	-rm *.aux *.log *.toc *.dvi

clean ::
	-rm *.CKP *.ln *.BAK *.bak *.o core errs ,* *~ *.a \
		.emacs_* tags TAGS MakeOut *.odf *_ins.h \
		*.aux *.log *.toc *.dvi *.lj *.ps

