#!/usr/bin/make  ### make/defines.make -- standard definitions for makefiles

# Utilities

MARKDOWN=pandoc
MARKDOWN_FLAGS= -t html

# Compute relative paths to BASEDIR and TOOLDIR
#  Note:  attempting to simplify this using `realpath -L` instead of a loop
#	  fails because realpath computes the relative path to MakeStuff's
#	  install directory.  What we usually want is the path to a direct
#	  ancestor directory that contains a _symlink_ to MakeStuff.
BASEREL:= $(shell if [ -e MakeStuff ]; then echo .; 			\
		  else d=""; while [ ! -d $$d/MakeStuff ]; do d=../$$d; done;	\
		       echo $${d};					\
		  fi)
TOOLREL := $(BASEREL)MakeStuff

### Rsync upload: DOTDOT is the path to this directory on $(HOST).
#	Either can -- and should -- be overridden in the local config.make

#	This hack works because the parent of our whole deployment tree is
#	either /vv or ~/vv here, and ~/vv on the host.  We can get away with
#	using a recursive variable because DOTDOT and HOST are only used with
#	the rsync* targets.
DOTDOT	= $(shell echo $(MYDIR) | sed s/^.*vv/vv/)

#	HOST is computed on the assumption that we're deploying to the same host
#	that we're getting MakeStuff from, which, as they say, works on my machine
#	but is otherwise a bad assumption.  We can't just use `git remote` in
#	this directory because most of the directories we need rsync for aren't
#	under git control, usually because they contain media files.  You can,
#	however, override it by defining HOST in the environment or a config file.
HOST	?= $(shell cd $(TOOLDIR); git remote -v|grep origin|head -1 \
		  |cut -d ":" -f 1|cut -f 2)

#	Note that we exclude git repositories -- those should be synchronized
#	using git.  It is possible to use both git and rsync to push a tree
#	containing large files.  Tracks, Master, and Premaster are used for
#	audio recordings; .audacity* is Audacity's temp directory.
EXCLUDES = $(addprefix --exclude=, Tracks Master Premaster \*temp .audacity\* .git)
#
###

### Subdirectories:
#	Note that $(SUBDIRS) only includes real directories with a Makefile
ALLDIRS  := $(subst /,,$(filter %/,$(shell ls -F)))
SUBDIRS  := $(shell for d in $(ALLDIRS); do \
	     if [ -e $$d/Makefile -a ! -L $$d ]; then echo $$d; fi; done)

# real (not linked) subdirs containing git repositories.
#    Note that we do not require a Makefile, only .git.

GITDIRS := $(shell for d in $(ALLDIRS); do \
		if [ -d $$d/.git -a ! -L $$d ]; then echo $$d; fi; done)

### Different types of subdirectories.
#   Collection:  capitalized name
#   Item:	 lowercase name -- not always consistent
#   Date:	 2-4 digits.  Matches months as well as years
#
#   Defined using "=" for efficiency -- they are not used very often
#
COLLDIRS = $(shell for d in $(ALLDIRS); do echo $$d | grep ^[A-Z]; done) 
ITEMDIRS = $(shell for d in $(ALLDIRS); do echo $$d | grep ^[a-z]; done)
DATEDIRS = $(shell for d in $(ALLDIRS); do echo $$d | grep '^[0-9]{2,4}$$'; done)
#
###

### Paths for date-based file creation
#   Defined using "=" for efficiency -- they are expanded only if used.
#
YYYY := $(shell date "+%Y")
MM := $(shell date "+%m")
DD := $(shell date "+%d")

MONTHPATH = $(YYYY)/$(MM)
DAYPATH   = $(MONTHPATH)/$(DD)
MMDDPATH  = $(YYYY)/$(MM)$(DD)

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
  #	if overriding on the command line use "message=..."
ifdef message
  COMMIT_MSG := $(message)
endif
ifdef COMMIT_MSG
  # If the message isn't overridden, we may prefix it with "push from" or "on"
  commit_msg_overridden = true
else
  commit_msg_overridden = false
  COMMIT_MSG := $(shell hostname) $(shell date)
endif
endif
#
###

### site configuration directory:
#	SITEDIR is defined as $(BASEDIR)/.?site iff it exists.
#	Note the use of wildcard to test for existence.
SITEDIR = $(firstword $(wildcard  $(BASEDIR)/.site $(BASEDIR)/site))
ifneq ($(SITEDIR),)
    -include $(SITEDIR)/config.make
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
hasSongs  = $(if $(findstring /Songs,$(MYPATH))$(wildcard *.songs),songs.make)
hasTracks = $(if $(wildcard *songs *.tracks Tracks),tracks.make)
hasLyrics = $(if $(hasTracks),,$(if $(wildcard *.flk),lyrics.make))
# Note that MUSIC_D may need to be changed later.
MUSIC_D := $(if $(hasSongs)$(hasLyrics)$(hasTracks),$(TOOLDIR)/music)
MUSIC_D_INCLUDES := $(hasLyrics) $(hasSongs) $(hasTracks)


### Variable lists for report-vars.
#	The lists are defined here so that they can be appended to 
varsLine1  := SHELL MYNAME HOST
varsLine2  := BASEREL TOOLREL
reportVars := $(reportVars) BASEDIR TOOLDIR DOTDOT SITEDIR ALLDIRS SUBDIRS \
			COLLDIRS DATEDIRS ITEMDIRS \
	   		GITDIRS GIT_REPO hasLyrics hasSongs hasTracks  MUSIC_D \
			MUSIC_D_INCLUDES
reportStrs := $(reportStrs) COMMIT_MSG


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
