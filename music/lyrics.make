### Makefile include for Lyrics directories
#
# Hacked from users/steve/Lyrics/Makefile.  

# By default the HTML, and text files are built in ../Songs/*/lyrics.[ext]
#   Postscript files are built here, and PDF files are built in both.
#   This meahs that it's easy to edit and print in this directory, while
#   all the web stuff ends up in ../Songs.
#
#   Eventually we ought to rejigger things so that we actually build
#   the individual song directories from Songs; that would make it possible
#   to have multiple export directories, possibly on different websites.

# The main difference between this and the original in users/steve is that
#   it (finally) uses tags (originally category, but I'd already started 
#   using it as a tags field) to define the song lists rather than requiring
#   them to be in the Makefile.

#   In the original, a tag of "long" indicates a song that needs to be printed
#   on multiple pages.  we don't bother here -- almost everything is long and
#   we don't have extraneous notes anyway -- it's all stuff we need for
#   performances and in-group discussions.

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

# WIP = work in progress
WIP := $(shell grep -le '^\\tags.*\Wwip\W' *.flk)

# PD contains songs that aren't ours, but where both words and lyrics are
#   in the public domain, so we don't have to worry about rights.  Note that
#   it does _not_ include songs where one of (words|lyrics) is mine and 
#   the other is PD.  PD is used along with NOT_MINE to filter out songs to
#   which I have no IP except as arranger, and hence that don't belong
#   in /Steve_Savitzky/* or other publicly-accessible collections.
#
PD := $(shell grep -le '^\\tags.*\Wpd\W' *.flk)

# OURS contains songs in which a band member has sufficient rights to
#   allow us to publish the lyrics on the web.
#
OURS := $(shell grep -le '^\\tags.*\Wours\W' *.flk)

# MINE contains songs ganked from one bandmember or another, typically
#   Steve.  Add it to OURS
#
MINE := $(shell grep -le '^\\tags.*\Wmine\W' *.flk)

# WEB_OK contains songs that aren't PD, and aren't "ours", but which by 
#   one means or another we have acquired permission to post on the site.
#
WEB_OK :=$(shell grep -le '^\\tags.*\Wweb-ok\W' *.flk)


# ASONGS is just the song files, alphabetical by filename.
#   This works in lgf and tg because we're not using Steve's
#   cryptic shortnames.
#   Note that template files start with a digit, so the wildcard skips them
ASONGS := $(shell ls [-a-z]*.flk | grep -ve '--' )

# Compute the song lists by filtering out work in progress
#   SONGS    -- stuff that's OK to put in a songbook
#   OURSONGS -- just ours, not PD or ok-to-publish
#   WEBSONGS -- Adds $(WEB_OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but work in progress
SONGS    := $(filter-out $(WIP), $(shell ls $(OURS) $(MINE) $(PD)))
OURSONGS := $(filter-out $(WIP), $(OURS) $(MINE))
WEBSONGS := $(filter-out $(WIP), $(shell ls $(OURS)  $(MINE) $(WEB_OK) $(PD)))
ALLSONGS := $(filter-out $(WIP), $(ASONGS))

# SONGS are what we can put in a songbook or compilation CDROM
# 	The derived lists are PS, PDF, HTML, TEXT, and NAMES
PS    = $(subst .flk,.ps,$(SONGS))
PDF   = $(subst .flk,.pdf,$(SONGS))
NAMES = $(subst .flk,,$(SONGS))
HTML  = $(subst .flk,.html,$(SONGS))
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
FLKTRAN  = $(TOOLDIR)/TeX/flktran.pl
INDEX    = $(TOOLDIR)/TeX/index.pl
TRACKINFO = $(TOOLDIR)/TrackInfo.pl

########################################################################
###
### Rules:
###

.SUFFIXES: .tex .dvi .flk .txt .lj .ps .pdf .html .ogg

# should decide whether to make the symlink based on whether I have rights
# to the song; if I don't we make a dummy web page instead, to allow the
# pdf and txt versions of the lyrics to go forward.
#
../Songs/%/index.html:
	[ -d `dirname $@` ] || mkdir `dirname $@`
	cd `dirname $@`; [ -e lyrics.html ] && ln -s lyrics.html index.html

../Songs/%/lyrics.pdf: %.ps
	ps2pdf $< $@

# flk to HTML, Text.
#	Note that there are still serious problems with these.
#
../Songs/%/lyrics.html: %.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(WEBDIR) $(FLKTRAN) $< $@

../Songs/%/lyrics.txt: %.flk 
	WEBSITE=$(WEBSITE) WEBDIR=$(WEBDIR) $(FLKTRAN) $< $@

.flk.txt:	
	chord < $*.flk > $@

ECHO=/bin/echo

# flk to tex:
#	Strictly speaking this isn't necessary; you shouldn't rebuild
#	foo.tex every time foo.flk changes.  But it reduces clutter in
#	the working directory and keeps filename completion from stopping
#	to ask whether I meant .flk or .tex.
.flk.tex:	
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
	@echo $(SONGS)
list-allsongs: 
	@echo $(ALLSONGS)
list-oursongs: 
	@echo $(OURSONGS)
list-websongs: 
	@echo $(WEBSONGS)

reportVars += NAMES

### Songbook:  Just my stuff and public domain.  
#   Longbook:  same, but with notes.
#	Note that the Songbook doesn't have a proper index -- use the 
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

IMPORTS= song.sty twocolumns.sty

imports: $(IMPORTS)

song.sty: $(TOOLDIR)/TeX/song.sty
	ln -s $(TOOLDIR)/TeX/song.sty .

twocolumns.sty: $(TOOLDIR)/TeX/twocolumns.sty
	ln -s $(TOOLDIR)/TeX/twocolumns.sty .

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

