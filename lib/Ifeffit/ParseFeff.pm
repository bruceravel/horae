package Ifeffit::ParseFeff;                  # -*- cperl -*-
######################################################################
## Ifeffit::ParseFeff: Class methods for parsing Feff6L's runtime
##                     messages
##
##                     Artemis is copyright (c) 2001-2006 Bruce Ravel
##                                                     bravel@anl.gov
##                            http://feff.phys.washington.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2006 Matt Newville
##                                         newville@cars.uchicago.edu
##                        http://cars.uchicago.edu/~newville/ifeffit/
##
##            Feff6L is Copyright (c) [2002] University of Washington
##                              http://feff.phys.washington.edu/feff/
##
##	  The latest version of Artemis can always be found at
##	 http://feff.phys.washington.edu/~ravel/software/exafs
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of Argonne National Laboratory, The
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
use vars qw($VERSION $nchecks @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();


## attempt to recognize the problem with feff by recognizing some
## phrase in its run time messages, return an index indicating the
## problem
$nchecks = 12; # this must equal the number of checks in recognize
sub recognize {
  shift;
  my $text = $_[0];
  return 1  if ($text =~ /No atoms or overlap cards/);
  return 2  if ($text =~ /at PATHSD:\s+no input/);
  return 3  if ($text =~ /not recognized as an internal/);
  return 5  if ($text =~ /Too many atoms in ATOMS list/);
  return 6  if ($text =~ /NO ATOMS CLOSE ENOUGH TO OVERLAP/);
  return 7  if ($text =~ /No absorbing atom \(ipot=0\) defined/);
  return 7  if ($text =~ /More than one absorbing atom \(ipot=0\)/);
  return 8  if ($text =~ /Unique potential\s+\d+\s+not allowed/);
  return 8  if ($text =~ /Unique potential index\s+\d+\s+out of range./);
  return 8  if ($text =~ /Unique potentials must be between\s+\d+\s+and\s+\d+/);
  return 9  if ($text =~ /TWO ATOMS VERY CLOSE TOGETHER/);
  return 10 if ($text =~ /Error reading input, bad line follows/);
  return 11 if ($text =~ /Internal path finder limit exceeded/);
  return 12 if (0);		# feff7, iprint4<>3
  return 0;
};


## return a lengthy diagnostic message based on the index returned by
## the recognized method.  mmmm.... closure-licious
sub describe {
  shift;
  my $err = $_[0];
  my $exists = 0;
  map {++$exists if ($err == $_)} (1 .. $nchecks);
  return "" unless $exists;
  return eval '&error_' . $err ;
};

## this error happens when the potentials list contains atoms not
## represented in the atoms list
sub error_1 {
  return <<EOH1

      This error may be due to the Atoms list in the the Feff input
      file being too short to contain an example of each unique
      potential.

      Another possibility is that there are gaps in the Potentials
      list.  Every potential index defined in the Potentials list must
      be used in the Atoms list, and you may not skip Potential
      indeces.

      Possible solutions include increasing the Rmax on the Atoms page
      and re-running both Atoms and Feff, or editing the Potentials
      and Atoms lists such that the indeces are sequential.

EOH1
  ;
};

## this error happens when Rmax is shorter than the nearest neighbor
sub error_2 {
  return <<EOH2

      This error is probably due to Rmax being too small
      in the feff.inp file.  Rmax should at least be larger
      than the distance to the nearest atom.

      Try increasing the Rmax on the feff.inp page and
      re-running Feff.

EOH2
  ;
};

## this error happens when the feff->feff_executable variable is set
## incorrectly on windows
sub error_3 {
  return <<EOH3

      This error is probably due to having Artemis configured
      incorrectly and so it does not know how to run Feff on
      your computer.

      Try clicking on the Settings menu, then selecting
      "Edit preferences".  On the Preferences page, click on the
      little plus sign next to the "Feff" category then select
      "feff_executable" in the list.  Then edit the value of this
      variable to be the name of the Feff executable on your
      computer.  Finally, press the "Save changes" button at the
      bottom of the page.

      If you are using the version of Feff6 that comes with the
      Ifeffit package, the correct value for this variable is
      "feff6l" (that's the letter l, and not the number 1).  If
      you are using some other version of Feff, you should enter
      the fully resolved (i.e. C:/path/to/feff.exe) filename
      as the value for this parameter.

EOH3
  ;
};

## this error happens when the feff->feff_executable variable is set
## incorrectly on unix-ish systems
sub error_4 {
  return <<EOH4

      This error is probably due to having Artemis configured
      incorrectly and so it does not know how to run Feff on
      your computer.

      Try clicking on the Settings menu, then selecting
      "Edit preferences".  On the Preferences page, click on the
      little plus sign next to the "Feff" category then select
      "feff_executable" in the list.  Then edit the value of this
      variable to be the name of the Feff executable on your
      computer.  Finally, press the "Save changes" button at the
      bottom of the page.

      If you are using the version of Feff6 that comes with the
      Ifeffit package, the correct value for this variable is
      "feff6".  If you are using some other version of Feff, you
      will enter the fully resolved (i.e. /path/to/feff) filename
      as the value for this parameter if that version of Feff is
      not in the path.

EOH4
  ;
};

## this happens when the atoms list is too long for the way Feff is
## compiled
sub error_5 {
  return <<EOH5

    This error is probably due to having a list of atoms in your
    feff.inp file that is longer than the compiled-in length
    allowed for the atoms list in your version of Feff.  (The
    limit in the version of Feff6 that comes with Ifeffit is 500.)
    There are two possible resolutions to this problem.  (1) Reduce
    the Rmax parameter in Atoms and run Atoms again.  (2) Manually
    edit the atoms list in the feff.inp file to have fewer than 500
    atoms and run Feff again.

EOH5
  ;
};

## this happens when the atoms are too far apart for overlapping to
## work properly
sub error_6 {
  return <<EOH6

    This error is due to Feff finding atoms which are too far from
    other atoms, resulting in a failure of the algorithm that
    constructs the muffin-tin potential surface.  Common causes of
    this include lattice parameters in Atoms which are too large
    and neglecting some items from the atoms list in Atoms.  Often
    the neglected atom is hydrogen, which is very hard to see in
    EXAFS analysis, but which can be quite important when running
    Feff.

    To resolve this problem, verify that your cyrstal parameters are
    valid, then rerun Atoms.

EOH6
  ;
};

sub error_7 {
  return <<EOH7

    This error indicates that you have failed to set an absorbing
    atom by not setting one and only one site in the Atoms list to
    have potential index 0.  It is an error in Feff to set no sites
    to be potential index 0.  It is also an error to set 2 or more
    sites to be potential index 0.

    To resolve this problem, choose one site in the Atoms list to
    be the absorber and set the number in the fourth column to be 0.

EOH7
  ;
};

sub error_8 {
  return <<EOH8

    This error indicates that you have attempted to set more than 7
    unique potentials.  7 is Feff's hard-wired limit on the number of
    potentials.

    There are several situations that might lead to this problem.
    If your material has more than 7 atomic species, you might
    consider removing the hydrogen atoms or combining similar atoms
    (such as O and N) into a single atom type.

    If you are using an Atoms template file which uses site tags to
    set the unique potentials, then you should combine atomic species
    (for example all oxygen sites) into a single tag.

EOH8
  ;
};


sub error_9 {
  return <<EOH9

    This warning indicates a problem in the Atoms list.  For some
    reason you have atoms that are separated by than 0.93 Angstroms
    (or 1.75 Rydberg).

    This may be due to the presence of hydrogen atoms in your feff.inp
    file, in which case this is an innocuous warning and may be ignored.

    However, this may indicate a problem constructing the Atoms
    list. The most common cause of this problem is a mistake in the
    crystallographic data used on the Atoms page.  You may have
    incorrect values for lattice constants or angles or incorrect
    values for site coordinates.  You may need a shift vector to move
    the lattice into its standard setting.

    Please be aware that Atoms works with 5 digits of precision.
    Thus, if you have a site with a coordinate of 1/3, you should use
    either "1/3" or "0.33333" on the Atoms page.  Using insufficient
    precision, say "0.333" is a common cause of this error message.

    Artemis has continued on the possibility that the warning is
    caused by hydrogen atoms, but be warned that the feff.inp may
    require your attention.

EOH9
  ;
};

sub error_10 {
  return <<EOH10

    This error indicates that Feff found a line in the input file that
    it could not understand.  Remove or fix the line indicated and run
    Feff again.

EOH10
  ;
};

sub error_11 {
  return <<EOH11

    Feff's path finder warned of reaching a memory limitation which
    caused it not to compute the complete list of paths for your
    cluster.  There are two ways to avoid this problem when running
    Feff.  One is to decrease the size of the RMAX parameter in the
    Feff input data.  The other is to have the Feff calculation not
    consider high order multiple scattering paths.  Putting "NLEG 4"
    in the Feff input data will limit Feff to compute only up to
    four-legged (triple scattering) paths.

EOH11
  ;
};

sub error_12 {
  return <<EOH12

    You just ran Feff but Artemis cannot find the feffNNNN.dat files.
    You seem to be using Feff7.  This is probably because the fourth
    argument to Feff's PRINT keyword is not set to 3, like so:

       PRINT  1  0  0  3

    Fix this, then rerun Feff.

EOH12
  ;
};

1;
__END__
