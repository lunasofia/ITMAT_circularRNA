# File: getMitochondrialIDs.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------
# This is a script to pull the IDs of reads that matched mitochondrial RNA.
# Takes in the SAM file.

use strict;
use warnings;

my $S_RNAME = 2;

while(<>) {
    next if $_ =~ /^\@/;
    chomp($_);
    my @vals = split("\t", $_);

    next unless $vals[$S_RNAME] eq 'chrM';

    print "$vals[0]\n";
}
