# File: runBWA.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ------------------------------------
# Takes in a list of IDs and runs BWA. This is definitely
# a first, quick version - going to have to make this
# more generalized later.

use strict;

foreach my $id (@ARGV) {
    `bwa/bwa-0.7.9a/bwa aln bwa/index/mm9_ucsc_exon-exon_shuffled.fa unnormalized_datasets/$id/norm_no_ribosomal.fq > unnormalized_datasets/$id/BWA_read.sai`;
    print "finished first step for $id\n";
    `bwa/bwa-0.7.9a/bwa samse bwa/index/mm9_ucsc_exon-exon_shuffled.fa unnormalized_datasets/$id/BWA_read.sai unnormalized_datasets/$id/norm_no_ribosomal.fq > unnormalized_datasets/$id/BWA_aln.sam`;
    print "finished second step for $id\n";
}
