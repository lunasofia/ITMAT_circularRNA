# File: lookupBoundary.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# ---------------------------------------
# Looks up information associated with a boundary between
# two exons, given various files of information.
#
# Information that can be looked up:
# Using the spreadsheet of matches, looks up the correct
# row in the spreadsheet.
# Using the exon information database, looks up the exon
# locations and lengths.
#
# For each SAM file given (using the --sam-filename flag),
# looks for an entry in that SAM file corresponding to
# the exon boundary. If none exists, prints out a message
# saying so. If it finds one, prints out information from
# that match. Does not look for multiple matches in one
# SAM file.

use strict;
use Getopt::Long;

my ($MATCHES_FILE, $EXONS_FILE, $BOUNDARY, @SAM_FILES, $help);
GetOptions('sam-filename=s' => \@SAM_FILES,
	   'matches-spreadsheet=s' => \$MATCHES_FILE,
	   'exon-database=s' => \$EXONS_FILE,
	   'boundary-name=s' => \$BOUNDARY,
	   'help|?' => \$help);

&usage if $help;
&usage unless ($MATCHES_FILE && $EXONS_FILE && $BOUNDARY);

print "\nLooking up information for $BOUNDARY\n\n";

# ---------------------------------
# GET INFORMATION FROM MATCHES FILE

print "Match frequencies from spreadsheet...\n";
open my $matches_fh, '<', $MATCHES_FILE or die "\nError: could not open matches file.\n";
my $matchFound;

# Get header info from beginning of file
my $firstLine = <$matches_fh>;
chomp($firstLine);
my @headerVals = split(" ", $firstLine);

# Iterate through file until match is found
while(my $line = <$matches_fh>) {
    chomp($line);
    my @vals = split(" ", $line);
    if($vals[0] eq $BOUNDARY) {
	for(my $i = 1; $i <= $#headerVals; $i++) {
	    print "\t$headerVals[$i]: $vals[$i]\n";
	}
	$matchFound = 1;
	last;
    }
}
print "\tno matches found. check syntax.\n" unless $matchFound;
print "\n";

# ---------------------------------
# GET INFORMATION FROM EXON DATABASE

print "Information about exons...\n";

# Some constants to represent indices into the exons file
my $E_GENE_NAME = 0;
my $E_EXON_NUM = 2;
my $E_EXON_START = 4;
my $E_EXON_END = 5;

# Splitting gene name to more easily match exon database format
my @boundaryVals = split("-", $BOUNDARY);

# Look through exon file for a match

my $firstExonLine;
my $secondExonLine;

# Keep track of exon lengths for use in SAM file info
# gathering
my $firstExonLen;
my $secondExonLen;

open my $exons_fh, '<', $EXONS_FILE or die "\nError: could not open exon database.\n";
while(my $line = <$exons_fh>) {
    next unless($line =~ $boundaryVals[0]); # only look at line if chance of success
    
    chomp($line);
    my @vals = split(" ", $line);
    next unless("$vals[$E_GENE_NAME]" eq ">$boundaryVals[0]");
    
    if($boundaryVals[1] == $vals[$E_EXON_NUM]) {
	$firstExonLen = $vals[$E_EXON_END] - $vals[$E_EXON_START];
	$firstExonLine = $line;
    }
    if($boundaryVals[2] == $vals[$E_EXON_NUM]) {
	$secondExonLen = $vals[$E_EXON_END] - $vals[$E_EXON_START];
	$secondExonLine = $line;
    }
}
close $exons_fh;

# Print out relevant information
if($firstExonLine) {
    print "\tFirst exon: $firstExonLine (length: $firstExonLen)\n";
} else {
    print "\tFirst exon not found.\n";
}
if($secondExonLine) {
    print "\tSecond exon: $secondExonLine  (length: $secondExonLen)\n";
} else {
    print "\tSecond exon not found.\n";
}
print "\n";

# ---------------------------------
# GET INFORMATION FROM SAM FILES

print "Information from SAM files...\n";
my $S_QNAME = 0;
my $S_RNAME = 2;
my $S_POS = 3;
my $S_SEQ = 9;
foreach my $SAM_FILE (@SAM_FILES) {
    my $samFound;
    open my $sam_fh, '<', $SAM_FILE or die "Error: could not open $SAM_FILE\n";
    while(my $line = <$sam_fh>) {
	# skip header lines, which start with '@'
	next if($line =~ /^@/);

	chomp($line);
	my @vals = split(" ", $line);
	
	next unless($vals[$S_RNAME] eq $BOUNDARY);
	
	my $firstExonOverlap = $firstExonLen - $vals[$S_POS];
	
	print "\tMatch in $SAM_FILE:\n";
	print "\t\tQuery ID: $vals[$S_QNAME]\n";
	print "\t\tStarting at position: $vals[$S_POS]\n";
	print "\t\tOverlap on first exon: $firstExonOverlap\n";
	print "\t\tSequence: $vals[$S_SEQ]\n";
	
	# Only find one match from each file
	$samFound = 1;
	last;
    }
    close $sam_fh;
    print "\tNo match in $SAM_FILE\n" unless $samFound;
}
print "\n";


sub usage {
    die "
Looks up information associated with a boundary between
two exons, given various files of information.

Necessary flags:
--matches-spreadsheet (-m)
     file containing names of exon junctions and the frequencies
     with which they appeared in various samples
--exon-database (-e)
     file containing names of exons and their locations on the
     genome. Same format as name line of fasta file.
--boundary-name (-b)
     in the format GENENAME-2-1 or something, where GENENAME is
     the name of the gene and the numbers are the exons. (Must
     be separated by dashes. Gene name cannot have dashes.)

Optional flags:
--sam-filename (-s)
     as many SAM files as desired can be specified by
     repeating this flag.
"
}
