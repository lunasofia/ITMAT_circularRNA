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
    
}

