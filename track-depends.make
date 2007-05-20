### track-depends.make
#	$Id: track-depends.make,v 1.3 2007-05-20 17:44:28 steve Exp $
#
#	This file contains rules for things that depend on track data.
#	We need it because track data moves around in a way that makes
#	it difficult for make to compute dependencies.
#

### Open Source/Free Software license notice:
 # The contents of this file may be used under the terms of the GNU
 # Lesser General Public License Version 2 or later (the "LGPL").  The text
 # of this license can be found on this software's distribution media, or
 # obtained from  www.gnu.org/copyleft/lesser.html	
###						    :end license notice	###

OGGS = $(shell for f in $(SONGS); do echo $$f.ogg; done)
MP3S = $(shell for f in $(SONGS); do echo $$f.mp3; done)

.PHONY: oggs mp3s mytracks
oggs:  $(OGGS)
mp3s:  $(MP3S)

# These are used in rules like foo.ogg: foo; if we assume that 
#	Premaster/* exists we can move them back to album.make
%.ogg: 
	oggenc -Q -o $@ $(shell $(TRACKINFO) --ogg track=Premaster/$*.wav \
	  title='$(TITLE)' $*)
%.mp3: 
	sox Premaster/$*.wav -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 track=- title='$(TITLE)' $*) $@
%.mp3-old: 
	sox $(shell $(TRACKINFO) format=cd-files $*) -w -t wav - | \
	  lame -b 64 -S $(shell $(TRACKINFO) $(SONGLIST_FLAGS)  \
	   --mp3 track=- title='$(TITLE)' $*) $@

#Master/%.wav:  Premaster/%.wav
#	sox $? -w $@

