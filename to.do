			to.do for Steve_Savitzky/Tools
	       $Id: to.do,v 1.3 2006-05-26 01:40:45 steve Exp $


=========================================================================

o webdir.make should go to projects/WURM
  o make sure it's all coming out of the same CVS tree
  o use .put, .put.log, .mkdir.log for sanity's sake

o move index.pl into Tools from TeX; adjust paths.

o Need a Perl *module* for extracting song info:
  o basically a SongInfo _class_
  o iterate through a list of TeX macros to turn into variables.

o Songs needs songlist files
  o instead of passing the whole list on the command line to, e.g., index.pl
    this would allow using the same tools in Songs and the albums.

  o when Songs gets moved, the way ogg files get built will have to change
    - Best would be to use "make published" in record/Tracks/*,
      and publish them into Steve_Savitzky/Tracks/* as well.
    - Expedient way is to make a link to the _real_ track directory.

o Should have a track.make template for track directories
  o use Makefile in Tracks to cons them up.

o pubdir.make to split out the web and publish-to-web functionality (?)

o Setlist.cgi ought to be installed (via symlink) in mirror's cgi-bin.
o Eventually setlists and tracklists need to be built using javascript.
  preload the data on the server, then PUT back.

=========================================================================
Done:

* 20060521 Move TeX in from ~steve; 
  * copy TeX and its CVS repo; leave the old one in place for now
  * fix the Makefile in TeX; grab HEADER.html from Doc/TeX
  * remove old Doc/TeX; replace with redirect
  * adjust Makefile, links in Songs

