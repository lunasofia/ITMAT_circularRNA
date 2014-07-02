This project is for my summer 2014 internship with ITMAT at UPenn.

The scripts work together with aligning software to find evidence of exon 
shuffling.

First, build a database of shuffled exons. To do this, start with a .fa file
of genes and exons. Feed this file to backwardsPairExonsV2.pl. (Version 2 does
a better job of getting rid of redundancy.) Its output is also in fa format,
but needs some modification (to make unique IDs - need to get rid of spaces.)

In order to match a sample to this database, do the following:

1. Start with a fastq file of sequenced RNA and a *regular* database for the
genome. Match up using star with the following commands:
--outSAMunmapped Within
--outFilterMultimapNmax 100000
--genomeDir yourgenomedir/
--readFilesIn yoursamples.fq
--outFilterMatchNminOverLread .75
(the match minimum can be adjusted depending on how much you want to filter)
This will give you an out file in SAM format.

2. Run unmatchedFromSam.pl with the SAM file and a the original fq file as
inputs. This spits out a fq file with the unmatched reads.

3. Align this fq file using BWA using the following two commands:
bwa aln exon-exon_shuffled.fa unmatched.out.fq > read.sai
bwa samse exon-exon_shuffled.fa read.sai unmatched.out.fq > aln.sam

4. Get rid of all but 100M (easy to do with grep).

5. Run exonExonCrossingCounter.pl with the exon info file (which is only the
title line, not the sequence, from the .fa file) and the sam file of unmatched
reads as input. This will output any reads which cross a reversed exon-exon
boundary by more than some number of base pairs. (That number can be adjusted
in the script.)

