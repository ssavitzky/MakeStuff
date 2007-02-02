### Makefile template for web publishing
#	$Id: publish.make,v 1.2 2007-02-02 06:13:21 steve Exp $
#
#  This template is meant to be included in the Makefile of a working
#	directory that has a corresponding web directory to publish to.
#

### Usage:
#
#   Variables:
#	TOOLDIR		the directory containing this file and other tools
#	MYNAME		the name of the directory to be published
#	PUBDIR		the directory to publish to
#	PUBFILES	the list of files to publish
#
#	TITLE		the full, plaintext title of this collection
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

#PUBDIR		= ../PUBDIR/$(MYNAME)

### From here on it's constant ###

###### Rules ##########################################################


###### Targets ########################################################

### publish
#

.PHONY: publish published prepublish publishable
publish: .publish.log
published: .publish.log

publishable: 
	@echo $(PUBFILES)

.publish.log:: prepublish
.publish.log::  $(PUBFILES)
	@for f in $? ; do ( \
	    { [ -f $(PUBDIR)/$$f ] && cmp -s $$f $(PUBDIR)/$$f; }	\
	    || ( rsync $$f $(PUBDIR); echo "  published $$f" );		\
	) done
	date >> .publish.log

# This line may not be needed
prepublish:

### put: publish and upload
#

.PHONY: put
put: .publish.log
	cd $(PUBDIR); $(MAKE) put
