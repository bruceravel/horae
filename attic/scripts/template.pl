#!/usr/bin/perl -w
######################################################################
## Feff input file template generator
##                                     copyright (c) 2000 Bruce Ravel
##                                          ravel@phys.washington.edu
##                            http://feff.phys.washington.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##      http://feff.phys.washington.edu/~ravel/software/atoms/
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it under the same terms as Perl
##     itself.
##
##     This program is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     Artistic License for more details.
## -------------------------------------------------------------------
######################################################################
my $cvs_info = '$Id: template.pl,v 1.1 2000/04/01 14:38:46 bruce Exp $ ';
## Time-stamp: <2000/03/09 10:08:25 bruce>
######################################################################
## This simple script reads an ATP file describing an empty template
## for a feff input file and writes out the empty template.  This is
## intended to be useful for running feff on non-crystalline compounds
## where one wants a good feff.inp file but needs to type in the
## coordinates by hand.
######################################################################
## Code:

##use lib '/usr/local/share/ifeffit/perl';
use strict;
use Xray::Xtal;
$Xray::Xtal::run_level = 0;
use Xray::Atoms qw(build_cluster rcfile_name);
use Xray::ATP; # qw(parse_atp);

## =============================== process command line switches
use Getopt::Std;
use vars qw(%opt);
$opt{o} = "";
getopts('678qho:', \%opt);
if ($opt{h}) {
  require Pod::Text;
  $^W=0;
  if ($Pod::Text::VERSION < 2.0) {
    Pod::Text::pod2text($0, *STDOUT);
  } elsif ($Pod::Text::VERSION >= 2.0) {
    my $parser = Pod::Text->new;
    open STDIN, $0;
    $parser->parse_from_filehandle;
  };
  exit;
};
my $atp = "template6";
($Xray::Atoms::meta{prefer_feff_eight}) and $atp = "template8";
$opt{6} and $atp = "template6";
$opt{7} and $atp = "template7";
$opt{8} and $atp = "template8";


## =============================== screen messages
my $v = (split(" ", $cvs_info))[2];
my $date = (split(" ", $cvs_info))[3];
my $screen_line = "=" x 71;

print STDOUT <<EOH
$screen_line
 Feff template generator $v ($^O) $date
$screen_line
EOH
unless ($opt{q});


## =============================== empty data structures
my $cell = Xray::Xtal::Cell -> new();
my $keywords = Xray::Atoms -> new();
$keywords -> make('identity'=>"the Feff template generator", die=>0);

## =============================== make the template
my $contents = "";
my (@cluster, @neutral);
my ($default_name, $is_feff) =
  &parse_atp($atp, $cell, $keywords, \@cluster, \@neutral, \$contents);
next unless ($default_name);
my $outfile = $opt{o} || $default_name;
my $inputdir = './'; #        dirname($file);	# if write_to_pwd is false...
if ($keywords->{'write_to_pwd'}) {
  $outfile = $outfile;
} else {			# e.g. on Mac or Windows
  $outfile = File::Spec -> catfile($inputdir, $outfile);
};
($keywords->{"quiet"}) or
  print STDOUT " $atp: ",
  $$Xray::Atoms::messages{'writing'}, " ", $outfile, $/;
open (INP, ">".$outfile) or
  die $$Xray::Atoms::messages{cannot_write} . " " . $outfile . $/;
print INP $contents;
close INP;


## =============================== finish up
($opt{q}) or print STDOUT $screen_line, $/, $/;
1;


=head1 NAME

Template - make an empty feff.inp template

=head1 SYNOPSIS

   template [-678q] [-o file]

=head1 DESCRIPTION

This simple program writes an empty template for an input file for
feff6, feff7, or feff8.  This is useful in a situation where you need
a good feff.inp file for a material that is not a crystal and so you
need to fill in atom coordinates by hand.

 command line options
    -6, -7  feff6/feff7 input file
    -8      feff8 input file
    -q      suppress screen messages
    -h      print this help message
    -o *    write template to the specified file name

=head1 AUTHOR

  Bruce Ravel, ravel@phys.washington.edu
  http://feff.phys.washington.edu/~ravel
