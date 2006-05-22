#!/usr/bin/perl
# $Id: flktran.pl,v 1.7 2006-05-22 01:15:00 steve Exp $
# flktran [options] infile outfile
#	Perform format translation on filksong files.    

### Print usage info:
sub usage {
    print "$0 [options] infile[.flk] [outfile].ext\n";
    print "	-t	use tables\n";
    print "	-h	output html\n";
    print "	-c	output chords\n";
    print "	-v	verbose\n";
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
$verbose = 0;
$chords	 = 0;

### Adjustable parameters:

$TABSTOP = 4;			# tabstop for indented constructs
$WIDTH   = 72;			# line width for centering
$AUTHOR  = "Stephen R. Savitzky"; # Author

### Variables set from environment:

$WEBSITE = $ENV{'WEBSITE'};
$WEBDIR  = $ENV{'WEBDIR'};
$WEBDIR  =~ s|/$||;

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
$category = "";
$key = "";
$timing = "";
$created = "";
$cvsid = "";
$music = "";
$lyrics = "";
$arranger = "";

### Handle options:


while ($ARGV[0] =~ /^\-/) {
    if ($ARGV[0] eq "-dtd") { shift; $dtd = shift; }
    elsif ($ARGV[0] eq "-opt") { shift; $opt = shift; }
    elsif ($ARGV[0] eq "-h" || $ARGV[0] eq "-html") { shift; $html = 1; }
    elsif ($ARGV[0] eq "-t"|| $ARGV[0] eq "-tables") { 
	shift; $tables = 1; $chords=1; }
    elsif ($ARGV[0] eq "-v"|| $ARGV[0] eq "-verbose") { shift; $verbose = 1; }
    elsif ($ARGV[0] eq "-c"|| $ARGV[0] eq "-chords") { shift; $chords = 1; }
    else { usage; die "unrecognized option $1\n"; }
}

if ($ARGV[0]) { $infile = shift; }
if ($ARGV[0]) { $outfile= shift; }

if ($infile !~ /\./) { $infile .= ".flk"; }
if ($html) { $outfmt = "html"; }

if ($outfile =~ /\.html$/) { $outfmt = "html"; $html = 1; }
if ($outfile && $outfile !~ /\./ && $outfmt) { $outfile .= ".$outfmt"; }
$html = $outfmt eq "html";

$outfile =~ m|^([^/]+)\.[^.]+$|;
$filebase = $1;
$htmlfile = "$filebase.html";

if ($verbose) {
    print STDERR "  infile = $infile; outfile = $outfile; format = $outfmt.\n";
}
if ($infile) { open(STDIN, $infile); }
if ($outfile) { open(STDOUT, ">$outfile"); }

### Formatting constants:
if ($html) {
    $EM  = "<em>";
    $_EM = "</em>";
    $BF  = "<b>";
    $_BF = "</b>";
    $TT  = "<tt>";
    $_TT = "</tt>";
    $UL  = "<u>";
    $_UL = "</u>";
    $SPOKEN  = "(spoken)";
    $_SPOKEN = "";
    $NL  = "<br />\n";
    $NP  = "<hr />\n";
    $SP  = "&nbsp;";
    $AMP = "&amp;";
    $FLKTRAN = "<a href='../TeX/flktran.html'><code>flktran</code></a>";
    # Creative Commons copyright notice
    $CCnotice = "<a href=\"http://creativecommons.org/licenses/by-nc-sa/2.0/\"
><img  alt=\"Creative Commons License\" border=\"0\" 
       src=\"http://creativecommons.org/images/public/somerights.gif\" 
     /><small>Some rights reserved.</small></a>";
} else {
    $EM  = "_";
    $_EM = "_";
    $BF  = "*";
    $_BF = "*";
    $TT  = "";
    $_TT = "";
    $UL  = "";
    $_UL = "";
    $SPOKEN  = "(spoken)";
    $_SPOKEN = "";
    $NL  = "\n";
    $NP  = "\f";
    $SP  = " ";
    $AMP = "&";
    $FLKTRAN = "flktran";
    $CCnotice = "Some Rights Reserved:  CC by-nc-sa/2.0/";
}

### === Dispatch on input format:

### Process input in FlkTeX:

while (<STDIN>) {			
    if (/^\\\\/) { sepVerse(); } 		# verse separator
    elsif (/^[ \t]*$/) { blankLine(); }		# blank line
    elsif (/^[ \t]*\%.*$/) { }			# comment: ignore

    # Variable-setting macros:

    elsif (/\\subtitle/)  	{ $subtitle = getContent($_); }
    elsif (/\\key/)  		{ $key = getContent($_); }
    elsif (/\\category/)	{ $category = getContent($_); }
    elsif (/\\dedication/)	{ $dedication = getContent($_); }
    elsif (/\\license/) 	{ $license = getContent($_); }
    elsif (/\\timing/)  	{ $timing = getContent($_); }
    elsif (/\\created/)  	{ $created = getContent($_); }
    elsif (/\\notice/)  	{ $notice = getContent($_); }
    elsif (/\\cvsid/)		{ $cvsid = getContent($_); }
    elsif (/\\music/)		{ $music = getContent($_); }
    elsif (/\\lyrics/)		{ $lyrics = getContent($_); }
    elsif (/\\arranger/)	{ $arranger = getContent($_); }
    elsif (/\\description/)	{ $description = getContent($_); }

    # Environments: 

    elsif (/\\begin\{refrain/)	{ begRefrain(); } # Refrain
    elsif (/\\end\{refrain/)	{ endRefrain(); }
    elsif (/\\begin\{note/)	{ begNote(); } 	  # Note
    elsif (/\\end\{note/)	{ endNote(); }
    elsif (/\\begin\{quotation/){ begQuote(); }	  # Quote
    elsif (/\\end\{quotation/)	{ endQuote(); }
    elsif (/\\begin\{song/)	{ begSong($_); }  # Song
    elsif (/\\end\{song/)	{ endSong(); }

    elsif (/\\inset/)		{ sepVerse();  
				  if ($html) { print "<pre><i>\n"; }
				  indentLine(getContent($_, $TABSTOP) . "\n",
					     $TABSTOP);
				  if ($html) { print "</i></pre>\n"; }
			        }
    elsif (/\\tailnote/)	{ sepVerse(); 
				  indentLine(getContent($_, 0) . "\n"); }

    # Ignorable TeX macros:
    elsif (/\\(small|footnotesize|advance|vfill|vfiller|vbox)/) {}
    elsif (/\\(begin|end)\{/)	{}
    elsif (/\\ignore/)		{ getContent($_); }

    # Default:

    else  { doLine(); }		# Verse or plaintext line
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
    if ($html) {
	print "<html><head>";
	print "<title>$title</title>\n";
	print "</head><body>\n";
	#print "<h3><a href='./'>$WEBDIR</a> / $htmlfile</h3>\n";
	print "<h3>" . expandPath("$WEBDIR/$htmlfile") . "</h3>\n";
    } else {
	print "Online: $WEBSITE$WEBDIR/$htmlfile\n\n";
    }
}

### End a song:
###	End the file.
sub endSong {
    if ($html) {
	print "<hr>";
	print "<p><small><code><a href='./'>$WEBSITE$WEBDIR/</a>$htmlfile";
	print "</code><br>\n";
	print "   <i>Automatically generated with $FLKTRAN";
	print " from <code>$infile</code>.<i><br>\n";
	if ($cvsid) { print "   <i>$cvsid</i>\n"; }
	print "</small></p>\n";
	print "</body></html>\n" ;
    } else {
	print "\n\nOnline:\n";
	print "    $WEBSITE$WEBDIR/$htmlfile\n\n";
	print "Automatically generated with $FLKTRAN from $infile.\n";
    }
}

### Begin a verse:
###	Called before processing the first line in the new verse.
sub begVerse {
    if ($verse) { print "\n"; }	# separate the verses
    if ($html) { print "<pre>\n"; }

    $verse ++;			# bump the verse count.
    $vlines = 0;
}

### End a verse:
###	Only called if there are actually lines in it.
sub endVerse {
    if ($html) { print "</pre>\n"; }
    $vlines = 0;
}

### Begin a refrain:
sub begRefrain {
    if ($vlines) { endVerse(); }
    $indent += $TABSTOP;
    # Note that begVerse will get called when the first line appears,
    # so we don't have to deal with verse count, line count, or <pre>.
}

### End a refrain:
sub endRefrain {
    if ($html) { print "</pre>"; }
    print "\n"; 
    $vlines = 0;
    $indent -= $TABSTOP;
}

### Begin a note:
sub begNote {
    if ($vlines) { endVerse(); }
    $plines = 0;
    $plain ++;
}

### End a note:
sub endNote {
    $plines = 0;
    $plain --;
}

### Begin a quote:
sub begQuote {
    if ($vlines) { endVerse(); }
    $plines = 0;
    $plain ++;
    if ($html) { print "<blockquote>\n"; }
    $indent += $TABSTOP;
}

### End a quote:
sub endQuote {
    $plines = 0;
    $plain --;
    $indent -= $TABSTOP;
    if ($html) { print "</blockquote>\n"; }
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
    $text =~ s/\\ttto\{([^\}]+)\}/To the tune of: $1/gs;
    $text =~ s/[Ss]ome rights reserved\.?/$CCnotice/gs;
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
    return (($cline && $chords)? $cline . "\n" . $dline : $dline);
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
    # here's where we need to handle superscripts.
    while ($txt =~ /\{\\em[ \t\n]/
	   || $txt =~ /\{\\tt[ \t\n]/
	   || $txt =~ /\{\\bf[ \t\n]/
	   || $txt =~ /\\underline/
	   || $txt =~ /\\link/
	   ) {
	if ($txt =~ /\{\\em[ \t\n]/) {
	    $txt =~ s/\{\\em[ \t\n]/$EM/; 
	    while ($txt !~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_EM/;
	}
	if ($txt =~ /\{\\tt[ \t\n]/) {
	    $txt =~ s/\{\\tt[ \t\n]/$TT/; 
	    while ($txt !~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_TT/;
	}
	if ($txt =~ /\{\\bf[ \t\n]/) { 
	    $txt =~ s/\{\\bf[ \t\n]/$BF/; 
	    while ($txt !~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_BF/;
	}
	if ($txt =~ /\\underline\{/) { 
	    $txt =~ s/\\underline\{/$UL/; 
	    while ($txt !~ /\}/) { $txt .= <STDIN>; }
	    $txt =~ s/\}/$_UL/;
	}
	if ($txt =~ /\\link/) {
	    while ($txt !~ /\\link\{[^\}]*\}\{[^\}]*\}/) { $txt .= <STDIN>; }
	    if ($html) {
		$txt =~ s/\\link\{([^\}]*)\}\{([^\}]*)\}/<a href="$1">$2<\/a>/;
		$txt =~ s/\\_/_/; #fix escaped _'s etc in url
	    } else {
		$txt =~ s/\\link\{([^\}]*)\}\{([^\}]*)\}/$2/;
	    }
	}
    }
    $txt =~ s/\\&/$AMP/g;
    $txt =~ s/\\;/$SP/g;
    $txt =~ s/\\ /$SP/g;
    $txt =~ s/\\ldots/.../g;
    $txt =~ s/\\\\/$NL/g;
    $txt =~ s/\\newpage/$NP/g;

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

### expandPath($urlpath)
#	convert a URL path into a sequence of links to the various path
#	components, separated by slashes.  The result, in other words, 
#	looks just like the path except that you can navigate with it.
#
#	The last component is not linked, so it need not be the same as
#	the actual filename.  Rooted links are used rather than relative,
#	so you can use this in contexts other than the directory the path
#	ends in.  (This makes the resulting HTML bulkier, but who cares?)
#
sub expandPath {
    my ($path) = (@_);
    my $result = '';
    my $pfx = '';

    while ($path =~ s|^(/+)([^/]+)/(.)|/$3| ) {
	$result .= $1;
	$result .= "<a href='$pfx$1$2/'>$2</a>";
	$pfx .= $1 . $2;
    }
    return $result . $path;
}
