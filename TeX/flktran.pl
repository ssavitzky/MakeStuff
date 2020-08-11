#!/usr/bin/perl
# $Id: flktran.pl,v 1.15 2010-10-14 06:48:15 steve Exp $
# flktran [options] infile outfile
#	Perform format translation on filksong files.    

# ChordPro: TODO
#   split (Key\capoN) into {key Key} and {capo N}
#   handle {chorus} and similar inline metadata

### Print usage info:
sub usage {
    print "$0 [options] infile[.flk] [outfile].ext\n";
    print "	-b -bare	bare lyrics -- no headings\n";
    print "	-c -chords	output chords\n";
    print "	-h -html	output html\n";
    print "	-n -dryrun	no action (dry run)\n";
    print "	-t -tables	use tables (implies -h -c)\n";
    print "	-v	verbose\n";
    print " Formats (extensions): \n";
    print "	cho	ChordPro (also chord, chordpro, or cpro)\n";
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
$dryrun  = 0;

### Adjustable parameters:

$TABSTOP = 4;			# tabstop for indented constructs
$WIDTH   = 72;			# line width for centering

### Variables set from environment:

$WEBSITE = $ENV{'WEBSITE'};
$WEBDIR  = $ENV{'WEBDIR'};
$WEBDIR  =~ s|/$||;

### State variables:

$indent   = 0;			# current indentation level
$plain    = 0;			# true when inside plain (non-chorded) text
$chorus   = 0;			# true inside a chorus or bridge

$verse    = 0;			# number of verses seen so far
$vlines   = 0;			# the number of lines in the current verse or chorus
$plines   = 0;			# the number of lines in the current text block
$header   = 0;			# true after header done.
$verbatim = 0;			# true inside a verbatim environment -- <pre> in html

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
    elsif ($ARGV[0] eq "-n"|| $ARGV[0] eq "-dryrun") { shift; $dryrun = 1; }
    else { usage; die "unrecognized option $1\n"; }
}

if ($ARGV[0]) { $infile = shift; }
if ($ARGV[0]) { $outfile= shift; }

if ($infile !~ /\./) { $infile .= ".flk"; }
if ($html) { $outfmt = "html"; }

# If $outfile ends in /, it's a directory.  In that case, the output
# goes into the corresponding directory, in a file called lyrics.html
if ($outfile =~ /\.html$/) { $outfmt = "html"; $html = 1; }
if ($outfile =~ /\.c(h|pr)o[a-z]*$/) { $outfmt = "cpro"; $cpro = 1; $chords = 1; }
if ($outfile && $outfile !~ /\./ && $outfile !~ /\/$/ && $outfmt) {
    $outfile .= ".$outfmt";
}
# The extension-handling and name-handling stuff is a mess, but we'll save
# any major changes for the grand refactoring.  Right now we just want
# to be able to handle ChordPro

$html = $outfmt eq "html";
$tables = 0 unless $html;

$outfile =~ s|/lyrics.html$|/|;
$outfile =~ s/^\.[a-z]+$//;	# just an extension: output goes to stdout

if ($outfile =~ m|^(.*/)?([^/]+)(\.[^./]+)$|) {
    $filebase = "$2";
    $filedir  = ($1 eq "")? "." : $1;
    $shortname= $2;
    $extension= $3;		# note that the extension includes the final "."
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
    print STDERR "  html=$html; tables=$tables; cpro=$cpro; plain=$plain\n";
}

if ($dryrun) { exit 0; }
if ($infile) { open(STDIN, $infile); }
if ($outfile) { open(STDOUT, ">$outfile"); }

### Formatting constants:
#   After the refactoring, these ought to end up as hash keys
if ($html) {
    $EM  = "<em>";
    $_EM = "</em>";
    $BF  = "<b>";
    $_BF = "</b>";
    $TT  = "<code>";
    $_TT = "</code>";
    $UL  = "<u>";
    $_UL = "</u>";
    $PRE = "<pre>";
    $_PRE= "</pre>";
    $QUOTATION = "&nbsp;&nbsp;"; # sometimes used for indent inside spoken text
    $_QUOTATION = "";
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
    $BVERSE = ($tables)? "<table cellpadding=0 cellspacing=0 class='verse'>\n<tr><td>" 
	                 : "<pre class='verse'>\n";
    $EVERSE = ($tables)? "</td></tr></table>\n" : "</pre>\n";
    $FLKTRAN = "<a href='/Tools/TeX/flktran.html'><code>flktran</code></a>";
    # Creative Commons copyright notice
    $SomeRightsReserved =
'<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/80x15.png" 
/>Some Rights Reserved: CC-by-nc-sa/4.0</a>
 ';
    $CCnotice = 
'<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/80x15.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.';
} elsif ($cpro) {
    $EM  = "_";			# there really isn't a good way to do \em, \bf, \tt, etc.
    $_EM = "_";			# in ChordPro without referring to actual fonts.  :P
    $BF  = "**";		# so use markdown and hope the app can render it.
    $_BF = "**";		# It's still understandable even if not rendered.
    $TT  = "`";
    $_TT = "`";
    $UL  = "_";
    $_UL = "_";
    $PRE = "";			# I have no idea how to do this in chordpro
    $_PRE= "";
    $QUOTATION = "    ";	# sometimes used for indent inside spoken text
    $_QUOTATION = "";
    $SPOKEN  = "{comment_italic: (spoken):";
    $_SPOKEN = "}";
    $SUBSEC  = "{textsize: 150%}";
    $_SUBSEC = "{textsize: 100%}";;
    $SUBSUB  = "{textsize: 120%}";
    $_SUBSUB  = "{textsize: 100%}";
    $NL  = "\n";
    $NP  = "{new_page}";
    $SP  = " ";
    $AMP = "&";
    $BVERSE = "{start_of_verse}\n"; # try this "\n";
    $EVERSE = "{end_of_verse}\n";
    $FLKTRAN = "flktran";
    $SomeRightsReserved = "CC by-nc-sa/4.0";
    $CCnotice = 'This work is licensed under a Creative Commons
Attribution-Noncommercial-Share Alike 4.0 International License</a>. ';
} else {
    $EM  = "_";
    $_EM = "_";
    $BF  = "*";
    $_BF = "*";
    $TT  = "";
    $_TT = "";
    $UL  = "";
    $_UL = "";
    $PRE = "";
    $_PRE= "";
    $QUOTATION = "";
    $_QUOTATION = "";
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
    $BVERSE = ""; # try this "\n";
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
    elsif (/\\category/)	{ $tags = getContent($_); }  # category -> tags
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

    elsif (/\\begin\{refrain/)	{ begChorus(); } # Refrain (deprecated; use chorus)
    elsif (/\\end\{refrain/)	{ endChorus(); }
    elsif (/\\begin\{chorus/)	{ begChorus(); } # Chorus
    elsif (/\\end\{chorus/)	{ endChorus(); }
    elsif (/\\begin\{bridge/)	{ begBridge(); }  # Bridge
    elsif (/\\end\{bridge/)	{ endBridge(); }
    elsif (/\\begin\{note/)	{ begNote(); } 	  # Note
    elsif (/\\end\{note/)	{ endNote(); }
    elsif (/\\begin\{quotation/){ begQuote(); }	  # Quote
    elsif (/\\end\{quotation/)	{ endQuote(); }
    elsif (/\\begin\{song/)	{ begSong($_); }  # Song
    elsif (/\\end\{song/)	{ endSong(); }
    elsif (/\\begin\{verbatim/)	{ begVerbatim(); }  # verbatim
    elsif (/\\end\{verbatim/)	{ endVerbatim(); }

    elsif (/\\inset/)		{ doInset(); }
    # it's tempting to do:  elsif (/\\spoken/) 	{ doInset("(spoken) "); }
    # that would make it difficult to ignore embedded emphasis.  The real
    # solution may be to deprecate embedded emphasis.
    elsif (/\\tailnote/)	{ doTailnote(); }

    # Ignorable TeX macros:
    elsif (/\\(small|footnotesize|advance|vfill|vfiller|vbox|makesongtitle)/) {}
    elsif (/\\(oddsidemargin|evensidemargin|textwidth)/) {}
    elsif (/\\(begin|end)\{/)	{} # other environments get ignored
    elsif (/\\ignore/)		{ getContent($_); }
    elsif (/\\comment/)		{ getContent($_); }

    # Default:

    else  { doLine(); }		# Verse or plaintext line
}

########################################################################
###
### Macro handlers:
###
###	Each of the following routines handles a LaTeX macro.
###

# after the refactoring, tag/cpro boilerplate ought to be functions

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
    if ($cpro) {
	# maybe we should put out {new_song}?
	print "{new_song}\n";
    }
}

### End a song:
###	End the file.
sub endSong {
    if ($vlines) { endVerse(); }
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
    } elsif ($cpro) {
	if ($WEBSITE) {
	    print "{meta: website $WEBSITE/$WEBDIR/$filedir$filebase}\n";
	}
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
###	Note that in HTML, chorus and bridge are treated as (unnumbered) verses
###     In ChordPro, verses, choruses, and bridges have different start/end tags.
sub begVerse {
    $vlines = 0;
    print $BVERSE unless ($cpro && $chorus);
    $verse ++ unless $chorus;			# bump the verse count.
}

### End a verse:
###	Only called if there are actually lines in it.
sub endVerse {
    if ($vlines) {
	print $EVERSE unless ($cpro && $chorus);
    }
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
    my $content = getContent($_, $TABSTOP);
    if ($html) { print "<blockquote><i>\n"; }
    if ($cpro) {
	if ($content =~ /^(refrain|chorus)$/i) {
	    indentLine('{chorus', $TABSTOP);
	} else {
	    indentLine("{comment_italic: $content", $TABSTOP);
	}
	print "}"
    } else {    
	indentLine($content, $TABSTOP);
    }
    print "\n";
    if ($html) { print "</i></blockquote>\n"; }
}

### Handle a tailnote
sub doTailnote {
    if ($vlines) {endVerse(); }
    if ($html) { print "<p>\n"; }
    indentLine(getContent($_, 0) . "\n");
}

### Begin a chorus:
sub begChorus {
    my ($isBridge) = @_;
    my $cssClass = $isBridge? "bridge" : "chorus";
    if ($vlines) { endVerse(); }
    print "\n";
    if ($html) { print "<blockquote class='$cssClass'>\n" if ($tables); }
    if ($cpro) {
	print "{start_of_$cssClass}\n";
	# chordpro (the reference implementation) treats a bridge just like a verse
	# so we add a comment to distinguish it.
	print "{comment_italic: bridge:}\n" if ($isBridge);
    }
    $indent += $TABSTOP;
    $chorus ++;
    # Note that begVerse will get called when the first line appears,
    # so we don't have to deal with verse count, line count, or <pre>.
}

### End a chorus:
#   (also called a refrain; that usage is being phased out.)
sub endChorus {
    my ($isBridge) = @_;
    my $cssClass = $isBridge? "bridge" : "chorus";
    if ($html) { 
	endVerse(); 
	print "</blockquote>\n" if ($tables);
    }
    if ($cpro) { 
	endVerse();
	print "{end_of_$cssClass}\n"; 
    }
    print "\n"; 
    $vlines = 0;
    $chorus --;
    $indent -= $TABSTOP;
 }

### Begin a bridge:
sub begBridge {
    begChorus(1);
    if ($html) { print "<blockquote>\n" if ($tables); }
    $indent += $TABSTOP;
    # Note that begVerse will get called when the first line appears,
    # so we don't have to deal with verse count, line count, or <pre>.
}

### End a bridge:
sub endBridge {
    endChorus(1);
    if ($html) { print "</blockquote>" if ($tables); }
    print "\n"; 
    $vlines = 0;
    $indent -= $TABSTOP;
}

### Begin a note:
sub begNote {
    if ($vlines) { endVerse(); }
    if ($html) {
	# We used to try to set this in a smaller font, but you can't
	# nest paragraphs (block elements) inside of a <small> (inline element);
    }
    $plines = 0;
    $plain ++;
}

### End a note:
sub endNote {
    if ($html) {
	# We used to try to set this in a smaller font, but you can't
	# nest paragraphs (block elements) inside of a <small> (inline element);
    }
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

### Begin a verbatim section:
sub begVerbatim {
    print $PRE;
    $verbatim ++;
    
}
sub endVerbatim {
    print $_PRE;
    $verbatim --;
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
    if ($bare)    { return; }
    if ($html)	  { htmlHeader(); }
    elsif ($cpro) { cproHeader(); }
    else	  { textHeader(); }
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

sub directive {
    my ($h, $text, $text2) = @_;
    $text = $text2 . " " . $text if $text2;
    print "{$h: $text}\n";
}

sub cproHeader {
    directive ("title", $title);
    if ($key)           {
	# If there's a capo indication, that goes in the {capo} directive
	if ($key =~ /([A-Za-z]+) *\\capo *([0-9]+)/) {
	    $key = $1;
	    $capo = $2;
	}
	directive "key", $key
    }
    if ($capo)          { directive "capo", $capo }
    if ($subtitle) 	{ directive "subtitle", $subtitle; }
    if ($notice) 	{ directive "comment_italic", $notice; }
    if ($license)	{ directive "meta", "license", $license; }
    if ($lyrics)        { directive "lyricist", $lyrics; }
    if ($music)         { directive "composer", $music; } 
    if ($timing)        { directive "time", $timing; }
    if ($dedication) 	{ directive "meta", "dedication", $dedication; }
    if ($description) 	{ directive "meta", "description", $description; }
    print "\n";
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
    if ($verbatim) {
	if ($html) {
	    s/\&/&amp;/;
	    s/\</&lt;/;
	    s/\>/&gt;/;
	}
	print $_;
    } elsif ($plain) {
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
    $line =~ s/\\maj/maj/g;

    if ($cpro) {
	return $line;
    }

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
    $line =~ s/[\n\r]//g;
    # the following may be redundant if handled in deTeX
    $line =~ s/\\sus/sus/g;
    $line =~ s/\\min/m/g;

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
    # ignore nested emphasis (i.e. in \spoken{...})
    # The right thing would be to handle it in doLine using getContent
    my ($em, $_em) = ("","");
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
	   || $txt =~ /\\(emph|spoken|quotation)\{/
	   || $txt =~ /\\(subsection|subsubsection)\*[^\{]*\{/
	   || $txt =~ /\\(hskip)/
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
	    $txt =~ s/\{\\em[ \t\n]/$em/; 
	    $txt =~ s/\}/$_em/;
	}
	if ($tag eq "emph") { # italicize, but has the form \tag{...}  Does't handle chords
	    $txt =~ s/\\emph\{/$em/;
	    $txt =~ s/\}/$_em/;
	}
	if ($tag eq "spoken") { # italicize, but has the form \tag{...}  Does't handle chords
	    $txt =~ s/\\spoken\{/$SPOKEN/;
	    $em = "";
	    $_em = "";
	    $txt =~ s/\}/$_SPOKEN/;
	}
	if ($tag eq "quotation") { # quotation in the form \tag{...}
	    # used sometimes to get a paragraph indent inside of "spoken"
	    $txt =~ s/\\quotation\{/$QUOTATION/;
	    $txt =~ s/\}/$_QUOTATION/;
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
	    $txt =~ s/$UL *$_UL//; # remove empty underline elements
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
	if ($tag eq "hskip") {
	    $txt =~ /\\hskip([0-9]+)em/;
	    my $sp = "";
	    for (my $d = $1; $d > 0; $d--) {
		$sp .= $SP;
	    }
	    $txt =~ s/\\hskip([0-9]+)em/$sp/;
	}
    }
    # convert FlkTex stuff that shows up inside chords and key
    $txt =~ s/\\sus/sus/g;
    $txt =~ s/\\min/m/g;
    $txt =~ s/\\maj/maj/g;
    $txt =~ s/\\dim/dim/g;
    $txt =~ s/\\sharp/#/g;
    $txt =~ s/\\flat/b/g;    
	
    # convert TeX constructs
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
