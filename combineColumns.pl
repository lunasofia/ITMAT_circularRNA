# File: combineColumns.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ---------------------------------
# Takes in two spreadsheet files and combines them into
# a single file.
# The files should have a header row with a "-" to start
# and then a tab-delimited list of column names.

use strict;

my @fh;
my @curLines;
my @ncols;
for(my $i = 0; $i < 2; $i++) {
    open $fh[$i], '<', $ARGV[$i];
    $curLines[$i] = <$fh[$i]>;
    my @header_vals = split("\t", $curLines[$i]);
    
    # index of the final entry is one less than total
    # number of entries, which is number of columns
    # with values
    $ncols[$i] = $#header_vals;
}

while($curLines[0] || $curLines[1]) {
    # If one file is done, increment the
    # other file.
    if(!$curLines[0]) {
	&printLines(0, 1);
	next;
    }

    if(!$curLines[1]) {
	&printLines(1, 0);
	next;
    }

    if
}

sub printLines {
    my @lineVals;
    my $rowName;
    for(my $i = 0; $i < 2; $i++) {
	if($_[$i]) {
	    $lineVals[$i] = \split("\t", $curLines[$i]);
	    $rowName = $lineVals[$i]->[0];
	    &nextLine($i);
	} else {
	    my @zeroArr = (0) x ($ncols[$i] + 1);
	    $lineVals[$i] = \@zeroArr;
	}
    }

    print "$rowName";
    for(my $i = 0; $i < 2; $i++) {
	for(my $col = 1; $col <= $ncols[$i]; $i++) {
	    print "\tlineVals[$i]->[$col]";
	}
    }
    print "\n";
}


# Takes in either 0 or 1 and reads in the next line for that
# file.
sub nextLine {
    $curLines[$_[0]] = <$fh[$_[0]]>;
}
