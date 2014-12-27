#!/usr/bin/make  ### make/defines.make -- standard definitions for makefiles

# MFDIR is where the make include files live
MFDIR	= $(TOOLDIR)/make

# Compute relative paths to BASEDIR and TOOLDIR
TOOLREL:= $(shell if [ -e Tools ]; then echo Tools; \
		  else d=""; while [ ! -d $$d/Tools ]; do d=../$$d; done; \
		       echo $${d}Tools; fi)
ifeq ($(TOOLREL),Tools)
      BASEREL:= ./
else
      BASEREL:= $(dir $(TOOLREL))
endif

### Web upload location and excludes:
#	DOTDOT is the path to this directory on $(HOST); it works because
#	/vv is the parent of our whole deployment tree, and ~/vv exists on
#	the web host.  This is not really a good assumption, and fails
#	miserably when deploying from, e.g., a laptop.  Don't do that.
#	Either can be overridden if necessary in the local config.make
#
DOTDOT  := .$(MYDIR)
HOST	 = savitzky@savitzky.net
EXCLUDES = --exclude=Tracks --exclude=Master --exclude=Premaster \
	   --exclude=\*temp --exclude=.audacity\* --exclude=.git
#
###

### Files and Subdirectories:
#	Note that $(SUBDIRS) only includes real directories with a Makefile
#
FILES    = Makefile $(wildcard *.html *.ps *.pdf)
SUBDIRS := $(shell for d in *; do \
	     if [ -e $$d/Makefile -a ! -L $$d ]; then echo $$d; fi; done)

# real (not linked) subdirs containing git repositories.
#    Note that we do not require a Makefile, only .git.

GITDIRS := $(shell for d in *; do \
		if [ -d $$d/.git -a ! -L $$d ]; then echo $$d; fi; done)

### Different types of subdirectories.
#   Collection:  capitalized name
#   Item:	 lowercase name -- not always consistent
#   Date:	 digit

COLLDIRS := $(shell ls -F | grep ^[A-Z] | grep / | grep -v CVS | sed s/\\///) 
ITEMDIRS := $(shell ls -F | grep ^[a-z] | grep / | sed s/\\///) 
DATEDIRS := $(shell ls -F | grep ^[0-9] | grep / | sed s/\\///)

#
###

### git setup:
#
GIT_REPO := $(wildcard $(BASEDIR)/.git)
ifneq  ($(GIT_REPO),)
  GIT_COMMIT = $(git log --format=format:%H -n1)

  # The commit when we started make.  We can use this to see whether we made a
  # new commit as part of the deployment process.
  GIT_INITIAL_COMMIT := $(GIT_COMMIT)
endif

### deploy/push commit message:
#	Can be overridden or appended to in config.make
COMMIT_MSG := from $(shell hostname) $(shell date)
TIMESTAMP= $(shell date -u +%Y%m%dT%H%M%SZ)

#
###

### site configuration directory:
#	SITEDIR is defined as $(BASEDIR)/site iff it exists.
#	Note the use of wildcard to test for existence.

ifneq ($(wildcard $(BASEDIR)/site)),)
  SITEDIR = $(BASEDIR)/site
  ifneq ($(wildcard $(SITEDIR)/config.make),)
    include $(wildcard $(SITEDIR)/config.make
  endif
endif


