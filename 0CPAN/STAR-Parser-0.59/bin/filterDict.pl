#! /usr/local/bin/perl -w

###################################
#                                 #
# Script filterDict.pl            #
# Wolfgang Bluhm, SDSC            #
#                                 #
###################################

use STAR::Filter;
use strict;

my $dict = STAR::Dictionary->new($ARGV[0]);

my $dict_filtered = STAR::Filter->filter_dict(-dict=>$dict);

my $outname = $ARGV[0].'.filtered';
$dict_filtered->store($outname);

=head1 DESCRIPTION

 Reads the data structure of a dictionary (.cob file). Enters a very simple 
 interactive dialog that prompts the user for each save block in the dictionary
 whether to retain it. Outputs a new file (original .cob file + ".filtered").

=head1 USAGE

 perl filterDict.pl <dict.cob>

=cut

