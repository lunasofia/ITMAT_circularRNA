# File: runAll.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------
# Runs the full pipeline to search for shuffled exons. Tuned for
# running on the public data, which is already equalized in
# number of reads and also does not have forward and backward
# reads. In addition, the directory structure is slightly
# different, because this is used for so many reads. Finally, the
# reads have already been aligned with STAR and those alignment
# files are used.
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
# --ids-filename <filename>
#     So that the script can be run simultaneously with
#     different id sets, optionally takes in the name of
#     the id file. If none is given, assumes ids.txt is
#     the name of the file.
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
#     name of the genome. IF this is not specified,
#     then there must be sam files available, called
#     ID.sam within each ID directory.
# --genome-path (-g) <name>
#     Necessary if --star-prealign is specified.
# --thread-count (-t)
#     How many threads should be used (while running
#     STAR - the rest does not yet support threads.)    
# --blast-path <path/>
#     This specifies the path to BLAST and relevant
#     scripts. For example, this path could be
#     "/path/ncbi-blast-2.2.27+/" If this is not
#     specified, then the ribosomal and mitochondrial
#     RNAs will not be weeded out at all.
# --ribo-reference <name>
#     This is the first part of the name of the various
#     files used for eliminating the ribosomal RNA. The
#     files themselves must be in the folder specified
#     by the blast path. This is necessary if blast-path
#     is specified.
# --verbose (-v)
#     If specified, prints out status messages.


use strict;
use warnings;
use Getopt::Long;

my ($BWA_PATH, $BWA_VERSION, $EXON_DATABASE,
    $SCRIPTS_PATH, $MIN_OVERLAP, $READS_PATH,
    $IDS_FILENAME, $STAR_PATH, $GENOME_PATH, $NTHREADS,
    $BLAST_PATH, $RIBO_REF, $help, $verbose);
GetOptions('help|?' => \$help,
           'verbose' => \$verbose,
           'bwa-path=s' => \$BWA_PATH,
           'exon-database=s' => \$EXON_DATABASE,
           'reads-path=s' => \$READS_PATH,
           'scripts-path=s' => \$SCRIPTS_PATH,
           'min-overlap=i' => \$MIN_OVERLAP,
	   'ids-filename=s' => \$IDS_FILENAME,
	   'prealign-star=s' => \$STAR_PATH,
	   'genome-path=s' => \$GENOME_PATH,
	   'thread-count=i' => \$NTHREADS,
	   'blast-path=s' => \$BLAST_PATH,
	   'ribo-reference=s' => \$RIBO_REF);


# Make sure arguments were entered correctly. Also,
# add "/" to end of directory names if not already
# there.
&usage("help requested!") if $help;
&usage("missing required flag") unless ($BWA_PATH && $READS_PATH && $EXON_DATABASE);
if($STAR_PATH) {
    &usage("missing genome path") unless $GENOME_PATH;
    $GENOME_PATH .= "/" unless $GENOME_PATH =~ /\/$/;
    $STAR_PATH .= "/" unless $STAR_PATH =~ /\/$/;
}
if($BLAST_PATH) {
    &usage("missing ribo-reference") unless $RIBO_REF;
    # here we do NOT want the '/'
    $BLAST_PATH = substr $BLAST_PATH, 0, -1 if $BLAST_PATH =~ /\/$/;
}
if($SCRIPTS_PATH) {
    $SCRIPTS_PATH .= "/" unless $SCRIPTS_PATH =~ /\/$/;
}
$BWA_PATH .= "/" unless $BWA_PATH =~ /\/$/;
$READS_PATH .= "/" unless $READS_PATH =~ /\/$/;

# Prefix for each perl script
my $PERL_PREFIX = "perl ";
$PERL_PREFIX .= $SCRIPTS_PATH if $SCRIPTS_PATH;

# Default IDs filename
$IDS_FILENAME = "ids.txt" unless $IDS_FILENAME;

# List of IDs (populated from ids.txt)
my @ids;

# ----------- GET ID LIST ----------
my $ID_FILE = $READS_PATH . $IDS_FILENAME;
print "STATUS: Getting ID list from $ID_FILE\n";
open my $id_fh, '<', $ID_FILE or die "ERROR: could not open id file ($ID_FILE)\n";
while(<$id_fh>) {
    chomp($_);
    push @ids, $_;
}
close $id_fh;
print "STATUS: Successfully loaded ID list\n\n";
# ---------- done getting ID list ----------


# ---------- ALIGN WITH STAR ----------
if($STAR_PATH) {
    print "STATUS: beginning to pre-align with STAR.\n";
    foreach my $id (@ids) {
        my $starCommand = "${STAR_PATH}STAR ";
	$starCommand .= "--genomeLoad LoadAndKeep ";
        $starCommand .= "--genomeDir $GENOME_PATH ";
        $starCommand .= "--readFilesIn $READS_PATH$id/${id}.fq ";
        $starCommand .= "--runThreadN $NTHREADS " if $NTHREADS;
        $starCommand .= "--outSAMunmapped Within ";
        my $starErr = system($starCommand);
        die "ERROR: call ($starCommand) failed with status $starErr. Exiting.\n\n" if $starErr;

        system("mv Aligned.out.sam $READS_PATH$id/$id.sam");

        print "\tSTATUS: successfully pre-aligned $id with STAR.\n"  if $verbose;
    }
    my $clearStarCommand = "${STAR_PATH}STAR ";
    $clearStarCommand .= "--genomeLoad Remove";
    my $clearStarErr = system($clearStarCommand);
    die "ERROR: call ($clearStarCommand) failed with status $clearStarErr. Exiting.\n\n" if $clearStarErr;
    print "\tSTATUS: done removing genome from shared memory.\n" if $verbose;
    print "STATUS: done aligning with star.\n";
} else {
    print "STATUS: not pre-aligning with STAR (not specified).\n";
}
# ---------- done aligning with star ----------


# ---------- NORMALIZING ALL READS (if specified) ----------
if($BLAST_PATH) {
    print "STATUS: normalizing reads.\n";
    foreach my $id (@ids) {
    
	# --- first, use BLAST to find ribosomal IDs ---
	print "\tSTATUS: finding ribosomal IDs with BLAST for $id.\n" if $verbose;
	my $blastCommand = "perl $BLAST_PATH/runblast.pl ";
	my $readsPathTemp = substr $READS_PATH, 0, -1;
	$blastCommand .= "$id $readsPathTemp $id.sam ";
	$blastCommand .= "$BLAST_PATH $BLAST_PATH/$RIBO_REF";
	my $blastErr = system($blastCommand);
	die "ERROR: call ($blastCommand) failed with status $blastErr. Exiting.\n\n" if $blastErr;

	# --- then, get mitochondrial IDs from SAM file ---
	print "\tSTATUS: finding mitochondrial IDs for $id.\n" if $verbose;
	my $mitoCommand = "$PERL_PREFIX";
	$mitoCommand .= "getMitochondrialIDs.pl ";
	$mitoCommand .= "$READS_PATH$id/$id.sam ";
	$mitoCommand .= "> $READS_PATH$id/mitochondrialIDs.txt";
	my $mitoErr = system($mitoCommand);
	die "ERROR: call ($mitoCommand) failed with status $mitoErr. Exiting.\n\n" if $mitoErr;
	
	# --- generate file with ribo & mito ids removed ---
	print "\tSTATUS: removing ribosomal and mitochondrial reads.\n" if $verbose;
	system("cat $READS_PATH$id/mitochondrialIDs.txt $READS_PATH$id/$id.ribosomalids.txt > $READS_PATH$id/${id}_removeIDs.txt");
	my $normCommand = "$PERL_PREFIX";
	$normCommand .= "removeSetFromFQ ";
	$normCommand .= "--fq-file $READS_PATH$id/$id.fq ";
	$normCommand .= "--idlist-file $READS_PATH$id/${id}_removeIDs.txt ";
	$normCommand .= "> $READS_PATH$id/norm.fq";
	my $normErr = system($normCommand);
	die "ERROR: call ($normCommand) failed with status $normErr. Exiting\n\n" if $normErr;

    }
    print "STATUS: done normalizing reads.\n\n";
} else {
    print "STATUS: not normalizing reads (blast path not specified).\n\n";
    foreach my $id (@ids) {
	system("mv $READS_PATH$id/$id.fq $READS_PATH$id/norm.fq");
    }
}
# ---------- done normalization ----------


# ---------- EQUALIZING NUMBER OF READS ----------
print "STATUS: Equalizing numbers of reads\n";
my $minNumReads;
foreach my $id (@ids) {
    # Count lines                                                                                                                                                               
    my $lineCount = 0;
    open my $fq_fh, '<', "$READS_PATH$id/norm.fq" or die "ERROR\n";
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
    $cutCommand .= "randSubset.pl ";
    $cutCommand .= "--fq-filename $READS_PATH$id/norm.fq ";
    $cutCommand .= "--n-output-entries $minNumReads ";
    $cutCommand .= "--n-lines-per-entry 4 ";
    $cutCommand .= " > $READS_PATH$id/equalized.fq";
    my $cutErr = system($cutCommand);
    die "ERROR: call ($cutCommand) failed with status $cutErr. Exiting.\n\n" if $cutErr;
    print "\tSTATUS: Equalized $id.\n" if $verbose;
    
    system("rm $READS_PATH$id/norm.fq");
}
print "STATUS: Done equalizing number of reads\n\n";
# ---------- done equalizing ----------



foreach my $id (@ids) {
    print "STATUS: working on id $id.\n";

    # ----------- REMOVE REGULAR MATCHES ----------
    print "STATUS: Removing STAR-aligned matches ($id).\n";
    
    my $unmatchedCommand = "${PERL_PREFIX}unmatchedFromSAM.pl ";
    $unmatchedCommand .= "--fastq-file $READS_PATH$id/equalized.fq ";
    $unmatchedCommand .= "--sam-file $READS_PATH$id/$id.sam ";
    $unmatchedCommand .= "> $READS_PATH$id/weeded.fq";
    my $unmatchedErr = system($unmatchedCommand);
    die "ERROR: call ($unmatchedCommand) failed with status $unmatchedErr. Exiting.\n\n" if $unmatchedErr;
    
    print "\tSTATUS: successfully removed STAR matches ($id).\n" if $verbose;
	
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
 Reason for usage message: $_[0]

 Necessary Flags:
 --bwa-path <path/>
     This specifies the path to BWA. If, to run
     BWA, you would write ../stuff/bwa/bwa-0.7.9a/bwa
     then path should be \"../stuff/bwa/bwa-0.7.9a/\"
 --exon-database <version/>
     This specifies the shuffles exon index. Note
     that BWA's index command should be used to
     generate the other files in the directory.
     (This file should be a FastA file.)
 --reads-path <path/>
     This specifies the directory containing the
     ids.txt file and the files with the samples.

 Optional Flags:
 --ids-filename <filename>
     So that the script can be run simultaneously with
     different id sets, optionally takes in the name of
     the id file. If none is given, assumes ids.txt is
     the name of the file.
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
     name of the genome. IF this is not specified,
     then there must be sam files available, called
     ID.sam within each ID directory
 --genome-path (-g) <name>
     Necessary if --star-prealign is specified.
 --thread-count (-t)
     How many threads should be used (while running
     STAR - the rest does not yet support threads.)
 --blast-path <path/>
     This specifies the path to BLAST and relevant
     scripts. For example, this path could be
     \"/path/ncbi-blast-2.2.27+/\"  If this is not
     specified, then the ribosomal and mitochondrial
     RNAs will not be weeded out at all.
 --ribo-reference <name>
     This is the first part of the name of the various
     files used for eliminating the ribosomal RNA. The
     files themselves must be in the folder specified
     by the blast path. This is necessary if blast-path
     is specified.
 --verbose (-v)
     If specified, prints out status messages.
"
}
