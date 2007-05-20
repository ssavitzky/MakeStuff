#!/usr/bin/perl
#	$Id: replace-template-file.pl,v 1.3 2007-05-20 17:44:27 steve Exp $
#
#<title>replace-template-file</title>
#	This script is used to replace part of a file -- usually HTML --
#	with the contents of a template.  The first and last lines
#	of the template file are matched, and everything between the first
#	match of the first line to the first match of the last line is
#	replaced by the contents of the template.  Usually the template
#	is an HTML <div> element with a distinctive id or class attribute.

### Open Source/Free Software license notice:
 # The contents of this file may be used under the terms of the GNU
 # General Public License Version 2 or later (the "GPL").  The text
 # of this license can be found on this software's distribution media,
 # or obtained from  www.gnu.org/copyleft/gpl.html	
###						    :end license notice	###

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


while (<IN>) {
    $template_text .= $_;
    $template_last = $_;
    if ($template_first eq "") { $template_first = $_; }
}
close IN;

### If no input files, just print the analysis of the template.

if (! @ARGV) {
    print "No target files specified; just analyzing the template:\n";
    print $template_first;
    print "...\n";
    print $template_last;
    exit 0;
}

### Loop through the input files.

my $n_replaced = 0;
my $n_failed = 0;

while (@ARGV) {
    my $infile = $ARGV[0]; shift @ARGV;

    # Skip directories and backup files

    next if (-d $infile);
    next if ($infile =~ /\~$/);

    # Read the input file (only once)
    my $content = read_file($infile);
    if ($content eq "") {
	print STDERR "*** Input file '$infile' missing or empty: skipping\n";
	next;
    }

    # skip files that already have the most recent template inserted.
    #	Note that the way we do the substitution is exceedingly crude; 
    #	in particular, it matches to the last instance of the last line,
    #   instead of the first, so it had better be unique.

    # === this needs to be fixed!! ===

    my $insert = $template_text;
    my $first  = $template_first;
    my $last   = $template_last;

    $first = quotemeta($first);
    $last  =~ s/\n//s;				# take the \n off $last...
						# it interacts w\ quotemeta
    $last  = quotemeta($last);
    my $inserted = quotemeta($insert);

    $last .= "\n";				# ...put the \n back

    if ($content =~ /$inserted/s) {
	print STDERR "-- Input file '$infile' is up to date: skipping.\n"
	    if $verbose;
	next;
    } elsif ($content =~ /$first.*$last/s) {
	# === This will do horrible things to a file that contains 
	# more than one line that matches $last!!
	# Really ought to cycle through the lines and do it carefully.
	$content =~ s/$first.*$last/$insert/s;
	$n_replaced ++;
    } else {
	print STDERR "** Nothing to replace in input file '$infile'.\n";
	$n_failed ++
    }

    # Save a backup file

    `[ -f $infile$bak ] && rm $infile$bak`;
    `mv $infile $infile$bak`;

    # Output the modified file
    
    print_file($infile, $content);

    # Make it executable if the backup was

    `[ -x $infile$bak ] && chmod +x $infile`;
}

print STDERR "  $n_replaced replaced; $n_failed failed\n";

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
