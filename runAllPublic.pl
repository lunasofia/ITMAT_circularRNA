# File: runAll.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------
# Runs the full pipeline to search for shuffled exons. Tuned for
# running on the public data, which is already equalized in
# number of reads and also does not have forward and backward
# reads. In addition, the directory structure is slightly
# different, because this is used for so many reads.
# 
# The directories must be arranged in the following structure:
#
# READS/
#   |--- ids.txt
#   |--- exon_info.txt
#   |--- Sample_1/
#           |--- Sample_1.fq
#   |--- Sample_2/
#           |--- Sample_2.fq
#
#
# Necessary Flags:
# --bwa-path <path/>
#     This specifies the path to BWA. If, to run
#     BWA, you would write ../stuff/bwa/bwa-0.7.9a/bwa
#     then path should be "../stuff/bwa/bwa-0.7.9a/"
# --exon-database <version/>
#     This specifies the shuffles exon index. Note
#     that BWA's index command should be used to
#     generate the other files in the directory.
#     (This file should be a FastA file.)
# --reads-path <path/>
#     This specifies the directory containing the
#     ids.txt file and the files with the samples.
#
# Optional Flags:
# --scripts-path <path/>
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


foreach my $id (@ids) {
    print "STATUS: working on id $id.\n";
    # ----------- REMOVE REGULAR MATCHES (if specified) ----------
    if($STAR_PATH) {
	print "STATUS: beginning to pre-align with STAR.\n";
	
	my $starCommand = "${STAR_PATH}STAR ";
	$starCommand .= "--genomeDir $GENOME_PATH ";
	$starCommand .= "--readFilesIn $READS_PATH$id/${id}.fq ";
	$starCommand .= "--runThreadN $NTHREADS " if $NTHREADS;
	$starCommand .= "--outFilterMultimapNmax 10000 ";
	$starCommand .= "--outSAMunmapped Within ";
	$starCommand .= "--outFilterMatchNminOverLread .75";
	my $starErr = system($starCommand);
	die "ERROR: call ($starCommand) failed with status $starErr. Exiting.\n\n" if $starErr;
	
	system("mv Aligned.out.sam $READS_PATH$id/");
	
	print "\tSTATUS: successfully pre-aligned $id with STAR.\n"  if $verbose;
	
	my $unmatchedCommand = "${PERL_PREFIX}unmatchedFromSAM.pl ";
	$unmatchedCommand .= "--fastq-file $READS_PATH$id/${id}.fq ";
	$unmatchedCommand .= "--sam-file $READS_PATH$id/Aligned.out.sam ";
	$unmatchedCommand .= "> $READS_PATH$id/weeded.fq";
	my $unmatchedErr = system($unmatchedCommand);
	die "ERROR: call ($unmatchedCommand) failed with status $unmatchedErr. Exiting.\n\n" if $unmatchedErr;
	
	print "\tSTATUS: successfully removed STAR matches for $id.\n" if $verbose;
	
    } else {
	print "\tSTATUS: not pre-aligning with STAR (not specified).\n" if $verbose;
	system("cp -l $READS_PATH$id/${id}.fq $READS_PATH$id/weeded.fq");
    }
    # ----------- done removing regular matches ----------


    # ----------- ALIGN TO SHUFFLED DATABASE -----------
    print "STATUS: Aligning to shuffled exon database ($id).\n";
    my $bwaCommand = $BWA_PATH;
    $bwaCommand .= "bwa aln $EXON_DATABASE ";
    $bwaCommand .= "$READS_PATH$id/weeded.fq";
    $bwaCommand .= " > $READS_PATH$id/reads.sai";
    my $bwaErr = system($bwaCommand);
    die "ERROR: call ($bwaCommand) failed with status $bwaErr. Exiting.\n\n" if $bwaErr;
    
    my $bwaCommand2 = $BWA_PATH;
    $bwaCommand2 .= "bwa samse $EXON_DATABASE ";
    $bwaCommand2 .= "$READS_PATH$id/reads.sai ";
    $bwaCommand2 .= "$READS_PATH$id/weeded.fq ";
    $bwaCommand2 .= "> $READS_PATH$id/shufflealigned.sam";
    my $bwaErr2 = system($bwaCommand2);
    die "ERROR: call ($bwaCommand2) failed with status $bwaErr2. Exiting.\n\n" if $bwaErr2;
    
    print "STATUS: Done aligning to shuffled exon database ($id).\n";
    # ----------- done aligning to shuffled database -----------
    
    
    # ----------- SELECT EXON-BOUNDARY CROSSING READS ----------
    print "STATUS: Selecting exon-boundary crossing reads ($id).\n";
    my $command = $PERL_PREFIX;
    $command .= "exonBoundaryCrossFilter.pl ";
    $command .= "--exon-info-file ${READS_PATH}exon_info.txt ";
    $command .= "--sam-file $READS_PATH$id/shufflealigned.sam ";
    $command .= "--min-overlap $MIN_OVERLAP " if $MIN_OVERLAP;
    $command .= "> $READS_PATH$id/finalmatch.sam";
    my $err = system($command);
    die "ERROR: call ($command) failed with status $err. Exiting.\n\n" if $err;
    print "\tSTATUS: exonBoundaryCrossFilter ran successfully\n" if $verbose;
    
    print "STATUS: Done selectiong exon-boundary crossing reads ($id).\n\n";
    # ----------- done selecting for boundary-crossing ----------


    # ----------- CONVERT TO FREQUENCY COLUMN ----------
    print "STATUS: Converting to frequency column ($id).\n";
    my $command2 = $PERL_PREFIX;
    $command2 .= "samToSpreadsheetCol.pl ";
    $command2 .= "--sam-filename $READS_PATH$id/finalmatch.sam ";
    $command2 .= "--column-title $id ";
    $command2 .= "> $READS_PATH$id/frequencies.txt";
    my $err2 = system($command2);
    die "ERROR: call ($command2) failed with status $err2. Exiting.\n\n" if $err2;
    print "\tSTATUS: samToSpreadsheetCol ran successfully.\n" if $verbose;
    print "STATUS: Done converting to frequency column ($id).\n\n";
    # ----------- done converting to column ----------
}

print "STATUS: Finished ID-wise processing!\n\n";


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
 --bwa-path <path/>
     This specifies the path to BWA. If, to run
     BWA, you would write ../stuff/bwa/bwa-0.7.9a/bwa
     then path should be \"../stuff/bwa/bwa-0.7.9a/\"
 --exon-database <version/>
     This specifies the shuffles exon index. Note
     that BWA's index command should be used to
     generate the other files in the directory.
     (This file should be a fasta file.)
 --reads-path <path/>
     This specifies the directory containing the
     ids.txt file and the files with the samples.
     
 Optional Flags:
 --scripts-path <path/>
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
 --remove-rrna
     If specified, removes rRNA matches. If this is
     not specified, then no rRNA ID files must be
     specified.   
 --verbose (-v)
     If specified, prints out status messages.

"
}