#!/usr/bin/make  ### Makefile for a practice session.  Designed to be symlinked
#	$Id$

### Parse directory tree to find Tools
#	It's either yyyy/mm-dd or yyyy/mm/dd

ifeq ($(shell [ -e ../../Tools ] || echo yyyy/mm/dd),)
MYNAME :=$(shell basename `/bin/pwd`)
PARENT :=$(shell dirname  `/bin/pwd`)
YEAR   :=$(shell basename $(PARENT))
DATE   :=$(YEAR)-$(MYNAME)
TOOLDIR = ../../Tools
DOTDOT=vv/users/record/$(YEAR)
else
MYNAME :=$(shell basename `/bin/pwd`)
PARENT :=$(shell dirname  `/bin/pwd`)
MONTH  :=$(shell basename $(PARENT))
GRAND  :=$(shell dirname  $(PARENT))
YEAR   :=$(shell basename $(GRAND))
DATE   := $(YEAR)-$(MONTH)-$(MYNAME)
TOOLDIR = ../../../Tools
DOTDOT=vv/users/record/$(YEAR)/$(MONTH)
endif 

### Web upload location and excludes:


HOST=savitzky@savitzky.net
EXCLUDES=--exclude=Tracks --exclude=Master --exclude=Premaster

### Filk/recording boilerplate

### title
#	There's no shortname, because there's no need to tie this directory
#	together with corresponding tracks and songs.  Consequently there's
#	no need for a longname -- it's just the directory name $(MYNAME)

TITLE := Practice Session $(DATE)

### Broken web stuff

FILES= Makefile $(wildcard *notes) \
	$(wildcard *.html) \
	$(wildcard *.list) \
	$(wildcard *.ogg) \
	$(wildcard *.mp3) \
	$(wildcard *.jpg) \
	$(wildcard *songs) 

PUBFILES=$(FILES)

TRACKLIST_FLAGS  = 


### Are we set up??
ifeq ($(wildcard *songs),)
#	If there's no "songs" file the include files will fail horribly,
#	so do the necessary setup.
all::
	@echo setting up $(TITLE)

all:: setup
	@echo set up $(TITLE)

else
#	There's a "songs" file, so go ahead and include album.make, etc.
  include $(TOOLDIR)/album.make
#  include $(TOOLDIR)/publish.make
endif

### Expand templates

# HEADER.html depends on extras
ifeq ($(shell [ -f HEADER.html ] && echo 1), 1) 
HEADER.html: extras.html
	$(TOOLDIR)/replace-template-file.pl $< $@
endif

# In a practice session, index.html also depends on extras
ifeq ($(shell [ -f index.html ] && echo 1), 1) 
index.html: extras.html
	$(TOOLDIR)/replace-template-file.pl $< $@
endif


### Web upload:
#	Greatly simplified put target because we're using rsync to put the
#	whole subtree.

put:: all
	rsync -a -z -v $(EXCLUDES) --delete ./ $(HOST):$(DOTDOT)/$(MYNAME)


### Setup
#	We only do the setup if there's no "songs" file
#	The conditional means that we can use a different set of rules
#	to make Premaster and Premaster/WAV; otherwise album.make has
#	its own rules for them.
ifeq ($(wildcard *songs),)
.PHONY: setup 

setup:: Tracks Premaster Premaster/WAV

Tracks Premaster Premaster/WAV: 
	mkdir $@

setup:: songs

songs:
	@echo Edit $@ to add songs
	@echo '# Song list for practice session $(MYNAME)' > $@
endif
