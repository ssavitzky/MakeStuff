### Makefile include for Lyrics directories
#
#   A Lyrics directory is mainly intended for making a printed songbook, so
#   we build PDF files here.  HTML and tex are built in a Songs directory
#   (see songs.make)

# 12pt is too big for: crypto.flk stuff.flk
SIZE = 12pt,
#SIZE = 

### Song lists:
#
#   ASONGS   -- all songs (all .flk files)
#   ZSONGS   -- all songs in zongbook.txt, in sequence.  
#		(nominmally alphabetical, with a couple of duplicates)
#   MYSONGS  -- just mine, not PD or ok-to-publish
#   SONGS    -- stuff that's OK to put in a songbook: mine and PD
#   WEBSONGS -- Adds $(OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but in-progress songs

# === need to drop the .flk and, ideally, generate the lists from metadata
# === need to drop zongbook.tex and generate that from metadata, too.

# ASONGS is just the song files, alphabetical by filename.
#   This works in lgf and tg because we're not using Steve's
#   cryptic shortnames.
#   Note that template files start with a digit, so the wildcard skips them
ASONGS := $(filter-out %--%, $(wildcard [a-z]*.flk))

# ugly shell pipeline to sort a list of song references.
SORT_SONGS =  sed 's/ /\n/g' | sed 's/\// /g' | sort | sed 's/ /\//g'

# WIP = work in progress
#	Note that we have to guard against the possibility that there are no
#	.flk files in the directory; that would make grep read from STDIN
#	if we let things get that far.
WIP := $(shell [ -z "$(ASONGS)" ] || grep -ile '^\\tags.*\Wwip\W' $(ASONGS))

# ALLSONGS is the songs minus work in progress, which is usually what we want.
ALLSONGS := $(shell echo $(filter-out $(WIP), $(ASONGS)) | $(SORT_SONGS))

# PD contains songs that aren't ours, but where both words and lyrics are
#   in the public domain, so we don't have to worry about rights.  Note that
#   it does _not_ include songs where one of (words|lyrics) is mine and 
#   the other is PD.  PD is used along with NOT_MINE to filter out songs to
#   which I have no IP except as arranger, and hence that don't belong
#   in /Steve_Savitzky/* or other publicly-accessible collections.
#
PD := $(shell [ -z "$(ALLSONGS)" ] || grep -ile '^\\tags.*\Wpd\W' $(ALLSONGS))

# OURS contains songs in which a band member has sufficient rights to
#   allow us to publish the lyrics on the web.
#
OURS := $(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wours\W' $(ALLSONGS))

# MINE contains songs ganked from one bandmember or another, typically
#   Steve.  Add it to OURS
#
MINE := $(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wmine\W'  $(ALLSONGS))

# WEB_OK contains songs that aren't PD, and aren't "ours", but which by 
#   one means or another we have acquired permission to post on the site.
#
WEB_OK :=$(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wweb-ok\W'  $(ALLSONGS))

# Songlists:
#   SONGBOOK -- stuff that's OK to put in a songbook
#   OURSONGS -- just ours, not PD or ok-to-publish
#   WEBSONGS -- Adds $(WEB_OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but work in progress
SONGBOOK := $(shell echo $(OURS) $(MINE) $(PD) | $(SORT_SONGS))
OURSONGS := $(shell echo $(OURS) $(MINE) | $(SORT_SONGS))
WEBSONGS := $(shell echo $(OURS) $(MINE) $(WEB_OK) $(PD) | $(SORT_SONGS))

# SONGS are what we can put in a songbook or compilation CDROM
# 	The derived lists are PS, PDF, HTML, TEXT, and NAMES
PS    = $(subst .flk,.ps,$(SONGBOOK))
PDF   = $(subst .flk,.pdf,$(SONGBOOK))
NAMES = $(subst .flk,,$(SONGBOOK))
HTML  = $(subst .flk,.html,$(SONGBOOK))
PRINT = $(PDF)

#	OGGS is also derived from SONGS, but only _includes_ what's here
OGGS  = $(wildcard *.ogg)
MP3S  = $(wildcard *.mp3)

# 	1Index.html is the index web page, 1IndexTable.html is just the
#	 <table> element, for use in template replacement.
INDICES= 1Index.html 1IndexTable.html 1IndexShort.html 
OTHER  = Makefile HEADER.html

# For personal songbook: $(ALLSONGS) just excludes incomplete stuff
ALLNAMES = $(subst .flk,,$(ALLSONGS))
ALLPS    = $(subst .flk,.ps,$(ALLSONGS))
ALLPDF   = $(subst .flk,.pdf,$(ALLSONGS))
ALLPRINT = $(ALLPDF)

# For publishing on the web, $(WEBSONGS) excludes NOTMINE but includes OK

WEBNAMES = $(subst .flk,,$(WEBSONGS))
WEBDIRS  = $(patsubst %,../Songs/%,$(WEBNAMES))
WEBPS    = $(subst .flk,.ps,$(WEBSONGS))
WEBPRINT = $(WEBPDF)

# What to publish on the web:
PUBFILES = $(WEBHTML) $(WEBPS) $(WEBPDF) $(WEBINDICES)

# Utility programs:
TEXDIR	  = $(TOOLDIR)/TeX
FLKTRAN   = $(TEXDIR)/flktran.pl
INDEX     = $(TEXDIR)/index.pl
TRACKINFO = $(TOOLDIR)/music/TrackInfo.pl
LATEX	  = latex

########################################################################
###
### Rules:
###

ECHO=/bin/echo

# flk to dvi:
# 	Rather than make a temporary .tex file, we basically unroll both that and
#	the existing \file macro, neither of which is particularly useful in this
#	case.  \file has been simplified to reflect the fact that songs no longer
#	contain a document environment, just a song environment; it's meant to be
#	used in songbooks.
#
SONG_LATEX =  echo q | TEXINPUTS=.:$(TEXDIR):$$TEXINPUTS $(LATEX)
SONG_PDFLATEX =  echo q | TEXINPUTS=.:$(TEXDIR):$$TEXINPUTS pdf$(LATEX)
SONG_PREAMBLE = '\documentclass[$(SIZE)letterpaper]{article}'			\
		'\usepackage{song,zongbook}'

.SUFFIX: flk

%.pdf:	%.flk
	$(SONG_PDFLATEX) -jobname $* $(SONG_PREAMBLE) 	\
		      \\'begin{document}' \\'input{$<}' \\'end{document}'
	rm -f $*.log $*.aux

%/lyrics.pdf:	%.flk
	$(SONG_PDFLATEX) -jobname $* $(SONG_PREAMBLE) \\'def\\theFile{$<}' 	\
		      \\'begin{document}' \\'input{$<}' \\'end{document}'
	rm -f $*.log $*.aux

%.dvi:	%.flk
	$(SONG_LATEX) -jobname $* $(SONG_PREAMBLE) \\'def\\theFile{$<}' 	\
		      \\'begin{document}' \\'input{$<}' \\'end{document}'
	rm -f $*.log $*.aux

# Ogg and mp3 files.  
#	They have no dependencies to prevent their being constantly rebuilt.
#	It might be better to make the mp3s depend on the oggs.
%.ogg: 
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg  $*)
%.mp3: 
	sox $(shell $(TRACKINFO) format=files $*) -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 $*) $@

########################################################################
###
### Targets
###

# We no longer have to worry about which flavor of directory we're in;
# Lyrics and Songs have different include files.  Similarly, don't bother
# building index files -- that's not something we need here.

all::
	@echo building postscript files
all::	$(ALLPRINT)

.PHONY: dirs html text postscript ps
dirs: 	$(ALLDIRS)
html: 	$(FLKTRAN) $(HTML)
text:	$(FLKTRAN) $(TEXT)
postscript: $(PS)
ps:	$(PS)

.PHONY: indices webindices pubfiles

indices: $(INDICES) $(WEBINDICES) 
webindices: $(WEBINDICES)
pubfiles: $(PUBFILES)

### Lists:

list-names:
	@echo $(NAMES)
list-songs: 
	@echo $(SONGBOOK)
list-allsongs: 
	@echo $(ALLSONGS)
list-oursongs: 
	@echo $(OURSONGS)
list-websongs: 
	@echo $(WEBSONGS)

reportVars += NAMES ALLNAMES WEBNAMES SONGBOOK ASONGS WIP

### Songbook:  Just my stuff and public domain.  
#   Longbook:  same, but with notes.

#	public HTML index file for that.

# Songbook: a songbook with just the lyrics and chords, not the notes
songbook: $(PS) 
	lp $(PS)

# Longbook: a songbook that includes the extra pages of notes
longbook: $(PS) 
	@for f in $(PS) ; do lpr $$f ; done 

# songlists:

songlist.txt:$(ALLSONGS) Makefile
	@echo building $@ from ALLSONGS
	@$(TOOLDIR)/Setlist.cgi $(ALLSONGS) > $@

### filkbook: make a printed songbook with everything in it.
filkbook: $(ALLPS)
	lp $(ALLPS)

### Cleanup:

clean::
	-rm -f *.ps *.pdf

### end lyrics.make ###

