#!/usr/bin/perl
# $Id: index.pl,v 1.6 2010-10-14 06:48:15 steve Exp $
# index [options] infile... 
#	Perform indexing operations on filksong files

### Open Source/Free Software license notice:
 # The contents of this file may be used under the terms of the GNU
 # General Public License Version 2 or later (the "GPL").  The text
 # of this license can be found on this software's distribution media,
 # or obtained from  www.gnu.org/copyleft/gpl.html	
###						    :end license notice	###

### Print usage info:
sub usage {
    print "$0 [options] infile[.flk] [outfile].ext\n";
    print "	-t	use tables\n";
    print "	-h	output html\n";
    print "	-ps	put in links to .ps files\n";
    print "	-dsc	output .htaccess description lines\n";
    print "	-v	verbose\n";
    print "	-o fn	output file\n";
    print "	-p fn	prefix file\n";
    print "	-s fn	suffix file\n";
    print "	-dtd fn	specify DTD\n";
    print "	-opt xx	specify style options (LaTeX)\n";
    print " Formats (extensions): \n";
    print "	flk	FlkTeX	(input; default)\n";
    print "	html	HTML\n";
    print "	fxml	FLK-XML\n";
    print "	tex	LaTeX -- sources .flk file\n";
    print "	txt	plain text (default)\n";
}

### Option variables and their defaults:

$infmt   = "flk";
$infile  = "";
$outfmt  = "txt";
$outfile = "";
$doctype = "";			# document type (LaTeX or SGML)
$options = "";			# LaTeX style options
$tables  = 0;			# use tables for HTML?
$verbose = 0;			# be verbose
$ps	 = 0;			# make links to postscript files
$prefix = "";
$suffix = "";

### Adjustable parameters:

$TABSTOP = 4;			# tabstop for indented constructs
$WIDTH   = 72;			# line width for centering
$AUTHOR  = "Stephen R. Savitzky"; # Author

### State variables:

$indent  = 0;			# current indentation level
$plain   = 0;			# true when inside plain (non-chorded) text

$verse   = 0;			# number of verses seen so far
$vlines  = 0;			# the number of lines in the current 
				#    verse or refrain. 
$plines  = 0;			# the number of lines in the current
				#    plain text block.
$header  = 0;			# true after header done.

### Variables set from song macros:
$title = "";
$subtitle = "";
$notice = "";
$license = "";
$dedication = "";
$tags = "";
$key = "";
$timing = "";
$created = "";
$cvsid = "";

### Handle options:


while ($ARGV[0] =~ /^\-/) {
    if ($ARGV[0] eq "-dtd") { shift; $dtd = shift; }
    elsif ($ARGV[0] eq "-opt") { shift; $opt = shift; }
    elsif ($ARGV[0] eq "-o") { shift; $outfile = shift; }
    elsif ($ARGV[0] eq "-p") { shift; $prefix = shift; }
    elsif ($ARGV[0] eq "-s") { shift; $suffix = shift; }
    elsif ($ARGV[0] eq "-h" || $ARGV[0] eq "-html") { shift; $html = 1; }
    elsif ($ARGV[0] eq "-ps") { shift; $ps = 1; }
    elsif ($ARGV[0] eq "-dsc") { shift; $outfmt = "dsc"; }
    elsif ($ARGV[0] eq "-t"|| $ARGV[0] eq "-tables") { shift; $tables = 1; }
    elsif ($ARGV[0] eq "-v"|| $ARGV[0] eq "-verbose") { shift; $verbose = 1; }
    else { usage; die "unrecognized option $1\n"; }
}
if ($html) { $outfmt = "html"; }
if ($outfile =~ /\.html$/) { $outfmt = "html"; $html = 1; }
if ($outfile && ($outfile !~ /\./) && $outfmt) { $outfile .= ".$outfmt"; }
$html = $outfmt eq "html";


### Accumulate titles:

$i = 0;
while ($ARGV[0]) { 
    $infile = shift; 
    $title = "";
    $subtitle = "";
    $key = "";
    $timing = "";

    if ($infile !~ /\./) { $infile .= ".flk"; }

    $infile = "../Lyrics/$infile" unless -f $infile;	

    open(STDIN, $infile);
    getTitle();
    close(STDIN);

    if ($verbose) {
	print STDERR " $infile:	$title\n";
    }

    if ($title) {
	$infile =~ m|([^/]+)\.[^.]*$|;
	$fn = $1;			   # $fn is filename without extension

	$fns{$title} = $fn;			# fns maps title => fn
	$titles{$fn} = $title;			# titles maps fn => title
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

if ($outfile) { 
    open(STDOUT, ">$outfile");
}


### Formatting constants:
if ($html) {
    $EM  = "<em>";
    $_EM = "</em>";
    $BF  = "<b>";
    $_BF = "</b>";
    $TT  = "<tt>";
    $_TT = "</tt>";
    $SPOKEN  = "(spoken)";
    $_SPOKEN = "";
    $NL  = "<br>\n";
    $SP  = "&nbsp;";
    $AMP = "&amp;";
    $FLKTRAN = "<a href='flktran.html'><code>flktran</code></a>";
} else {
    $EM  = "_";
    $_EM = "_";
    $BF  = "*";
    $_BF = "*";
    $TT  = "";
    $_TT = "";
    $SPOKEN  = "(spoken)";
    $_SPOKEN = "";
    $NL  = "\n";
    $SP  = " ";
    $AMP = "&";
    $FLKTRAN = "flktran";
}

if ($prefix) {
    open(STDIN, $prefix) || die "Cannot open prefix file $prefix";
    while (<STDIN>) { print $_; }
}

### Sort the titles and fns

sort @fnList;
sort @titleList;
sort @shortTitles;

### See if we're looking at Lyrics or Songs


# We're now assuming that everything is in ../Songs/$fn/

if ($outfmt eq "dsc") {		# .htaccess description lines
    for ($j = 0; $j < $i; $j++) {
	$fn = $fnList[$j];
	print "AddDescription \"", $titles{$fn};
	if ($subtitles{$fn}) {print " ($subtitles{$fn})"; }
	print "\" $fn\n";
    }
} elsif ($outfmt eq "html" && $tables) {	# HTML table
    print "<table class='songlist'>\n";
    print "<tr><th>ogg</th><th>mp3</th><th>pdf</th><th align=left>file</th>"
	. "<th>time</th>";
    if ($ps) { print "<th>.ps</th>"; }
    print "<th align=left> Title </tr>\n ";
    for ($j = 0; $j < $i; $j++) {
	$fn = $fnList[$j];
	my $d = (-d $fn)? "" : "../Songs/";
	my $audio_o =
	    (-f "$d$fn/$fn.ogg")? "<a href='$d$fn/$fn.ogg'>ogg</a>" : "";
	my $audio_m =
	    (-f "$d$fn/$fn.mp3")? "<a href='$d$fn/$fn.mp3'>mp3</a>" : "";
	print "<tr> ";
	print "  <td valign='top'> $audio_o </td>";
	print "  <td valign='top'> $audio_m </td>";
	print "  <td valign='top'> <a href='$d$fn/lyrics.pdf'>pdf</a>	\n";
	print "  <td valign='top'> <tt><a href='$d$fn/'>$fn</a></tt></td>\n";
	print "  <td valign='top'> $times{$fn}	</td>";
	if ($ps) { print "  <td> <a href='$d$fn.ps'>[ps]</a>	\n"; }
	print "  <td valign='top'> <a href='$d$fn/'>", $titles{$fn};
	if ($subtitles{$fn}) {print " <small>($subtitles{$fn})</small>"; }
	print "</a> </td> </tr>\n";
    }
    print "</table>\n";

} elsif ($outfmt eq "html") {	# HTML
    print "<ol class='songlist'>\n";
    for ($j = 0; $j < $i; $j++) {
	$fn = $fnList[$j];
	my $d = (-d $fn)? "" : "../Songs/";
	print "  <li> ";
	if ($ps) { print "<a href='$fn.ps'>[ps]</a>	"; }
	print "<a href='$d$fn/lyrics.pdf'>[pdf]</a>	"; 
	print "<a href='$d$fn/'>", $titles{$fn};
	if ($subtitles{$fn}) {print " ($subtitles{$fn})"; }
	print "</a> $times{$fn}";
	my $audio_o
	    = (-f "$d$fn/$fn.ogg")? "<a href='$d$fn/$fn.ogg'>ogg</a>" : "";
	my $audio_m
	    = (-f "$d$fn/$fn.mp3")? "<a href='$d$fn/$fn.mp3'>mp3</a>" : "";
	print "$audio_o $audio_m\n";
    }
    print "</ol>\n";

} elsif ($outfmt eq "tex") {	# TeX

} else {			# Plain text

}

if ($suffix) {
    open(STDIN, $suffix) || die "Cannot open suffix file $suffix";
    while (<STDIN>) { print $_; }
}

exit(0);

### Process input in FlkTeX:

sub getTitle {
    
    while (<STDIN>) {			
	if (/^[ \t]*$/) { }		# blank line
	elsif (/^[ \t]*\%.*$/) { }	# comment: ignore

    # Variable-setting macros:

	elsif (/\\begin\{song/)	{ begSong($_); }  # Song

	elsif (/\\subtitle/)  	{ $subtitle = getContent($_); }
	elsif (/\\key/)  	{ $key = getContent($_); }
	elsif (/\\tags/)	{ $tags = getContent($_); }
	elsif (/\\category/)	{ $tags = getContent($_); }
	elsif (/\\dedication/)	{ $dedication = getContent($_); }
	elsif (/\\license/) 	{ $license = getContent($_); }
	elsif (/\\timing/)  	{ $timing = getContent($_); }
	elsif (/\\created/)  	{ $created = getContent($_); }
	elsif (/\\notice/)  	{ $notice = getContent($_); }
	elsif (/\\cvsid/)	{ $cvsid = getContent($_); }

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
	if ($txt =~ /\{\\small[ \t\n]/) { 
	    $txt =~ s/\{\\small[ \t\n]/$BF/; 
	    while (! $txt =~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_BF/;
	}
    }
    $txt =~ s/\\small//;
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

