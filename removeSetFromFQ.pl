# File: removeSetFromFQ.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -------------------------------------------
# Takes in as the first parameter a fastq files.
# Takes in as the second parameter a file of
# ID for searches (separated by newlines, no @
# symbol prefix).
#
# Outputs a fastq with the entries corresponding
# to those IDs removed.

my ($FQ_FILE, $IDLIST_FILE) = @ARGV;

my %idlist = ();

# Read list of IDs into hash
open my $idlist_fh, '<', $IDLIST_FILE;
while(<$idlist_fh>) {
    chomp($_);
    $idlist{ "\@$_" } = 1;
}
close $idlist_fh;

my $FQ_NUMLINES = 4;
open my $fq_fh, '<', $FQ_FILE;
while(<$fq_fh>) {
    # skip if not an ID line or ID is in map
    next if($. % $FQ_NUMLINES != 1);
    my @idline_arr = split(" ", $_);
    my $id = $idline_arr[0];
    next if($idlist{ "$id" });

    print "$_";
    for(my $i = 1; $i < $FQ_NUMLINES; $i++) {
	my $contentLine = <$fq_fh>;
	chomp($contentLine);
	print "$contentLine\n";
    }
}
close $fq_fh;
