#!/usr/bin/perl
#	$Id: boilermaker.pl,v 1.1 2007-05-20 17:44:27 steve Exp $

#<title>insert boilerplate</title>
#	This script is used to insert "boilerplate" text, especially 
#	license notices, into source code and documentation files.  
#	The insertion is done following the first blank line in the file,
#	unless an earlier version of the boilerplate text is detected.
#	
#	A boilerplate template file must begin and end with a line
#	containing three hashes; unless overridden on the command
#	line, the text on the first and last lines must match exactly
#	(modulo the changes needed to make a comment) in order for the
#	old boilerplate to be recognized.
#	
#	The template is converted into a comment by either:
#	  o enclosing it in comment-start and comment-end sequences
#	  o inserting a comment sequence at the beginning of each line
#	  o converting the first hash in each line to a comment 
#	    sequence, if each template line starts with a hash.

### Open Source/Free Software license notice:
 # The contents of this file may be used under the terms of the GNU
 # General Public License Version 2 or later (the "GPL").  The text
 # of this license can be found on this software's distribution media,
 # or obtained from  www.gnu.org/copyleft/gpl.html	
###						    :end license notice	###

# Note:	Eventually things like the hashmark should be parametrized. 
#	There is no good way to distinguish a Makefile or script fragment
#	from a template, but it's easy enough to avoid running boilermaker
#	on templates, so we don't worry about it.  Using hash instead of 
#	asterisk (which was also briefly considered) makes it easier to
#	construct a Makefile (e.g. in "make setup") using echo and cat.
#
#	It should also be possible to recognize a previous insert version
#	by matching ### plus a keyword, to handle the case where the text
#	on the first line changes from one version to the next.
#
#	We should also make space at the beginning and end of the first and
#	last line optional when checking for a previous version.

if (! @ARGV) {
    print "Usage:  $0 template file...\n";
    exit 0;
}

my $bak = ".~bak~";

### Read and analyse the template file

my $template_file = $ARGV[0]; shift @ARGV;
if (! open(IN, $template_file)) {
    die "Template file '$template_file' does not exist";
}

my $template_text  = "";
my $template_first = "";
my $template_last  = "";
my $template_hash  = 1;

while (<IN>) {
    $template_text .= $_;
    $template_last = $_;
    if ($template_first eq "") { $template_first = $_; }
    $template_hash = 0 unless /^ *\#/;
}
close IN;

### If no input files, just print the analysis of the template.

if (! @ARGV) {
    print "No target files specified; just analyzing the template:\n";
    print $template_first;
    print " " . ($template_hash? "E" : "Not e")
	. "very line of template has * as its first nonblank character\n";
    exit 0;
}

### Loop through the input files.

my $n_replaced = 0;
my $n_inserted = 0;

while (@ARGV) {
    my $infile = $ARGV[0]; shift @ARGV;

    next if (-d $infile);
    next if ($infile =~ /\~$/);

    # Read the input file (only once)
    my $content = read_file($infile);
    if ($content eq "") {
	print STDERR "*** Input file '$infile' missing or empty: skipping\n";
	next;
    }

    if ($content =~ /^\#/) {
	print STDERR "   Input file '$infile' appears to be a script.\n"
	    if $verbose;
	$comment_bol = "";			# would be #, but it's a no-op
	$comment_beg = "";
	$comment_end = "";
    } elsif ($content =~ /^[;\[]/) {
	print STDERR "   Input file '$infile' appears to be LISP.\n"
	    if $verbose;
	$comment_bol = ";";
	$comment_beg = "";
	$comment_end = "";
    } elsif ($content =~ /^[%\\]/) {
	print STDERR "   Input file '$infile' appears to be TeX.\n"
	    if $verbose;
	$comment_bol = "%";
	$comment_beg = "";
	$comment_end = "";
    } elsif ($content =~ /^\</) {
	print STDERR "   Input file '$infile' appears to be *ML.\n"
	    if $verbose;
	$comment_bol = "";
	$comment_beg = "<!-- ";
	$comment_end = " -->";
    } elsif ($content =~ m|^ *//| ||
	     $content =~ m|^ /\*|) {
	print STDERR "   Input file '$infile' appears to be C or Java.\n"
	    if $verbose;
	$comment_bol = "*";
	$comment_beg = "/*";
	$comment_end = "*/";
    } else {
	print STDERR "** Input file '$infile' is unrecognizable: skipping.\n";
	next;
    }
    
    # Hack the template according to the comment style

    my $insert = $template_text;
    my $first  = $template_first;
    my $last   = $template_last;
    my $qce    = quotemeta($comment_end);
    my $qqce   = quotemeta($qce);

    if ($comment_bol && $template_hash) {
	$insert =~ s/\#/$comment_bol/gs;
	$first  =~ s/\#/$comment_bol/gs;
	$last   =~ s/\#/$comment_bol/gs;
    } else {
	$insert =~ s/^/$comment_bol/gs if $comment_bol;
    }

    $insert = $comment_beg . $insert . $comment_end;
    $insert =~ s/\n$qce/$comment_end\n/s if $comment_end;

    # Either replace the old template, or insert a new one
    #	skip files that already have the most recent template inserted.
    #	Note that the way we do the substitution is exceedingly crude; 
    #	there are things that might show up in the template that would
    #	cause trouble in the substitution.

    $first = quotemeta($first);
    $last  =~ s/\n//s;				# take the \n off $last...
						# it interacts w\ quotemeta
    $last  = quotemeta($last);
    my $inserted = quotemeta($insert);

    # Make number of leading spaces on first and last line optional
    # to make it easier to change the indentation.  

    if ($first =~ /^ /) { $first =~ s/^ / */; }
    else 		{ $first = " *" . $first; }
    if ($last  =~ /^ /) { $last =~ s/^ / */; }
    else 		{ $last = " *" . $last; }

    $first = quotemeta($comment_beg) . $first;
    $last .= $qce . "\n";			# ...put the \n back

    if ($content =~ /$inserted/s) {
	print STDERR "-- Input file '$infile' is up to date: skipping.\n"
	    if $verbose;
	next;
    } elsif ($content =~ /$first.*$last/s) {
	# This will do horrible things to a file that contains 
	# more than one line that matches $last!!
	# Really ought to cycle through the lines and do it carefully.
	$content =~ s/$first.*$last/$insert/s;
	$n_replaced ++;
    } else {
	# This will probably work OK unless there is something in the template
	# that causes trouble in the s/... expression.
	if ($content =~ s/\n\n/\n\n$insert\n/s) {
	    $n_inserted ++;
	} else {
	    print STDERR "** Insertion failed for input file '$infile'.\n";
	}
    }

    # Save a backup file

    `[ -f $infile$bak ] && rm $infile$bak`;
    `mv $infile $infile$bak`;

    # Output the modified file
    
    print_file($infile, $content);

    # Make it executable if the backup was

    `[ -x $infile$bak ] && chmod +x $infile`;

}

print STDERR "  $n_inserted inserted; $n_replaced replaced\n";

exit 0;

#########################################################################

### read_file($pathname)
#	Read a file into a string.  Return null if the file doesn't exist.
sub read_file {
    my ($fn) = (@_);
    my $s = '';
    if (open(IN, $fn)) {
	while (<IN>) { $s .= $_; }
	close IN;
    }

    return $s;
}

### print_file($pathname, $string) 
#	print a string into a file.  If the file was a symlink,
#	remove it to ensure that we don't clobber the original.
sub print_file {
    my ($fn, $s) = (@_);
    if (-l $fn) { unlink($fn); }
    if (open(OUT, ">$fn")) {
	print OUT $s;
	print OUT "\n" unless $s =~ /\n$/s;
	close OUT;
    }
}


#########################################################################
