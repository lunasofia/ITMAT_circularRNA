# File: backwardsPairExons.pl
# Author: S. Luna Frank-Fischer
# ITMAT
# ----------------------------------------------
# This program takes in a list of exons and, within
# each gene, finds all out-of-order pairings of exons
# and prints out the resulting sequence.
#
# Input format:
# >NM_028778 exon 1 chr1 134212701 134213049
# GCGGGGCTTTCTAGCGTGCTCGGG
# >NM_028778 exon 2 chr1 134221529 134221650
# GTGGCCATCAAGTCCATCAGGAAAGACAAAATCAAAGATGAGCAGGATCTGC
#
# Output format:
# >NM_028778 exon 2 chr1 134221529 134221650 exon 1 chr1 134212701 134213049
# GTGGCCATCAAGTCCATCAGGAAAGACAAAATCAAAGATGAGCAGGATCTGCGCGGGGCTTTCTAGCGTGCTCGGG

use strict;

# Indices of the various information
my $GENE_NAME = 0;
my $EXON = 1;
my $EXON_NUM = 2;
my $CHR = 3;
my $EXON_START = 4;
my $EXON_END = 5;
my $EXON_DATA = 6;

# The name of the current gene. Starts with ">".
my $curGeneName;

# The exons (in order) of the current gene, populated
# as the file is parsed.
my @exonList;

# Hash to keep track of the pair locations already matched
my %pairSet = ();


while (my $nameline = <>) {
    my $dataline;
    if (!($dataline = <>)) {
	   #this would really be some kind of error...
	   last;
    }
    chomp($dataline);
    chomp($nameline);

    my @namelinevals = split(" ", $nameline);

    if($curGeneName ne $namelinevals[$GENE_NAME]) {
	&processGene;
	&clearExonList;
	$curGeneName = $namelinevals[$GENE_NAME];
    }

    push @exonList, [ (@namelinevals, $dataline) ];
}
&processGene;
&clearExonList;


# processes the exons of a single gene, re-arranging in all
# necessary ways and printing out the results.
sub processGene {
    for(my $first = 0; $first <= $#exonList; $first++) {
	for(my $second = 0; $second <= $first; $second++) {
	    if(&addToAlreadyPaired($first, $second)) {
		&printPair($first, $second);
	    }
	}
    }
}

# Adds the given pair to the list of pairs already matched.
# (Pair is given by indexing into the exonList array.)
# Returns true if the addition was successful, false if the pair
# was already in the list. Takes in two array references.
sub addToAlreadyPaired {
    my $key = &makeLocDataString($_[0]) . &makeLocDataString($_[1]);

    my $alreadyPaired = $pairSet{ $key };

    $pairSet{ $key } = 1;
    return 1 - $alreadyPaired; # 0 if already there
}

# Takes in indices into the exon array of a single exon. Prints
# out a string to be the key to the exon pair map. String is in the form
# chr1 134212701 134213049
sub makeLocDataString {
    my $string;

    for(my $i = $CHR; $i <= $EXON_END; $i++) {
	$string .= $exonList[$_[0]]->[$i];
	$string .= " ";
    }

    return $string;
}

# Takes in the indices into the exon array of two exons (in order) and
# prints out the information about that pair and the combined data.
sub printPair {
	    print "$curGeneName ";
	    &printNameData($_[0]);
	    &printNameData($_[1]);
	    print "\n";
	    print "$exonList[$_[0]]->[$EXON_DATA]";
	    print "$exonList[$_[1]]->[$EXON_DATA]\n";

}

# Takes in the index into the exon array of an exon and prints out
# information about that exon.
sub printNameData {
    for(my $i = $EXON; $i <= $EXON_END; $i++) {
	print "$exonList[$_[0]]->[$i] ";
    }
}

# Clears out the list of exons after a gene has been processed
sub clearExonList {
    undef @exonList;
}
