# File: sortBySum.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------
# Given a tab-separated spreadsheet (in the format 
# created by combineColumns.pl), prints out the
# same spreadsheet with entries sorted in order of
# the sum of the columns (with highest first).

use strict;
use warnings;

# Hash from line to sum of the frequencies for that
# line
my %lines;

while(my $line = <>) {
    chomp($line);
    my @vals = split(" ", $line);
    
    # If this is the first line
    if($vals[0] eq "-") {
	print $line;
	next;
    }

    my $sum = 0;
    for(my $i = 1; $i <= $#vals; $i++) {
	$sum += $vals[$i];
    }
    
    $lines{ $line } = $sum;
}

foreach my $line (sort { $lines{$a} <=> $lines{$b} } keys %lines) {
    print "\n$line";
}
