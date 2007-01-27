### track-depends.make
#	$Id: track-depends.make,v 1.1 2007-01-27 16:04:17 steve Exp $
#
#	This file contains rules for things that depend on track data.
#	We need it because track data moves around in a way that makes
#	it difficult for make to compute dependencies.
#

OGGS = $(shell for f in $(SONGS); do echo $$f.ogg; done)
MP3S = $(shell for f in $(SONGS); do echo $$f.mp3; done)

.PHONY: oggs mp3s mytracks
oggs:  $(OGGS)
mp3s:  $(MP3S)

%.ogg: 
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg title='$(TITLE)' $*)
%.mp3: 
	lame -b 64 -S $(shell $(TRACKINFO) --mp3 title='$(TITLE)' $*) $@

