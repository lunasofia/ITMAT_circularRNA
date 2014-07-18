# File: exonBoundaryCrossFilter.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------------------
# Counts the number of crossings for each scrambled pair.
# Output is in SAM format.
# 
# Required flags:
# --exon-info-file (-e) <filename>
#     file with list of exons for each gene. This file
#     can be either in fasta format or in fasta without
#     the actual sequences (only the header lines,
#     wich start with '>').
# --sam-file (-s) <filename>
#     SAM file with reads matched to the database of
#     scrambled exon junctions.
# Optional flags:
# --min-overlap (-m) <n>
#     Integer value. The minimum overlap for a boundary
#     crossing to be counted as legitimate. The default
#     value is 30 (base pairs).

use strict;
use warnings;
use Getopt::Long;

my ($EXONS_FILE, $SAM_FILE, $help);
my $MIN_OVERLAP = 30;
GetOptions('help|?' => \$help,
	   'exon-info-file=s' => \$EXONS_FILE,
	   'sam-file=s' => \$SAM_FILE,
	   'min-overlap=i' => \$MIN_OVERLAP);

&usage if $help;
&usage unless ($EXONS_FILE && $SAM_FILE);

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

# Keep track of errors to be printed at end
my $incorNamesCount = 0;
my $noExonFoundCount = 0;
my $asteriskCount = 0; # INSERTED FOR TESTING

open my $sam_fh, '<', $SAM_FILE or die "\nError: Could not open sam file.\n";
while(my $line = <$sam_fh>) {
    # skip over header lines, which start with '@'
    if($line =~ /^@/) { next; }
    
    chomp($line);
    my @fieldVals = split(" ", $line);

    my @nameArr = split("-", $fieldVals[$RNAME]);
    if($#nameArr != 2) { 
	$incorNamesCount++ unless ($nameArr[0] eq '*');
	$asteriskCount++ if ($nameArr[0] eq '*');
	next;
    }

    my $firstExonKey = &makeExonLenKey(">$nameArr[0]", $nameArr[1]);
    my $firstExonLen = $exonLengths{ $firstExonKey };
    unless($firstExonLen) {
        $noExonFoundCount++;
	next;
    }

    # make sure there is sufficient overlap
    my $refAlignLength = &getRefAlignLength($fieldVals[$CIGAR]);
    my $firstExOverlap = $firstExonLen - $fieldVals[$POS];
    next if($firstExOverlap < $MIN_OVERLAP);
    next if($refAlignLength - $firstExOverlap < $MIN_OVERLAP);

    # if sufficient overlap, print out line
    print "$line\n";
}
close $sam_fh;

warn "WARNING: $incorNamesCount badly formed RNAME fields found\n" if $incorNamesCount;
warn "WARNING: $noExonFoundCount exons not found\n" if $noExonFoundCount;
warn "WARNING: $asteriskCount asterisks found in RNAME field\n" if $asteriskCount;


# Given a CIGAR string, returns the length along
# the reference of the match. This is found by
# summing the M, N, D, X, and = values.
sub getRefAlignLength {
    my $len = 0;

    my @values = split(/[MIDNSHPX=]/, $_[0]);
    my @operations = split(/[0-9]+/, $_[0]);
    
    # Off-by-one is because of details of split.
    for(my $i = 0; $i <= $#values; $i++) {
	if($operations[$i + 1] =~ /[MDNX=]/) {
	    $len += $values[$i];
	}
	if($operations[$i + 1] =~ /[I]/) {
	    $len -= $values[$i];
	}
    }

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
	next unless($nameline =~ /^>/); # only exon info lines read
	chomp($nameline);
	
	my @namelineVals = split(" ", $nameline);
	
	my $key = &makeExonLenKey($namelineVals[$GENE_NAME], $namelineVals[$EXON_NUM]);
	my $value = $namelineVals[$EXON_END] - $namelineVals[$EXON_START];
	
	$exonLengths{ $key } = $value;
    }
    close $exons_fh;
}

# Given the start and end locations of an exon, makes an array with the
# start and end values and the length of the exon. Returns a reference
# to that array.
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


sub usage {
    die "
 Counts the number of crossings for each scrambled pair.
 Output is in SAM format.
 
 Required flags:
 --exon-info-file (-e) <filename>
     file with list of exons for each gene. This file
     can be either in fasta format or in fasta without
     the actual sequences (only the header lines,
     wich start with '>').
 --sam-file (-s) <filename>
     SAM file with reads matched to the database of
     scrambled exon junctions.
 Optional flags:
 --min-overlap (-m) <n>
     Integer value. The minimum overlap for a boundary
     crossing to be counted as legitimate. The default
     value is 30 (base pairs).

"
}
