#!/usr/bin/make  ### track-depends.make
#
#	This file contains rules for things that depend on track data;
#	It's used in Album.make as an include in a generated makefile.
#	We need it because track data moves around in a way that makes
#	it difficult for make to compute dependencies
#
#	This and Album.make badly need to be replaced.
#

# These are used in rules like foo.ogg: foo; if we assume that 
#	Premaster/* exists we can move them back to album.make
%.ogg: Premaster/WAV/%.wav
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg track=$< \
	  title='$(TITLE)' $*)
%.mp3: Premaster/WAV/%.wav
	sox $< -b 16 -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 track=- title='$(TITLE)' $*) $@

#Master/%.wav:  Premaster/%.wav
#	sox $? -b 16 $@

