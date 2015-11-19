#! /usr/local/bin/perl -w

#########################
#                       #
# Script check.pl       #
# Wolfgang Bluhm, SDSC  #
#                       #
#########################

# a simple application script for the module STAR::Checker

use STAR::Checker;
use strict;
use Getopt::Std;
use vars qw($opt_d $opt_l);

my ($data, $dict, $options, $check);
$options="";

getopt('');
$options .= 'd' if ( $opt_d );   #debug
$options .= 'l' if ( $opt_l );   #log

if ( !$ARGV[0] || !$ARGV[1] ) {
    print "Usage:   check.pl [-dl] DataBlock Dictionary\n";
    exit;
}

$data = STAR::DataBlock->new($ARGV[0]);
$dict = STAR::Dictionary->new($ARGV[1]);

$check=STAR::Checker->check(-datablock=>$data,
                            -dictionary=>$dict,
                            -options=>$options);

print STDERR "Checker found ", $check?"no ":"", "problems.\n";

=head1 DESCRIPTION

 Checks the data representation of a cif file (.cob file) against 
 a specified dictionary (.cob file).

=head1 USAGE

 perl check.pl [-dl] <data.cob> <dict.cob>

 -d write debug information to STDERR
 -l write activity log to STDERR

=cut

