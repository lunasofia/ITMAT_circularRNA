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
use Getopt::Long;

my $USAGE = "Usage:\n perl samToSpreadsheetCol --sam-filename=\"filename.sam\" ";
my $USAGE = $USAGE . "[--column-titles=col1]\n";
my $help;

my $SAM_FILE;
my $COL_NAME;

GetOptions('help|?' => \$help,
	   'sam-filename=s' => \$SAM_FILE,
	   'column-titles=s' =>\$COL_NAME);
die "$USAGE" if $help;
die "$USAGE" unless $SAM_FILE;
$COL_NAME = $SAM_FILE unless $COL_NAME;

# Index of reference sequence name in SAM format
my $S_RNAME = 2;

# Hash to keep track of frequencies of the reference
# sequences. Key is name of sequence, value is how
# many times that name has been seen.
my %hist = ();

open my $sam_fh, '<', $SAM_FILE or die "\nError: could not open sam file.\n";
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
