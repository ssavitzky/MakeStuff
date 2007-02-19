			to.do for Steve_Savitzky/Tools
	       $Id: to.do,v 1.5 2007-02-19 03:04:50 steve Exp $


=========================================================================

o note that we're not using SongInfo.pl anymore -- should remove it.
  the audio files are now made with TrackInfo.pl.

o webdir.make should go to projects/WURM
  o make sure it's all coming out of the same CVS tree
  o use .put, .put.log, .mkdir.log for sanity's sake
  o incorporate publish.make functionality (?)
  o check out projects/WURM in Tools for easy export 
    or symlink from docroot/Site -- has to be accessible from here

o makefile templates
  o need a good way to get a monochrome printable version of a web page
    html2ps, probably.

o flktran
  o \hfill not getting pulled out
  o --- -> -- in text and html.
  o don't put in excess blank lines in html

o Songs/Makefile
  ->Index headers are wrong; should be /Steve_Savitzky NOT ../.. 
    this loses when exporting.  Could maybe fix with templates.
  o header/footer boilerplate should come from a template file
  * mp3's
  o make mp3s depend on the oggs to keep them in sync
  o use songlist files instead of passing list on the command line

o index.pl, flktran.pl; Songs/Makefile
  o (?)move index.pl and flktran.pl into Tools from TeX; adjust paths.
  o (?)use TrackInfo instead of index.pl -- it's more recent.
  o add license and URL info to ogg, html, pdf files
  
o TrackInfo: like SongInfo, but lists the info needed for an album tracklist
  o need $EM, etc. from flktran
  o LaTeX format (for album covers, etc.)
  o use directory name as $shortname when in track directories
  o read song, track, and local shortname.flk files in that order
    so that the more local info overrides the global.
  o take a track-data-dir parameter (e.g. for Master or Premaster)
  o give preference to <track>/notes and <album>/<track>.notes
  o get timing from wav files when present.
  o output filename formatting option similar to grip, etc. 

o concert.make:
  o should be possible to have almost everything in common with album.make
  o especially now that we have concert albums like ABT.

o Tracklist.cgi: like Songlist.cgi but builds album tracklists 

o burning:  
  ? wodim for burning -- includes cue support, maybe not toc
  o cuetools for toc->cue file;  toc2cue also doesn't like pregap
  o shntool to manipulate WAV files  shnlen [list-of-files] for length.
    (doesn't give length in frames for files that aren't "CD quality";
     this includes monophonic concert files off the sound board.)

o normalization and other mastering:
  o probably best to export as *32-bit* (floating-point) .wav files so we
    don't lose bits in the normalization.  
  o Probably requires separate export into the album directory.
  o make would need to check for tracks newer than the current .wav's

o Need a Perl *module* for extracting song/track info:
  o basically a SongInfo _class_
  o needs to include stuff from flktran as well -- unify all three
  o iterate through a list of TeX macros to turn into variables, rather 
    than the ad-hoc if statements used now.
  o should also include functions to generate the list formats common to
    Setlist.cgi and SongInfo.pl

o Need a program to replace an HTML element with a given id (mainly for
  tracklists)  The present template hack has problems with multiple end
  lines. 

o Songs/ needs songlist files -- see $(TRACKS) in album.make
  o instead of passing the whole list on the command line to, e.g., index.pl
    this would allow using the same tools in Songs/ and the albums.
  o would remove the dependency on Makefile

  o when Songs gets moved, the way ogg files get built will have to change
    o make the ogg file in the track directory (track.make)
    o "make published" to copy to Steve_Savitzky/Tracks/*. $(PUBDIR)/...
    ~ Expedient way is to make a link to the _real_ track directory, but that
      would break "make put".

o Should have a track.make template for track directories
  o use Makefile in Tracks to cons up the Makefile, HEADER.html, notes, etc.
  o move ogg generation into track directories.

* pubdir.make to split out the web and publish-to-web functionality (?)
  * currently used in Concerts and Concerts/Worldcon-2006

o SongInfo.pl 
  o needs a way to echo a single variable's value -- %variable
  o needs an option that produces a setlist with proper links.
    (Alternative would be to run Setlist.cgi from the shell, but that's 
    not as versatile.  Maybe a --links option.)
  o use songlist files like trackinfo does  

o list-tracks
  o make check-times to list .aup files that are newer than newest .wav

o Setlist.cgi 
  * 20061104 add cols=0 for a very compact listing.
  o be nice if we could add a note (using a text box)
  o install (via symlink) in mirror's cgi-bin so we can take it out of ~steve
  o all list operations need to be javascript to make them robot-proof

o Eventually setlists and tracklists need to be built using javascript.
  preload the data on the server, then PUT back.

=========================================================================
=========================================================================
Done:
=====

* 20060521 Move TeX in from ~steve; 
  * copy TeX and its CVS repo; leave the old one in place for now
  * fix the Makefile in TeX; grab HEADER.html from Doc/TeX
  * remove old Doc/TeX; replace with redirect
  * adjust Makefile, links in Songs

* 20060629 list-tracks
  * add -i option to list-tracks
  * -x (--hex) option to Setlist.cgi

o 20060706 Setlist.cgi 
  * need absolute links in header of copyable list

o TrackInfo: like SongInfo, but lists the info needed for an album tracklist
  * basic functionality:  handle numeric prefixes, songs in other dir, etc.
  * handle tracknames that don't correspond to songs (e.g. house-c_demon)
  * in most cases, print description on next line. (--long)
  * handle shortname=song1_song2 for links; assume title1 / title2.
  * add an extra frame of silence to make new cdrdao happy
  * @file to get list from a file instead of cmd line.
  * every track needs a songwriter in TOC format
  * 0120 hex formats need decimal alternatives (--dec flag)
  * 0120 need "files" format for Makefile dependencies, etc.

o 10070121 album.make:
  * use TRACKS = @trackfile instead of SONGS whenever TrackInfo is used.

o TrackInfo: like SongInfo, but lists the info needed for an album tracklist
  * html format needs option for whether to include audio links.
  * 20070126 need mp3 format (like ogg only for lame or whatever)
  * 20070127 text format (for album covers, etc.)

o list-tracks
  * 20070127 be nice to know whether the .aup file is newer than the .wav

o TrackInfo: like SongInfo, but lists the info needed for an album tracklist
  * need format that lists the song shortnames from concert track names

o burning:  
  * 20070204 wodim in tao mode for burning CD-Extra

o flktran
  * 20070205 html pages need links to pdf; audio files if present.
  * <song>.html has to link to pdf, ogg, and mp3 files

