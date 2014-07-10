# File: runCrossFilter.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------
# Selects the desired files from the SAM output
# of BWA. First uses grep to find the 100M matches
# and then calls exonBoundaryCrossFilter.pl to
# select only the matches which cross reverse
# exon-exon boundaries by enough base pairs.
#
# This is very much a beta-version, and will be
# improved and generalized for the full pipeline
# script.

use strict;

foreach my $id (@ARGV) {
    `grep "100M" unnormalized_datasets/$id/BWA_aln.sam > unnormalized_datasets/$id/100M_aln.sam`;
    print "finished grep call for $id\n";
    `perl scripts/exonBoundaryCrossFilter.pl -e exon_info_docs/mm9_ucsc_exons_info.txt -s unnormalized_datasets/$id/100M_aln.sam > unnormalized_datasets/$id/finalMatches.sam`;
    print "finished full selection for $id\n";
}
