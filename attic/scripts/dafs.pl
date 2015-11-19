#!/usr/bin/perl -w
my $cvs_info = '$Id: dafs.pl,v 1.5 2001/09/20 17:26:41 bruce Exp $ ';
## Time-stamp: <14 December, 2005>
######################################################################
## DAFS for Atoms version 3.0.1        copyright (c) 1998 Bruce Ravel
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
## This file is the main program for DAFS (command line).
##
## This version of atoms is intended for running from the command
## line.  It requires an input file identical to that used by the
## command line version of Atoms, but with a few additional keywords.
## Also the occupancy column in the input file is observed by this
## program, whereas it is ignored by Atoms.
######################################################################
## Code:


## =============================== load methods
require 5.004;
use strict;
use Carp;
use IO::File;
use Xray::Xtal;
$Xray::Xtal::run_level = 0;
use Xray::Atoms qw(build_cluster rcfile_name);
use Xray::ATP;
use File::Basename;
use File::Spec;
use Xray::Absorption;
use Xray::Scattering;
use POSIX qw/atan/;
## use Math::Complex;
$| = 1;
use constant PI    => 3.14159265358979323844;
use constant RE    => 0.00002817938;
use constant HBARC => 1973.27053324;

## =============================== process command line switches
use Getopt::Std;
use vars qw(%opt);
($opt{o}, $opt{r}, $opt{d}, $opt{T}) = ("", 0, "", 0);
getopts('ADvsqho:t:r:d:n:x:p:T:', \%opt);
$opt{s} and $opt{q} = 1;

my $matchstring = join("|", Xray::Absorption -> scattering);
if ($opt{d} =~ /\b($matchstring)\b/i) {
  Xray::Absorption -> load($opt{d});
} else {
  my %meta = Xray::Atoms -> rcvalues();
  Xray::Absorption -> load($meta{dafs_default});
};
die $$Xray::Atoms::messages{'require_fp'} unless
  (Xray::Absorption -> current_resource =~ /\b(Henke|Chantler|CL|Sasaki)\b/i);

my $file;
if ($opt{A}) {
  my $inp = $ARGV[0];
  unless ($inp =~ /\.inp$/) {
    $inp .= ($inp =~ /\.$/) ? 'inp' : '.inp';
  };
  $file = $Xray::Atoms::meta{ADB_location} . $inp;
} else {
  unless ($^O eq 'MacOS') {
  INPUT: {
      $file = "atoms.inp",       last INPUT if (not $ARGV[0]);
      ##$file = "dafs.inp",        last INPUT if (-e $file);
      $file = $ARGV[0],          last INPUT if (-e $ARGV[0]);
      $file = $ARGV[0] . ".inp", last INPUT if (-e "$ARGV[0].inp");
      $file = $ARGV[0] . "inp",  last INPUT if (-e "$ARGV[0]inp");
      die $ARGV[0] . ": " . $$Xray::Atoms::messages{'invalid_input'} . $/;
    };
  } else {
    require Mac::StandardFile;
    $file = Mac::StandardFile::StandardGetFile(0, 'TEXTclpt');
    if ($file -> sfGood()) {
      $file = $file->sfFile();
    } else {
      die "File opening canceled.  Atoms quitting.$/";
    };
  };
};
my $inputdir = dirname($file);	# this may not work as intended...


## =============================== run time screen messages
my $v		  = (split(" ", $cvs_info))[2] || "pre_release";
my $date	  = (split(" ", $cvs_info))[3] || "";
my $atoms_version = "3.0.1";
my $screen_line	  = "=" x 71;

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
 DAFS $v for Atoms $atoms_version ($^O) $date
$screen_line
EOH
unless ($opt{q});

my $absorption_resource = Xray::Absorption -> current_resource;
print STDOUT <<EOH
    by Bruce Ravel, copyright (c) 1999
    <ravel\@phys.washington.edu>

    using Atoms.pm $Xray::Atoms::module_version
          Xtal.pm $Xray::Xtal::VERSION with space groups database $Xray::Xtal::sg_version
          Absorption.pm $Xray::Absorption::cvs_version
          $absorption_resource

EOH
if ($opt{v});
exit if ($opt{v});


## =============================== define a cell, parse the input file,
my @sites   = ();		 # list of sites
my $cell = Xray::Xtal::Cell -> new();
my $keywords = Xray::Atoms -> new();
$keywords->make('program'=>'dafs', dafs=>0);
$opt{q} && $keywords->make('quiet'=>1);
$keywords->make('identity'=>"DAFS $v", 'emin'=>0, 'emax'=>0, 'estep'=>0);
$keywords -> parse_input($file);
die "\n" if $keywords->{cli_warn};
exists($keywords->{thickness}) or $keywords->{thickness} = 1;

## =============================== fill up the cell and the sites
$cell -> make( Space_group=>$keywords->{'space'} );
foreach my $param ('a', 'b', 'c', 'alpha', 'beta', 'gamma') {
  $cell -> make( $param=>$keywords->{$param} );
};
( @{$keywords->{'sites'}} ) or
  croak "$$Xray::Atoms::messages{no_sites} $file\n";

my $nsites = 0;
foreach my $this (@{$keywords->{'sites'}}) {
  $sites[$nsites] = Xray::Xtal::Site -> new();
  $sites[$nsites] -> make(Element=>$$this[0],
			  X=>$$this[1]+${$keywords->{"shift"}}[0],
			  Y=>$$this[2]+${$keywords->{"shift"}}[1],
			  Z=>$$this[3]+${$keywords->{"shift"}}[2] );
  ($$this[4]) && ( $sites[$nsites] -> make(Tag=>$$this[4]) );
  ($$this[5]) && ( $sites[$nsites] -> make(Occupancy=>$$this[5]) );
  ++$nsites;
};

## =============================== error check, populate the cell
$cell -> verify_cell();
$cell -> populate(\@sites);
$keywords -> verify_keywords($cell, \@sites, 0);

## =============================== set bounds of calculation
($opt{n}) and $keywords->make('emin'	 => $opt{n});
($opt{x}) and $keywords->make('emax'	 => $opt{x});
($opt{p}) and $keywords->make('estep'	 => $opt{p});
($opt{T}) and $keywords->make('thickness' => $opt{T});
my ($central, $xc, $yc, $zc) = $cell -> central($keywords->{'core'});
my $edge = $keywords->{'edge'};
my $e0 = Xray::Absorption -> get_energy($central, $edge);
my $emin = $keywords->{'emin'} || 300;
my $emax = $keywords->{'emax'} || 500;
($emin, $emax) = ($e0-$emin, $e0+$emax);
my $estep = $keywords->{'estep'} || 15;
($estep <= 0) and $estep = 15;	# some error checking
($emin > $emax) and ($emin, $emax) = ($emax, $emin);
$keywords -> make('emin'=>$emin, 'emax'=>$emax, 'estep'=>$estep);
my $e = $emin;

## =============================== set reflection
my @reflection;
if (length($opt{r}) == 3) {
  @reflection = map {sprintf "%d", $_} split("", $opt{r});
  $keywords->make("qvec"=>split("", $opt{r}));
} else {
  die $$Xray::Atoms::messages{'no_reflection'} . $/
    unless (defined @{$keywords->{'qvec'}} and @{$keywords->{'qvec'}});
  @reflection = @{$keywords->{'qvec'}};
};
my $d = $cell -> d_spacing(@reflection);

## =============================== cache the f0 and phase values
my ($contents) = $cell -> attributes("contents");
my %fnot;
my @phase;
my $counter = 0;
foreach my $s (@{$contents}) {
  my ($e, $v) = $ {$$s[3]} -> attributes('Element', 'Valence');
  my $sym = Xray::Scattering->get_valence($e, $v);
  $ {$$s[3]} -> make('CromerMann'=>$sym);
  $fnot{$sym} = Xray::Scattering->get_f($sym, $d);
  $phase[$counter] = $$s[0] * $reflection[0] + $$s[1] * $reflection[1] +
    $$s[2] * $reflection[2];
  $phase[$counter] *= 2*PI;
  ++$counter;
};

## =============================== dump...
if ($opt{D}) {
  use Data::Dumper;
  print Data::Dumper->Dump([$keywords, $cell, \%fnot],
			   [qw/*keywords *cell *fnot/]);
  exit;
};

## =============================== the big energy loop
($keywords->{"quiet"}) or
  print STDOUT " ", $$Xray::Atoms::messages{'calculating_dafs'}, " ...", $/;
my (%fp, %fpp, $ampsqr, $r, $i, $la, %mu, $mutot, @calculation);

my $lambda = 2*PI*HBARC / $e;
my $dsp = $cell -> d_spacing(@reflection);
my $sinthnot = $lambda / (2 * $cell -> d_spacing(@reflection));
my $munot = Xray::Atoms::xsec($cell, $central, $e);
$munot *= 10e-8; # undef $dens;
my $absnot = (1 - exp(-2*$keywords->{thickness}*$munot/$sinthnot)) / (2*$munot);
my $sinth;

## ------------------------------------------------------------------------
## cache all anomalous scattering values for this calculation
foreach my $s (@{$contents}) {
  my ($el) = $ {$$s[3]} -> attributes('Element');
  next if exists $fp{$el};
  $fp{$el} = [];
};
my $ee = $e;
my @energies = ();
while ($ee < $emax) {
  push @energies, $ee;
  $ee += $estep;
};
my $foo = 0;
foreach my $l (keys %fp) {
  @{$fp{$l}}  = Xray::Absorption -> cross_section($l, \@energies, 'f1');
  @{$fpp{$l}} = Xray::Absorption -> cross_section($l, \@energies, 'f2');
  my $factor  = Xray::Absorption -> get_conversion($l);
  my $weight  = Xray::Absorption -> get_atomic_weight($l);
  foreach my $i (0 .. $#energies) {
    my $lambda    = 2 * PI * HBARC / $energies[$i];
    ${$mu{$l}}[$i] = 2*RE * $lambda * ${$fpp{$l}}[$i] *
                     0.6022045 * 1e8 * $factor / $weight;
  };
  ##@{$mu{$_}}  = Xray::Absorption -> cross_section($_, \@energies, 'xsec');
};
my @total = Xray::Atoms::xsec($cell, $central, \@energies);
## ------------------------------------------------------------------------

my $pt = 0;
while ($e < $emax) {
  ($r, $i, $la) = (0,0,0);		 ## clear these at each energy
  $mutot = 0;
  $counter = 0;
  $lambda = 2*PI*HBARC / $e;
  $sinth = $lambda / (2 * $dsp);
  foreach my $s (@{$contents}) {
    my ($el, $sym, $occ, $id) =
      $ {$$s[3]} -> attributes('Element', 'CromerMann', 'Occupancy', 'Id');
    my $phase = $phase[$counter];
    my $fone = $fnot{$sym} + $ {$fp{$el}}[$pt];
    my $ftwo = $ {$fpp{$el}}[$pt];
    ## do the complex arithmatic by hand
    $r += $occ * ($fone * cos($phase) - $ftwo * sin($phase));
    $i += $occ * ($fone * sin($phase) + $ftwo * cos($phase));
    $mutot += $occ * $ {$mu{$el}}[$pt];
    ++$counter;
  };
  ## Lorentz and absoprtion correction
  $total[$pt] *= 10e-8;
  $la = (1 - exp(-2*$keywords->{thickness}*$total[$pt]/$sinth)) / (2*$total[$pt]);
  $la /= $absnot;
  $la *= ($emin**3 * $sinthnot) / ($e**3 * $sinth);
  my $this_energy = [$e, $r, $i, $la];
  push @calculation, $this_energy;
  $e += $estep;			# increment energy
  ++$pt;
};

## =============================== open the output file and make the file header
my ($fh, $atp, $outfile);
if (defined %{$keywords->{'atp'}}) {
 LOOP: while (($atp, $outfile) = each(%{$keywords->{'files'}})) {
    last LOOP;			# just the first (should only be one)
  };				# there must be a better way!
} else {
  $atp = 'dafs';
  $outfile = sprintf("dafs_%d%d%d.dat", @reflection);
};
($opt{t}) and $atp = $opt{t};
if ($opt{s}) {
  $fh = *STDOUT;
  $outfile = "to standard output";
} else {
  ($opt{o}) and $outfile = $opt{o};
  unless ($keywords->{'write_to_pwd'}) {
    $outfile = File::Spec -> catfile($inputdir, $outfile);
  };
  $fh = IO::File->new();
  open $fh, ">".$outfile
    or die $$Xray::Atoms::messages{cannot_write} . $outfile . $/;
}

my $data = "";
my @neutral;
my ($default_name, $is_feff) =
  &parse_atp($atp, $cell, $keywords, \@calculation, \@neutral, \$data);
print $fh $data;
($opt{s}) or close $fh;

## =============================== finish up
($keywords->{"quiet"}) or
  print STDOUT " ", $atp, ": ", $$Xray::Atoms::messages{'writing'},
  " ", $outfile, $/;
($keywords->{"quiet"}) or print STDOUT $screen_line, $/, $/;
1;

######################################################################
## End of main program atoms

=head1 NAME

DAFS - Simulate energy dependent scattering factors

=head1 SYNOPSIS

   dafs -r hkl [-t file] [-o file] [-d data_resource]
          [-n #] [-x #] [-p #] [-sqvh] <input_file>

=head1 DESCRIPTION

Take crystallographic data from the input file given on the command
line and write a file containing the energy dependent scattering
factor for the crystal.  Tables of f' and f" are used along with
tables of the Thomson scattering.  The input file for this program is
almost identical to Atoms' input file.  See the Atoms documentation
for a complete description of the input file.

The keywords "emin", "emax", "estep", "qvec", and "feout" are
recognized by DAFS and ignored by Atoms.  If no input file is given at
the command line, F<atoms.inp> is used.  Several command line switches
can be used to override the contents of the input files.

 command line switches:
    -r ### hkl of a reflection (only hkl between 0 and 9)
    -T ### sample thickness in Angstroms
    -t s   atp file to use for the output (default is 'dafs')
    -o s   output file name (default is 'dafs_hkl.dat')
    -d s   name of absorption data resource (default is Henke)
    -n #   lower bound of energy relative to edge (eV)
    -x #   upper bound of energy relative to edge (eV)
    -p #   energy step (eV)
    -A     use a named file from the Atoms Database
    -s     write calculation to standard output
    -q     suppress all screen messages
    -v     write version information and exit
    -h     write this help message and exit

         # = number    s = string

For complete information about DAFS, consult the documentation.

=head1 AUTHOR

  Bruce Ravel, bruce@phys.washington.edu
  http://feff.phys.washington.edu/~ravel

=cut
