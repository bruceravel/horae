#!/usr/bin/perl -w
######################################################################
## Tk utilities module for Atoms 3.0beta9
##                                     copyright (c) 1999 Bruce Ravel
##                                          ravel@phys.washington.edu
##                            http://feff.phys.washington.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##	    http://feff.phys.washington.edu/~ravel/software/atoms/
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

package Xray::Tk::Utils;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(tkatoms_make_tic tkatoms_fraction2canvas saveplot);
$cvs_info = '$Id: Utils.pm,v 1.2 2001/09/21 21:47:42 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

## ref to canvas, 'x' or 'y', percentage of full span, height in
## pixels of tic
sub tkatoms_make_tic {
  my ($canvas, $width, $height, $axis, $value, $size) = @_;
  my ($x1, $y1, $x2, $y2);
  if ($axis eq 'x') {
    $value *= ($width-36-11);
    $x1 = int($value)+36;
    $y1 = $height-21;
    $x2 = int($value)+36;
    $y2 = $height-21-$size;
  } else {
    $value *= $height-21-11;
    $value  = $height-21-11-int($value);
    $x1 = 36;
    $y1 = $value+11;
    $x2 = 36+$size;
    $y2 = $value+11;
  };
  $$canvas -> createLine($x1, $y1, $x2, $y2);
  1;
}

sub tkatoms_fraction2canvas {
  my ($width, $height, $x, $y) = @_;
  $x  = $x*($width-36-11) + 36;
  $y *= $height-21-11;
  $y  = $height-21-11 - $y + 11;
  return (sprintf("%d", $x), sprintf("%d", $y));
};


sub saveplot {
  require Xray::Tk::Plotter;
  my $format = $_[0];
  my $fname;
  if (lc($_[1]) eq 'dafs') {
    $fname =
      join("", 'dafs_', (map {sprintf "%d", $_} @{$::keywords->{'qvec'}}),
	   ".", lc($format));
  } elsif (lc($_[1]) eq 'powder') {
    $fname = "powder." . lc($format);
  };
  &Xray::Tk::Plotter::saveplot($format, $fname);
};


1;
__END__
