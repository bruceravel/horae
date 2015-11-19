#! /usr/local/bin/perl -w

###################################
#                                 #
# Script filter.pl                #
# Wolfgang Bluhm, SDSC            #
#                                 #
###################################

use STAR::Filter;
use strict;

my $data = STAR::DataBlock->new($ARGV[0]);
my $dict = STAR::Dictionary->new($ARGV[1]);

my $out = STAR::Filter->filter_through_dict(-data=>$data,
                                            -dict=>$dict);

my $outname = $ARGV[0].'.filtered';
$out->store($outname);

=head1 DESCRIPTION

 Reads a data structure (.cob file) and filters it through a dictionary (.cob file).
 Only items present in the dictionary are retained in the file.
 Outputs a new data structure file (.cob file -- original name + ".filtered").

=head1 USAGE

 perl filter.pl <data.cob> <dict.cob>

=cut


