# File: makeGenomeLocSheet.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# This takes creates a tab-separated spreadsheet of information
# about reads crossing reverse exon junctions. Information is in
# similar format to the CircBase spreadsheet (including the indexing,
# which is different than the indexing in the exon info file).

use strict;
use warnings;
use Getopt::Long;

my ($EXON_REF, $GENE_NAME_REF, $FREQUENCIES, $MIN_FREQ, $help);

GetOptions('exon-info-ref=s' => \$EXON_REF,
	   'gene-name-ref=s' => \$GENE_NAME_REF,
	   'freq-spreadsheet=s' => \$FREQUENCIES,
	   'min-frequency=i' => \$MIN_FREQ,
	   'help|?' => \$help);

&usage if $help;
&usage unless ($EXON_REF && $GENE_NAME_REF && $FREQUENCIES);
$MIN_FREQ = 2 unless defined $MIN_FREQ;

# Load information about genes
warn "STATUS: loading information about genes.\n";
my %ucIDtoGene = ();

my $G_GENE_SYMBOL = 1;
my $G_UC_ID = 0;

open my $genes_fd, '<', $GENE_NAME_REF or die "ERROR: could not open file $GENE_NAME_REF\n";
while(my $line = <$genes_fd>) {
    chomp($line);
    my @data = split("\t", $line);
    
    next if $. == 1; # Don't want to use the first line.
    next unless $data[$G_UC_ID]; # Don't want empty lines

    $ucIDtoGene{ $data[$G_UC_ID] } = $data[$G_GENE_SYMBOL];
}
close $genes_fd;
warn "STATUS: done loading info about genes.\n";

# Load information about exons
warn "STATUS: loading information about exons.\n";
my %exonToLoc = ();

my $E_GENE_NAME = 0;
my $E_EXON_NUM = 2;
my $E_CHR = 3;
my $E_EXON_START = 4;
my $E_EXON_END = 5;

open my $exons_fd, '<', $EXON_REF or die "ERROR: could not open file $EXON_REF\n";
while(my $line = <$exons_fd>) {
    chomp($line);
    my @vals = split(" ", $line);
    
    my $key = substr $vals[$E_GENE_NAME], 1;
    $key .= "-$vals[$E_EXON_NUM]";

    my @locData = ($vals[$E_CHR], $vals[$E_EXON_START], $vals[$E_EXON_END]);
    $exonToLoc{ $key } = \@locData;
}
close $exons_fd;
warn "STATUS: done loading information about exons.\n";

warn "STATUS: iterating through frequencies spreadsheet.\n";
# Now that everything is loaded, iterate through frequencies spreadsheet
my $linesPrinted = 0;
open my $freq_fq, '<', $FREQUENCIES or die "ERROR: could not open file $FREQUENCIES\n";
while(my $line = <$freq_fq>) {
    chomp($line);
    my @vals = split("\t", $line);

    # Skip the header (but print out file header)
    if($vals[0] eq '-') {
	&printHeader(@vals);
	next;
    }

    # Find total frequency
    my $freqSum = 0;
    for(my $i = 1; $i <= $#vals; $i++) {
	$freqSum += $vals[$i];
    }
    next unless ($freqSum >= $MIN_FREQ);
	 

    # Print out entry
    &printInfo($vals[0]);
    print "$line\n";
    $linesPrinted++;
}

close $freq_fq;
warn "STATUS: done iterating through frequencies spreadsheet. $linesPrinted lines printed.\n";


# Takes in a junction ID and prints out the information about
# the location (chromosome, start of chr that appears first in
# the genome, and end of chr that appears later in the genome).
sub printInfo {
    my $junctionData = $_[0];
    my @junctionVals = split("-", $junctionData);

    my $firstExon = "$junctionVals[0]-$junctionVals[1]";
    my $secondExon = "$junctionVals[0]-$junctionVals[2]";

    my $firstLocData = $exonToLoc{ $firstExon };
    my $secondLocData = $exonToLoc{ $secondExon };

    my $chr = $firstLocData->[0];
    my $start = $secondLocData->[1] - 1;
    my $end = $firstLocData->[2];

    my $geneSymb = $ucIDtoGene{ $junctionVals[0] };
    $geneSymb = "*" unless $geneSymb;

    print "$chr\t$start\t$end\t$geneSymb\t";
}


# Prints the header of the file. Takes in the header line
# (already split) from the frequencies table to make the
# end of the header.
sub printHeader {
    print "chrom\tstart\tend\tgene_symbol\tjunction_id";
    for(my $i = 1; $i <= $#_; $i++) {
	print "\t$_[$i]";
    }
    print "\n";
}



sub usage {
    die "
 Necessary Flags:
 --exon-info-ref
 --gene-name-ref
 --freq-spreadsheet

 Optional Flags:
 --min-frequency

"}
