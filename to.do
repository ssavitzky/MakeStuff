			     to.do for MakeStuff

Many of the following items were pulled over from to.do in the 2014 year-end
cleanup.  More ended up in wibnif.do, and should probably be consolidated here.

=========================================================================

BUGS:
  o [scripts/import-blog-entries] need to slugify tags, too.  Keep ", "
  o [scripts/import-blog-entries] should replace cut and user tags.
  o [scripts/init-deployment] make deployable doesn't work.
  o [deployment] post-update hooks are out of date; there should be a way to update them.
  o [flktran] need to be able to specify CC license subtype; in particular my songs need
    to be CC-BY-SA-NC for monetization.
  o [flktran] should be able to handle list environments and a subset of math.
  o [make/songs.make] body text in other formats, e.g. markdown
  o [charm-wrapper, defines.make] markdown processor.  charm-wrapper uses kramdown; the
    MARKDOWN in defines was kramdown but is now pandoc; turns out I was using an outdated
    gem for kramdown.  GitHub etc. are now using the <a href="http://spec.commonmark.org/"
    >CommonMark Spec</a> -- cmark is a C implementation.  MakeStuff should either find
    an implementation that works or get it from a config file if pandoc isn't available.
  o MakeStuff should look for a global (i.e. home directory) config file for
    system-dependent definitions.

General:
  o in shared projects (e.g. github) make push should always happen on a feature branch,
    and can use -f.  That would make it possible to filter out commits that are only used
    for syncing between workstations.  Use "git merge --squash"
  o <a href="https://github.com/rylnd/shpec" >rylnd/shpec: Test your shell scripts!</a>

Blogging:
  o probably useful to have a .do -> .html formatter, too.
  = DW field size limits:  custom mood: 38, Music: 80, Location 80

WAV->FLAC
  o Move to a workflow that uses flac instead of wav.  Audacity can export it,
    and most of the tools can handle it.  cdrdao can't, but Master is generated from
    Premaster/* by sox.  normalize-audio might not -- that's a problem.  But its
    package recommends flac, and libaudiofile1 supports it, so maybe it does now.
  o Premaster/WAV -> Premaster; make it all FLAC.
    Tag the flac files in Premaster; hopefully it will be possible to transfer the tags
    to the ogg and mp3 files.
  o upgrade makefiles in older record directories.

songs.make, Songs/ improvements: (NOTE:  most of these aren't really MakeStuff issues.)
  ~ eventually, make lyrics visible for logged-in band members; maybe fans.
    It's security by obscurity, but lyrics.* are always there, just not indexed.
  o web links for lyrics we don't own; on the songwriter's official site if possible. 
  o header should be #included and auto-generated; that's the way to do title and
    navbar correctly - Songs/name currently aren't links.
  o be nice to have a song index on the left; maybe hideable.
  * header/footer boilerplate should come from a template file
  o use songlist files instead of passing list on the command line ?
    (Can make all.songs from listing)
  o Be nice if one could use Lyrics-suffix as an implicit tag.
  o main audio files would of course be %/%.ogg.  Anything else should have a name like
    yyyy-mm-dd--event--%.ogg or albumname--nn-%.ogg - i.e., the path with / -> -
    There should be a script that does this for a list of files.

TeX improvements
  @ <a href="http://www.ctan.org/pkg/etoolbox" >CTAN: Package etoolbox</a>
  @ <a href="https://www.tug.org/texinfohtml/latex2e.html"
    >LaTeX2e unofficial reference manual (October 2015)</a>
  o use \newcomand and \newcommand* (opposite of \long) for all definitions.
  o note that \indent is already defined - it adds paragraph indentation.  otoh, it's not
    used at all.  \Indent is used only in times-they-are-a-changin (where refrain would
    work equally well) and kitchen-heroes.  Rename to Refrain and Bridge respectively,
    define Indented, or, better, define indented with an optional length argument.  Use
    that with \refrainindent and \bridgeindent
  o filkbook document class
    see <a href="https://www.ctan.org/pkg/songbook" >CTAN: Package songbook</a>
    page styles:  broadside, filkbook.  option compact: no title pages
    \makesongtitle optional in compact mode, because we're not trying to do cover pages.
    compact is the default when not twosided.
    subtitle and other metadata that prints on the song's first page needs to save as well
    as print, so that it can get duplicated on the title page
  o filkbook document class should define \songfile (renamed from file) and add a hook so
    that \makesongtitle can add it to the TOC.  Suppose we could rename it "filk"
    o LaTeX2e for class and package writers:
      https://www.latex-project.org/help/documentation/clsguide.pdf
    o Uppercase style names to distinguish;
    * Separate packages for context-specific (i.e. scripting) macros. -> zingers
  o LaTeX2e
    . clean up obsolete constructs
    o parametrize page size and layout, e.g. for tablets.  See
      <a href="https://en.wikibooks.org/wiki/LaTeX/Page_Layout#Page_size_for_tablets"
      >LaTeX/Page Layout # Page size for tablets</a> 
    
tracks.make (was album.make)
  o add license and URL info to ogg, html, pdf files
  o TOC etc should be conditional on the presence of Master
    since they're meaningless without it.  Mainly for field recordings
  o Master/* should be order-only prerequisites -- should not remake them.
    Master should be all you need to make album.rips.

tags
  o hierarchical: fmt.long, lic.cc, pub.{no,web}
    that way we can easily tell which tags not to copy over to the html

flktran
  o suppress excess blank lines in html
  o eliminate ~ (halfspace) - see aengus.flk
  o performance notes (\perf{...})
  o link on .txt output is broken

flktran HTML5 conversion
  o all links in breadcrumbs should be fully-qualified for cut&paste
  o flktran should output HTML5 with properly-closed tags and quoted attributes.
  @ <a href="http://www.html-tidy.org/" >HTML Tidy</a>
  @ <a href="http://www.w3schools.com/html/html5_migration.asp" >HTML5 Migration</a>
  . Web: Convert the main websites to HTML-5 and CSS.
  ~ audio and track HTML5 elements. (track is for synchronized text like subtitles)
  o Need an "about" page to explain that ogg won't work in ie.
  * Lyrics in HTML5 include files. Top-level tag should be [article class=lyrics]

songbook.make (proposed) - make plugin for Songbook directories
  o makes html  and pdf songbook in a subdirectory. can .gitignore [a-z]*.html
  o use a "songbook.songs" file to re-order; default should be sorted by title.
  o most indices should be (optionally?) sorted by title, not filename.
    compact should of course be filenames.

index.pl, flktran.pl; Songs/Makefile
  o flktex.pm song parser module would help a lot. 
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

o Need a Perl *module* for extracting song/track info:
  o basically a SongInfo _class_
  o needs to include stuff from flktran as well -- unify all three
  o iterate through a list of TeX macros to turn into variables, rather 
    than the ad-hoc if statements used now.
  o should also include functions to generate the list formats common to
    Setlist.cgi and SongInfo.pl

  o needs a way to pass a custom format string on the command line
    (probably just perl with $variable as needed)

  o LaTeX format (for album covers, etc.)
  o use directory name as $shortname when in track directories
  o when making a TOC, -nogap to make a 0-length pregap for 
    run-together tracks like house-c/demon
  o output filename formatting option similar to grip, etc. 

Consider rewriting TrackInfo etc in Python or Haskell, possibly as a Pandoc plugin.

Tracklist.cgi: like Setlist.cgi but builds album tracklists 
  o could probably merge both into TrackInfo using a format and template.

Should have a track.make template for [album]/Tracks/* directories
  o use Makefile in Tracks to cons up the Makefile, HEADER.html, notes, etc.
  o move ogg generation into track directories.

list-tracks
  o make check-times to list .aup files that are newer than newest .wav

=========================================================================
History moved to Archive/*.done prior to deletion
=================================================

Local Variables:
    fill-column:90
End:
