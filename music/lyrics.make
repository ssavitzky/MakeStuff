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
FLKTRAN   = $(TEXDIR)/flktran.pl
PDFLATEX  = pdflatex -file-line-error
SORT_BY_TITLE = $(TEXDIR)/sort-by-title
PRINT_DUPLEX = lp -o sides=two-sided-long-edge

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

# ASONGS is just the song files, alphabetical by filename.
#   This works in lgf and tg because we're not using Steve's
#   cryptic shortnames.
#   Note that template files start with a digit, so the wildcard skips them
ASONGS := $(shell $(SORT_BY_TITLE) $(wildcard [a-z]*.flk) $(wildcard [1-9][0-9]*.flk))

# REJECT = work in progress and other songs we don't want in the songbook
#	Note that we have to guard against the possibility that there are no
#	.flk files in the directory; that would make grep read from STDIN
#	if we let things get that far.
REJECT := $(shell [ -z "$(ASONGS)" ] || grep -ilEe '^\\tags.*\W(wip|rej)\W' $(ASONGS))

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
ALLSONGS := $(filter-out $(REJECT), $(ASONGS))

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
		 perl -n -e '/^\\file\{(.+\.flk)/ && print "$$1\n"' zongbook.tex)
ZONGBOOK := $(filter-out $(REJECT), $(ZONGS))

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
		'\usepackage{song,zongbook,zingers}'
SONG_LOOSELEAF= '\documentclass[$(SIZE)letterpaper,twoside]{article}'		\
		'\usepackage[utf8]{inputenc}'                                   \
		'\usepackage{song,zongbook,zingers}'

.SUFFIX: flk

%.pdf:	%.flk
	echo q | $(PDFLATEX) $(TEXOPTS) -jobname $*				\
		$(SONG_LOOSELEAF) '\begin{document}\input{$<}\end{document}'
	rm -f $*.log $*.aux

%.dvi:	%.flk
	echo q | $(LATEX) $(TEXOPTS) -jobname $*				\
		$(SONG_PREAMBLE) '\begin{document}\input{$<}\end{document}'
	rm -f $*.log $*.aux

%.txt:	%.flk
	$(FLKTRAN) $< $@

%.chords.txt: %.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) -c $< $@

%.html: %.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) -t -b $< $@

# Build into another directory, for constructing websites and songbooks.
#	Note that the target directory has to be specified directly as well as
#	in the target filenames, e.g.:  make DESTDIR=foo foo/bar.dvi
$(DESTDIR)/%.dvi:	%.flk
	echo q | $(LATEX) $(TEXOPTS) -jobname $* -output-directory $(DESTDIR)	\
		$(SONG_PREAMBLE) '\begin{document}\input{$<}\end{document}'
	cd $(DESTDIR); rm -f $*.log $*.aux

reportVars += TEXDIR ASONGS TRANSPOSED NAMES ALLNAMES ZNAMES REJECT ALLPDF

########################################################################
###
### Targets
###

# There's no need to build index files anymore; Lyrics isn't linked from
# the website at this point.  HTML and PDF songbooks _will_ be built here
# eventually.

all::	$(ALLPDF)
	@echo building PDF files
all::	$(PRINT)

# zongbook.pdf depends on all the files it references 
zongbook.pdf: zongbook.tex $(ZONGS) $(TEXDIR)/song.sty

###
### Lists:
###
.PHONY: list-names list-songs list-missing list-long list-short

list-names:
	@echo $(NAMES)
list-songs: 
	@echo $(SONGBOOK)

# List the songs that are missing from zongbook.tex
#
list-missing:
	for f in *.flk; do \
		grep -q $$f zongbook.tex || echo $$f missing from zongbook.tex ;\
	done

# List long songs, i.e. songs that will require two facing pages when printed
#
list-long:
	@for f in *.pdf; do g=$$(basename $$f .pdf); \
		echo $$g.flk $$(pdfinfo $$f | grep Pages) \
		     $$(if head -1 $$g.flk|grep -q '\[L'; \
			then :; else echo unmarked; fi);\
	done | egrep '[3-6]'

# List short songs, for which lyrics fit on one page
#	We test for 2 pages because the stand-along PDFs always have a title page.
#	Only bother with songs that will actually be printed.
#
list-short:
	@for f in $(ZPDF); do g=$$(basename $$f .pdf); \
		echo $$g.flk $$(pdfinfo $$f|grep Pages) \
		     $$(if head -1 $$g.flk | grep -q '\[S'; \
			then :; else echo unmarked; fi);\
	done | grep 2

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

# print-songbook: print SONGS as individual files
print-songbook: $(PDF) 
	for f in $(ALLPDF); do $(PRINT_DUPLEX) $$f; done

# print-longbook: print ALLSONGS as individual files
print-longbook: $(ALLPDF) 
	for f in $(ALLPDF); do $(PRINT_DUPLEX) $$f; done

# Zongbook: print zongbook.pdf, which is a properly-formatted book.
#
#	zongbook.tex should have a \file tag for every song you want
#	to print.  The easy way to make it is to add every song and
#	comment out the ones you don't want; that makes it easy to
#	verify that you haven't left anything out.  Use list-missing.
#
print-zongbook: zongbook.pdf
	$(PRINT_DUPLEX) $<

# print-zongs -- all the songs in zongbook printed separately
#
#	zongbook is supposed to contain \file entries for all the songs
#	that we actually want
#
print-zongs: $(ZPDF)
	for f in $(ZPDF); do $(PRINT_DUPLEX) $$f; done

### Cleanup:

clean::
	-rm -f *.ps *.pdf *.aux *.dvi *.log

### end lyrics.make ###

