MakeStuff/music

This directory contains makefile templates, include files, and scripts
related to music -- lyrics, recordings, and so on. The templates
(capitalized) are meant to be symlinked as `Makefile`s; the include
files (lower case) are meant to be included. The generic include files
in [../make](../make) were a later development, but will be used in the
future.

Note that everything here has been moved from [Tools/](../); it will
take a while before they all get moved here and converted to the new
Makefile system. In the mean time, symlinks have been left in place.

Annotated Contents
------------------

### Templates

[~~Album.make~~](Album.make) (deprecated)

The old album makefile. Can't simply be replaced because of some differences
in directory layout.  This will be removed once the directories that use it
have been tracked down and converted. Record.make has already been replaced,
and Concert.make and Practice.make have been moved to the only working
directory where they are used.

### Include Files

[lyrics.make](lyrcs.make)

Replacement for \*/Lyrics/Makefile. None of these are symlinked; they
have subtle differences that will make conversion a bit challenging. In
addition, future plans require multiple lyrics directories, to allow
songbooks with appropriate rights to be distributed via public git
repositories.

[record.make](record.make)

Replacement for Record.make (which in turn is symlinked from
../record.make) meant to be included from a `config.make`

[songs.make](songs.make)

Include for \*/Songs. Currently only users/steve has a Songs directory.

[track-depends.make](track-depends.make)

Rules for use in a Tracks subdirectory; the makefile there is
auto-generated. This could be replaced with a Makefile symlink and an
auto-generated .depends.make, at this point.

### Scripts

 [`TrackInfo.pl`](TrackInfo.pl) 
:   Extract and format track information. Gets song metadata from the
    appropriate `.flk` files (basically LaTeX with a lot of custom
    macros), and track metadata from whichever `.wav` file is
    most appropriate.

 [`list-tracks`](list-tracks) 
:   List either all known tracks, or a specific set of tracks (e.g. the
    ones in an album's track list), in a format that makes it easy to
    keep (cough) *track* of recording progress. Most of the information
    comes out of a file called `notes` in the track directory. With the
    "`-i`" option, it lists key, meter, tempo, and style; these are
    useful when you're trying not to put excessively-similar
    tracks together. Otherwise it appends the last line of `notes` that
    starts in column 1; by convention this describes the most recent
    useable take. In a very real sense, this command produces a compact
    "status/to-do" list for an album.

 [`transpose`](transpose) 
:   Transpose a file that contains chord symbols in square brackets:
    ChordPro, FlkTran, etc.

------------------------------------------------------------------------

**Copyright © HyperSpace Express**\
[]()

------------------------------------------------------------------------
