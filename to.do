			     to.do for WURM/Tools

NOTE (201412) WURM has largely been superceded, but Tools/Makefile is more or
less alive and well.

=========================================================================


album.make
  o TOC etc should be conditional off Master
    since they're meaningless without it.  Mainly for field recordings

tags
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
  o header/footer boilerplate should come from a template file
  o use songlist files instead of passing list on the command line

index.pl, flktran.pl; Songs/Makefile
  o (?)move index.pl and flktran.pl into Tools from TeX; adjust paths.
  o (?)use TrackInfo instead of index.pl -- it's more recent.
  o add license and URL info to ogg, html, pdf files

album.make
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

=========================================================================
=========================================================================
Done:
=====
