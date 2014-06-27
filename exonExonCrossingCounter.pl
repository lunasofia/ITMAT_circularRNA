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

my $QNAME = 0;
my $RNAME = 2;
my $POS = 3;
my $CIGAR = 5;
my $SEQ = 9;
my $MIN_OVERLAP = 10;
open my $sam_fh, '<', $SAM_FILE;
while(my $line = <$sam_fh>) {
    if($line =~ /^@/) { 
	print "skipped header\n";
	next;
    }
    chomp($line);

    my @fieldVals = split(" ", $line);

    my @nameArr = split(/\./, $fieldVals[$RNAME]);
    if($#nameArr != 2) {
#	print "invalid name field ($fieldVals[$RNAME])\n";
	next;
    }

    my $key = &makeExonLenKey(">$nameArr[0]", $nameArr[1]);
    my $firstExonLen = 
	$exonLengths{ $key };
    if(!$firstExonLen) { 
#	print "no matching exon in length database ($fieldVals[$RNAME])\n";
	next; 
    }
    
    my $refAlignLength = getRefAlignLength($fieldVals[$CIGAR]);

    my $firstExOverlap = $firstExonLen - $fieldVals[$POS]; # add 1??
    if($firstExOverlap < $MIN_OVERLAP) { 
#	print "not enough overlap on first exon. first overlap: $firstExOverlap\n";
	next; 
    }
    if($refAlignLength - $firstExOverlap < $MIN_OVERLAP) {
#	print "not enough overlap on second exon. first overlap: $firstExOverlap\n";
	next; 
    }

# TODO: figure out better output format!
    print "MATCH! $fieldVals[$RNAME] $fieldVals[$POS]";
    print "$fieldVals[$CIGAR] $fieldVals[$QNAME] $fieldVals[$SEQ]\n";
    

}
close $sam_fh;

# Given a CIGAR string, returns the length along
# the reference of the match. This is found by
# summing the M, N, D, X, and = values.
sub getRefAlignLength {
    my $len = 0;

    my @values = split(/[MIDNSHPX=]/, $_[0]);
    my @operations = split(/[0-9]+/, $_[0]);
    
    for(my $i = 0; $i <= $#values; $i++) {
	if($operations[$i + 1] =~ /[MDNX=]/) {
	    $len += $values[$i];
	}
	if($operations[$i + 1] =~ /[I]/) {
	    $len -= $values[$i];
	}
    }

    #print "$len\n";
    return $len;
}



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
}

# Given a gene name and exon number, returns the map
# key associated with that exon.
# Keys are of the form gene_name exon_num
# GENE1 4
sub makeExonLenKey {
    return "$_[0] $_[1]";
}
