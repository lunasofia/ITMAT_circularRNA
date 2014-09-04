ITMAT at UPenn
Garret FitzGerald Labs
Summer 2014
S. Luna Frank-Fischer

This pipeline searches for evidence of scrambled exons in RNA sequencing
data.

---------- PREPARING TO RUN THE PIPELINE ----------
First, if a shuffled exon database has not yet been created, run
backwardsPairExons.pl to build the fasta-format database. Then,
run BWA's scripts to create the other files necessary for BWA to
run.

If you need to perform the normalization step, you must download
BLAST. You also need the ribosomal database for the organism
you are looking at. Finally, you need runblast.pl and parseblastout.pl
from https://github.com/itmat/Normalization/tree/master/norm_scripts.
These should both be inside the BLAST directory (which contains
sub-directories like bin/ and doc/).

You also must have BWA, STAR, and BLAST.

Next, make sure that directories are in the following structure:

 READS/
   |--- ids.txt
   |--- exon_info.txt
   |--- Sample_1/
           |--- Sample_1.fq
           |--- Sample_1.sam (optional)
	   |--- Sample_1_removeIDs.txt (optional)
   |--- Sample_2/
           |--- Sample_2.fq
           |--- Sample_2.sam (optional)
	   |--- Sample_2_removeIDs.txt (optional)

Note that READS can be replaced by any directory path, as specified.

In addition, the sam files are necessary if STAR is not specified, and
will be used instead of generating pre-alignment with STAR.

Similarly, the removeIDs file (which has a list of IDs to remove from the
fastq file, one ID per line) is only necessary if the general normalization
pipeline is not specified (by including a path for BLAST). Note that if no
normalization is desired, this file could be empty. However, the files will
still be normalized for size.

---------- RUNNING THE PIPELINE ----------
 Necessary Flags:
 --bwa-path </path/>
     This specifies the path to BWA. If, to run
     BWA, you would write /path/bwa/bwa-0.7.9a/bwa
     then path should be "/path/bwa/bwa-0.7.9a/"
 --exon-database </path/version/>
     This specifies the shuffles exon index. Note
     that BWA's index command should be used to
     generate the other files in the directory.
     (This file should be a FastA file.) This is
     the full path, for example:
     "/path/bwa/index/file.fa"
 --reads-path </path/>
     This specifies the directory containing the
     ids.txt file and the files with the samples.
     Should be a full path, for example:
      "/path/reads/"

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
     the path should be "../stuff/star/". The STAR
     directory must also contain, in index/, the
     name of the genome. IF this is not specified,
     then there must be sam files available, called
     ID.sam within each ID directory.
 --genome-path </path/dir/>
     Necessary if --star-prealign is specified. This
     is the full path to the directory containing the
     genome information. For example:
     "/path/star/index/mm9/"
 --thread-count <n>
     How many threads should be used (while running
     STAR - the rest does not support threads.) This
     does nothing unless STAR is specified.
 --blast-path <path/>
     This specifies the path to BLAST and relevant
     scripts. For example, this path could be
     "/path/ncbi-blast-2.2.27+/" If this is not
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


---------- ABOUT THE PIPELINE ----------
The pipeline consists of the following main stages:
1. Pre-aligns fastq files with the regular genome, using
   STAR. (Unless this alignment has already been done,
   in which case uses previously generated SAM files.)
2. Normalizes the reads by finding and removing reads
   aligning with ribosomal and mitochondrial genomes.
   (Unless this has already been done, in which case
   uses previously generated list of IDs to throw out.)
3. Equalizes the number of reads in each file. Uses
   random selection.
4. Removes regular matches (using star-aligned SAM file)
5. Aligns to database of shuffled exon-exon boundaries.
6. Selects reads that cross an exon-exon boundary by the
   specified margin
7. Creates a spreadsheet of number of events for a particular
   exon-exon boundary in each sample.

---------- ABOUT THE PROJECT ----------
This is my summer internship project. I'm working at the Garret FitzGerald
lab at UPenn. I'm working under Greg Grant, whose help has been absolutely
crucial in creating this pipeline. I also received plenty of help from other 
members of Greg's team, especially Katherina Hayer and Eun Ji Kim. Anand
Srinivasan helped me with various questions about git and unix.
