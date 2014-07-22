# File: pairedEndSAM.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# Given a particular exon-exon boundary crossing, finds
# out information about the paired ends. As of right now,
# outputs as a SAM file (without any headers), with all
# reads that cross that boundary and all their pairs, either
# from STAR or BWA.

use strict;
use warnings;
use Getopt::Long;

my ($CROSS_SAM, $REG_SAM, $BOUNDARY, $help); 

GetOptions('help|?' => \$help,
	   'crossing-sam-file=s' => \$CROSS_SAM,
	   'regular-sam-file=s' => \$REG_SAM,
	   'boundary-name=s' => \$BOUNDARY);
&usage if $help;
&usage unless ($CROSS_SAM && $REG_SAM && $BOUNDARY);

# Constants for reading SAM files
my $S_QNAME = 0;
my $S_RNAME = 2;

# First, find all the IDs associated with boundary-crossing
# events and put them into a hash.
my %crossingEvents = ();

open my $cross_sam_fh, '<', $CROSS_SAM;
while(my $line = <$cross_sam_fh>) {
    chomp($line);
    my @samVals = split("\t", $line);
    next unless $samVals[$S_RNAME] eq $BOUNDARY;
    
    # add to hash
    $crossingEvents{ $samVals[$S_QNAME] } = 1;

    # print out SAM line
    print "$line\n";
}
close $cross_sam_fh;

# Read through full SAM file, printing all with IDs that
# match the hash.
open my $reg_sam_fh, '<', $REG_SAM;
while(my $line = <$reg_sam_fh>) {
    chomp($line);
    my @samVals = split("\t", $line);
    next unless $crossingEvents{ $samVals[$S_QNAME] };
    
    print "$line\n";
}
close $reg_sam_fh;


sub usage {
die "
 Given a particular exon-exon boundary crossing, finds
 out information about the paired ends. As of right now,
 outputs as a SAM file (without any headers), with all
 reads that cross that boundary and all their pairs, either
 from STAR or BWA.

 Necessary flags:
 --crossing-sam-file
 --regular-sam-file
 --boundary-name

"}
