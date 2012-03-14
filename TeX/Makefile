### Makefile for www/Steve_Savitzky/Tools/TeX
#	$Id: Makefile,v 1.4 2006-05-21 03:24:39 steve Exp $
# 	COPYRIGHT 1998, HyperSpace Express

MYNAME :=$(shell basename `/bin/pwd`)
PARENT :=$(shell dirname  `/bin/pwd`)
TOOLDIR = ../../Tools
DOTDOT=vv/users/steve/Tools

### Web upload location and excludes:
#	Eventually HOST ought to be in an include file, e.g. WURM.cf

HOST=savitzky@savitzky.net
EXCLUDES=--exclude=Tracks --exclude=Master --exclude=Premaster \
	--exclude=tmp --exclude=\*temp --exclude=.audacity\*

FILES= HEADER.html Makefile

all:: $(FILES)

### Greatly simplified put target because we're using rsync to put the
#	whole subtree.
#

put:: all
	rsync -a -z -v $(EXCLUDES) --delete $(RSYNC_FLAGS) \
	      ./ $(HOST):$(DOTDOT)/$(MYNAME)

