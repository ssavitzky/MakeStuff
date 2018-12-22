#!/usr/bin/make  ### include file for a directory that hasTracks
#
# This template is meant to be symlinked to the Makefile of an "album" 
#   "concert", or "practice" directory.  It automagically searches
#   up the directory tree to find the Tools, Lyrics, and Songs directories. 
#
# It can usually do a good job of figuring out good defaults, but just in
#   case it looks for a "record.conf" and includes it if present; this is
#   most useful for albums.
#
# It allows multiple sets, sessions, versions, or whatever, each with a 
#   .songs file.  (Unlike its predecessors, it does not allow a default
#   "songs" file; this avoids having to make duplicate rules for it.)

### Usage:
#
#   Variables: (use make.config to override the defaults)
#
#	SHORTNAME	the shortname (directory name) of the album
#	LONGNAME	the name of the album's collection directory:
#			(title with words capitalized and separated by _)
#	TITLE		the full, plaintext title of the album 
#			special characters must be quoted for use in "..."
#
#   Targets:
#	all		makes the TOC and track-list files
#	lstracks	list track information (== lstracks for this album)
#	cdr		burns a CD-R
#	try-cdr		does a fake burn.  Recommended to test TOC integrity.
#	archive		make a local copy of all track data (.wav) files

# Now look for Lyrics, which has all the .flk (metadata) files in it.

ifeq ($(wildcard Lyrics), Lyrics)
  LYRICDIR := ./Lyrics
else ifneq ($(wildcard *.flk),,)
  LYRICDIR := .
else
  LYRICDIR := $(shell d=$(MYDIR); 					\
		  while [ ! -d $$d/Lyrics ] && [ ! $$d = / ]; do	\
			d=`dirname $$d`;				\
		  done; echo $$d/Lyrics)
endif
ifeq ($(shell [ -d $(LYRICDIR) ] || echo notfound),notfound)
     $(error Cannot find Lyrics)
endif

reportVars += LYRICDIR

# Figure out the default type and title from the path:
#
#   session - the whole path looks like a date
#	      could be a practice or a recording session.  Don't care.
#   concert - a prefix of the path looks like a date
#   album   - anything else
#
#   We can also handle paths like yyyy/mm-dd/, and day ranges like 
#   yyyy/mm/dd-dd
#

DATEX = m|/([0-9][0-9][0-9][0-9])/([0-9][0-9])[-/]([0-9][0-9](-[0-9][0-9])?)|
DATE := $(shell perl -e '"$(MYPATH)" =~ $(DATEX) && print "$$1/$$2/$$3";')

EVNAME := $(shell perl -e '"$(MYNAME)" =~ /^[-0-9]*(.*)$$/; print "$$1";')

ifeq ($(strip $(DATE)),)
  TITLE := $(MYNAME)
  TYPE  := album
else
ifeq ($(strip $(EVNAME)),)
  TITLE := Session on $(DATE)
  TYPE  := session
else
  TITLE := $(EVNAME)
  TYPE  := concert
endif
endif


### See whether we have a record.conf file, and include it if we do.
#   Putting it here allows for overriding the defaults

ifeq ($(shell [ -f record.conf ] || echo noconf),)
     include $(shell /bin/pwd)/record.conf
endif


# look for Tracks.  

ifeq ($(shell [ -d ./Tracks ] || echo notracks),)
     TRACKDIR	:= ./Tracks
else
     $(warn No Tracks directory:  things could get weird.)
endif


###### Commands ######################################################

## Metadata extraction and formatting programs:

TRACKINFO := $(TOOLDIR)/music/TrackInfo.pl
ifdef PERFORMER
  TRACKINFO := $(TRACKINFO) performer="$(PERFORMER)"
endif

LIST_TRACKS = $(TOOLDIR)/music/list-tracks

## shntool looks useful for manipulating WAV files.
##	shnlen <files> gets lengths
##	cuetools for manipulating cue and toc files

## CD writing.  wodim and genisoimage are new as of Debian Etch.

WODIM = $(shell if [ -x /usr/bin/wodim ]; \
		then echo wodim; else echo cdrecord; fi)

GENISOIMAGE = $(shell if [ -x /usr/bin/genisoimage ]; \
		      then echo genisoimage; else echo mkisofs; fi)

CDRDAO = /usr/bin/cdrdao

## audio player

PLAYER = play


###### Lists ##########################################################

### The times, they are a'changing.  
#
#	Prior to 2008 we used $(SHORTNAME).tracks for the tracklist 
#	of a CD.  Concerts were handled using concert.make.  Around
#	the beginning of 2008 we switched to using "songs" as the
#	main songlist, and %.songs for secondary lists such as 
#	individual sessions or concerts in a field recording directory.
#
#	Now, starting in late 2011, we use only %.songs; this means that
#	we no longer need duplicate rules to handle "songs" and so on.
#
#	From %.songs, we generate corresponding %.oggs and %.mp3s 
#	directories, with numbered symlinks to the corresponding 
#	audio files.
#
#	Note that song names must be unique, allowing a single song to 
#	be part of several playlists.  This lets us keep compressed
#	files in the current directory, and continue keeping single 
#	Tracks, Master, and Premaster directories.  If there are multiple
#	takes on a song, each should have a suffix separated by "--". 
#
#	We no longer require a Premaster/WAV 

# Get the filenames of all the .song files
SONGFILES := $(wildcard *.songs)

# Get the shortnames of all the songs from $(TRACKFILE)
#	Ignore comment lines.  $(SONGS) has *extended* shortnames
#	that include the prefixes and suffixes of concert tracks.
#
SONGS := $(foreach f,$(SONGFILES),$(shell grep -v '\#' $(f)))

# $(SHORTNAMES) is the songfile shortnames that we need to select
#	the appropriate .flk files in $(SONGDIR) for dependencies.
SHORTNAMES := $(shell $(TRACKINFO) format=songs $(TRACKS))

SONGDIR=$(LYRICDIR)
# We know at this point that all the metadata is in SONGDIR
FLK_FILES := $(shell for f in $(SHORTNAMES); do \
		[ -f $(SONGDIR)/$$f.flk ] && echo $(SONGDIR)/$$f.flk; \
		[ -f ./$$f.flk ] && echo ./$$f.flk; \
		done)

# PRINT_FILES -- the printable (.ps) lyrics
PRINT_FILES := $(shell for f in $(SONGS); do \
		[ -f $(LYRICDIR)/$$f.ps ] && echo $(LYRICDIR)/$$f.ps; \
		done)

OGGS = $(addsuffix .ogg, $(SONGS))
MP3S = $(addsuffix .mp3, $(SONGS))

# LOCAL_METADATA -- the local .flk files mainly used for local descriptions,
#	performers, and so on.

LOCAL_METADATA = $(wildcard *.flk)

#FIXME? TRACK_* may not be necessary

# TRACK_SOURCES -- the original .wav (or other) files for the tracks
#	These are in Premaster, and are converted to 16-bit .wav files in Master.

TRACK_SOURCES = $(addprefix Premaster/, $(SONGS))

# TRACK_DATA -- the data files in Master, in the correct order for burning
#

TRACK_DATA = $(addsuffix .wav, $(addprefix Master/, $(SONGS)))

## Compute targets

TRACKLISTS = $(BASEPFX)short.list $(BASEPFX)files $(BASEPFX)long.list \
	$(BASEPFX)short.html $(BASEPFX)long.html $(BASEPFX)extras.html


### Look for *.songs.

SONGFILES=$(wildcard *.songs)
ifneq ($(SONGFILES),)
  SONGLISTS += \
	$(subst .songs,.names, $(SONGFILES)) \
	$(subst .songs,.files, $(SONGFILES)) \
	$(subst .songs,.oggs, $(SONGFILES)) \
	$(subst .songs,.mp3s, $(SONGFILES)) \
	$(subst .songs,.short.list, $(SONGFILES))\
	$(subst .songs,.long.list, $(SONGFILES)) \
	$(subst .songs,.short.html, $(SONGFILES)) \
	$(subst .songs,.long.html, $(SONGFILES)) \
	$(subst .songs,.extras.html, $(SONGFILES)) 

  SUBMAKES += $(subst .songs,.make, $(SONGFILES))
  RIPDIRS += $(subst .songs,.rips, $(SONGFILES)) 
else
  # no songfiles -- set the default so setup: can make it later.
  DEFAULT_SONGFILE = $(TYPE).songs
endif


###### Rules ##########################################################

### Rules for things derived from %.songs

# %.names:  just the shortnames, with comments and blank lines removed
%.names: %.songs
	grep -v '^#' $< | grep -ve '^$$' > $@
# %.files:  track data input files 
%.files: %.songs
	$(TRACKINFO) format=files @$< > $@

%.short.list: %.songs
	$(TRACKINFO) $(TRACKLIST_FLAGS) format=list.text -t -T @$< > $@

%.long.list: %.songs
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long --credits  -T \
		format=list.text @$< > $@

%.credits.list: %.songs
	$(TRACKINFO)  --credits  -T format=list.text @$< > $@

%.long.html: %.songs
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long --credits -t \
		format=list.html @$< > $@

%.short.html: %.songs
	$(TRACKINFO) $(TRACKLIST_FLAGS) \
		 format=list.html -t @$< > $@

%.extras.html: %.songs
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long  --credits \
		--sound format=list.html @$< > $@

%.oggs: %.names
	(for f in `cat $<`; do echo $$f.ogg; done) > $@

%.mp3s: %.names
	(for f in `cat $<`; do echo $$f.mp3; done) > $@

%.rips: %.names %.make %.oggs %.mp3s
	[ -d $@ ] || mkdir $@
	rm -f $@/[0-9][0-9]-*
	make -f $*.make
	$(TRACKINFO) format=symlinks dir=$@ @$*.names

%.re-rip: %.names %.make %.oggs %.mp3s
	[ -d $*.rips ] || mkdir $*.rips
	rm -f $*.rips/[0-9][0-9]-*
	make -f $*.make
	$(TRACKINFO) format=symlinks dir=$*.rips @$*.names

## rules to make ogg and mp3 files
#	We now make them from the normalized versions in Premaster
#	unless the make variable NO_PREMASTER is defined.  The NO_PREMASTER
#	versions only work in, e.g., concert directories where the .wav
#	files are local or locally-symlinked.  

%.ogg: Premaster/%.wav
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg track=$< \
	  title="$(TITLE)" $*)
%.mp3: Premaster/%.wav
	sox $< -t wav -b 16 - | \
	lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3  title="$(TITLE)" $*) $@


###### Targets ########################################################

### All: doesn't do much, just builds the TOC and lists

all::
	@echo $(TYPE) $(SHORTNAME)/ "($(TITLE))"
	@echo performer: $(PERFORMER)

reindex::
	rm -f *.names *.files *.list 
	rm -f *.short.html *.long.html *.extras.html

clean::
	rm -f *.names *.files *.list 
	rm -f *.short.html *.long.html *.extras.html

ifdef RELEASED
all::	$(TRACKLISTS)

ifeq ($(strip $(shell test -d Master && echo -n 1)),1)
all::	$(BASEPFX)toc time
endif
ifeq ($(strip $(shell test -d Rips && echo -n 1)),1)
all::	mp3s.m3u oggs.m3u
endif

endif # end of all targets for CD

all:: $(SONGFILES)
	@echo songfiles: $(SONGFILES)

all:: $(SONGLISTS) 


ifeq ($(strip $(shell test -f songs && echo -n 1)),1)
all::	est-time
endif

### update: do this to capture changed track files

.PHONY: update
update:: update-tracks normalized update-master 
update:: all

### re-list, clean-lists
.PHONY: re-list clean-lists
clean-lists:
	rm -f $(SONGLISTS)

re-list: 
	rm -f $(SONGLISTS)
	$(MAKE) $(SONGLISTS)

### Table of contents for CD-R:
#	Standard target: toc-file

# === needs work - there may be multiple toc files now

.PHONY:	toc-file
toc-file: $(BASEPFX)toc

# FIXME: track lengths are bad.
$(BASEPFX)toc: $(TRACKFILE) $(TRACK_DATA)
	$(TRACKINFO) -cd $(TOC_FLAGS) title="$(TITLE)" $(SONGS) > $@
	$(CDRDAO) show-toc $(BASEPFX)toc | tail -1

### Playlists:

# === the playlist stuff is completely broken

# really need to get this the hard way...
URL_PREFIX = http://theStarport.com/Steve_Savitzky/Albums/$(MYNAME)
mp3s.m3u: $(TRACKFILE)
	echo -n > $@
	for f in $(MP3S); do \
		echo $(URL_PREFIX)/$$f		>> $@ ;\
	done

oggs.m3u: $(TRACKFILE)
	echo -n > $@
	for f in $(OGGS); do \
		echo $(URL_PREFIX)/$$f		>> $@ ;\
	done


### Utilities:

## show the total time (on stdout)

.PHONY: time est-time
time:	$(BASEPFX)toc
	@$(CDRDAO) show-toc $(BASEPFX)toc 2>&1 | tail -1

est-time: $(BASEPFX)short.list
	@echo Estimated `tail -1 $(BASEPFX)short.list`

## List tracks to STDOUT in various formats:

.PHONY: lstracks
lstracks: list-tracks

.PHONY: list-tracks
list-tracks: $(TRACKFILE)
	@$(LIST_TRACKS) $(SONGS)

.PHONY: lsti
lsti: list-track-info

.PHONY: list-track-info 
list-track-info: $(TRACKFILE)
	@echo TRACKDIR=$(TRACKDIR)
	@$(LIST_TRACKS) -i $(SONGS)

.PHONY: list-text
list-text: $(TRACKFILE)
	@$(TRACKINFO) $(TRACKLIST_FLAGS) format=list.text -t -T $(TRACKS)

.PHONY: list-long-text $(LOCAL_METADATA)
list-long-text: $(TRACKFILE)
	@$(TRACKINFO) $(TRACKLIST_FLAGS) --long --credits -t -T \
		format=list.text $(TRACKS)

.PHONY:	list-html $(LOCAL_METADATA)
list-html: $(TRACKFILE)
	@$(TRACKINFO) $(TRACKLIST_FLAGS) --long --credits \
		format=list.html $(TRACKS)

.PHONY:	list-html-sound $(LOCAL_METADATA)
list-html-sound: $(TRACKFILE)
	@$(TRACKINFO) $(TRACKLIST_FLAGS) --sound --long format=list.html \
		$(TRACKS)

.PHONY: list-times
list-times: 
	@cd $(TRACKDIR); for d in $(SONGS); do 		\
		ls -l $$d/notes 			\
			`ls -tr $$d/*.aup | tail -1; 	\
			 ls -tr $$d/*.wav | tail -1;` ;	\
	done

## List variables that refer to files.
#  Useful for scripting as well as debugging.

.PHONY:	list-files list-sources list-songs list-missing
list-files: $(TRACKFILE)
	@$(TRACKINFO) format=cd-files $(TRACKS)

list-sources: 
	@echo $(TRACK_SOURCES)

list-songs: 
	@echo $(SONGS)

list-lyrics: 
	@echo $(SONGS)

list-print:
	@echo $(PRINT_FILES)

list-missing:
	@for f in $(SONGS); do \
		if [ ! -e Premaster/$$f.wav ]; then echo $$f; fi \
	done

.PHONY: list-oggs list-mp3s play
list-oggs:
	@ for f in $(SONGS); do \
		if [ -e $$f.ogg ]; then echo $$f.ogg; fi \
	done

list-mp3s:
	@ for f in $(SONGS); do \
		if [ -e $$f.mp3 ]; then echo $$f.mp3; fi \
	done

play: oggs
	$(PLAYER) `make list-oggs`


## Print lyrics either in leadsheet (single-page) or songbook format
##	use print-songbook with TGl's fully-chorded lead sheets
.PHONY: print-lyrics print-songbook

print-lyrics: $(PRINT_FILES)
	@for f in $(PRINT_FILES); do psselect -p1 $$f | lpr; done 

print-songbook: $(PRINT_FILES)
	@for f in $(PRINT_FILES); do echo $$f; lp $$f; done


### Premaster
#
#	When we export a track, we normally put it in Premaster.  This
#	is particularly easy when we can do export-multiple in
#	Audacity, but it works for individual tracks, too.  This
#	replaces the old, and mostly broken, logic we had for finding
#	the most recent take in a track directory.  If, instead, the
#	track files are in this directory, we can indicate that by
#	setting the makefile variable NO_PREMASTER
#
# 	Files in Premaster can be in any format as long as sox can
#	read them and convert them to 16-bit CD audio tracks.  It is
#	convenient to do premastering steps like normalization on .wav
#	files, because normalize-audio can't handle .flac.  by setting
#	the makefile variable NO_PREMASTER
#
#	It is no longer necessary to kludge up a "mytracks.make" file.

Master/%.wav:  Premaster/%.wav | Master
	sox $? -b 16 $@

Master/%.wav:  Premaster/%.flac | Master
	sox $? -b 16 $@

.PHONY: oggs mp3s
oggs:  $(OGGS)

mp3s:  $(MP3S)

clean::
	rm -f *.ogg *.mp3


### Make the subdirectories:

# Tracks directory

Tracks: 
	mkdir Tracks

# Master directory

Master:
	mkdir Master

# Premaster directory
#	At some point we may need to build a Premaster/Makefile; 
#	it's certainly necessary when there's an ISO subdirectory.
#	wing it for now.

Premaster:
	mkdir Premaster

### Normalization:
# 	Probably don't want the --mix flag on normalize.
#	That would make bring everything to the same average level,
#	rather than maximizing each track separately.  
#	Probably don't want -q, either -- it's a long time to go without
#	output, and we'll almost always be doing it from the command line.

# === no good way to do exception parameters.  perl script?  
# === $(MAKE) normalize-fixup?
Premaster/normalized: $(wildcard Premaster/*.wav)
	for f in $?; do normalize-audio  $$f; done
	echo `date` $? > $@
	touch Premaster

.PHONY: test-normalize normalized
test-normalize: 
	cd Premaster; normalize-audio -n *.wav

normalized: Premaster/normalized

clean::
	rm -f Premaster/normalized

#   Premaster/ISO is only needed if we're building a CDROM or dual-session
#	disk; it contains the directory tree that gets rolled up into the
#	.iso file.

### make a dated "snapshot" with the track list and TOC file.
# 	This is mainly for test, which has highly variable contents, but
#	can be useful as a record of intermediate states.  The TOC includes
#	the filenames for the .wav files.
#
#	It wouldn't hurt to put the snapshot into a dated subdirectory.
#

yyyymmdd := $(shell date +%Y%m%d)

.PHONY: snapshot
snapshot:: $(SHORTNAME).$(yyyymmdd).toc $(SHORTNAME).$(yyyymmdd).tracks

$(SHORTNAME).$(yyyymmdd).toc: $(SHORTNAME).toc
	cp $? $@

$(SHORTNAME).$(yyyymmdd).tracks: $(SHORTNAME).tracks
	cp $? $@

### Burn a CD-R
#	Note that you no longer have to be root in order to run cdrdao, but
#	you don't get the advantage of realtime scheduling if you're not.
#	Speed is parametrized, default 8:  you can get away with just about 
#	anything for data, but audio is more picky.  I've never had any
#	problems with 8, and _have_ had problems with 24.
#
#	Make masters at 4 or lower.  verify with qpxtool (plextor drives) or
#	readom -c2scan dev=ATA:1,1,0
#
# 	Note that it is no longer necessary to specify a device
#	Note that if you want to burn a mixed disk, you MUST eject and reload
#	the disk before reading the msinfo.
#

SPEED=--speed 8
.PHONY: cdr
cdr: $(BASEPFX)toc
	@[ `whoami` = "root" ] || (echo "cdrdao should be run by root")
	/usr/bin/time $(CDRDAO) write --driver generic-mmc --buffers 128 --eject \
	  --device /dev/sr0 $(SPEED) $(BASEPFX)toc

.PHONY: try-cdr
try-cdr: $(BASEPFX)toc
	@[ `whoami` = "root" ] || (echo "cdrdao should be run by root")
	/usr/bin/time $(CDRDAO) write --driver generic-mmc --buffers 128 --simulate \
	  --device /dev/sr0 $(SPEED) $(BASEPFX)toc

.PHONY: tao
tao: 	
	@[ `whoami` = "root" ] || (echo "wodim should be run by root")
	$(WODIM) -pad -tao -audio $(TRACK_DATA)

try-tao: 	
	@[ `whoami` = "root" ] || (echo "wodim should be run by root")
	$(WODIM) -pad -tao -audio --dummy $(TRACK_DATA)

### Setup

.PHONY: setup

setup:: Tracks Premaster $(DEFAULT_SONGFILE)

ifdef DEFAULT_SONGFILE

$(DEFAULT_SONGFILE):
	echo '# $@ for $(TITLE)' > $@

endif

#######################################################################

### Test - list important variables

reportVars += LONGNAME TITLE TYPE DATE SONGS SONGFILES PRINT_FILES DEFAULT_SONGFILE
reportVars += TRACKS TRACK_SOURCES TRACK_DATA
reportStrs += TITLE EVNAME

