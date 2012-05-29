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
TOOLDIR := $(BASEDIR)/Tools

### From this point we can start including stuff from TOOLDIR/make. 

include $(TOOLDIR)/make/defines.make
include $(TOOLDIR)/make/rules.make

### If there's a local config.make, include that too.
#	site/config.make, if present, is included in make/defines.make
ifneq ($(wildcard config.make),)
     include config.make
endif

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

### Cleanup

.PHONY: texclean clean

texclean::
	-rm -f *.aux *.log *.toc *.dvi

clean::
	-rm -f *.CKP *.ln *.BAK *.bak *.o core errs  *~ *.a \
		.emacs_* tags TAGS MakeOut *.odf *_ins.h \
		*.aux *.log *.toc *.dvi

### Test - list important variables

.PHONY: test
V1 := BASEDIR MYNAME 
V2 := BASEREL TOOLREL 
V3 := HOST DOTDOT 
test::
	@echo $(foreach v,$(V1), $(v)=$($(v)) )
	@echo $(foreach v,$(V2), $(v)=$($(v)) )
	@echo $(foreach v,$(V3), $(v)=$($(v)) )
	@echo FILES: $(FILES)
	@if [ "$(SUBDIRS)" != "" ]; then echo SUBDIRS: $(SUBDIRS); fi
	@echo items: $(ITEMDIRS)
	@echo colls: $(COLLDIRS)
	@echo git: $(GIT_DIRS)


### Setup


### Fixup

# link-makefile - link a Makefile from Tools.
.PHONY: link-makefile
link-makefile: 
	if [ ! -L Makefile ]; then \
	   if [ -f Makefile ]; then git rm -f Makefile; fi; \
	   ln -s $(TOOLREL)/Makefile .; \
	   git add Makefile; \
	   git commit -m "Makefile linked from Tools"; \
	fi

### Include targets & depends from depends.make if present 
#
include $(MFDIR)/targets.make
ifneq ($(wildcard depends.make),)
     include depends.make
endif
#
###### End of Tools/Makefile.  Thanks for playing. ######
