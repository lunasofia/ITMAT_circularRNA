# File: samToSpreadsheetCol.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -----------------------------------------
# Takes in a SAM file and outputs a histogram of
# how many matches there are for a particular
# template.
#
# First line of output file is:
# - COL_NAME
# where COL_NAME is the second input to the program.

use strict;
use warnings;
use Getopt::Long;

my $help;
my $SAM_FILE;
my $COL_NAME;

GetOptions('help|?' => \$help,
	   'sam-filename=s' => \$SAM_FILE,
	   'column-title=s' =>\$COL_NAME);
&usage if $help;
&usage unless $SAM_FILE;
$COL_NAME = $SAM_FILE unless $COL_NAME;


# Hash to keep track of frequencies of the reference
# sequences. Key is name of sequence, value is how
# many times that name has been seen.
my %hist = ();


# Index of reference sequence name in SAM format
my $S_RNAME = 2;

open my $sam_fh, '<', $SAM_FILE or die "\nError: could not open sam file.\n";
while(my $line = <$sam_fh>) {
   chomp($line);
   if($line =~ /^@/) { next; }
   
   my @fieldVals = split(" ", $line);
   my $rname = $fieldVals[$S_RNAME];

   # initialize value if not yet in hash
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

sub usage {
die "
 Takes in a SAM file and outputs a histogram of
 how many matches there are for a particular
 template.

 Usage: perl samToSpreadsheetCol --sam-filename=\"filename.sam\" [--column-title=col1]

";
}
