# File: fillInTissueTypeInfo.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -----------
# Quick script to add the information from EunJi's tissue type file
# to the file of column sums & ribo vs poly data.

use strict;
use warnings;

my ($TISSUE_FILE, $DUP_FILE, $SPREADSHEET) = @ARGV;


# read in tissue information
my %IDtoInfo = ();

open my $tissue_fh, '<', $TISSUE_FILE or die "could not open $TISSUE_FILE\n";
while(my $line = <$tissue_fh>) {
    chomp($line);
    my @vals = split("\t", $line);

    $IDtoInfo{ $vals[0] } = \@vals;
}
close $tissue_fh;

# Load primary ID information
my %idToPrimary = ();

open my $dup_fh, '<', $DUP_FILE or die "could not open $DUP_FILE\n";
while(my $line = <$dup_fh>) {
    chomp($line);
    my @ids = split("\t", $line);

    my $primary = substr $ids[0], 0, -1;
    for (my $i = 1; $i <= $#ids; $i++) {
        $idToPrimary{ $ids[$i] } = $primary;
    }
}
close $dup_fh;

# Go through file and fill in info
open my $spreadsheet_fh, '<', $SPREADSHEET or die "could not open $SPREADSHEET\n";
while(my $line = <$spreadsheet_fh>) {
    chomp($line);
    my @vals = split("\t", $line);

    if($. == 1) {
	print join("\t", @vals), "\n";
	next;
    }

    # in case column not filled in yet
    if ($#vals == 2) {
	push(@vals, "*");
    }

    # make sure to get rid of _1
    my $id = $vals[0];
    $id = substr($id, 0, -2) if ($id =~ /_1$/);
    my $primaryID = $idToPrimary{ $id };

    my $infoRef = $IDtoInfo{ $id };
    $infoRef = $IDtoInfo{ $primaryID } if $primaryID;

    if($infoRef) {
	# look at each column with procedure info, fill in unless
	# that column has a '-'.
	my @methods;

	my @info = @$infoRef;

	for(my $i = 2; $i <= $#info; $i++) {
	    push @methods, $info[$i] unless ($info[$i] eq '-' || $info[$i] eq '');
	}

	# write in as method if anything was found
	$vals[3] = join(",", @methods) if $methods[0];
    }

    print join("\t", @vals), "\n";
    
}
close $spreadsheet_fh;
