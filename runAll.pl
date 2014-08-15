# File: runAll.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ----------------------------------------
# Runs the full pipeline to search for shuffled exons. For more
# information, read README.txt
# 
# The directories must be arranged in the following structure:
#
# READS/
#   |--- ids.txt
#   |--- exon_info.txt
#   |--- Sample_1/
#           |--- Sample_1.fq
#           |--- Sample_1.sam (optional)
#           |--- Sample_1_removeIDs.txt (optional)
#   |--- Sample_2/
#           |--- Sample_2.fq
#           |--- Sample_2.sam (optional)
#           |--- Sample_2_removeIDs.txt (optional)
#
#
# Necessary Flags:
# --bwa-path </path/>
#     This specifies the path to BWA. If, to run
#     BWA, you would write /path/bwa/bwa-0.7.9a/bwa
#     then path should be "/path/bwa/bwa-0.7.9a/"
# --exon-database </path/version/>
#     This specifies the shuffles exon index. Note
#     that BWA's index command should be used to
#     generate the other files in the directory.
#     (This file should be a FastA file.) This is
#     the full path, for example:
#     "/path/bwa/index/file.fa"
# --reads-path </path/>
#     This specifies the directory containing the
#     ids.txt file and the files with the samples.
#     Should be a full path, for example:
#     "/path/reads/"
#
# Optional Flags:
# --ids-filename </path/filename>
#     So that the script can be run simultaneously with
#     different id sets, optionally takes in the name of
#     the id file. If none is given, assumes ids.txt is
#     the name of the file, and that the file is in the
#     reads directory. If specified, this should be the
#     full path.
# --scripts-path </path/>
#     This specifies the path to the file of scripts.
#     If unspecified, assumed to be in the present
#     directory.
# --min-overlap <n>
#     This specifies the minimum number of base pairs
#     that must cross an exon-exon boundary in order
#     to count the read as evidence of shuffles exons
# --prealign-star </path/>
#     If specified, pre-aligns with STAR. The path
#     to STAR must be specified. If, to run STAR,
#     you would write ../stuff/star/STAR then the
#     the path should be "../stuff/star/". The STAR
#     directory must also contain, in index/, the
#     name of the genome. IF this is not specified,
#     then there must be sam files available, called
#     ID.sam within each ID directory.
# --genome-path </path/dir/>
#     Necessary if --star-prealign is specified. This
#     is the full path to the directory containing the
#     genome information. For example:
#     "/path/star/index/mm9/"
# --thread-count <n>
#     How many threads should be used (while running
#     STAR - the rest does not support threads.) This
#     does nothing unless STAR is specified.
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
# --conserve-space
#     If specified, the program will delete intermediate
#     files to conserve space. Even if specified, keeps
#     the star-aligned SAM files and original fq files.
# --verbose
#     If specified, prints out status messages.


use strict;
use warnings;
use Getopt::Long;

my ($BWA_PATH, $BWA_VERSION, $EXON_DATABASE,
    $SCRIPTS_PATH, $MIN_OVERLAP, $READS_PATH,
    $IDS_FILENAME, $STAR_PATH, $GENOME_PATH, $NTHREADS,
    $BLAST_PATH, $RIBO_REF, $CONSERVE_SPACE, $HELP, $VERBOSE);
GetOptions('help|?' => \$HELP,
           'verbose' => \$VERBOSE,
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
	   'ribo-reference=s' => \$RIBO_REF,
	   'conserve-space' => \$CONSERVE_SPACE);


# Make sure arguments were entered correctly. Also,
# add "/" to end of directory names if not already
# there.
&usage("help requested!") if $HELP;
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

# Set default ids filename unless specified
$IDS_FILENAME = "${READS_PATH}ids.txt" unless $IDS_FILENAME;

# List of IDs (populated from ids.txt)
my @ids;

# ----------- GET ID LIST ----------
print "STATUS: Getting ID list from $IDS_FILENAME\n";
open my $id_fh, '<', $IDS_FILENAME or die "ERROR: could not open id file ($IDS_FILENAME)\n";
while(<$id_fh>) {
    chomp;
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
	&run($starCommand);
	
        system("mv Aligned.out.sam $READS_PATH$id/$id.sam");

        print "\tSTATUS: successfully pre-aligned $id with STAR.\n"  if $VERBOSE;
    }

    # clear genome from memory
    my $clearStarCommand = "${STAR_PATH}STAR ";
    $clearStarCommand .= "--genomeDir $GENOME_PATH ";
    $clearStarCommand .= "--genomeLoad Remove";
    &run($clearStarCommand);
    print "\tSTATUS: done removing genome from shared memory.\n" if $VERBOSE;
    print "STATUS: done aligning with star.\n\n";
} else {
    print "STATUS: not pre-aligning with STAR (not specified).\n\n";
}
# ---------- done aligning with star ----------


# ---------- NORMALIZING ALL READS ----------
print "STATUS: normalizing reads.\n";
foreach my $id (@ids) {
    if($BLAST_PATH) {
    
	# --- first, use BLAST to find ribosomal IDs ---
	print "\tSTATUS: finding ribosomal IDs with BLAST for $id.\n" if $VERBOSE;
	my $blastCommand = "perl $BLAST_PATH/runblast.pl ";
	my $readsPathTemp = substr $READS_PATH, 0, -1;
	$blastCommand .= "$id $readsPathTemp $id.sam ";
	$blastCommand .= "$BLAST_PATH $BLAST_PATH/$RIBO_REF";
	&run($blastCommand);

	print "\tSTATUS: removing blast-generated temporary files.\n" if $VERBOSE;
	system("rm $READS_PATH$id/blast.out.1") if $CONSERVE_SPACE;
	system("rm $READS_PATH$id/temp.1") if $CONSERVE_SPACE;

	# --- then, get mitochondrial IDs from SAM file ---
	print "\tSTATUS: finding mitochondrial IDs for $id.\n" if $VERBOSE;
	my $mitoCommand = "$PERL_PREFIX";
	$mitoCommand .= "getMitochondrialIDs.pl ";
	$mitoCommand .= "$READS_PATH$id/$id.sam ";
	$mitoCommand .= "> $READS_PATH$id/mitochondrialIDs.txt";
	&run($mitoCommand);

	# --- generate file with ribo & mito ids removed ---
	print "\tSTATUS: removing ribosomal and mitochondrial reads.\n" if $VERBOSE;
	system("cat $READS_PATH$id/mitochondrialIDs.txt $READS_PATH$id/$id.ribosomalids.txt > $READS_PATH$id/${id}_removeIDs.txt");
    }
    
    # --- remove those IDs ---
    my $normCommand = "$PERL_PREFIX";
    $normCommand .= "removeSetFromFQ.pl ";
    $normCommand .= "--fq-file $READS_PATH$id/$id.fq ";
    $normCommand .= "--idlist-file $READS_PATH$id/${id}_removeIDs.txt ";
    $normCommand .= "> $READS_PATH$id/norm.fq";
    &run($normCommand);
    print "\tSTATUS: all unwanted IDs removed.\n" if $VERBOSE; 
}
print "STATUS: done normalizing reads.\n\n";
    
# ---------- done normalization ----------


# ---------- EQUALIZING NUMBER OF READS ----------
print "STATUS: Equalizing numbers of reads\n";
my $minNumReads;
foreach my $id (@ids) {
    # count number of lines
    my $lineCount = 0;
    open my $fq_fh, '<', "$READS_PATH$id/norm.fq" or die "ERROR\n";
    while(<$fq_fh>) {
	$lineCount++;
    }
    close $fq_fh;
    
    # update minimum if necessary
    my $nReads = $lineCount / 4;
    print "\tSTATUS: $id has length $lineCount and $nReads reads.\n" if $VERBOSE;
    $minNumReads = $nReads unless defined $minNumReads; # if first loop
    $minNumReads = $nReads if $nReads < $minNumReads;
}

print "\tSTATUS: Minimum number of reads is $minNumReads\n" if $VERBOSE;

foreach my $id (@ids) {
    my $cutCommand = $PERL_PREFIX;
    $cutCommand .= "randSubset.pl ";
    $cutCommand .= "--fq-filename $READS_PATH$id/norm.fq ";
    $cutCommand .= "--n-output-entries $minNumReads ";
    $cutCommand .= "--n-lines-per-entry 4 ";
    $cutCommand .= " > $READS_PATH$id/equalized.fq";
    &run($cutCommand);
    print "\tSTATUS: Equalized $id.\n" if $VERBOSE;
    
    system("rm $READS_PATH$id/norm.fq") if $CONSERVE_SPACE;
}
print "STATUS: Done equalizing number of reads\n\n";
# ---------- done equalizing ----------


foreach my $id (@ids) {
    print "STATUS: working on aligning to scrambled database (id: $id).\n";

    # ----------- REMOVE REGULAR MATCHES ----------
    print "\tSTATUS: Removing STAR-aligned matches ($id).\n" if $VERBOSE;
    
    my $unmatchedCommand = "${PERL_PREFIX}unmatchedFromSAM.pl ";
    $unmatchedCommand .= "--fastq-file $READS_PATH$id/equalized.fq ";
    $unmatchedCommand .= "--sam-file $READS_PATH$id/$id.sam ";
    $unmatchedCommand .= "> $READS_PATH$id/weeded.fq";
    &run($unmatchedCommand);

    print "\tSTATUS: successfully removed STAR matches ($id).\n" if $VERBOSE;
    # ----------- done removing regular matches ----------


    # ----------- ALIGN TO SHUFFLED DATABASE -----------
    print "\tSTATUS: Aligning to shuffled exon database ($id).\n" if $VERBOSE;
    my $bwaCommand = $BWA_PATH;
    $bwaCommand .= "bwa aln $EXON_DATABASE ";
    $bwaCommand .= "$READS_PATH$id/weeded.fq";
    $bwaCommand .= " > $READS_PATH$id/reads.sai";
    &run($bwaCommand);

    my $bwaCommand2 = $BWA_PATH;
    $bwaCommand2 .= "bwa samse $EXON_DATABASE ";
    $bwaCommand2 .= "$READS_PATH$id/reads.sai ";
    $bwaCommand2 .= "$READS_PATH$id/weeded.fq ";
    $bwaCommand2 .= "> $READS_PATH$id/shufflealigned.sam";
    &run($bwaCommand2);
    
    print "\tSTATUS: Done aligning to shuffled exon database ($id).\n" if $VERBOSE;
    # ----------- done aligning to shuffled database -----------
    
    
    # ----------- SELECT EXON-BOUNDARY CROSSING READS ----------
    print "\tSTATUS: Selecting exon-boundary crossing reads ($id).\n" if $VERBOSE;
    my $boundaryCommand = $PERL_PREFIX;
    $boundaryCommand .= "exonBoundaryCrossFilter.pl ";
    $boundaryCommand .= "--exon-info-file ${READS_PATH}exon_info.txt ";
    $boundaryCommand .= "--sam-file $READS_PATH$id/shufflealigned.sam ";
    $boundaryCommand .= "--min-overlap $MIN_OVERLAP " if $MIN_OVERLAP;
    $boundaryCommand .= "> $READS_PATH$id/finalmatch.sam";
    &run($boundaryCommand);
    
    print "\tSTATUS: Done selectiong exon-boundary crossing reads ($id).\n" if $VERBOSE;
    # ----------- done selecting for boundary-crossing ----------


    # ----------- CONVERT TO FREQUENCY COLUMN ----------
    print "\tSTATUS: Converting to frequency column ($id).\n" if $VERBOSE;
    my $freqCommand = $PERL_PREFIX;
    $freqCommand .= "samToSpreadsheetCol.pl ";
    $freqCommand .= "--sam-filename $READS_PATH$id/finalmatch.sam ";
    $freqCommand .= "--column-title $id ";
    $freqCommand .= "> $READS_PATH$id/frequencies.txt";
    &run($freqCommand);
    print "\tSTATUS: Done converting to frequency column ($id).\n" if $VERBOSE;
    # ----------- done converting to column ----------
}
print "STATUS: Finished ID-wise processing!\n\n";


# ---------- COMBINE INTO SINGLE FINAL SPREADSHEET ----------
print "STATUS: Combining into single final spreadsheet.\n\n";
my $finalCommand = $PERL_PREFIX;
$finalCommand .= "combineColumns.pl ";
foreach my $id (@ids) {
    $finalCommand .= "$READS_PATH$id/frequencies.txt ";
}
$finalCommand .= "> $READS_PATH/finalspreadsheet.txt";

&run($finalCommand);
print "STATUS: Done combining.\n\n";
# ---------- done combining into spreadsheet ----------


####################################################################

# Given a command, runs that command and fails with an appropriate error message if necessary.
sub run {
    my $err = system($_[0]);
    die "ERROR: call ($_[0]) failed with status $err. Exiting.\n\n" if $err;
}


sub usage {
die "
 Reason for usage message: $_[0]

 Necessary Flags:
 --bwa-path </path/>
     This specifies the path to BWA. If, to run
     BWA, you would write /path/bwa/bwa-0.7.9a/bwa
     then path should be \"/path/bwa/bwa-0.7.9a/\"
 --exon-database </path/version/>
     This specifies the shuffles exon index. Note
     that BWA's index command should be used to
     generate the other files in the directory.
     (This file should be a FastA file.) This is
     the full path, for example:
     \"/path/bwa/index/file.fa\"
 --reads-path </path/>
     This specifies the directory containing the
     ids.txt file and the files with the samples.
     Should be a full path, for example:
      \"/path/reads/\"

 Optional Flags:
 --ids-filename </path/filename>
     So that the script can be run simultaneously with
     different id sets, optionally takes in the name of
     the id file. If none is given, assumes ids.txt is
     the name of the file, and that the file is in the
     reads directory. If specified, this should be the
     full path.
 --scripts-path </path/>
     This specifies the path to the file of scripts.
     If unspecified, assumed to be in the present
     directory.
 --min-overlap <n>
     This specifies the minimum number of base pairs
     that must cross an exon-exon boundary in order
     to count the read as evidence of shuffles exons
 --prealign-star </path/>
     If specified, pre-aligns with STAR. The path
     to STAR must be specified. If, to run STAR,
     you would write ../stuff/star/STAR then the
     the path should be \"../stuff/star/\". The STAR
     directory must also contain, in index/, the
     name of the genome. IF this is not specified,
     then there must be sam files available, called
     ID.sam within each ID directory.
 --genome-path </path/dir/>
     Necessary if --star-prealign is specified. This
     is the full path to the directory containing the
     genome information. For example:
     \"/path/star/index/mm9/\"
 --thread-count <n>
     How many threads should be used (while running
     STAR - the rest does not support threads.) This
     does nothing unless STAR is specified.
 --blast-path <path/>
     This specifies the path to BLAST and relevant
     scripts. For example, this path could be
     \"/path/ncbi-blast-2.2.27+/\" If this is not
     specified, then the ribosomal and mitochondrial
     RNAs will not be weeded out at all.
 --ribo-reference <name>
     This is the first part of the name of the various
     files used for eliminating the ribosomal RNA. The
     files themselves must be in the folder specified
     by the blast path. This is necessary if blast-path
     is specified.
 --conserve-space
     If specified, the program will delete intermediate
     files to conserve space. Even if specified, keeps
     the star-aligned SAM files and original fq files.
 --verbose
     If specified, prints out status messages.

"
}
