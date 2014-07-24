# File: makeIDsList.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# -----------------------------------
# This is a quick script to make a list of all the IDs for
# reads within a folder. NOTE that the ID folders should be
# the ONLY directories in the directory given.

use strict;
use warnings;

my $READS_PATH = $ARGV[0];

opendir(my $dh, $READS_PATH) or die "ERROR: could not open directory $READS_PATH.\n";
while(my $file = readdir($dh)) {
    next unless (-d "$READS_PATH/$file");
    next if ($file =~ /^\./);

    print "$file\n";
}
closedir($dh);

sub usage {
    die "
Usage: perl makeIDsList.pl path/to/reads/

"}
