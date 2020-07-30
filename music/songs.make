# Makefile includes for song directories
#

# Songs is the web directory; each song is in an individual subdirectory
#   [song]/lyrics.{html,pdf,txt} are built from ../Lyrics*/[song].flk
#   this needs to be fixed eventually.

# Utility programs:
TEXDIR	  = $(TOOLDIR)/TeX
FLKTRAN   = $(TEXDIR)/flktran.pl
INDEX     = $(TEXDIR)/index.pl
TRACKINFO = $(TOOLDIR)/music/TrackInfo.pl
SONGINFO  = $(TOOLDIR)/music/songinfo
SORT_BY_TITLE = $(TEXDIR)/sort-by-title
MUSTACHE  = $(shell which mustache)

# These are the tags for which we can put lyrics on the web.  This can be overridden
# in the local .config.make, e.g. to add specific songwriter tags.
WEB_OK_TAGS = web-ok mine ours pd cc

# These are the tags that indicate that it's not ok to put up lyrics, even if they have
# one of the tags in WEB_OK_TAGS.  The rej and wip tags are included for completeness;
# songs that have them don't normally have directories made for them.
NOT_OK_TAGS = not-ok rej wip

# Directories containing lyrics (virtual path for dependencies):
LPATH := $(filter-out %WIP, $(wildcard $(BASEREL)Lyrics*))
VPATH = $(LPATH)

# We need a list of lyrics that includes the path information.  Instead of relying
# on the makefiles in the various lyrics directories, we go direct.  Files containing
# "--" are versions in different keys, and are meant to be printed individually when
# someone is performing with an instrument that can't be capoed.
#
# ASONGS is just the song files sorted by pathname
#   It's almost impossible to write a glob that rejects template files at this point,
#   but they get filtered out in ALLSONGS because they have an empty song title.
ASONGS := $(shell for d in $(LPATH); do ls $$d/*.flk; done)

# REJECT = work in progress and other songs we don't want on the web at all.
#
REJECT := $(shell [ -z "$(ASONGS)" ] || grep -ilEe '^\\tags.*\W(wip|rej)\W' $(ASONGS))

# ALLSONGS is the list of files sorted by title, which is more useful
ALLSONGS := $(shell $(SORT_BY_TITLE)  $(filter-out $(REJECT),$(ASONGS)))

# Directory names:
#	DIRNAMES is the list of all song directories, sorted by title.  (We sort
#	by title because eventually we'll want to build indices and such.)
#	It would be better if we could use filter-out, but it doesn't handle regexps
#	Similarly, we need the loop because grep needs each name on a separate line.
DIRNAMES := $(shell for f in $(subst .flk,,$(notdir $(ALLSONGS))); do echo $$f; done \
		    | grep -v -e .orig -e --)

# Lists.  Just the ones we actually need
ALLFLK   = $(patsubst %,%/lyrics.flk,$(DIRNAMES))
ALLPDF   = $(patsubst %,%/lyrics.pdf,$(DIRNAMES))
ALLCHO   = $(patsubst %,%/lyrics.cho,$(DIRNAMES))
ALLHTML  = $(patsubst %,%/lyrics.html,$(DIRNAMES))
ALLTEXT  = $(patsubst %,%/lyrics.txt,$(DIRNAMES)) \
	   $(patsubst %,%/lyrics.chords.txt,$(DIRNAMES))

# Indices: 
# 	0IndexTable.html is the song list in a <table> element
#	0IndexShort.html is the raw list of names linked to subdirs
#
#  there are additional optional index targets:
#	0Index is a full HTML page rather than a fragment
#	0IndexLong.html is a long table with descriptions
WEBINDICES = 0IndexTable.html 0IndexShort.html
SUBDIR_INDICES =  $(patsubst %,%/index.html, $(DIRNAMES))

# these are the optional include files that %/index.html depends on
SUBDIR_INCLUDES = body-text.html audio-links.html

# At some point we can add 1Index*, after we add subdir indices that can handle
# directories without visible lyrics.

reportVars += LPATH ASONGS ALLSONGS DIRNAMES WEB_OK_TAGS MUSTACHE

########################################################################
###
### Rules:
###

# Rules to make song subdirectories and their contents

%: | %.flk
	mkdir -p $@

# lyrics.pdf
#	It would be better if we could make foo/lyrics.pdf directly, but
#	there's no good way to do that because latex doesn't have a way
#	to specify the output file, just the output directory.  Even if
#	we did, the default in ../Lyrics is to generate looseleaf (double
#	sided) format.  What most people expect, and what we've been doing
#	so far, is "compact" format, without a title page.
#
#	So to make looseleaf format PDFs, set LOOSELEAF to anything non-
#	blank.   The lyrics directories are in VPATH, so if the pdf already
#	exists there, make will find it and copy it to %/.  We use cp so
#	that the PDF in Lyrics doesn't get treated as an intermediate file
#	and deleted.
#
ifdef LOOSELEAF
%/lyrics.pdf: %.pdf
	cp $< $@
endif

#	... If Lyrics/%.pdf doesn't exist, we first make it there, then
#	copy it here (i.e. to Songs), where the previous rule will find it
#	because at that point % and %.pdf are in the same directory.  It
#	gets copied, then make deletes it because it's an intermediate file.
#
%.pdf:	%.flk
	d=`pwd`; cd `dirname $<`; $(MAKE) $*.pdf; cp $*.pdf $$d

# 
#       For compact format, we make a dvi file in Songs, which lyrics.make
#	does using compact format, and then use dvipdf to create the PDF
#	in the song directory.
#	That _sort of_ works, but to make a dvi file we have to use
#	latex instead of pdftex, and the two have differences.  
#
ifndef LOOSELEAF
%/lyrics.pdf: %.dvi | %
	dvipdf $< $@
endif

#	making the dvi file here just involves setting DESTDIR.
#
%.dvi:	%.flk
	d=`pwd`; cd `dirname $<`; $(MAKE) $$d/$*.dvi DESTDIR=$$d

# 	The lyrics.html file is just a fragment; we use mustache to include
#	it in the index.html file
%/lyrics.html: %.flk | %
	$(FLKTRAN) -t -b $< > $@

#	The text files might get passed around loose, so we'd like them to
#	point back to the web.  That's rather ugly, and it's done in flktran
%/lyrics.txt: %.flk | %
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) $< $@

%/lyrics.chords.txt: %.flk | %
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) -c $< $@

%/lyrics.cho: %.flk | %
	WEBSITE=$(WEBSITE) WEBDIR=$(MYNAME) $(FLKTRAN) -c $< $@

#	This one makes a symlink to the appropriate lyric (.flk) file
#	Not done by default because doing so would require major changes to
#	the lyrics.pdf recipe
%/lyrics.flk: | %.flk %
	ln -rsf %.flk $@

## Here we generate several types of metadata.

#	metadata.yml is an input to the mustache template engine
%/metadata.yml: %.flk $(SONGINFO) | %
	$(SONGINFO) --format=yaml --ok='$(WEB_OK_TAGS)' $< > $@

#	metadata.sh can be sourced into a shell script; it can be used if
#	  we don't have the mustache templating engine.
%/metadata.sh: %.flk $(SONGINFO) | %
	$(SONGINFO) --format=shell --ok='$(WEB_OK_TAGS)' $< > $@

#	metadata.make can be included in a makefile; it's not used at the moment.
%/metadata.make: %.flk $(SONGINFO) | %
	$(SONGINFO) --format=make --ok='$(WEB_OK_TAGS)' $< > $@

#	metadata.timestamp is touched if index.html is out of date
%/metadata.timestamp: FORCE
	@if [ ! -f $@ ]; then 				\
	   touch $@; echo touch $@;			\
	else 						\
	   export d=`dirname $@`; for f in $(SUBDIR_INCLUDES); do	\
		if [ -e $$d/$$f ] && [ $$d/$$f -nt $@ ]; then		\
		   touch $@; echo touch $@; break;			\
		fi							\
	   done								\
	fi
.PHONY: FORCE

# The index.html files depend on the corresponding metadata.
#	Note that if we don't explicitly make the metadata, it will be treated as an
#	intermediate file and deleted after making index.html.
#
#	On the other hand, we _do_ want to delete the symlink to the template.
#	It's there because paths to partials are resolved relative to the template.
#
#	At some point we might want to try mo: Mustache templates in pure bash
#       https://github.com/tests-always-included/mo
#
#	Note that we are no longer using server-side includes here.  Currently
#	they _are_ used elsewhere in the site, mainly for footers.  Also note
#	that in order for this to work, footers etc. have to be in /site, which
#	must be a sibling of /Songs.
#
#	Note that there appears to be no direct way to make %/index.html depend on
#	optional include files like %/body-text.html and %/audio-links.html, so we
#	use a timestamp file instead and touch it if index.html is out of date.
#
ifneq ($(MUSTACHE),)
%/index.html: %/metadata.yml %/metadata.timestamp 1subdir-index.mustache
	cd $(dir $@);  ln -sf ../1subdir-index.mustache; 			\
	    $(MUSTACHE) metadata.yml 1subdir-index.mustache > index.html; 	\
	    rm ./1subdir-index.mustache
else
# What we really ought to do is fall back on server-side includes and a shell template
%/index.html: %/metadata.yml %/metadata.timestamp 
	touch $@
	@echo NO TEMPLATING ENGINE DEFINED
endif

# Ogg and mp3 files.  
#	They have no dependencies to prevent their being constantly rebuilt.
#	It might be better to make the mp3s depend on the oggs.
%.ogg: 
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg  $*)
%.mp3: 
	sox $(shell $(TRACKINFO) format=files $*) -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 $*) $@

AUDIO_LINKS = $(shell for f in *; do \
		[ -e $$f/$$f.ogg ] && echo $$f/audio-links.html; done | uniq)
all::	$(AUDIO_LINKS)

## If a subdirectory contains audio files, it needs an audio-links.html file
#	If there are only ogg and mp3 files with names that match the directory,
#	things are simple.  Otherwise somebody is going to have to do some editing.
#
#	This is a single-colon rule with no dependencies, so it will only be built
#	if it does not already exist.  Once it's there you can edit it to add
#	additional links or text.
#
%/audio-links.html:
	d=$(subst /,,$(dir $@)); \
	  echo "<hr />" 				 			 > $@; \
	  echo "<h3 id='Recordings'>Recordings:</h3>" 				>> $@; \
	  echo "<p class='recording'>"						>> $@; \
	  echo "    <a href='$$d.ogg'>[ogg]</a> <a href='$$d.mp3'>[mp3]</a>"	>> $@; \
	  echo "    <audio controls>" 						>> $@; \
	  echo "         <source src='$$d.ogg' type='audio/ogg'>"		>> $@; \
	  echo "         <source src='$$d.mp3' type='audio/mp3'>"		>> $@; \
	  echo "    </audio>"	 						>> $@; \
	  echo "</p>"	 							>> $@;


########################################################################
###
### Targets
###

all::	$(DIRNAMES) $(ALLPDF) metadata $(ALLHTML) $(ALLTEXT) $(ALLCHO)

.PHONY: metadata
metadata::	$(patsubst %,%/metadata.yml, $(DIRNAMES))
metadata::	$(patsubst %,%/metadata.sh, $(DIRNAMES))
metadata::	$(patsubst %,%/metadata.timestamp, $(DIRNAMES))


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

.PHONY: subdir-indices

subdir-indices: $(SUBDIR_INDICES)

ifneq ($(MUSTACHE),)
## If we have the templating engine it's safe to rebuild */index.html
all:: subdir-indices
endif

### Lists:

list-names:
	@echo $(DIRNAMES)
list-dirs: 
	@echo $(DIRNAMES)
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
# multiple lyrics directories. 

# We used to generate complete HTML files, but that's not nearly versatile
# enough.  What we do now is generate HTML fragments that get included in
# the real index.html and other pages.

# Also, we now generate the indices from the directory listing, rather than
# trying to generate lists in the lyrics directory.  That gives us better
# control over what's included.

WEBINDICES = 0IndexShort.html 0IndexTable.html 0IndexLong.html

.PHONY: webindices 
webindices: $(WEBINDICES)

# indices currently broken
all:: webindices

0IndexTable.html: $(INDEX)
	@echo building $@ from WEBLYRICS
	@echo '<!-- begin $@ -->'			>  $@
	@$(INDEX) -t -h -l $(ALLSONGS)			>> $@
	@echo '<!-- end $@ -->'				>> $@

0IndexShort.html: 
	@echo building $@ from directory listing:
	@echo '<!-- begin $@ -->'			>  $@
	@for f in `echo $(DIRNAMES) | tr ' ' "\n" | grep -v ".orig" | sort | uniq`; do \
		echo '<a href="'$$f/'">'$$f'</a>' >> $@; \
	done
	@echo '<!-- end $@ -->'				>> $@

# Note that TrackInfo might not look at metadata to check whether it should include lyrics
0IndexLong.html: 
	$(TRACKINFO) --long --credits --sound -t format=list.html $(DIRNAMES) > $@
