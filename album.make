### Makefile template for album directories
#	$Id: album.make,v 1.10 2007-04-28 15:37:15 steve Exp $
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
#  The album directory contains a file called [name].tracks with
#  the shortnames of the album's tracks.  The most recent .wav file
#  in each track directory is used.  (Eventually one ought to be able to
#  specify the take, but that would require substantial refactoring.)

### Usage:
#
#   Variables:
#	TOOLDIR		the directory containing this file
#	SHORTNAME	the shortname (directory name) of the album
#	LONGNAME	the name of the album's collection directory:
#			(title with words capitalized and separated by _)
#	TITLE		the full, plaintext title of the album
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
#		 have the .flk files in it, you're hosed.

BASEDIR		= $(subst /Tools/..,/,$(TOOLDIR)/..)
#BASEDIR		= ../..
SONGDIR 	= $(BASEDIR)/Songs
TRACKDIR	= $(BASEDIR)/Tracks

## Directory to publish to

PUBDIR		= ../PUBDIR/$(MYNAME)

## Programs:

TRACKINFO = $(TOOLDIR)/TrackInfo.pl
LIST_TRACKS = $(TOOLDIR)/list-tracks

# In some cases the old CDRDAO (in /usr/local/bin) works better.
#CDRDAO = /usr/local/bin/cdrdao
CDRDAO = /usr/bin/cdrdao

# Look for the new (Etch) replacements for cdrecord and mkisofs

WODIM = $(shell if [ -x /usr/bin/wodim ]; \
		then echo wodim; else echo cdrecord; fi)

GENISOIMAGE = $(shell if [ -x /usr/bin/genisoimage ]; \
		      then echo genisoimage; else echo mkisofs; fi)

## Devices (for burning):
#	For a 2.4 kernel with one IDE-SCSI device, use DEVICE=0,0,0
#	For a 2.6 kernel with the burner on /dev/hdd, use ATA:1,1,0
DEVICE		= ATA:1,1,0

### From here on it's constant ###

###### Rules ##########################################################

# Want to snarf the track data -- could use TrackInfo -get-track-data
# but there's probably a simple way to do it in pure make.

# Name to use for files.
NAME=$(SHORTNAME)

# Track file.  
#   TRACKS= @<file> is the shortcut we use for TrackInfo.pl
TRACKFILE = $(NAME).tracks
TRACKS	  = @$(TRACKFILE)

# Get the shortnames of all the songs from $(NAME).tracks
#	Ignore comment lines.  $(SONGS) has *extended* shortnames
#	that include the prefixes and suffixes of concert tracks.
#
SONGS = $(shell grep -v '\#' $(TRACKFILE))

# $(SHORTNAMES) is the songfile shortnames that we need to select
#	the appropriate .flk files in $(SONGDIR) for dependencies.
SHORTNAMES := $(shell $(TRACKINFO) format=songs $(TRACKS))

FLK_FILES := $(shell for f in $(SHORTNAMES); do echo \
		     $(SONGDIR)/$$f.flk; done)

OGGS = $(shell for f in $(SONGS); do echo $$f.ogg; done)
MP3S = $(shell for f in $(SONGS); do echo $$f.mp3; done)

# TRACK_SOURCES -- the original .wav files for the tracks
#	They are first copied into Premaster/WAV, normalized, then
#	converted to 16-bit .wav files in Master.

TRACK_SOURCES = $(shell $(TRACKINFO) format=files $(TRACKS))

# TRACK_DATA -- the data files in Master, in the correct order for burning
#

TRACK_DATA = $(shell $(TRACKINFO) format=cd-files $(TRACKS))

#%.wav: $(TRACKDIR)/%
#	@echo snagging $@ from `ls $?/*.wav | tail -1`
#	rsync `ls $?/*.wav | tail -1` $@

###### Targets ########################################################

### All: doesn't do much, just builds the TOC and lists

all::
	@echo album $(NAME)/ '($(TITLE))'

all::	$(NAME).list $(NAME).long.list 
all::	$(NAME).html $(NAME).extras.html
all::	mp3s.m3u oggs.m3u
all::	$(NAME).toc time

### update: do this to capture changed track files

.PHONY: update
update:: update-tracks normalized update-master 
update:: all

### Table of contents for CD-R:
#	Standard target: toc-file

.PHONY:	toc-file
toc-file: $(NAME).toc

# Note that the toc-file does NOT depend on $(TRACK_DATA).
$(NAME).toc: $(NAME).tracks $(TRACK_SOURCES)
	$(TRACKINFO) -cd $(TOC_FLAGS) title='$(TITLE)' $(SONGS) > $@
	$(CDRDAO) show-toc $(NAME).toc | tail -1

### Playlists:

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

.PHONY: time
time:	$(NAME).toc
	@$(CDRDAO) show-toc $(NAME).toc 2>&1 | tail -1

## List tracks to STDOUT in various formats:

.PHONY: lstracks
lstracks: list-tracks

.PHONY: list-tracks
list-tracks: $(NAME).tracks
	@$(LIST_TRACKS) $(SONGS)

.PHONY: lsti
lsti: list-track-info

.PHONY: list-track-info 
list-track-info: $(NAME).tracks
	@$(LIST_TRACKS) -i $(SONGS)

.PHONY: list-text
list-text: $(NAME).tracks
	@$(TRACKINFO) $(TRACKLIST_FLAGS) format=list.text $(TRACKS)

.PHONY: list-long-text
list-long-text: $(NAME).tracks
	@$(TRACKINFO) $(TRACKLIST_FLAGS) --long format=list.text $(TRACKS)

.PHONY:	list-html 
list-html: $(NAME).tracks
	@$(TRACKINFO) $(TRACKLIST_FLAGS) --long format=list.html $(TRACKS)

.PHONY:	list-html-sound
list-html-sound: $(NAME).tracks
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
list-files: $(NAME).tracks
	@$(TRACKINFO) format=cd-files $(TRACKS)

list-sources: 
	@echo $(TRACK_SOURCES)

list-songs: 
	@echo $(SONGS)

## List tracks to a file:

$(NAME).list: $(NAME).tracks
	$(TRACKINFO) $(TRACKLIST_FLAGS) format=list.text $(TRACKS) > $@

$(NAME).long.list: $(NAME).tracks
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long format=list.text $(TRACKS) > $@

$(NAME).html: $(NAME).tracks  $(FLK_FILES)
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long format=list.html $(TRACKS) > $@

# [name].extras.html includes links to the sound files; it's used
#	most notably to provide "extra features" for people who have
#	preordered or purchased albums.
$(NAME).extras.html: $(NAME).tracks  $(FLK_FILES)
	$(TRACKINFO) $(TRACKLIST_FLAGS) --long --sound format=list.html \
		 $(TRACKS) > $@

$(NAME).files: $(NAME).tracks
	@$(TRACKINFO) format=files $(TRACKS) > $@

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
update-master: $(TRACK_SOURCES) $(NAME).tracks Master
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
mytracks.make: $(TRACK_SOURCES) $(NAME).tracks
	echo '# mytracks.make' $(shell date)		 > $@
	@echo 'TRACKINFO = $(TRACKINFO)'			>> $@
	@echo 'TITLE	 = $(TITLE)'				>> $@
	@echo 'TOOLDIR	 = $(TOOLDIR)'				>> $@
	@echo 'SONGS	 = $(SONGS)'				>> $@
	@echo 'include $$(TOOLDIR)/track-depends.make'		>> $@
	@echo 'oggs: $$(OGGS)'					>> $@
	@echo 'mp3s: $$(MP3S)'					>> $@
	@for f in $(SONGS); do	\
		tf=`$(TRACKINFO) format=files $$f`;			\
		pf=Premaster/WAV/$$f.wav;				\
		echo Premaster/WAV/$$f.wav: $$tf	 	>> $@;	\
		echo "	"rsync  --copy-links -v -p '$$< $$@'	>> $@;	\
		echo update-tracks:: Premaster/WAV/$$f.wav	>> $@;	\
		echo Master/$$f.wav: Premaster/WAV/$$f.wav 	>> $@;	\
		echo "	"sox '$$< -w -t .wav $$@'		>> $@;	\
		echo update-master:: Master/$$f.wav	 	>> $@;	\
	done

# make ogg and mp3 files
#	We now make them from the normalized versions in Premaster/WAV
#	unless the make variable NO_PREMASTER is defined.  The NO_PREMASTER
#	versions only work in, e.g., concert directories where the .wav
#	files are local or locally-symlinked.  Otherwise we'd have to
#	put the dependencies in mytracks.make.

ifdef NO_PREMASTER
%.ogg: 
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg title='$(TITLE)' $*)
%.mp3: 
	sox $(shell $(TRACKINFO) format=files $*) -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 title='$(TITLE)' $*) $@
else
%.ogg:  Premaster/WAV/%.wav
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg track=$< \
	  title='$(TITLE)' $*)
%.mp3: Premaster/WAV/%.wav
	sox $< -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 track=- title='$(TITLE)' $*) $@
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
	make update-tracks

#   Normalization:
# 	Probably don't want the --mix flag on normalize.
#	That would make bring everything to the same average level,
#	rather than maximizing each track separately.  
#	Probably don't want -q, either -- it's a long time to go without
#	output, and we'll almost always be doing it from the command line.

Premaster/WAV/normalized: Premaster/WAV/*.wav
	normalize-audio  $? 
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
#	Note that you have to be root in order to run cdrdao with an ATA
#	device -- playing with chgrp on /dev/hdd doesn't seem to help.
#	--speed 24 doesn't appear to be necessary anymore

.PHONY: cdr
cdr: $(NAME).toc
	@[ `whoami` = "root" ] || (echo "cdrdao must be run by root" && false)
	/usr/bin/time $(CDRDAO) write --eject --device $(DEVICE) $(NAME).toc

.PHONY: try-cdr
try-cdr: $(NAME).toc
	@[ `whoami` = "root" ] || (echo "cdrdao must be run by root" && false)
	/usr/bin/time $(CDRDAO) write --simulate --device $(DEVICE) $(NAME).toc

.PHONY: tao
tao: 	
	@[ `whoami` = "root" ] || (echo "wodim must be run by root" && false)
	$(WODIM) -pad -tao dev=$(DEVICE) -audio $(TRACK_DATA)

