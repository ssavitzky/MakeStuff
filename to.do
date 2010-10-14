			     to.do for WURM/Tools
	       $Id: to.do,v 1.12 2010-10-14 06:48:15 steve Exp $



=========================================================================


webdir.make should go to projects/WURM
  * 20080119 copy all of Tools into projects/WURM
  o move the filk stuff into a subdir
  o convert to git
  o make sure it's all coming out of the same CVS tree
  o use .put, .put.log, .mkdir.log for sanity's sake
  o incorporate publish.make functionality (?)
  o check out projects/WURM in Tools for easy export 
    or symlink from docroot/Site -- has to be accessible from here

album.make
  o TOC etc should be conditional off Master
    since they're meaningless without it.  Mainly for field recordings

tags
  * 20081226 \category -> \tags
  o hierarchical: fmt.long, lic.cc, pub.{no,web}
    that way we can easily tell which tags not to copy over to the html
  
uploading: 
  o make sure we can handle multiple destinations.
  o upload to the fastest (e.g. dreamhost) and sync the others from there

Uploading with pushmipullyu
  o three targets:  put, rsync, push
    put is conditional, and uses push if there's a pull.cgi in the right place
    in the tree (first time, of course, we get it up using rsync)

  o on the site, pull.cgi uses whichever of rsync, svn, or git is appropriate
    probably best to grep the Makefile for a pull target.
    could allow multiple sources (i.e. repos or working directories) taken
    from a list (out of the tree) of authorized users and source URIs.

makefile templates
  o need a good way to get a monochrome printable version of a web page
    html2ps, probably.

flktran
  o don't put in excess blank lines in html
  o eliminate ~ (halfspace) - see aengus.flk
  o performance notes (\perf{...})
  * 20081226 category -> tags
  o link on .txt output is broken
  o all links in breadcrumbs should be fully-qualified for cut&paste

Songs/Makefile
  ~ 20080820 Index headers are wrong; should be /Steve_Savitzky NOT ../.. 
    this loses when exporting.  Could maybe fix with templates.
  ~ 200808 make mp3s depend on the oggs to keep them in sync
  o header/footer boilerplate should come from a template file
  o use songlist files instead of passing list on the command line

index.pl, flktran.pl; Songs/Makefile
  o (?)move index.pl and flktran.pl into Tools from TeX; adjust paths.
  o (?)use TrackInfo instead of index.pl -- it's more recent.
  o add license and URL info to ogg, html, pdf files

album.make
  * debugging/cleanup for concert and dual-session CDs
  * generics names for the various lists: $(BASENAME) =  $(NAME). or ""
  o separate config file for title, longname
    allows dependencies; with generic names, makes Makefile generic
    in fact, Makefile could possibly be a symlink

TrackInfo:
  o recording notes (\rnote{...})
  o need optional path to working directory for sound files
  o soundfile links should be to longnames in Rips if available
  o needs an option that produces a setlist with proper links.
    format=list.html -T is probably close now.

  o needs a way to pass a custom format string on the command line
    (probably just perl with $variable as needed)

  o LaTeX format (for album covers, etc.)
  o use directory name as $shortname when in track directories
  o when making a TOC, -nogap to make a 0-length pregap for 
    run-together tracks like house-c/demon
  o output filename formatting option similar to grip, etc. 

Tracklist.cgi: like Setlist.cgi but builds album tracklists 
  o could probably merge both into TrackInfo using a format and template.

burning:  
  = shntool to manipulate WAV files  shnlen [list-of-files] for length.
    (doesn't give length in frames for files that aren't "CD quality";
     and the sound files have to be padded to full frames in order not to
     upset cdrdao.  The current mastering process fixes this.)
  ? wodim for burning (tao for mixed disks) -- has cue support, not toc,
    but can use .inf files with -useinfo.  see icedax(0)
  o it seems to be important to eject the disk before reading the msinfo

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

Songs/ needs songlist files -- see $(TRACKS) in album.make
  o instead of passing the whole list on the command line to, e.g., index.pl
    this would allow using the same tools in Songs/ and the albums.
  o would remove the dependency on Makefile
  o use a real sort by title rather than relying on zongbook.tex

  o allow sound files to be symlinks to released tracks in a Rips dir.
    this allows long, informative filenames
    handle, e.g., shortname.ogg with a redirect rather than a symlink

  o when Songs gets moved, the way ogg files get built will have to change
    o make the ogg file in the track directory (track.make)
    o "make published" to copy to Steve_Savitzky/Tracks/*. $(PUBDIR)/...
    ~ Expedient way is to make a link to the _real_ track directory, but that
      would break "make put".

  o per-song directories would allow multiple sound files.

Should have a track.make template for track directories
  o use Makefile in Tracks to cons up the Makefile, HEADER.html, notes, etc.
  o move ogg generation into track directories.

publish.make to split out the web and publish-to-web functionality (?)
  * currently used in Concerts and Concerts/Worldcon-2006
  o if PUBDIR/shortname is a symlink, publishing isn't needed
    we can upload directly from the working directory.  

webdir.make
  o put in a subdirectory needs to go up far enough in the hierarchy
    to hit other directories that need to be made simultaneously, e.g.
    Coffee_Computers_and_Song when publishing Albums/coffee
  o this also lets us update changelogs and RSS feeds.

list-tracks
  o make check-times to list .aup files that are newer than newest .wav

Setlist.cgi 
  * 20061104 add cols=0 for a very compact listing.
  o doesn't preserve title when adding a song
    (unfixable as long as songs are added with links, not buttons or js)
  o needs to work from a simple track list (foo.tracks)
  o make the corresponding html page using TrackInfo
  o be nice if we could add notes using a text box 
    would go into track list as indented text; 
    requires only a slight mod to the grep -v command
  o install (via symlink) in mirror's cgi-bin so we can take it out of ~steve
  o all list operations need to be javascript to make them robot-proof
    draggable list items for sequencing
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

* 20060706 Setlist.cgi 
  * need absolute links in header of copyable list

TrackInfo: like SongInfo, but lists the info needed for an album tracklist
  * basic functionality:  handle numeric prefixes, songs in other dir, etc.
  * handle tracknames that don't correspond to songs (e.g. house-c_demon)
  * in most cases, print description on next line. (--long)
  * handle shortname=song1_song2 for links; assume title1 / title2.
  * add an extra frame of silence to make new cdrdao happy
  * @file to get list from a file instead of cmd line.
  * every track needs a songwriter in TOC format
  * 0120 hex formats need decimal alternatives (--dec flag)
  * 0120 need "files" format for Makefile dependencies, etc.

* 10070121 album.make:
  * use TRACKS = @trackfile instead of SONGS whenever TrackInfo is used.

TrackInfo: 
  * html format needs option for whether to include audio links.
  * 20070126 need mp3 format (like ogg only for lame or whatever)
  * 20070127 text format (for album covers, etc.)

list-tracks
  * 20070127 be nice to know whether the .aup file is newer than the .wav

TrackInfo: 
  * need format that lists the song shortnames from concert track names

burning:  
  * 20070204 wodim in tao mode for burning CD-Extra

flktran
  * 20070205 html pages need links to pdf; audio files if present.
  * <song>.html has to link to pdf, ogg, and mp3 files
  * \hfill not getting pulled out
  * --- -> -- in text and html.

normalization and other mastering: (taken care of in album.make)
  * separate export into the album directory [Premaster/WAV]
  * make would need to check for tracks newer than the current .wav's
  * probably best to export as *32-bit* (floating-point) .wav files so we
    don't lose bits in the normalization.  

album.make
  * (20070320) need to make .m3u playlist files
  * don't renormalize songs in Premaster/WAV that are older than normalized
    (not really necessary: normalize-audio checks first.  But useful anyway.)
  * (20070323) if Premaster/WAV exists, make oggs and mp3s from Master/*.wav
  * (20070323) handle NO_PREMASTER in update-master -- still need a Master
    directory in order to make a CD in the presence of 32-bit wav files.

TrackInfo:
  * need $EM, etc. from flktran (setupFormattingInfo -- fixes desc. markup)
  ~ BUG: not getting songwriter and composer credits from .flk files
    20070319 works if you specify \lyrics and \music explicitly.
  * 20070319 cd and cd-files format MUST look in ./Master for the data; 
    format=files and most others MUST NOT
  * take a track-data-dir parameter (e.g. for Master or Premaster)

Songs/Makefile
  * mp3's
  * mp3s need to use sox to convert possible 32-bit wavs to 16-bit

TrackInfo:
  * 20070506 allow ISO file.  -cdrom for CD-ROM disks; can also have audio
  * 20070508 read songDir/shortname.flk and local filename.flk files in that
    order so that the more local info overrides the global.
  * 20070521 get timing from wav files when present. (shntool len foo.wav)
    note that they have to be padded using the sox pseudo-type cdr
  ~ 20080804 need a non-sticky form of performer for the occasional live track.
    maybe performers=[comma-separated list] 
    (gets tricky; album shouldn't look like a compilation)
  ~ 20080804 give preference to <track>/notes and <album>/<track>.notes
    (use <album>/<shortname>.flk)

album.make
  * have separate ISO files for single- and dual-session disks
  * ensure "make clean" does not remove .wav's -- they might be rips or links
  * 20071220 use ./Tracks if available
  * 20071221 *tracks instead of $(NAME).tracks (much more generic)
  ? generics for the various lists, too: $(BASENAME) =  $(NAME). or ""
  = Need the following for mastering in concerts ripped from DVDs:
      sox infile -r 44100 -w -c 2 outfile effect?
	  -c 2 needed if input is mono;  -w = 16-bit words
	  effect= polyphase or resample -- default may be sufficient
  = for mastering need tracks to be padded; go through sox -t cdr

* 20070520 add license boilerplate to .pl, .cgi, .make files
  (added by hand using boilermaker.pl with boilerplate in ./include)

* 20071219 note that we're not using SongInfo.pl anymore -- should remove it.
  the audio files are now made with TrackInfo.pl.

TrackInfo:
  * should put songwriter and composer into HTML and text lists, especially
    if different from the defaults.
  * 20071219 last-name extraction fails on, e.g., William Butler Yeats (PD)
  * 20071219 look in ./Tracks for tracks if present
  * 20071220 -T option to show total run time

* 20080706 eliminate concert.make:
  * should be possible to have almost everything in common with album.make
    especially now that we have concert albums like ABT.

Songs/Makefile
  ~ 20080820 Index headers are wrong; should be /Steve_Savitzky NOT ../.. 
    this loses when exporting.  Could maybe fix with templates.
  ~ 200808 make mp3s depend on the oggs to keep them in sync
