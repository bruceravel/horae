#! /usr/local/bin/perl -w

############################
#                          #
# Script write.pl          #
# Wolfgang Bluhm, SDSC     #
#                          #
############################

#Reads a .cob file (CIF object) and writes it as a CIF file

use STAR::DataBlock;
use STAR::Writer;
use strict;

if ( !$ARGV[0] || !$ARGV[1] ) {
    print "Usage:   write.pl <infile.cob> <outfile.cif>\n";
    exit;
}

my $data = STAR::DataBlock->new($ARGV[0]);
 
STAR::Writer->write_cif( -dataref=>$data,
                         -file=>$ARGV[1]   );

=head1 DESCRIPTION

 Reads in the data structure of a file or dictionary (.cob file), and writes it
 out as a .cif file.

=head1 USAGE

 perl write.pl <data.cob or dict.cob> <outfile.cif>

=cut

