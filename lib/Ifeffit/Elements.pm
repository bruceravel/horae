package Ifeffit::Elements;	# -*- cperl -*-
######################################################################
## Ifeffit::Elements: Element manipulation utilities for Athena
##
##                      Athena is copyright (c) 2001-2006 Bruce Ravel
##                                                     bravel@anl.gov
##                            http://feff.phys.washington.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2006 Matt Newville
##                                         newville@cars.uchicago.edu
##                       http://cars9.uchicago.edu/~newville/ifeffit/
##
##	  The latest version of Athena can always be found at
##	 http://feff.phys.washington.edu/~ravel/software/exafs
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of The Naval Research Laboratory, The
##     University of Chicago, University of Washington, or the authors
##     appear in advertising or endorsement of works derived from this
##     software without specific prior written permission from all
##     parties.
##
##     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
##     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
##     OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
##     NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
##     HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
##     WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
##     FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
##     OTHER DEALINGS IN THIS SOFTWARE.
## -------------------------------------------------------------------
######################################################################

use strict;
use vars qw($VERSION $cvs_info $module_version @ISA @EXPORT @EXPORT_OK);
use Chemistry::Elements qw/get_name get_symbol/;
use Xray::Absorption;
Xray::Absorption -> load("elam");

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

$VERSION = '0.00';
$cvs_info = '$Id: $ ';
$module_version = (split(' ', $cvs_info))[2] || 'pre_release';


my @k1 = ();
foreach (5..25) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @k1, [command=>"$_ $name ($sym)",
	     -command=>[\&Ifeffit::Elements::set_e0, $sym, 'K']];
};
my @k2 = ();
foreach (26..50) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @k2, [command=>"$_ $name ($sym)",
	     -command=>[\&Ifeffit::Elements::set_e0, $sym, 'K']];
};
my @k3 = ();
foreach (51..75) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @k3, [command=>"$_ $name ($sym)",
	     -command=>[\&Ifeffit::Elements::set_e0, $sym, 'K']];
};
my @k4 = ();
foreach (76..84) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @k4, [command=>"$_ $name ($sym)",
	     -command=>[\&Ifeffit::Elements::set_e0, $sym, 'K']];
};

my @l31;
foreach (15..25) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @l31, [command=>"$_ $name ($sym)",
	      -command=>[\&Ifeffit::Elements::set_e0, $sym, 'L3']];
};
my @l32;
foreach (26..50) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @l32, [command=>"$_ $name ($sym)",
	      -command=>[\&Ifeffit::Elements::set_e0, $sym, 'L3']];
};
my @l33;
foreach (51..75) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @l33, [command=>"$_ $name ($sym)",
	      -command=>[\&Ifeffit::Elements::set_e0, $sym, 'L3']];
};
my @l34;
foreach (76..94) {
  my ($name, $sym) = (get_name($_), get_symbol($_));
  push @l34, [command=>"$_ $name ($sym)",
	      -command=>[\&Ifeffit::Elements::set_e0, $sym, 'L3']];
};

use vars qw/@element_menu/;
@element_menu = ([cascade => "K-edge: B-Mn",   -tearoff=>0,
		  -menuitems=>\@k1],
		 [cascade => "K-edge: Fe-Sn",  -tearoff=>0,
		  -menuitems=>\@k2],
		 [cascade => "K-edge: Sb-Re",  -tearoff=>0,
		  -menuitems=>\@k3],
		 [cascade => "K-edge: Os-Po",  -tearoff=>0,
		  -menuitems=>\@k4],
		 "-",
		 [cascade => "L3-edge: P-Mn",  -tearoff=>0,
		  -menuitems=>\@l31],
		 [cascade => "L3-edge: Fe-Sn", -tearoff=>0,
		  -menuitems=>\@l32],
		 [cascade => "L3-edge: Sb-Re", -tearoff=>0,
		  -menuitems=>\@l33],
		 [cascade => "L3-edge: Os-Pu", -tearoff=>0,
		  -menuitems=>\@l34]);



sub set_e0 {
  my $en = Xray::Absorption->get_energy(@_);
  &::set_e0($en, @_);
};

1;
__END__
