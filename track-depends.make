### track-depends.make
#	$Id: track-depends.make,v 1.2 2007-03-14 16:06:20 steve Exp $
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
	sox $(shell $(TRACKINFO) format=files $*) -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 title='$(TITLE)' $*) $@

