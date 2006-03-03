### Makefile template for albums
#	$Id: album.make,v 1.2 2006-03-03 00:11:59 steve Exp $
#
#  This template is meant to be included in the Makefile of an "album" 
#	directory.  The usual directory tree looks like:
#
#  top/
#	Songs		song information (.flk files)
#	tracks		recorded tracks; a subdirectory per song
#	albums		a subdirectory for each album
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

SONGDIR		= $(TOOLDIR)/../Songs
TRACKDIR	= $(TOOLDIR)/../Tracks

## Programs:

SONGINFO = $(SONGDIR)/SongInfo.pl

## Devices (for burning):
#	For a 2.4 kernel with one IDE-SCSI device, use DEVICE=0,0,0

DEVICE		= ATA:1,1,0


### From here on it's constant ###

## Programs

LIST_TRACKS = $(TOOLDIR)/list-tracks

###### Rules ##########################################################

# Want to snarf the track data -- could use SongInfo -get-track-data
# but there's probably a simple way to do it in pure make.

# Name to use for files.
NAME=$(SHORTNAME)

# Get the shortnames of all the songs from $(NAME).tracks
#	Ignore comment lines.
#
SONGS = $(shell grep -v '\#' $(NAME).tracks)

# Locally-archived track data
#	Note that we do NOT build this by default:  most of the time
#	we're just testing.  When the time comes to make the gold master,
#	snarf the track data with "make archive" and rebuild the toc-file.
#
TRACK_DATA = $(patsubst %, %.wav, $(SONGS))

%.wav: $(TRACKDIR)/%
	@echo snagging $@ from `ls $?/*.wav | tail -1`
	rsync `ls $?/*.wav | tail -1` $@

###### Targets ########################################################

### All: doesn't do much, just builds the TOC.

all::
	@echo album $(NAME)/ '($(TITLE))'

all::	$(NAME).toc $(NAME).list

all::	time

### Table of contents for CD-R:
#	Standard target: toc-file

.PHONY:	toc-file
toc-file: $(NAME).toc

# Note that the toc-file does NOT depend on $(TRACK_DATA).
$(NAME).toc: $(NAME).tracks 
	$(SONGINFO) -cd title='$(TITLE)' $(SONGS) > $@
	cdrdao show-toc $(NAME).toc | tail -1

### Utilities:

## show the total time (on stdout)

.PHONY: time
time:	$(NAME).toc
	@cdrdao show-toc $(NAME).toc 2>&1 | tail -1

## List tracks to STDOUT in various formats:

.PHONY: lstracks
lstracks: list-tracks

.PHONY: list-tracks
list-tracks: $(NAME).tracks
	@$(LIST_TRACKS) $(SONGS)

.PHONY: list-text
list-text: $(NAME).tracks
	@$(SONGINFO) format=list.text $(SONGS)

.PHONY:	list-html
list-html: $(NAME).tracks
	@$(SONGINFO) format=list.html $(SONGS)

## List tracks to a file:

$(NAME).list: $(NAME).tracks
	$(SONGINFO) format=list.text $(SONGS) > $@

$(NAME).html: $(NAME).tracks
	$(SONGINFO) format=list.html $(SONGS) > $@


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
