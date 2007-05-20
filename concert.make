### Makefile template for concerts
#	$Id: concert.make,v 1.4 2007-05-20 17:44:27 steve Exp $
#
#  This template is meant to be included in the Makefile of a "concert" 
#	directory.  The usual directory tree looks like:
#
#  top/
#	Songs		song information (.flk files)
#	Tracks		recorded tracks; a subdirectory per song
#	Albums		a subdirectory for each album
#	Concerts	a subdirectory for each concert
#	Tools		(this directory) scripts and makefile templates
#
#  The concert directory contains a .wav file for each track.

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
#	MYNAME	the name of the concert's collection directory:
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

## Devices (for burning):
#	For a 2.4 kernel with one IDE-SCSI device, use DEVICE=0,0,0
#	For a 2.6 kernel with the burner on /dev/hdd, use ATA:1,1,0
DEVICE		= ATA:1,1,0

### From here on it's constant ###

###### Rules ##########################################################

# Get the shortnames of all the tracks from $(MYNAME)/tracks
#	Note that we don't necessarily have corresponding song files
#	Ignore comment lines.
#
ifndef TRACKFILE
TRACKFILE=tracks
endif

TRACKS := $(shell grep -v '\#' $(TRACKFILE))

WAVS = $(patsubst %, %.wav, $(TRACKS))
OGGS = $(patsubst %.wav, %.ogg, $(WAVS))
MP3S = $(patsubst %.wav, %.mp3, $(WAVS))

.SUFFIXES: .flk .html .ogg .wav

.wav.ogg:
	oggenc -Q -o $@ $(shell $(TRACKINFO) $(SONGLIST_FLAGS) --ogg $*)
%.mp3: 
	sox $(shell $(TRACKINFO) format=files $*) -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 title='$(TITLE)' $*) $@


###### Targets ########################################################

### All: doesn't do much, just builds the TOC.

all::
	@echo album $(MYNAME)/ '($(TITLE))'

all::	$(MYNAME).toc $(MYNAME).list

all::	time

.PHONY: oggs mp3s
oggs:	$(OGGS)
mp3s:  $(MP3S)

### Table of contents for CD-R:
#	Standard target: toc-file

.PHONY:	toc-file
toc-file: $(MYNAME).toc

# Note that the toc-file does NOT depend on $(TRACK_DATA).
$(MYNAME).toc: tracks 
	$(TRACKINFO) -cd title='$(TITLE)' $(TRACKS) > $@
	cdrdao show-toc $(MYNAME).toc | tail -1

### Utilities:

## show the total time (on stdout)

.PHONY: time
time:	$(MYNAME).toc
	@cdrdao show-toc $(MYNAME).toc 2>&1 | tail -1

## List tracks to STDOUT in various formats:

.PHONY: lstracks
lstracks: list-tracks

.PHONY: list-tracks
list-tracks: tracks
	@$(LIST_TRACKS) $(TRACKS)

.PHONY: lsti
lsti: list-track-info

.PHONY: list-track-info
list-track-info: tracks
	@$(LIST_TRACKS) -i $(TRACKS)

.PHONY: list-text
list-text: tracks
	@$(TRACKINFO) $(SONGLIST_FLAGS) format=list.text $(TRACKS)

.PHONY: list-long
list-long: tracks
	@$(TRACKINFO) $(SONGLIST_FLAGS) --long format=list.text $(TRACKS)

.PHONY:	list-html
list-html: tracks
	@$(TRACKINFO) $(SONGLIST_FLAGS) --long format=list.html $(TRACKS)

## List tracks to a file:

html_fmt = format=list.html
$(MYNAME).list: tracks $(TRACKINFO)
	$(TRACKINFO) $(SONGLIST_FLAGS) format=list.text $(TRACKS) > $@

$(MYNAME).html: tracks $(TRACKINFO)
	$(TRACKINFO) $(SONGLIST_FLAGS) --long --sound $(html_fmt) $(TRACKS) > $@

tracks.html: tracks $(TRACKINFO)
	$(TRACKINFO) $(SONGLIST_FLAGS) --long --sound $(html_fmt) $(TRACKS) > $@

### Archive the track data: 
#	Copy all track data to the current directory for archival purposes
#	and rebuild the TOC file.

.PHONY: archive
archive: $(TRACK_DATA)
	touch $(MYNAME).tracks
	$(MAKE) $(MYNAME).toc

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
cdr: $(MYNAME).toc
	@[ `whoami` = "root" ] || (echo "cdrdao must be run by root" && false)
	/usr/bin/time cdrdao write --eject --device $(DEVICE) $(MYNAME).toc

.PHONY: try-cdr
try-cdr: $(MYNAME).toc
	@[ `whoami` = "root" ] || (echo "cdrdao must be run by root" && false)
	/usr/bin/time cdrdao write --simulate --device $(DEVICE) $(MYNAME).toc

### Publish to the web
#
