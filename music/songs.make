# Makefile includes for song directories
#

# Songs is the web directory; each song is in an individual subdirectory
#   At the moment, [song]/lyrics.{html,pdf,txt} are built from ../Lyrics;
#   this needs to be fixed eventually.

### Song lists:  (All made via (cd ../Lyrics; make list-*)
#
#   SONGS    -- stuff that's OK to put in a songbook: mine/ours and PD
#   MYSONGS  -- just mine, not PD or ok-to-publish
#   WEBSONGS -- Adds $(OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but in-progress songs
#

# Directories containing lyrics (virtual path for dependencies):
LPATH := $(filter-out %WIP, $(wildcard $(BASEREL)/Lyrics*))
VPATH = $(LPATH)

SONGS    := $(shell for d in $(LPATH); do cd $$d; make list-songs; done | sort)
ALLSONGS := $(shell for d in $(LPATH); do cd $$d; make list-allsongs; done | sort)
WEBSONGS := $(shell for d in $(LPATH); do cd $$d; make list-websongs; done | sort)

# SONGS are what we can put in a songbook or compilation CDROM
# 	The derived lists are PS, PDF, HTML, TEXT, and NAMES
NAMES = $(filter-out %--% %.orig.%, $(subst .flk,,$(SONGS)))
DIRS  = $(NAMES)
PDF   = $(patsubst %,%/lyrics.pdf,$(NAMES))
HTML  = $(patsubst %,%/lyrics.html,$(NAMES))
TEXT  = $(patsubst %,%/lyrics.txt,$(NAMES))

# Indices: all
# 	1Index.html is the index web page, 1IndexTable.html is just the
#	 <table> element, for use in template replacement.
#	1IndexShort.html is the raw list of names linked to subdirs
#	1IndexLong.html is the long table with descriptions
#
INDICES= 1Index.html 1IndexTable.html 1IndexShort.html   # 1IndexLong.html

# For personal songbook: $(ALLSONGS) just excludes incomplete stuff
ALLNAMES = $(subst .flk,,$(ALLSONGS))
ALLDIRS  = $(ALLNAMES)
ALLPDF   = $(patsubst %,%/lyrics.pdf,$(ALLNAMES))
ALLHTML  = $(patsubst %,%/lyrics.html,$(ALLNAMES))
ALLTEXT  = $(patsubst %,%/lyrics.txt,$(ALLNAMES))
ALLLYRICS= $(patsubst %,../Lyrics/%,$(ALLSONGS))

# For publishing on the web, $(WEBSONGS) excludes NOTMINE but includes OK
WEBNAMES = $(subst .flk,,$(WEBSONGS))
WEBDIRS  = $(WEBNAMES)
WEBPDF   = $(patsubst %,%/lyrics.pdf,$(WEBNAMES))
WEBHTML  = $(patsubst %,%/lyrics.html,$(WEBNAMES))
WEBTEXT  = $(patsubst %,%/lyrics.txt,$(WEBNAMES))
WEBLYRICS= $(patsubst %,../Lyrics/%,$(WEBSONGS))

# Indices: web
#	0Index* are the web-safe versions of the index files
WEBINDICES = 0Index.html 0IndexTable.html 0IndexShort.html  # 0IndexLong.html

# What to publish on the web:
PUBFILES = $(WEBHTML) $(WEBPS) $(WEBPDF) $(WEBINDICES) $(DOCS) 

# Utility programs:
FLKTRAN  = $(TOOLDIR)/TeX/flktran.pl
INDEX    = $(TOOLDIR)/TeX/index.pl
TRACKINFO = $(TOOLDIR)/TrackInfo.pl

########################################################################
###
### Rules:
###

# Rules to make song directories and their contents

%: %.flk
	[ -d $@ ] || mkdir $@
	touch $@

%.ps: %.flk
	d=`pwd`; cd `dirname $<`; $(MAKE) $@; cp $@ $$d

%.pdf: %.ps
	ps2pdf $< $@

# lyrics.pdf
#	It would be better if we could make foo/foo.pdf.  Unfortunately
#	that would require a rule with two %'s on the left, and make
#	can't handle it.  What we _can_ do is cd into each song directory
#	and make -f ../Makefile.	

%/lyrics.pdf: %.ps
	ps2pdf $< $@

%/lyrics.html: %.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) -t $< $@

%/lyrics.txt: ../Lyrics/%.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) $< $@

# === Eventually we want to be able to make the index.html file.
#	This is currently a symlink to lyrics.html, but if we don't
#	have the necessary rights it needs to be a link to dummy.html
#	instead.  We also need to be able to make dummy.html, but 
#	that's another matter.

%/index.html:
	cd `dirname $@`; ln -s lyrics.html index.html

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

all::	$(INDICES) $(WEBINDICES) 

.PHONY: indices webindices
indices: $(INDICES) $(WEBINDICES) 
webindices: $(WEBINDICES)

### Lists:

list-songs: 
	@echo $(SONGS)
list-names:
	@echo $(NAMES)
list-oursongs: 
	@echo $(OURSONGS)
list-allsongs: 
	@echo $(ALLSONGS)
list-websongs: 
	@echo $(WEBSONGS)

### Songbook:  Just my stuff and public domain.  
#	Note that the Songbook doesn't have a proper index -- use the 
#	public HTML index file for that.

# Songbook: a songbook with just the lyrics and chords, not the notes
songbook: $(PS) 
	@for f in $(PS) ; do psselect -p1 $$f | lpr; done 

# Longbook: a songbook that includes the extra pages of notes
longbook: $(PS) 
	@for f in $(PS) ; do lpr $$f ; done 

### Zongbook:  everything, including third-party, in a single file

# "zongbook.ps" -- everything in a single .ps file, with index

zongbook.dvi: song.sty zongbook.sty $(SONGS)
zongbook: zongbook.ps


### Cleanup:

texclean::
	-rm *.aux *.log *.toc *.dvi

clean::
	-rm *.CKP *.ln *.BAK *.bak *.o core errs ,* *~ *.a 	\
		.emacs_* tags TAGS MakeOut *.odf *_ins.h	\
		*.aux *.log *.toc *.dvi *.lj *.ps  		\
		$(WEBINDICES) $(INDICES)
	-rm -f $(ALLHTML)
	-rm -f $(ALLTEXT)

pubclean::
	-rm -f $(ALLHTML)
	-rm -f $(ALLTEXT) $(WEBINDICES) $(INDICES)

htmlclean::
	-rm -f $(ALLHTML)

### Setup:

reportVars := SONGS $(reportVars)

### Website indices:

# We used to generate complete HTML files, but that's not nearly versatile
# enough.  What we do now is generate HTML fragments that get included in
# the real index.html and other pages.

# Also, we now generate the indices from the directory listing, rather than
# trying to generate lists in the lyrics directory.  That gives us better
# control over what's included.

0List.html: $(WEBLYRICS) | $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song List</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Songs</a>'		>> $@
	@echo '  / Song List</h1>'			>> $@
	@$(INDEX) -h  $(WEBLYRICS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

0Index.html: $(WEBLYRICS) | $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song Index</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Songs</a>'		>> $@
	@echo '  / Song Index</h2>'			>> $@
	@$(INDEX) -t -h $(WEBLYRICS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

0IndexTable.html: $(WEBLYRICS) | $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h $(WEBLYRICS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

0IndexShort.html: $(WEBNAMES)
	@echo building $@ from WEBNAMES
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(WEBNAMES) | tr ' ' "\n" | sort | uniq`; do \
		echo '<a href="'$$f/'">'$$f'</a>' >> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

0IndexLong.html: $(WEBNAMES) 
	$(TRACKINFO) --long --credits --sound -t format=list.html $(WEBNAMES) > $@

1Index.html: $(ALLLYRICS) | $(INDEX)
	@echo building $@ from ALLLYRICS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song Index</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Songs</a>'		>> $@
	@echo '  / Complete Index</h2>'			>> $@
	@$(INDEX) -t -h $(ALLLYRICS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

1IndexTable.html: $(ALLLYRICS) | $(INDEX)
	@echo building $@ from ALLLYRICS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h $(ALLLYRICS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

1IndexShort.html: $(ALLNAMES)
	@echo building $@ 
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(ALLNAMES) | tr ' ' "\n" | sort | uniq`; do \
		echo '<a href="'$$f/'">'$$f'</a>' 	>> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

1IndexLong.html: $(ALLNAMES) | $(TRACKINFO)
	$(TRACKINFO) --long --sound --credits -t format=list.html $(ALLNAMES) > $@
