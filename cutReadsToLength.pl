# File: cutReadsToLength.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# This file takes in an fq file and cuts down all the reads to the specified
# length. It removes any read that is shorter than that length.

use strict;
use warnings;
use Getopt::Long;

my ($FQ_FILE, $READ_LENGTH, $help);
GetOptions('fastq-file=s' => \$FQ_FILE,
	   'read-length=i' => \$READ_LENGTH,
	   'help|?' => \$help);

&usage if $help;
&usage unless $FQ_FILE && $READ_LENGTH;

my $shortSeqCount = 0;
open my $fq_fh, '<', $FQ_FILE or die "ERROR: cannot open $FQ_FILE\n";
while(my $nameLine = <$fq_fh>) {
    my $seqLine = <$fq_fh>;
    my $plusLine = <$fq_fh>;
    my $qualLine = <$fq_fh>;
    chomp($nameLine);
    chomp($seqLine);
    chomp($plusLine);
    chomp($qualLine);
    
    if(length($seqLine) < $READ_LENGTH) {
	$shortSeqCount++;
	next;
    }
    
    print $nameLine, "\n";
    print(substr $seqLine, -$READ_LENGTH);
    print "\n";
    print $plusLine, "\n";
    print $qualLine, "\n";
}

warn "$shortSeqCount sequences were too short.\n" if $shortSeqCount;



sub usage {
    die "
Necessary flags:
--fastq-file
--read-length

"}
