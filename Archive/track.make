#!/usr/bin/make  ### Makefile template for track directories
#	$Id: track.make,v 1.3 2007-05-20 17:44:28 steve Exp $
#
#  This template is meant to be included in the Makefile of a "track" 
#	directory.  The usual directory tree looks like:
#
#  top/
#	Songs		song information (.flk files)
#	Tracks		recorded tracks; a subdirectory per song
#	Albums		a subdirectory for each album
#	Tools		(this directory) scripts and makefile templates
#
#  A track directory contains Audacity projects with names like "take-N"
#  (sometimes with a suffix to indicate further editing).
#  === at some point we may switch to just N.aup; doing an actual rename
#  === requires using Audacity (or an edit) so as not to lose the connection
#  === between the project file and the data directory.
#
#	It's unfortunate that git doesn't support sub-projects yet;
#	the best thing would seem to be giving every track directory
#	its own git repo.

# === need setup targets, including one to set up a git repository.

### Usage:
#
#   Variables:
#	TOOLDIR		the directory containing this file
#	LONGNAME	the name of the song's collection directory:
#			(title with words lowercased and separated by _)
#	SHORTNAME	the shortname (directory name) of the track
#	TITLE		the full, plaintext title of the song
#
#   Targets:
#	all		doesn't do much

### Site-dependent variables:

## Directories:
#	CAUTION: the really critical one here is SONGDIR; if it doesn't
#		 have the .flk files in it, you're hosed.

BASEDIR		= $(subst /Tools/..,/,$(TOOLDIR)/..)
#BASEDIR		= ../..
SONGDIR 	= $(BASEDIR)/Songs
ALBUMDIR	= $(BASEDIR)/Albums
TRACKDIR	= $(BASEDIR)/Tracks

## Directory to publish to

PUBDIR		= ../PUBDIR/$(MYNAME)

## Programs:

TRACKINFO = $(TOOLDIR)/TrackInfo.pl
LIST_TRACKS = $(TOOLDIR)/list-tracks

### From here on it's constant ###

###### Rules ##########################################################


###### Targets ########################################################

### All: doesn't do much yet

all::
	@echo track $(NAME)/ '($(TITLE))'

### Utilities:
