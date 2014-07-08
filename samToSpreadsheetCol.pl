# File: samToSpreadsheetCol.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -----------------------------------------
# Takes in a SAM file and outputs a histogram of
# how many matches there are for a particular
# template.
# 
# Output file is always sorted alphabetically by
# the name of the reference seq (except the header
# line, which always is first)
#
# First line of output file is:
# - COL_NAME
# where COL_NAME is the second input to the program.

use strict;

my $SAM_FILE = $ARGV[0];
my $COL_NAME = $ARGV[1];

# Index of reference sequence name in SAM format
my $S_RNAME = 2;

# Hash to keep track of frequencies of the reference
# sequences. Key is name of sequence, value is how
# many times that name has been seen.
my %hist = ();

open my $sam_fh, '<', $SAM_FILE;
while(my $line = <$sam_fh>) {
   chomp($line);
   if($line =~ /^@/) { next; }
   
   my @fieldVals = split(" ", $line);
   my $rname = $fieldVals[$S_RNAME];

   if(!$hist{ $rname }) {
       $hist{ $rname } = 0;
   }

   $hist{ $rname }++;
}
close $sam_fh;

print "-\t$COL_NAME\n";

foreach my $rname (sort keys %hist) {
    print "$rname\t$hist{$rname}\n";
}
