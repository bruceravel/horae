#!/usr/bin/perl -w
my $cvs_info = '$Id: powder.pl,v 1.3 2001/09/20 17:28:26 bruce Exp $ ';
## Time-stamp: <14 December, 2005>
######################################################################
## Powder for Atoms version 3.0beta9
##                                     copyright (c) 2000 Bruce Ravel
##                                          ravel@phys.washington.edu
##                            http://feff.phys.washington.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##	 http://feff.phys.washington.edu/~ravel/software/atoms/
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
## This reads input files for Atoms and simulates the powder
## diffraction spectrum for that crystal.  Do `powder.pl -h' for
## details.
######################################################################

##use lib '/usr/local/share/ifeffit/perl';
## =============================== load methods
require 5.004;
use strict;
use Carp;
use Xray::Xtal;
$Xray::Xtal::run_level = 0;
use Xray::ATP;
use Xray::Absorption;
use Xray::Scattering;
use IO::File;
use File::Basename;
use Cwd;
use constant EPSI  => 0.01;
use constant PI    => 4 * atan2 1, 1;
use constant HBARC => 1973.27053324;

## =============================== process command line switches
use Getopt::Std;
use vars qw(%opt);
$opt{o} = "";
getopts('ADIvqhst:o:e:m:', \%opt);


my ($file, $inputdir);
if ($ARGV[0] and ($ARGV[0] eq '-')) {		# read from STDIN
  $file = '____stdin';		# an unlikely string (I hope)
  $inputdir = cwd;
} elsif ($opt{A}) {
  my $inp = $ARGV[0];
  unless ($inp =~ /\.inp$/) {
    $inp .= ($inp =~ /\.$/) ? 'inp' : '.inp';
  };
  $file = $Xray::Atoms::meta{ADB_location} . $inp;
  $inputdir = cwd;
} else {
  unless ($^O eq 'MacOS') {
  INPUT: {
      $file = "atoms.inp",       last INPUT if (not $ARGV[0]);
      $file = $ARGV[0],          last INPUT if (-e $ARGV[0]);
      $file = $ARGV[0] . ".inp", last INPUT if (-e "$ARGV[0].inp");
      $file = $ARGV[0] . "inp",  last INPUT if (-e "$ARGV[0]inp");
      die $ARGV[0] . ": " . $$Xray::Atoms::messages{'invalid_input'} . $/;
    }
  } else {
    require Mac::StandardFile;
    $file = Mac::StandardFile::StandardGetFile(0, 'TEXTclpt');
    if ($file -> sfGood()) {
      $file = $file->sfFile();
    } else {
      die "File opening canceled.  Powder quitting.$/";
    };
  };
  $inputdir = dirname($file);	# if write_to_pwd is false...
}

my @sites   = ();		# list of sites
my @cluster = ();		# spherical cluster
my @neutral = ();		# charge neutral rhomboidal cluster

## =============================== run time screen messages
my $v		= $Xray::Atoms::VERSION;
my $date	= (split(" ", $cvs_info))[3] || '';
my $scriptv	= (split(" ", $cvs_info))[2] || 'pre-release';
my $screen_line = "=" x 71;

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

print STDOUT <<EOH
$screen_line
 Powder $scriptv ($^O) $date
$screen_line
EOH
unless ($opt{q});

my $resource = (grep /CL/, Xray::Absorption->scattering()) ? 'CL' : 'Chantler';
$opt{I} and ($resource = "None");
Xray::Absorption -> load($resource);

my $absorption_resource = Xray::Absorption -> current_resource;
print STDOUT <<EOH
    by Bruce Ravel copyright (c) 2000
    <ravel\@phys.washington.edu>

    powder.pl for Atoms $v
    using Atoms.pm $Xray::Atoms::module_version, ATP.pm $Xray::ATP::module_version
          Xtal.pm $Xray::Xtal::VERSION, space groups database $Xray::Xtal::sg_version
          Absorption.pm $Xray::Absorption::cvs_version
          $absorption_resource
    with perl $] on $^O.

EOH
and exit if ($opt{v});

## =============================== define a cell, parse the input file,
my $cell = Xray::Xtal::Cell -> new();
my $keywords = Xray::Atoms -> new();
$opt{q} && $keywords->make('quiet'=>1);
$keywords -> parse_input($file, 0);
die "\n" if $keywords->{cli_warn};
($opt{c}) && $keywords->make(core=>$opt{c});
$keywords->make('identity'=>"Powder $scriptv", die=>0);

## =============================== determine the energy at which to calculate
($resource eq 'None') or Xray::Absorption -> load('elam');
if ($opt{e}) {			# see Cookbook recipe 2.1
  unless ($opt{e} =~ /^(?:\d+(?:\.\d*)?|\.\d+)$/) { # regex matching a number
    my ($el, $en) = ("", "");
    ($el, $en) =  split(/[-_]/, $opt{e});
    $opt{e} = Xray::Absorption -> get_energy($el, $en);
  };
};
my $energy = $opt{e} || $keywords->{energy} ||
  Xray::Absorption -> get_energy('Cu', 'kalpha1');
my $lambda  = 2*PI*HBARC / $energy;
## the cutoff with this trick is about 111.3
($lambda > $energy) and (($lambda, $energy) = ($energy, $lambda));
$keywords->make('energy'=>$energy, 'lambda'=>$lambda);

($resource eq 'None') or Xray::Absorption -> load($resource);

## =============================== fill up the cell and the sites
$cell -> make( Space_group=>$keywords->{'space'} );
foreach my $param ('a', 'b', 'c', 'alpha', 'beta', 'gamma') {
  $cell -> make( $param=>$keywords->{$param} );
};
($file eq '____stdin') and $file = 'the input data';
( @{$keywords->{'sites'}} ) or croak "$$Xray::Atoms::messages{no_sites} $file$/";

my $nsites = 0;
foreach my $this (@{$keywords->{'sites'}}) {
  $sites[$nsites] = Xray::Xtal::Site -> new($nsites);
  $sites[$nsites] -> make(Element=>$$this[0],
			  X=>$$this[1]+${$keywords->{"shift"}}[0],
			  Y=>$$this[2]+${$keywords->{"shift"}}[1],
			  Z=>$$this[3]+${$keywords->{"shift"}}[2] );
  ($$this[4]) && ( $sites[$nsites] -> make(Tag=>$$this[4]) );
  ($$this[5]) && ( $sites[$nsites] -> make(Occupancy=>$$this[5]) );
  ## cache f' and f" for this site and this energy
  $sites[$nsites] ->
    make(F1=>scalar Xray::Absorption->cross_section($$this[0],$energy,'f1'));
  $sites[$nsites] ->
    make(F2=>scalar Xray::Absorption->cross_section($$this[0],$energy,'f2'));
  ++$nsites;
};


## =============================== error check, populate the cell, set rmax
$cell -> verify_cell();
$cell -> populate(\@sites);
$keywords -> verify_keywords($cell, \@sites, 0, 1);

## =============================== some error checking
($opt{q}) or print $cell -> warn_shift(), $cell -> cell_check();

## =============================== dump...
if ($opt{D}) {
  use Data::Dumper;
  print Data::Dumper->Dump([$keywords, $cell], [qw/*keywords *cell/]);
  exit;
};

## =============================== determine bounds of calculation
my $max_order = $keywords -> {maxorder} || 0;
## the $max_order variable will be eval-ed a little below.  thus we
## must do some taint checking of the value of the $opt{m} variable
if ($opt{m}) {
  if ($opt{m} =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
    $max_order = int($opt{m});
  } else {
    warn "max_order should be an integer or a float$/";
  };
};
##   require Safe;
##   my $cpt = new Safe;
##   $ {$cpt->varglob('m')} = $cpt->reval($opt{m});
##   $max_order = $ {$cpt->varglob('m')};
##   ($max_order) || warn " Tainted value for max_order found.  Reset to default.$/";
$max_order ||= 12;

my $class = $cell -> crystal_class;
my ($hrange, $krange, $lrange);
CLASS: {
  ($class eq 'cubic') and do {
    $hrange = "(0 .. \$max_order)";
    $krange = "(0 .. \$h)";
    $lrange = "(0 .. \$k)";
    last CLASS;
  };
  ($class eq 'trigonal') and do {
    die " Sorry, no trigonal yet$/";
  };
  (($class eq 'hexagonal') or ($class eq 'tetragonal')) and do {
    $hrange = "(0 .. \$max_order)";
    $krange = "(0 .. \$h)";
    $lrange = "(0 .. \$max_order)";
    last CLASS;
  };
  do {				# ortho, mono, tri
    $hrange = "(0 .. \$max_order)";
    $krange = "(0 .. \$max_order)";
    $lrange = "(0 .. \$max_order)";
    last CLASS;
  };
};


$$Xray::Atoms::messages{powder_comp} = "Computing powder diffraction";
($opt{q}) or printf " %s -- %8.2f eV (%.4f Å)$/",
  $$Xray::Atoms::messages{powder_comp}, $energy, $lambda;
my %peaks;
foreach my $h (eval $hrange) {
  foreach my $k (eval $krange) {
    foreach my $l (eval $lrange) {
      next unless $h||$k||$l;	# watch out for (0,0,0)

      my %f0 = ();
      my $d = $cell -> d_spacing($h, $k, $l);
      next if (($lambda / (2*$d)) > 1);	# unreachable reflections at this energy

      my $theta   = asin($lambda / (2*$d));
      $theta     *= 180/PI;
      my $twoth   = $theta * 2;

      my ($real, $imag, $m) = (0, 0, 0);
      foreach my $s (@sites) {
	my ($positions, $tag, $elem, $occ, $f1, $f2, $b) =
	  $s -> attributes('Positions', 'Tag', 'Element', 'Occupancy', 'F1', 'F2', 'B');
	$f0{$elem} ||= Xray::Scattering->get_f($elem, $d); # memoize for a bit of speed
	my ($freal, $fimag) = ($f0{$elem}+$f1, $f2);
	foreach my $pos (@$positions) {
	  my $phase = $$pos[0]*$h + $$pos[1]*$k + $$pos[2]*$l;
	  $phase   *= 2 * PI;
	  $real    += $occ * (cos($phase)*$freal - sin($phase)*$fimag);
	  $imag    += $occ * (sin($phase)*$freal + cos($phase)*$fimag);
	};
	$m = $b*(sin($theta)/$lambda)**2;
      };
      (abs($real) < EPSI) and $real = 0;
      (abs($imag) < EPSI) and $imag = 0;
      next unless ($real or $imag);
      ## just cache the values of the structure factor.  computing
      ## intensity will happen when the atp file is parsed
      @{$peaks{$twoth}} = ($h, $k, $l, $real, $imag, $m);
    };
  };
};

## sort and prep for atp
my @calculation;
foreach my $tth (sort {$a <=> $b} (keys(%peaks))) {
  push @calculation, [$tth, @{$peaks{$tth}}];
};


## =============================== open the output file and make the file header
my ($fh, $atp, $outfile);
if (defined %{$keywords->{'atp'}}) {
 LOOP: while (($atp, $outfile) = each(%{$keywords->{'files'}})) {
    last LOOP;			# just the first (should only be one)
  };				# there must be a better way!
} else {
  $atp = 'powder';
};
($atp =~ /^powder/) and ($atp = 'powder');
($opt{t}) and $atp = $opt{t};
my $data = "";
my ($default_name, $is_feff) =
  &parse_atp($atp, $cell, $keywords, \@calculation, \@neutral, \$data);

if ($opt{s}) {
  $fh = *STDOUT;
  $outfile = "to standard output";
} else {
  $outfile = $opt{o} || $default_name;
  unless ($keywords->{'write_to_pwd'}) {
    $outfile = File::Spec -> catfile($inputdir, $outfile);
  };
  $fh = IO::File->new();
  open $fh, ">".$outfile
    or die $$Xray::Atoms::messages{cannot_write} . $outfile . $/;
}

print $fh $data;
($opt{s}) or close $fh;

($opt{q}) or
  print STDOUT " $atp: ", $$Xray::Atoms::messages{'writing'}, " ", $outfile, $/;

## =============================== finish up
($opt{q}) or print STDOUT $screen_line, $/, $/;

sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }


1;

######################################################################
## End of main program powder

=head1 NAME

Powder - Simulate powder diffraction for a crystal

=head1 SYNOPSIS

   powder [-m#] [-e#] [-AIqvh] [-t atptype] [-o file] input_file

=head1 DESCRIPTION

Take crystallographic data from the input file given on the command
line and compute a powder diffraction simulation for the crystal
described in the that input file.  By default, the simulation is made
at the copper Kalpha1 energy, although a different energy can be
specified.  If the input file specified at the command line is '-',
then input is read from STDIN.  Several command line switches can be
used to override the contents of the input files.

 output file flags
    -t s  user supplied template   -o f  output file name
    -O    write to STDOUT

 operational flags
    -I    ignore anomalous corrections to the scattering factors
    -A    use a named file from the Atoms Database
    -e #  override the value of energy with the given value
    -m #  override the value of maxorder with the given value (12)
    -q    suppress screen messages
    -v    write version information and exit
    -h    write this message and exit

               # = number   f = file   s = string

The argument to -e can be an energy, a wavelength, or a string such as
"cu_kalpha1" or "Pt-Lbeta2" (i.e. an element symbol and a line symbol
separated by a dash or an underscore, case does not matter).  Line
energies from the Elam tables (see L<Xray::Absorption::Elam>) are
used.

For complete information about Powder and/or Atoms, consult the
documentation.

=head1 AUTHOR

Bruce Ravel, ravel@phys.washington.edu

my homepage

   http://feff.phys.washington.edu/~ravel/

the Atoms homepage

   http://feff.phys.washington.edu/~ravel/software/atoms/

=cut
