# File: runAll.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------
# Runs the full pipeline to search for shuffled exons.
# 
# The directories must be arranged in the following structure:
#
# READS/
#   |--- ids.txt
#   |--- Sample_1/
#        Sample_1_forward.fq
#           |--- Sample_1_reverse.fq
#           |--- Sample_1.ribosomalids.txt
#   |--- Sample_2/
#           |--- Sample_2_forward.fq
#           |--- Sample_2_reverse.fq
#           |--- Sample_2.ribosomalids.txt
#
# More detailed specifications are in README.txt
#
# Necessary Flags:
# --bwa-path (-b) <path/>
#     This specifies the path to BWA. If, to run
#     BWA, you would write ../stuff/bwa/bwa-0.7.9a/bwa
#     then path should be "../stuff/bwa/bwa-0.7.9a/"
# --reads-path (-r) <path/>
#     This specifies the directory containing the
#     ids.txt file and the files with the samples.
#     
# Optional Flags:
# --scripts-path (-s) <path/>
#     This specifies the path to the file of scripts.
#     If unspecified, assumed to be in the present
#     directory.
# --min-overlap (-m) <n>
#     This specifies the minimum number of base pairs
#     that must cross an exon-exon boundary in order
#     to count the read as evidence of shuffles exons
# --prealign-star (-p) <path/>
#     If specified, pre-aligns with STAR. The path
#     to STAR must be specified. If, to run STAR,
#     you would write ../stuff/star/STAR then the
#     the path should be "../stuff/star/". The STAR
#     directory must also contain, in index/, the
#     name of the genome.
# --genome-name (-g) <name>
#     Necessary if --star-prealign is specified.
# --quality-filter (-q) <command>
#     If specified, uses the specified command as
#     an additional quality filter on the SAM file
#     immediately after aligning to shuffled-exon
#     database.
# --verbose (-v)
#     If specified, prints out status messages.


use strict;
use warnings;
use Getopt::Long;

my ($BWA_PATH, $READS_PATH, $SCRIPTS_PATH, $MIN_OVERLAP,
    $STAR_PATH, $GENOME, $QUAL_COMMAND, $help, $verbose);
GetOptions('help|?' => \$help,
	   'verbose' => \$verbose,
	   'bwa-path=s' => \$BWA_PATH,
	   'reads-path=s' => \$READS_PATH,
	   'scripts-path=s' => \$SCRIPTS_PATH,
	   'min-overlap=i' => \$MIN_OVERLAP,
	   'prealign-star=s' => \$STAR_PATH,
	   'genome-name=s' => \$GENOME,
	   'quality-filter=s' => \$QUAL_COMMAND);
&usage if $help;
&usage unless ($BWA_PATH && $READS_PATH);
&usage if ($STAR_PATH && !$GENOME);

my @ids;

# ----------- GET ID LIST ----------
my $ID_FILE = $READS_PATH . "ids.txt";
print "STATUS: Getting ID list from $ID_FILE\n" if $verbose;
open my $id_fh, '<', $ID_FILE or die "ERROR: could not open id file ($ID_FILE)\n";
while(<$id_fh>) {
    chomp($_);
    push @ids, $_;
}
close $id_fh;
print "STATUS: Successfully loaded ID list\n" if $verbose;


foreach my $id (@ids) {
    print "STATUS: Beginning to process $id\n" if $verbose;

# ----------- REMOVE rRNA MATCHES ----------
# my $command = "perl ";
# $command .= $SCRIPTS_PATH if $SCRIPTS_PATH;
# $command .= "removeSetFromFQ.pl ";
# $command .=

    print "STATUS: Done processing $id\n" if $verbose;
}


# ---------- COMBINE INTO SINGLE FINAL SPREADSHEET ----------


sub usage {
die "
 See README.txt for more detailed specifications.

 Necessary Flags:
 --bwa-path (-b) <path/>
     This specifies the path to BWA. If, to run
     BWA, you would write ../stuff/bwa/bwa-0.7.9a/bwa
     then path should be \"../stuff/bwa/bwa-0.7.9a/\"
 --read-directory (-r) <path/>
     This specifies the directory containing the
     ids.txt file and the files with the samples.
     
 Optional Flags:
 --min-overlap (-m) <n>
     This specifies the minimum number of base pairs
     that must cross an exon-exon boundary in order
     to count the read as evidence of shuffles exons
 --star-prealign (-s) <path/>
     If specified, pre-aligns with STAR. The path
     to STAR must be specified. If, to run STAR,
     you would write ../stuff/star/STAR then the
     the path should be \"../stuff/star/\". The STAR
     directory must also contain, in index/, the
     name of the genome.
 --genome-name (-g) <name>
     Necessary if --star-prealign is specified.
 --quality-filter (-q) <command>
     If specified, uses the specified command as
     an additional quality filter on the SAM file
     immediately after aligning to shuffled-exon
     database.

"
}
