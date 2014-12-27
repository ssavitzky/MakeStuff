### Tools/Makefile
#
#   This is not only the Makefile for the Tools directory, but is written so 
#   that it can be symlinked into almost any directory in the "vv/..." tree.
#
###

### Open Source/Free Software license notice:
 # The contents of this file may be used under the terms of the GNU
 # Lesser General Public License Version 2 or later (the "LGPL").  The text
 # of this license can be found on this software's distribution media, or
 # obtained from  www.gnu.org/copyleft/lesser.html	
###						    :end license notice	###

### Tools:  Figure out where we are and where the Tools directory is: 
#   BASEDIR is the directory that contains Tools, possibly as a symlink.
#
MYPATH := $(shell pwd -P)
MYNAME := $(notdir $(MYPATH))
MYDIR  := $(dir $(MYPATH))
BASEDIR:= $(shell d=$(MYPATH); 					\
		  while [ ! -d $$d/Tools ] && [ ! $$d = / ]; do	\
			d=`dirname $$d`;			\
		  done; echo $$d)
# Make sure we actually found Tools, because we can't proceed without it.
ifeq ($(BASEDIR),/)
     $(error Cannot find Tools directory.  Giving up.)
endif
TOOLDIR := $(BASEDIR)/Tools

### From this point we can start including stuff from TOOLDIR/make. 

include $(TOOLDIR)/make/defines.make
include $(TOOLDIR)/make/rules.make

### If there's a local config.make, include that too.
#	site/config.make, if present, is included in make/defines.make
#	It should not include targets -- those go in ./depends.make
ifneq ($(wildcard config.make),)
     include config.make
endif

###### Targets ##########################################################

# Note:  It's useful to be able to grep Makefile for targets, so we put
#	 the ones that we need or are likely to grep for here.  Bash 
#	 completion used to only look here, but it now looks in the
#	 include files as well, so that's no longer a consideration.

### all -- the default target; must come first or confusion reigns.

.PHONY: all
all:: $(FILES)

### deploy -- deploy to the web server.
#	Differs from the original "push" target in not being recursive.
#	Sites that want recursion can add deploy-r as a dependency of
#	pre-deploy.  Sites that want a tag can add deploy-tag as a
#	dependency of deploy-this

.PHONY: deploy
deploy: all pre-deploy deploy-this
	@echo deployment complete


### Include targets & depends from depends.make if present 
#
include $(MFDIR)/targets.make
ifneq ($(wildcard depends.make),)
     include depends.make
endif
#
###### End of Tools/Makefile.  Thanks for playing. ######
