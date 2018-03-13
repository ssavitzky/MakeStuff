# Makefile includes for song directories
#

# Songs is the web directory; each song is in an individual subdirectory
#   [song]/lyrics.{html,pdf,txt} are built from ../Lyrics*/[song].flk
#   this needs to be fixed eventually.

### Song lists:  (All made via (cd ../Lyrics; make list-*)
#
#   SONGS    -- stuff that's OK to put in a songbook: mine/ours and PD
#   WEBSONGS -- Adds $(OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but in-progress songs
#

# These are the tags for which we can put lyrics on the web
WEB_OK_TAGS = mine ours tgl pd cc web-ok

# Directories containing lyrics (virtual path for dependencies):
LPATH := $(filter-out %WIP, $(wildcard $(BASEREL)Lyrics*))
VPATH = $(LPATH)

# We need a list of lyrics that includes the path information.  Instead of relying
# on the makefiles in the various lyrics directories, we go direct.  Files containing
# "--" are versions in different keys, and are meant to be printed individually when
# someone is performing with an instrument that can't be capoed.
#
ASONGS := $(shell for d in $(LPATH); do ls $$d/[a-z]*.flk | grep -ve '--' ; done)

# WIP = work in progress
WIP := $(shell [ -z "$(ASONGS)" ] || grep -ile '^\\tags.*\Wwip\W' $(ASONGS))

ALLSONGS := $(filter-out $(WIP), $(ASONGS))

# PD = public domain
PD := $(shell [ -z "$(ALLSONGS)" ] || grep -ile '^\\tags.*\Wpd\W' $(ALLSONGS))

# OURS =  a band member has sufficient rights to allow us to publish the lyrics
OURS := $(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wours\W' $(ALLSONGS))

# MINE contains songs ganked from one bandmember or another
MINE := $(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wmine\W' $(ALLSONGS))

# WEB_OK = not ours but we have permission to publish on the web
WEB_OK :=$(shell [ -z "$(ALLSONGS)" ] || grep -le '^\\tags.*\Wweb-ok\W' $(ALLSONGS))

# ugly shell pipeline to sort a list of song references.
SORT_SONGS =  sed 's/ /\n/g' | sed 's/\// /g' | sort -k3 | sed 's/ /\//g'

# Songlists:
#   SONGBOOK -- stuff that's OK to put in a songbook
#   OURSONGS -- just ours, not PD or ok-to-publish
#   WEBSONGS -- Adds $(WEB_OK) to get stuff that's OK to put on the web
#   ALLSONGS -- everything but work in progress
SONGBOOK = $(shell echo $(OURS) $(MINE) $(PD) | $(SORT_SONGS))
OURSONGS = $(shell echo $(OURS) $(MINE) | $(SORT_SONGS))
WEBSONGS = $(shell echo $(OURS) $(MINE) $(WEB_OK) $(PD) | $(SORT_SONGS))

# Directory name lists:
# 	Because we're building a web directory here, we're mostly interested in
#	ALLNAMES and WEBNAMES.  We will build subdirectories for ALLNAMES, because
#	those are the songs in our repertoire.  We will make lyrics visible only
#	in WEBNAMES.
#
SBNAMES  = $(sort $(filter-out %--% %.orig.%, $(subst .flk,,$(notdir $(SONGBOOK)))))
ALLNAMES = $(sort $(filter-out %--% %.orig.%, $(subst .flk,,$(notdir $(ALLSONGS)))))
WEBNAMES = $(sort $(filter-out %--% %.orig.%, $(subst .flk,,$(notdir $(WEBSONGS)))))
NOTWEB   = $(filter-out $(WEBNAMES), $(ALLNAMES))


# Indices: all
# 	1Index.html is the index web page, 1IndexTable.html is just the
#	 <table> element, for use in template replacement.
#	1IndexShort.html is the raw list of names linked to subdirs
#	1IndexLong.html is the long table with descriptions
#
INDICES= 1Index.html 1IndexTable.html 1IndexShort.html   # 1IndexLong.html

# Lists.  Just the ones we actually need
ALLDIRS  = $(ALLNAMES)
ALLPDF   = $(patsubst %,%/lyrics.pdf,$(ALLNAMES))
ALLHTML  = $(patsubst %,%/lyrics.html,$(ALLNAMES))
ALLTEXT  = $(patsubst %,%/lyrics.txt,$(ALLNAMES))

WEBDIRS  = $(WEBNAMES)
WEBPDF   = $(patsubst %,%/lyrics.pdf,$(WEBNAMES))
WEBHTML  = $(patsubst %,%/lyrics.html,$(WEBNAMES))
WEBTEXT  = $(patsubst %,%/lyrics.txt,$(WEBNAMES))

# Indices: web
#	0Index* are the web-safe versions of the index files
WEBINDICES = 0Index.html 0IndexTable.html 0IndexShort.html  # 0IndexLong.html

# At some point we can add 1Index*, after we add subdir indices that can handle
# directories without visible lyrics.


# Utility programs:
TEXDIR	  = $(TOOLDIR)/TeX
FLKTRAN   = $(TEXDIR)/flktran.pl
INDEX     = $(TEXDIR)/index.pl
TRACKINFO = $(TOOLDIR)/music/TrackInfo.pl
SONGINFO  = $(TOOLDIR)/music/songinfo

reportVars += LPATH WEBNAMES NOTWEB WEB_OK_TAGS

########################################################################
###
### Rules:
###

# Rules to make song subdirectories and their contents

%: %.flk
	mkdir -p $@

# lyrics.pdf
#	It would be better if we could make foo/lyrics.pdf directly, but
#	there's no good way to do that because latex doesn't have a way
#	to specify the output file, just the output directory.
#
#	We also can't make %/%.pdf, because make can't handle rules with
#	multiple wildcards on the left.
#	
%/lyrics.pdf: %.dvi
	dvipdf $< $@

# %.dvi:  Intermediate stage in making %/lyrics.pdf
#	We want to do the build in the Lyrics directory rather than here
#	because there may be multiple lyrics directories in the search path,
#	and we want to use whatever local styles they have, including
#	singer annotations (zinger.sty).
#
#	An alternative would be to put the lyrics directory in the
#	search path, which would allow us to override the songbook
#	style here if we wanted to.  See lyrics.make for the rule.
#
%.dvi:	%.flk
	d=`pwd`; cd `dirname $<`; $(MAKE) $$d/$*.dvi DESTDIR=$$d

%/lyrics.html: %.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) -t -b $< $@

%/lyrics.txt: %.flk
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) $< $@

# We generate several types of metadata
%/metadata.sh: %.flk
	$(SONGINFO) --format=shell --ok='$(WEB_OK_TAGS)' $< > $@

%/metadata.yml: %.flk
	$(SONGINFO) --format=yaml --ok='$(WEB_OK_TAGS)' $< > $@

%/metadata.make: %.flk
	$(SONGINFO) --format=make --ok='$(WEB_OK_TAGS)' $< > $@

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

all::	$(ALLDIRS) $(WEBHTML) $(ALLPDF) subdir-indices webindices

.PHONY: webindices
webindices: $(WEBINDICES)

### Showing and hiding lyrics:
#
#	For now, we're simply symlinking lyrics.html in any web-visible
#	directory, and unlinking it (showing any unfortunate user an
#	error if they try to see it) for non-web songs.
#
#	Eventually the plan is for index.html to come from a template and
#	do server-side includes for header, notes, audio files, and
#	lyrics.  That will allow us to show pages for all songs in our
#	repertoire.
#
#	In either case, we do this in a loop, so that if the status of
#	a song changes we do the right thing.

.PHONY: show-lyrics hide-lyrics subdir-indices

subdir-indices:: show-lyrics hide-lyrics

show-lyrics: $(WEBNAMES)
	for d in $(WEBNAMES); do (cd $$d; ln -sf lyrics.html index.html) done

hide-lyrics: $(NOTWEB)
	for d in $(NOTWEB); do (cd $$d; rm -f index.html) done

### Lists:

list-names:
	@echo $(ALLNAMES)
list-songbook: 
	@echo $(SONGBOOK)
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

zongbook.dvi: song.sty zongbook.sty
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


### Website indices:

# FIXME: At the moment neither $(INDEX) and $(TRACKINFO) is able to handle
# multiple lyrics directories.  trackinfo can probably be fixed by giving
# it 

# We used to generate complete HTML files, but that's not nearly versatile
# enough.  What we do now is generate HTML fragments that get included in
# the real index.html and other pages.

# Also, we now generate the indices from the directory listing, rather than
# trying to generate lists in the lyrics directory.  That gives us better
# control over what's included.

0List.html: $(WEBSONGS) $(WEBDIRS) | $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song List</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Songs</a>'		>> $@
	@echo '  / Song List</h1>'			>> $@
	@$(INDEX) -h  $(WEBSONGS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

0Index.html: $(WEBSONGS) $(WEBDIRS) | $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song Index</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Songs</a>'		>> $@
	@echo '  / Song Index</h2>'			>> $@
	@$(INDEX) -t -h $(WEBSONGS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

0IndexTable.html: | $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h $(WEBSONGS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

0IndexShort.html: 
	@echo building $@ from WEBNAMES
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(WEBNAMES) | tr ' ' "\n" | sort | uniq`; do \
		echo '<a href="'$$f/'">'$$f'</a>' >> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

0IndexLong.html: 
	$(TRACKINFO) --long --credits --sound -t format=list.html $(WEBNAMES) > $@

1Index.html:
	@echo building $@ from ALLLYRICS
	@echo '<html>' 					>  $@
	@echo '<head>'					>> $@
	@echo '<title>Song Index</title>'		>> $@
	@echo '</head><body>'				>> $@
	@echo '<h2><a href="/">steve.savitzky.net</a> '	>> $@
	@echo '  / <a href="./">Songs</a>'		>> $@
	@echo '  / Complete Index</h2>'			>> $@
	@$(INDEX) -t -h $(ALLSONGS)			>> $@
	@echo '<h5>Last update: ' `date` '</h5>'	>> $@
	@echo '</body>'					>> $@
	@echo '</html>' 				>> $@

1IndexTable.html: | $(INDEX)
	@echo building $@ from ALLLYRICS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h $(ALLSONGS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

1IndexShort.html:
	@echo building $@ 
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(ALLSONGS) | tr ' ' "\n" | sort | uniq`; do \
		echo '<a href="'$$f/'">'$$f'</a>' 	>> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

1IndexLong.html:  | $(TRACKINFO)
	$(TRACKINFO) --long --sound --credits -t format=list.html $(ALLNAMES) > $@
