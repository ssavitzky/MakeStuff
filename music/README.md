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

 [`lyrics.make`](lyrics.make)
:  Rules and targets for a directory containing song lyrics in FlkTex format
   (see [../TeX](../TeX)).  Generates printable PDF files and HTML index
   files, as well as combining lyrics into songbooks.  Two different formats
   for PDF lyrics are supported: a one-or-two-page "compact" form used in the
   songbook and on the web, and a two-or-four-page "looseleaf" format meant
   for two-sided printing, which puts lyrics on two facing pages.

 [`songs.make`](songs.make)
:   Rules and targets for `\*/Songs`.  This is used to build an online
    songbook on a website -- see [this one](https://steve.savitzky.net/Songs/)
    for example.  Song lyrics and metadata come from one or more associated
    `Lyrics` directories; a song directory may also contain audio files and
    additional text.  The `Songs` directory is under git control -- typically
    with its own repo -- but subdirectories are ignored unless they contain
    non-generated files.
	
 [`track-depends.make`](track-depends.make)
:  Used in `Album.make` and `tracks.make` to build a secondary makefile,
   `mytracks.make`, that makes ogg and mp3 files from wav files in the
   `./Premaster` subdirectory.

 [`tracks.make`](tracks.make)
:   Rules and targets for a directory containing recorded tracks.  Included
    automatically if a `\*.songs` file exists in a directory.  It expects to
    find subdirectories called `Master`, `Premaster`, and `Tracks`.

### Scripts

 [`TrackInfo.pl`](TrackInfo.pl) 
:   Extract and format track information. Gets song metadata from the
    appropriate `.flk` files (basically LaTeX with a lot of custom macros for
    metadata -- see [../TeX](../TeX)), and track metadata from the
    corresponding `.wav` file in `./Premaster`.  Generates HTML in several
    different formats, text track lists, CD `.toc` files, and command-line
    arguments suitable for `oggenc` or `lame`.

 [`list-tracks`](list-tracks) 
:   List either all known tracks, or a specific set of tracks (e.g. the ones
    in an album's track list), in a format that makes it easy to keep (cough)
    *track* of recording progress.  It expects each track to have a
    corresponding subdirectory in `./Tracks`. Most of the information comes
    out of a file called `notes` in the track directory. With the "`-i`"
    option, it lists key, meter, tempo, and style; these are useful when
    you're trying not to put excessively-similar tracks together. Otherwise it
    appends the last line of `notes` that starts in column 1; by convention
    this describes the most recent useable take. In a very real sense, this
    command produces a compact status/to-do list for an album.
 
 [`songinfo.pl`](songinfo.pl) 
:   Extract and format song metadata from a `.flk` file.  Output formats are
	YAML (name: "value"), shell (name="value"), and make (name =
	unquoted-value).

 [`transpose`](transpose) 
:   Transpose a file that contains chord symbols in square brackets:
    ChordPro, FlkTeX, etc.

------------------------------------------------------------------------
