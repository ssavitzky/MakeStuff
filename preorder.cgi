#!/usr/bin/perl
# $Id: preorder.cgi,v 1.1 2007-02-24 18:43:53 steve Exp $
# preorder.cgi -- create an album preorder transaction file
#	<title>make a preorder data file</title>

use CGI;

### Make a preorder (so far) transaction file

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

# URL components

$publicDir   = "/Steve_Savitzky/";
$publicSite  = "http://theStarport.com";
$publicURL   = "${publicSite}${publicDir}preorder/";

### Parameters:

# Parameter names in the order we want to see them.

@param_names = ( 'basic-price', 'basic-quantity', 'basic-total',
		 'shipping-price', 'shipping-quantity', 'shipping-total',
		 'ca-addr', 'ca-tax', 
		 'total', 'payment-method',
		 'shipping-method', 'name', 
		 'address1', 'address2', 'city', 'state', 'zip', 'country',
		 'email',  'phone', 'message',
		 'notes',  'status', 'set-number', 'email-sent',

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
		 'payment-method'	=> ['cash', 'check', 'deferred',
					    'comp', 'paypal',
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
		 'set-number'		=> '0',
		 'Action'		=> ['Submit', 'Edit', 'Confirm',],
		 'directory' 		=> 's=',
		 'filename' 		=> 's=',
		);


### Get CGI parameters

my %record = ();
my $action;
my $error = '';
my $error_count = 0;

for my $p (@param_names) {
    my $v = $q->param($p);
    if ($p eq 'Action') {
	$action = $v;
    } else {
	$record{$p} = $v if $v;
    }
}

# compute directory and filename for the record

### Build the page
#

my $content = "<html>\n";
$content .= "  <head>\n";
$content .= ("    <title>preorder record</title>\n");
$content .= "  </head>\n";
$content .= "  <body>\n";
$content .= "<h2>preorder record</h2>\n";

# The actual data

if ($action ne 'Confirm') {
    $content .= "<form method='POST' action='$this'>\n";
}

$content .= "<table>\n";

if ($action eq 'Confirm') {
    for my $p (@param_names) {
	next unless $record{$p};
	$content .= "<tr><th align='right'>$p</th>\n";
	$content .= "    <td>" . $record{$p} . "</td>\n";
	$content .= "</tr>\n";
    }
} else {
    for my $p (@param_names) {
	next if $p eq 'Action';
	$content .= "<tr><th align='right'>$p</th>\n";
	my $t = $param_types{$p};
	$content .= "    <td>" . form_field($p, $record{$p}, $t);
	$content .= "<font color='red'>$error</font>\n" if $error ne '';
	$error_count++ if $error ne '';
	$content .= "</td>\n";
	$content .= "</tr>\n";
    }
}


$content .= "</table>\n";

$action = 'Edit' if ($error_count > 0); 
if ($action eq 'Confirm') {
    # write record
} else {
    $content .= '<input type="submit" name="Action" value="Edit">' . "\n";
    if ($error_count == 0) {
	$content .= "<input type='submit' name='Action' value='Confirm'>\n";
    } else {
	$content .= 
	    "<font color='red'>You need to fix $error_count errors</font?>\n";
    }
    $content .= "</form>\n";
}


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
	$v = entityEncode($v);
	$res = "<input name='$n' value='$v' size='40' />";
    } elsif ($t =~ /s/) {
	$v = entityEncode($v);
	$res = "<input name='$n' value='$v' size='40' />";
    } elsif ($t =~ /S/) {
	$v = entityEncode($v);
	$res = "<input name='$n' value='$v' size='100' />";
    } else {
	$v = entityEncode($v);
	$res = "<input name='$n' value='$v' size='40' /> ?";
    }
    if (!ref($t) && $t =~ /\!/ && $v eq '') {
	$error = "required";
    }
    return $res;
}


# entity encode (protect) a string
sub entityEncode {
    my ($s) = @_;
    $s =~ s/\&/&amp;/gs;
    $s =~ s/\>/&gt;/gs;
    $s =~ s/\</&lt;/gs;
    return $s;
}


1;
