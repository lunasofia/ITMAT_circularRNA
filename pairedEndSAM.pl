# File: pairedEndSAM.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# Given a particular exon-exon boundary crossing, finds
# out information about the paired ends. Outputs a SAM
# file of all the paired ends that appear in any of the
# input SAM files, and writes all others to a fastq
# file.

use strict;
use warnings;
use Getopt::Long;

my (@CROSS_SAM_FILES, @REG_SAM_FILES, $IN_FQ_FILE, $OUT_FQ_FILE, $BOUNDARY, $help); 

GetOptions('help|?' => \$help,
	   'crossing-sam-file=s' => \@CROSS_SAM_FILES,
	   'regular-sam-file=s' => \@REG_SAM_FILES,
	   'fastq-file=s' => \$IN_FQ_FILE,
	   'fastq-output=s' => \$OUT_FQ_FILE,
	   'boundary-name=s' => \$BOUNDARY);
&usage if $help;
&usage unless ($CROSS_SAM_FILES[0] && $IN_FQ_FILE && $OUT_FQ_FILE && $BOUNDARY);

# Constants for reading SAM files
my $S_QNAME = 0;
my $S_RNAME = 2;

# First, find all the IDs associated with boundary-crossing
# events and put them into a hash.
my %crossingEvents = ();

foreach my $FILE (@CROSS_SAM_FILES) {
    open my $cross_sam_fh, '<', $FILE or die "ERROR: could not open file $FILE\n";
    while(my $line = <$cross_sam_fh>) {
	chomp($line);
	my @samVals = split("\t", $line);
	next unless $samVals[$S_RNAME] eq $BOUNDARY;
	
	# add to hash with value 2, because we need to find
	# 2 reads with this ID before we're done
	$crossingEvents{ $samVals[$S_QNAME] } = 2;
    }
    close $cross_sam_fh;
}


foreach my $FILE (@CROSS_SAM_FILES) {
    open my $cross_sam_fh, '<', $FILE or die "ERROR: could not open file $FILE\n";
    while(my $line = <$cross_sam_fh>) {
	chomp($line);
	my @samVals = split("\t", $line);
	next unless $crossingEvents{ $samVals[$S_QNAME] };

	print "$line\n";
	$crossingEvents{ $samVals[$S_QNAME] } -= 1;
	
    }
    close $cross_sam_fh;
}

foreach my $FILE (@REG_SAM_FILES) {    
    # Read through full SAM file, printing all with IDs that
    # match the hash.
    open my $reg_sam_fh, '<', $FILE or die "ERROR: could not open file $FILE\n";
    while(my $line = <$reg_sam_fh>) {
	chomp($line);
	my @samVals = split("\t", $line);
	next unless $crossingEvents{ $samVals[$S_QNAME] };
	
	print "$line\n";
	$crossingEvents{ $samVals[$S_QNAME] } -= 1;
    }
    close $reg_sam_fh;
}

open my $infq_fh, '<', $IN_FQ_FILE or die "ERROR: could not open file $IN_FQ_FILE\n";
open my $outfq_fh, '>', $OUT_FQ_FILE or die "ERROR: could not open (create) fiel $OUT_FQ_FILE\n";
while(my $nameline = <$infq_fh>) {
    next unless ($. % 4 == 0);
    
    chomp($nameline);
    my @namevals = split(" ", $nameline);
    my $id = substr $namevals[0], 1;

    next unless $crossingEvents{ $id };
    
    print "$nameline\n";
    for(my $i = 1; $i < 4; $i++) {
	my $line = <$infq_fh>;
	chomp($line);
	print $outfq_fh "$line\n";
    }
}
close $infq_fh, $outfq_fh;

sub usage {
die "
 Given a particular exon-exon boundary crossing, finds
 out information about the paired ends. As of right now,
 outputs as a SAM file (without any headers), with all
 reads that cross that boundary and all their pairs, either
 from STAR or BWA.

 Necessary flags:
 --crossing-sam-file
     Uses these files to find the IDs of the events that
     cross the specified boundary. Also prints out the
     entries for those events.
 --fastq-file
 --fastq-output
 --boundary-name

 Optional flags:
 --regular-sam-file

"}
