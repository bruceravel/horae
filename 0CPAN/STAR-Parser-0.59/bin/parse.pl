#! /usr/local/bin/perl -w

###################################
#                                 #
# Script parse.pl                 #
# Wolfgang Bluhm, SDSC            #
#                                 #
###################################

# A simple application script for the 
# parsing module STAR::Parser     

use STAR::Parser;
use strict;
use Getopt::Std;
use vars qw($opt_d $opt_D $opt_l $opt_s);

my ($file, $dict, @objs, $obj, $title);
my $options = "";

getopt('');
$options .= 'd' if ( $opt_d );   #debug
$options .= 'l' if ( $opt_l );   #logfile
$dict = 1 if ( $opt_D );         #Dictionary

$file = $ARGV[0];

@objs = STAR::Parser->parse(-file=>$file,
                            -dict=>$dict, 
                            -options=>$options);

foreach $obj ( @objs ) {

    if ( $opt_s ) {                            # save data structure
        $title =($obj->title).".cob";
        $obj->store($title);
    }
} 

=head1 DESCRIPTION

 Parses a STAR-compliant file (e.g. .cif file or dictionary).
 Command line options including saving the parsed data structure

=head1 USAGE

 perl parse.pl [-dDls] <.cif file>

 -d  writes debugging log to STDERR 
 -D  file to be parsed is a dictionary
 -l  writes program activity log to STDERR
 -s  Saves each entry as a .cob file to disk

=cut
