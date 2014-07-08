# File: combineColumns.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ---------------------------------
# Takes in a series of filenames, each containing
# a single data column. The first line of each file
# is in the format:
# -        colName
#
# Then the rest of the lines in the file are in the
# format:
# GENE1    12

use strict;

# Index of the current column being written.
# Incremented by 1 every time first line of
# a file is read in. Starts at -1 so that the
# first line of the first file will push it
# to 0.
my $curDataArrIndex = -1;

# Number of files inputted is number of columns
my $nDataCols = $#ARGV + 1;

# Key is gene name. Values are references to
# arrays of length nDataCols.
my %geneToData = ();

while(<>) {
    chomp($_);
    my @lineVals = split("\t", $_);

    # In case this is the first line of a file
    if($lineVals[0] eq "-") {
	$curDataArrIndex++;
    }

    # In case this ID is not yet in the hash
    if(!$geneToData{ $lineVals[0] }) {
	my @dataArr = (0) x $nDataCols;
	$dataArr[$curDataArrIndex] = $lineVals[1];
	$geneToData{ $lineVals[0] } = \@dataArr;
    } else {
	$geneToData{ $lineVals[0] }->[$curDataArrIndex] = $lineVals[1];
    }
}

my $headerArrRef = delete $geneToData{ "-" };
print "-";
&printDataVector($headerArrRef);

foreach my $key (keys %geneToData) {
    print "$key";
    printDataVector($geneToData{ $key });
}


# Takes in a reference to a data vector and prints out the
# contents. Starts with a tab (so previous print should not
# include a tab).
sub printDataVector {
    for(my $i = 0; $i < $nDataCols; $i++) {
	print "\t$_[0]->[$i]";
    }
    print "\n";
}
