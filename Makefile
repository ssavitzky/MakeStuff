### Tools/Makefile
#
#   This is not only the Makefile for the Tools directory, but is written so 
#   that it can be symlinked into almost any directory in the "vv/..." tree.

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
TOOLDIR := $(BASEDIR)/Tools
#
### From this point we can start including stuff from TOOLDIR/make. 

include $(TOOLDIR)/make/defines.make
include $(MFDIR)/rules.make

### site-wide and local config files
#   and include it to add or override make variables.

RULES_FILE  = rules.make
DIR_CONFIG  = config.make
DIR_TARGETS = depends.make

### Now include rules.make from BASEDIR   === BASEDIR/site?

ifeq ($(shell [ -f $(BASEDIR)/$(RULES_FILE) ] || echo no),)
     include $(BASEDIR)/$(RULES_FILE)
endif

### If there's a local config.make, include that too.

ifeq ($(shell [ -f $(DIR_CONFIG) ] || echo no),)
     include $(MYPATH)/$(DIR_CONFIG)
endif
#
###

###### Targets ##########################################################

# Note:  It's useful to be able to grep Makefile for targets, and bash 
#	 completion also looks there.  So we want to have as many common 
#	 targets as possible in the main Makefile.

### all -- the default target; must come first or confusion reigns.

.PHONY: all
all:: $(FILES)

### Greatly simplified put target, using rsync to put the whole subtree.

.PHONY: put
put:: 	all
	rsync -a -z -v $(EXCLUDES) --delete $(RSYNC_FLAGS) \
	      ./ $(HOST):$(DOTDOT)/$(MYNAME)


### Test - list important variables

.PHONY: test
V1 := BASEDIR MYNAME 
V2 := HOST DOTDOT 
test::
	@echo $(foreach v,$(V1), $(v)=$($(v)) )
	@echo $(foreach v,$(V2), $(v)=$($(v)) )
	@echo FILES: $(FILES)
	@echo git_dirs: $(GIT_DIRS)

### Include local targets & depends from depends.make if present 
#
ifeq ($(shell [ -f $(DIR_TARGETS) ] || echo no),)
     include $(MYPATH)/$(DIR_TARGETS)
endif
#
###### End of Tools/Makefile.  Thanks for playing. ######
