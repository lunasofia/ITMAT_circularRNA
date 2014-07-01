# File: unmatchedFromSAM.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -----------------------------------
# This program scans through a SAM file and finds
# all unmapped entries. Writes those entries in
# fastq format.

use strict;

# Indices of various information in the SAM file
my $S_QNAME = 0;
my $S_CIGAR = 5;
my $S_SEQ = 9;
my $S_QUAL = 10;

# Indices of various information in the fastq file
my $FQ_QNAME = 0;
my $FQ_SEQ = 1;
my $FQ_PLUS = 2;
my $FQ_QUAL = 3;

while(<>) {
    my @sVals = split($_);

    # only copy over if isMapped returns 0 (false)
    if(&isMapped($sVals[$S_CIGAR]) == 0) {
	&writeQuery(@sVals);
    }
}

# Takes in the values of a SAM file line and prints
# out the query information in fastq format.
sub writeQuery {
    print "$_[$S_QNAME]\n";
    print "$_[$S_SEQ]\n";
    print "+\n";
    print "$_[$S_QUAL]\n";
}

# Takes in the CIGAR string and returns a 0 exactly
# when the CIGAR string is a *, i.e., the query is
# not mapped.
sub isMapped {
    if($_[0] eq '*') {
	return 0;
    }
    return 1;
}
