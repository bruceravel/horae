#! /usr/local/bin/perl -w 

#############################
#                           #
# Script keys.pl            #
#                           #
# Writes out a hierarchical #
# list of hash keys         #
#                           #
#############################

use strict;
use STAR::DataBlock;
use STAR::Dictionary;

my $data = STAR::DataBlock->new($ARGV[0]);

open (OUT, ">$ARGV[1]");
print OUT $data->get_keys;
close OUT;

=head1 DESCRIPTION

 Reads a data structure (.cob file). Outputs a file that contains a hierarchically 
 formatted list of all the hash keys (data blocks. save blocks, categories, items) 
 present in the data structure.

=head1 USAGE

 perl keys.pl <data.cob or dict.cob> <outfile>

=cut


