#!/usr/bin/make  ### Makefile template for album directories
#	$Id: album.make,v 1.17 2010-10-14 06:48:16 steve Exp $
#
#  This template is meant to be included in the Makefile of an "album" 
#	directory.  The usual directory tree looks like:
#
#  top/
#	Songs		song information (.flk files)
#	Tracks		recorded tracks; a subdirectory per song
#	Albums		a subdirectory for each album
#	Tools		(this directory) scripts and makefile templates
#
#  The album directory contains a file called songs or [name].tracks with
#  the shortnames of the album's tracks.  The most recent .wav file
#  in each track directory is used.  (Eventually one ought to be able to
#  specify the take, but that would require substantial refactoring.)

### Open Source/Free Software license notice:
 # The contents of this file may be used under the terms of the GNU
 # Lesser General Public License Version 2 or later (the "LGPL").  The text
 # of this license can be found on this software's distribution media, or
 # obtained from  www.gnu.org/copyleft/lesser.html	
###						    :end license notice	###

### Usage:
#
#   Variables:
#	TOOLDIR		the directory containing this file
#	SHORTNAME	the shortname (directory name) of the album
#	LONGNAME	the name of the album's collection directory:
#			(title with words capitalized and separated by _)
#	TITLE		the full, plaintext title of the album 
#			  special characters must be quoted for use in "..."
#
#   Targets:
#	all		makes the TOC and track-list files
#	lstracks	list track information (== lstracks for this album)
#	cdr		burns a CD-R
#	try-cdr		does a fake burn.  Recommended to test TOC integrity.
#	archive		make a local copy of all track data (.wav) files

### Site-dependent variables:

## Directories:
#	CAUTION: the really critical one here is SONGDIR; if it doesn't
#		 have the .flk files in it, you're hosed.  These days it's
#		 actually $(BASEDIR)/Lyrics; .../Songs has a directory
#		 per song, but no .flk or .ps files.

BASEDIR		:= $(subst /Tools/..,/,$(TOOLDIR)/..)
#BASEDIR		= ../..
ifeq ($(shell [ -d ./Lyrics ] && echo Lyrics), Lyrics)
SONGDIR 	:= ./Lyrics
else
SONGDIR 	:= $(BASEDIR)Lyrics
endif
LYRICDIR	= $(SONGDIR)

ifeq ($(shell [ -f make.config ] || echo noconfig),)
	include $(shell /bin/pwd)/make.config
endif

ifeq ($(shell [ -d ./Tracks ] || echo notracks),)
	TRACKDIR	:= ./Tracks
else
	TRACKDIR	:= $(BASEDIR)/Tracks
endif

## Directory where ogg and mp3 files end up. 
#	It's essentially a stand-alone web album
#
RIPS=Rips

## Directory to publish to === doesn't seem to be used now
#PUBDIR		= ../PUBDIR/$(MYNAME)


### Programs

## Metadata extraction and formatting programs:

TRACKINFO := $(TOOLDIR)/TrackInfo.pl
ifdef PERFORMER
  TRACKINFO := $(TRACKINFO) performer="$(PERFORMER)"
endif

LIST_TRACKS = $(TOOLDIR)/list-tracks

## CD writing.  wodim and genisoimage are new as of Debian Etch.

WODIM = $(shell if [ -x /usr/bin/wodim ]; \
		then echo wodim; else echo cdrecord; fi)

GENISOIMAGE = $(shell if [ -x /usr/bin/genisoimage ]; \
		      then echo genisoimage; else echo mkisofs; fi)

CDRDAO = /usr/bin/cdrdao

## Devices (for burning):
#	For a 2.4 kernel with one IDE-SCSI device, use DEVICE=0,0,0
#	For a 2.6 kernel with the burner on /dev/hdd, use ATA:1,1,0
DEVICE		= ATA:1,1,0

### From here on it's constant ###

###### Rules ##########################################################

### Things are changing.  
#
#	Prior to 2008 we used $(SHORTNAME).tracks for the tracklist 
#	of a CD.  Concerts were handled using concert.make.  Around
#	the beginning of 2008 we switched to using "songs" as the
#	main songlist, and %.songs for secondary lists such as 
#	individual sessions or concerts in a field recording directory.
#
#	At this point the plan is to _continue_ using .tracks for
#	a CD tracklist, and to insist on having only one per directory.
#	Similarly we'll use Rips for the rips of the CD's tracks.
#	Now we use songs as the main song list, and prefix.songs in
#	field recordings to break out individual concerts or sessions.
#
# 	Similarly we now want rips %.rips where we used to have Rips; 
#	it will probably be best to save Rips for the CD.
#
#	We blithely continue to lump all metadata and WAV files into
#	the Master, Premaster, and Tracks; this makes sense because
#	field recordings in Tracks often mix things (like concerts or
#	two-shots) that we want to split later.  
#
#	For the moment all .ogg and .mp3 files are in the main directory;
#	this makes for shorter pathnames, but eventually they need to 
#	be symlinks into the various .rips directories.
#
#	We need a separate set of rules for, e.g., songs and %.songs


### See whether we have a CD, indicated by a *.tracks or songs file
#	The .tracks file is *only* used for the CD tracks; it's possible
#	to have both a .tracks file and a .songs file.
#	It is an error to have both [shortname].tracks and songs.


TRACKFILE = $(wildcard songs $(SHORTNAME).tracks)
ifneq ($(TRACKFILE),)

RELEASED = 1

### The following definitions are used for "albums", where we're mastering
#	a single CD and we have a single primary list of tracks.

# Track list file.
#   TRACKS= @<file> is the shortcut we use for TrackInfo.pl

TRACKS	  = @$(TRACKFILE)

# Base prefix for derived files:
ifneq ($(TRACKFILE),songs)
BASEPFX := $(SHORTNAME).
endif

# Get the shortnames of all the songs from $(TRACKFILE)
#	Ignore comment lines.  $(SONGS) has *extended* shortnames
#	that include the prefixes and suffixes of concert tracks.
#
SONGS := $(shell grep -v '\#' $(TRACKFILE))

# $(SHORTNAMES) is the songfile shortnames that we need to select
#	the appropriate .flk files in $(SONGDIR) for dependencies.
SHORTNAMES := $(shell $(TRACKINFO) format=songs $(TRACKS))

# We know at this point that all the metadata is in SONGDIR
FLK_FILES := $(shell for f in $(SHORTNAMES); do \
		[ -f $(SONGDIR)/$$f.flk ] && echo $(SONGDIR)/$$f.flk; \
		[ -f ./$$f.flk ] && echo ./$$f.flk; \
		done)

# PRINT_FILES -- the printable (.ps) lyrics
PRINT_FILES := $(shell for f in $(SHORTNAMES); do \
		[ -f $(SONGDIR)/$$f.ps ] && echo $(SONGDIR)/$$f.ps; \
		done)

OGGS = $(shell for f in $(SONGS); do echo $$f.ogg; done)
MP3S = $(shell for f in $(SONGS); do echo $$f.mp3; done)

# LOCAL_METADATA -- the local .flk files mainly used for local descriptions,
#	performers, and so on.

LOCAL_METADATA = $(wildcard *.flk)

# TRACK_SOURCES -- the original .wav files for the tracks
#	They are first copied into Premaster/WAV, normalized, then
#	converted to 16-bit .wav files in Master.

TRACK_SOURCES = $(shell $(TRACKINFO) format=files $(TRACKS))

# TRACK_DATA -- the data files in Master, in the correct order for burning
#

TRACK_DATA = $(shell $(TRACKINFO) format=cd-files $(TRACKS))

## Compute targets

TRACKLISTS = $(BASEPFX)short.list $(BASEPFX)files $(BASEPFX)long.list \
	$(BASEPFX)short.html $(BASEPFX)long.html $(BASEPFX)extras.html
endif ### CD


### Look for songs and *.songs.

SONGFILES=$(wildcard *songs)
ifneq ($(SONGFILES),,)


ifeq ($(wildcard songs),songs)  # compute targets for the default, "songs"
  SONGLISTS := short.list long.list short.html long.html extras.html
  SUBMAKES := mytracks.make
  RIPDIRS := Rips
endif

ifneq ($(wildcard *.songs),)	# compute targets for *.songs
  DOTSONGS=$(wildcard *.songs)
  SONGLISTS += \
	$(subst .songs,.names, $(DOTSONGS)) \
	$(subst .songs,.files, $(DOTSONGS)) \
	$(subst .songs,.oggs, $(DOTSONGS)) \
	$(subst .songs,.mp3s, $(DOTSONGS)) \
	$(subst .songs,.short.list, $(DOTSONGS))\
	$(subst .songs,.long.list, $(DOTSONGS)) \
	$(subst .songs,.short.html, $(DOTSONGS)) \
	$(subst .songs,.long.html, $(DOTSONGS)) \
	$(subst .songs,.extras.html, $(DOTSONGS)) 

  SUBMAKES += $(subst .songs,.make, $(DOTSONGS))
  RIPDIRS += $(subst .songs,.rips, $(DOTSONGS)) 
endif


endif

###### Targets ########################################################

### All: doesn't do much, just builds the TOC and lists

all::
	@echo album $(SHORTNAME)/ "($(TITLE))"
	@echo performer: $(PERFORMER)

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

.PHONY:	toc-file
toc-file: $(BASEPFX)toc

# Note that the toc-file does NOT depend on $(TRACK_DATA).
$(BASEPFX)toc: $(TRACKFILE) $(TRACK_SOURCES)
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

## List, mainly for debugging, various make variables

.PHONY:	list-files list-sources list-songs
list-files: $(TRACKFILE)
	@$(TRACKINFO) format=cd-files $(TRACKS)

list-sources: 
	@echo $(TRACK_SOURCES)

list-songs: 
	@echo $(SONGS)


### Rules for things that depend on $(TRACKFILE)

ifneq ($(TRACKFILE),)
$(BASEPFX)short.list: $(TRACKFILE)
	$(TRACKINFO) $(TRACKLIST_FLAGS) format=list.text -t -T $(TRACKS) > $@

$(BASEPFX)long.list: $(TRACKFILE)
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long --credits  -T \
		format=list.text $(TRACKS) > $@

$(BASEPFX)credits.list: $(TRACKFILE)
	$(TRACKINFO)  --credits  -T \
		format=list.text $(TRACKS) > $@

$(BASEPFX)long.html: $(TRACKFILE)  # $(FLK_FILES)
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long --credits -t \
		format=list.html $(TRACKS) > $@

$(BASEPFX)short.html: $(TRACKFILE)  # $(FLK_FILES)
	$(TRACKINFO) $(TRACKLIST_FLAGS) format=list.html -t $(TRACKS) > $@

# [name].extras.html includes links to the sound files; it's used
#	most notably to provide "extra features" for people who have
#	preordered or purchased albums.
$(BASEPFX)extras.html: $(TRACKFILE)  # $(FLK_FILES)
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long  --credits \
		--sound format=list.html \
		$(TRACKS) > $@

$(BASEPFX)files: $(TRACKFILE)
	@$(TRACKINFO) format=files $(TRACKS) > $@

$(BASEPFX)names: $(TRACKFILE)
	grep -v '^#' $< | grep -ve '^$$' > $@

Rips: $(BASEPFX)names $(OGGS) $(MP3S)
	[ -d $@ ] || mkdir $@
	rm -f $@/[0-9][0-9]-*
	make -f mytracks.make
	$(TRACKINFO) format=symlinks dir=$@ @$<

re-rip: $(BASEPFX)names  $(OGGS) $(MP3S)
	[ -d Rips ] || mkdir Rips
	rm -f Rips/[0-9][0-9]-*
	make -f mytracks.make
	$(TRACKINFO) format=symlinks dir=Rips @$<
endif

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



## Print lyrics either in leadsheet (single-page) or songbook format
##	use print-songbook for now with TGl's fully-chorded lead sheets
.PHONY: print-lyrics print-songbook

print-lyrics: $(PRINT_FILES)
	@for f in $(PRINT_FILES); do psselect -p1 $$f | lpr; done 

print-songbook: $(PRINT_FILES)
	@for f in $(PRINT_FILES); do lpr $$f; done 

## Move track directories from ../../Tracks to ./Tracks
#	this is to move to the new tree layout in which each album is 
#	self-contained. 
.PHONY: snarf-tracks
snarf-tracks:	Tracks
	@for d in $(SONGS); do 						\
	    if [ ! -d Tracks/$$d ] && [ -d ../../Tracks/$$d ]; then	\
		echo moving ../../Tracks/$$d to Tracks/;		\
		mv ../../Tracks/$$d Tracks/;				\
	    fi								\
	done

.PHONY: list-misplaced-tracks
list-misplaced-tracks:	
	@for d in $(SONGS); do 						\
	    if [ ! -d Tracks/$$d ] && [ -d ../../Tracks/$$d ]; then	\
		echo should move ../../Tracks/$$d to Tracks/;		\
	    fi								\
	done

Tracks: 
	mkdir Tracks


### Update Premaster/WAV by importing track data
#	This is not done by default because normalization and other 
#	premastering is done there; as a side-effect we get an archive
#	of exactly what track data is on the disk.

#	This has to be done using an auxiliary Makefile, mytracks.make,
#	because the track data files keep changing their names as we
#	work on them.  The only exception is, e.g., concerts, where the 
#	original wav files are local to this directory.  This is indicated
#	by setting the makefile variable NO_PREMASTER

.PHONY: update-tracks update-master 
update-tracks: Premaster Premaster/WAV mytracks.make
	$(MAKE) -f mytracks.make update-tracks
	touch Premaster/WAV

ifdef NO_PREMASTER
update-master: $(TRACK_SOURCES) $(TRACKFILE) Master
	rsync  --copy-links -v -p $(TRACK_SOURCES) Master
else
update-master: Premaster Premaster/WAV mytracks.make Master
	$(MAKE) -f mytracks.make update-master
endif

### Make ogg and mp3 files and other things that depend on tracks.
#
#	Rules like %.ogg $(shell $(TRACKINFO) format=files %) 
#	apparently don't allow make to detect the dependency.  Grump.
#
#	So instead, we gather them all up into mytracks.make and
#	run make -f mytracks.make
#
#	Also note that we use "-w -t .wav" to force sox to make 16-bit
#	.wav files; the -t is there because otherwise sox gets confused
#	by filenames that have dots in them, like foo.bar.wav.  -w is
#	no longer supported as of lenny/karmic
#
mytracks.make: $(TRACK_SOURCES) $(TRACKFILE)
	echo '# mytracks.make' $(shell date)		 > $@
	@echo 'TRACKINFO = $(TRACKINFO)'			>> $@
	@echo 'TITLE	 = '"$(TITLE)"				>> $@
	@echo 'TOOLDIR	 = $(TOOLDIR)'				>> $@
	@echo 'SONGS	 = $(SONGS)'				>> $@
	@echo 'include $$(TOOLDIR)/track-depends.make'		>> $@
	@echo 'all:: oggs mp3s'					>> $@
	@echo 'oggs: $$(OGGS)'					>> $@
	@echo 'mp3s: $$(MP3S)'					>> $@
	@for f in $(SONGS); do	\
		tf=`$(TRACKINFO) format=files $$f`;			\
		pf=Premaster/WAV/$$f.wav;				\
		echo Premaster/WAV/$$f.wav: $$tf	 	>> $@;	\
		echo "	"rsync  --copy-links -v -p '$$< $$@'	>> $@;	\
		echo update-tracks:: Premaster/WAV/$$f.wav	>> $@;	\
		echo Master/$$f.wav: Premaster/WAV/$$f.wav 	>> $@;	\
		echo "	"sox '$$<  -t cdr - |'			\
			 sox '-t cdr - -t .wav $$@'		>> $@;	\
		echo update-master:: Master/$$f.wav	 	>> $@;	\
	done

### Now do *.make for all the prefixes
%.make: %.songs 
	echo '# $@' $(shell date)		 	> $@
	@echo 'TRACKINFO = $(TRACKINFO)'			>> $@
	@echo 'TITLE	 = '"$(TITLE)"				>> $@
	@echo 'TOOLDIR	 = $(TOOLDIR)'				>> $@
	@echo 'SONGS	 = '`cat $*.names`			>> $@
	@echo 'include $$(TOOLDIR)/track-depends.make'		>> $@
	@echo 'all:: oggs mp3s'					>> $@
	@echo 'oggs: '`cat $*.oggs`				>> $@
	@echo 'mp3s: '`cat $*.mp3s`				>> $@
	@for f in `cat $*.names`; do	\
		tf=`$(TRACKINFO) format=files $$f`;			\
		pf=Premaster/WAV/$$f.wav;				\
		echo Premaster/WAV/$$f.wav: $$tf	 	>> $@;	\
		echo "	"rsync  --copy-links -v -p '$$< $$@'	>> $@;	\
		echo update-tracks:: Premaster/WAV/$$f.wav	>> $@;	\
		echo Master/$$f.wav: Premaster/WAV/$$f.wav 	>> $@;	\
		echo "	"sox '$$< -b 16 -t cdr - |'			\
			 sox '-t cdr - -t .wav $$@'		>> $@;	\
		echo update-master:: Master/$$f.wav	 	>> $@;	\
	done


# this doesn't work because it creates output files with funny names
# 		echo "	"shntool pad $$@			>> $@;	\

# make ogg and mp3 files
#	We now make them from the normalized versions in Premaster/WAV
#	unless the make variable NO_PREMASTER is defined.  The NO_PREMASTER
#	versions only work in, e.g., concert directories where the .wav
#	files are local or locally-symlinked.  Otherwise we'd have to
#	put the dependencies in mytracks.make.

ifdef NO_PREMASTER
%.ogg: 
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg title="$(TITLE)" $*)
%.mp3: 
	sox $(shell $(TRACKINFO) format=files $*) -b 16 -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 title="$(TITLE)" $*) $@
else
%.ogg:  Premaster/WAV/%.wav
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg track=$< \
	  title="$(TITLE)" $*)
%.mp3: Premaster/WAV/%.wav
	sox $< -t wav -b 16 - | \
	lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 title="$(TITLE)" $*) $@
endif

# The rule for oggs and mp3s used to use mytracks.make in, e.g.,
#	$(MAKE) -f mytracks.make oggs
#
#	This is no longer necessary, since we make them from the 
#	(presumably normalized and tweaked) files in Premaster/WAV
#	using the rules above, or from .wav files (or symlinks) in
#	this directory.

.PHONY: oggs mp3s mytracks
oggs:  $(OGGS)

mp3s:  $(MP3S)

mytracks: mytracks.make

### Master directory

Master:
	mkdir Master

### Premaster directory
#	At some point we may need to build a Premaster/Makefile; 
#	it's certainly necessary when there's an ISO subdirectory.
#	wing it for now.

Premaster:
	mkdir Premaster

#   Premaster/WAV contains the (typically 32-bit) .wav files that are
#	normalized and converted to 16-bit files (in Master) for putting
#	on the CD.  Now that the default is to export 32-bit files from
#	Audacity, we have to make the intermediate files this way.
#
#	We don't make update-tracks automatically except to initially
#	populate the directory.
#

Premaster/WAV:
	mkdir Premaster/WAV
	[ -f mytracks.make ] && make update-tracks

#   Normalization:
# 	Probably don't want the --mix flag on normalize.
#	That would make bring everything to the same average level,
#	rather than maximizing each track separately.  
#	Probably don't want -q, either -- it's a long time to go without
#	output, and we'll almost always be doing it from the command line.

# === no good way to do exception parameters.  perl script?  
# === $(MAKE) normalize-fixup?
Premaster/WAV/normalized: $(wildcard Premaster/WAV/*.wav)
	for f in $?; do normalize-audio  $$f; done
	echo `date` $? > $@
	touch Premaster/WAV

.PHONY: test-normalize normalized
test-normalize: Premaster/WAV
	cd Premaster/WAV; normalize-audio -n *.wav

normalized: Premaster/WAV/normalized

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
#
#SPEED=--speed 8
.PHONY: cdr
cdr: $(BASEPFX)toc
	@[ `whoami` = "root" ] || (echo "cdrdao should be run by root")
	/usr/bin/time $(CDRDAO) write --driver generic-mmc-raw --eject \
	  $(SPEED) $(BASEPFX)toc

.PHONY: try-cdr
try-cdr: $(BASEPFX)toc
	@[ `whoami` = "root" ] || (echo "cdrdao should be run by root")
	/usr/bin/time $(CDRDAO) write --driver generic-mmc-raw --simulate \
	  $(BASEPFX)toc

.PHONY: tao
tao: 	
	@[ `whoami` = "root" ] || (echo "wodim should be run by root")
	$(WODIM) -pad -tao -audio $(TRACK_DATA)

