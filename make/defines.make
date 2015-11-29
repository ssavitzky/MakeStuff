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

### Rsync upload: DOTDOT is the path to this directory on $(HOST).
#	Either can -- and should -- be overridden in the local config.make

#	This hack works because /vv is the parent of our whole deployment tree,
#	and ~/vv exists on the web host.  This is not really a good assumption,
#	and fails miserably when deploying with rsync from, e.g., a laptop.
DOTDOT  := .$(MYDIR)

#	HOST is computed on the assumption that we're deploying to the same host
#	that we're getting Tools from, which, as they say, works on my machine
#	but is otherwise a bad assumption.
HOST	 = $(shell cd $(TOOLDIR); git remote -v|grep origin|head -1 \
		  |cut -d ":" -f 1|cut -f 2)

#	Note that we exclude git repositories -- those should be synchronized
#	using git.  It is possible to use both git and rsync to push a tree
#	containing large files.
EXCLUDES := --exclude=Tracks --exclude=Master --exclude=Premaster \
	    --exclude=\*temp --exclude=.audacity\* --exclude=.git
#
###

### Subdirectories:
#	Note that $(SUBDIRS) only includes real directories with a Makefile
ALLDIRS  := $(shell ls -F | grep / | grep -v CVS | sed s/\\///)
SUBDIRS  := $(shell for d in $(ALLDIRS); do \
	     if [ -e $$d/Makefile -a ! -L $$d ]; then echo $$d; fi; done)

# real (not linked) subdirs containing git repositories.
#    Note that we do not require a Makefile, only .git.

GITDIRS := $(shell for d in $(ALLDIRS); do \
		if [ -d $$d/.git -a ! -L $$d ]; then echo $$d; fi; done)

### Different types of subdirectories.
#   Collection:  capitalized name
#   Item:	 lowercase name -- not always consistent
#   Date:	 digit
#
#   Defined using "=" for efficiency -- they are expanded only if used.
#
COLLDIRS = $(shell for d in $(ALLDIRS); do echo $$d | grep ^[A-Z]; done) 
ITEMDIRS = $(shell for d in $(ALLDIRS); do echo $$d | grep ^[a-z]; done)
DATEDIRS = $(shell for d in $(ALLDIRS); do echo $$d | grep ^[0-9]; done)
#
###

### Paths for date-based file creation
#   Defined using "=" for efficiency -- they are expanded only if used.
#
DAYPATH   = $(shell date "+%Y/%m/%d")
MONTHPATH = $(shell date "+%Y/%m")
MMDDPATH  = $(shell date "+%Y/%m%d")
#
# Timestamps
#
TIME	  = $(shell date "+%H%M%S")
HRTIME	  = $(shell date "+%H:%M")
TIMESTAMP = $(shell date -u +%Y%m%dT%H%M%SZ)
#
###

### git setup:
#

# Find the git repo, if any.  Note that it can be anywhere between here and 
#	BASEDIR (which, in turn, might not have one)
GIT_REPO := $(shell d=$(MYPATH); 					\
		  while [ ! -d $$d/.git ] && [ ! $$d = $(BASEDIR) ]; do	\
			d=`dirname $$d`;				\
		  done; [ -d $$d/.git ] && echo $$d/.git)

ifdef GIT_REPO
  GIT_COMMIT = $(git log --format=format:%H -n1)

  # The commit when we started make.  We can use this to see whether we made a
  #     new commit as part of the deployment process.
  GIT_INITIAL_COMMIT := $(GIT_COMMIT)

  # deploy/push commit message:
  #	Can be overridden or appended to in config.make
  COMMIT_MSG := $(shell hostname) $(shell date)
endif
#
###

### site configuration directory:
#	SITEDIR is defined as $(BASEDIR)/site iff it exists.
#	Note the use of wildcard to test for existence.

ifneq ($(wildcard $(BASEDIR)/site)),)
  SITEDIR = $(BASEDIR)/site
  ifneq ($(wildcard $(SITEDIR)/config.make),)
    include $(SITEDIR)/config.make
  endif
endif


### Music-related directory types.
#	These are used to conditionally include definitions and rules from
#	MUSIC_D = Tools/music.  If MUSIC_D is defined, the files named by
#	the specific "hasX" variables should be included from it.
#
#	hasTracks is defined if a directory contains audio; the source for it
#	lives in a subdirectory called Tracks.
#	Detecting a directory that hasTracks is a little tricky, and may want
#	to be revised.  For the moment, look for Tracks or one or the other of
#	*.songs or *.tracks (the latter indicating an album's recording directory)
#
hasLyrics = $(if $(findstring /Lyrics,$(MYPATH)),lyrics.make)
hasSongs  = $(if $(findstring /Songs,$(MYPATH)),songs.make)
hasTracks = $(if $(wildcard *songs *.tracks Tracks),tracks.make)
# Note that MUSIC_D may need to be changed later.
MUSIC_D := $(if $(hasSongs)$(hasLyrics)$(hasTracks),$(TOOLDIR)/music)
MUSIC_D_INCLUDES := $(hasLyrics) $(hasSongs) $(hasTracks)


### Variable lists for report-vars.
#	The lists are defined here so that they can be appended to 
varsLine1  := SHELL MYNAME HOST
varsLine2  := BASEREL TOOLREL
reportVars := BASEDIR DOTDOT ALLDIRS SUBDIRS \
			COLLDIRS DATEDIRS ITEMDIRS \
	   		GITDIRS GIT_REPO hasLyrics hasSongs hasTracks  MUSIC_D \
			MUSIC_D_INCLUDES
reportStrs := COMMIT_MSG


### Templates

define TO_DO
= to.do: =


==============================================================================
Work Log:
========


==============================================================================
Local Variables:
    fill-column:90
End:

endef
export TO_DO
