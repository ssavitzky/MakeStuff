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
=========================================================================
Done:
=====

2015
====

0101

Uploading with pushmipullyu
  x three targets:  put, rsync, push
    put is conditional, and uses push if there's a pull.cgi in the right place
    in the tree (first time, of course, we get it up using rsync)

  x on the site, pull.cgi uses whichever of rsync, svn, or git is appropriate
    probably best to grep the Makefile for a pull target.
    could allow multiple sources (i.e. repos or working directories) taken
    from a list (out of the tree) of authorized users and source URIs.

2016
====

0723Sa
  * allow .site, .config.make, .depends.make

0731Su
publish.make to split out the web and publish-to-web functionality (?)
  * currently used in Concerts and Concerts/Worldcon-2006
  ~ if PUBDIR/shortname is a symlink, publishing isn't needed
    we can upload directly from the working directory.  

  * cleanup:
    webdir.make -> superceded by git
      ~ put in a subdirectory needs to go up far enough in the hierarchy
	to hit other directories that need to be made simultaneously, e.g.
	Coffee_Computers_and_Song when publishing Albums/coffee
      ~ this also lets us update changelogs and RSS feeds.
      ~ when Songs gets moved, the way ogg files get built will have to change
	o make the ogg file in the track directory (track.make)
	o "make published" to copy to Steve_Savitzky/Tracks/*. $(PUBDIR)/...
	~ Expedient way is to make a link to the _real_ track directory, but that
	  would break "make put".

0814Su
  * Remove license boilerplate from all files.  It's not consistent, and it's
    far from clear whether LGPL/GPL are best.  At this point I'm leaning
    toward BSD or MIT.
  -> MIT.  Simple, well-known; one of GitHub's recommended licenses.
     * fetch MIT license file.

0817We
     * remove the LGPL and GPL license files, or maybe move them -> Archive
     * add license reference to top-level README
     * Tag.

0826Fr
  ^ Still mulling name change.  So far I think MakeStuff is winning -- it's not
    pretentious, and it's pretty descriptive. (Note new tag: ^ for meta.  Not as
    applicable here as in my main to.do, and I'm not going to go back and re-tag old
    entries.

0827Sa
  * push to github:  https://github.com/ssavitzky/MakeStuff.git
   next it needs README.md
    -> install pandoc; pandoc -o README.md HEADER.html easy.  Will want a little editing.
  * next step:  reconfigure Makefile to find MakeStuff as well as Tools.  Should also be
    able to find it in site/, but that's going to be harder

1125Fr
  * much fixing in songs.make -- can now handle multiple lyrics directories.  On its way
    to being able to generate files in song subdirectories.
  * test framework in MakeStuff; music.test started with proof-of-concept for lyrics.

songs.make - make plugin for Songs directories
  * 20161125 VPATH made from ../Lyrics*, omitting WIP.
  * 20161125 test framework for MakeStuff; testing music stuff.
  * BUG: indices aren't sorted
     make list-allsongs | sed 's/ /\n/g' | sed 's/\// /g' | sort -k3 | sed 's/ /\//g'
  * Tag cleanup, because the new songs.make is tag-driven.
    grep \\tags *.flk | grep -v mine | grep -v ours | grep -vi pd | grep -v web-ok
    for f in $FILES; do sed -i.bak -e 's/\\tags{/\\tags{mine, /' $f; done

  * review make manual for VPATH and GPATH, which may do the right thing for building
    in subdirectories like SONGS/*, *.rips, etc.

1127Su
  * update license to 4.0 international


2017
====

0615We
  * Finally remove symlinks to the include and music directories; the appropriate .make
    files now refer to them in the right place.

TeX->YAML headers -> rejected.  makes it harder to apply multiple styles to lyrics
  x Move the format to one with YAML (i.e., email-type) headers instead of
    LaTeX macros.  That would make them extensible.  Instead of concatenating
    with a constant TeX header, simply translate foo.flk -> foo.tex.  This
    should also make it easier to experiment with different macro packages,
    LaTeX 2e, etc.

0619Mo
  * There is a big problem with the cover pages, which is that the metadata hasn't been
    seen by the time we want to put them out.  Worse than that, subtitle, notice,
    dedication, description, etc. actually typeset their contents, and the song
    environment itself puts out the title.
    ? Possible solutions: -> decided 20170619
    x don't have anything on the cover page but the title.  See above about subtitle etc. 
    - define a lyrics environment.  Could change to make use of other peoples' packages.
      Another really good thing about this is that we could put the tailnote _after_ the
      lyrics, possibly making it an environment.  Needs to be skippable.
      It would, however, probably require changing, e.g., \lyrics to \lyricist
    ->define \makesongtitle (analogous to \maketitle)
      less work than \lyrics because it doesn't require the name change.  Very little
      effect on existing parsers, etc.  Easy for user to change behavior.
    - move \begin{song} to after the metadata.  Add a keyword for the song title.
    x co-opt \maketitle. bad idea because we'll want it for the songbook title page.
    x Enclose the metadata with braces and make it an argument to begin{song}
    x preprocess the metadata and put it in an auxiliary file (ugh!)
    x find some kind of hook that gets called when starting page content.
    x do it in \verse, for which \\ is an alias, so just starting with it would work.
      This would require setting a flag so that it only gets expanded once, and because it
      would require changing every file, it's no better than \makesongtitle or lyrics.
    - do it in \file, making it a feature of songbooks/setlists rather than broadsides.
      I like this, because it means that %.pdf will start with the song, the way we want
      it to for publication on the web.  Songbooks can have options for page size
      (e.g. tablet).  Nothing prevents having a make target that makes a one-song
      songbook, and that would make it easy to give it a different filename.
    x use catcode to redefine LF.  the first time it's seen, it runs \maketitle, then
      does the right thing for line breaks and possibly even verse breaks.
      -> doesn't work.  extra blank lines are ignored only because \leavevmode has no
	 effect when already in vertical mode.
    ~ note that \include forces a page break, so \file doesn't have to do much.
    ~ see subdoc class in https://en.wikibooks.org/wiki/LaTeX/Modular_Documents
  * verify page counts:
    for f in *.pdf; do echo -ne $f "\t"; pdfinfo $f | grep Pages:; done

0620Tu
  ~ 0620 separate broadside.sty and songbook.sty.  Actually, these should probably be classes.
    That would leave song.sty (possibly renamed to lyrics.sty) formatting the lyrics.
  * 0620 music/lyrics.make - make variable for options (e.g. local options) TEXOPTS
  
uploading: 
  ~ make sure we can handle multiple destinations -> multiple branches.  Easy.
  ~ upload to the fastest (e.g. dreamhost) and sync the others from there
    -> actually, that's what we do now with pull deployments, so the right thing is to
       generalize _that_

makefile templates
  ? need a good way to get a monochrome printable version of a web page
    html2ps, probably.  But why?  What was I thinking needed this?

0622Th

Songs/ needs songlist files -- see $(TRACKS) in album.make
  x would remove the dependency on Makefile -> obsolete
  x instead of passing the whole list on the command line to, e.g., index.pl
    this would allow using the same tools in Songs/ and the albums.
  * allow sound files to be symlinks to released tracks in a Rips dir.
    this allows long, informative filenames
    handle, e.g., shortname.ogg with a redirect rather than a symlink
  * 0622 use a real sort by title rather than relying on zongbook.tex
    could be done with index.pl, but better to make a new command that could
    later be rewritten to use flktex.pm
  * per-song directories would allow multiple sound files.


burning:  -> notes copied to tracks.make
  = shntool to manipulate WAV files  shnlen [list-of-files] for length.
    (doesn't give length in frames for files that aren't "CD quality";
     and the sound files have to be padded to full frames in order not to
     upset cdrdao.  The current mastering process fixes this.)
  ? wodim for burning (tao for mixed disks) -- has cue support, not toc,
    but can use .inf files with -useinfo.  see icedax(0)
  = it is necessary to eject and reload the disk before reading the msinfo

  * LaTeX2e
    * documentclass.  May want broadside and songbook classes.
    * 0619 multicol for columns.  Redefine the twocolumns environment, for minimum upset.
    * 0619 fancyhdr for headers.
    
0624Sa
  * cleanup.  remove TeX/1song.tex, which is obsolete.
    remove obsolete \Centered and \Indented macros.
    Move some documentation from song.sty to hsxheaders.sty

0625Su
  * \makesongtitle, looseleaf mode working
  * use \newenvironment to define environments.
  * 0624 Songbook 2-sided printing (compact)
    \@twosidetrue - so this maps into a conditional, \if@twoside
    \begin{song}[S/L], \defaultsonglength{S/L} - short songs can start on either side.
  * 0624 <a href="https://tex.stackexchange.com/questions/11707/how-to-force-output-to-a-left-or-right-page"
      >double sided - How to force output to a left (or right) page?</a>
      \cleardoublepage -- use \documentclass[...twoside...]
  ~ refactoring:
    ~ songbook, leadsheet (cover page, no tailnotes), and broadside (no cover page).
    ? local style file (basically zongbook, though may want to rename) that defines
      the basic page style plus any locally-unique singer annotation macros.
    * zingers.sty -> singer annotations.  Local overrides default, which is empty.
  * 0625 looseleaf style:
    Front cover, two facing pages, back cover.  If we don't mind the lyrics on the left
    for one-pagers we can either drop pages 3 and 4, or have a blank third page.  (even
    pages are on the left, odd on the right).  Suppressing covers (compact mode) would
    make a two-sided songbook with half as many pages as song-at-a-time formatting, but
    would make insertions more difficult.  Makes some sense for printing sets, though
  * 0625 define \makesongtitle - make a song title page if appropriate.
    Goes in front of the first line of the song, at which point all of the metadata has
    been seen.  Makes title page if two-sided, puts out subtitle, notice, etc. on main
    page (and title page if present)
  x marginpar for singer annotations?  -> no; interacts wrong with columns

1211
  * grab posting stuff from Private/Journals/River
  * use charm to post - make foo.post
  : note that the ljpost wrapper for charm is in Honu/bin
  
2018
====

0121
  * BUG: make zongbook prints in looseleaf format; one would expect it to make and
    print zongbook.pdf.
  ~ might be a good idea to ask for confirmation before printing a songbook
    -> change targets to print-songbook etc.
  * BUG: zongbook.pdf should depend on all .flk files
  * BUG: printing doesn't force two-sided.

0122
  * BUG [S] puts a spurious L on the (unnecessary) first page of short songs.
    -> was using \if to compare expansions; should have used \ifx

0309Fr
  * generate Songs/*/lyrics.html without headers.

0312Mo
  * extracting song info for template expansion:
    eval $(LYRICDIR=../Lyrics-Other $(TOOLDIR)/music/TrackInfo.pl --shell $shortname)
    loads the shell's environment with the track info.
    TrackInfo does too much; need a module that parses song files correctly.
    -> 0312 songinfo.
    -> Needs YAML and make options as well as shell.
    
0313Tu
  * options for lyrics:
    -> build %/lyrics.pdf, which is what we do currently
    - symlink %.flk into Songs/%, and do the build directly.  (loses information about
      which directory it came from, so not a good idea.)
  * %/index.html should #include lyrics.html, and only if we have rights.
    in steve/Songs we can do this by lyrics directory, i.e. Lyrics and Lyrics-PD.
    In lgf, use tags.
  * generate Songs/*/index.html from templates
  @ <a href="http://httpd.apache.org/docs/current/expr.html"
    >Expressions in Apache HTTP Server - Apache HTTP Server Version 2.4</a>
    SSI can, for example, test variables set in  .htaccess.
    Or, we can just have two different index file templates that we link to.
  * make */Songs from */Lyrics* -- use tags or subdirs to identify which ones get visible
    lyrics.  Pages want to be there even if the lyrics are hidden, because the
    performances, notes, etc. are still needed.
  * Put body text in an editable include file which is generated only if missing
    (e.g. text.html) -> body-text.html

0314Th
  x move index.pl and flktran.pl into Tools from TeX; adjust paths.
    -> no, they belong with the rest of the scripts that operate on .flk files
  : index.pl is incredibly badly written (parses a file into global variables instead of a
    hash!) and seems to have a preliminary version of the flktran chord parser as well!
    And why am I not using it to sort song files by title
  x Need a program to replace an HTML element with a given id (mainly for
    tracklists)  The present template hack has problems with multiple end
    lines.  -> use mustache templates or something bash or make based

0316Fr
  * take Songs/*/index.html out of git now that they can be made on the server.

0317Sa
  * [TeX/songinfo] metadata files need descriptions.
  * [make/songs.make] indices are badly-formatted, don't need filenames anymore

0510
  * 0510 [lgf, steve] need to build Songs after push.

0825Sa
  * It would be useful for make entry to have targets for both html and markdown, or else
    a command-line variable maybe ff for file format.  ff=html (default), ff=md, etc.  ff
    is more versatile, but targets like make draft.md may be feasible.
    -> EXT; can be defined in .config.make or, e.g., jekyll.make

1027Sa
  * it should be easy to crosspost. => going to mark this done:
  * import-blog-entries working modulo spaces and punctuation in tags.

1231Mo
  * should include the post's URL in the Posted: header, if the program returns it.
    -> the way DW archive pages are named, /yyyy/mm/dd/, can be used to get the URL of the
       most recent one.  (as long as it's public)  Ought to parametrize with how archived
       posts are listed -- mine is most recent last; some people use blog order.
  * Each entry starts with [h3 class="entry-title"][a title="..." href="POSTED_URL"
    That's all you need to find the permalink URL of the entry.  Use the following:
    wget -q -O - https://mdlbear.dreamwidth.org/$(date +%Y/%m/%d/) \
       | grep 'class="entry-title"' | tail -1                      \
       | sed -E 's/^<[^>]*><[^>]*href="([^"]*)".*$/\1/'

2019
====

0206We and later
  * [make/songs.make] indices should indicate which songs have notes, audio, or postable
    lyrics.  That will require actually looking at the metadata.

unknown
  * (0315) note that some, perhaps all, includes can be done in mustache at
    template-expansion time.
  * BUG: etoolbox.sty not found on Dreamhost.
  ? lyrics--*.pdf probably not worth the trouble in most 

  * 0527 \comment instead of \ignore

  * Use initials as tag instead of "mine", so "ss, nr" -- then have OURTAGS = ss nr
 
2020
====

0805We
  * add ChordPro output to flktran.pl 

0811Tu
  * [flktran] need to handle \singer; 
  & bug-smashing in flktran -- finding edge cases in html conversion with check-html

=now====Tools/to.do=====================================================================>|

Local Variables:
    fill-column:90
End:
?
