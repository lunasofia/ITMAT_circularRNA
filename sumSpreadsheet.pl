# File: sumSpreadsheet.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# Sums the columns of a spreadsheet and prints out those
# sums as the data in a new tab-separated spreadsheet, with
# the old column titles as rows.

use strict;
use warnings;

my @names;
my @sums;

while(my $line = <>) {
    chomp($line);
    my @lineVals = split("\t", $line);
    
    if ($lineVals[0] eq '-') {
	@names = @lineVals[1..$#lineVals];
	@sums = 0 x $#lineVals;
	next;
    }

    for(my $i = 0; $i <= $#sums; $i++) {
	$sums[$i] += $lineVals[$i + 1];
    }
}

print "name\tsum";
for(my $i = 0; $i <= $#names; $i++) {
    print "\n$names[$i]\t$sums[$i]";
}
