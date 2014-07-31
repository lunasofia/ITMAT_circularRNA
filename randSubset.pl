# File: randSubset.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ---------------------------------------------
# Using reservoir sampling, selects a random set of an
# fq file and writes it out, generating a new fq file
# with a set number of entries.
#
# Description of reservoir sampling found on wikipedia.
# http://en.wikipedia.org/wiki/Reservoir_sampling

use strict;
use warnings;
use Getopt::Long;

my $help;
my $FQ_FILE;
my $N_OUT;
my $LINES_PER_ENTRY;

GetOptions('help|?' => \$help,
	   'fq-filename=s' => \$FQ_FILE,
	   'n-output-entries=i' => \$N_OUT,
	   'n-lines-per-entry=i' => \$LINES_PER_ENTRY);

<<<<<<< HEAD:randSubset.pl
&usage unless ($FQ_FILE && $N_OUT && $LINES_PER_ENTRY);
=======
&usage unless ($FQ_FILE);
&usage unless defined $N_OUT;
>>>>>>> develop:randSubsetFromFQ.pl

# Hash to hold the fq entries. After adding enough and
# swapping according to algorithm, prints to file.
# Each entry is a reference to an array (the four lines
# of the fq entry). Reservoir is of set size to hold the
# $N_OUT entries to be printed.
my @reservoir;
$#reservoir = $N_OUT - 1;

my $curEntryNum = 0;

open my $fq_fh, '<', $FQ_FILE or die "\nError: could not open fq file.\n";
while(my $entry = <$fq_fh>) {
    # Fill the entry with all lines from entry
    for (my $i = 1; $i < $LINES_PER_ENTRY; $i++) {
	$entry .= <$fq_fh>;
    }
    chomp($entry); # so no final \n, only in between
    
    # If still in reservoir-filling stage
    if($curEntryNum < $N_OUT) {
	$reservoir[$curEntryNum] = $entry;
	$curEntryNum++;
	next;
    }

    # Get a random number between 0 and curEntryNum-1 (inclusive).
    my $random = int(rand($curEntryNum));
    if($random < $N_OUT) {
	$reservoir[$random] = $entry;
    }
    
    $curEntryNum++;
}


# Print out the reservoir to standard out.
print(join("\n", @reservoir));

sub usage {
    die "
 Prints a random selection of lines from the given fastq file
 to standard out. Takes in the fastq file and the number of
 lines to print.

 Usage: perl randSubsetFromFQ.pl --fq-filename=\"filename.fq\" --n-output-entries=1000 --n-lines-per-entry=4

"
}
