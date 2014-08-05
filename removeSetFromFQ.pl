# File: removeSetFromFQ.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------------------
# Takes in a fastq file and a file of IDs to
# be removed from the fastq file. The IDs should
# be one per line, without @ symbol prefix.
#
# Outputs a fastq with the entries corresponding
# to those IDs removed.
#
# Usage: perl removeSetFromFQ --fq-file="file.fq" --idlist-file="file.txt"

use strict;
use warnings;
use Getopt::Long;

my ($FQ_FILE, @IDLIST_FILES, $help);
GetOptions('help|?' => \$help,
	   'fq-file=s' => \$FQ_FILE,
	   'idlist-file=s' => \@IDLIST_FILE);

&usage if $help;
&usage unless ($FQ_FILE && $IDLIST_FILES[0]);

my %idlist = ();

# Read list of IDs into hash
foreach my $file (@IDLIST_FILES) {
    open my $idlist_fh, '<', $file;
    while(<$idlist_fh>) {
	chomp($_);
	$idlist{ "\@$_" } = 1;
    }
    close $idlist_fh;
}

# Read through fastq and print any entry that
# does not appear in the hash
my $FQ_NUMLINES = 4;
open my $fq_fh, '<', $FQ_FILE;
while(<$fq_fh>) {
    # skip if not an ID line or ID is in map
    next if($. % $FQ_NUMLINES != 1);
    my @idline_arr = split(" ", $_);
    my $id = $idline_arr[0];
    next if($idlist{ "$id" });

    # Print out all fq lines.
    print "$_";
    for(my $i = 1; $i < $FQ_NUMLINES; $i++) {
	my $contentLine = <$fq_fh>;
	last unless $contentLine;
	chomp($contentLine);
	print "$contentLine\n";
    }
}
close $fq_fh;



sub usage {
    die "
 Takes in a fastq file and a file of IDs to
 be removed from the fastq file. The IDs should
 be one per line, without @ symbol prefix. Can
 take in multiple ID files, specified by
 several --idlist-file flags.

 Outputs a fastq with the entries corresponding
 to those IDs removed.

 Usage: perl removeSetFromFQ --fq-file file.fq --idlist-file file.txt

"
}
