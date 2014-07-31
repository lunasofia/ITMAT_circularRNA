# File: makeFrequencyHistogram
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ---------------------------------
# Couldn't think of a better name.
# Creates a histogram of # of matches (calculated by summing
# across rows of the spreadsheet) to how many genes have that
# number of matches/events.

use strict;
use warnings;

# To keep track of the matches
my %hist;


while(<>) {
    chomp($_);
    my @vals = split(" ", $_);
    next if $vals[0] eq "-";
    
    my $sum = 0;
    for(my $i = 1; $i <= $#vals; $i++) {
	$sum += $vals[$i];
    }

    $hist{ $sum } = 0 unless $hist{ $sum };
    $hist{ $sum }++;
}

print "cov\tevents";
foreach my $key (sort {$a <=> $b} keys %hist) {
    print "\n$key\t$hist{$key}";
}
