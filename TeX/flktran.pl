#!/usr/bin/perl
# $Id: flktran.pl,v 1.15 2010-10-14 06:48:15 steve Exp $
# flktran [options] infile outfile
#	Perform format translation on filksong files.    

### Print usage info:
sub usage {
    print "$0 [options] infile[.flk] [outfile].ext\n";
    print "	-b -bare	bare lyrics -- no headings\n";
    print "	-c -chords	output chords\n";
    print "	-h -html	output html\n";
    print "	-t -tables	use tables (implies -h -c)\n";
    print "	-v	verbose\n";
    print " Formats (extensions): \n";
    print "	flk	FlkTeX	(input; default)\n";
    print "	html	HTML\n";
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
$bare = "";
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
$music = "";
$lyrics = "";
$arranger = "";

### Handle options:

if (@ARGV == 0) {
    usage;
    exit
}

while ($ARGV[0] =~ /^\-/) {
    if ($ARGV[0] eq "-b" || $ARGV[0] eq "-bare") { shift; $bare = 1; }
    elsif ($ARGV[0] eq "-c"|| $ARGV[0] eq "-chords") { shift; $chords = 1; }
    elsif ($ARGV[0] eq "-h" || $ARGV[0] eq "-html") { shift; $html = 1; }
    elsif ($ARGV[0] eq "-t"|| $ARGV[0] eq "-tables") { 
	shift; $tables = 1; $chords = 1; $html = 1; }
    elsif ($ARGV[0] eq "-v"|| $ARGV[0] eq "-verbose") { shift; $verbose = 1; }
    else { usage; die "unrecognized option $1\n"; }
}

if ($ARGV[0]) { $infile = shift; }
if ($ARGV[0]) { $outfile= shift; }

if ($infile !~ /\./) { $infile .= ".flk"; }
if ($html) { $outfmt = "html"; }

# If $outfile ends in /, it's a directory.  In that case, the output
# goes into the corresponding directory, in a file called lyrics.html

if ($outfile =~ /\.html$/) { $outfmt = "html"; $html = 1; }
if ($outfile && $outfile !~ /\./ && $outfile !~ /\/$/ && $outfmt) {
    $outfile .= ".$outfmt";
}

$html = $outfmt eq "html";
$outfile =~ s|/lyrics.html$|/|;

if ($outfile =~ m|^(.*/)?([^/]+)(\.[^./]+)$|) {
    $filebase = "$2";
    $filedir  = ($1 eq "")? "." : $1;
    $shortname= $2;
    $filename = "$2$3";
    $htmlfile = "$filebase.html";
} elsif ($outfile =~ m|^(.*/)?([^/]+)/$|) {
    $filebase = "$2";
    $filedir  = "$1/$2";
    $shortname= $2;
    $filename = "lyrics.html";
    $htmlfile = "$filebase/";
    $outfile  = "$filedir/lyrics.html";
} 

if ($WEBSITE) {
    $WEBSITE =~ m|https?://([^/]+)|;
    $sitename = $1;
} else {
    $sitename = '';
}

if ($verbose) {
    print STDERR "  infile=$infile; outfile=$outfile; format=$outfmt\n";
    print STDERR "  filedir=$filedir; filebase=$filebase; htmlfile=$htmlfile\n";
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
    $SPOKEN  = $EM . "(spoken) ";
    $_SPOKEN = $_EM;
    $SUBSEC  = "<h3>";
    $_SUBSEC  = "</h3>";
    $SUBSUB  = "<h4>";
    $_SUBSUB  = "</h4>";
    $NL  = "<br />\n";
    $NP  = "<hr />\n";
    $SP  = "&nbsp;";
    $AMP = "&amp;";
    # it might be more sensible to use the cellpadding to space the verses.
    $BVERSE = ($tables)? "<table cellpadding=0 cellspacing=0 class='verse'>\n<tr>" : "<pre class='verse'>\n";
    $EVERSE = ($tables)? "</tr></table>\n" : "</pre>\n";
    $FLKTRAN = "<a href='/Tools/TeX/flktran.html'><code>flktran</code></a>";
    # Creative Commons copyright notice
    $SomeRightsReserved =
'<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/80x15.png" 
/>Some Rights Reserved: CC-by-nc-sa/4.0</a>
 ';
    $CCnotice = 
'<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/80x15.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.';
} else {
    $EM  = "_";
    $_EM = "_";
    $BF  = "*";
    $_BF = "*";
    $TT  = "";
    $_TT = "";
    $UL  = "";
    $_UL = "";
    $SPOKEN  = "(spoken) ";
    $_SPOKEN = "";
    $SUBSEC  = "";
    $_SUBSEC  = "";
    $SUBSUB  = "";
    $_SUBSUB  = "";
    $NL  = "\n";
    $NP  = "\f";
    $SP  = " ";
    $AMP = "&";
    $BVERSE = "\n";
    $EVERSE = "\n";
    $FLKTRAN = "flktran";
    $SomeRightsReserved = "CC by-nc-sa/4.0";
    $CCnotice = 'This work is licensed under a Creative Commons
Attribution-Noncommercial-Share Alike 4.0 International License</a>. ';

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
    elsif (/\\tags/)		{ $tags = getContent($_); }
    elsif (/\\category/)	{ $tags = getContent($_); }
    elsif (/\\dedication/)	{ $dedication = getContent($_); }
    elsif (/\\license/) 	{ $license = getContent($_); }
    elsif (/\\timing/)  	{ $timing = getContent($_); }
    elsif (/\\created/)  	{ $created = getContent($_); }
    elsif (/\\notice/)  	{ $notice = getContent($_); }
    elsif (/\\cvsid/)		{ $cvsid = getContent($_); } # deprecated
    elsif (/\\music/)		{ $music = getContent($_); }
    elsif (/\\lyrics/)		{ $lyrics = getContent($_); }
    elsif (/\\arranger/)	{ $arranger = getContent($_); }
    elsif (/\\description/)	{ $description = getContent($_); }
    elsif (/\\ttto/)            { $ttto = getContent($_); }
    elsif (/\\def/)             {  } # ignore macro definitions

    # Environments: 

    elsif (/\\begin\{refrain/)	{ begRefrain(); } # Refrain (deprecated)
    elsif (/\\end\{refrain/)	{ endRefrain(); }
    elsif (/\\begin\{chorus/)	{ begRefrain(); } # chorus (same as refrain for now)
    elsif (/\\end\{chorus/)	{ endRefrain(); }
    elsif (/\\begin\{bridge/)	{ begBridge(); }  # Bridge
    elsif (/\\end\{bridge/)	{ endBridge(); }
    elsif (/\\begin\{note/)	{ begNote(); } 	  # Note
    elsif (/\\end\{note/)	{ endNote(); }
    elsif (/\\begin\{quotation/){ begQuote(); }	  # Quote
    elsif (/\\end\{quotation/)	{ endQuote(); }
    elsif (/\\begin\{song/)	{ begSong($_); }  # Song
    elsif (/\\end\{song/)	{ endSong(); }

    elsif (/\\inset/)		{ doInset(); }
    elsif (/\\tailnote/)	{ doTailnote(); }

    # Ignorable TeX macros:
    elsif (/\\(small|footnotesize|advance|vfill|vfiller|vbox|makesongtitle)/) {}
    elsif (/\\(oddsidemargin|evensidemargin|textwidth)/) {}
    elsif (/\\(begin|end)\{/)	{} # other environments get ignored
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

### Begin a song:
###	Stash the title, put out the header.
sub begSong {
    my ($line) = @_;		# input line
    $line =~ s/^.*song\}//;
    $title = getContent($line);	
    if ($bare) { return; }
    if ($html) {
	my $alinks = " <a href='lyrics.pdf'>[pdf]</a>";
	$alinks .= " <a href='$filebase.ogg'>[ogg]</a>" 
	    if -f "$filedir/$filebase.ogg";
	$alinks .= " <a href='$filebase.mp3'>[mp3]</a>"
	    if -f "$filedir/$filebase.mp3";
	print "<html><head>";
	print "<title>$title</title>\n";
	print "</head><body>\n";
	#print "<h3><a href='./'>$WEBDIR</a> / $htmlfile</h3>\n";
	print "<h3>"
	    . ($sitename? "<a href='$WEBSITE'>$sitename</a>" : "")
	    . expandPath("$WEBDIR/$htmlfile") . $alinks . "</h3>\n";
    }
}

### End a song:
###	End the file.
sub endSong {
    if ($bare) { return; }
    if ($html) {
	print "<hr>";
	print "<p><small><code><a href='./'>$WEBSITE/$WEBDIR/</a>$htmlfile";
	print "</code><br>\n";
	print "   <i>Automatically generated with $FLKTRAN";
	print " from <code>$infile</code>.<i><br>\n";
	if ($cvsid) { print "   <i>$cvsid</i>\n"; }
	print "</small></p>\n";
	print "</body></html>\n" ;
    } else {
	if ($WEBSITE) {
	    print "\n\nOnline:\n";
	    print "    $WEBSITE/$WEBDIR/$filedir$filename\n\n";
	}
	print "Automatically generated with $FLKTRAN from $infile.\n";
    }
}

### Begin a verse:
###	Called before processing the first line in the new verse.
sub begVerse {
    print $BVERSE;
    $verse ++;			# bump the verse count.
    $vlines = 0;
}

### End a verse:
###	Only called if there are actually lines in it.
sub endVerse {
    print $EVERSE;
    $vlines = 0;
}

### Separate verses.
sub sepVerse {
    if ($vlines) { endVerse(); $vlines = 0; }
    if ($tables) { print "<br/>\n"; }
}

### Handle a blank line.
sub blankLine {
    if ($vlines) { endVerse(); $vlines = 0; }
    if ($plain) {
	print "\n";
	$plines = 0;
    }
}

### Handle an inset
sub doInset {
    endVerse();
    if ($html) { print "<blockquote><i>\n"; }
    indentLine(getContent($_, $TABSTOP) . "\n", $TABSTOP);
    if ($html) { print "</i></blockquote>\n"; }
}

### Handle a tailnote
sub doTailnote {
    endVerse(); 
    if ($html) { print "<p>\n"; }
    indentLine(getContent($_, 0) . "\n");
}

### Begin a refrain:
sub begRefrain {
    my ($isBridge) = @_;
    my $cssClass = $isBridge? "bridge" : "chorus";
    if ($vlines) { endVerse(); }
    if ($html) { print "<blockquote class='$cssClass'>\n" if ($tables); }
    $indent += $TABSTOP;
    # Note that begVerse will get called when the first line appears,
    # so we don't have to deal with verse count, line count, or <pre>.
}

### End a refrain:
sub endRefrain {
    if ($html) { 
	endVerse(); 
	print "</blockquote>" if ($tables);
    }
    print "\n"; 
    $vlines = 0;
    $indent -= $TABSTOP;
 }

### Begin a bridge:
sub begBridge {
    begRefrain(1);
    if ($html) { print "<blockquote>\n" if ($tables); }
    $indent += $TABSTOP;
    # Note that begVerse will get called when the first line appears,
    # so we don't have to deal with verse count, line count, or <pre>.
}

### End a bridge:
sub endBridge {
    endRefrain();
    if ($html) { print "</blockquote>" if ($tables); }
    print "\n"; 
    $vlines = 0;
    $indent -= $TABSTOP;
}

### Begin a note:
sub begNote {
    if ($vlines) { endVerse(); }
    if ($html) { print "<small>"; }
    $plines = 0;
    $plain ++;
}

### End a note:
sub endNote {
    if ($html) { print "</small>\n"; }
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
    $header ++;
    if ($bare)  { return; }
    if ($html)	{ htmlHeader(); }
    else	{ textHeader(); }
}

sub center {
    # === need to handle multiple lines ===
    my ($text) = @_;
    $text =~ s/^[ \t]*//;
    $text =~ s/[ \t]*\n$//;
    $text =~ s/\\copyright/Copyright/;
    $text =~ s/[Ss]ome [Rr]ights [Rr]eserved\.?/$SomeRightsReserved/gs;
    $text =~ s/\\SomeRightsReserved/$SomeRightsReserved/gs;
    $text =~ s/\\CcByNcSa/$CCNotice/gs;

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
    $text =~ s/[Ss]ome [Rr]ights [Rr]eserved\.?/$SomeRightsReserved/gs;
    $text =~ s/\\SomeRightsReserved/$SomeRightsReserved/gs;
    $text =~ s/\\CcByNcSa/$CCNotice/gs;
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
###   When using tables, each line becomes a separate table containing chords and text.
###   This, in turn, becomes a row in a table containing the verse.
sub tableLine {
    my ($line) = @_;		# input line
    my $cline = "";		# chord line
    my $dline = "";		# dest. (text) line
    my ($scol, $ccol, $dcol, $inword, $inchord, $inmacro) = ($indent, 0, 0, 0, 0, 0);
    my $c = '';			# current character
    my $p = 0;			# current position

    $line = deTeX($line);

    $line =~ s/^[ \t]*//;
    $line =~ s/\\sus/sus/g;
    $line =~ s/\\min/m/g;
    $line =~ s/[\n\r]//g;

    $cline .= "  <tr class=chords><td>";
    $dline .= "  <tr class=lyrics><td>";

    for ($p = 0; $p < length($line); $p++) {
	$c = substr($line, $p, 1); 
	if    ($c eq "\n" || $c eq "\r") { break; }
	if    ($c eq '[') {
	    if (! $inword) { $dline .= "\&nbsp;"; }
	    $inchord ++;
	    $cline .= "<td> ";
	    $dline .= "<td> ";
	}
	elsif ($c eq ']') { $inchord --; }
	elsif ($c eq ' ') { if (!$inchord) { $scol ++; $inword = 0; } }
	elsif ($c eq "\t") {
	    if (!$inchord) { do {$scol ++; } while ($scol % 8); $inword = 0; } }
	else {
	    if ($inchord) {
		while ($ccol < $scol) { $cline .= ' '; $ccol ++ }
		$cline .= $c;
		$ccol ++;
	    } else {
		while ($dcol < $scol) { $dline .= ' '; $dcol ++ }
		$dline .= $c;
		$inword = 1;
		$dcol ++;
		$scol++;
	    }
	}
    }
    $cline .= "</tr>\n";
    $dline .= "</tr></table>\n";
    # The result has a newline appended to it.
    # cellpadding=0 cellspacing=0 only when the chord appears inside a word.
    # alternatively, use &nbsp; for a space before a chord.  Probably cleaner.
    return "<table cellpadding=0 cellspacing=0>\n" . (($chords)? $cline . $dline : $dline);
}

### Remove LaTeX constructs.
###    NOTE:  This code does not handle nested {...} blocks or comments that contain braces.
###    It's really crude; it would be better to parse the input into tokens and keep a stack
###    that says what to do when we reach a chord or a closing brace.  Later.  Also, see
###    songinfo for what to do about getting the content for things like \notice, which can
###    be split across several lines.
sub deTeX {
    my ($txt) = @_;		# input line

    # Remove TeX comments (which eat the line break as well)
    # and extend the line until it contains no unmatched left braces
    while ($txt =~ /\%/ || $txt =~ /\{[^\}]*$/) {
	$txt =~ s/\%.*\n$//;	# TeX comments eat the line break, too.
	$txt .= <STDIN>;
    }
    
    # The tricky part is making sure that the block doesn't include a chord, because
    # the parts before and after the chord end up in different <td> cells.
    while ($txt =~ /\{\\(em|tt|bf|)[ \t\n]/
	   || $txt =~ /\\(ul|underline|link|subsection|subsubsection)\{/
	   || $txt =~ /\\(emph|spoken)\{/
	   || $txt =~ /\\(subsection|subsubsection)\*[^\{]*\{/
      ) {
	my $tag = $1;
	if ($tables && ($tag =~ /(em|bf|tt)/) && $txt =~ /\{\\$tag[^\}\[]*\[/) {
	    # we have a chord before the end of the block.  Split.
	    # em, bf, and tt all split the same way
	    $txt =~ s/(\{\\$tag[^\[]*)(\[[^\]]*\])/$1\}$2\{\\$tag /;
	    # If there's a space in front of the chord, keep it there, because
	    # tableLine turns a space before a chord into &nbsp;
	    $txt =~ s/([ \t])\}/}$1/;
	}
	if ($tag eq "em") {
	    $txt =~ s/\{\\em[ \t\n]/$EM/; 
	    $txt =~ s/\}/$_EM/;
	}
	if ($tag eq "emph") { # italicize, but has the form \tag{...}  Does't handle chords
	    $txt =~ s/\\emph\{/$EM/;
	    $txt =~ s/\}/$_EM/;
	}
	if ($tag eq "spoken") { # italicize, but has the form \tag{...}  Does't handle chords
	    $txt =~ s/\\spoken\{/$SPOKEN/;
	    $txt =~ s/\}/$_EM/;
	}
	if ($tag eq "tt") {
	    $txt =~ s/\{\\tt[ \t\n]/$TT/; 
	    $txt =~ s/\}/$_TT/;
	}
	if ($tag eq "bf") {
	    $txt =~ s/\{\\bf[ \t\n]/$BF/; 
	    $txt =~ s/\}/$_BF/;
	}
	if ($tag eq "ul" || $tag eq "underline") {
	    # want to be able to handle underline{}
	    if ($tables && ($txt =~ /\\$tag\{[^\}\[]*\[/)) {
		# we have a chord before the end of the block.  Split.
		$txt =~ s/(\\$tag\{[^\}\[]*)(\[[^\]]*\])/$1\} $2\\$tag\{/;
	    }	    
	    $txt =~ s/\\$tag\{/$UL/; # ul and underline have the same replacement text
	    $txt =~ s/\}/$_UL/;
	}
	if ($tag eq "link") {
	    while ($txt !~ /\\link\{[^\}]*\}\{[^\}]*\}/) { $txt .= <STDIN>; }
	    if ($html) {
		$txt =~ s/\\link\{([^\}]*)\}\{([^\}]*)\}/<a href="$1">$2<\/a>/;
		$txt =~ s/\\_/_/; #fix escaped _'s etc in url
	    } else {
		$txt =~ s/\\link\{([^\}]*)\}\{([^\}]*)\}/$2/;
	    }
	}
	if ($tag eq "subsection") {
	    $txt =~ s/\\subsection\*?\{/$SUBSEC/;
	    $txt =~ s/\}/$_SUBSEC/;
	}
	if ($tag eq "subsubsection") {
	    $txt =~ s/\\subsubsection\*?\{/$SUBSUB/;
	    $txt =~ s/\}/$_SUBSUB/;
	}
    }
    $txt =~ s/\\hfill//g;
    $txt =~ s/---/--/g;
    $txt =~ s/\\&/$AMP/g;
    $txt =~ s/\\;/$SP/g;
    $txt =~ s/\\ /$SP/g;
    $txt =~ s/\\ldots/.../g;
    $txt =~ s/\\\_/\_/g;
    $txt =~ s/\\\$/\$/g;
    $txt =~ s/\\\\/$NL/g;
    $txt =~ s/\\clearpage/$NP/g;
    $txt =~ s/\\newpage/$NP/g;
    $ext =~ s/\\columnbreak/$NP/g;

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
#	The last directory component is linked to "./", which is something
#	of a hack, but it works.  All other path components are linked to 
#	the absolute path, including $WEBSITE, so that they'll work even
#	if the file ends up on a disk somewhere.
#
sub expandPath {
    my ($path) = (@_);
    my $result = '';
    my $pfx = '';

    $path .= ' ' if $path =~ m|/$|;
    while ($path =~ s|^(/+)([^/]+)/(.+)$|/$3| ) {
	$result .= $1;
	$pfx .= $1 . $2;
	my ($dir, $tail) = ($2, $3);
	$result .= ($tail =~ m|/|)
	    ? "<a href='$WEBSITE$pfx/'>$dir</a>"
	    : "<a href='./'>$dir</a>"
	}
    return $result . $path;
}
