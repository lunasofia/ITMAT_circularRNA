# File: unmatchedFromSAM.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -----------------------------------
# This program scans through a SAM file and finds
# all unmapped entries. It then finds the corresponding
# entries in the fastq file given (as the second
# parameter) and prints those entries.

use strict;

my ($SAM_FILE, $FQ_FILE) = @ARGV;

# Indices of various information in the SAM file
my $S_QNAME = 0;
my $S_CIGAR = 5;

# Indices of various information in the fastq file
my $FQ_QNAME = 0;
my $FQ_SEQ = 1;
my $FQ_PLUS = 2;
my $FQ_QUAL = 3;

# Hash to keep track of entries (by query ID)
my %unmatchedQueries;

open my $sam_fh, '<', $SAM_FILE;
while(my $nameline = <$sam_fh>) {
    my @sVals = split("\t", $nameline);

    # only copy over if isMapped returns 0 (false)
    if(&isMapped($sVals[$S_CIGAR]) == 0) {
	$unmatchedQueries{ "\@$sVals[$S_QNAME]" } = 1;
    }
}
close $sam_fh;

open my $fq_fh, '<', $FQ_FILE;
while(my $line = <$fq_fh>) {
    if($. % 4 != 1) { next; } #only look at lines with IDs
    my @IDLineArr = split(" ", $line);
    my $key = @IDLineArr[0];

    if($unmatchedQueries{ $key } == 1) {
	print $line;
	for(my $i = 0; $i < 3; $i++) {
	    my $contentLine = <$fq_fh>;
	    print $contentLine;
	}
    }
}
close $fq_fh;

# Takes in the CIGAR string and returns a 0 exactly
# when the CIGAR string is a *, i.e., the query is
# not mapped.
sub isMapped {
    if($_[0] eq '*') {
	return 0;
    }
    return 1;
}
