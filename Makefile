### MakeStuff/Makefile
#
# This is not only the Makefile for the MakeStuff directory, but is written
# so that it can be symlinked into almost any directory in a tree containing
# multiple resource and website directories.
#
###

### MakeStuff:  Figure out where we are and where the MakeStuff is: 
#   BASEDIR is the directory that contains it, possibly as a symlink.
#   Note that the former name of MakeStuff was Tools, but now that all active instances
#        have been fixed it's safe not to look for it.
#
MYPATH := $(shell pwd -P)
MYNAME := $(notdir $(MYPATH))
MYDIR  := $(dir $(MYPATH))
BASEDIR:= $(shell d=$(MYPATH); 						 \
		  while [ ! -d $$d/MakeStuff/make ] && [ ! $$d = / ]; do \
			d=`dirname $$d`;				 \
		  done; echo $$d)
# Make sure we actually found MakeStuff, because we can't proceed without it.
ifeq ($(BASEDIR),/)
     $(error Cannot find MakeStuff directory.  You need a symlink to it.)
endif

### TOOLDIR:  absolute path to MakeStuff.  All scripts, include files, and so on
#   are located in TOOLDIR or its subdirectories.
#
TOOLDIR := $(BASEDIR)/$(shell if [ -d $(BASEDIR)/MakeStuff/make ]; then	\
				 echo MakeStuff; else echo Tools; fi	)

### From this point we can start including stuff from TOOLDIR/make. 

include $(TOOLDIR)/make/defines.make
include $(TOOLDIR)/make/rules.make

### If there's a local config.make, include that too.
#	site/config.make, if present, was included in make/defines.make
#	config.make should not include targets -- those go in ./depends.make
#	Rules can go in either place.  Note that we can now use .config.make
#	which can be useful for both directory organization and, with a
#	suitable .htaccess, website access control.
-include .config.make config.make

###### Targets ##########################################################

# Note:  It's useful to be able to grep Makefile for targets, so we put
#	 the ones that we need or are likely to grep for here.  Bash 
#	 completion used to only look here, but it now looks in the
#	 include files as well, so that's no longer a consideration.

### all -- the default target; must come first or confusion reigns.
#	(actually, that's not entirely true:  we could set the default
#	 target explicitly, and then it wouldn't matter.  That, however,
#	 could confuse things for subdirectories that get this by
#	 inclusion rather than symlinking. So we don't.)

.PHONY: all
all::

### deploy -- deploy to the web server.
#	Differs from the original "push" target in not being recursive.
#	Sites that want recursion can add deploy-r as a dependency of
#	pre-deploy.  Sites that want a tag can add deploy-tag as a
#	dependency of deploy-this
#
#	"deploy:" is what we grep for if we want to test whether a
#	directory can be deployed using the standard targets.

.PHONY: deploy
deploy: all pre-deploy deploy-this
	@echo deployment complete


### Include standard targets and local dependencies if present.
#
include $(MFDIR)/targets.make
-include .depends.make depends.make

### report-vars - list important make variables
#   Down at the end in case any of the lists needs to get appended to.

.PHONY: report-vars
filteredVars = $(foreach v, $(reportVars), $(if $($(v)), $(v)))
filteredStrs = $(foreach v, $(reportStrs), $(if $($(v)), $(v)))

report-vars::
	@echo "" $(foreach v,$(varsLine1), $(v)=$($(v)) )
	@echo "" $(foreach v,$(varsLine2), $(v)=$($(v)) )
	@echo  "" $(foreach v,$(filteredVars),$(v)=$($(v)) "\n")
	@echo "" $(foreach v,$(filteredStrs),$(v)=\""$($(v))"\" "\n")
#
###### End of Tools/Makefile.  Thanks for playing. ######
