# File: exonBoundaryCrossFilter.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------------------
# Counts the number of crossings for each scrambled pair.
#
# Takes in two files. The first is the list of exons for
# each gene, which is used to gather information about
# the lengths of the exons. The second is the SAM file
# of matches.
# 
# The list of exons must be in the following format:
# >GENE1 exon 1 chr1 00050 00100
#
# Prints in SAM format.

use strict;
use Getopt::Long;

my $USAGE = "Usage:\n perl exonBoundaryCrossFilter.pl " .
    "--exon-info-filename=\"exons.txt\" --sam-filename=\"filename.sam\"\n";

my ($EXONS_FILE, $SAM_FILE, $help);
GetOptions('help|?' => \$help,
	   'exon-info-filename=s' => \$EXONS_FILE,
	   'sam-filename=s' => \$SAM_FILE);

die "$USAGE" if $help;
die "$USAGE" unless ($EXONS_FILE && $SAM_FILE);

# Hash to keep track of exon lengths.
# Key format is gene_name exon_num
# GENE1 4
my %exonLengths = ();

# Fills the exonLengths hash with the exon info
# file.
&getExonLengths;

# Constants to give the indices of various pieces
# of information in the SAM format.
my $QNAME = 0;
my $RNAME = 2;
my $POS = 3;
my $CIGAR = 5;
my $SEQ = 9;

# Minimum required overlap for a crossing to count
my $MIN_OVERLAP = 10;

# Variables for keeping track of matches and cases of
# insufficient overlap.
my $matchCount = 0;
my $insufOverlapCount = 0;

open my $sam_fh, '<', $SAM_FILE or die "\nError: Could not open sam file.\n";
while(my $line = <$sam_fh>) {
    # skip over header lines, which start with '@'
    if($line =~ /^@/) { next; }
    
    chomp($line);
    my @fieldVals = split(" ", $line);

    my @nameArr = split("-", $fieldVals[$RNAME]);
    if($#nameArr != 2) { 
	die "ERROR: incorrenctly formatted name: $fieldVals[$RNAME]\n";
    }

    my $firstExonKey = &makeExonLenKey(">$nameArr[0]", $nameArr[1]);
    if(!($exonLengths{ $firstExonKey })) {
        die "ERROR failure to find exon: $firstExonKey\n";
    }
    my $firstExonLen =
        $exonLengths{ $firstExonKey }->[2];


    my $secondExonKey = &makeExonLenKey(">$nameArr[0]", $nameArr[2]);
    if(!($exonLengths{ $secondExonKey })) {
        die "ERROR failure to find exon: $secondExonKey\n";
    }

    # make sure there is sufficient overlap
    my $refAlignLength = &getRefAlignLength($fieldVals[$CIGAR]);
    my $firstExOverlap = $firstExonLen - $fieldVals[$POS];
    if($firstExOverlap < $MIN_OVERLAP) {
        $insufOverlapCount++;
        next;
    }
    if($refAlignLength - $firstExOverlap < $MIN_OVERLAP) {
        $insufOverlapCount++;
        next;
    }

#   Print out successful match
#   print "MATCH\n";
    for(my $i = 0; $i <= $SEQ; $i++) {
	print "$fieldVals[$i]\t";
    }
    print "\n";
    $matchCount++;
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

    open my $exons_fh, '<', $EXONS_FILE or die "\nError: could not open exon info file.\n";
    while(my $nameline = <$exons_fh>) {
	chomp($nameline);
	
	my @namelinevals = split(" ", $nameline);
	
	my $key = &makeExonLenKey($namelinevals[$GENE_NAME], $namelinevals[$EXON_NUM]);
	my $value_arr = &makeExonLenVal($namelinevals[$EXON_START], $namelinevals[$EXON_END]);
	
	$exonLengths{ $key } = $value_arr;
    }
    close $exons_fh;
}

sub makeExonLenVal {
    my @valArr = @_;
    push @valArr, $_[1] - $_[0];
    return \@valArr;
}

# Given a gene name and exon number, returns the map
# key associated with that exon.
# Keys are of the form gene_name exon_num
# GENE1-4
sub makeExonLenKey {
    return "$_[0]-$_[1]";
}