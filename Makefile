### Makefile for www/Steve_Savitzky/Tools
#	$Id: Makefile,v 1.6 2007-07-17 06:16:51 steve Exp $
# 	COPYRIGHT 2005, HyperSpace Express

MYNAME :=$(shell basename `/bin/pwd`)
PARENT :=$(shell dirname  `/bin/pwd`)
TOOLDIR = .Tools
DOTDOT=vv/users/steve

### Web upload location and excludes:
#	Eventually HOST ought to be in an include file, e.g. WURM.cf

HOST=savitzky@savitzky.net
EXCLUDES=--exclude=Tracks --exclude=Master --exclude=Premaster \
	--exclude=tmp --exclude=\*temp --exclude=.audacity\*

FILES= HEADER.html Makefile to.do

SUBDIRS= TeX

all:: $(FILES)

### Greatly simplified put target because we're using rsync to put the
#	whole subtree.
#

put:: all
	rsync -a -z -v $(EXCLUDES) --delete $(RSYNC_FLAGS) \
	      ./ $(HOST):$(DOTDOT)/$(MYNAME)


