# File: sortBySum.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------
# Given a tab-separated spreadsheet (in the format 
# created by combineColumns.pl), prints out the
# same spreadsheet with entries sorted in order of
# the sum of the columns (with highest first).
# Takes in a set of columns to sum and sort by.

use strict;
use warnings;
use Getopt::Long;
my ($help, @COLS_TO_SUM, $SPREADSHEET);
GetOptions('help|?' => \$help,
	   'column-to-sum=i' => \@COLS_TO_SUM,
	   'spreadsheet=s' => \$SPREADSHEET);

&usage if $help;
&usage unless ($COLS_TO_SUM[0] && $SPREADSHEET);

sub usage {
    die "
 Given a tab-separated spreadsheet (in the format
 created by combineColumns.pl), prints out the
 same spreadsheet with entries sorted in order of
 the sum of the columns specified. Leaves the first
 line alone.

 Necessary flags:
 --column-to-sum (-c)
 --spreadsheet (-s)

 USAGE: perl sortBySum.pl -c 2 -c 3 -c 4 -c 8 -s filename.txt
   
"}

# Hash from line to sum of the frequencies for that
# line
my %lines;

while(my $line = <>) {
    chomp($line);
    my @vals = split(" ", $line);
    
    # If this is the first line
    if($. == 1) {
	print $line;
	next;
    }

    my $sum = 0;
    foreach my $i (@COLS_TO_SUM) {
	$sum += $vals[$i];
    }
    
    $lines{ $line } = $sum;
}

foreach my $line (sort { $lines{$b} <=> $lines{$a} } keys %lines) {
    print "\n$line";
}
