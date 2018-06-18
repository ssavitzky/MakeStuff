# MakeStuff/music

This directory contains makefile templates, include files, and scripts
related to music -- lyrics, recordings, and so on. The "templates"
(capitalized) are meant to be symlinked as `Makefile`s; the include
files (lower case) are meant to be included. The generic include files
in [../make](../make) were a later development, but will be used in the
future.

Note that everything here has been moved from [Tools/](../); it will
take a while before they all get moved here and converted to the new
Makefile system. In the mean time, symlinks have been left in place.

## Contents

### Makefiles

[~~Album.make~~](Album.make) (deprecated)
: The old album makefile. Can't simply be replaced because of some differences
  in directory layout.  This will be removed once the directories that use it
  have been tracked down and converted. Record.make has already been replaced
  (by tracks.make), and Concert.make and Practice.make have been moved to the
  only working directory where they are used.

### Include Files

 [`lyrics.make`](lyrcs.make)
:  Rules and targets for a directory containing song lyrics in FlkTex format
   (see [../TeX](../TeX)).  Generates printable PDF files and index files, as
   well as combining lyrics into songbooks.

 [`songs.make`](songs.make)
:   Rules and targets for `\*/Songs`.  This is used to build an online songbook
    on a website -- see [this one](https://steve.savitzky.net/Songs/).

 [`track-depends.make`](track-depends.make)
:  Used in `Albums.make` and `tracks.make` to build a secondary makefile,
   `mytracks.make`, that makes ogg and mp3 files from wav files in the
    Premaster subdirectory.

 [`tracks.make`](tracks.make)
:   Rules and targets for a directory containing recorded tracks.  Included
    automatically if a `\*.songs` file exists.

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
