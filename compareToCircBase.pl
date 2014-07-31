# File: compareToCircBase.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# This is written to compare our findings to the circBase database of
# circular RNA. The input format for the circBase information is the
# same as the spreadsheet downloadable from the circBase website.
#
# Both databases entered must have, as the first three values in each
# line:
# chrN   1000   500
#
# both should have a header line.

use strict;
use warnings;
use Getopt::Long;

my($CIRCBASE_DB, $FOUND_DB, $CIRC_ONLY_OUT, $FOUND_ONLY_OUT, $help);
GetOptions('circbase-db=s' => \$CIRCBASE_DB,
	   'found-db=s' => \$FOUND_DB,
	   'circ-only-out=s' => \$CIRC_ONLY_OUT,
	   'found-only-out=s' => \$FOUND_ONLY_OUT,
	   'help|?' => \$help);

&usage if $help;
&usage unless $CIRCBASE_DB && $FOUND_DB && $CIRC_ONLY_OUT && $FOUND_ONLY_OUT;




my %foundLines = ();
my $foundHeader;

# Load everything from database of found into a hash
open my $found_fh, '<', $FOUND_DB or die "Could not open $FOUND_DB\n";
while(my $line = <$found_fh>) {
    chomp($line);
    if($. == 1) {
	$foundHeader = $line;
	next;
    }
    
    my $key = &makeKey($line);
    my $val = &makeValue($line);
    $foundLines{ $key } = $val;
}
close $found_fh;

open my $circout_fh, '>', $CIRC_ONLY_OUT or die "Cound not open/create $CIRC_ONLY_OUT\n";
open my $circbase_fh, '<', $CIRCBASE_DB or die "Could not open $CIRCBASE_DB\n";
while(my $line = <$circbase_fh>) {
    chomp($line);
    if($. == 1) {
	my $foundHeaderLineEnd = &makeValue($foundHeader);
	print "$line$foundHeaderLineEnd\n";
	print $circout_fh "$line\n";
	next;
    }

    my $foundLineEnd = $foundLines{ &makeKey($line) };
    if($foundLineEnd) {
	print "$line$foundLineEnd\n";
	delete $foundLines{ &makeKey($line) };
    } else {
	print $circout_fh "$line\n"
    }
    
}
close $circbase_fh;
close $circout_fh;

# Print remaining found elements
open my $foundout_fh, '>', $FOUND_ONLY_OUT or die "Cound not open/create $FOUND_ONLY_OUT\n";
print $foundout_fh "$foundHeader\n";
foreach my $key (keys %foundLines) {
    my $val = $foundLines{$key};
    print $foundout_fh "$key$val\n";
}
close $foundout_fh;


# Takes in a (chomped) full line. Uses the first three values to
# create a key for the hash. Does NOT include a final tab.
sub makeKey {
    my @vals = split("\t", $_[0]);
    return "$vals[0]\t$vals[1]\t$vals[2]";
}



# Takes in a (chomped) full line. Uses all but the first three
# values to create a value for the hash. DOES include
# leading tab.
sub makeValue {
    my @vals = split("\t", $_[0]);
    my $value = "";
    for(my $i = 3; $i <= $#vals; $i++) {
	$value .= "\t$vals[$i]";
    }
    return $value;
}



sub usage {
    die "
 Necessary flags:
 --circbase-db 
      Database downloaded from CircBase
 --found-db
      Database generated by makeGenomeLocSheet
 --circ-only-out
      Name of output for only circular
 --found-only-out
      Name of output for only found

"}
