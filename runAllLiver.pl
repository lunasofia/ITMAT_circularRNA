# File: runAll.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------
# Runs the full pipeline to search for shuffled exons, but with
# no normalization step.
# 
# The directories must be arranged in the following structure:
#
# READS/
#   |---ids.txt
#   |---exon_info.txt
#   |--- Sample_1/
#           |--- Sample_1.fq
#   |--- Sample_2/
#           |--- Sample_2.fq
#
# More detailed specifications are in README.txt
#
# Necessary Flags:
# --bwa-path (-b) <path/>
#     This specifies the path to BWA. If, to run
#     BWA, you would write ../stuff/bwa/bwa-0.7.9a/bwa
#     then path should be "../stuff/bwa/bwa-0.7.9a/"
# --exon-database (-e) <version/>
#     This specifies the shuffles exon index. Note
#     that BWA's index command should be used to
#     generate the other files in the directory.
#     (This file should be a FastA file.)
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
# --genome-path (-g) <name>
#     Necessary if --star-prealign is specified.
# --thread-count (-t)
#     How many threads should be used (while running
#     STAR - the rest does not yet support threads.)
# --verbose (-v)
#     If specified, prints out status messages.


use strict;
use warnings;
use Getopt::Long;

my ($BWA_PATH, $BWA_VERSION, $EXON_DATABASE,
    $SCRIPTS_PATH, $MIN_OVERLAP, $STAR_PATH,
    $READS_PATH, $GENOME_PATH, $NTHREADS, 
    $help, $verbose);
GetOptions('help|?' => \$help,
	   'verbose' => \$verbose,
	   'bwa-path=s' => \$BWA_PATH,
	   'exon-database=s' => \$EXON_DATABASE,
	   'reads-path=s' => \$READS_PATH,
	   'scripts-path=s' => \$SCRIPTS_PATH,
	   'min-overlap=i' => \$MIN_OVERLAP,
	   'prealign-star=s' => \$STAR_PATH,
	   'genome-path=s' => \$GENOME_PATH,
	   'thread-count=i' => \$NTHREADS);

# Make sure arguments were entered correctly. Also,
# add "/" to end of directory names if not already
# there.
&usage if $help;
&usage unless ($BWA_PATH && $READS_PATH);
if($STAR_PATH) {
    &usage unless $GENOME_PATH;
    $GENOME_PATH .= "/" unless $GENOME_PATH =~ /\/$/;
    $STAR_PATH .= "/" unless $STAR_PATH =~ /\/$/;
}
if($SCRIPTS_PATH) {
    $SCRIPTS_PATH .= "/" unless $SCRIPTS_PATH =~ /\/$/;
}
$BWA_PATH .= "/" unless $BWA_PATH =~ /\/$/;
$READS_PATH .= "/" unless $READS_PATH =~ /\/$/;

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


# ----------- REMOVE REGULAR MATCHES (if specified) ----------
print "STATUS: Beginning match weed-out\n";
if($STAR_PATH) {
    print "\tSTATUS: beginning to pre-align with STAR.\n";
    foreach my $id (@ids) {
	my $starCommand = "${STAR_PATH}STAR ";
	$starCommand .= "--genomeDir $GENOME_PATH ";
	$starCommand .= "--readFilesIn $READS_PATH$id/${id}.fq ";
	$starCommand .= "--runThreadN $NTHREADS " if $NTHREADS;
	$starCommand .= "--outFilterMultimapNmax 10000 ";
	$starCommand .= "--outSAMunmapped Within ";
	$starCommand .= "--outFilterMatchNminOverLread .75";
	my $starErr = system($starCommand);
	die "ERROR: call ($starCommand) failed with status $starErr. Exiting.\n\n" if $starErr;
	    
	system("mv Aligned.out.sam $READS_PATH$id/STAR_aligned.sam");
	
	print "\tSTATUS: successfully pre-aligned $id with STAR.\n"  if $verbose;
	    
	my $unmatchCommand = "${PERL_PREFIX}unmatchedFromSAM.pl ";
	$unmatchCommand .= "--fastq-file $READS_PATH$id/${id}.fq ";
	$unmatchCommand .= "--sam-file $READS_PATH$id/STAR_aligned.sam ";
	$unmatchCommand .= "> $READS_PATH$id/filtered.fq";
	my $unmatchErr = system($unmatchCommand);
	die "ERROR: call ($unmatchCommand) failed with status $unmatchErr. Exiting.\n\n" if $unmatchErr;
	
	print "\tSTATUS: successfully removed STAR matches for $id.\n" if $verbose;
	
	
    }
}
print "STATUS: Finished match weed-out\n\n";
# ----------- done removing regular matches ----------


foreach my $id (@ids) {
    # ----------- ALIGN TO SHUFFLED DATABASE -----------
    print "STATUS: Aligning to shuffled exon database.\n";
    my $bwaCommand = $BWA_PATH;
    $bwaCommand .= "bwa aln $EXON_DATABASE ";
    $bwaCommand .= "$READS_PATH$id/filtered.fq";
    $bwaCommand .= " > $READS_PATH$id/BWA_reads.sai";
    my $bwaErr = system($bwaCommand);
    die "ERROR: call ($bwaCommand) failed with status $bwaErr. Exiting.\n\n" if $bwaErr;
	
    my $bwaCommand2 = $BWA_PATH;
    $bwaCommand2 .= "bwa samse $EXON_DATABASE ";
    $bwaCommand2 .= "$READS_PATH$id/BWA_reads.sai ";
    $bwaCommand2 .= "$READS_PATH$id/filtered.fq ";
    $bwaCommand2 .= "> $READS_PATH$id/aligned.sam";
    my $bwaErr2 = system($bwaCommand2);
    die "ERROR: call ($bwaCommand2) failed with status $bwaErr2. Exiting.\n\n" if $bwaErr2;

    print "\tSTATUS: Aligned $id\n" if $verbose;

    
    print "STATUS: Done aligning to shuffled exon database.\n";
    # ----------- done aligning to shuffled database -----------
    
    
    # ----------- SELECT EXON-BOUNDARY CROSSING READS ----------
    print "STATUS: Selecting exon-boundary crossing reads for $id.\n";
    my $crossfiltCommand = $PERL_PREFIX;
    $crossfiltCommand .= "exonBoundaryCrossFilter.pl ";
    $crossfiltCommand .= "--exon-info-file ${READS_PATH}exon_info.txt ";
    $crossfiltCommand .= "--sam-file $READS_PATH$id/aligned.sam ";
    $crossfiltCommand .= "--min-overlap $MIN_OVERLAP " if $MIN_OVERLAP;
    $crossfiltCommand .= "> $READS_PATH$id/finalmatch.sam";
    my $crossfiltErr = system($crossfiltCommand);
    die "ERROR: call ($crossfiltCommand) failed with status $crossfiltErr. Exiting.\n\n" if $crossfiltErr;
    print "\tSTATUS: exonBoundaryCrossFilter ran successfully for $id\n" if $verbose;
    # ----------- done selecting exon-boundary crossing reads ----------


    # ----------- CONVERT TO FREQUENCY COLUMN ----------
    print "STATUS: Converting to frequency column.\n";
    my $freqCommand = $PERL_PREFIX;
    $freqCommand .= "samToSpreadsheetCol.pl ";
    $freqCommand .= "--sam-filename $READS_PATH$id/finalmatch.sam ";
    $freqCommand .= "--column-title $id ";
    $freqCommand .= "> $READS_PATH$id/frequencies.txt";
    my $freqErr = system($freqCommand);
    die "ERROR: call ($freqCommand) failed with status $freqErr. Exiting.\n\n" if $freqErr;
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
 --exon-database (-e) <version/>
     This specifies the shuffles exon index. Note
     that BWA's index command should be used to
     generate the other files in the directory.
     (This file should be a fasta file.)
 --reads-path (-r) <path/>
     This specifies the directory containing the
     ids.txt file and the files with the samples.
     
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
 --genome-path (-g) <name>
     Necessary if --star-prealign is specified.
 --thread-count (-t)
     How many threads should be used (while running
     STAR - the rest does not yet support threads.)
 --verbose (-v)
     If specified, prints out status messages.

"
}
