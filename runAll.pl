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
#           |--- Sample_1_forward.fq
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
# --exon-info-file (-e) <path/filename>
#     This specifies the file (either fastA or in a
#     similar format, with the sequence lines removed)
#     to be used for info about the exons
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
# --verbose (-v)
#     If specified, prints out status messages.


use strict;
use warnings;
use Getopt::Long;

my ($BWA_PATH, $READS_PATH, $EXON_FILE,
    $SCRIPTS_PATH, $MIN_OVERLAP, $STAR_PATH,
    $GENOME, $help, $verbose);
GetOptions('help|?' => \$help,
	   'verbose' => \$verbose,
	   'bwa-path=s' => \$BWA_PATH,
	   'reads-path=s' => \$READS_PATH,
	   'exon-info-file=s' => \$EXON_FILE,
	   'scripts-path=s' => \$SCRIPTS_PATH,
	   'min-overlap=i' => \$MIN_OVERLAP,
	   'prealign-star=s' => \$STAR_PATH,
	   'genome-name=s' => \$GENOME);

# Make sure arguments were entered correctly. Also,
# add "/" to end of directory names if not already
# there.
&usage if $help;
&usage unless ($BWA_PATH && $READS_PATH && $EXON_FILE);
if($STAR_PATH) {
    &usage unless $GENOME;
    $STAR_PATH .= "/" unless $STAR_PATH =~ /\/$/;
}
if($SCRIPTS_PATH) {
    $SCRIPTS_PATH .= "/" unless $SCRIPTS_PATH =~ /\/$/;
}
$BWA_PATH .= "/" unless $BWA_PATH =~ /\/$/;
$READS_PATH .= "/" unless $READS_PATH =~ /\/$/;

# To be used to run commands for both forward and backward
my @DIRECTIONS = ("forward", "reverse");

# Prefix for each perl script
my $PERL_PREFIX = "perl ";
$PERL_PREFIX .= $SCRIPTS_PATH if $SCRIPTS_PATH;
	

# List of IDs (populated from ids.txt)
my @ids;


# ----------- GET ID LIST ----------
my $ID_FILE = $READS_PATH . "ids.txt";
print "STATUS: Getting ID list from $ID_FILE\n";
open my $id_fh, '<', $ID_FILE or die "ERROR: could not open id file ($ID_FILE)\n";
while(<$id_fh>) {
    chomp($_);
    push @ids, $_;
}
close $id_fh;
print "STATUS: Successfully loaded ID list\n\n";
# ---------- done getting ID list ----------


print "STATUS: Beginning match weed-out\n";
foreach my $id (@ids) {

    # ----------- REMOVE rRNA MATCHES ----------
    print "\tSTATUS: Removing rRNA matches for $id\n" if $verbose;
    foreach my $direction (@DIRECTIONS) {
	my $command = $PERL_PREFIX;
	$command .= "removeSetFromFQ.pl ";
	$command .= "--fq-file $READS_PATH$id/$id";
	$command .= "_$direction.fq ";
	$command .= "--idlist-file $READS_PATH$id/$id.ribosomalids.txt";
	$command .= " > $READS_PATH$id/${direction}_norib.fq";
	my $err = system($command);
	die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
	print "\tSTATUS: removeSetFromFQ ran successfully for $direction.\n" if $verbose;
    } 
    print "\tSTATUS: Done removing rRNA matches for $id\n" if $verbose;
    # ----------- done removing rRNA matches ----------


    # ----------- REMOVE REGULAR MATCHES (if specified) ----------
    # ----------- done removing regular matches ----------
    
}
print "STATUS: Finished match weed-out\n\n";



# ----------- EQUALIZE NUMBER OF READS -----------
print "STATUS: Equalizing numbers of reads\n";
my $minNumReads;
foreach my $id (@ids) {
    foreach my $direction (@DIRECTIONS) {
	# Count lines
	my $lineCount = 0;
	open my $fq_fh, '<', "$READS_PATH$id/${direction}_norib.fq" or die "ERROR\n";
	while(<$fq_fh>) {
	    $lineCount++;
	}
	close $fq_fh;
	
	# Update min if necessary
	my $nReads = $lineCount / 4;	
	$minNumReads = $nReads unless $minNumReads; # if first loop
	$minNumReads = $nReads if $nReads < $minNumReads;
    }
}
print "\tSTATUS: Minimum number of reads is $minNumReads\n" if $verbose;

foreach my $id (@ids) {
    foreach my $direction (@DIRECTIONS) {
	my $command = $PERL_PREFIX;
	$command .= "randSubsetFromFQ.pl ";
	$command .= "--fq-filename $READS_PATH$id/${direction}_norib.fq ";
	$command .= "--n-output-entries $minNumReads";
	$command .= " > $READS_PATH$id/${direction}_equalized.fq";
	my $err = system($command);
	die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
	print "\tSTATUS: Equalized $id $direction.\n" if $verbose;
    }
}
print "STATUS: Done equalizing number of reads\n\n";
# ----------- done equalizing number of reads -----------


foreach my $id (@ids) {
    # ----------- ALIGN TO SHUFFLED DATABASE -----------
    # DO LATER
    # ----------- done aligning to shuffled database -----------


    # ----------- SELECT EXON-BOUNDARY CROSSING READS ----------
    print "STATUS: Selecting exon-boundary crossing reads for $id.\n";
    foreach my $direction (@DIRECTIONS) {
	my $command = $PERL_PREFIX;
	$command .= "exonBoundaryCrossFilter.pl ";
	$command .= "--exon-info-file $EXON_FILE ";
	$command .= "--sam-file $READS_PATH$id/${direction}_aligned.sam ";
	$command .= "--min-overlap $MIN_OVERLAP " if $MIN_OVERLAP;
	$command .= "> $READS_PATH$id/${direction}_finalmatch.sam";
	my $err = system($command);
	die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
	print "\tSTATUS: exonBoundaryCrossFilter ran successfully for $direction\n" if $verbose;
	
    }
    # Combine forward and reverse
    my $command = "cat $READS_PATH$id/forward_finalmatch.sam ";
    $command .= "$READS_PATH$id/reverse_finalmatch.sam ";
    $command .= "> $READS_PATH$id/together_finalmatch.sam";
    my $err = system($command);
    die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
    print "\tSTATUS: combined forward and reverse\n" if $verbose;
    
    print "STATUS: Done selectiong exon-boundary crossing reads for $id.\n\n";
    # ----------- done selecting for boundary-crossing ----------


    # ----------- CONVERT TO FREQUENCY COLUMN ----------
    print "STATUS: Converting to frequency column.\n";
    my $command = $PERL_PREFIX;
    $command .= "samToSpreadsheetCol.pl ";
    $command .= "--sam-filename $READS_PATH$id/together_finalmatch.sam ";
    $command .= "--column-title $id ";
    $command .= "> $READS_PATH$id/frequencies.txt";
    my $err = system($command);
    die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
    print "\tSTATUS: samToSpreadsheetCol ran successfully.\n" if $verbose;
    print "STATUS: Done converting to frequency column.\n\n";
    # ----------- done converting to column ----------
}


# ---------- COMBINE INTO SINGLE FINAL SPREADSHEET ----------
print "STATUS: Combining into single final spreadsheet.\n";
my $command = $PERL_PREFIX;
$command .= "combineColumns.pl ";
foreach my $id (@ids) {
    $command .= "$READS_PATH$id/frequencies.txt ";
}
$command .= "> $READS_PATH/finalspreadsheet.txt";

my $err = system($command);
die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
print "\tSTATUS: combineColumns ran successfully.\n" if $verbose;
print "STATUS: Done combining.\n\n";
# ---------- done combining into spreadsheet ----------


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
 --exon-info-file (-e) <path/filename>
     This specifies the file (either fastA or in a
     similar format, with the sequence lines removed)
     to be used for info about the exons
     
 Optional Flags:
 --scripts-path (-s) <path/>
     This specifies the path to the file of scripts.
     If unspecified, assumed to be in the present
     directory.
 --min-overlap (-m) <n>
     This specifies the minimum number of base pairs
     that must cross an exon-exon boundary in order
     to count the read as evidence of shuffles exons
 --prealign-star (-p) <path/>
     If specified, pre-aligns with STAR. The path
     to STAR must be specified. If, to run STAR,
     you would write ../stuff/star/STAR then the
     the path should be \"../stuff/star/\". The STAR
     directory must also contain, in index/, the
     name of the genome.
 --genome-name (-g) <name>
     Necessary if --star-prealign is specified.
 --verbose (-v)
     If specified, prints out extra status messages.

"
}