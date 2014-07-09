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

my ($MATCHES_FILE, $EXON_FILE, @SAM_FILES, $help);
GetOptions('sam-filename=s' => \@SAM_FILES,
	   'matches-spreadsheet=s' => \$MATCHES_FILE,
	   'exon-database=s' => \$EXON_FILE,
	   'help|?' => \$help);

&usage if $help;
&usage unless ($MATCHES_FILE && $EXON_FILE);

sub usage {
    die "
Looks up information associated with a boundary between
two exons, given various files of information.

Necessary flags:
--matches-spreadsheet (-m)
--exon-database (-e)

Optional flags:
--sam-filename (-s)
     as many SAM files as desired can be specified by
     repeating this flag.
"
}
