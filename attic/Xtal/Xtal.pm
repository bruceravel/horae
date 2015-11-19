#! /usr/bin/perl -w
######################################################################
##  This module is copyright (c) 1998-2004 Bruce Ravel
##  <ravel@phys.washington.edu>
##  http://feff.phys.washington.edu/~ravel/software/Xray/
##  http://feff.phys.washington.edu/~ravel/software/atoms/
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
##
######################################################################
##
## This is the Xray::Xtal.pm module.  It contains the Xtal, Cell, and
## Site packages which are used to define objects for a unit cell and
## a unique site in a crystallography problem.  See the pod for usage
## details or the program Atoms for an implementation.
##
######################################################################
## Time-stamp: <1999-07-19 19:06:19 bruce>
######################################################################
## Code:

package Xray::Xtal;

=head1 NAME

Xray::Xtal - A Perl extension for crystallography data classes

=head1 SYNOPSIS

  use Xray::Xtal;

  my $cell = Xray::Xtal::Cell -> new();
  $cell -> make( Space_group=>"f m -3 m", A=>3.961, );

  my @sites;
  $sites[0] = Xray::Xtal::Site -> new();
  $sites[0] -> make( X=>0.0, Y=>0.0, Z=>0.0, Element=>"Cu" );

  $cell -> populate(\@sites);
  $cell -> verify_cell();

The preceding lines define a unit cell for FCC copper.


=head1 DESCRIPTION

Xray::Xtal is a module defining packages for unit cell and
crystallographic site objects useful in a crystallography problem.

As suggested in the synopsis, these objects are closely related to one
another.  In fact, the method of translating a unique site to a set of
symmetry-related sites requires a Cell object as an argument.
Similarly, the method of populating a unit cell requires a list of
Site objects as its argument.  Consequently it is very unusual to use
one of these classes and not the other.

In its current form, Xtal.pm is intended to solve simple
crystallography problems of the sort commonly encountered by the X-ray
absorption spectroscopist.  Given a description of a crystal in terms
of a space group symbol, axis lengths and angles, and the fractional
coordinates of the unique crystallographic sites, F<Xtal.pm> is used
to describe the entire contents of the unit cell either in fractional
or Cartesian coordinates.

To this end, two packages are included in Xtal.pm which define two
data classes.  One is a Cell and the other is a Site.  Alone,
F<Xtal.pm> provides only these data classes.  This, however, is the
basis of several useful applications.  The initial use of this module
is to create lists of atomic coordinates of the sort needed for
ball-and-stick figures or real-sapce multiple scattering calculations
(which is the reason F<Xtal.pm> was created).  F<Xtal.pm> can also be
useful, for example, for powder diffraction or anomalous scattering
simulations.

F<Xtal.pm> obtains its crystallography data from a database which
comes with the distribution.  The space groups database is stored to
disk using the C<Storable> module with portable binary ordering.  This
choice allows both speed and networked applicability.

The following CPAN modules may not be part of a normal perl
installation, but are needed by F<Xtal.pm>:

  Storable,  File::Spec,  Chemistry::Elements

=head1 THE CELL AND SITE PACKAGES.

=cut
;

## use Safe;
## Storable:
use Storable;
##end Storable:
##MLDBM:
## use MLDBM qw(DB_File Storable);
## use Fcntl;
##end MLDBM:

use File::Spec;
use Ifeffit::FindFile;
my $data_dir = Xray::Xtal::identify_self();
my $dbfile = ($Ifeffit::FindFile::is_windows) ?
  Ifeffit::FindFile->find("atoms", "space_group_db") :
  File::Spec->catfile($data_dir, "space_groups.db");
##Storable:
use vars qw($r_space_groups);
$r_space_groups = retrieve($dbfile);
##end Storable:
##MLDBM:
## tie my %space_groups, 'MLDBM', $dbfile, O_RDONLY or die $!;
## my $r_space_groups = \%space_groups;
##end MLDBM:




######################################################################

use strict;
use Carp;
use vars qw($VERSION $cvs_info $cvs_version $sg_version
	    @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
## @EXPORT_OK = qw();
$cvs_info = '$Id: Xtal.pm,v 1.30 2001/09/21 18:17:11 bruce Exp $ ';
$cvs_version = (split(' ', $cvs_info))[2];
$VERSION = 0.31;
$sg_version = $$Xray::Xtal::r_space_groups{'version'};

use vars qw($run_level $xtal_warnings $xtal_fatals);
$run_level = 0; # 0 = command line (warn is ok)
		# 1 = Tk (always die, never warn)
		# 2 = CGI (no error channel, use storage bins)
                # 3 = testing (no error channel, use storage bins, fragile)

## these are bins for storing warning and error messages.  they are
## used in situations where STDERR is not convenient, such as CGI.
## they are cleared each time a new cell item is created.
$xtal_warnings = "";
$xtal_fatals   = "";

## method for getting attributes of a Site or Cell object
## this is the sole method in the Xray::Xtal class and is
## inherited by both the Site and Cell classes.
## input:  a list of attributes
## output: a list of attribute values in the order specified on input.
##         an unknown attribute returns undef.
sub attributes {
  my $self = shift;
  my @ret = ();
  foreach my $att (@_) {
    if (exists($self->{ucfirst($att)})) {
      push @ret, $self->{ucfirst($att)} ;
    } else {
      push @ret, undef;
    };
  };
  return @ret;
};

## return the path to this file, this seems to be a pretty bomber way
## of doing that
sub identify_self {
  my @caller = caller;
  use File::Basename qw(dirname);
  return dirname($caller[1]);
};

## does the right thing for different run levels
sub trap_error {
  my ($message, $just_warn) = @_;
  if ($run_level == 0) {	# command line
    if ($just_warn) {
      warn $message, $/;
      return;
    } else {
      die $message, $/;
    };
  } elsif ($run_level == 1) {	# Tk
    $::top -> messageBox(-icon    => 'error',
			 -message => $message,
			 -title   => 'Atoms: Error',
			 -type    => 'OK');
    return;
  } elsif ($run_level == 2) {	# CGI
    if ($just_warn) {
      $xtal_warnings .= $message . $/;
    } else {
      $xtal_fatals .= $message . $/;
    };
  } elsif ($run_level == 3) {	# testing
    if ($just_warn) {
      $xtal_warnings .= $message . $/;
    } else {
      $xtal_fatals .= $message . $/;
    };
  } else {
    croak "Programmer error.  Invalid run level.  0=>cli, 1=>tk, 2=>cgi, 3=>test"
  };
};


## Internationalization:

use vars qw($languages $strings);
my $libdir = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
  Ifeffit::FindFile->find("atoms", "xray_lib") :
  File::Spec->catfile($data_dir, "lib");
my $languagerc = File::Spec->catfile($libdir, 'languages');

sub set_language {
  ##eval "do '$languagerc'" or warn "Language rc file not found.  Using English.$/";
  my $xtal_language;
  if (not $languages) {
    $xtal_language = File::Spec->catfile($libdir, "xtalrc.en");
  } else {
    $xtal_language = "xtalrc." . $$languages{lc($_[0])};
    $xtal_language = File::Spec->catfile($libdir, $xtal_language);
    unless (-e $xtal_language) {
      $xtal_language = File::Spec->catfile($libdir, "xtalrc.en");
    };
  };
  eval "do '$xtal_language'";	# read strings
};

&set_language("english");

1;

######################################################################

package Xray::Xtal::Cell;

use constant EPSILON => 0.00001;
use constant PI => 4*atan2(1,1);

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
require Xray::Xtal;

@ISA = qw(Exporter AutoLoader Xray::Xtal);
## @EXPORT_OK = qw();

use Carp;

# constructor for a new unit cell + initializations
sub new {
    my $classname = shift;
    my $self = {};
    $self->{Space_group} = "";	# supplied & calculated
    $self->{Given_group} = "";	#            calculated
    $self->{A}           = 0;	# supplied
    $self->{B}           = 0;	# supplied | calculated
    $self->{C}           = 0;	# supplied | calculated
    $self->{Alpha}       = 90;	# supplied | calculated
    $self->{Beta}        = 90;	# supplied | calculated
    $self->{Gamma}       = 90;	# supplied | calculated
    $self->{Angle}       = "";	#            calculated
    $self->{Setting}     = 0;	#            calculated
    $self->{Contents}    = 0;	#            calculated
    $self->{Bravais}     = ();	#            calculated
    $self->{Volume}      = 1;	#            calculated
    $self->{Txx}         = 0;	#            calculated
    $self->{Tyx}         = 0;	#            calculated
    $self->{Tyz}         = 0;	#            calculated
    $self->{Tzx}         = 0;	#            calculated
    $self->{Tzz}         = 0;	#            calculated
    $self->{Occupancy}   = 1;   # supplied
    bless($self, $classname);
    $Xray::Xtal::xtal_warnings = "";
    $Xray::Xtal::xtal_fatals   = "";
    return $self;
};

=head2 The Cell object

A unit cell is constructed by C<new();> and the attributes of the unit
cell are set using the C<make> method.  An example of the use of
C<make> to set the a lattice constant:

    $cell -> new() -> make( A=4.0 );

The attributes of the Cell object are stored internally as capitalized
words  i.e. words that begin with an upper case letter and have lower
case for the remaining letters, however the user is free to mix case
in any convenient manner.


The Cell attributes that can be set using C<make> are:

=over 4

=item B<A>

The a lattice constant.

=item B<B>

The b lattice constant.

=item B<C>

The c lattice constant.

=item B<Alpha>

The angle between the b and c lattice constants.

=item B<Beta>

The angle between the a and c lattice constants.

=item B<Gamma>

The angle between the a and b lattice constants.

=item B<Angle>

This takes the value of the most recently set angle.  This is only
needed for the peculiar situation of a monoclinic space group with all
three angles equal to 90.  The function determine monoclinic will not
be able to resolve the setting in that situation without a little
help.  The idea is that the user has to specify at least one angle in
order to unambiguously determine the setting.

=item B<Space_group>

A string specifying the space group of the cell. The supplied value is
stored in the C<Given_group> attribute and this is filled with the
canonical symbol.

=back

The bare minimum required to define is a cell is the a lattice
constant and the space group symbol.  All other attributes have
sensible defaults or are calculated quantities.  Of course, any space
group of lower than cubic symmetry will require that other axes and/or
angles be specified.

There are several other Cell attributes.  Except for the Contents
attribute, these are updated every time the C<make> method is called.
These include:

=over 4

=item B<Given_group>

The space group symbol used as the argument for
the C<Space_group> attribute when the C<make> method is called.

=item B<Setting>

The setting of a low symmetry space group.  See
below for a discussion of low symmetry space groups.

=item B<Contents>

This is an anonymous list of anonymous lists specifying the contents
of the fully decoded unit cell.  This attribute is set by caling the
C<populate> method.  Each list element is itself a list containing the
x, y, and z fractional coordinates of the site and a reference to the
Site obect which generated that site.  To examine the contents of the
cell, do something like this:

  my ($contents) = $cell -> attributes("Contents");
  foreach my $pos (@{$contents}) {
    printf "x=%8.5f, y=%8.5f, z=%8.5f$/",
      $$pos[0], $$pos[1], $$pos[2]
  };

=item B<Volume>

The volume of the unit cell computed from the axes and angles.

=item B<Txx>

The x-x element of the metric tensor computed from the axes and
angles.  This is used to translate from fractional to cartesian
coordinates.

=item B<Tyx>

The y-x element of the metric tensor computed from the axes and
angles.

=item B<Tyz>

The y-z element of the metric tensor computed from the axes and
angles.

=item B<Tzx>

The z-x element of the metric tensor computed from the axes and
angles.

=item B<Tzz>

The z-z element of the metric tensor computed from the axes and
angles.

=item other metric tensor elements

The yy element of the metric tensor is unity and the other three are
zero.

=back

C<Xray::Xtal::Cell> will only allow you to directly modify the lattice
constants and angles and the space group using the make method.  While
it is common for object definitions to allow the user to define new
attributes, that is not allowed for a Cell object.  There truly only
are 8 attributes of a Cell which the user should allowed to set.


=head2 Methods and Functions in the Cell Package

There are several other function that may be useful in your programs.
Some of these are methods and some are non-exported functions.  Except
as noted, these subroutines are from the C<Xray::Xtal::Cell> package.

=over 4

=item C<attributes>

Takes a list of attributes as its input and returns the values of the
attributes as a list in the same order as the input list of attribute
names.  The return value is always an array, even if only one element
is requested.  This is the sole method of the C<Xray::Xtal> package and
is inherited by both the Site and Cell packages.

  $cell -> Xray::Xtal::Cell::new()
     -> make("A"=>4.0, "B"=>4.3, "C"=>4.6)
  ($a, $b, $c) = $cell -> attributes("A", "B", "C");

  $site -> Xray::Xtal::Site::new()
     -> make("X"=>0.5, "Y"=>0.25, "Z"=>0)
  ($x, $y, $z) = $site -> attributes("X", "Y", "Z");

  print "$x, $y, $z, $a, $b, $c$/";
    |-> 0.5, 0.25, 0, 4.0, 4.3, 4.6

=back

=cut
;
## do error checking, canonicalize group, determine seting for low
## symmetry space groups, calculate volume and metric tensor elements,
## then return the current cell object basically this handles all
## attributes of a cell object except for Contents.  Use
## $cell->populate for that purpose.
sub make {
    my $self = shift;
    ($#_ % 2) || do {
	my $this = (caller(0))[3];
	croak "$this takes an even number of arguments";
	return; };
    my @attributes = qw(Space_group A B C Alpha Beta Gamma Angle Occupancy);
    ##my $epsilon = $Xray::Atoms::epsilon || 0.00001;

    while (@_) {
      my $att = ucfirst($_[0]);
      unless (grep /\b$att\b/, @attributes) {
	carp "$_[0] : You should not attempt to set this by hand";
	shift; shift;
      } else {
	if ($att eq "Space_group")  {
	  $self->{Given_group} = $_[1];
	  ($self->{Space_group}, $self->{Setting}) =
	    canonicalize_symbol($_[1]) ;
	  unless ($self->{Space_group}) {
	    Xray::Xtal::trap_error($$Xray::Xtal::strings{not_a_group}, 0);
	  };
	} else {
	  $self->{ $att } = $_[1];
	};
	shift; shift;
      };
      (lc($att) =~ /(alpha|beta|gamma)/) && ($self->{Angle} = $1);
    };
    my $cryscls = $self->crystal_class();

    ## try to recognize some easy mistakes
  SWITCH: {
      ($cryscls eq 'cubic') and do {
	if (($self->{A} < EPSILON) and ($self->{B} > EPSILON) and
	    ($self->{C} < EPSILON)) {
	  $self->{A} = $self->{B};
	} elsif (($self->{A} < EPSILON) and ($self->{B} < EPSILON) and
		 ($self->{C} > EPSILON)) {
	  $self->{A} = $self->{C};
	};
	last SWITCH;
      };
      (($cryscls eq 'tetragonal') or ($cryscls eq 'hexagonal')) and do {
	if (($self->{A} < EPSILON) and ($self->{B} > EPSILON)) {
	  $self->{A} = $self->{B};
	};
	last SWITCH;
      };
      (($cryscls eq 'trigonal') and ($self->{Space_group} !~ /^[Rr]/)) and do {
	if (($self->{A} < EPSILON) and ($self->{B} > EPSILON)) {
	  $self->{A} = $self->{B};
	};
	last SWITCH;
      };
      (($cryscls eq 'trigonal') and ($self->{Space_group} =~ /^[Rr]/)) and do {
	if (($self->{A} < EPSILON) and ($self->{B} > EPSILON) and
	    ($self->{C} < EPSILON)) {
	  $self->{A} = $self->{B};
	} elsif (($self->{A} < EPSILON) and ($self->{B} < EPSILON) and
		 ($self->{C} > EPSILON)) {
	  $self->{A} = $self->{C};
	};
	if (($self->{Alpha} < EPSILON) and ($self->{Beta} > EPSILON) and
	    ($self->{Gamma} < EPSILON)) {
	  $self->{Alpha} = $self->{Beta};
	} elsif (($self->{Alpha} < EPSILON) and ($self->{Beta} < EPSILON) and
		 ($self->{Gamma} > EPSILON)) {
	  ($self->{Alpha} = $self->{Gamma}) unless (abs($self->{Gamma}-120) < EPSILON);
	};
	last SWITCH;
      };
    };

    $self->{B} ||= $self->{A};	# B and C default to the value of A
    $self->{C} ||= $self->{A};
    ($self->{B}     < EPSILON) and $self->{B} = $self->{A};
    ($self->{C}     < EPSILON) and $self->{C} = $self->{A};
    unless ($self->{Alpha}) {$self->{Alpha} = 90};
    unless ($self->{Beta})  {$self->{Beta}  = 90};
    unless ($self->{Gamma}) {$self->{Gamma} = 90};
    ($self->{Alpha} < EPSILON) and $self->{Alpha} = 90;
    ($self->{Beta}  < EPSILON) and $self->{Beta}  = 90;
    ($self->{Gamma} < EPSILON) and $self->{Gamma} = 90;

				# Rhombohedral groups
    ($self->{Space_group} =~ /^[Rr]/) && do {
      if (abs(90-$self->{Alpha}) > EPSILON) {
	$self->{Setting} = "rhombohedral";
	$self->{B} = $self->{A}; # this flags the use of the rhomb. positions
	$self->{C} = $self->{A};
	$self->{Beta}  = $self->{Alpha};
	$self->{Gamma} = $self->{Alpha};
	##       } elsif ($self->{C} != $self->{A}) {
	## 	$self->{Setting} = 0;
	## 	$self->{B}     = $self->{A};
	## 	$self->{Alpha} = 90;
	## 	$self->{Beta}  = 90;
	## 	$self->{Gamma} = 120;
      } else {
	$self->{Setting} = 0;
	$self->{B}     = $self->{A};
	$self->{Alpha} = 90;
	$self->{Beta}  = 90;
	$self->{Gamma} = 120;
      };
    };
				# Trigonal and Hexagonal
    ((($self -> crystal_class() eq "trigonal") ||
      ($self -> crystal_class() eq "hexagonal")) &&
     ($self->{Space_group} !~ /^[Rr]/)) && do {
	$self->{B}     = $self->{A};
	$self->{Alpha} = 90;
	$self->{Beta}  = 90;
	$self->{Gamma} = 120;
    };

    ## now is the right time to set this...
    $self->{Bravais} = [bravais($self->{Space_group},$self->{Setting})];

				# Monoclinic
    if ($self -> crystal_class() eq "monoclinic") {
      $self->{Setting} = determine_monoclinic($self);
      $self->{Bravais} = [bravais($self->{Given_group},0)];
    };
				# Set metric tensor elements (this is
				# some ugly stuff!)
    my $alpha = $self->{Alpha} * PI / 180;
    my $beta  = $self->{Beta}  * PI / 180;
    my $gamma = $self->{Gamma} * PI / 180;
    my $cosxx = ( cos($alpha)*cos($gamma) - cos($beta) ) /
      ( sin($alpha)*sin($gamma) );
    my $cosyy = ( cos($alpha)*cos($beta) - cos($gamma) ) /
      ( sin($alpha)*sin($beta) );
				# careful for the sqrt!
    my $sinxx = ($cosxx**2 < 1) ? sqrt(1-$cosxx**2) : 0;
    my $sinyy = ($cosyy**2 < 1) ? sqrt(1-$cosyy**2) : 0;
    $self->{Txx} = sprintf "%11.7f", $sinyy*sin($beta);
    $self->{Tyx} = sprintf "%11.7f", -( ($cosyy/($sinyy*sin($alpha)) ) +
		     (cos($alpha)*$cosxx)/($sinxx*sin($alpha)))
                   * ($sinyy*sin($beta));
    $self->{Tyz} = sprintf "%11.7f", cos($alpha);
    $self->{Tzx} = sprintf "%11.7f", -( $cosxx*$sinyy*sin($beta) ) / $sinxx;
    $self->{Tzz} = sprintf "%11.7f", sin($alpha);

				# Set cell volume
    my $term  = 1 - cos($alpha)**2 - cos($beta)**2 - cos($gamma)**2 +
      2*cos($alpha)*cos($beta)*cos($gamma);
    $self->{Volume} = $self->{A} * $self->{B} * $self->{C} * sqrt($term);

    return $self;
};


=over 4

=item C<clear>

Reset a cell without destroying it.

  $cell -> clear();

=back

=cut
## reset a cell without destroying it
sub clear {
    my $self = shift;
    $self->{Space_group} = "";	# supplied & calculated
    $self->{Given_group} = "";	#            calculated
    $self->{A}           = 0;	# supplied
    $self->{B}           = 0;	# supplied | calculated
    $self->{C}           = 0;	# supplied | calculated
    $self->{Alpha}       = 90;	# supplied | calculated
    $self->{Beta}        = 90;	# supplied | calculated
    $self->{Gamma}       = 90;	# supplied | calculated
    $self->{Angle}       = "";	#            calculated
    $self->{Setting}     = 0;	#            calculated
    $self->{Contents}    = 0;	#            calculated
    $self->{Bravais}     = ();	#            calculated
    $self->{Volume}      = 1;	#            calculated
    $self->{Txx}         = 0;	#            calculated
    $self->{Tyx}         = 0;	#            calculated
    $self->{Tyz}         = 0;	#            calculated
    $self->{Tzx}         = 0;	#            calculated
    $self->{Tzz}         = 0;	#            calculated
    $self->{Occupancy}   = 1;   # supplied
    return $self;
};

=over 4

=item C<populate>

Populate a unit cell given a list of sites.  Each element of the list
of sites must be a Site object.  The symmetries operations implied by
the space group are applied to each unique site to generate a
description of the stoichiometric contents of the unit cell.

   $cell -> populate(\@sites)

This fills the C<Contents> attribute of the Cell with an anonymous
array.  Each element of the anonymous array is itself an anonymous
array whose first three elements are the x, y, and z fractional
coordinates of the site and whose fourth element is a reference to the
Site that generated the position.  This is, admitedly, a complicated
data structure and requires a lot of ``line-noise'' style perl to
dereference all its elements.  It is, however, fairly efficient.

=back

=cut

sub populate {
  my $self = shift;
  my $r_sites = $_[0];
  my @unit_cell = ();

  my $cnt = 0;
  my %seen;			# need unique tags for formulas
  foreach my $site (@{$r_sites}) {
    ++$cnt;
    if ($seen{$site->{Tag}}++) {
      $site->{Utag} = $site->{Tag} . '_' . $cnt;
    } else {
      $site->{Utag} = $site->{Tag};
    };
  };
  my $crystal_class = $self -> crystal_class();
  my $setting       = $self->{Setting};
  my $do_tetr       = ($crystal_class eq "tetragonal" )   && ($setting);
  if ($do_tetr) {
    my ($a, $b) = ($self->{A}, $self->{B});
    $self -> make(A=>$a/sqrt(2), B=>$b/sqrt(2));
  };
  foreach my $site (@{$r_sites}) {
    $site -> populate($self);
    my ($t) = $site -> attributes("tag");
    my $cnt = 0;
    foreach my $list (@{$site->{Positions}}) {
      ## ($t eq "V1-5") and print join("  ", @$list[0..2], $/);
      my $form = $ {$site->{Formulas}}[$cnt];
      push @unit_cell, [$$list[0], $$list[1], $$list[2], \$site, @$form];
      ++$cnt;
    };
  };
  $self->{Contents} = [@unit_cell];
  #---------------------------- Check for repeats.
  my %occ  = ();
  %seen = ();	  	          #   similar to section 4.6, p.102,
  foreach my $item (@unit_cell) { #   The Perl Cookbook, 1st edition
    my $keya = sprintf "%7.5f", $$item[0]; chop $keya;
    my $keyb = sprintf "%7.5f", $$item[1]; chop $keyb;
    my $keyc = sprintf "%7.5f", $$item[2]; chop $keyc;
    my $key = $keya . $keyb . $keyc;
    (exists $seen{$key}) && do {
      my ($that, $this) = ($ {$seen{$key}->[3]}->{Tag}, $ {$$item[3]}->{Tag});
      $occ{$key}->[0] += $ {$$item[3]}->{Occupancy};
      push @{$occ{$key}}, $this; # add tag to list
      ## flag this as a dopant
      $ {$$item[3]} -> make(Host=>0);
      ## 	croak "The sites \"" . $this . "\" and \"" . $that .
      ## 	    "\" generate the same position in space.$/" .
      ## 	      "Multiple occupancy is not allowed in this program.$/" .
      ## 		"This program cannot continue due to the error";
    };
    $seen{$key} = $item;	# $ {$$item[3]}->{Tag};
    $occ{$key} ||= [ $ {$$item[3]}->{Occupancy}, $ {$$item[3]}->{Tag} ];
  };
  ## now check that a site is not overly occupied
  #if ($self->{Occupancy}) {
  my @croak;
  foreach my $k (keys %occ) {
    my @list = @{$occ{$k}};
    my $val = shift @list;
    if ($val > (1+EPSILON)) {
      push @croak,
      $$Xray::Xtal::strings{these_sites} .
      "$/\t" . join("  ", map {sprintf "\"%s\"", $_} @list) .
	"$/" . $$Xray::Xtal::strings{occupied} ;
    };
  };
  if (@croak) {		# weed out repititious error messages
    my %seen = ();
    my @unique = ();
    foreach my $item (@croak) {
      unless ($seen{$item}) {
	$seen{$item} = 1;
	push (@unique, $item);
      };
    };
    #unless ($Xray::Xtal::Site::molecule) {
    Xray::Xtal::trap_error(join("$/", @unique), 0);
    #};
  };
  #};
  return $self;
};

=over 4

=item C<canonicalize_symbol>

This takes a character string representing a space group and returns
the canonical symbol for that group.  See the Atoms document and
L<"INTERPRETING SPACE GROUP SYMBOLS"> below for complete details about
space group symbols and how they are interpretted by this function.
This is not a method of the Cell class, it is just a normal function.

  $string = Xray::Xtal::Cell::canonicalize_symbol($string);

For example

  Xray::Xtal::Cell::canonicalize_symbol('pm3m')
  yields "P m -3 m"

=back

=cut

sub canonicalize_symbol {
    my $symbol = $_[0];
    my $sym;
				# this is a null value
    (! $symbol) && return (0,0);

    $symbol = lc($symbol);	# lower case and ...
    $symbol =~ s/[!\#%*].*$//;  # trim off comments
    $symbol =~ s/^\s+//;	# trim leading spaces
    $symbol =~ s/\s+$//;	# trim trailing spaces
    $symbol =~ s/\s+/ /g;	# ... single space
    $symbol =~ s|\s*/\s*|/|g;	# spaces around slash

    $symbol =~ s/2_1/21/g;	# replace `i 4_1' with `i 41'
    $symbol =~ s/3_([12])/2$1/g; #  and so on ...
    $symbol =~ s/4_([1-3])/2$1/g;
    $symbol =~ s/6_([1-5])/2$1/g;

    my $shorthands = 'bcc|c(scl|ubic)|diamond|fcc|gra(|phite)|h(cp|ex)';
    $shorthands = $shorthands . '|nacl|perov(|skite)|salt|z(incblende|ns)';
    unless ( ($symbol =~ /[_^ ]/)       or  # HM with spaces, schoen
	     ($symbol =~ /\b\d{1,3}\b/) or  # 1-230
	     ($symbol =~ /\b($shorthands)\b/io) # shorthands like 'cubic', 'zns'
	   ) {
      $symbol = insert_spaces($symbol);
    };
				# this is the standard symbol
    (exists($$Xray::Xtal::r_space_groups{$symbol})) && return ($symbol, 0);

    foreach $sym (keys %$Xray::Xtal::r_space_groups ) {
      next if ($sym eq "version");
      my %hash = %{$$Xray::Xtal::r_space_groups{$sym}};

				# scalar valued fields
				# this is a number between 1 and 230
				#    or the 1935 symbol
 				#    or a double glide plane symbol
 				#    or the full symbol
      foreach my $field ("thirtyfive", "new_symbol", "full") {
	exists $hash{$field} && ($symbol eq $hash{$field}) &&
	  return ($sym, 0);
      };
      if ($symbol eq $hash{number}) {
	if (($symbol > 2) and ($symbol < 16)) {
	  return ($sym, 1);
	} else {
	  return ($sym, 0);
	};
      };
				# this is the Schoenflies symbol, (it
				# must have a caret in it)
      ($symbol =~ /\^/) && do {
	$symbol =~ s/\s+//g;	#   no spaces
	$symbol =~ s/^v/d/g;	#   V -> D
				# put ^ and _ in correct order
	$symbol =~ s/([cdost])(\^[0-9]{1,2})(_[12346dihsv]{1,2})/$1$3$2/;
	exists $hash{"schoenflies"} and
	  ($symbol eq $hash{"schoenflies"}) and
	    return ($sym, 0);
      };
				# now check the array values fields
      foreach my $field ("settings", "short", "shorthand") {
	(exists($hash{$field})) && do {
	  my $i=0;
	  foreach my $setting ( @{$hash{$field}} ) {
	    ++$i;
	    my $s = ($field eq "settings") ? $i : 0;
	    if ($symbol eq $setting) {
	      ##print "setting : $s\n";
	      return ($sym, $s);
	    };
	  };			# "settings" is an array field
	};
      };
    };
				# this is not a symbol
    1 && do { return (0,0); };
}

## This is the algorithm for dealing with user-supplied space group
## symbols that do not have the canonical single space separating the
## part of the symbol.
sub insert_spaces {
  my $sym = $_[0];

  my ($first, $second, $third, $fourth) = ("", "", "", "");

  ## a few groups don't follow the rules below ...
  ($sym =~ /\b([rhc])32\b/i)                 && return "$1 3 2";
  ($sym =~ /\bp31([2cm])\b/i)                && return "p 3 1 $1";
  ($sym =~ /\bp(3[12]?)[22][12]\b/i)         && return "p $1 2 1";
  ($sym =~ /\bp(6[1-5]?)22\b/i)              && return "p $1 2 2";
  ($sym =~ /\b([fip])(4[1-3]?)32\b/i)        && return "$1 $2 3 2";
  ($sym =~ /\b([fipc])(4[1-3]?)(21?)(2)\b/i) && return "$1 $2 $3 $4";

  ## the first symbol is always a single letter
  $first = substr($sym, 0, 1);
  my $index = 1;

  if (substr($sym, $index, 4) =~ /([2346][12345]\/[mnabcd])/) {
    ## second symbol as in p 42/n c m
    $second = $1;
    $index += 4;
  } elsif (substr($sym, $index, 3) =~ /([2346]\/[mnabcd])/) {
    ## second symbol as in p 4/n n c
    $second = $1;
    $index += 3;
  } elsif (substr($sym, $index, 2) =~ /(-[1346])/) {
    ## second symbol as in p -3 1 m
    $second = $1;
    $index += 2;
  } elsif (substr($sym, $index, 2) =~ /(21|3[12]|4[123]|6[12345])/) {
    ## second symbol as in p 32 1 2
    $second = $1;
    $index += 2;
  } else {
    $second = substr($sym, $index, 1);
    $index += 1;
  };

  if (substr($sym, $index, 4) =~ /([2346][12345]\/[mnabcd])/) {
    ## third symbol as in full symbol p 21/c 21/c 2/n
    $third = $1;
    $index += 4;
  } elsif (substr($sym, $index, 3) =~ /([2346]\/[mnabcd])/) {
    ## third symbol as in full symbol p 4/m 21/b 2/m
    $third = $1;
    $index += 3;
  } elsif (substr($sym, $index, 2) =~ /(-[1346])/) {
    ## third symbol as in f d -3 m
    $third = $1;
    $index += 2;
  } elsif (substr($sym, $index, 2) =~ /(21|3[12]|4[123]|6[12345])/) {
    ## third symbol as in p 21 21 2
    $third = $1;
    $index += 2;
  } else {
    $third = substr($sym, $index, 1);
    $index += 1;
  };

  ($index < length($sym)) and $fourth = substr($sym, $index);

  $sym = join(" ", $first, $second, $third, $fourth);
  $sym =~ s/\s+$//;		# trim trailing spaces
  return $sym;
};

## =over 4
##
## =item C<bravais>
##
## This takes the values of the C<Space_group> and C<Setting> attributes
## of a Cell and returns a list which specifies the Bravais translation
## vectors.  This list is the truncation of the various Bravais
## translation three-vectors, thus has 0, 3, 6, or 9 elements.  This is
## not method of the Cell class, it is just a normal function.  It should
## rarely be necessary to call this, as the Bravais vector gets stored in
## the "Bravais" attribute of a cell.
##
##   ($group, $setting) =
##        $cell -> attributes("Space_group", "Setting");
##   @list = Xray::Xtal::Cell::bravais($group, $setting);
##
## =back
##
## =cut

sub bravais {
    my $group = lc(substr($_[0], 0, 1));
    my $setting = $_[1];
    ( $group eq "f") && return (  0, 1/2, 1/2, 1/2,   0, 1/2, 1/2, 1/2,   0);
    ( $group eq "i") && return (1/2, 1/2, 1/2);
    ( $group eq "c") && return (1/2, 1/2,   0);
    ( $group eq "a") && return (  0, 1/2, 1/2);
    ( $group eq "b") && return (1/2,   0, 1/2);
    (($group eq "r") && ($setting eq 0))
                     && return (2/3, 1/3, 1/3, 1/3, 2/3, 2/3);
    return ();
};


=over 4

=item C<crystal_class>

This returns a character string specifying the crystal class.  The
return value is one of ``cubic'', ``hexagonal'', ``trigonal'',
``tetragonal'', ``orthorhombic'', ``monoclinic'', or ``triclinic''.
This is a method of the Cell class.

  $class = $cell -> crystal_class();

=back

=cut

sub crystal_class {
  my $self = shift;
  my $group = $self->{Space_group};
  (exists $$Xray::Xtal::r_space_groups{$group}{number}) && do {
    my $hash_element = $$Xray::Xtal::r_space_groups{$group};
    ($$hash_element{number} <= 0)   && return "";
    ($$hash_element{number} <= 2)   && return "triclinic";
    ($$hash_element{number} <= 15)  && return "monoclinic";
    ($$hash_element{number} <= 74)  && return "orthorhombic";
    ($$hash_element{number} <= 142) && return "tetragonal";
    ($$hash_element{number} <= 167) && return "trigonal";
    ($$hash_element{number} <= 194) && return "hexagonal";
    ($$hash_element{number} <= 230) && return "cubic";
                                       return "";
  };          # need to return something if $group not yet defined or
  return "";  # defined incorrectly
};

## input:  reference to a cell
## output: string specifying the monoclinic setting for that cell
## this is called by the make method
sub determine_monoclinic {
  my $self = $_[0];
  ## need to know the space group, the user-provided symbol, and the
  ## unique axis (determined from the non-90 degree angle)
  my $group = $self->{Space_group};
  ($self -> crystal_class() eq "monoclinic") || return;
  my $given = $self->{Given_group};
  my $axis = 0;
  ((abs( 90 - $self->{Alpha} )) > EPSILON) && ($axis = "a");
  ((abs( 90 - $self->{Beta}  )) > EPSILON) && ($axis = "b");
  ((abs( 90 - $self->{Gamma} )) > EPSILON) && ($axis = "c");
  (! $axis) && do {
    if ($self->{Angle}) {
      $axis = substr($self->{Angle}, 0, 1);
      ($axis = lc($axis)) =~ tr/g/c/;
    };
  };
  (! $axis) && do {		# apparently the non-90 angle has not
    return 0;			# been set yet...
  };
  my $number = $$Xray::Xtal::r_space_groups{$group}{number};
				# if it has, then continue...
  ($given =lc($given)) =~ s/^\s+//; # lower case and strip leading blanks
  $given =~ s/\s+$//;               # strip trailing blanks
  my $setting = $axis . "_unique";
  if ($given eq $number) {
    $given = $$Xray::Xtal::r_space_groups{$group}{settings}[0];
  };
  ## these groups have one cell choice for each unique axis
  foreach my $n (3,4,5,6,8,10,11,12) {
    ($number == $n) && return $setting;
  };
  ## groups 7, 13, 14 are p centered and have multiple cell choices
  ($group =~ /^p/i) && do {
    ($axis eq "b") && do {
      ($given =~ /c/i) && ($setting .= "_1");
      ($given =~ /n/i) && ($setting .= "_2");
      ($given =~ /a/i) && ($setting .= "_3");
    };
    ($axis eq "c") && do {
      ($given =~ /a/i) && ($setting .= "_1");
      ($given =~ /n/i) && ($setting .= "_2");
      ($given =~ /b/i) && ($setting .= "_3");
    };
    ($axis eq "a") && do {
      ($given =~ /b/i) && ($setting .= "_1");
      ($given =~ /n/i) && ($setting .= "_2");
      ($given =~ /c/i) && ($setting .= "_3");
    };
  };
  ## groups 9, 15 are c centered and have multiple cell choices
  ($group =~ /^c/i) && do {
    ($axis eq "b") && do {
      ($given =~ /^c/i) && ($setting .= "_1");
      ($given =~ /^a/i) && ($setting .= "_2");
      ($given =~ /^i/i) && ($setting .= "_3");
    };
    ($axis eq "c") && do {
      ($given =~ /^a/i) && ($setting .= "_1");
      ($given =~ /^b/i) && ($setting .= "_2");
      ($given =~ /^i/i) && ($setting .= "_3");
    };
    ($axis eq "a") && do {
      ($given =~ /^b/i) && ($setting .= "_1");
      ($given =~ /^c/i) && ($setting .= "_2");
      ($given =~ /^i/i) && ($setting .= "_3");
    };
  };
  ## if none of the preceding 6 blocks altered setting then there is a
  ## mismatch between the symbol and the unique axis, so return 0.
  ($setting =~ /_[123]$/) || ($setting = 0);
  return $setting;
};

## explicitly set the value of $self->{Setting} for a monoclinic
## groups regardless of how it was set in canonicalize_coordinate.
sub enforce_monoclinic {
    my $self = shift;
    (($#_ == 1)||($#_ == 2)) || do {
      my $this = (caller(0))[3];
      croak "$this takes 1 or 2 arguments arguments";
      return;
    };
    my ($axis,$choice) = @_;
    ($axis =~ /\b[abc]\b/i) || do {
      my $this = (caller(0))[3];
      croak "The unique axis must be a b or c in $this";
      return;
    };
    ($choice) && do {
      ($choice =~ /\b[123]\b/) || do {
	my $this = (caller(0))[3];
	croak "The cell choice must be 1 2 or 3 in $this";
	return;
      };
    };
    $self->{Setting} = $axis . "_unique";
    ($choice) && ($self->{Setting} .= "_" . $choice);
    $self->{Setting} = lc($self->{Setting});
    return $self;
};

=over 4

=item C<verify_cell>

This performs consistency checks on the all cell attributes.  If
anything suspicious turns up, warning or error messages are issued.

  $cell -> verify_cell();

=back

=cut

sub verify_cell {
  my $self = shift;
  my ($fault, $error, $warning, $caution) = (0, 3, 2, 1);
  my $normal = 0;
  my $message = "";
				# 1: verify space group
  my $group = $self -> {Space_group};
  (exists $$Xray::Xtal::r_space_groups{$group}) || do {
    $fault = &set_fault($fault, $error);
    $message .= $self->{Given_group} . " " . $$Xray::Xtal::strings{not_valid};
  };
				# 2: axes must be positive
  (($self->{A}) > EPSILON) || do {
    $fault = &set_fault($fault, $error);
    ($message !~ /^\s*$/) && ($message .= $/);
    $message .= "x=$self->{A}, x " . $$Xray::Xtal::strings{positive} . ".";
  };
  (($self->{B}) > EPSILON) || do {
    $fault = &set_fault($fault, $error);
    ($message !~ /^\s*$/) && ($message .= $/);
    $message .= "y=$self->{B}, y " . $$Xray::Xtal::strings{positive} . ".";
  };
  (($self->{C}) > EPSILON) || do {
    $fault = &set_fault($fault, $error);
    ($message !~ /^\s*$/) && ($message .= $/);
    $message .= "z=$self->{C}, z " . $$Xray::Xtal::strings{positive} . ".";
  };
				# 3: rules for crystal classes
  my $class = $self -> crystal_class();
				# Triclinic
  ($class eq "triclinic") && do {
    $normal = ( (abs(90-$self->{Alpha})     > EPSILON) &&
		(abs(90-$self->{Beta} )     > EPSILON) &&
		(abs(90-$self->{Gamma})     > EPSILON) &&
		(abs($self->{A}-$self->{B}) > EPSILON) &&
		(abs($self->{A}-$self->{C}) > EPSILON) &&
		(abs($self->{B}-$self->{C}) > EPSILON) );
    $normal || do {
      $fault = &set_fault($fault, $caution);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{triclinic_desc};
    };
  };
				# Monoclinic
  ($class eq "monoclinic") && do {
    $normal = ( ( ((abs(90-$self->{Alpha})  > EPSILON)
		   xor
		   (abs(90-$self->{Beta} )  > EPSILON))
		  xor
		  (abs(90-$self->{Gamma})   > EPSILON) ) &&
		(abs($self->{A}-$self->{B}) > EPSILON) &&
		(abs($self->{A}-$self->{C}) > EPSILON) &&
		(abs($self->{B}-$self->{C}) > EPSILON) );
    $normal || do {
      $fault = &set_fault($fault, $caution);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{monoclinic_desc};
    };
    ($self->{Setting} =~ /unique/i) || do {
      $fault = &set_fault($fault, $error);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{monoclinic_unknown};
    };
  };
				# Orthorhombic
  ($class eq "orthorhombic") && do {
    $normal = ( (abs(90-$self->{Alpha})     < EPSILON) &&
		(abs(90-$self->{Beta} )     < EPSILON) &&
		(abs(90-$self->{Gamma})     < EPSILON) &&
		(abs($self->{A}-$self->{B}) > EPSILON) &&
		(abs($self->{A}-$self->{C}) > EPSILON) &&
		(abs($self->{B}-$self->{C}) > EPSILON) );
    $normal || do {
      $fault = &set_fault($fault, $caution);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{orthorhombic_desc};
    };
  };
				# Tetragonal
  ($class eq "tetragonal") && do {
    $normal = ( (abs(90-$self->{Alpha})     < EPSILON) &&
		(abs(90-$self->{Beta} )     < EPSILON) &&
		(abs(90-$self->{Gamma})     < EPSILON) &&
		(abs($self->{A}-$self->{B}) < EPSILON) &&
		(abs($self->{A}-$self->{C}) > EPSILON) );
    $normal || do {
      $fault = &set_fault($fault, $caution);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{tetragonal_desc};
    };
  };
				# Hexagonal
  ($class eq "hexagonal") && do {
    $normal = ( (abs( 90-$self->{Alpha})    < EPSILON) &&
		(abs( 90-$self->{Beta} )    < EPSILON) &&
		(abs(120-$self->{Gamma})    < EPSILON) &&
		(abs($self->{A}-$self->{B}) < EPSILON) &&
		(abs($self->{A}-$self->{C}) > EPSILON) );
    $normal || do {
      $fault = &set_fault($fault, $warning);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{hexagonal_desc};
    };
  };
				# Trigonal
  ($class eq "trigonal") && do {
				# rhombohedral
    if (($group =~ /^r/i) && (abs( 90-$self->{Alpha}) > EPSILON)) {
      $normal = ( (abs($self->{Alpha}- $self->{Beta})  < EPSILON) &&
		  (abs($self->{Alpha}- $self->{Gamma}) < EPSILON) &&
		  (abs($self->{Beta} - $self->{Gamma}) < EPSILON) &&
		  (abs($self->{A}    - $self->{B})     < EPSILON) &&
		  (abs($self->{A}    - $self->{C})     < EPSILON) &&
		  (abs($self->{B}    - $self->{C})     < EPSILON) );
      $normal || do {
	$fault = &set_fault($fault, $warning);
	($message !~ /^\s*$/) && ($message .= $/);
	$message .= $$Xray::Xtal::strings{rhombohedral_desc};
      };
				# not rhombohedral
    } else {
      $normal = ( (abs($self->{A}-$self->{B}) < EPSILON) &&
		  (abs($self->{A}-$self->{C}) > EPSILON) );
      $normal || do {
	$fault = &set_fault($fault, $warning);
	($message !~ /^\s*$/) && ($message .= $/);
	$message .= $$Xray::Xtal::strings{trigonal_desc};
      };
      $normal = ( (abs( 90-$self->{Alpha})    < EPSILON) &&
		  (abs( 90-$self->{Beta} )    < EPSILON) &&
		  (abs(120-$self->{Gamma})    < EPSILON) );
      $normal || do {
	$fault = &set_fault($fault, $error);
	($message !~ /^\s*$/) && ($message .= $/);
	$message .= $$Xray::Xtal::strings{trigonal_desc};
      };
    };
  };
				# Cubic
  ($class eq "cubic") && do {
    $normal = ( (abs(90-$self->{Alpha})     < EPSILON) &&
		(abs(90-$self->{Beta} )     < EPSILON) &&
		(abs(90-$self->{Gamma})     < EPSILON) &&
		(abs($self->{A}-$self->{B}) < EPSILON) &&
		(abs($self->{B}-$self->{C}) < EPSILON) &&
		(abs($self->{A}-$self->{C}) < EPSILON) );
    $normal || do {
      $fault = &set_fault($fault, $caution);
      ($message !~ /^\s*$/) && ($message .= $/);
      $message .= $$Xray::Xtal::strings{cubic_desc};
    };
  };
  ($fault >=3 ) &&
    Xray::Xtal::trap_error($message . "$/$/ " .
			   $$Xray::Xtal::strings{fatal_error} . "$/", 0);
  return $fault;
};

sub set_fault {
  ##use Term::ANSIColor;
  my ($fault, $level) = @_;
  my @message = (" ", " $$Xray::Xtal::strings{caution}: ",
		 " $$Xray::Xtal::strings{warning}: ",
		 " $$Xray::Xtal::strings{error} ");
  my @colors = ("", "green", "yellow", "red");
  ##warn color($colors[$level]), $message[$level], $string, color("reset"), "$/";
  $fault = ($level > $fault) ? $level : $fault;
  return $fault;
};

## sub color {
##   ($_[0] eq "")        && return;
##   ($_[0] eq "red")     && return "[31;1m";
##   ($_[0] eq "green")   && return "[32;1m";
##   ($_[0] eq "yellow")  && return "[33;1m";
##   ($_[0] eq "blue")    && return "[34;1m";
##   ($_[0] eq "magenta") && return "[35;1m";
##   ($_[0] eq "cyan")    && return "[36;1m";
##   ($_[0] eq "white")   && return "[37;1m";
##   ($_[0] eq "reset")   && return "[33m[0m";
## };

=over 4

=item C<metric>

Takes the three fractional coordinates and returns the cartesian
coordinates of the position.  The fractional coordinates need not be
canonicalized into the first octant, thus this method can be used to
generate the cartesian coordinates for any atom in a cluster.

  ($x,$y,$z) = $cell -> metric($xf, $yf, $zf);

This method is called repeatedly by the C<build_cluster> function in
the Xray::Atoms module.  The elements of the metric tensor, i.e. the
C<Txx>, C<Tyx>, C<Tyz>, C<Tzx>, and C<Tz> Cell attributes, are used to
make the transformation according to this formula:

              / Txx   0    0  \   / xf \
   (x y z) = |  Tyx   1   Tyz  | |  yf  |
              \ Tzx   0   Tzz /   \ zf /

=back

=cut

## note that sprintf is a significant speed hit given the large number
## of times this function is called, but it does assure a given level
## of precision
sub metric {
  my $self = shift;
  my ($x,$y,$z) = @_;
  my ($xp, $yp, $zp);
  ($x, $y, $z) = ($x*$self->{A}, $y*$self->{B}, $z*$self->{C});
  $xp = sprintf "%11.7f", $x*$self->{Txx};
  $yp = sprintf "%11.7f", $x*$self->{Tyx} + $y + $z*$self->{Tyz};
  $zp = sprintf "%11.7f", $x*$self->{Tzx} +      $z*$self->{Tzz};
  return ($xp,$yp,$zp);
};

=over 4

=item C<d_spacing>

Takes the Miller indeces of a scattering plane and returns the d
spacing of that plane in Angstroms.

  $d = $cell -> d_spacing($h, $k, $l);

=back

=cut

sub d_spacing {
  my $self = shift;
  my ($h, $k, $l) = @_;
  return 0 unless ($h or $k or $l);
  my $alpha = $self->{Alpha} * PI / 180;
  my $beta  = $self->{Beta}  * PI / 180;
  my $gamma = $self->{Gamma} * PI / 180;

  my $s11 = ($self->{B}*$self->{C}*sin($alpha))**2;
  my $s22 = ($self->{A}*$self->{C}*sin($beta ))**2;
  my $s33 = ($self->{A}*$self->{B}*sin($gamma))**2;

  my $s12 =  $self->{A} * $self->{B} * ($self->{C}**2) *
    ( cos($alpha)*cos($beta)  - cos($gamma) );
  my $s23 =  $self->{B} * $self->{C} * ($self->{A}**2) *
    ( cos($beta) *cos($gamma) - cos($alpha) );
  my $s13 =  $self->{C} * $self->{A} * ($self->{B}**2) *
    ( cos($gamma)*cos($alpha) - cos($beta)  );

  my $d = $s11*($h**2) + $s22*($k**2) + $s33*($l**2) +
    2*$s12*$h*$k + 2*$s23*$k*$l + 2*$s13*$h*$l;
  $d = $self->{Volume} / sqrt($d);
  return $d;
};



=over 4

=item C<multiplicity>

Returns the multiplicity of a reflection hkl for the cell.

  $p = $cell -> multiplicity($h, $k, $l);

See the footnote in Cullity page 523 for a caveat.

=back

=cut

sub multiplicity {
  my $self= shift;
  my $class = $self -> crystal_class();
  my ($h, $k, $l) = @_;
  my @r = sort($h, $k, $l);
 SWITCH:
  ($class eq 'cubic') and do {
    (not $r[0]) && (not $r[1]) && $r[2]   && return 6;
    ($r[0] == $r[1]) && ($r[1] == $r[2])  && return 8;
    (not $r[0]) && ($r[1] == $r[2])       && return 12;
    (not $r[0]) && ($r[1] != $r[2])       && return 24; #*
    ($r[0] == $r[1]) && ($r[1] != $r[2])  && return 24;
    ($r[0] != $r[1]) && ($r[1] == $r[2])  && return 24;
    return 48
  };
  (($class eq 'hexagonal') || ($class eq 'trigonal')) and do {
    (not $h) && (not $k) && $l            && return 2;
    (not $l) && ((not $h) || (not $k))    && return 6;
    (not $l) && ($h == $k)                && return 6;
    (not $l) && ($h != $k)                && return 12; #*
    $l && ((not $h) || (not $k))          && return 12;	#*
    $l && ($h == $k)                      && return 12;	#*
    return 24; #*
  };
  ($class eq 'tetragonal') and do{
    (not $h) && (not $k) && $l            && return 2;
    (not $l) && ((not $h) || (not $k))    && return 4;
    (not $l) && ($h == $k)                && return 4;
    (not $l) && ($h != $k)                && return 8; #*
    $l && ((not $h) || (not $k))          && return 8;
    $l && ($h == $k)                      && return 8;
    return 16; #*
  };
  ($class eq 'orthorhombic') and do{
    (not $r[0]) && (not $r[1])            && return 2;
    (not $r[0]) || (not $r[1])            && return 4;
    return 4;
  };
  ($class eq 'monoclinic') and do{
    (not $r[0]) || (not $r[1])            && return 2;
    return 4;
  };
  ($class eq 'triclinic') and return 2;
};


=over 4

=item C<central>

This method takes one argument, a string specifying the tag of the
central atom.  It returns a four element list of the central atom
elemental symbol and its fractional coordinates.

  ($elem_c, $x_c, $y_c, $z_c) = $cell -> central($central_tag)

In many cases there is more than one choice for the central atom.  Any
of the various crystallographically identical positions matching the
tag of the central atom can be chosen.  This method returns the one
closest to the center of the unit cell, i.e. the one closest to
(1/2,1/2,1/2).  The meaning of the word "closest" is a bit strange in
this context.  It is the position with the smallest value of

  sqrt( (x-0.5)**2 + (y-0.5)**2 + (z-0.5)**2 )

This is chosen for speed and efficiency in building a spherical
cluster of atoms.

=back

=cut

sub central {
  my $self = shift;
  my $core = $_[0];
  my $list;
  my ($xcenter, $ycenter, $zcenter, $central, $is_host);
  return ("",0,0,0,0) unless ($self->{Contents});
 FIND: foreach my $site (@{$self->{Contents}}) {
    #print lc($core), "  ", lc($ {$$site[3]}->{Tag}), $/ ;
    (lc($core) eq lc($ {$$site[3]}->{Tag})) && do {
      $central = $ {$$site[3]}->{Element};
      $is_host = $ {$$site[3]}->{Host};
      $list    = $ {$$site[3]}->{Positions};
      last FIND;
    };
  };
  #my @cformula = ("", "", "");
  if ($list) {
    my ($dist, $best) = (0, 100000);
    foreach my $site (@$list) {
      $dist =
	sqrt((0.5-$$site[0])**2 + (0.5-$$site[1])**2 + (0.5-$$site[2])**2);
      if ($dist < $best) {
	($xcenter, $ycenter, $zcenter) = ($$site[0], $$site[1], $$site[2]);
	$best = $dist;
      };
    };
    #print join(" ", $central, $xcenter, $ycenter, $zcenter), $/;
    ##($xcenter, $ycenter, $zcenter) =
    ##  $self -> metric($xcenter, $ycenter, $zcenter);
    return ($central, $xcenter, $ycenter, $zcenter, $is_host);
  };
  return ("",0,0,0,0);
};


=over 4

=item C<overfull>

This method returns the overfilled unit cell with atom positions in
Cartesian coordinates.  It takes an optional argument for specifying
the epsilon defining which atoms should be considered close to a side,
edge, or corner of the unit cell.  The default for this value is 0.1
and the units are fractional cell coordinates.  The return value is a
list structured the same as the Contents attribute of the cell.

  @overfull = $cell -> overfull($epsi);

Each element of C<@overfull> is an anonymous array containing the x,
y, and z fractional coordinates and a reference to the Site that
generated the position.

=back

=cut
;
sub overfull {
  my $self = shift;
  my $epsi = $_[0] || EPSILON;
  my @list = ();
  foreach my $site (@{$self->{Contents}}) {
    my @p = ([0],[0],[0]);
    unless ($epsi < 0) {
      foreach my $i (0..2) {
	($$site[$i]     < $epsi) && ($p[$i] = [0,1]);  # near 0
	((1-$$site[$i]) < $epsi) && ($p[$i] = [-1,0]); # near 1
      };
    };
    foreach my $a (@{$p[0]}) {
      foreach my $b (@{$p[1]}) {
	foreach my $c (@{$p[2]}) {
	  my ($x, $y, $z) =
	    $self -> metric($$site[0]+$a, $$site[1]+$b, $$site[2]+$c);
	  push @list, [$x, $y, $z, $$site[3]];
	  #push @list, [$$site[0]+$a, $$site[1]+$b, $$site[2]+$c, $$site[3]];
	};
      };
    };
  };
  return @list;
};

=over 4

=item C<warn_shift>

This method returns a warning string if the space group is one for
which the International Tables give two possible origin positions.
This string suggests a value for the shift vector.  An empty string
is returned if only one origin is given.

  print $cell -> warn_shift;

=back

=cut

sub get_shift {
  my $group = $_[0];
  my $setting;
  ($group, $setting) = canonicalize_symbol($group);
  (exists $$Xray::Xtal::r_space_groups{$group}{shiftvec}) &&
    return @{$$Xray::Xtal::r_space_groups{$group}{shiftvec}};
  return ();
};
sub warn_shift {
  my $self = shift;
  my $group = $self->{Space_group};
  (exists $$Xray::Xtal::r_space_groups{$group}{shiftvec}) && do {
    my $vec = join(", ", @{$$Xray::Xtal::r_space_groups{$group}{shiftvec}});
    my $message = join("", $/, "  \"", ucfirst($group), "\" ",
		       $$Xray::Xtal::strings{warn_shift},
		       $/, "\t", $vec, $/, $/);
    return $message;
  };
  return "";
};

=over 4

=item C<cell_check>

This method returns a warning if the cell axes and angles are not
appropriate to the space group.  It returns an empty string if they
are appropriate.

  print $cell -> cell_check;

=back

=cut

sub cell_check {
  my $self = shift;
  my $class = $self -> crystal_class();
  my $aa    = $self->{A};
  my $bb    = $self->{B};
  my $cc    = $self->{C};
  my $alpha = $self->{Alpha};
  my $beta  = $self->{Beta};
  my $gamma = $self->{Gamma};
  my $from_cell = "";
 DETERMINE: {
				# cubic
    ((abs($aa-$bb)   < EPSILON) &&
     (abs($aa-$cc)   < EPSILON) &&
     (abs($bb-$cc)   < EPSILON) &&
     (abs($alpha-90) < EPSILON) &&
     (abs($beta-90)  < EPSILON) &&
     (abs($gamma-90) < EPSILON)) && do {
       $from_cell = "cubic";
       last DETERMINE;
     };
				# tetragonal
    ((abs($aa-$bb)   < EPSILON) &&
     (abs($aa-$cc)   > EPSILON) &&
     (abs($alpha-90) < EPSILON) &&
     (abs($beta-90)  < EPSILON) &&
     (abs($gamma-90) < EPSILON)) && do {
       $from_cell = "tetragonal";
       last DETERMINE;
     };
				# hexagonal or trigonal
    ((abs($aa-$bb)    < EPSILON) &&
     (abs($aa-$cc)    > EPSILON) &&
     (abs($alpha-90)  < EPSILON) &&
     (abs($beta-90)   < EPSILON) &&
     (abs($gamma-120) < EPSILON)) && do {
       $from_cell = "hexagonal";
       last DETERMINE;
     };
				# rhombohedral
    ((abs($aa-$bb)       < EPSILON) &&
     (abs($aa-$cc)       < EPSILON) &&
     (abs($bb-$cc)       < EPSILON) &&
     (abs($alpha-$beta)  < EPSILON) &&
     (abs($alpha-$gamma) < EPSILON) &&
     (abs($beta-$gamma)  < EPSILON)) && do {
       $from_cell = "hexagonal";
       last DETERMINE;
     };
				# orthorhombic
    ((abs($aa-$bb)   > EPSILON) &&
     (abs($aa-$cc)   > EPSILON) &&
     (abs($bb-$cc)   > EPSILON) &&
     (abs($alpha-90) < EPSILON) &&
     (abs($beta-90)  < EPSILON) &&
     (abs($gamma-90) < EPSILON)) && do {
       $from_cell = "orthorhombic";
       last DETERMINE;
     };
				# triclinic
    ((abs($aa-$bb)   > EPSILON) &&
     (abs($aa-$cc)   > EPSILON) &&
     (abs($bb-$cc)   > EPSILON) &&
     (abs($alpha-90) > EPSILON) &&
     (abs($beta-90)  > EPSILON) &&
     (abs($gamma-90) > EPSILON)) && do {
       $from_cell = "triclinic";
       last DETERMINE;
     };
				# monoclinic
    ((abs($aa-$bb) > EPSILON) &&
     (abs($aa-$cc) > EPSILON) &&
     (abs($bb-$cc) > EPSILON) &&
     ((abs($alpha-90) > EPSILON) ||
      (abs($beta-90)  > EPSILON) ||
      (abs($gamma-90) > EPSILON))) && do {
       $from_cell = "monoclinic";
       last DETERMINE;
     };
  };
  ( (($from_cell) eq "hexagonal") &&
    (($class eq "trigonal") || ($class eq "hexagonal")) ) &&
      return "";
  my $extra_message = "";
  ($extra_message = "Trigonal cells have x=y<>z and alpha=beta=90 and gamma=120.")
    if ($class eq "trigonal");
  ($extra_message = "Triclinic cells have all unequal axes and angles.")
    if ($class eq "triclinic");

  ($class eq $from_cell) || do {
    my $message = join("", $/, "  ",
		       "The axis lengths and angles specified are not",
		       $/,
		       "appropriate for the given space group.",
		       $/,
		       $extra_message,
		       $/, $/);
    return $message;
  };
  return "";
};

=over 4

=item C<get_symmetry_table>

Return the list of symmetry operations for a space group (and,
optionally, a setting).  This returns an anonymous list of lists.
Each list element contains three strings -- the three strings which
are eval-ed to generate the positions in the unit cell.

  $positions = $cell -> get_symmetry_table;
  @first_position = @ {$positions[0]};

=back

=cut

sub get_symmetry_table {
  my $self = shift;
  my $group = $self->{Space_group};
  my $positions = $self->{Setting};
  ($positions !~ /\b[0-5]\b/) || ($positions = "positions");
  (defined $$Xray::Xtal::r_space_groups{$group}{$positions}) &&
    return $$Xray::Xtal::r_space_groups{$group}{$positions};
  (defined $$Xray::Xtal::r_space_groups{$group}{b_unique}) &&
    return $$Xray::Xtal::r_space_groups{$group}{b_unique};
  (defined $$Xray::Xtal::r_space_groups{$group}{b_unique_1}) &&
    return $$Xray::Xtal::r_space_groups{$group}{b_unique_1};
  return [];
};




sub set_ipots {
  my $self = shift;
  my $style = $_[0];		# assignment scheme
  my $is_mol = $_[1];		# optional molecule flag
  my $tag = $_[2];		# optional central atom tag
  my $nip = 0;
  my %ipots = ();
  my $which;
  STYLES: {
      ($style eq "species") && do {
	$which = 'Element'; last STYLES;
      };
      ($style eq "tags")    && do {
	$which = 'Tag';     last STYLES;
      };
      ($style eq "sites")   && do {
	$which = 'Id';      last STYLES;
      };
    };
  foreach my $site (@{$self->{Contents}}) {
    #require Data::Dumper;
    #print Data::Dumper->Dump([\$site],[qw(*site)]);
    next unless ( $ {$$site[3]}->{Host} );
    next if ( $is_mol and (lc($tag) eq lc($ {$$site[3]}->{Tag})) );
    my $this = $ {$$site[3]}->{$which};
    ($style eq "tags") or $this = lc($this);
    (exists $ipots{$this}) or ($ipots{$this} = ++$nip);
  };
  return %ipots;
};


sub describe_group {
  my $group = $_[0];
  return $$Xray::Xtal::r_space_groups{$group};
};



1;


######################################################################

=head2 The Site object

The Site object is a blessed hash.  It predefines several attributes
of a Site, but allows the user to define new attributes on the fly.
The predefined (i.e. the ones that are used in Atoms) attributes are:

=over 4

=item B<Element>

The two letter symbol for the chemical species.

=item B<Tag>

A character string identifying a unique crystallographic site.

=item B<X>, B<Y>, B<Z>

The fractional coordinates of the sites (but see L<"MOLECULES"> below).

=item B<B>

The thermal spheroid parameter for the site.

=item B<Valence>

The formal valence for the element occupying the site.

=item B<Occupancy>

The fractional occupancy of the site.  This allows the user to specify
dopants.

=item B<Host>

This is 1 if the site is a host atom and 0 if it is a dopant.

=item B<Positions>

This takes an anonymous array of symmetry equivalent sites.  This is
filled after calling the C<populate> method.

=item B<File>

The name of an external file to be used with the site.

=item B<Id>

A pseudo-random number assigned by the C<new> method to uniquely
identify the object.

=item B<Color>

The color assigned to the site in a ball-and-stick image.

=back


=head2 Methods and Functions of the Site Package

See the descriptions of C<attributes> and C<clear> in the Cell Package
section.

=cut

package Xray::Xtal::Site;

use constant EPSILON => 0.00001;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
require Xray::Xtal;

@ISA = qw(Exporter AutoLoader Xray::Xtal);
@EXPORT_OK = qw(canonicalize_coordinate);

use Carp;
use Chemistry::Elements qw(get_name get_Z get_symbol);

use vars qw($molecule);
$molecule = 0;

## constructor for a new crystallographic site
sub new {
    my $classname = shift;
    my $self = {};
    my $index = shift || 0;
    $self->{Element}   = q{};
    $self->{Tag}       = q{};
    $self->{Utag}      = q{};
    $self->{X}         = 0;
    $self->{Y}         = 0;
    $self->{Z}         = 0;
    $self->{B}         = 0;
    $self->{Bx}        = 0;	  # |
    $self->{By}        = 0;	  #  > crystallographic thermal factors
    $self->{Bz}        = 0;	  # |
    $self->{Valence}   = 0;	  # intended for Cromer-Mann tables
    $self->{Occupancy} = 1;
    $self->{Host}      = 1;
    $self->{Positions} = 0;	  # filled in by populate method
    $self->{Formulas}  = 0;	  # filled in by populate method
    $self->{File}      = q{};
    $self->{Id}        = int(rand 100000) + 1;
    bless($self, $classname);
    $self->{Color}     = $self -> default_color($index);
    $self->{message_buffer} = q{},
    return $self;
};
## $self->{Dopants}   = 0;	  # a list of some sort...

## method for filling in attributes of a site
sub make {
    my $self = shift;
    my @attributes = qw(Element Tag X Y Z Bx By Bz Valence Color
			Occupancy Host Positions);
    ($#_ % 2) || do {
	my $this = (caller(0))[3];
	croak "$this takes an even number of arguments";
	return; };
    my $this_message = q{};
    while (@_) {
      my $att = ucfirst($_[0]);
      ## there are a few checks that can be done...
    ATT: {
	($att eq "Positions") && do {
	  my $this = (caller(0))[3];
	  ##carp "You should not set the Positions attribute of a site by hand$/";
	  ##carp "Use the populate method instead.$/";
	  $this_message = "You should not set the Positions attribute of a site by hand$/Use the populate method instead.$/";
	  $self->make(message_buffer => $self->{message_buffer} . $this_message);
	  last ATT;
	};
	($att eq "Id") && do {
	  my $this = (caller(0))[3];
	  ##carp "You should not set the Id attribute of a site by hand$/";
	  $this_message = "You should not set the Id attribute of a site by hand$/";
	  $self->make(message_buffer => $self->{message_buffer} . $this_message);
	  last ATT;
	};
	## element can be a symbol, name, or number
	## return "--" for an improper element
	($att eq "Element") && do {
	  my $sym = get_symbol($_[1]);
	  unless (defined $sym) {$sym = "--"};
	  $self->{"Element"} = $sym;
	  last ATT;
	};
	## occupancy must be between 0 and 1
	($att eq "Occupancy") && do {
	  if ($_[1] < 0) {
	    $self->{"Occupancy"} = 0;
	    $this_message = " " . $$Xray::Xtal::strings{site_occ} . $/;
	    $self->make(message_buffer => $self->{message_buffer} . $this_message);
	    last ATT;
	  };
	  if ($_[1] > 1) {
	    $self->{"Occupancy"} = 1;
	    $this_message = " " . $$Xray::Xtal::strings{site_occ} . $/;
	    $self->make(message_buffer => $self->{message_buffer} . $this_message);
	    last ATT;
	  };
	  $self->{"Occupancy"} = $_[1];
	  last ATT;
	};
	## thermal factors are positive definate (units of AA^2)
	($att =~ /B[xyz]/) && do {
	  my $val = ($_[1] > 0) ? $_[1] : 0;
	  $self->{$att} = $val;
	  last ATT;
	};
	## some other possibilities:
	## -- check valence against Cromer-Mann tables
	## -- convert color to an RGB triplet
	do {
	  $self->{ $att } =  $_[1];
	  $self->{ $att } =~ s/^\s+$//;
	};
      };
      shift; shift;
    }
    $self->{Tag} ||= ucfirst($self->{Element});
    unless ($molecule) {
      $self->{X}     = canonicalize_coordinate($self->{X});
      $self->{Y}     = canonicalize_coordinate($self->{Y});
      $self->{Z}     = canonicalize_coordinate($self->{Z});
    };
    return $self;
};

=over 4

=item C<reset_message_buffer>

Reset the message buffer for this object to the empty string.

=back

=cut

sub reset_message_buffer {
  my $self = shift;
  $self -> make(message_buffer => q{});
}

=over 4

=item C<clear>

Reset a site without destroying it.  For a site, this resets all
predefined attributes to their initial values and all user-defined
attributes to 0.

  $site -> clear();

=back

=cut
## reset a site without destroying it
sub clear {
    my $self = shift;
    foreach my $key (keys %$self) {
      next if ($key eq "Id");
      $self->{$key} = 0;
    };
    ## these three predefined attributes are reset to strings
    $self->{Element} = "";
    $self->{Tag}     = "";
    $self->{Color}   = "black";
    return $self;
};

=over 4

=item C<populate>

This applied the symmetry operations implied by the space group of the
Cell object C<$cell> to a unique crystallographic site.  The
collection of symmetry related sites will be stored in the site object
as the C<Positions> attribute.

  $site -> populate($cell);

Typically, it is not necessary to call this explicitly as it is called
for each site by the Cell populate method.

=back

=cut
## apply the symmetries of $group to a site, canonicalize to the first
## octant, and weed out the repeats.  This subroutine is the real
## workhorse of the Site package.
## input: reference to a cell object
## output: a list of lists, the coordinates of the equivalent sites in
##         the unit cell
sub populate {
  my $self = shift;
  my ($cell)  = $_[0];
  my $group   = $cell->{Space_group};
  my $given   = $cell->{Given_group};
  my $setting = $cell->{Setting};
  my $x	      = $self->{X};		# take x,y,z from $self
  my $y	      = $self->{Y};
  my $z	      = $self->{Z};
  my $utag    = "_" . $self->{Utag};
  my @list;
  my $bravais =  $cell->{Bravais};
  ## (@bravais) && (print join(",", @$bravais), "$/");

  #-------------------------- handle different settings as needed
  my $positions = "positions";
  my $crystal_class = $cell -> crystal_class();
  my $do_ortho = ($crystal_class eq "orthorhombic" ) && ($setting);
  my $do_tetr  = ($crystal_class eq "tetragonal" )   && ($setting);
  ($crystal_class eq "monoclinic") && do {
    $positions = $cell->{Setting};
				# bravais vector for the //given// symbol
  };
  ($group =~ /^r/i) && ($positions = $setting ? $setting : $positions);
  ($positions) || do {
    my $this = (caller(0))[3];
    croak "Invalid positions specifier in $this";
    return;
  };

  #-------------------------- permute to alternate settings (orthorhombic)
  #                           1..5 |--> [ ba-c, cab, -cba, bca, a-cb ]
  ($do_ortho) && do {
  FORWARD: {
      ($setting == 1) && do {
	( ($x, $y, $z) = (  $y,  $x, -$z) ); last FORWARD;
      };
      ($setting == 2) && do {
	( ($x, $y, $z) = (  $y,  $z,  $x) ); last FORWARD;
      };
      ($setting == 3) && do {
	( ($x, $y, $z) = (  $z,  $y, -$x) ); last FORWARD;
      };
      ($setting == 4) && do {
	( ($x, $y, $z) = (  $z,  $x,  $y) ); last FORWARD;
      };
      ($setting == 5) && do {
	( ($x, $y, $z) = (  $x,  $z, -$y) ); last FORWARD;
      };
    };
  };
  #-------------------------- rotate from F or C settings to P or I
  ($do_tetr) and do {
    ($x, $y) = ($x-$y, $x+$y);
    #my ($a, $b) = ($$r_cell->{A}, $$r_cell->{B});
    #$$r_cell -> make(A=>$a/sqrt(2), B=>$b/sqrt(2));
    #($$r_cell->{A}, $$r_cell->{B}) =
    #  ($$r_cell->{A}/sqrt(2), $$r_cell->{B}/sqrt(2));
  };

  ## ----- evaluate the coordinates safely
  ## see `perldoc Safe' for details
  my $message = $$Xray::Xtal::strings{tainted_sgdb} . $/;
  ## my $cpt = new Safe;
  ## ## need to load $x, $y, $z into the safe compartment
  ## $ {$cpt->varglob('x')} = $x;
  ## $ {$cpt->varglob('y')} = $y;
  ## $ {$cpt->varglob('z')} = $z;
  #print join("  ", $x, $y, $z, $/);

  #---------------------------- loop over all symmetry operations
  foreach my $position (@{ $$Xray::Xtal::r_space_groups{$group}{$positions} }) {
    my $i = 0;
    my ($xpos, $ypos, $zpos) = ( $$position[0], $$position[1], $$position[2] );

    foreach ($xpos, $ypos, $zpos) {
      ## the regex is intended to be an exhaustive list of characters
      ## found in the symmetry part of the space groups database.
      ## This is not bomber security as it is possible to, say,
      ## somehow alias "y56z-3" to "rm -rf ~".  But I think this will
      ## foil the casual black hat.
      ($_ =~ /([^-1-6xyzXYZ+\$\/])/) and
	Xray::Xtal::trap_error("$message\nfirst bad character: $1$/", 0);
    };
    ($xpos, $ypos, $zpos) = map {eval $_} ($xpos, $ypos, $zpos);

    ##print join("  ", $xpos, $ypos, $zpos, $/);
    my @f = @$position;		  # store formulas for this position
    map {s/\$//g} @f;		  # remove dollar sign
    map {s/([xyz])/$1$utag/g} @f; # append unique tag

    ## $ {$cpt->varglob('xx')} = $cpt->reval($xpos);
    ## $ {$cpt->varglob('yy')} = $cpt->reval($ypos);
    ## $ {$cpt->varglob('zz')} = $cpt->reval($zpos);
    ## ($xpos, $ypos, $zpos) = ($ {$cpt->varglob('xx')},
    ## 			     $ {$cpt->varglob('yy')},
    ## 			     $ {$cpt->varglob('zz')} );
    ## test_safe_return($message, $xpos, $ypos, $zpos);
    ## ----- end of safe evaluation

    my ($xposi, $yposi, $zposi) = ($xpos, $ypos, $zpos);

    #-------------------------- permute back from alt. settings (orthorhombic)
    ($do_ortho) && do {
      ($setting == 1) && (($xposi, $yposi, $zposi) = ( $yposi, $xposi,-$zposi));
      ($setting == 2) && (($xposi, $yposi, $zposi) = ( $zposi, $xposi, $yposi));
      ($setting == 3) && (($xposi, $yposi, $zposi) = (-$zposi, $yposi, $xposi));
      ($setting == 4) && (($xposi, $yposi, $zposi) = ( $yposi, $zposi, $xposi));
      ($setting == 5) && (($xposi, $yposi, $zposi) = ( $xposi,-$zposi, $yposi));
    };
    # need to rectify formulas for orthorhombic settings

    #-------------------------- permute back to F or C settings from P or I
    #($do_tetr) and ($x, $y) = ($x-$y, $x+$y);

    #-------------------------- canonicalize and push onto list
    ($xposi, $yposi, $zposi) = (&canonicalize_coordinate($xposi),
				&canonicalize_coordinate($yposi),
				&canonicalize_coordinate($zposi));
    push @list, [$xposi, $yposi, $zposi, @f];

    #-------------------------- do Bravais translations
    while ($i < $#{$bravais}) {
      ($xposi, $yposi, $zposi) = ($xpos+$$bravais[$i],
				  $ypos+$$bravais[$i+1],
				  $zpos+$$bravais[$i+2]);
      #------------------------ permute back from alt. settings (orthorhombic)
      ($do_ortho) && do {
      BACKWARD: {
	  ($setting == 1) && do {
	    (($xposi, $yposi, $zposi)=( $yposi, $xposi,-$zposi));
	    last BACKWARD;
	  };
	  ($setting == 2) && do {
	    (($xposi, $yposi, $zposi)=( $zposi, $xposi, $yposi));
	    last BACKWARD;
	  };
	  ($setting == 3) && do {
	    (($xposi, $yposi, $zposi)=(-$zposi, $yposi, $xposi));
	    last BACKWARD;
	  };
	  ($setting == 4) && do {
	    (($xposi, $yposi, $zposi)=( $yposi, $zposi, $xposi));
	    last BACKWARD;
	  };
	  ($setting == 5) && do {
	    (($xposi, $yposi, $zposi)=( $xposi,-$zposi, $yposi));
	    last BACKWARD;
	  };
	};
      };

      #-------------------------- canonicalize and push this bravais position
      ($xposi, $yposi, $zposi) = (&canonicalize_coordinate($xposi),
				  &canonicalize_coordinate($yposi),
				  &canonicalize_coordinate($zposi));
      my @ff = @f;		# append bravais translation to formulas
      map {$ff[$_] = $f[$_] . " + " . $$bravais[$i+$_]} (0 .. 2);
      push @list, [$xposi, $yposi, $zposi, @ff];
      $i+=3;
    };
  };
  #---------------------------- Weed out repeats.
  my @form = ();
  my %seen = ();
  my @uniq = ();		#   see section 4.6, p.102,
  foreach my $item (@list) {	#   The Perl Cookbook, 1st edition
    #my $keya = sprintf "%7.5f", $$item[0]; chop $keya;
    #my $keyb = sprintf "%7.5f", $$item[1]; chop $keyb;
    #my $keyc = sprintf "%7.5f", $$item[2]; chop $keyc;
    my $keya = sprintf "%6.4f", $$item[0]; chop $keya;
    my $keyb = sprintf "%6.4f", $$item[1]; chop $keyb;
    my $keyc = sprintf "%6.4f", $$item[2]; chop $keyc;
    my $key = $keya . $keyb . $keyc;
    unless ($seen{$key}++) {
      push (@uniq, [@$item[0..2]]);
      push (@form, [@$item[3..5]]);
    };
  };
  #---------------------------- return an anonymous array
  $self -> {Positions} = [@uniq];
  $self -> {Formulas}  = [@form];
  return $self;
};

## an unsafe string will result in an undefined value
sub test_safe_return {
  my $message = shift(@_);
  my @list = @_;
  foreach my $item (@list) {
    (defined $item) || Xray::Xtal::trap_error("$message$/", 0);
  };
  return 1;
};


my @default_color_list = qw(black red blue green brown orange yellow
			    cyan magenta grey);
sub default_color {
  my ($self, $index) = (shift, shift||0);
  $index %= 10;
  return $default_color_list[$index];
};

=over 4

=item C<canonicalize_coordinate>

This the subroutine is part of the Site package.  It takes a
fractional coordinate and returns it shifted into the first octant.
This is not actually a method of the Site class, it is just a normal
function.

  $coord = Xray::Xtal::Site::canonicalize_coordniate($coord);

=back

=cut

sub canonicalize_coordinate {
  my $pos = $_[0];
  return $pos if ($Xray::Xtal::Site::molecule == 1);
  $pos -= int($pos);		# move to first octant
  ($pos < -1*EPSILON) && ($pos += 1);
  (abs($pos) < EPSILON) && ($pos = 0);
 SYM: {				# positions of special symmetry
    if (abs($pos)        < 0.00001) {($pos = 0);   last SYM;}
    if (abs($pos-0.125)  < 0.00001) {($pos = 1/8); last SYM;}
    if (abs($pos-0.1666) < 0.00001) {($pos = 1/6); last SYM;}
    if (abs($pos-0.25)   < 0.00001) {($pos = 1/4); last SYM;}
    if (abs($pos-0.3333) < 0.00001) {($pos = 1/3); last SYM;}
    if (abs($pos-0.375)  < 0.00001) {($pos = 3/8); last SYM;}
    if (abs($pos-0.5)    < 0.00001) {($pos = 1/2); last SYM;}
    if (abs($pos-0.625)  < 0.00001) {($pos = 5/8); last SYM;}
    if (abs($pos-0.6666) < 0.00001) {($pos = 2/3); last SYM;}
    if (abs($pos-0.75)   < 0.00001) {($pos = 3/4); last SYM;}
    if (abs($pos-0.8333) < 0.00001) {($pos = 5/6); last SYM;}
    if (abs($pos-0.875)  < 0.00001) {($pos = 7/8); last SYM;}
    if (abs($pos-1)      < 0.00001) {($pos = 0);   last SYM;}
  };
  return $pos;
};

1;

package Xray::Xtal;
1;

# Autoload methods go after =cut, and are processed by the autosplit program.

__END__


=head1 INTERPRETING SPACE GROUP SYMBOLS

You may specify space group symbols in a variety of ways.  When
presented with a possible symbol, the Xtal module will first clean the
symbol up by adding and/or removing whitespace then by trying each of
the following ways of interpreting the symbol.

=over 4

=item 1.

A standard symbol from the 1995 edition of the International Tables
for Crystallography.  For example, the group for the cubic perovskite
structure is C<P m -3 m>.

=item 2.

A Schoenflies symbol.  The Scoenflies symbol for C<P m -3 m> is C<O_1^h>.

=item 3.

A symbol from the 1935 edition of the International tables.  The 1935
symbol for C<P m -3 m> is C<P m 3 m>.

=item 4.

The number for the entry of the space group in the International
Tables.  The number for C<P m -3 m> is 221.

=item 5.

The full symbol.  For C<P m -3 m> this is C<P 4/m -3 2/m>.

=item 6.

An alternative symbol.  See L<"LOW SYMMETRY SPACE GROUPS"> for details.

=item 7.

A shorthand phrase, such as C<fcc> for C<F m -3 m>.  See (somewhere)
for a complete list of shorthand phases.

=item 8.

A short symbol for a monoclinic space group.  See
L<"LOW SYMMETRY SPACE GROUPS"> for details.

=back

Since whitespace in the symbol is regularized, you can usually include
or omit whitespace in any fashion.  For example C<pm3m> and
C<P  m  -3  m> both come out as C<P m -3 m>, just
as you would expect.

A space group is specified using the C<make> method from the Cell
class.  When this is done the original symbol is stored in the
Given_group attribute of the Cell object and the standard symbol
interpreted from it is stored in the Space_group attribute.  If the
given symbol cannot be interpretted, the Space_group attribute is set
to 0.

In the future, more flexibility may be added to the space group symbol
interpretation scheme, including full symbols for alternate settings
and more obsolete notation.  I am open to suggestions.



=head1 LOW SYMMETRY SPACE GROUPS

There is a more complete discussion of low symmetry groups in the
Atoms document.  Here are the highlights:

=head2 Monoclinic Space Groups

Monoclinic groups can be quite confusing for the user.  Because any of
the three angles can be the unique (acute or obtuse rather than right)
angle and because there are three possible settings for the cell, the
standard symbol can be ambiguous.  In that case, using the full symbol
or the short monoclinic symbol would break the ambiguity and allow the
make method to correctly assign the space group.  An example would
help illustrate this.

In "Structural phase diagram of La(1-x)Sr(x)MnO(3+delta): Relationship
to magnetic and transport properties." by J.F. Mitchell et al,
Phys. Rev. B54, no. 9, (1996), pp./ 6172-6183 the monoclinic structure
for room temperature LnMnO3 is given in Table IV.  The space group is
given as C<P 21/c> and the setting is given as C<P 1 21/n 1>.
Specifying the space group symbol will result in the wrong application
of symmetries when the Contents attribute of the cell is filled.
Specifying the full symbol for that setting will work correctly.  The
shorthand C<P 21/n> will also result in a correct applciation of
symmetries.

In the Atoms document, there is a complete list of symbols recognized
by Atoms, including all the short and full symbols for the different
settings of monoclinic groups.  It is essential to always use site
coordinates and unique angles appropriate to the symbol (and vice
versa).

In the strange case of crystal data in a monoclinic setting but with
the unique angle equal to 90, it is necessary to specify the unique
angle like so

   $cell -> make(Angle=>'beta')

Without this, there is no way for the Cell class to know which setting
to use.

=head2 Orthorhombic Space Groups

You may use any setting of an orthorhombic crystal, although it is up
to you to be sure that the unique coordinates are appropriate to that
setting.  Atoms has no way of checking that!

=head2 Tetragonal Space Groups

F and C centered tetragonal cells are handled transparently by
Atoms. If you find a literature reference using one of these, you can
usually use the crystal data given in the article as written.

=head2 Rhombohedral Space Groups

You can specify either hexagonal or rhombohedral parameters for
rhombohedral space groups.  For the hexagonal representation, you must
specify C<a> and C<b> and C<c>, C<alpha>, C<beta>, and C<gamma> will
be set correctly by the C<make> method.  For the rhombohedral
representation, you must specify C<a> and C<alpha> and the rest will
be set appropriately.

=head1 CHANGE LOG

=over 4

=item *

Apr 26 2004: fixed the shift vector for space group #129. (thanks to
Pieter Glatzel)

=back

=head1 BUGS

Surely there are plenty.  Send me email if you find any.

=head1 AUTHOR

  Bruce Ravel <bruce@phys.washington.edu>
  http://feff.phys.washington.edu/~ravel/software/

=head1 SEE ALSO

The documentation that comes with the Atoms package.

=cut

## Local Variables:
## time-stamp-line-limit: 25
## End:
