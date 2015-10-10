#!/usr/bin/make  ### Makefile for a concert.  
#	Designed to be "include"d after setting TITLE

### Parse directory tree to find Tools
#	It's either yyyy/mm-dd or yyyy/mm/dd

ifeq ($(shell [ -e ../../Tools ] || echo yyyy/mm/dd),)
MYNAME :=$(shell basename `/bin/pwd`)
PARENT :=$(shell dirname  `/bin/pwd`)
YEAR   :=$(shell basename $(PARENT))
MONTH  :=$(shell perl -e '"$(MYNAME)" =~ /^([0-9]+)/; print $$1;')
DATE   :=$(YEAR)-$(MONTH)
TOOLDIR = ../../Tools
DOTDOT=vv/users/record/$(YEAR)
EVNAME :=$(shell perl -e '"$(MYNAME)" =~ /^[0-9]+-(.*)$$/; print $$1;')
else
MYNAME :=$(shell basename `/bin/pwd`)
PARENT :=$(shell dirname  `/bin/pwd`)
MONTH  :=$(shell basename $(PARENT))
GRAND  :=$(shell dirname  $(PARENT))
YEAR   :=$(shell basename $(GRAND))
# need to check if MYNAME starts with dd or dd-dd
DAY    := $(shell perl -e '"$(MYNAME)" =~ /^([0-9]+)-(.*)$$/; print $$1;')
DATE   := $(YEAR)-$(MONTH)-$(DAY)
TOOLDIR = ../../../Tools
SONGDIR:= ../../../Lyrics
DOTDOT=vv/users/record/$(YEAR)/$(MONTH)
EVNAME := $(shell perl -e '"$(MYNAME)" =~ /^[0-9]+-(.*)$$/; print $$1;')
#EVNAME := $(MYNAME)
endif 

ifeq ($(shell [ -d ./Lyrics ] && echo Lyrics), Lyrics)
SONGDIR :=./Lyrics
endif

### Web upload location and excludes:
#	Eventually HOST ought to be in an include file, e.g. WURM.cf

HOST=savitzky@savitzky.net
EXCLUDES=--exclude=Tracks --exclude=Master --exclude=Premaster

FILES= Makefile $(wildcard *notes) \
	$(wildcard *.html) \
	$(wildcard *.list) \
	$(wildcard *.ogg) \
	$(wildcard *.mp3) \
	$(wildcard *.jpg) \
	$(wildcard *songs) 

PUBFILES=$(FILES)


### Default title
#	There's no longname, because this isn't an album and so isn't
#	tied to a publication directory.  Ideally we'd take the month
#	off the name.

ifndef TITLE
    TITLE	= Concert: $(EVNAME) $(YEAR)
endif

TRACKLIST_FLAGS  = 

### Include appropriate makefile rules
#	Depending on whether we're in a website or a recording tree
#	It's better to look for $(SRCDIR)/WURM.cf then $(MF_DIR), since
#	at some point MF_DIR and TOOLDIR may get merged.

include $(TOOLDIR)/album.make

all:: 
	@echo $(DATE) $(EVNAME)
	@echo SONGDIR=$(SONGDIR)

all:: $(FILES)

### Expand templates depending on extras.html
ifeq ($(shell [ -f extras.html ] && echo 1), 1)

ifeq ($(shell [ -f HEADER.html ] && echo 1), 1) 
HEADER.html: extras.html
	$(TOOLDIR)/replace-template-file.pl $< $@
	touch $@
endif

ifeq ($(shell [ -f index.html ] && echo 1), 1) 
index.html: extras.html
	$(TOOLDIR)/replace-template-file.pl $< $@
	touch $@
endif

endif

### Greatly simplified put target because we're using rsync to put the
#	whole subtree.  

put: all
	rsync -a -z -v $(EXCLUDES) --delete ./ $(HOST):$(DOTDOT)/$(MYNAME)


### Setup
#	We only do the setup if there's no "songs" file
#	The conditional means that we can use a different set of rules
#	to make Premaster and Premaster/WAV; otherwise album.make has
#	its own rules for them.
ifeq ($(wildcard *songs),)
.PHONY: setup 

setup:: Tracks Premaster Premaster/WAV

setup:: songs

songs:
	@echo Edit $@ to add songs
	@echo '# Song list for $(TITLE) $(MYNAME)' > $@
endif
