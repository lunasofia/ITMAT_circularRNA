# File: backwardsPairExons.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------------
# This program takes in a list of exons and, within
# each gene, finds all out-of-order pairings of exons
# and prints out the resulting sequence. The input is
# fasta, with information line as shown below:
#
# Input format:
# >GENEA.1 exon 1 chr1 134212701 134213049
# GCGGGGCTTTCTAGCGTGCTCGGG
# >GENEA.1 exon 2 chr1 134221529 134221650
# GTGGCCATCAAGTCCATCAGGAAAGACAAAATCAAAGATGAGCAGGATCTGC
#
# The gene name can not have any dashes.
#
# Output format:
# >GENEA.1-2-1
# GTGGCCATCAAGTCCATCAGGAAAGACAAAATCAAAGATGAGCAGGATCTGCGCGGGGCTTTCTAGCGTGCTCGGG

use strict;

# Indices of the various information in the array of
# exons for a particular gene.
my $GENE_NAME = 0;
my $EXON = 1;
my $EXON_NUM = 2;
my $CHR = 3;
my $EXON_START = 4;
my $EXON_END = 5;
my $SEQ = 6;

# Indices of various information in the array of a
# junction (the value in the hash). $ORD keeps track
# of the order entered, so that the output can be
# printed in order.
my $ORD = 0;
my $LENGTH = 1;
my $PRINT_INFO = 2;
my $CONCAT_SEQ = 3;

# The name of the current gene. Starts with ">".
my $curGeneName;

# The exons (in order) of the current gene, populated
# as the file is parsed. 
my @exonList;

# Hash to keep track of all matched pairs
my %pairs = ();

# Keeps track of how many have been processed, so that
# everything can be kept in order.
my $order = 0;

while (my $nameline = <>) {
    # Read in sequence line.
    my $dataline = <> or die "Error: bad file format\n";

    chomp($dataline);
    chomp($nameline);
    
    my @namelineVals = split(" ", $nameline);

    if($curGeneName ne $namelineVals[$GENE_NAME]) {
	&processGene;
	&clearExonList;
	$curGeneName = $namelineVals[$GENE_NAME];
    }

    push @exonList, [ (@namelineVals, $dataline) ];
}
&processGene;
&clearExonList;

&printAll;


# processes the exons of a single gene, re-arranging in all
# necessary ways and printing out the results.
sub processGene {
    for(my $first = 0; $first <= $#exonList; $first++) {
	for(my $second = 0; $second <= $first; $second++) {
	    my $key = &makeKeyString($first, $second);
	    
	    # check if already a longer pairing at this junction
	    my $oldVal = $pairs{ $key };
	    if($oldVal ne 0) {
		my $oldLen = $oldVal->[$LENGTH];
		my $newLen = &getLength($first, $second);
		if($oldLen >= $newLen) { next; }
	    }

	    $pairs{ $key } = &makeValueArray($first, $second);
	}
    }
}

# Takes in indices into the exon array for two exons and
# returns the key for their junction. The key is in the
# form: 
# chr1.100:20
sub makeKeyString {
    return "$exonList[$_[0]]->[$CHR]" . "-" 
	. "$exonList[$_[0]]->[$EXON_END]" . "-" 
	. "$exonList[$_[1]]->[$EXON_START]";
}


# Takes in indices into the exon array for two exons and builds
# the value array for their junction. Returns a reference to
# the array. Also increments the order counter so that each value
# array will have a unique order integer.
sub makeValueArray {
    my @array;

    push @array, $order;
    push @array, &getLength($_[0], $_[1]);
    push @array, &makeNameDataString($_[0], $_[1]);
    push @array, &makeSequenceString($_[0], $_[1]);

    $order++;
    return \@array;
}

# Takes in indices into the exon array for two exons and
# returns the combined lengths of the exons
sub getLength {
    my $len1 = $exonList[$_[0]]->[$EXON_END] - $exonList[$_[0]]->[$EXON_START];
    my $len2 = $exonList[$_[0]]->[$EXON_END] - $exonList[$_[0]]->[$EXON_START];

    return $len1 + $len2;
}

# Takes in the indices into the exon array of two exons and
# returns the info about the pair (to be used as a header for
# the sequence information).
sub makeNameDataString {
    my $nameString = "$exonList[$_[0]]->[$GENE_NAME]-";
    $nameString .= "$exonList[$_[0]]->[$EXON_NUM]-";
    $nameString .= "$exonList[$_[1]]->[$EXON_NUM]";
    return $nameString;
}

sub makeSequenceString {
    return $exonList[$_[0]]->[$SEQ] . $exonList[$_[1]]->[$SEQ];
}

# Clears out the list of exons after a gene has been processed
sub clearExonList {
    undef @exonList;
}

# Prints out all pairs in the hash. TODO: make this iterate in order
sub printAll {
    foreach my $val (sort {$a->[$ORD] <=> $b->[$ORD]} values %pairs) {
	printEntry($val);
    }
}

# Takes in a reference to a value array and prints out that junction
sub printEntry {
    print $_[0]->[$PRINT_INFO];
    print "\n";
    print $_[0]->[$CONCAT_SEQ];
    print "\n";
}
