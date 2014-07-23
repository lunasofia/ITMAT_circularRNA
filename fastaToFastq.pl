# File: fastaToFastq.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------------
# Converts a fasta file to a fastq file. Leaves
# blank lines instead of a quality rating.

use strict;
use warnings;

while(my $nameLine = <>) {
    my $sequence = <>;
    chomp($nameLine);
    chomp($sequence);
    my $name = substr $nameLine, 1;
    
    print "\n" unless $. == 1; # avoid \n fencepost problem
    print "\@$name";
    print "\n$sequence";
    print "\n+";
    print "\n"; # no quality information, so empty line
}
