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
#	It should not include targets -- those go in ./depends.make
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

### deploy -- deploy to the web server.
#	Differs from the original "push" target in not being recursive.
#	Sites that want recursion can add deploy-subdirs as a dependency
#	of pre-deployment.

.PHONY: deploy
deploy: all deploy-only

### Cleanup

.PHONY: texclean clean

texclean::
	-rm -f *.aux *.log *.toc *.dvi

clean::
	-rm -f *.CKP *.ln *.BAK *.bak *.o core errs  *~ *.a 	\
		.emacs_* tags TAGS MakeOut *.odf *_ins.h 	\
		*.aux *.log *.toc *.dvi

### Include targets & depends from depends.make if present 
#
include $(MFDIR)/targets.make
ifneq ($(wildcard depends.make),)
     include depends.make
endif
#
###### End of Tools/Makefile.  Thanks for playing. ######
