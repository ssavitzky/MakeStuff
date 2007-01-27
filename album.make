### Makefile template for album directories
#	$Id: album.make,v 1.7 2007-01-27 00:26:25 steve Exp $
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
#	Ignore comment lines.
#
SONGS = $(shell grep -v '\#' $(TRACKFILE))

FLK_FILES = $(shell for f in $(SONGS); do echo \
		$(SONGDIR)/$$f.flk; done)

OGGS = $(shell for f in $(SONGS); do echo $$f.ogg; done)
MP3S = $(shell for f in $(SONGS); do echo $$f.mp3; done)

# Locally-archived track data
#	Note that we do NOT build this by default:  most of the time
#	we're just testing.  When the time comes to make the gold master,
#	snarf the track data with "make archive" and rebuild the toc-file.
#
TRACK_DATA = $(patsubst %, %.wav, $(SONGS))

%.wav: $(TRACKDIR)/%
	@echo snagging $@ from `ls $?/*.wav | tail -1`
	rsync `ls $?/*.wav | tail -1` $@

TRACK_FILES = $(shell $(TRACKINFO) format=files $(TRACKS))

###### Targets ########################################################

### All: doesn't do much, just builds the TOC and lists

all::
	@echo album $(NAME)/ '($(TITLE))'

all::	$(NAME).toc $(NAME).list $(NAME).long.list 
all::	$(NAME).html $(NAME).extras.html

all::	time

### Table of contents for CD-R:
#	Standard target: toc-file

.PHONY:	toc-file
toc-file: $(NAME).toc

# Note that the toc-file does NOT depend on $(TRACK_DATA).
$(NAME).toc: $(NAME).tracks $(TRACK_FILES)
	$(TRACKINFO) -cd $(TOC_FLAGS) title='$(TITLE)' $(SONGS) > $@
	$(CDRDAO) show-toc $(NAME).toc | tail -1

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

.PHONY:	list-files 
list-files: $(NAME).tracks
	@$(TRACKINFO) format=files $(TRACKS)

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

### Make ogg and mp3 files
#
%.ogg: $(shell $(TRACKINFO) format=files %)
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg title='$(TITLE)' $*)

%.mp3: $(shell $(TRACKINFO) format=files %)
	lame -b 64 -S $(shell $(TRACKINFO) --mp3 title='$(TITLE)' $*) $@

.PHONY: oggs mp3s
oggs:  $(OGGS)
mp3s:  $(MP3S)

### Archive the track data: 
#	Copy all track data to the current directory for archival purposes
#	and rebuild the TOC file.

.PHONY: archive
archive: $(TRACK_DATA)
	touch $(NAME).tracks
	$(MAKE) $(NAME).toc

### make a dated "snapshot" with the track list and TOC file.
# 	This is mainly for test, which has highly variable contents, but
#	can be useful as a record of intermediate states.  The TOC includes
#	the filenames for the .wav files.
#
#	It wouldn't hurt to put the snapshot into a dated subdirectory.
#

yyyymmdd	= $(shell date +%Y%m%d)

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
	/usr/bin/time cdrdao write --eject --device $(DEVICE) $(NAME).toc

.PHONY: try-cdr
try-cdr: $(NAME).toc
	@[ `whoami` = "root" ] || (echo "cdrdao must be run by root" && false)
	/usr/bin/time cdrdao write --simulate --device $(DEVICE) $(NAME).toc
