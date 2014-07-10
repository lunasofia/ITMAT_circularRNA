ITMAT at UPenn
Garret FitzGerald Labs
Summer 2014
S. Luna Frank-Fischer

This pipeline searches for evidence of scrambled exons in RNA sequencing
data.

---------- HOW TO RUN THE PIPELINE ----------
First, if a shuffled exon database has not yet been created, run the
necessary scripts to build a shuffled exon database. (NOTE: this is
not yet complete - these scripts are still not fully functional!)

Also, to get the list of ribosomal IDs, see the process outlined at
https://github.com/itmat/Normalization and use the first step.

Also, make sure to have BWA installed. The path to run BWA must be 
specified in the command to run the pipeline.

Next, make sure that directories are in the following structure:

READS/
   |--- ids.txt
   |--- Sample_1/
	Sample_1_forward.fq
	   |--- Sample_1_reverse.fq
	   |--- Sample_1.ribosomalids.txt
   |--- Sample_2/
	   |--- Sample_2_forward.fq
	   |--- Sample_2_reverse.fq
	   |--- Sample_2.ribosomalids.txt

"READS/" can be replaced by any path, and is specified in the command.
"Sample_1" and "Sample_2" are both IDs, and could be any string (but no
two samples can have the same ID). The file ids.txt MUST be named ids.txt,
and contains a list of the IDs to be processed. In this example, then,
ids.txt would contain:

Sample_1
Sample_2

and no other lines.


---------- ABOUT THE PIPELINE ----------
The pipeline consists of the following main stages:
1. Remove rRNA matches
2. Remove regular matches with STAR (optional)
3. Normalize number of reads
4. Align to shuffled exon database
5. Select well-aligned entries (optional)
6. Remove entries not crossing exon-exon boundaries
7. Create frequency spreadsheet


---------- ABOUT THE PROJECT ----------
This is my summer internship project. I'm working at the Garret FitzGerald
lab at UPenn. I'm working under Greg Grant, whose help has been absolutely
crucial in creating this pipeline. I also received plenty of help from other 
members of Greg's team.
