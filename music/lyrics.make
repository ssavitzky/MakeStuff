### Makefile include for Lyrics directories
#
#   A Lyrics directory is mainly intended for making a printed songbook, so
#   we build PDF files here.  HTML and tex are built in a Songs directory
#   (see songs.make)

# 12pt is too big for: crypto.flk stuff.flk
SIZE = 12pt,
#SIZE = 


### Utility programs:
TEXDIR	  = $(TOOLDIR)/TeX
LATEX	  = latex -file-line-error
PDFLATEX  = pdflatex -file-line-error
SORT_BY_TITLE = $(TEXDIR)/sort-by-title

### Song lists:
#
#   ASONGS   -- all songs (all .flk files)
#   ALLSONGS -- everything but in-progress songs
#   ZSONGS   -- all songs in zongbook.txt, in sequence.  
#		(nominmally alphabetical, with a couple of duplicates)
#   MYSONGS  -- just mine, not PD or ok-to-publish
#   SONGS    -- stuff that's OK to put in a songbook: mine and PD

# === need to drop the .flk and, ideally, generate the lists from metadata
# === need to drop zongbook.tex and generate that from metadata, too.

# ugly shell pipeline to sort a list of file names.  Not used
SORT_BY_FILENAME =  sed 's/ /\n/g' | sed 's/\// /g' | sort | sed 's/ /\//g'

# ASONGS is just the song files, alphabetical by filename.
#   This works in lgf and tg because we're not using Steve's
#   cryptic shortnames.
#   Note that template files start with a digit, so the wildcard skips them
ASONGS := $(shell $(SORT_BY_TITLE) $(wildcard [a-z]*.flk))

# WIP = work in progress
#	Note that we have to guard against the possibility that there are no
#	.flk files in the directory; that would make grep read from STDIN
#	if we let things get that far.
WIP := $(shell [ -z "$(ASONGS)" ] || grep -ile '^\\tags.*\Wwip\W' $(ASONGS))

# TRANSPOSED
#	We use "--X" to indicate songs that have been transposed into the key
#	of X, and occasionally for other purposes, eg, --orig.  They are
#	usually printed out only for musicians who like to see the chords in
#	the concert key rather than the capoed key, so that they don't have
#	to transpose on the fly.
#	
TRANSPOSED := $(wildcard *--*.flk)

# PD contains songs that aren't ours, but where both words and lyrics are
#   in the public domain, so we don't have to worry about rights.  Note that
#   it does _not_ include songs where one of (words|lyrics) is mine and 
#   the other is PD.
#
PD := $(shell [ -z "$(ALLSONGS)" ] || grep -ile '^\\tags.*\Wpd\W' $(ALLSONGS))

# There isn't a good way to separate out "our" or "my" songs; in my main website
#   the Lyrics directory is all my stuff, and there are separate Lyrics-PD,
#   Lyrics-Other, and Lyrics-WIP directories.  That's a good organization if
#   you want to put a songbook on the web.
#
#   My various bands, tg and lgf, use tags to distinguish songs for which they
#   have rights to post lyrics on the site.  When preparing a personal or band
#   songbook, you naturally want to include everything in your repertoire.
#   That's the default here.  What goes on the website is determined in a
#   /Songs directory -- see songs.make for the details.


# ALLSONGS is the songs minus work in progress, which is usually what we want.
ALLSONGS := $(filter-out $(WIP), $(ASONGS))

SONGBOOK := $(filter-out $(TRANSPOSED), $(ALLSONGS))

# SONGS are the ones that go into a printed songbook or up on a website.
# 	The derived lists are PS, PDF, HTML, TEXT, and NAMES
PS    = $(subst .flk,.ps,$(SONGBOOK))
PDF   = $(subst .flk,.pdf,$(SONGBOOK))
NAMES = $(subst .flk,,$(SONGBOOK))
HTML  = $(subst .flk,.html,$(SONGBOOK))

# ALLSONGS are what we want for a _performance_ songbook; that includes
#	key variations and similar things.
ALLPS    = $(subst .flk,.ps,$(ALLSONGS))
ALLPDF   = $(subst .flk,.pdf,$(ALLSONGS))
ALLNAMES = $(subst .flk,,$(ALLSONGS))
ALLHTML  = $(subst .flk,.html,$(ALLSONGS))
PRINT	 = $(ALLPDF)

### zongbook.tex, if present, generates the "official" printed songbook.
#	We derive the Z-lists from it; it may have duplicate entries if
#	songs are commonly known by multiple names (e.g. m*-bear) or have
#	short filenames that sort out of order.  (My 8-character filenames
#	go back to the 1980s.)
#
#	In case you're wondering, I use "zongbook" so that it sorts at the
#	end of the listing and doesn't get mixed in with the songs.  That
#	will, of course, fail if I ever write "zulu-lovesong" or something
#	of the sort.

HAVE_ZONGBOOK := $(wildcard zongbook.tex)

# We extract ZONGS from zongbook.tex because it's sorted by title:
#   Use := so as to only run the perl command once.
#   Now that we have SongInfo.pl, we could use index_title instead ===
# This really ought to go into a file.

ZONGS := $(shell [ -e zongbook.tex ] && 	\
		 perl -n -e '/file\{(.+\.flk)/ && print "$$1\n"' zongbook.tex)
ZONGBOOK := $(filter-out $(WIP), $(ZONGS))

# Compute the song lists by filtering ZSONGS
#   SONGS    -- stuff that's OK to put in a songbook
#   MYSONGS  -- just mine, not PD or ok-to-publish
#   WEBSONGS -- Adds $(OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but work in progress

ZPDF   = $(subst .flk,.pdf,$(ZONGBOOK))
ZNAMES = $(subst .flk,,$(ZONGBOOK))
ZHTML  = $(subst .flk,.html,$(ZONGBOOK))
ZPRINT = $(ZPDF)

########################################################################
###
### Rules:
###

# flk to dvi:
# 	Rather than make a temporary .tex file, we pass everything we need
#	on the command line to wrap the song file in a \documentclass and
#	appropriate document environment.
#
TEXINPUTS := .:$(TEXDIR):$(TEXINPUTS)
export TEXINPUTS
SONG_PREAMBLE = '\documentclass[$(SIZE)letterpaper]{article}'			\
		'\usepackage[utf8]{inputenc}'                                   \
		'\usepackage{song,zingers,zongbook}'
SONG_LOOSELEAF= '\documentclass[$(SIZE)letterpaper,twoside]{article}'		\
		'\usepackage[utf8]{inputenc}'                                   \
		'\usepackage{song,zingers,zongbook}'

.SUFFIX: flk

%.pdf:	%.flk
	echo q | $(PDFLATEX) $(TEXOPTS) -jobname $*				\
		$(SONG_LOOSELEAF) '\begin{document}\input{$<}\end{document}'
	rm -f $*.log $*.aux

%.dvi:	%.flk
	echo q | $(LATEX) $(TEXOPTS) -jobname $*				\
		$(SONG_PREAMBLE) '\begin{document}\input{$<}\end{document}'
	rm -f $*.log $*.aux

# Build into another directory, for constructing websites and songbooks.
#	Note that the target directory has to be specified directly as well as
#	in the target filenames, e.g.:  make DESTDIR=foo foo/bar.dvi
$(DESTDIR)/%.dvi:	%.flk
	echo q | $(LATEX) $(TEXOPTS) -jobname $* -output-directory $(DESTDIR)	\
		$(SONG_PREAMBLE) '\begin{document}\input{$<}\end{document}'
	cd $(DESTDIR); rm -f $*.log $*.aux

reportVars += TRANSPOSED NAMES ALLNAMES ZNAMES WIP

########################################################################
###
### Targets
###

# There's no need to build index files anymore; Lyrics isn't linked from
# the website at this point.  HTML and PDF songbooks _will_ be built here
# eventually.

all::
	@echo building PDF files
all::	$(PRINT)

### Lists:

list-names:
	@echo $(NAMES)
list-songs: 
	@echo $(SONGBOOK)

### Printing.
#	The following recipes print the individual PDF files that make
#	up the various lists: SONGS, ALLSONGS, and ZONGS.  There are
#	some subtleties involved.
#
#	The formatting that makes the most sense for the web, for
#	example, is one-sided, because that works right when people
#	(who might not have duplexing printers) are going to be
#	downloading and printing individual pages.  It's what we do in
#	Songs directories -- see songs.make for the details.
#
#	A performance book, on the other hand, should be two-sided
#	with a "title page" for each song, so that the lyrics make a
#	two-page spread on the following even and odd pages.  Doing
#	this, naturally, requires a printer capable of printing two-
#	sided, and also requires a line with \makesongtitle between
#	the metadata and the lyrics.
#
#	On the gripping hand, a songbook printed for publication might
#	want to be two-sided in "compact" format, with songs starting
#	on even pages, but omitting the title pages and blank fourth
#	pages to save space.  This can be tricky if you want to
#	correctly handle the occasional page of notes or one-page
#	song.  This is what we do for zongbook.tex.  It also makes
#	the most sense if you can read tiny print printed two-up.
#
#	Finally, a songbook formatted for display on a tablet wants to
#	be one-sided (displaying an almost-blank title page is just
#	silly unless you have a _really_ wide screen), but with very
#	narrow margins to make the best use of the available pixels.
#
#   Note that in some cases the following might work better:
#	@for f in $(PS) ; do lpr $$f ; done 

# Songbook: print SONGS as individual files
songbook: $(PDF) 
	lp $(PDF)

# Longbook: print ALLSONGS as individual files
longbook: $(ALLPDF) 
	lp $(ALLPDF)

# Zongbook: print ZSONGS as individual files
zongbook: $(ZPDF) 
	lp $(ZPDF)

# songlists:

songlist.txt:$(ALLSONGS) Makefile
	@echo building $@ from ALLSONGS
	@$(TOOLDIR)/Setlist.cgi $(ALLSONGS) > $@

### filkbook: make a printed songbook with everything in it.
filkbook: $(ALLPS)
	lp $(ALLPS)

### Cleanup:

clean::
	-rm -f *.ps *.pdf *.aux *.dvi *.log

### end lyrics.make ###

