#!/usr/bin/perl
# $Id: preorder.cgi,v 1.3 2007-12-19 17:38:19 steve Exp $
# preorder.cgi -- create an album preorder transaction file
#	<title>make a preorder data file</title>

use CGI;

### Make a preorder (so far) transaction file
#
#	form: http://mirror/Steve_Savitzky/preorder/local-form.html

#to.do:
#  o load transaction file for editing
#  o add itemID and paypal transactionID fields
#  o make entry from paypal email / CSV file / web-scrape
#    (the CSV file is probably the best start:  do the minimum:
#     just name, email, date, transID; fill in details later)
#    Can use Text::CSV_XS (from libtext-csv-perl) to parse the CSV file
#    ~/download/HSX/paypal-20070101-20070118-trimmed.csv
#   

if (@ARGV) {
    # invoked from the command line.  Bogus at the moment.
    exit 0;
}

### Setup -- should probably come from a configuration file

# URL components

$public_dir	= "/Steve_Savitzky/";
$public_site  	= "http://theStarport.com";
$publicURL	= "${public_site}${public_dir}preorder/";

$form_url	= "${public_dir}preorder/local-form.html";
$page_title	= "Preorder data";

# Where we put the data

$data_base	= "${public_dir}preorder/.cust-data";

# Parameter names in the order we want to see them.
#	= and == turn into <hr> in the table
#	anything after == is omitted from the data file
@param_names = ( 'basic-price', 'basic-quantity', 'basic-total',
		 'shipping-price', 'shipping-quantity', 'shipping-total',
		 'ca-addr', 'ca-tax', 
		 'total', 'payment-method',
		 'shipping-method', 'name', 
		 'address1', 'address2', 'city', 'state', 'zip', 'country',
		 'email',  'phone', 'message',
		 '=',
		 'notes',  'status', 'set-number', 'email-sent',
# debugging:	 '==', 'directory', 'filename',
		 'Action', 	# buttons
		);

# Parameter types:
#   $ = currency; 0 = integer (other integer: default value); t/f = boolean
#   s = string; S = long string; e = email T = text box; array = selection
#
#   Modifiers:  ! required; = computed

%param_types = ( 'basic-price' 		=> '$20', 
		 'basic-quantity' 	=> '0',
		 'basic-total' 		=> '$',
		 'shipping-price' 	=> '$5',
		 'shipping-quantity'	=> '0',
		 'shipping-total' 	=> '$',
		 'ca-addr' 		=> 'f',
		 'ca-tax' 		=> '$0', 
		 'total' 		=> '$!',
		 'payment-method'	=> ['cash', 'check', 'cod',
					    'comp', 'trade', 'paypal',
					    ],
		 'shipping-method'	=> ['mail', 'hand deliver',],
		 'name' 		=> 's!', 
		 'address1' 		=> 's',
		 'address2' 		=> 's',
		 'city' 		=> 's',
		 'state' 		=> 's',
		 'zip' 			=> 's', #actually postal code
		 'country' 		=> 's',
		 'email' 		=> 'e!',
		 'phone' 		=> 's',
		 'message' 		=> 'S',
		 'notes' 		=> 'S',
		 'status'		=> ['paid', 'abt-shipped',
					    'all-shipped',
					    ],
		 'email-sent'		=> 'f',
		 'set-number'		=> 's',	# hex
		 'directory' 		=> 's=',
		 'filename' 		=> 's=',
		 'Action'		=> ['Submit', 'Edit', 'Confirm',],
		);


### CGI setup:

my $q = new CGI;
my $this = @ENV{SCRIPT_NAME};
my $root = @ENV{DOCUMENT_ROOT};

my $this =~ m|^(.*/)([^/]+)|;
my $cgidir = $1;
my $cginame= $2;

$data_base = $root . $data_base;

### Current datestamp

my $date = `date +%y%m%dT%H%M`;
$date =~ s/[^0-9]*$//;

### Get CGI parameters

my %record = ();
my $action;
my $error = '';
my $error_count = 0;

for my $p (@param_names) {
    next if $p eq '=';
    my $v = $q->param($p);
    if ($p eq 'Action') {
	$action = $v;
    } else {
	$v =~ s/^\s*//;
	$v =~ s/\s*$//;
	$v =~ s/[\n\r\t]/ /g;
	$record{$p} = $v if $v;			# === $v .ne ""???
    }
}

# === really ought to snarf any parameters that aren't in param_names,
# === and also check to make sure that every name has a type.

# compute directory and filename for the record

my $directory = $record{'directory'};
if (!defined($directory) || $directory eq '') {
    $directory = $record{'email'};
    $record{'directory'} = $directory;
}
my $filename = $record{'filename'};
if ($filename eq '') {
    $filename = $date;
    $record{'filename'} = $filename;
}

my $data_dir  = "$data_base/$directory";
my $data_file = "$filename";


# build the form here to verify that there are no errors.

my $form_content = '';
for my $p (@param_names) {
    next if $p eq 'Action';
    if ($p =~ /\=/) {
	$form_content .= "<tr><td colspan='2'><hr /></td></tr>\n";
	next;
    }
    $form_content .= "<tr><th align='right'>$p</th>\n";
    my $t = $param_types{$p};
    $form_content .= "    <td>" . form_field($p, $record{$p}, $t);
    $form_content .= "<font color='red'>$error</font>\n" if $error ne '';
    $error_count++ if $error ne '';
    $form_content .= "</td>\n";
    $form_content .= "</tr>\n";
}

$action = 'Edit' if ($error_count > 0); 

if ($action eq 'Confirm') {
    $page_title .= " confirmation";
}

### Build the page
#

my $content = "<html>\n";
$content .= "  <head>\n";
$content .= ("    <title>$page_title</title>\n");
$content .= "  </head>\n";
$content .= "  <body>\n";
$content .= "<h2>$page_title</h2>\n";

# The actual data

if ($action ne 'Confirm') {
    $content .= "<form method='POST' action='$this'>\n";
}

$content .= "<table>\n";

if ($action eq 'Confirm') {
    for my $p (@param_names) {
	next if $p eq 'Action';
	last if $p eq '==';
	next if $p eq '=';
 	next unless $record{$p};
	$content .= "<tr><th align='right'>$p:</th>\n";
	$content .= "    <td>" . entity_encode($record{$p}) . "</td>\n";
	$content .= "</tr>\n";
    }
} else {
    $content .= $form_content;
}


$content .= "</table>\n";

if ($action eq 'Confirm') {			# write record
    umask(2);
    if (! -d $data_dir && !mkdir($data_dir, 0775)) {
	$content .= ("<font color='red'>" .
		     "<b>cannot open data directory $data_dir</b>" .
		     "</font>");
	$error_count++;
    } elsif (open(OUT, ">$data_dir/$data_file")) {
        for my $p (@param_names) {
	    next if $p eq 'Action';
	    next unless $record{$p};
	    print OUT "$p: " . $record{$p} . "\n";
	}
	close OUT;
	$content .= "<b>Wrote</b> $data_dir/$data_file</b><br />\n";
	$content .= "<a href='$form_url'>Enter another record</a><br />\n";
    } else {
	$content .= ("<font color='red'>" .
		     "<b>cannot write data file $data_dir/$data_file</b>" .
		     "</font>");
	$error_count++;
    }
} else {
    $content .= '<input type="submit" name="Action" value="Edit">' . "\n";
    if ($error_count == 0) {
	$content .= "<input type='submit' name='Action' value='Confirm'>\n";
    } else {
	$content .= 
	    "<font color='red'>You need to fix $error_count errors.</font>\n";
    }
    $content .= "</form>\n";
}

$content .= "<hr />\n";
$content .= "<b>data_base = </b>$data_base<br />\n";
$content .= "<b>directory = </b>$directory (customer ID)<br />\n";
$content .= "<b>filename = </b>$filename (transaction ID)<br />\n";
$content .= "<b>form_url = </b>$form_url<br />\n";
$content .= "<b>date = </b>$date<br />\n";

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


### name to field

sub form_field {
    my ($n, $v, $t) = @_;
    my $res = '';
    $error = '';
    if (ref($t)) {
	# have to put this first in case a regexp matches the ref
	$res = "<select>\n";
	for my $opt (@$t) {
	    $res .= "<option ";
	    $res .= "selected='selected' " if $opt eq $v;
	    $res .= ">$opt</option>\n";
	}
	$res .= "</select>\n";
    } elsif ($t =~ /[\$]/) {
	if ($v !~ /^[0-9.]*$/) { $error = "must be a dollar amount"; }
	$res = "\$<input name='$n' value='$v' />";
    } elsif ($t =~ /^[0-9]*[!]*$/) {
	if ($v !~ /^[0-9]*$/) { $error = "must be an integer"; }
	$res = "\&nbsp;\&nbsp;<input name='$n' value='$v' />";
    } elsif ($t =~ /[tf]/) {
	$res = ($t =~ /t/)
	    ? "<input name='$n' type='checkbox' checked='checked' />"
	    : "<input name='$n' type='checkbox' />";
	
    } elsif ($t =~ /e/) {
	if ($v ne '' && $v !~ /.\@./) {
	    $error = "must be email address";
	}
	$v = entity_encode($v);
	$res = "<input name='$n' value='$v' size='40' />";
    } elsif ($t =~ /s/) {
	$v = entity_encode($v);
	$res = "<input name='$n' value='$v' size='40' />";
    } elsif ($t =~ /S/) {
	$v = entity_encode($v);
	$res = "<input name='$n' value='$v' size='100' />";
    } else {
	$v = entity_encode($v);
	$res = "<input name='$n' value='$v' size='40' /> ?";
    }
    if (!ref($t) && $t =~ /\!/ && $v eq '') {
	$error = "required";
    }
    return $res;
}


# entity encode (protect) a string
sub entity_encode {
    my ($s) = @_;
    $s =~ s/\&/&amp;/gs;
    $s =~ s/\>/&gt;/gs;
    $s =~ s/\</&lt;/gs;
    return $s;
}


1;
