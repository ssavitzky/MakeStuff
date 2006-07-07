#!/usr/bin/perl
# $Id: Setlist.cgi,v 1.4 2006-07-07 06:01:39 steve Exp $
# Setlist.cgi [options] infile...	make the title index
# .../Setlist.cgi from web.		make a setlist
#	<title>make a setlist</title>

use CGI;

### If called from the command line, 
#	expect a list of song names as parameters.
#	Read the times and titles, and write out the maps.

if (@ARGV) {
    $verbose=1;
    setup();
    exit 0;
}

### CGI setup:

$q = new CGI;
$this = @ENV{SCRIPT_NAME};
$root = @ENV{DOCUMENT_ROOT};

$this =~ m|^(.*/)([^/]+)|;
$cgidir = $1;
$cginame= $2;

### Look for a config file.
# === Setlist.cf

$publicSongs = "/Steve_Savitzky/Songs/";
$publicSite  = "http://theStarport.com";
$publicURL   = "${publicSite}${publicSongs}Sets/";

### Get CGI parameters
$songs = $q->param("songs");			# URL path to songs
$songs = "" unless $songs;
$songs .= "/" unless ($songs eq "" || $songs =~ m|/$|);

### Look for the songs in the usual places:
#	We do this by assuming that the songlist file is with them.

$songlistFile = "songlist.txt";
$songlistFile .= ".txt" unless $songlistFile =~ /\./;

$songDir = ($songs =~ m|^/|)? "$root$songs" : "./$songs";
if (-f  "$songDir$songlistFile") {
    # everything's cool
} elsif (-f "$root$publicSongs$songlistFile") {
    # we must be on the public site, then, or a mirror of it
    $songDir = "$root$publicSongs";
} elsif (-f "../$songlistFile") {
    # try the current directory and its relatives
    $songDir = "../";
} elsif (-f "../Songs/$songlistFile") {
    $songDir = "../Songs/";
} elsif (-f "../../Songs/$songlistFile") {
    $songDir = "../../Songs/";
} else {
    # can't find the song directory, so we're hosed anyway.
}

# === needs to come from config file or be computed from $songs
$songURL = "$publicSite$publicSongs";
$songlistFile = "$songDir$songlistFile";

### Now get the rest of the parameters

$list = $q->param("list");			# songs in the set
$op   = $q->param("op");			# operation
$name = $q->param("name");			# song to operate on
$cols = $q->param("cols");			# number of columns
$titles = $q->param("titles");			# show titles?
$pageTitle = $q->param("title");		# page title
$ro   = $q->param("ro");			# read only (lock)
$sort = $q->param("sort");			# sort filenames

$sort = 1 if $sort;

# really need to put out a setlist file in songlist form that we can
# read and write, rather than using a horrendous GET link.

$list = "" unless $list;
@list = (split(/[ +]+/, $list));

### Operations:  require song name in $name
#	up 	move toward head of list
#	dn	move toward tail of list
#	add	add to list
#	del	delete from list

# handle shortcuts:  op=name

if (!$op && $name) {
    $op = 'add';
} elsif (!$op && !$name) {
    if ($q->param("del")) { $op = 'del'; $name = $q->param("del"); }
    elsif ($q->param("up")) { $op = 'up'; $name = $q->param("up"); }
    elsif ($q->param("dn")) { $op = 'dn'; $name = $q->param("dn"); }
    elsif ($q->param("add")) { $op = 'add'; $name = $q->param("add"); }
}

### Initialize:  

@songlist = ();
%timeMap  = ();
%titleMap = ();


### Option variables and their defaults:

$verbose = 0;			# be verbose


### Variables set from song macros:
$title = "";
$subtitle = "";
$notice = "";
$license = "";
$dedication = "";
$category = "";
$key = "";
$timing = "";
$created = "";
$cvsid = "";

$message = "";					# error message

# Suck in the initial list of songs
# Build the titleMap and timeMap

if (! open(IN, $songlistFile)) {
    $message = "Can't open songlist $songlistFile";
}
while (<IN>) {
    s/\n//;
    my ($f, $t, $ttl) = split(/\|/, $_);
    next unless $f;
    push(@songlist, $f);
    $timeMap{$f} = $t;
    $titleMap{$f} = $ttl;
}

#print STDERR join(" ", @songlist) . "\n";

### do the specified operation

if ($op eq "add") {
    # === error checking
    push(@list, $name);
} elsif ($op eq "up") {
    my $i;
    for ($i = @list; $i--;) { last if $list[$i] eq $name; }
    if ($i > 0) {
	my $t = $list[$i];
	$list[$i] = $list[$i - 1];
	$list[$i - 1] = $t;
    }
} elsif ($op eq "dn") {
    my $i;
    for ($i = @list; $i--;) { last if $list[$i] eq $name; }
    if ($i >= 0 && $i < @list-1) {
	my $t = $list[$i];
	$list[$i] = $list[$i + 1];
	$list[$i + 1] = $t;
    }
} elsif ($op eq "del") {
    my $i;
    for ($i = @list; $i--;) { last if $list[$i] eq $name; }
    delete(@list[$i]) if $i >= 0;
} elsif ($op eq "save" && -d "$songDir/Sets" && -w "$songDir/Sets") {
    # should do name washing, error checking...
    umask 2;
    if (open(OUT, ">${songDir}Sets/$pageTitle.html")) {
	print OUT "<html>\n";
	print OUT "  <head>\n";
	print OUT "    <title>Set list: $pageTitle</title>\n";
	print OUT "  </head>\n";
	print OUT "  <body>\n";
	print OUT "    <h2><a href='${publicSongs}Sets/'>Set list</a>:";
	print OUT " $pageTitle</h2>\n";
	print OUT "    <p>\n" . songLinks() . "\n</p>\n";
	print OUT "    <hr />\n";
	print OUT "    <b>list:</b> <small>$list</small>\n";
	# Here's the mostly-hidden form for re-editing the setlist:
	print OUT join("\n", 
		       ( "<form method='POST' action='" .
			 $this .
			 "'>"),
		       "<input type='hidden' name='list' value='$list'>",
		       "<input type='hidden' name='cols' value='$cols'>",
		       "<input type='hidden' name='title' value='$pageTitle'>",
		       "<input type='hidden' name='sort' value='$sort'>",
		       "<input type='SUBMIT' name='edit' value='edit'>",
		       "</form>\n"
		       );
	print OUT "  </body>\n";
	print OUT "</html>\n";
	close OUT;
	$message = "wrote $pageTitle.html";
    } else {
	$message = "can't write $songDir/Sets/$pageTitle.html";
    }
}

### Add up the times for the listed songs. 

$totalTime = 0;					# total time for list
$noTime = 0;					# #songs with no time
$nSongs = 0;

for my $song (@list) {
    my $t = $timeMap{$song};
    if ($t =~ /([0-9]+)\:([0-9]+)/) {
	$totalTime += ($1 * 60) + $2;
    } else {
	++$noTime;
    }
    ++$nSongs;
}
$ttime = sprintf("%d:%02d", $totalTime/60, $totalTime%60);

### Build the page
#
# We're doing this *very* crudely with links, because it's too stupidly
# hard to do the right thing in the form with buttons.  Note, however, that
# this means that you have to keep robots away from the page, otherwise 
# you get a combinatorial explosion that will blow your site's bandwidth 
# to smithereens.  Be warned.

$content = "<html>\n";
$content .= "  <head>\n";
$content .= ("    <title>Set list " .
	     ($pageTitle? $pageTitle : "Maker") . "</title>\n");
$content .= "  </head>\n";
$content .= "  <body>\n";
$content .= "<h2><a href='${songDir}Sets/'>Set list</a>: "
    . ($pageTitle? $pageTitle : "Maker") . "</h2>\n";

# The form should be at the end if $ro is set

$content .= ("    <form method='GET'>\n" .
	     "      <b>list:</b> " .
	     "<input name='list' value='" . join(" ", @list) .
	     "' size='70' />\n" .
	     "<br />" .
	     " <b>cols:</b> <input name='cols' value='$cols' size='2'/>" .
	     " <input type='submit' value='update' />" .
	     " <input type='submit' name='ro' value='done' />" .
	     " <input type='submit' name='op' value='save' />" .
	     " \&nbsp;\&nbsp; " . opLink('', '', "bookmark") .
	     (" \&nbsp;\&nbsp; " . "<b>sort:</b>".
	      " <input name='sort' type='checkbox'" .
	      ($sort? " checked='checked'" : "") . " />\n") .
	     (" \&nbsp;\&nbsp; " . "<b>title:</b>".
	      " <input name='title' size='30' value='$pageTitle' />\n") .
	     "</form>");
$content .= $message . "\n";
$content .= "<hr />\n";

$content .= "  no songlist file $songlistFile\n" unless -f $songlistFile;

if (1) {
    $content .= "<table>\n";
    for my $f (@list) {
	my $t   = $timeMap{$f}; $t = "" unless $t;
	my $ttl = $titleMap{$f};
	my $up = opLink($f, "up", "^");
	my $dn = opLink($f, "dn", "v");
	my $del= opLink($f, "del", "x");
	$content .= "  <tr>\n";
	if (!$ro) {
	    $content .= "    <td>$up $dn $del</td>\n";	# up, down, delete
	    $content .= "    <td>$f</td>\n";		# shortname
	}
	$content .= "    <td align='right'>$t</td>\n";	# time
	if (-f "$songDir/$f.html") {			# title link
	    $content .= "    <td><a href='$songURL$f.html'>$ttl</a></td>\n";
	} else {
	    $content .= "    <td>$ttl</td>\n";
	}
	$content .= "  </tr>\n";
    }
    $content .= ("  <tr>" . ($ro? "" : "<td></td><th></th>") .
		 "<td><hr /></td><td><hr /></td></tr>");
    $content .= ("  <tr>" . ($ro? "" : "<td></td><th>time</th>") .
		 "     <td align='right'>$ttime</td>" .
		 "     <td>\&nbsp; $nSongs songs " .
		 ($noTime? "; \&nbsp;\&nbsp; $noTime untimed" : "") .
		 "     </td>\n" .
		 "  </tr>\n");
    $content .= "</table>\n";
}

# Real quick kludge -- list of all songs with add link.
#	We could wrap it up in a big honking form and use submit buttons
#	with name=name, value=song because the operation is always the same.

@songlist = sort(@songlist) if $sort;
if (!$ro) {
    my $total = 0;
    my $notime= 0;
    $content .= "<hr>\n";
    $content .= "<table>\n";
    my $c = 0;
    for my $f (@songlist) {
	my $t   = $timeMap{$f}; $t = "" unless $t;
	my $ttl = $titleMap{$f};
	$total++;
	$notime++ unless $t;
	$content .= "<tr>\n" if $c == 0; 
	$content .= "    <td>" . opLink($f, "add", $f) . "</td>\n";
	$content .= "    <td>$t</td>\n";
	if ($cols > 2) {
	    # no title.  Otherwise it links to the song lyrics.
	} elsif (-f "$songDir/$f.html") {
	    $content .= "    <td><a href='$songURL$f.html'>$ttl</a></td>\n";
	} else {
	    $content .= "    <td>$ttl</td>\n";
	}
	$c = ($c + 1) % $cols if $cols;
	$content .= "</tr>\n" if $c == 0;
	$content .= "    <td>|</td>\n" if $c;
    }
    $content .= "</tr>\n" if $c > 0;
    $content .= "</table>\n";
    $content .= "<p>$total songs total; \&nbsp; $notime without times.";
    $content .= " \&nbsp; Click a filename to add a song to the setlist.";
    $content .= " \&nbsp; Titles link to the songs' lyric pages, ";
    $content .= "if I have permission to post them on this site.";
    $content .= (" \&nbsp; You can use the command line below to print" .
		 " a custom songbook for the set." );
    $content .= "</p>\n";

    $content .= "<p><small><code>\n";
    $content .= "lpr";
    for my $f (@list) {
	$content .= " $f.ps";
    }
    $content .= "</code></small></p>\n";
}

# Here's the stuff we'll paste into LJ or some such:

$content .= "<hr>\n";

# ok, eventually we'll quote this to make it really simple.

$content .= "<h4>Setlist links:</h4>\n";
$content .= "<pre>\n" 
    . entityEncode("<a href='${publicURL}'>Set list</a>:\n".
		   "  <a href='${publicURL}$pageTitle.html'>$pageTitle</a>" .
		   "\n")
    . entityEncode("<blockquote>\n" . songLinks() . "</blockquote>\n")
    . "</pre>\n";

$content .= "<h4>link to this page:</h4>\n";
$content .= ("<p><small>" .
	     "\&lt;a&nbsp;href='" . roURL() . "' \&gt;$pageTitle\&lt;/a\&gt;" .
	     "</small></p>");

# End of the content
$content .= "<hr />\n";
$content .= ("<p align='right'>" .
	     "<a href='$cgidir'>$cgidir</a>" .
	     "<a href='$this'>$cginame</a>" .
	     "</p>\n");
$content .= "  </body>\n</html>\n";


### Return the page:

print "Content-type: text/html\n";
print "Content-length: " . length($content) . "\n";
print "\n";
print $content;
exit 0;


sub songLinks {
    my $content = '';
    my $i = 1;
    for my $f (@list) {
	my $ttl = $titleMap{$f};
	if (-f "$songDir/$f.html") {
	    $content .= "  $i. <a href='$songURL$f.html'>$ttl</a>";
	} else {
	    $content .= "  $i. $ttl";
	}
	$content .= "<br />\n";
	++$i;
    }
    $content;
}

sub opLink {
    my ($f, $op, $txt) = @_;
    my $list=join("+", @list);
    return ("<a href='$this?" .
	    ($ro? "ro=$ro;" : "") . 
	    ($pageTitle? "title=$pageTitle;" : "") . 
	    ($sort? "sort=$sort;" : "") . 
	    ($f? "name=$f;" : "") . 
	    ($op? "op=$op;" : "") .
	    ($cols? "cols=$cols;" : "") .
	    "list=$list'" .
	    ">$txt</a>");
}

sub opURL {
    my ($f, $op) = @_;
    my $list=join("+", @list);
    return ("$this?" .
	    ($ro? "ro=$ro;" : "") . 
	    ($pageTitle? "title=$pageTitle;" : "") . 
	    ($sort? "sort=$sort;" : "") . 
	    ($f? "name=$f;" : "") . 
	    ($op? "op=$op;" : "") .
	    ($cols? "cols=$cols;" : "") .
	    "list=$list");
}

# read-only URL for this setlist
sub roURL {
    my ($base) = @_;
    $$base = $this unless $base;
    my $list=join("+", @list);
    return ("$this?" .
	    "ro=1;" . 
	    ($pageTitle? "title=$pageTitle;" : "") . 
	    ($cols? "cols=$cols;" : "") .
	    "list=$list");
}


# entity encode (protect) a string
sub entityEncode {
    my ($s) = @_;
    $s =~ s/\&/&amp;/gs;
    $s =~ s/\>/&gt;/gs;
    $s =~ s/\</&lt;/gs;
    return $s;
}

### Setup:  read songs to get their titles and times.
#	It's assumed that the Makefile will do this to generate
#	the songlist file (songlist.txt)

sub setup {
    $i = 0;
    foreach $infile (@ARGV) {
	$title = "";
	$subtitle = "";
	$key = "";
	$timing = "";

	if ($infile !~ /\./) { $infile .= ".flk"; }

	open(STDIN, $infile);
	getTitle();
	close(STDIN);

	if ($verbose > 1) {
	    print STDERR " $infile:	$timing\t$title\n";
	}

	if ($title) {
	    $fn = $infile;
	    $fn =~ s/\.[^.]*$//;	# $fn is filename without extension

	    $fns{$title} = $fn;	# fns maps title => fn
	    $titles{$fn} = $title;	# titles maps fn => title
	    $subtitles{$fn} = $subtitle;
	    $keys{$fn} = $key;
	    $times{$fn} = $timing;

	    $titleList[$i] = $title;
	    $fnList[$i] = $fn;

	    $title =~ s/^A //;
	    $title =~ s/^The //;

	    $shortTitles[$i] = $title;
	    $fns{$title} = $title;

	    $i++;
	}
    }

    if ($verbose) {
	print STDERR "*** $i songs processed\n";
    }

    # Write a file of name|time|title on stdout

    for $fn (@fnList) {
	print $fn . "|" . $times{$fn} . "|" . $titles{$fn} . "\n";
    }
}


### Process input in FlkTeX:

sub getTitle {
    
    while (<STDIN>) {			
	if (/^[ \t]*$/) { }		# blank line
	elsif (/^[ \t]*\%.*$/) { }	# comment: ignore

    # Variable-setting macros:

	elsif (/\\begin\{song/)	{ begSong($_); }  # Song

	elsif (/\\subtitle/)  	{ $subtitle = getContent($_); }
	elsif (/\\key/)  	{ $key = getContent($_); }
	elsif (/\\category/)	{ $category = getContent($_); }
	elsif (/\\dedication/)	{ $dedication = getContent($_); }
	elsif (/\\license/) 	{ $license = getContent($_); }
	elsif (/\\timing/)  	{ $timing = getContent($_); }
	elsif (/\\created/)  	{ $created = getContent($_); }
	elsif (/\\notice/)  	{ $notice = getContent($_); }
	elsif (/\\cvsid/)	{ $cvsid = getContent($_); }
	elsif (/\\music/)	{ $music     = getContent($_); }
	elsif (/\\lyrics/)	{ $lyrics    = getContent($_); }
	elsif (/\\arranger/)	{ $arranger  = getContent($_); }
	elsif (/\\performer/)	{ $performer = getContent($_); }

	elsif ($title) { return; }
    }
}


########################################################################
###
### Macro handlers:
###
###	Each of the following routines handles a LaTeX macro.
###

### Separate verses.
sub sepVerse {
    if ($vlines) { endVerse(); }
}

### Handle a blank line.
sub blankLine {
    if ($vlines) { endVerse(); }
    if ($plain) {
	print "\n";
	$plines = 0;
    }
}

### Begin a song:
###	Stash the title, put out the header.
sub begSong {
    my ($line) = @_;		# input line
    $line =~ s/^.*song\}//;
    $title = getContent($line);	
}


########################################################################
###
### Block conversion:
###
###	Each of these routines converts the start or end of a
###	delimited block of lines to output format.
###

sub doHeader {
    if ($html)	{ htmlHeader(); }
    else	{ textHeader(); }
    $header ++;
}

sub center {
    # === need to handle multiple lines ===
    my ($text) = @_;
    $text =~ s/^[ \t]*//;
    $text =~ s/[ \t]*\n$//;
    $text =~ s/\\copyright/Copyright/;

    my $w = $WIDTH - length($text);
    for ( ; $w > 0; $w -= 2) { $text = " " . $text; }
    print "$text\n";
}

sub hcenter {
    my ($h, $text) = @_;
    $text =~ s/^[ \t]*//;
    $text =~ s/\\copyright/\&copy;/;
    $text =~ s/\n/\<br\>/g;
    $text = "<h$h align=center>$text</h$h>";
    print "$text\n";
}

sub textHeader {
    center "$title\n";
    if ($subtitle) 	{ center "$subtitle\n"; }
    if ($notice) 	{ center "$notice\n"; }
    if ($license)	{ center "$license\n"; }
    if ($dedication) 	{ center "$dedication\n"; }
    print "\n";
}
sub htmlHeader {
    hcenter 1, $title;
    if ($subtitle) 	{ hcenter 2, $subtitle; }
    if ($notice) 	{ hcenter 3, $notice; }
    if ($license)	{ hcenter 3, $license; }
    if ($dedication) 	{ hcenter 3, $dedication; }
    print "\n";
}

sub footer {

}

########################################################################
###
### Line conversion:
###
###	Each of these routines converts a single line of mixed chords
###	and text. 
###

### Process the current line:
###	Does any necessary dispatching. 
sub doLine {
    # Put out the header, if this is the very first line. 
    if (! $header) { doHeader(); }
    if ($plain) {
	if ($plines == 0) { 
	    if ($html) { print "<p>\n"; }
	    else { print "\n"; }
	} 
	$_ = deTeX($_);
	if ($html) { s/\~/&nbsp;/g; } else { s/\~/ /g; }
	s/\\newline/$NL/g;
	s/\\\///g;
	indentLine($_, $indent);
	$plines ++;
    } else {
	if ($vlines == 0) { begVerse(); }
	if ($tables) { print tableLine($_); }
	else 	     { print chordLine($_); }
	$vlines ++;
    }
}

### Put out a plain line, possibly indented.
sub indentLine {
    my ($line, $indent) = @_;

    $line =~ s/^[ \t]*//;
    while ($indent--) { $line = " ".$line; }
    print $line;
}

### Convert an ordinary line to chords + text
# === does not insert indent yet.
sub chordLine {
    my ($line) = @_;		# input line
    my $cline = "";		# chord line
    my $dline = "";		# dest. (text) line
    my ($scol, $ccol, $dcol, $inchord, $inmacro) = ($indent, 0, 0, 0, 0);
    my $c = '';			# current character
    my $p = 0;			# current position

    $line = deTeX($line);

    $line =~ s/^[ \t]*//;
    $line =~ s/\\sus/sus/g;
    $line =~ s/\\min/m/g;

    for ($p = 0; $p < length($line); $p++) {
	$c = substr($line, $p, 1); 
	if    ($c eq "\n" || $c eq "\r") { break; }
	if    ($c eq '[') { $inchord ++; }
	elsif ($c eq ']') { $inchord --; }
	elsif ($c eq ' ') { if (!$inchord) { $scol ++; } }
	elsif ($c eq "\t") {
	    if (!$inchord) { do {$scol ++; } while ($scol % 8); } }
	else {
	    if ($inchord) {
		while ($ccol < $scol) { $cline .= ' '; $ccol ++ }
		$cline .= $c;
		$ccol ++;
	    } else {
		while ($dcol < $scol) { $dline .= ' '; $dcol ++ }
		$dline .= $c;
		$dcol ++;
		$scol++;
	    }
	}
    }

    # The result has a newline appended to it.
    return (($cline eq "")? $dline : $cline . "\n" . $dline);
}

### Convert a line to a table
###   When using tables, each line becomes a separate table.
###   This, in turn, becomes a row in a table containing the verse.
sub tableLine {

}

### Convert a line to XML
sub xmlLine {

}

### Remove LaTeX constructs.
###	This would be easier with a table.
sub deTeX {
    my ($txt) = @_;		# input line

    while ($txt =~ /\%/) {	# TeX comments eat the line break, too.
	$txt =~ s/\%.*$//;
	$txt .= <STDIN>;
     }
    while ($txt =~ /\{\\em[ \t\n]/
	   || $txt =~ /\{\\tt[ \t\n]/
	   || $txt =~ /\{\\bf[ \t\n]/) {
	# This will fail if there's a \bf and \em in one line in that order
	if ($txt =~ /\{\\em[ \t\n]/) {
	    $txt =~ s/\{\\em[ \t\n]/$EM/; 
	    while (! $txt =~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_EM/;
	}
	if ($txt =~ /\{\\tt[ \t\n]/) {
	    $txt =~ s/\{\\tt[ \t\n]/$TT/; 
	    while (! $txt =~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_TT/;
	}
	if ($txt =~ /\{\\bf[ \t\n]/) { 
	    $txt =~ s/\{\\bf[ \t\n]/$BF/; 
	    while (! $txt =~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_BF/;
	}
    }
    $txt =~ s/\\&/$AMP/g;
    $txt =~ s/\\;/$SP/g;
    $txt =~ s/\\ /$SP/g;
    $txt =~ s/\\ldots/.../g;
    $txt =~ s/\\\\/$NL/g;

    return $txt
}


### getContent(line): get what's between macro braces.
sub getContent {
    my ($line) = @_;		# input line
    # Throw away everything up to the "{"
    $line =~ s/^[^{]*\{//;
    $line = deTeX($line);
    # Suck in more lines if we haven't seen the closing brace
    while ($line !~ /\}/) { $line .= <STDIN>; $line = deTeX($line); }
    # Throw away everything after the "}"
    $line =~ s/\}[^}]*$//;
    $line =~ s/\n$//;
    return $line;
}

1;
