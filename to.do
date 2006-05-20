			to.do for Steve_Savitzky/Tools
		$Id: to.do,v 1.1 2006-05-20 21:30:52 steve Exp $


=========================================================================

o Move TeX in from ~steve; 
  o adjust Makefile in Songs
  o there's some stuff in Doc/TeX that we need to save:  web Makefile and
    HEADER.html in particular.

o move index.pl into Tools from TeX; adjust paths.

o Need a Perl *module* for extracting song info:
  o basically a SongInfo _class_
  o iterate through a list of TeX macros to turn into variables.

o Songs needs songlist files
  o instead of passing the whole list on the command line to, e.g., index.pl
    this would allow using the same tools in Songs and the albums.

  o if Songs gets moved, the way ogg files get built will have to be
    rethought; currently they use ../Tracks.  
    Best would be to use "make published" in the record/Tracks/* directory.

o Setlist.cgi needs to be installed (via symlink) in mirror's cgi-bin.
o Eventually setlists and tracklists need to be built using javascript.
  preload the data on the server, then PUT back.

=========================================================================
