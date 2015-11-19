#! /usr/bin/perl -w
######################################################################
## This is the Xray::Atoms.pm module.  It contains various subroutines
## used by the various versions of atoms.  See the pod for details and
## one of the atoms versions for how they are implemented.
##
##  This program is copyright (c) 1998-2006, 2009 Bruce Ravel
##  <bravel@anl.gov>
##  http://cars9.uchicago.edu/~ravel/software/
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
## Time-stamp: <2009-01-08 09:00:10 bruce>
######################################################################
## Code:

=head1 NAME

Xray::Atoms - Utilities and data structures for the Atoms program

=head1 SYNOPSIS

  use Xray::Xtal;
  use Xray::Atoms qw(parse_input keyword_defaults parse_atp
		     absorption mcmaster);

=head1 DESCRIPTION

This module contains the utility subroutines used by the program
Atoms.  It defines a number of exportable routines for performing
chores specific to Atoms.  It also defines an object for storing input
data to the various programs which use this file.  For details about
the crystallographic objects used by Atoms, see L<Xray::Xtal>.

There are several versions of Atoms with different user interfaces all
of which use routines from this module.  These include the command
line, Tk, and CGI versions.

=cut
;

package Xray::Atoms;

use strict;
use vars qw($VERSION $atoms_dir $languages @available_languages
	    $cvs_info $module_version $messages @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(build_cluster number rcdirectory rcfile_name
		absorption mcmaster i_zero self);

$VERSION = '3.0beta10';
$cvs_info = '$Id: Atoms.pm,v 1.40 2001/12/21 02:28:44 bruce Exp $ ';
$module_version = 1.41; #(split(' ', $cvs_info))[2];

use Carp;
##use Safe;
use Xray::Xtal;
use Xray::Absorption;
use Xray::FluorescenceEXAFS;
use Chemistry::Elements qw(get_name get_Z get_symbol);
use Statistics::Descriptive;
use Text::Abbrev;
use File::Basename;
use Ifeffit::FindFile;
my $STAR_Parser_exists = (eval "require STAR::Parser");
if ($STAR_Parser_exists) {
  import STAR::Parser;
  require STAR::DataBlock;
  import STAR::DataBlock;
};

#use constant EV2RYD => 13.605698;
use constant EPSILON => 0.00001;

my $elem_match = '([BCFHIKNOPSUVWY]|A[cglrstu]|B[aeir]|C[adelorsu]|Dy|E[ru]|F[er]|G[ade]|H[efgo]|I[nr]|Kr|L[aiu]|M[gno]|N[abdeip]|Os|P[abdmortu]|R[abehnu]|S[bceimnr]|T[abcehilm]|Xe|Yb|Z[nr])';

## location of atp files
use File::Spec;
use vars qw($atp_dir $lib_dir $is_windows);
$is_windows = $Ifeffit::FindFile::is_windows;
$atoms_dir = Xray::Xtal::identify_self();
$atp_dir = ($is_windows) ?
  Ifeffit::FindFile->find("atoms", "atp_sys") :
  File::Spec->catfile($atoms_dir, "atp");
$lib_dir = ($is_windows) ?
  Ifeffit::FindFile->find("atoms", "xray_lib") :
  File::Spec->catfile($atoms_dir, "lib");

## my $languagerc = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
##   File::Spec->catfile($lib_dir, "languages");
## eval "do '$languagerc'" or warn "Language rc file not found.  Using English.$/";


use vars qw(%meta %colors %fonts);
## use vars qw($always_write_feff $atoms_language $write_to_pwd
## 	    $prefer_feff_eight $absorption_tables $dafs_default
## 	    $plotting_hook $default_filepath $unused_modifier
## 	    $display_balloons $no_crystal_warnings $one_frame $convolve_dafs
## 	    $never_ask_to_save $ADB_location);
%meta = (ADB_location        => "http://cars9.uchicago.edu/atomsdb/",
	 absorption_tables   => 'elam',
	 always_write_feff   => 0,
	 atoms_language	     => 'english',
	 convolve_dafs	     => 1,
	 dafs_default	     => 'cl',
	 default_filepath    => '',
	 display_balloons    => 1,
	 never_ask_to_save   => 0,
	 no_crystal_warnings => 0,
	 one_frame	     => 1,
	 plotting_hook	     => '',
	 prefer_feff_eight   => 0,
	 unused_modifier     => 'Shift',
	 write_to_pwd	     => 1,
	);

## keep these refs to anon hashes so as not to break rcfiles from
## alpha16 and earlier
## use vars qw();	# unused variables from atomsrc
## ## must declare variables for colors and fonts for TkAtoms
## use vars qw($c_foreground $c_background $c_trough $c_entry $c_label
## 	    $c_balloon $c_button $c_buttonActive $c_sgbActive $c_sgbGroup
## 	    $c_done $c_todo $c_plot
## 	    $f_balloon $f_label $f_menu $f_button $f_header $f_entry $f_sgb);

use vars qw($rcfile);
$rcfile = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
  File::Spec->catfile($lib_dir, "tkatoms.ini"):
  File::Spec->catfile($lib_dir, "atomsrc");
(-e $rcfile) and &read_rc($rcfile);
my $users_rc = &rcfile_name;
(-e $users_rc) and &read_rc($users_rc);
$meta{atoms_language}    = lc($meta{atoms_language});
$meta{absorption_tables} = lc($meta{absorption_tables});
Xray::Absorption -> load($meta{absorption_tables});
#Xray::Absorption -> load('Elam');
$meta{unused_modifier}   = ucfirst($meta{unused_modifier});
($meta{unused_modifier} =~ /Alt|Control|Meta|Shift/) or
  $meta{unused_modifier} = 'Shift';

my $language_file;
if (not $languages) {
  $language_file = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
    File::Spec->catfile($lib_dir, "atomsrc.en"):
      File::Spec->catfile($lib_dir, "atomsrc.en");
} else {
  $language_file = "atomsrc." . $$languages{$meta{atoms_language}};
  $language_file = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
    File::Spec->catfile($lib_dir, $language_file):
      File::Spec->catfile($lib_dir, $language_file);
  unless (-e $language_file) {
    $language_file = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
      File::Spec->catfile($lib_dir, "atomsrc.en"):
	File::Spec->catfile($lib_dir, "atomsrc.en");
  };
};
eval "do '$language_file'";	# read strings
($meta{atoms_language} eq 'english') or
  Xray::Xtal::set_language($meta{atoms_language});

my $overfull_margin = 0.1;

# Preloaded methods go here.

=head1 THE KEYWORDS OBJECT

To simplify the handling of input data, this module provides an
object.  It is used like this:

   my $keywords = Xray::Atoms -> new();
   $keywords -> make('rmax' => 5.7)

The make method is the general way of storing data in the keywords
object.  In general, this method assumes that the keyword takes a
scalar value.  The data structure is just a hash, so the keyword can
be anything.  Indeed, keyword recognition is not done in this module.
Keyword/value pairs are just blindly stored for later processing.
Several keywords are treated specially because they are commonly used
in the programs included in the Atoms package.  These keywords

    a b c alpha beta gamma argon krypton nitrogen rmax

are treated as numbers.  This means that they are eval-ed (and so can
be short expressions like 1/2 or 3.5+0.001) and return 0 if they
cannot be interpreted as numbers.  This evaluation is done in a
taint-safe manner.

A couple of keywords are treated specially.

  $keywords -> make(title=>'This is a title!');

pushes the given string onto an anonymous array of strings.  In this
way, any number of title lines can be kept in the object.

The C<shift> keyword is also handled specially.  This takes three
arguments, the three components of the shift vector.  A syntax like
this works fine:

  $keywords -> make('shift' => $x, $y, $z);

This stores the three values of the shift vector as an anonymous
array.


=cut


sub new {
  my $classname = shift;
  my $self = {};
				# fuctional keywords
  $self->{'title'}    = [];
  $self->{'edge'}     = "";
  $self->{'core'}     = "";
  $self->{'argon'}    = 0;
  $self->{'krypton'}  = 0;
  $self->{'nitrogen'} = 0;
  $self->{'rmax'}     = 0;
  $self->{'shift'}    = [0,0,0];
				# lattice parameters
  $self->{'space'}    = '';
  $self->{'a'}        = 0;
  $self->{'b'}        = 0;
  $self->{'c'}        = 0;
  $self->{'alpha'}    = 0;
  $self->{'beta'}     = 0;
  $self->{'gamma'}    = 0;
				# sites
  $self->{'sites'}    = [];
				# operational keywords
  $self->{'overfull_margin'} = 0.1;
  $self->{'found_output'} = 0;
  $self->{'quiet'} = 0;
  $self->{'program'} = 'atoms';
				# atp flags
  my @atpfiles = ();
  my @atp_dir_list = ();
  push @atp_dir_list, $Xray::Atoms::atp_dir;
  push @atp_dir_list, File::Spec->catfile(&rcdirectory, "atp");
  foreach my $dir (@atp_dir_list) {
    if (-d $dir) {
      opendir (ATPDIR, $dir) ||
	die $$messages{'no_directory'} . " " . $dir . $/;
      push @atpfiles, grep /\.atp/, readdir ATPDIR;
      closedir ATPDIR;
    };
  };  ## feff feff8 p1 unit alchemy xyz geom symmetry test
  $self->{'files'}     = {};
				# feff potentials
  $self->{'ipots'}         = 'species'; # 'sites'
  $self->{'ipot_vals'}     = {};
  $self->{'always_feff'}   = $meta{always_write_feff};
  $self->{'prefer_feff_8'} = $meta{prefer_feff_eight};
  $self->{'language'}      = $meta{atoms_language};
  $self->{'write_to_pwd'}  = $meta{write_to_pwd};

  bless($self, $classname);
  return $self;
};
# dafs
##"fdat"        => 0,           "refile"      => "reflect.dat",
##"qvec"        => (0,0,0),     "nepoints"    => 100,
##"feout"       => "fe.dat",    "egrid"       => 1,
##"reflections" => (0,0,0),     "noanomalous" => 0 );
## corrections, index


sub make {
  my $self = shift;
  unless (($#_ % 2) || (grep /\b(files|sites)\b/, @_)) {
    my $this = (caller(0))[3];
    croak "$this " . $$messages{make_error};
    return;
  };

  my $die = $self->{die} || 1;
  while (@_) {
    my $att   = lc(shift);
    my $value = shift;
  KEYWORDS: {
      ($att eq 'title') && do {
	foreach my $l (split(/\n/, $value)) {
	  push @{$self->{'title'}}, $l unless ($l =~ /^\s*$/);
	};
	last KEYWORDS;
      };
      ($att =~ /(shift|qvec)/) && do {
	my $v1 = number($value, $die, $self);
	my $v2 = number(shift,  $die, $self);
	my $v3 = number(shift,  $die, $self);
	$self->{$1} = [$v1, $v2, $v3];
	last KEYWORDS;
      };
      ($att =~ /^(argon|krypton|nitrogen|rmax)$/) && do {
	$self->{$1} = number($value, $die, $self);
	last KEYWORDS;
      };
      ($att =~ /^(a|b|c|alpha|beta|gamma)$/) && do {
	$self->{$1} = number($value, $die, $self);
	last KEYWORDS;
      };
      ($att eq 'atp') && do {
	$value = $value;
	$self->{atp}{$value} = 1;
	last KEYWORDS;
      };
      ($att eq 'files') && do {
	$value = lc($value);
	my $v2 = shift;
	($v2 =~ /^\s*$/) and $v2 = undef;
	$self->{files}{$value} = $v2;
	last KEYWORDS;
      };
      ($att eq 'sites') && do {
	my $e = $value;
	my $x = number(shift, $die, $self);
	my $y = number(shift, $die, $self);
	my $z = number(shift, $die, $self);
	my $t = shift;
	my $o = number(shift, $die, $self);
	push @{$self->{'sites'}}, [$e, $x, $y, $z, $t, $o];
	last KEYWORDS;
      };
      do {
	$self->{$att} = $value;
	last KEYWORDS;
      };

    };

  };

  return $self;
};


=head1 METHODS

=head2 C<parse_input>

This method is used by atoms to read an atoms input file.  It is
typically called by

  $keywords -> parse_input($file, 0);

The first argument is the name of the input file.  The input file is
presumed to be of the atoms.inp sort unless the file extension is
C<.cif>, in which case it is presumed to be a CIF file.  This check is
made case-insensitively.

The second argument is tells the error trapping mechnism what kind of
environment you are working in.  If you have written a command-line
program, it should be 0.  In a Tk program, it should 1.  In a CGI
script it should be 2.

The contents of the file are parsed and stored in a keywords object.
The method is fairly clever about interpreting the file and offering
warning and error messages.  It interprets numbers in a fairly secure
manner, thus allowing simple math expressions to be used in the atom
list and as the shift vectors.

Alternately, you can pass a CIF file with the syntax

  $keywords -> parse_input($file, 0, 'cif');

or

  $keywords -> parse_input($file, 0, 'cif', 2);

The third argument is "cif" or "inp" to specify the input file type.
The fourth argument tells the CIF parser which structure to use from a
multi-structure file.

=cut

$$::messages{adb_unknown} = "You requested an unknown ADB file";
sub parse_input {

  my $href = abbrev qw(a alpha argon atoms b basis beta c core corrections
		       edge egrid emax emin egrid estep dopants fdat feff
		       feff8 gamma geom index ipots krypton
		       nepoints nitrogen noanomalous out output p1
		       qvec refile reflection reflections rmax shift
		       space title unit xanes);

  my $keys = shift;
  my ($file, $die, $type, $entry) = @_;
  $type ||= 'inp';
  $type = ($type =~ /cif/i) ? "cif" : "inp";
  $entry ||= 0;
  my ($nsites, $ntitles, $iline) = (0,0,0);

  ## is this a CIF file?
  my ($nn,$pp,$suff) = fileparse($file,
				 ".inp", ".INP", ".Inp",
				 ".cif", ".CIF", ".Cif");
  cif($keys, $file ,$entry), return
    if ($STAR_Parser_exists and ((lc($type) eq 'cif') or ($suff =~ /cif$/i)));


				## divy up the keywords into birds of
				## a feather
  my @normal = ("argon", "center", "core", "ipots", "krypton",
		"nitrogen", "rmax");
  ##my @logicals = ();
  my @threevecs	   = ("shift", "dafs", "qvec", "reflection");
  my @cellwords	   = ("a", "alpha", "b", "beta", "c", "gamma");
  my @output_types = ("feff", "feff8", "p1", "geom", "unit", "out");
  my @dafs	   = ("emin", "emax", "estep", "egrid");
  my @deprecated   = ("fdat", "nepoints", "xanes", "modules",
		      "message", "noanomalous", "self", "i0", "mcmaster",
		      "dwarf", "reflections", "refile",
		      "egrid", "index", "corrections");
  my ($term, $prompt, $stdin);
  my $fh;
  if ($file =~ /^http:/) {
    if (eval "require LWP::Simple") {
      unless (LWP::Simple::head($file)) { # handle unknown ADB file
	$keys -> warn_or_die("$$::messages{adb_unknown}:\n\t$file.\n", $die);
	return;
      };
      open ($fh, "GET $file |")
	or die "A pipe using LWP::Simple could not be opened to fetch ADB file.\n";
    } else {
      die "You must install LWP::Simple to fetch ADB files.\n";
    };
  } elsif ($file ne '____stdin') {
    open ($fh, $file) || die "could not open " . $file . " for reading" . $/;
  };
  ## what about STDIN???

 READ: while (<$fh>) {

    my @line = ();
    ++$iline;
    next if /^\s*$/;		 # skip blanks
    next if /^\s*[!\#%*]/;	 # skip comment lines
    chomp;
    (m/<HTML>/) and do {	# handle an unknown ADB file name

    };
    (my $line = $_) =~ s/^\s+//; # trim leading blanks
    $line =~ s/\r//g;	 	 # strip spurious control-M characters
    @line = split(/\s*[ \t=,]\s*/, $line);

  KEYWORDS: while (@line) {
      my $word = lc(shift @line);
      next READ if ($word =~ /^[!\#%*]/);	   # skip comment lines
      my $wasword = $word;
      $word = $href -> {$word};
      $word ||= $wasword;
      ##       unless ($word) {
      ## 	my $message = "\"$wasword\": " . $$messages{'unknown_keyword'} .
      ## 	  ", " . $$messages{'line'} . " $..$/";
      ## 	$keys -> warn_or_die($message, $die);
      ## 	next READ;
      ##       };
      ($word eq "end")  && last READ;

				## title/comment

      ($word =~ /^(com|tit)/) && do {
	## trim `title' or `comment' and leading spaces
	$line =~ s/^\s+//;
	my $string = substr($line, length($word));
	$string =~ s/^\s+//; $string =~ s/^=//; $string =~ s/^\s+//;
	unless ($keys -> {"quiet"}) {
	  print STDOUT "   ", $$messages{'title'}, " > ",
	  substr($string, 0, 59), "$/";
	};
	$keys -> make('title'=>$string);
	foreach my $a (@line) {
	  shift @line;
	};
	next READ;
      };
				## edge/hole can be error-checked en
				## passant
      ($word =~ /^(edg|hol)/) && do {
	my $value = shift @line;
	$keys -> make('edge'=>$value);
	next KEYWORDS;
      };
				## keywords which take the next word
				## literally
				## argon center core krypton nitrogen rmax
      (grep(/\b$word\b/, @normal)) && do {
	($word eq "center") && ($word = "core");
	my $value = shift @line;
	$keys -> make($word=>$value);
	next KEYWORDS;
      };
				## DAFS keywords which take the next
				## word literally: emin estep emax
      (grep(/\b$word\b/, @dafs)) && do {
	($word eq "egrid") && ($word = "estep");
	my $value = shift @line;
	$keys -> make($word=>$value);
	next KEYWORDS;
      };
				## three vectors, take the next three
				## words literally
      (grep(/\b$word\b/, @threevecs)) && do {
	my @value;
	$value[0] = shift @line;
	$value[1] = shift @line;
	$value[2] = shift @line;
	($word eq "dafs") && ($word = "qvec");
	($word eq "reflection") && ($word = "qvec");

	## ----- evaluate the coordinates safely
	## see `perldoc Safe' for details
	## my $message = $$messages{'tainted_vector'} . $/;
	## $message .= $$messages{'file'} . ": $file, ";
	## $message .= $$messages{'line'} . ": $.$/";
	## my $cpt = new Safe;
	## ##$cpt->share('@value');
	## $ {$cpt->varglob('x')} = $cpt->reval($value[0]);
	## $ {$cpt->varglob('y')} = $cpt->reval($value[1]);
	## $ {$cpt->varglob('z')} = $cpt->reval($value[2]);
	## @value = ($ {$cpt->varglob('x')}, $ {$cpt->varglob('y')},
	## 	  $ {$cpt->varglob('z')} );
	## test_safe_return($message, @value);

	## this is a much weaker form of security, but it works with
	## PerlApp
	@value = map {number($_,$die,$keys)} @value;
	## ----- end of safe evaluation

	$keys -> make($word=>$value[0],$value[1],$value[2]);
	next KEYWORDS;
      };
				## logical flags and diagnostics take
				## boolean values, on if next word is
				## yes, true, or on
      ##(grep(/\b$word\b/, @logicals)) && do {
      ##  my $value = shift @line;
      ##  $keywords{$word} = ($value =~ /^(t|y|on)/) ? 1 : 0;
      ##  next KEYWORDS;
      ##};
				## output styles take filenames
      ($word =~ /^outp/) && do {
	my $type = shift @line;
	my $value = shift @line;
	#push @$outputs, $type;
	if ($keys->{'program'} eq 'dafs') {
	  undef $keys->{atp}; undef $keys->{files};
	};
	$keys -> make('atp'   => $type);
	$keys -> make('files' => $type, $value);
	$keys -> make("found_output" => 1);
	next KEYWORDS;
      };
				## backwards compatability
      (grep(/\b$word\b/, @output_types)) && do {
	my $value = shift @line;
	if ($word eq "out") {
	  $keys -> make('atp'=>'feff', 'feff'=>$value);
	  #push @$outputs, "feff";
	} else {
	  my $set = ($value =~ /^(t|y|on)/);
	  if ($set) {
	    $keys -> make('atp'=>$word);
	    ## ($word eq "feff")  && ($keys -> make('feff' => "feff.inp"));
	    ## ($word eq "feff8") && ($keys -> make('feff8'=> "feff.inp"));
	    ## ($word eq "geom")  && ($keys -> make('geom' => "geom.dat"));
	    ## ($word eq "p1")    && ($keys -> make('p1'   => "p1.inp"  ));
	    ## ($word eq "unit")  && ($keys -> make('unit' => "unit.dat"));
	    #push @$outputs, $word;
	  };
	};
	next KEYWORDS;
      };
				## deprecated keywords
      (grep(/\b$word\b/, @deprecated)) && do {
	shift @line;
	my $mess = "\"$word\": " . $$messages{'deprecated'} . ", " .
	  $$messages{'line'} . " $..$/";
	warn $mess;
	($word =~ /dafs|reflections|qvec/) && do {
	  shift @line; shift @line;
	};
	next KEYWORDS;
      };
				## space group symbol
      ($word =~ /^spa/) && do {
	my $lline = lc($line);
	my $space = substr($line, index($lline,"space")+6);
	$space =~ s/^[\s=,]+//;
	$space =  substr($space, 0, 10); # next 10 characters
	$space =~ s/[!\#%*].*$//;  # trim off comments
	$keys -> make('space'=>$space);
	foreach my $x (split " ", $space) {
	  shift @line;
	};
	next KEYWORDS;
      };
				## a,b,c,alpha,beta,gamma
      (grep(/\b$word\b/, @cellwords)) && do {
	my $value = shift @line;
	$value = sprintf "%11.7f", $value;
	my $attribute = lc $word;
	$keys -> make($attribute=>$value);
	## the angle attribute carries the most recently set angle
	## this is needed to correctly interpret monoclinic cells
	## with all angles equal to 90 (pathology!!)
	##($attribute =~ /(alpha|beta|gamma)/i) &&
	##  ($cell -> make( "Angle"=>$1 ) );
	next KEYWORDS;
      };
				## site methods
      ($word =~ /^dop/) && do {
	my $mess = $$messages{'dopants'} . ", " . $$messages{'line'} . " $..$/";
	$keys -> warn_or_die($mess, $die);
	shift @line; shift @line; shift @line;
	next KEYWORDS;
      };
      ($word =~ /^bas/) && do {
	croak $$messages{'basis'}, $/;
	next KEYWORDS;
      };
      ($word =~ /^ato/) && do {
	my $nip = 0;
      ATOMS: while (1) {
	  $_ = <$fh>;
	  (! $_) && last KEYWORDS;
	  ++$iline;
	  last KEYWORDS if /---/;
	  next ATOMS if /^\s*$/;          # skip blanks
	  next ATOMS if /^\s*[!\#%*]/;    # skip comment lines
	  chomp;
	  my @line = split;
	  my $save = $line[0];
	  $line[0] = get_symbol($line[0]);
	  unless ($line[0]) {
	    if ($die == 0) {
	      my $mess = join(" ", $save, $$messages{not_an_element},
			      $$messages{at_line}, $iline, $/);
	      die $mess;
	    } else {
	      $line[0] = "??";
	      ##my $mess = join(" ", $save, "is not an element symbol", $/);
	      ##$keys -> warn_or_die($mess, $die);
	    };
	  };
	  ## ----- evaluate the coordinates safely
	  ## see `perldoc Safe' for details

	  ## this is a much weaker form of security, but it works with
	  ## PerlApp
	  my @xyz = map {number($_, $die, $keys)} ($line[1], $line[2], $line[3]);

	  ## my $message = $$messages{'tainted_atoms'} . $/;
	  ## $message .= $$messages{'file'} . ": $file, ";
	  ## $message .= $$messages{'line'} . ": $.$/";
	  ## my $cpt = new Safe;
	  ## ##$cpt->share('@xyz');
	  ## $ {$cpt->varglob('x')} = $cpt->reval($xyz[0]);
	  ## $ {$cpt->varglob('y')} = $cpt->reval($xyz[1]);
	  ## $ {$cpt->varglob('z')} = $cpt->reval($xyz[2]);
	  ## @xyz = ($ {$cpt->varglob('x')}, $ {$cpt->varglob('y')},
	  ##	  $ {$cpt->varglob('z')} );
	  ## test_safe_return($message, @xyz);
	  # @xyz = map {sprintf "%11.7f", $_} @xyz;
	  ## ----- end of safe evaluation

	  if (defined $line[4]) {
	    ## if the fourth column matches a C float, assume it is an
	    ## occupancy and that the tag should be ""
	    if ($line[4] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	      $line[5] = $line[4];
	      $line[4] = "";
	    };
	  } else {
	    ($line[4] = "");
	  };
	  ## test fifth column to see if it is an occupancy
	  (defined $line[5]) || ($line[5] = 1);
	  if ($line[5] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
	    $line[5] = number($line[5], $die, $keys);
	    ($line[5] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
	      || ($line[5] = 1);
	  } else {
	    $line[5] = 1;
	  };
	  $keys -> make('sites'=>
			$line[0], $xyz[0], $xyz[1], $xyz[2], $line[4], $line[5]);
	  ++$nsites;
	  my $this = lc($line[0]);
	};
      };
				## unknown keyword, store it anyway
      ($word) && do {
	my $value = shift @line;
	$keys -> make($word=>$value);
	## 	my $message = "\"$word\": " . $$messages{'unknown_keyword'} .
	## 	  ", " . $$messages{'line'} . "$..$/";
	## 	warn $message;
	## 	shift @line;
	next KEYWORDS;
      };
    };
  };
  close $fh;
};


=head2 C<cif>

This method reads from a CIF file and loads the data into keywords
object.

=cut


## this is ungainly due to the mismatch in nomenclature and verbosity
## of my stuff and the STAR stuff.
sub cif {
  my ($keys, $file, $which) = @_;
  my @datablocks = STAR::Parser->parse($file);
  my $datablock = $datablocks[$which];
  ##    if STAR::Checker->check(-datablock=>$datablocks[0]);

  my @item;

  ## titles: consider various common title-like entries, strip white
  ## space characters and stuff them into the title attribute
  @item = $datablock->get_item_data(-item=>"_chemical_name_mineral");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);
  @item = $datablock->get_item_data(-item=>"_chemical_name_systematic");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);
  @item = $datablock->get_item_data(-item=>"_chemical_formula_structural");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);
  @item = $datablock->get_item_data(-item=>"_chemical_formula_sum");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);
  @item = $datablock->get_item_data(-item=>"_publ_author_name");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);
  @item = $datablock->get_item_data(-item=>"_citation_journal_abbrev");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);
  @item = $datablock->get_item_data(-item=>"_publ_section_title");
  $item[0] ||= ""; $item[0] =~ s///g; chomp $item[0];
  $keys->make(title=>$item[0]) unless ($item[0] =~ /^\s*$/);

  ## space group: try the number then the NM symbol and canonicalize it
  @item = $datablock->get_item_data(-item=>"_symmetry_Int_Tables_number");
  my @sg = Xray::Xtal::Cell::canonicalize_symbol($item[0]);
  unless ($sg[0]) {
    @item = $datablock->get_item_data(-item=>"_symmetry_space_group_name_H-M");
    @sg = Xray::Xtal::Cell::canonicalize_symbol($item[0]);
  };
  $keys->make(space=>$sg[0]) if $sg[0];

  ## lattic parameters
  my $min = 100000;   # use lattice constants to compute default for Rmax
  foreach my $k (qw(a b c)) {
    @item = $datablock->get_item_data(-item=>"_cell_length_$k");
    (my $this = $item[0]) =~ s/\(\d+\)//;
    #print "$k $this\n";
    $keys->make($k=>$this);
    $min = 1.1*$this if ($min > 1.1*$this);
  };
  $min = 7 if ($min > 11);
  $keys->make(rmax=>$min);
  foreach my $k (qw(alpha beta gamma)) {
    @item = $datablock->get_item_data(-item=>"_cell_angle_$k");
    (my $this = $item[0]) =~ s/\(\d+\)//;
    #print "$k $this\n";
    $keys->make($k=>$this);
  };

  ## load up and clean up the atom positions
  my @tag = $datablock->get_item_data(-item=>"_atom_site_label");
  my @el  = $datablock->get_item_data(-item=>"_atom_site_type_symbol");
  my @x	  = $datablock->get_item_data(-item=>"_atom_site_fract_x");
  my @y	  = $datablock->get_item_data(-item=>"_atom_site_fract_y");
  my @z	  = $datablock->get_item_data(-item=>"_atom_site_fract_z");
  my @occ = $datablock->get_item_data(-item=>"_atom_site_occupancy");
  foreach my $i (0 .. $#tag) {
    my $ee = $el[$i] || $tag[$i];
    $ee = get_elem($ee);
    (my $xx = $x[$i]) =~ s/\(\d+\)//; # remove parenthesized error bars
    (my $yy = $y[$i]) =~ s/\(\d+\)//;
    (my $zz = $z[$i]) =~ s/\(\d+\)//;
    (my $oo = $occ[$i]||1) =~ s/\(\d+\)//;
    ##print "$ee, $xx, $yy, $zz, $tag[$i], $oo\n";
    $keys -> make('sites'=> $ee, $xx, $yy, $zz, $tag[$i], $oo);
  };
};

## Tags in the cif file seem to mostly be the two letter element
## symbol concatinated with a number (possibly concatinated with a
## non-alphanumeric, such as a plus sign or parens).  Also "Wat" and "OH"
## indicate oxygen sites (with one or two associated hydrogens) and D
## means deuterium.
sub get_elem {
  my $elem = $_[0];
  ($elem =~ /Wat/) and return "O";
  ($elem =~ /OH/)  and return "O";
  ($elem =~ /^D$/) and return "H";
  ## snip off the last character until an element symbol is found
  while ($elem) {
    return $elem if ($elem =~ /^$elem_match$/o);
    chop $elem;
  };
  return "??";
};


sub test_safe_return {
  my $message = shift(@_);
  my @list = @_;
  foreach my $item (@list) {
    (defined $item) || die $message . $/;
  };
  return 1;
};

=head2  C<verify_keywords>

This method is used to perform some sanity checks on the keyword
values after reading in the input data and populating the sites and the
cell.  It is a good idea to call this before building a cluster or
starting some other calculation.

  $keywords -> verify_keywords($cell, \@sites, 0, 0);

The first two arguments are a Cell object and a reference to a
list of Site objects.  The third argument is the same as the second
argument to the C<parse_input> method.  The last argument should be
non-zero only for a calculation that does not need to know which is
the central atom (e.g. a powder diffraction simulation).

=cut

sub verify_keywords {
  my $keys = shift;
  my ($cell,$r_sites,$die,$no_core) = @_;
  my $def = 7;
  $keys ->{dopant_core} = "";
  $keys -> set_rmax($cell, $def, $die);
  unless ($no_core) {
    my $checkit = $keys -> set_core($r_sites, $die);
    return 1 if ($checkit eq '-1');
    #$keys -> check_core($r_sites, $die);
    $keys -> set_edge($cell,$die);
  };
  foreach my $word (qw/argon krypton nitrogen/) {
    if (($keys->{$word} < 0) || ($keys->{$word} > 1)) {
      $keys->make($word=>'0');
      my $message = "\"$word\": $$messages{'one_gas'}$/";
      $keys -> warn_or_die($message, $die);
    };
  };
  if (($keys->{nitrogen} + $keys->{argon} + $keys->{krypton}) > 1) {
    my $message = $$messages{'all_gases'} . $/;
    $keys->make('nitrogen'=> '0');
    $keys->make('argon'=>    '0');
    $keys->make('krypton'=>  '0');
    $keys -> warn_or_die($message, $die);
    return 1;
  };
  if ($keys->{dopant_core}) {
    my $z = &get_Z($keys->{dopant_core});
    unless ($z) {
      my $message = $$::messages{dopant_core} . $/;
      $keys -> warn_or_die($message, $die);
      return 1;
    };
  };
};
# perhaps take as arguments refs to subroutines for further tests

## the next several subroutines are used internally, thus not pod
## docmented.

## reference to a cell and default rmax value (defaults to 7)
sub set_rmax {
  my $keys = shift;
  my ($cell, $def, $die) = @_;
  my $message = $$messages{'rmax'} . $/;
  $def ||= 7;
  my $rm = number($keys->{'rmax'}, $die, $keys);
  if (($rm != 0) && ($rm < EPSILON)) {
    $rm = 0;
    $keys -> warn_or_die($message, $die);
  };
  ($rm > EPSILON) || do {
    ## rmax is the larger of (7 and 1.1 times the shortest axis)
    my @list = sort ($cell->attributes('A','B','C'));
    @list = sort ($list[0], $def/1.1);
    $keys->{"rmax"} = 1.1*$list[1];
  };
  return $keys->{"rmax"};
};

## reference to an array of sites
sub set_core {
  my $keys = shift;
  my $sites = $_[0];
  my $die = $_[1];
  #unless ($keys->{"core"}) {
  if ($#{$sites} == 0) {
    my ($t) = $$sites[0] -> attributes('Tag');
    $keys->make("core", $t);
    return $keys->{"core"};
  } elsif (($#{$sites} != 0) and ($keys->{"core"} =~ /^\s*$/)) {
    $keys -> warn_or_die($$messages{'no_core'} . $/, $die);
    my ($t) = $$sites[0] -> attributes('Tag');
    $keys->make("core", $t);
    return $keys->{"core"};
  } elsif ($keys -> check_core($sites, $die)) {
    return $keys->{"core"};
  } else {
    $keys -> warn_or_die($$messages{'no_core'} . $/, $die);
  };
  #return $keys->{"core"};
  #};
};

sub check_core {
  my $keys = shift;
  my ($sites, $die) = @_;
  my $c = lc($keys->{'core'});
  my $found = 0;
  foreach my $site (@$sites) {
    my ($t) = $site -> attributes('Tag');
    $t = lc($t);
    $found = 1, last if ($t eq $c);
  };
  $| = 1;
  ($found) ||
    $keys -> warn_or_die("\"" . $keys->{'core'} . "\" " .
			 $$messages{'unknown_core'} . $/,
			 $die);
  (not $found) and ($die == 0) and die "\n";
  #$::help{'check_core'};
  return $found;
};

sub set_edge {
  my $keys = shift;
  my ($cell,$die) = @_;
  if ($cell->{Contents}) {
    unless ($keys->{'edge'}) { # default based on Z number
      my ($central, $xcenter, $ycenter, $zcenter) =
	$cell -> central($keys->{"core"});
      my $z = &get_Z($central);
      $keys->{'edge'} = 'K';
      if ($z > 57) {
	$keys->{'edge'} = 'L3';
      };

    };
    ($keys->{"edge"} =~ /k|l[123]|m[1-5]|n[1-7]|o[1-7]|p[1-3]/i) || do {
      my $message = $$messages{'bad_edge'} . $/;
      ($keys->{"edge"} = 'k');
      $keys -> warn_or_die($message, $die);
      return 0;
    };
  };
  return $keys->{'edge'};
};


sub atp_selected {
  my $keys = shift;
  my $atp = $_[0];
  return $keys->{'atp'}{$atp};
};
sub toggle_atp {
  my $keys = shift;
  my $atp = $_[0];
  if ($keys->{'atp'}{$atp}) {
    $keys->{'atp'}{$atp} = 0;
  } else {
    $keys->{'atp'}{$atp} = 1;
  };
};

=head2 C<warn_or_die>

This is a subroutine rather than a method, so that is can be used even
without an active keywords object.  It is a wrapper for generating
error and warning methods that will work in command-line, GUI, and CGI
environments.

   $keywords -> warn_or_die("This is a warning message", $die);

The first argument is the actual message.  The C<die> argument is 0,
1, or 2 as described for C<parse_input>.  The final argument is a
keywords object and is only used in the CGI environment.  In that
case, here are no convenient output or error channels, so messages are
stored in the keywords hash as a single string under the key
"www_warn".

=cut

sub warn_or_die {
  my $keys = shift;
  my ($message, $die) = @_;
  if ($die == 1) {		# Tk
    ##my $temp = MainWindow->new;
    ##$temp -> withdraw;
    $::top -> messageBox(-icon    => 'error',
			 -message => $message,
			 -title   => 'Atoms: Error',
			 -type    => 'OK');
    ##undef $temp;
    return -1;
  } elsif ($die == 2) {		# CGI
    $keys -> {www_warn} .= $message;
  } elsif ($die == 0) {		# CLI
    warn $message;
    $keys -> {cli_warn} .= $message if $keys;
  } elsif ($die == 4) {		# ignore
    return -1;
  } else {
    die "Programmer error!  Invalid run level $die in warn_or_die!\n";
  };
};

## =head2 C<available_languages>
##
## This subroutine takes no arguments and returns a list of the languages
## for which translations of the language data exist.
##
## =cut

sub available_languages {
  return @available_languages;
};


=head2 C<parse_atp>

This subroutine is the output engine.  It parses the appropriate atp
file, interprets its content, and generates output data.  This one
subroutine handles the creation of F<feff.inp> and the other sorts of
lists generated by Atoms.  It also generates reports for the
Absorption notecard in TkAtoms and for the lists describing the DAFS
calculation as a function of energy and the powder calculation as a
function of angle.  Essentially all output from all programs that come
with the Atoms package is generated here.

  my ($default_name, $is_feff) =
    &parse_atp($atp, $cell, $keywords, \@cluster, \@neutral, \$contents);
  open (INP, ">".$default_name) or die $!;
  print INP $contents;
  close INP;

The arguments are

=over 4

=item 1.

A string specifying the atp file to read.  The actual atp file either
lives in the F<atp/> subdirectory of the Atoms installation or in the
F<.atoms/> directory of the individual user.

=item 2.

A Cell object.

=item 3.

A keywords object.

=item 4.

A reference to the list generated by the C<build_cluster> subroutine,
to the list containing a calculation such as the one in DAFS or
Powder, or 'whatever the thing is that I did to make atoms.inp output
work.'

=item 5.

A reference to a list.  This is just a place holder and is not
currently used for anything.

=item 6.

A scalar reference.  This is assumed to be empty on entry, and is
filled with contents intended for the output file on exit.

=back

Typically the C<contents> variables is the things written to the
output channel.  The two return values are the default name for the
output file and a flag indicating whether the output is intended to
run FEFF.  Both of these pieces of information are read from the
C<meta> line of the atp file.



=head1 EXPORTED SUBROUTINES

=head2 C<absorption>

This subroutine calculates the total absorption (or one over the
e-fold absorption length), the delta_mu across the edge (or one over
the unit edge step length) and the specific gravity of the crystal.

  ($total_absorption, $delta_mu, $specific_gravity) =
       &absorption(\$cell, $central, $edge);

The input arguments are a populated cell, the tag of the central atom,
and the alphanumeric (i.e. K, L1, etc) symbol of the absorption edge.

Note that the values returned depend on the data resource used.  See
L<Xray::Absorption>.


=cut


## this reproduces well the results from the Fortran atoms.
sub absorption {
  my ($cell, $central, $edge) = @_;
  $central = lc($central);
  my $specified = ($edge =~ /\b\d+\b/);
  my $energy     = ($edge =~ /\b\d+\b/) ?
    $edge : Xray::Absorption -> get_energy($central, $edge);
  my ($contents) = $cell -> attributes("Contents");
  my ($bravais)  = $cell -> attributes("Bravais");
  my $brav       = ($#{$bravais}+4) / 3;
  my ($volume, $occ)   = $cell -> attributes("Volume", "Occupancy");
  my ($mass, $xsec, $delta_mu, $den, $conv) = (0,0,0,0,0);
  my %cache = ();   # memoize and call cross_section less often
  foreach my $atom (@{$contents}) {
    my ($element, $this_occ) =
      $ {$$atom[3]} -> attributes("Element", "Occupancy");
    # print join(" ", $element, $this_occ, $/);
    $element = lc($element);
    my $factor = $this_occ;  # $occ ? $this_occ : 1; # consider site occupancy??
    my $weight = Xray::Absorption -> get_atomic_weight($element);
    $mass += $weight*$factor;
    $cache{lc($element)} ||=
      scalar Xray::Absorption -> cross_section($element, $energy+50);
    $xsec += $cache{lc($element)} * $factor;
    if (($central eq $element) and not $specified) {
      $delta_mu +=
	($factor/$brav) *
	  ( $cache{lc($central)} -
	    scalar Xray::Absorption -> cross_section($central, $energy-50) );
    };
  };
  $mass     *= 1.66053/$volume;	## atomic mass unit = 1.66053e-24 gram
  $xsec     /= $volume;
  $delta_mu /= $volume;
  return ($xsec, $delta_mu, $mass);
};


=head2 C<xsec>

This subroutine calculates the total absorption (or one over the
e-fold absorption length) and the specific gravity of the crystal at a
specified energy (rather than around the edge energy of an element).

In scalar context:

  ($total_absorption, $specific_gravity) =
      &xsec($cell, $central, $energy);

In list context:

  (\@total_absorption, $specific_gravity) =
      &xsec($cell, $central, \@energies);

The input arguments are a populated cell and the tag of the central
atom.  The third argument is either the desired energy in eV or a
reference to a list of energies in eV.

Note that the values returned depend on the data resource used.  See
L<Xray::Absorption>.


=cut

sub xsec {
  my ($cell, $central, $energy) = @_;
  $central = lc($central);
  my ($contents) = $cell -> attributes("Contents");
  my ($bravais)  = $cell -> attributes("Bravais");
  my $brav       = ($#{$bravais}+4) / 3;
  my ($volume, $occ)   = $cell -> attributes("Volume", "Occupancy");
  my ($xsec, $delta_mu, $den, $conv) = (0,0,0,0);
  my @xsec = ();
  my %cache = ();   # memoize and call cross_section less often
  foreach my $atom (@{$contents}) {
    my ($element, $this_occ) =
      $ {$$atom[3]} -> attributes("Element", "Occupancy");
    $element = lc($element);
    my $factor = $this_occ;  # $occ ? $this_occ : 1; # consider site occupancy??
    if (wantarray) {
      exists $cache{$element} or
	@{$cache{$element}} =
	  Xray::Absorption -> cross_section($element, $energy);
      foreach (0 .. $#{$energy}) {
	$xsec[$_] += $ {$cache{$element}}[$_] * $factor;
      };
    } else {
      $cache{$element} ||=
	scalar Xray::Absorption -> cross_section($element, $energy);
      $xsec += $cache{$element} * $factor;
    };
  };
  $xsec /= $volume;
  return wantarray ? @xsec : $xsec;
};

sub density {
  my $cell = $_[0];
  my ($contents, $bravais) = $cell -> attributes("Contents", "Bravais");
  my $brav       = ($#{$bravais}+4) / 3;
  my ($volume, $occ)   = $cell -> attributes("Volume", "Occupancy");
  my ($mass, $den, $conv) = (0,0,0);
  foreach my $atom (@{$contents}) {
    my ($element, $this_occ) =
      $ {$$atom[3]} -> attributes("Element", "Occupancy");
    $element = lc($element);
    my $factor = $this_occ;  # $occ ? $this_occ : 1; # consider site occupancy??
    my $weight = Xray::Absorption -> get_atomic_weight($element);
    $mass += $weight*$factor;
  };
  $mass *= 1.66053/$volume;	## atomic mass unit = 1.66053e-24 gram
  return $mass;
};


sub mcmaster_pre_edge {
  my ($central, $edge) = @_;
  $edge = lc($edge);
  my $emin = Xray::Absorption -> get_energy($central, $edge) - 10;
  ## find the pre-edge line
  my %next_e = ("k"=>"l1", "l1"=>"l2", "l2"=>"l3", "l3"=>"m");
  my $ebelow;
  if (exists $next_e{$edge}) {
    $ebelow = Xray::Absorption -> get_energy($central, $next_e{$edge}) + 10;
    $ebelow = (($emin - $ebelow) > 100) ? $emin - 100 : $ebelow;
  } else {
    $ebelow = $emin - 100;
  };
  my $delta  = ($emin - $ebelow)/10;;
  my @i=(0..9);			# load the pre edge energies/sigmas
  my @energy = map {$ebelow + $delta*$_} @i;
  my @sigma  = Xray::Absorption -> cross_section($central, \@energy);
				#  and fit 'em
  my $pre_edge = Statistics::Descriptive::Full->new();
  $pre_edge -> add_data(@sigma);
  my ($bpre, $slope) = $pre_edge -> least_squares_fit(@energy);
  $bpre ||= 0; $slope ||= 0;
  return ($bpre, $slope);
};

=head2 C<mcmaster>

This is called C<mcmaster> for historical reasons.  It calculates the
normalization correcion for a given central atom.

  $sigma_mm = &mcmaster($central, $edge);

It takes the central atoms tag and the alphanumeric edge symbol as
arguments and returns the normalization correction in units of
Angstrom squared.

Note that the values returned depend on the data resource used.  See
L<Xray::Absorption>.

=cut


## $span in the fortran version was 500eV and the regression was
## performed with a square term.
## Statistics::Descriptive::least_squares_fit only fits a line, so I
## drew the #span back to 300 volts.  This gives the "canonical"
## 0.00052 for copper.
sub mcmaster {
  my ($central, $edge) = @_;
  return Xray::FluorescenceEXAFS->mcmaster($central, $edge);
};


=head2 C<i_zero>

This calculates the correcion due to the I0 fill gases in a
fluorescence experiment.

  $sigma_i0 = &i_zero($central, $edge, $nitrogen, $argon, $krypton);

It takes the central atoms tag, the alphanumeric edge symbol, and the
volume percentages of the three gases as arguments.  It assumes that
any remaining volume is filled with helium and it correctly accounts
for the fact that nitrogen is a diatom.  It returns the I0 correction
in units of Angstrom squared.

Note that the values returned depend on the data resource used.  See
L<Xray::Absorption>.

=cut

sub i_zero {
  my ($central, $edge, $nitrogen, $argon, $krypton) = @_;
  my $gases = {nitrogen=>$nitrogen, argon=>$argon, krypton=>$krypton};
  return Xray::FluorescenceEXAFS->i0($central, $edge, $gases);
};

=head2 C<self>

This calculates the correcion due to self-absorption fluorescence
experiment.  It assumes that the sample is infinately thick and that
the entry and exit angles of the photons are the same.

  $sigma_i0 = &self($central, $edge, $cell);

It takes the central atoms tag, the alphanumeric edge symbol, and a
populated cell.  It returns a list whose zeroth element is the
multiplicative amplitude correction and whose first element is the a
correction in units of Angstrom squared.

Note that the values returned depend on the data resource used.  See
L<Xray::Absorption>.

=cut

sub self {
  my ($central, $edge, $cell) = @_;
  my @list = ();
  my ($contents) = $cell -> attributes("Contents");
  my ($occ) = $cell -> attributes("Occupancy");
  my %count = ();
  foreach my $atom (@{$contents}) {
    ## apparetnly this needs to be coerced into a string
    my $this = sprintf("%s", $ {$$atom[3]} -> attributes("Element") );
    ++$count{$this};
  };
  return Xray::FluorescenceEXAFS->self($central, $edge, \%count);
};


## =over 4
##
## =item &bravais_string
##
## Returns the peculiar array from &bravais as a pretty-printed string.
## This is not method of the Cell class, it is just a normal function.
## This demonstrates the differnt return values of bravais and
## bravais_string
##
##   @list = Xray::Xtal::Cell::bravais("F m 3 m", 0);
##   print Xray::Xtal::Cell::bravais_string(@list), "\n",
##         join(", ", @list), "\n":
##
##   |-> (0, 0, 0), (0, 1/2, 1/2), (1/2, 0, 1/2), (1/2, 1/2, 0)
##       (0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 0.5, 0.5, 0.5, 0)
##
## =back
##
## =cut

sub bravais_string {
  my ($bravais, $gnxas) = @_;
  return "" unless ($bravais);
  my @temp = @$bravais;
  length(join("", @temp)) || return ($gnxas) ? "1$/0,0,0"  : "(0, 0, 0)";
  @temp = map {
    if      (abs($_ - 0.5) < EPSILON) {
      ($_ = "1/2")
    } elsif (abs($_ - 2/3) < EPSILON) {
      ($_ = "2/3")
    } elsif (abs($_ - 1/3) < EPSILON) {
      ($_ = "1/3")
    } else {
      ($_ = "0")
    } }
    @temp;
  my $string = "";
  if ($gnxas) {
    ($#temp == 2) and $string = "2$/";
    ($#temp == 5) and $string = "3$/";
    ($#temp == 8) and $string = "4$/";
    $string .= "0.0000,0.0000,0.0000";
    while (@temp) {
      $string .= sprintf("$/%6.4f,%6.4f,%6.4f",
			 eval(shift @temp), eval(shift @temp), eval(shift @temp));
    };
  } else {
    $string = "(0, 0, 0), (";
    $string .= join(", ", $temp[0], $temp[1], $temp[2]);
    ($#{temp} > 2) &&
      ($string .= "), (" . join(", ", $temp[3], $temp[4], $temp[5]));
    ($#{temp} > 5) &&
      ($string .= "), (" . join(", ", $temp[6], $temp[7], $temp[8]));
    $string .= ")";
  };
  return $string;
};

=head2 C<build_cluster>

This exported routine builds a spherical cluster from a populated unit
cell by constructing a rhomboid of an intger number of complete cells
which fully encloses the sphere.  The spherical cluster is probably
not stoichiometric.

     build_cluster($cell, $keywords, \@cluster, \@neutral);

The first two arguments are cell and keywords objects.  The cell
should already have been populated by the C<populate> method. The
thrid argument is a reference to an array that will contain the
cluster.  The fourth argument is an unused placeholder.

The C<@cluster> array is an anonymous array or arrays.  Each entry in
C<@cluster> is an array containing x, y, z, r, r squared, x, y, z, the
formula for x, the formula for y , and the formula for z.  The first
three arguments are the coordinates to full precision.  The fourth
through seventh arguments are of limited precision and are used
internally for sorting the cluster.

=cut


# cell, rmax, position of central atom
# return cluster and neutral cluster
sub build_cluster {
  use POSIX qw(ceil);
  my ($cell, $keys, $r_cluster, $r_neutral) = @_;
  my $rmax = $keys->{'rmax'};
  @$r_cluster = ();
  @$r_neutral = ();
  my ($central, $xcenter, $ycenter, $zcenter) =
    $cell -> central($keys->{"core"});
  my $setting	    = $cell->{Setting};
  my $crystal_class = $cell -> crystal_class();
  my $do_tetr	    = ($crystal_class eq "tetragonal" )   && ($setting);
  ##print join(" ", $central, $xcenter, $ycenter, $zcenter), $/;
  my ($aa, $bb, $cc) = $cell -> attributes("A", "B", "C");
  my $xup = ceil($rmax/$aa - 1 + $xcenter);
  my $xdn = ceil($rmax/$aa - $xcenter);
  my $yup = ceil($rmax/$bb - 1 + $ycenter);
  my $ydn = ceil($rmax/$bb - $ycenter);
  my $zup = ceil($rmax/$cc - 1 + $zcenter);
  my $zdn = ceil($rmax/$cc - $zcenter);
  ##print join(" ", "up,dn", $xup, $xdn, $yup, $ydn, $zup, $zdn), $/;
  #my $num_z = int($rmax/$cc) + 1; # |
  my $rmax_squared = $rmax**2; # (sprintf "%9.5f", $rmax**2);
  my ($contents) = $cell -> attributes("Contents");
  foreach my $nz (-$zdn .. $zup) {
    foreach my $ny (-$ydn .. $yup) {
      foreach my $nx (-$xdn .. $xup) {
	foreach my $pos (@{$contents}) {
	  my ($x, $y, $z) = ($$pos[0]+$nx, $$pos[1]+$ny,  $$pos[2]+$nz);
	  ($x, $y, $z) = ($x-$xcenter, $y-$ycenter, $z-$zcenter);
	  ($x, $y, $z) =  $cell -> metric($x, $y, $z);
	  ($do_tetr) and ($x, $y) = (($x+$y)/sqrt(2), ($x-$y)/sqrt(2));
	  #printf "in:  %25s %25s %25s %3d %3d %3d\n", @$pos[4..6],$nx,$ny,$nz;
	  my ($fx, $fy, $fz) = &rectify_formula(@$pos[4..6], $nx, $ny, $nz);
	  #printf "out: %25s %25s %25s\n\n", $fx, $fy, $fz;
	  my $r_squared = (sprintf "%9.5f", $x**2 + $y**2 + $z**2);
	  my $this_site = [$x, $y, $z, $$pos[3],
			   $r_squared,             # cache the
			   (sprintf "%11.7f", $x), # stuff needed
			   (sprintf "%11.7f", $y), # for sorting
			   (sprintf "%11.7f", $z),
			   $fx, $fy, $fz ];
	  ($r_squared < $rmax_squared) && # keep the ones within rmax
	    (push @$r_cluster, $this_site);
	  ## (push @$r_neutral, $this_site);
	};
      };
    };
  };

  ## =============================== sort the cluster (& neutral clus.)
  foreach my $r_list ($r_cluster) { ##, $r_neutral) {
    @$r_list = sort {
      ($a->[4] cmp $b->[4])	# sort by distance squared or ...
	or
      ($ {$a->[3]}->{Element} cmp $ {$b->[3]}->{Element})
	or
      ($a->[7] cmp $b->[7])	# by z value or ...
	or
      ($a->[6] cmp $b->[6])	# by y value or ...
	or
      ($a->[5] cmp $b->[5]);	# by x value
      ##	or
      ## ($ {$b->[3]}->{Host} <=> $ {$a->[3]}->{Host});	# hosts before dopants
    } @$r_list;
  };

  ## final adjustment to the formulas, store the formulas for the
  ## central atom ...
  $keys -> {cformulas} =
    [$$r_cluster[0][8], $$r_cluster[0][9], $$r_cluster[0][10]];
  ##   ## ... subtract the central atom coordinates from each site ...
  ##   foreach my $site (reverse(@$r_cluster)) {
  ##     (@$site[8..10]) =
  ##       ($$site[8] . " - Xc", $$site[9] . " - Yc", $$site[10] . " - Zc");
  ##   };
  ##   ## ... and set the central atom to an empty string
  ##   ($$r_cluster[0][8], $$r_cluster[0][9], $$r_cluster[0][10]) = ("", "", "");

  ## if this is a tetragonal crystal in the C or F setting , rotate
  ## all the coordinates back to the original setting
  if ($do_tetr) {
    my ($a, $b) = ($cell->{A}, $cell->{B});
    $cell -> make(A=>$a*sqrt(2), B=>$b*sqrt(2));
  };
};


sub rectify_formula {
  my ($fx, $fy, $fz, $nnx, $nny, $nnz, $r_cformula) = @_;
  my $debug_formulas = 1;
  ##open DEBUG, '>debug.formulas' or die $!;
  #warn "input: ", join(" | ",$fx, $fy, $fz, $nnx, $nny, $nnz, $/);
  ## apply bravais translation
  map {
    if    ($_ < 0)  { $_ = ' + '.$_ }
    elsif ($_ == 0) { $_ = '' }
    else            { $_ = ' + '.$_ };
  } ($nnx, $nny, $nnz);
  ($fx, $fy, $fz) = ($fx . $nnx, $fy . $nny, $fz . $nnz);
  ## convert fractions to decimal
  map { s|(\d)/(\d)|$1/$2|ge } ($fx, $fy, $fz);
  # collapse the numeric fields
  map {
    my @list = reverse(split(/\s*\+\s*/, $_));
    #print join('|', @list, $/);
    my $sum = 0;
  LIST: while (@list) {
      my $this = shift @list;
      #print $this, " ";
      if ($this =~ /^-?[xyz]/) {	# whoops! put the variable back on
	unshift @list, $this;
	last LIST;
      };
      $sum = eval '$sum + $this';	# eval the constants
    };
    if ($sum) {				# prettify the number and unshift it
      $sum = sprintf("%10.6f", $sum);
      $sum =~ s/\.?0+$//;
      $sum =~ s/^\s+//;
      unshift @list, $sum;
    };
    @list = reverse(@list);
    $_ = join("+", @list);	        # make a math expression
    s/\+-/-/g;	 		        # finally clean up the + and - signs
    s/([+-])/ $1 /g;
    s|^ - |-|;
  } ($fx, $fy, $fz);
  # all done!
  #warn "output: ", join(" ", $fx, $fy, $fz, $/ x 2);
  return ($fx, $fy, $fz);
};

=head2 C<rcfile_name>

This takes no arguments and returns the name of the Atoms runtime
configuration file belonging to the user.  This does the ``right
thing'' on the different platforms.

=cut

sub rcfile_name {
  return "???" if (&rcdirectory() eq '???');
  return File::Spec -> catfile(&rcdirectory(), "tkatoms.ini")
    if (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
  return File::Spec -> catfile(&rcdirectory(), "atomsrc");
};
sub rcdirectory {
  if ($^O eq 'VMS') {
    return "???";
  } elsif ($^O eq 'os2') {
    return "???";
  } elsif ($^O eq 'MacOS') {
    return $lib_dir;
  } elsif (($^O eq 'MSWin32') or ($^O eq 'cygwin')) {
    return File::Spec->catfile($ENV{FEFFIT_DIR}, "horae") if defined($ENV{FEFFIT_DIR});
    return "???";
  } else {
    my $home;
    eval '$home = $ENV{"HOME"} || $ENV{"LOGDIR"} || (getpwuid($<))[7];' or
      $home = "";
    return $home . "/.horae/";
  };
};

sub read_rc {
  open RC, $_[0] or die "could not open $_[0] as a configuration file\n";
  my $mode = "";
  while (<RC>) {
    next if (/^\s*$/);
    next if (/^\s*\#/);
    if (/\[(\w+)\]/) {
      $mode = lc($1);
      next;
    };
    chomp;
    s/^\s+//;
    unless ($_ =~ /\$c_/) {s/\s*\#.*$//;};
    my @line = split(/\s*[ \t=]\s*/, $_);
    (defined $line[1]) and
      (($line[1] eq "''") or ($line[1] eq '""')) and $line[1] = '';
  MODE: {
      ($line[0] =~ /^\s*\$([a-zA-Z_]+)/) and do {
	my $var = $1;
	$line[1] =~ s/[;\'\"]//g;
	if ($var =~ /^c_/) {	# colors
	  ## 	  my $v = substr($var, 2);
	  ## 	  $colors{$v} = $line[1];
	  ## 	  if (($colors{$v} =~ /^[0-9a-fA-F]{6}$/) or
	  ## 	      ($colors{$v} =~ /^[0-9a-fA-F]{12}$/)) {
	  ## 	    $colors{$v} = '#'.$line[1];
	  ## 	  };
	} elsif ($var =~ /^f_/) { # fonts
	  ## 	  my $v = substr($var, 2);
	  ## 	  $fonts{$v} = join(" ", @line[1..$#line]);
	  ## 	  $fonts{$v} =~ s/[;\'\"]//g;
	} else {		# meta
	  $meta{$var} = $line[1];
	};
	last MODE;
      };
      ($mode eq 'meta') and do {
	$meta{$line[0]} = $line[1];
	last MODE;
      };
      ### don't need to parse colors and fonts here
      ## ($mode eq 'colors') and do {
      ##        $colors{$line[0]} = $line[1];
      ## 	(($colors{$line[0]} =~ /[0-9a-fA-F]{6}/) or
      ## 	 ($colors{$line[0]} =~ /[0-9a-fA-F]{12}/)) and
      ## 	   $colors{$line[0]} = '#'.$line[1];
      ## 	last MODE;
      ## };
      ## ($mode eq 'fonts') and do {
      ## 	$fonts{$line[0]} = join(" ", @line[1..$#line]);
      ## 	last MODE;
      ## };
    };
  };
};

=head2 C<rcvalues>

This takes no argmuents and returns the hash containing the values of
variables (but not of fonts or colors) read from the rc file.

=cut

sub rcvalues {
  shift;
  return %meta;
##   ##            0                  1                  2
##   return ($always_write_feff,   $atoms_language,    $write_to_pwd,
##   ##            3                  4                  5
## 	  $prefer_feff_eight,   $absorption_tables, $dafs_default,
##   ##            6                  7                  8
## 	  $plotting_hook,       $default_filepath,  $display_balloons,
##   ##            9                 10                 11
## 	  $no_crystal_warnings, $one_frame,         $convolve_dafs,
##   ##           12                 13
## 	  $never_ask_to_save,   $ADB_location)
};

=head2 C<number>

This takes a text string and attempts to evaluate it as a number.  It
uses eval and so allows for simple math expressions, but it tries to
be safe and not eval just any old math expression.  You can use this
if you want to evaluate numbers in the same manner as Atoms.

    $x = number(1/3);
    printf "%7.5f\n", $x;
      |--> 0.33333

=cut

## this returns a text string as a proper number
sub number {
  my $num = $_[0];
  (my $input = $num) =~ s/\s//g; # trim blanks
  my $die = $_[1] || 0;
  my $keys = $_[2] || Xray::Atoms->new();
  ##my $m = $num+0;
  my $num_match = '([+-]?(\d+\.?\d*|\.\d+))';
  ($num =~ /^\s*$/) && return 0;       # null value
  ##if ($num == $m) {
  if ($num =~ /^\s*$num_match\s*$/) {  # floating point number
    ($num = sprintf "%9.5f", $num) =~ s/^\s+//;
    return $num;
  };				# simple binary operation
  if ($num =~ /^\s*($num_match)\s*(\-|\+|\/|\*)\s*($num_match)\s*$/) {
    $num = eval $num;
    ($num = sprintf "%9.5f", $num) =~ s/^\s+//;
    return $num;
  };
  #(abs($num) < $Xray::Atoms::epsilon) && ($num = 0);
  ## interpret angle as 80.23'45"
  my $message = join("", "The string \"", $num, "\" was found among the atom coordinates.  Atoms doesn't know what to do with it.  The parameter was set to zero.  You might want to verify your input data.", $/);
  $keys -> warn_or_die($message, $die);
  print caller;
  return 0;
};

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__



=head1 MORE INFORMATION

There is more information available in the Atoms document.  There you
will find complete descriptions of atp files, calculations using the
Xray::Absorption package, keywords in atoms input files and lots of
other topics.


=head1 AUTHOR

  Bruce Ravel <ravel@phys.washington.edu>
  Atoms URL: http://feff.phys.washington.edu/~ravel/software/atoms/


=cut

## Local Variables:
## time-stamp-line-limit: 25
## End:
