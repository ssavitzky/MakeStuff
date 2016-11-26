### Makefile include for Lyrics directories
#
#   A Lyrics directory is mainly intended for making a printed songbook, so
#   we build Postscript files here.  HTML, text, and PDF files are built in
#   a Songs directory (see songs.make)

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

# WIP = work in progress
#	Note that we have to guard against the possibility that there are no
#	.flk files in the directory; that would make grep read from STDIN
#	if we let things get that far.
WIP := $(shell [ -z "$(ASONGS)" ] || grep -le '^\\tags.*\Wwip\W' $(ASONGS))

# ALLSONGS is the songs minus work in progress, which is usually what we want.
ALLSONGS := $(filter-out $(WIP), $(ASONGS))

# PD contains songs that aren't ours, but where both words and lyrics are
#   in the public domain, so we don't have to worry about rights.  Note that
#   it does _not_ include songs where one of (words|lyrics) is mine and 
#   the other is PD.  PD is used along with NOT_MINE to filter out songs to
#   which I have no IP except as arranger, and hence that don't belong
#   in /Steve_Savitzky/* or other publicly-accessible collections.
#
PD := $(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wpd\W' $(ALLSONGS))

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
SONGBOOK := $(OURS) $(MINE) $(PD)
OURSONGS := $(OURS) $(MINE)
WEBSONGS := $(OURS) $(MINE) $(WEB_OK) $(PD)

# SONGS are what we can put in a songbook or compilation CDROM
# 	The derived lists are PS, PDF, HTML, TEXT, and NAMES
PS    = $(subst .flk,.ps,$(SONGBOOK))
PDF   = $(subst .flk,.pdf,$(SONGBOOK))
NAMES = $(subst .flk,,$(SONGBOOK))
HTML  = $(subst .flk,.html,$(SONGBOOK))
PRINT = $(PS)

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
ALLDIRS  = $(patsubst %,../Songs/%,$(ALLNAMES))
ALLHTML  = $(patsubst %,../Songs/%/lyrics.html,$(ALLNAMES))
ALLTEXT  = $(patsubst %,../Songs/%/lyrics.txt,$(ALLNAMES))
ALLPRINT = $(ALLPS)

# For publishing on the web, $(WEBSONGS) excludes NOTMINE but includes OK

WEBNAMES = $(subst .flk,,$(WEBSONGS))
WEBDIRS  = $(patsubst %,../Songs/%,$(WEBNAMES))
WEBPS    = $(subst .flk,.ps,$(WEBSONGS))
WEBPDF   = $(patsubst %,../Songs/%/lyrics.pdf,$(WEBNAMES))
WEBHTML  = $(patsubst %,../Songs/%/lyrics.html,$(WEBNAMES))
WEBTEXT  = $(patsubst %,../Songs/%/lyrics.txt,$(WEBNAMES))
WEBPRINT = $(WEBPS) $(WEBPDF)
WEBINDICES = 0Index.html 0IndexTable.html 0IndexShort.html

# Where it ends up on the website.  
#    We use this when we need to make absolute links.
#    FIXME: this has to come out of site/config.make
WEBSITE  = http://Steve.Savitzky.net
WEBDIR   = /Songs

# What to publish on the web:
PUBFILES = $(WEBHTML) $(WEBPS) $(WEBPDF) $(WEBINDICES)

# Utility programs:
FLKTRAN   = $(TOOLDIR)/TeX/flktran.pl
INDEX     = $(TOOLDIR)/TeX/index.pl
TRACKINFO = $(TOOLDIR)/TrackInfo.pl

########################################################################
###
### Rules:
###

ECHO=/bin/echo

# flk to tex:
#	Strictly speaking this isn't necessary; you shouldn't rebuild
#	foo.tex every time foo.flk changes.  But it reduces clutter in
#	the working directory and keeps filename completion from stopping
#	to ask whether I meant .flk or .tex.
%.tex:	%.flk	
	@$(ECHO) \\'documentstyle[$(SIZE)song,twocolumns,zongbook]{article}' > $@
	@$(ECHO) \\'special{papersize=8.5in,11in}'	>> $@
	@$(ECHO) \\'begin{document}'			>> $@
	$(ECHO)  \\'file{$*.flk}'			>> $@
	@$(ECHO) \\'end{document}'			>> $@

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
# Lyrics and Songs have different include files

all::
	@echo building for direct upload in Lyrics and ../Songs
all::	$(ALLPRINT) $(INDICES) 
all::  $(wildcard *.pdf)

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

reportVars += NAMES ALLNAMES WEBNAMES

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
	-rm -f $(WEBINDICES) $(INDICES)
	-rm -f $(ALLHTML)
	-rm -f $(ALLTEXT)

.PHONY: pubclean htmlclean

pubclean::
	-rm -f $(ALLHTML)
	-rm -f $(ALLTEXT) $(WEBINDICES) $(INDICES)

htmlclean::
	-rm -f $(ALLHTML)

### Setup:

# Imports (for LaTeX)

IMPORTS= song.sty twocolumns.sty zongbook.sty

imports: $(IMPORTS)

song.sty: $(TOOLDIR)/TeX/song.sty
	ln -s $(TOOLDIR)/TeX/song.sty .

twocolumns.sty: $(TOOLDIR)/TeX/twocolumns.sty
	ln -s $(TOOLDIR)/TeX/twocolumns.sty .

zongbook.sty: $(TOOLDIR)/TeX/zongbook.sty
	ln -s $(TOOLDIR)/TeX/zongbook.sty .

### Website indices:

# .htaccess just has titles
.htaccess: $(WEBSONGS)
	$(INDEX) -dsc -o $@ $(WEBSONGS)

# === These really need to be done using templates or defines ===

0List.html: $(WEBSONGS) Makefile $(INDEX)
	@echo building $@ from WEBSONGS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song List</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Lyrics</a>'		>> $@
	@echo '  / Song List</h1>'			>> $@
	@$(INDEX) -h  $(WEBSONGS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

0Index.html: $(WEBSONGS) $(OGGS) $(MP3S) Makefile $(INDEX)
	@echo building $@ from WEBSONGS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song Index</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Lyrics</a>'		>> $@
	@echo '  / Song Index</h2>'			>> $@
	@$(INDEX) -t -h $(WEBSONGS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

0IndexTable.html: $(WEBSONGS) $(OGGS) $(MP3S) Makefile $(INDEX)
	@echo building $@ from WEBSONGS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h $(WEBSONGS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

0IndexShort.html: $(WEBSONGS) Makefile
	@echo building $@ from WEBSONGS
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(WEBNAMES) | tr ' ' "\n" | sort | uniq`; do \
		echo '<a href="'../Songs/$$f/'">'$$f'</a>' >> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

1Index.html: $(ALLSONGS) $(OGGS) $(MP3S) Makefile $(INDEX)
	@echo building $@ from ALLSONGS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song Index</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Lyrics</a>'		>> $@
	@echo '  / Complete Index</h2>'			>> $@
	@$(INDEX) -t -h $(ALLSONGS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

1IndexTable.html: $(ALLSONGS) $(OGGS) $(MP3S)  Makefile $(INDEX)
	@echo building $@ from ALLSONGS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h $(ALLSONGS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

1IndexShort.html: $(ALLSONGS) Makefile
	@echo building $@ from ALLSONGS
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(ALLNAMES) | tr ' ' "\n" | sort | uniq`; do \
		echo '<a href="'../Songs/$$f/'">'$$f'</a>' >> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

