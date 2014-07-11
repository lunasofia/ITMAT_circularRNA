# File: runMakeSpreadsheet.pl
# Author: S. Luna Frank-Fischer
# ITMAT at UPenn
# --------------------------------------
# Given a list of IDs, makes the spreadsheet of all the
# results. This is a beta version; will be better and
# more general in final full pipeline.

use strict;
use warnings;

my $colfile_list = "";
foreach my $id (@ARGV) {
    `perl ITMAT_circularRNA/samToSpreadsheetCol.pl -s unnormalized_datasets/$id/finalMatches_all.sam -c $id > unnormalized_datasets/$id/finalMatches_all.col`;
    $colfile_list .= " unnormalized_datasets/$id/finalMatches_all.col";
}

`perl ITMAT_circularRNA/combineColumns.pl $colfile_list > combinedSpreadsheet_all.txt`;
