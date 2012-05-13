###### make/defines.make -- standard definitions for makefiles

MFDIR	= $(TOOLDIR)/make


### Web upload location and excludes:
#	DOTDOT is the path to this directory on $(HOST)
#	either can be overridden if necessary in the local site.make
#
DOTDOT  := .$(MYDIR)
HOST	 = savitzky@savitzky.net
EXCLUDES = --exclude=Tracks --exclude=Master --exclude=Premaster \
	   --exclude=\*temp --exclude=.audacity\*
#
###

### Files and Subdirs:
#	Note that $(SUBDIRS) only includes directories with a Makefile
#
FILES  = Makefile $(wildcard *.html *.ps *.pdf)
SUBDIRS= $(shell for d in *; do if [ -e $$d/Makefile ]; do echo $$d; done)

### Different types of subdirectories.
#   Collection:  capitalized name
#   Item:	 lowercase name -- not always consistent
#   Date:	 digit

COLLDIRS := $(shell ls -Fd | grep ^[A-Z] | grep / | grep -v CVS | sed s/\\///) 
ITEMDIRS := $(shell ls -Fd | grep ^[a-z] | grep / | sed s/\\///) 
DATEDIRS := $(shell ls -Fd | grep ^[0-9] | grep / | sed s/\\///)

GIT_DIRS := $(shell for d in *; do if [ -e $$d/.git ]; then echo $$d; fi; done)
#
###


