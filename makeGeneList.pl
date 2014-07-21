# File: makeGeneList.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# Prints out a tab-separated spreadsheet with the gene ID,
# the frequency total (across all boundaries & all samples),
# and the ucID (for easy lookup in other files). The gene
# ID is the unique identifier. Takes in the file that maps
# between genes and IDs and also the frequency spreadsheet.

use strict;
use warnings;
use Getopt::Long;

my ($GENES_FILE, $FREQ_FILE, $help);
GetOptions('help|?' => \$help,
	   'genes-file' => \$GENES_FILE,
	   'frequency-spreadsheet' => \$FREQ_FILE);

&usage if $help;
&usage unless ($GENES_FILE && $FREQ_FILE);

my %ucIDtoGene = ();

my $G_GENE_SYMBOL = 0;
my $G_UC_ID = 1;

open my $genes_fd, '<', $GENES_FILE or die "ERROR: could not open genes file.\n";
while(my $line = <$genes_fd>) {
    chomp($line);
    my @data = split("\t", $line);

    next if $. == 1; # Don't want to use the first line.
    
    $ucIDtoGene{ $data[$G_UC_ID] } = $data[$G_GENE_SYMBOL];
}
close $genes_fd;


my %geneToFreq = ();

open my $freq_fd, '<', $FREQ_FILE or die "ERROR: could not open frequencies file.\n";
while(my $line = <$freq_fd>) {
    chomp($line);
    my @data = split("\t", $line);
    
    next if $. == 1; # Don't want ot use the first line.
    
    my $geneName = $ucIDtoGene{ $data[0] };

    $geneToFreq{ $geneName } = 0 unless $geneToFreq{ $geneName };
    
    my $sum = 0;
    for(my $i = 1; $i <= $#data; $i++) {
	$sum += $data[$i];
    }
    
    $geneToFreq{ $geneName } += $sum;
}
close $freq_fd;


print "Gene_Symbol\tFrequency";
foreach my $gene (keys %geneToFreq) {
    print "\n$gene\t$geneToFreq{$gene}";
}


sub usage {
die "
 Prints out tab-separated spreadsheet with gene ID,
 the frequency total, and the ucID.

 Usage: perl makeGeneList.pl --genes-file filename.txt --frequency-spreadsheet spreadsheet.txt

"
}
