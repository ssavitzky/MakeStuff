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

### Figure out where we are and where the Tools directory is: 
#   BASEDIR is the directory that contains Tools, possibly as a symlink.
#
MYPATH := $(shell pwd -P)
MYNAME := $(notdir $(MYPATH))
MYDIR  := $(dir $(MYPATH))
BASEDIR := $(shell d=$(MYDIR); 					\
		  while [ ! -d $$d/Tools ] && [ ! $$d = / ]; do	\
			d=`dirname $$d`;			\
		  done; echo $$d)
TOOLDIR = $(BASEDIR)Tools
include $(TOOLDIR)/make/rules.make
#
### Done. 

### Web upload location and excludes:
#	Eventually HOST ought to be in an include file, e.g. WURM.cf

HOST	 = savitzky@savitzky.net
EXCLUDES = --exclude=Tracks --exclude=Master --exclude=Premaster \
	   --exclude=\*temp --exclude=.audacity\*

# DOTDOT is the path to this directory on $(HOST)
#   === for now, fake it knowing that /vv maps to ~/vv on savitzky.net

DOTDOT = .$(MYDIR)


FILES= HEADER.html Makefile to.do

SUBDIRS= TeX



### See whether we have a local config.make file, and include it if we do.
#   Putting it here allows for overriding the defaults

LOCAL_CONFIG = config.make
ifeq ($(shell [ -f $(LOCAL_CONFIG) ] || echo noconf),)
     include $(shell /bin/pwd)/$(LOCAL_CONFIG)
endif



all:: $(FILES)

### Greatly simplified put target, using rsync to put the whole subtree.
#

.phony: put
put:: all
	rsync -a -z -v $(EXCLUDES) --delete $(RSYNC_FLAGS) \
	      ./ $(HOST):$(DOTDOT)/$(MYNAME)


#######################################################################

### Test - list important variables

.phony: test
V1 := BASEDIR MYNAME 
V2 := HOST DOTDOT 
test::
	@echo $(foreach v,$(V1), $(v)=$($(v)) )
	@echo $(foreach v,$(V2), $(v)=$($(v)) )
