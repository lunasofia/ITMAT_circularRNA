# File: runAll.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------
# Runs the full pipeline to search for shuffled exons.
# 
# The directories must be arranged in the following structure:
#
# READS/
#   |---ids.txt
#   |---exon_info.txt
#   |--- Sample_1/
#           |--- Sample_1.fq
#           |--- Sample_1.sam
#           |--- Sample_1_removeIDs.txt
#   |--- Sample_2/
#           |--- Sample_2.fq
#           |--- Sample_2.sam
#           |--- Sample_2_removeIDs.txt
#
# Note that the remove id files are only necessary if the
# flag normalize-fully is specified.
# More detailed specifications are in README.txt.
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
# --normalize-fully
#     If specified, removes rRNA and mitochondrial  matches.
#     If this is not specified, then no rRNA ID or
#     mitochondrial ID files must be specified.   
# --verbose (-v)
#     If specified, prints out status messages.


use strict;
use warnings;
use Getopt::Long;

my ($BWA_PATH, $EXON_DATABASE,
    $SCRIPTS_PATH, $MIN_OVERLAP, $READS_PATH,
    $NORMALIZE, $help, $verbose);
GetOptions('help|?' => \$help,
           'verbose' => \$verbose,
           'bwa-path=s' => \$BWA_PATH,
           'exon-database=s' => \$EXON_DATABASE,
           'reads-path=s' => \$READS_PATH,
           'scripts-path=s' => \$SCRIPTS_PATH,
           'min-overlap=i' => \$MIN_OVERLAP,
	   'normalize-fully' => \$NORMALIZE);


# Make sure arguments were entered correctly. Also,
# add "/" to end of directory names if not already
# there.
&usage if $help;
&usage unless ($BWA_PATH && $READS_PATH);
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


print "STATUS: Beginning match weed-out\n";
foreach my $id (@ids) {
    
    # ----------- REMOVE rRNA AND MITOCHONDRIAL MATCHES (if specified) ----------
    if($NORMALIZE) {
	print "\tSTATUS: Removing rRNA and mitochondrial matches for $id\n" if $verbose;
	system("mv $READS_PATH$id/${id}.fq $READS_PATH$id/original.fq");
	
	my $weedCommand = $PERL_PREFIX;
	$weedCommand .= "removeSetFromFQ.pl ";
	$weedCommand .= "--fq-file $READS_PATH$id/original.fq";
	$weedCommand .= "--idlist-file $READS_PATH$id/${id}_removeIDs.txt";
	$weedCommand .= " > $READS_PATH$id/weeded.fq";
	my $weedErr = system($weedCommand);
	die "ERROR: call ($weedCommand) failed with status $weedErr. Exiting.\n\n" if $weedErr;
	
	print "\tSTATUS: Done removing rRNA and mitochondrial matches for $id\n" if $verbose;
    } else {
	print "\tSTATUS: Not removing rRNA or mitochondrial (not specified)\n" if $verbose;
    }
    # ----------- done removing rRNA and mitochondrial matches ----------

}

# ----------- EQUALIZE NUMBER OF READS -----------
print "STATUS: Equalizing numbers of reads\n";

my $minNumReads;
foreach my $id (@ids) {
    # Count lines
    my $lineCount = 0;
    open my $fq_fh, '<', "$READS_PATH$id/weeded.fq" or die "ERROR\n";
    while(<$fq_fh>) {
	$lineCount++;
    }
    close $fq_fh;
    
    # Update min if necessary
    my $nReads = $lineCount / 4;	
    print "\tSTATUS: $id has length $lineCount and $nReads reads.\n" if $verbose;
    
    $minNumReads = $nReads unless defined $minNumReads; # if first loop
    $minNumReads = $nReads if $nReads < $minNumReads;
}

print "\tSTATUS: Minimum number of reads is $minNumReads\n" if $verbose;

foreach my $id (@ids) {
    my $cutCommand = $PERL_PREFIX;
    $cutCommand .= "randSubsetFromFQ.pl ";
    $cutCommand .= "--fq-filename $READS_PATH$id/weeded.fq ";
    $cutCommand .= "--n-output-entries $minNumReads";
    $cutCommand .= " > $READS_PATH$id/equalized.fq";
    my $cutErr = system($cutCommand);
    die "ERROR: call ($cutCommand) failed with status $cutErr. Exiting.\n\n" if $cutErr;
    print "\tSTATUS: Equalized $id.\n" if $verbose;
}
print "STATUS: Done equalizing number of reads\n\n";
# ----------- done equalizing number of reads -----------
    

# ----------- REMOVE REGULAR MATCHES (if specified) ----------
foreach my $id (@ids) {
	
    my $starCommand = "${PERL_PREFIX}unmatchedFromSAM.pl ";
    $starCommand .= "--fastq-file $READS_PATH$id/equalized.fq ";
    $starCommand .= "--sam-file $READS_PATH$id/$id.sam ";
    $starCommand .= "> $READS_PATH$id/starUnmatched.fq";
    my $starErr = system($starCommand);
    die "ERROR: call ($starCommand) failed with status $starErr. Exiting.\n\n" if $starErr;
    
    print "\tSTATUS: successfully removed STAR matches for $id.\n" if $verbose;
    # ----------- done removing regular matches ----------


    # ----------- ALIGN TO SHUFFLED DATABASE -----------
    print "STATUS: Aligning to shuffled exon database.\n";
    my $BWAcommand = $BWA_PATH;
    $BWAcommand .= "bwa aln $EXON_DATABASE ";
    $BWAcommand .= "$READS_PATH$id/starUnmatched.fq";
    $BWAcommand .= " > $READS_PATH$id/reads.sai";
    my $BWAerr = system($BWAcommand);
    die "ERROR: call ($BWAcommand) failed with status $BWAerr. Exiting.\n\n" if $BWAerr;
    
    my $BWAcommand2 = $BWA_PATH;
    $BWAcommand2 .= "bwa samse $EXON_DATABASE ";
    $BWAcommand2 .= "$READS_PATH$id/reads.sai ";
    $BWAcommand2 .= "$READS_PATH$id/starUnmatched.fq ";
    $BWAcommand2 .= "> $READS_PATH$id/aligned.sam";
    my $BWAerr2 = system($BWAcommand2);
    die "ERROR: call ($BWAcommand2) failed with status $BWAerr2. Exiting.\n\n" if $BWAerr2;
    
    print "\tSTATUS: Aligned $id.\n" if $verbose;
    # ----------- done aligning to shuffled database -----------


    # ----------- SELECT EXON-BOUNDARY CROSSING READS ----------
    print "STATUS: Selecting exon-boundary crossing reads for $id.\n";
    my $crossCommand = $PERL_PREFIX;
    $crossCommand .= "exonBoundaryCrossFilter.pl ";
    $crossCommand .= "--exon-info-file ${READS_PATH}exon_info.txt ";
    $crossCommand .= "--sam-file $READS_PATH$id/aligned.sam ";
    $crossCommand .= "--min-overlap $MIN_OVERLAP " if $MIN_OVERLAP;
    $crossCommand .= "> $READS_PATH$id/finalmatch.sam";
    my $crossErr = system($crossCommand);
    die "ERROR: call ($crossCommand) failed with status $crossErr. Exiting.\n\n" if $crossErr;
    print "STATUS: Done selectiong exon-boundary crossing reads for $id.\n\n";
    # ----------- done selecting for boundary-crossing ----------


    # ----------- CONVERT TO FREQUENCY COLUMN ----------
    print "STATUS: Converting to frequency column.\n";
    my $colCommand = $PERL_PREFIX;
    $colCommand .= "samToSpreadsheetCol.pl ";
    $colCommand .= "--sam-filename $READS_PATH$id/finalmatch.sam ";
    $colCommand .= "--column-title $id ";
    $colCommand .= "> $READS_PATH$id/frequencies.txt";
    my $colErr = system($colCommand);
    die "ERROR: call ($colCommand) failed with status $colErr. Exiting.\n\n" if $colErr;
    print "\tSTATUS: samToSpreadsheetCol ran successfully.\n" if $verbose;
    print "STATUS: Done converting to frequency column.\n\n";
    # ----------- done converting to column ----------
}


# ---------- COMBINE INTO SINGLE FINAL SPREADSHEET ----------
print "STATUS: Combining into single final spreadsheet.\n";
my $sheetCommand = $PERL_PREFIX;
$sheetCommand .= "combineColumns.pl ";
foreach my $id (@ids) {
    $sheetCommand .= "$READS_PATH$id/frequencies.txt ";
}
$sheetCommand .= "> $READS_PATH/finalspreadsheet.txt";

my $sheetErr = system($sheetCommand);
die "ERROR: call ($sheetCommand) failed with status $sheetErr. Exiting.\n\n" if $sheetErr;
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
 --remove-rrna
     If specified, removes rRNA matches. If this is
     not specified, then no rRNA ID files must be
     specified.   
 --verbose (-v)
     If specified, prints out status messages.

"
}
