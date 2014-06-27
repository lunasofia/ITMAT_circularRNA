# File: exonExonCrossingCounter.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------------------
# This program takes in the SAM file list of matches
# for a scrambled exon database. Each gene name must be 
# in the format:
# FORMAT HERE. WHAT IS THE FORMAT?
# Counts the number of crossings for each scrambled pair.
#
# Takes in two files. The first is the list of exons for
# each gene, which is used to gather information about
# the lengths of the exons. The second is the SAM file
# of matches.

use strict;

my ($EXONS_FILE, $SAM_FILE) = @ARGV;

# Hash to keep track of exon lengths.
# Key format is gene_name exon_num
# GENE1 4
my %exonLengths = ();

&getExonLengths;






# reads through the first input file and populates 
# the hash of exon lengths. 
sub getExonLengths {
    # Indices of various info in name line values
    my $GENE_NAME = 0;
    my $EXON_NUM = 2;
    my $EXON_START = 4;
    my $EXON_END = 5;

    open my $exons_fh, '<', $EXONS_FILE;
    while(my $nameline = <$exons_fh>) {
	my $dataline = <$exons_fh>;
	chomp($nameline);
	
	my @namelinevals = split(" ", $nameline);
	
	my $key = makeExonLenKey($namelinevals[$GENE_NAME], $namelinevals[$EXON_NUM]);
	my $value = $namelinevals[$EXON_END] - $namelinevals[$EXON_START];
	
	$exonLengths{ $key } = $value;
    }
    close $exons_fh;

    # TEST: printing
    foreach my $key (keys %exonLengths) {
	my $val = $exonLengths{ $key };
	print "$key: $val\n";
    }
}

# Given a gene name and exon number, returns the map
# key associated with that exon.
# Keys are of the form gene_name exon_num
# GENE1 4
sub makeExonLenKey {
    return "$_[0] $_[1]";
}
