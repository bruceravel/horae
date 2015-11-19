#!/usr/bin/perl
######################################################################
## APT: The ATOMS Periodic Table
##      calculate absorption lengths for foils and gases
##      calculate f' and f" for the elements
##                                     copyright (c) 1999 Bruce Ravel
##                                          ravel@phys.washington.edu
##                            http://feff.phys.washington.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##       http://feff.phys.washington.edu/~ravel/software/atoms/
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
my $version = '$Id: apt.pl,v 1.3 2000/04/20 11:58:38 bruce Exp $ ';
######################################################################
##  This is a simple GUI interface to the Xray::Absorption package.
##  At the click of a mouse it tells you element names, atomic
##  numbers, atomic weights, densities of pure materials, absorption
##  energies, and values of f' and f".  If supplied with an energy
##  value, it can calculate the aborption length of the material at
##  that energy.  If also supplied with a length, it can calculate the
##  attentuation of the pure material at the given energy.
##
##  When run, a periodic table is displayed in the upper half of a
##  window and, when an element is clicked, the data is displayed in
##  the lower half.  This is intended to be a handy-dandy little
##  beamline tool useful for checking edge energies, absorption of ion
##  chambers, and absorption of metal foils.
##
##  By default the Elam absorption data resource is used, except for
##  the f' and f" calculations which use CL if available and Henke
##  otherwise.  Of course any of the other resources could be used as
##  well.  I chose Elam because it has the most exhaustive list of
##  edge and line energies and CL because it produces a nice smooth
##  function.
######################################################################
## To do:
##   -- add more useful kinds of data
##   -- internationalize element names, then program
######################################################################
## Code:

BEGIN {
  use lib $ENV{IFEFFIT_DIR} . "/share//perl";
};
use warnings;
use strict;
use File::Spec;
use File::Basename;
use Tk;
## need to make PerlApp happy....
use Tk::widgets qw(NoteBook DialogBox Checkbutton Entry Label
		   Scrollbar Pod Pod/Text Pod/Tree Menu More ROText LabEntry);
use Chemistry::Elements qw(get_name get_Z);
use Xray::Absorption;
use constant PI    => 4 * atan2 1, 1;
use constant HBARC => 1973.27053324;

use Storable;
use Math::Spline;
use Math::Derivative;

my $install_dir = dirname($INC{'Xray/Absorption.pm'});

# columns: 0 -- 17    rows: 0 -- 8
# [ symbol, row, column, phase]
my @elements = (['H',  0, 0,  'g'],
		['He', 0, 17, 'g'],
		['Li', 1, 0,  'm'],
		['Be', 1, 1,  'm'],
		['B',  1, 12, 's'],
		['C',  1, 13, 'n'],
		['N',  1, 14, 'n'],
		['O',  1, 15, 'n'],
		['F',  1, 16, 'n'],
		['Ne', 1, 17, 'g'],
		['Na', 2, 0,  'm'],
		['Mg', 2, 1,  'm'],
		['Al', 2, 12, 'm'],
		['Si', 2, 13, 's'],
		['P',  2, 14, 'n'],
		['S',  2, 15, 'n'],
		['Cl', 2, 16, 'n'],
		['Ar', 2, 17, 'g'],
		['K',  3, 0,  'm'],
		['Ca', 3, 1,  'm'],
		['Sc', 3, 2,  'm'],
		['Ti', 3, 3,  'm'],
		['V',  3, 4,  'm'],
		['Cr', 3, 5,  'm'],
		['Mn', 3, 6,  'm'],
		['Fe', 3, 7,  'm'],
		['Co', 3, 8,  'm'],
		['Ni', 3, 9,  'm'],
		['Cu', 3, 10, 'm'],
		['Zn', 3, 11, 'm'],
		['Ga', 3, 12, 'm'],
		['Ge', 3, 13, 's'],
		['As', 3, 14, 's'],
		['Se', 3, 15, 'n'],
		['Br', 3, 16, 'n'],
		['Kr', 3, 17, 'g'],
		['Rb', 4, 0,  'm'],
		['Sr', 4, 1,  'm'],
		['Y',  4, 2,  'm'],
		['Zr', 4, 3,  'm'],
		['Nb', 4, 4,  'm'],
		['Mo', 4, 5,  'm'],
		['Tc', 4, 6,  'm'],
		['Ru', 4, 7,  'm'],
		['Rh', 4, 8,  'm'],
		['Pd', 4, 9,  'm'],
		['Ag', 4, 10, 'm'],
		['Cd', 4, 11, 'm'],
		['In', 4, 12, 'm'],
		['Sn', 4, 13, 'm'],
		['Sb', 4, 14, 's'],
		['Te', 4, 15, 's'],
		['I',  4, 16, 'n'],
		['Xe', 4, 17, 'g'],
		['Cs', 5, 0,  'm'],
		['Ba', 5, 1,  'm'],
		['La', 5, 2,  'm'],
		['Ce', 7, 4,  'm'],
		['Pr', 7, 5,  'm'],
		['Nd', 7, 6,  'm'],
		['Pm', 7, 7,  'm'],
		['Sm', 7, 8,  'm'],
		['Eu', 7, 9,  'm'],
		['Gd', 7, 10, 'm'],
		['Tb', 7, 11, 'm'],
		['Dy', 7, 12, 'm'],
		['Ho', 7, 13, 'm'],
		['Er', 7, 14, 'm'],
		['Tm', 7, 15, 'm'],
		['Yb', 7, 16, 'm'],
		['Lu', 7, 17, 'm'],
		['Hf', 5, 3,  'm'],
		['Ta', 5, 4,  'm'],
		['W',  5, 5,  'm'],
		['Re', 5, 6,  'm'],
		['Os', 5, 7,  'm'],
		['Ir', 5, 8,  'm'],
		['Pt', 5, 9,  'm'],
		['Au', 5, 10, 'm'],
		['Hg', 5, 11, 'm'],
		['Tl', 5, 12, 'm'],
		['Pb', 5, 13, 'm'],
		['Bi', 5, 14, 'm'],
		['Po', 5, 15, 'm'],
		['At', 5, 16, 's'],
		['Rn', 5, 17, 'g'],
		['Fr', 6, 0,  'm'],
		['Ra', 6, 1,  'm'],
		['Ac', 6, 2,  'm'],
		['Th', 8, 4,  'm'],
		['Pa', 8, 5,  'm'],
		['U',  8, 6,  'm'],
		['Np', 8, 7,  'm'],
		['Pu', 8, 8,  'm'],
		['Am', 8, 9,  'm'],
		['Cm', 8, 10, 'm'],
		['Bk', 8, 11, 'm'],
		['Cf', 8, 12, 'm'],
		['Es', 8, 13, 'm'],
		['Fm', 8, 14, 'm'],
		['Md', 8, 15, 'm'],
		['No', 8, 16, 'm'],
		['Lr', 8, 17, 'm'],
		['Rf', 6, 3,  'm'],
		['Ha', 6, 4,  'm'],
		['Sg', 6, 5,  'm'],
		['Bh', 6, 6,  'm'],
		['Hs', 6, 7,  'm'],
		['Mt', 6, 8,  'm']);



## determine location of languages and foilsrc file from the location
## of Xray::Absorption, the only part of Atoms actually used by this
## program.
## my ($languages, $this_language, @available_languages);
## my $abs_location = $INC{'Xray/Absorption.pm'};
## my ($abs_name,$atoms_path) = fileparse($abs_location);
## my $libdir = File::Spec->catfile($atoms_path, 'lib');
##
## my $languagerc = File::Spec->catfile($libdir, 'languages');
## eval "do '$languagerc'" or die "Language rc file not found$/";
##
## my $suffix = $$languages{english};
## my $language_database = File::Spec->catfile($libdir, 'foilsrc.'.$suffix);
## #eval "do '$language_database'" or die "Foils language data file not found$/";

my %apt_language;
%apt_language = (title			=> "The ATOMS Periodic Table",
		 energies		=> "Energies",
		 wavelengths		=> "Wavelengths",
		 lanthanides		=> "Lanthanides:",
		 actinides		=> "Actinides:",
		 energy			=> "Energy:",
		 wavelength		=> "Wavelength:",
		 thickness		=> "Thickness:",
		 thickness_units	=> "µm (cm for gases)",
		 Name			=> "Name",
		 Number			=> "Number",
		 Weight			=> "Weight",
		 Density		=> "Density",
		 'Absorption Length'	=> "Absorption Length",
		 Attenuation		=> "Transmitted fraction",
		 edges_ev		=> 'Edges (eV)',
		 edges_a		=> 'Edges (Å)',
		 lines_ev		=> 'Lines (eV)',
		 lines_a		=> 'Lines (Å)',
		 clear			=> 'Clear',
		 help			=> 'Help',
		 'exit'			=> 'Exit',
		 warning_title		=> 'APT warning!',
		 ok			=> 'OK',
		 cancel			=> 'Cancel',
		 low_energy		=>
		 "Foils is currently set to use energies.$/" .
		 "You have chosen a very low energy.  Should I$/" .
		 "try to calculate the absorption length?$/" .
		 "(There might be no data at that energy!)",
		 high_wavelength	=>
		 "Foils is currently set to use wavelengths.$/" .
		 "You have chosen a very large wavelnegth.  Should I$/" .
		 "try to calculate the absorption length?$/" .
		 "(There might be no data at that wavelength!)",

		 "energy_range" => 'Energy Range',
		 'from' => 'from:',
		 'to' => 'to:',
		 'step' => 'step:',
		 'edge' => 'edge:',
		 'clear_range' => 'Clear range',
		 'save_data' => 'Save data',
		 'no_data' => 'No data for ',
		);


## load the absorption and atom data
Xray::Absorption -> load("elam");
my $fpfpp_source = grep (/CL/, Xray::Absorption -> available()) ? "CL" : "Henke";
my $display_fpfpp = 0; #($fpfpp_source eq "CL");
my $ev               = $Xray::Absorption::Elam::elam_version;
my $show_intensities = 1;
my $current_units    = $apt_language{'energies'};
my $odd_value        = 40;	# energy/wavelength cutoff
my $is_apt = ($0 =~ /apt/);	# stand-alone or called by  another program?
my (@e, @fp, @fpp);

my %fpfpp_params = (edge       => '',
		    overplot   => 0,
		    colors     => [qw(red blue darkgreen brown
				      darkviolet deeppink)],
		    plotnumber => 0,
		    current    => '');


## handle command line switches
use Getopt::Std;
use vars qw($opt_h $opt_v);
getopts('vh');
if ($opt_h) {
  require Pod::Text;
  $^W=0;
  Pod::Text::pod2text($0, *STDOUT);
  exit;
};
if ($opt_v) {
  my $v = (split(' ', $version))[2];
  my $d = (split(' ', $version))[3];
  my $ev = $Xray::Absorption::Elam::elam_version;
  print <<EOH

    APT - simple graphical interface to the Xray::Absorption package
    version $v ($d) copyright (c) 1999 Bruce Ravel
    using Xray::Absorption $Xray::Absorption::VERSION and Elam Tables version $ev

EOH
  ;
  exit;
}

## set up the window
use vars qw/$top/;
if ($is_apt) {
  $top = MainWindow->new(-class=>'horae');
  $top -> setPalette(foreground=>'black', background=>'cornsilk3', #'#cdb79e',
		     highlightColor=>'red', font=>'Arial 12 bold');
} else {
  $top = $::top -> Toplevel;
};
$top -> title($apt_language{'title'});
$top -> iconname($apt_language{'title'});
$top -> iconbitmap('@'.File::Spec->catfile($install_dir, "lib", "elephant.xbm"))
  unless (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
$top -> bind('<Control-q>' => \&exit_or_dismiss);
$top -> bind('<Control-x>' => \&exit_or_dismiss);
$top -> bind('<Control-c>' => \&clear_data);
$top -> bind('<Control-t>' => \&swap_units);
$top -> bind('<Control-h>' => \&display_help);

## declare some global variables
my ($energy, $thickness, %energies, %data, %probs);

## common widget arguments
my @label_args     = qw(-foreground        blue3);
my @metal_args	   = (-foreground       => 'seashell',
		      -background       => 'darkslategrey',
		      -activeforeground => 'black',
		      -activebackground => 'slategrey',
		      -font             => 'Arial 12 bold');
my @semimetal_args = (-foreground       => 'seashell',
		      -background       => 'khaki4',
		      -activeforeground => 'black',
		      -activebackground => 'khaki3',
		      -font             => 'Arial 12 bold');
my @nonmetal_args  = (-foreground       => 'seashell',
		      -background       => 'cadetblue4',
		      -activeforeground => 'black',
		      -activebackground => 'cadetblue3',
		      -font             => 'Arial 12 bold');
my @gas_args	   = (-foreground       => 'seashell',
		      -background       => 'goldenrod4',
		      -activeforeground => 'black',
		      -activebackground => 'goldenrod3',
		      -font             => 'Arial 12 bold');
my @button_font = (-font=>'Arial 12 bold');
my @action_args    = qw(-foreground        seashell
			-background        firebrick4
			-activeforeground  seashell
			-activebackground  firebrick3
			-width             12
			-font);
my @answer_args = (-foreground=>'black',
		   -background=>'cornsilk3',
		   (($Tk::VERSION > 804) ?
		    (-disabledforeground=>'black',
		     -disabledbackground=>'cornsilk3',) :
		    ())
		  );
push @action_args, 'Arial 12 bold';


## -------------------------------------------------------------------
## control buttons
my @button_args = @action_args;
my $box = $top -> Frame(-relief=>'ridge', -borderwidth=>3)
  -> pack(-fill=>'x', -side=>"bottom");
my $button = $box -> Button(-text=>$apt_language{'clear'},
			    @button_args, -command=>\&clear_data)
  -> pack(-padx=>2, -pady=>2, -side=>'left');
$button = $box -> Button(-text=>$apt_language{'help'},
			 @button_args, -command=>\&display_help)
  -> pack(-padx=>2, -pady=>2, -side=>'left');
my $units_button = $box -> Button(-text=>$apt_language{'wavelengths'},
				  @button_args, -command=>\&swap_units)
  -> pack(-padx=>2, -pady=>2, -side=>'left');
$button = $box -> Button(-text=>$apt_language{'exit'},
			 @button_args, -command=>\&exit_or_dismiss)
  -> pack(-padx=>2, -pady=>2, -side=>'right');



## set up the frame structure within the window
my $frame = $top -> Frame(-relief=>'ridge', -borderwidth=>3,)
  -> pack(-side=>"top");
my $trans = $frame -> Frame()
  -> grid(-column=>0, -row=>7, -columnspan=>17, -pady=>6);
my $label = $trans -> Label(-text=>$apt_language{'lanthanides'}, @label_args)
  -> grid(-column=>0, -columnspan=>3, -row=>0, -sticky=>'e');
$label = $trans -> Label(-text=>$apt_language{'actinides'}, @label_args)
  -> grid(-column=>0, -columnspan=>3, -row=>1, -sticky=>'e');


## -------------------------------------------------------------------
## set up periodic table
my %arg_refs = ('m'=>\@metal_args,    's'=>\@semimetal_args,
		'n'=>\@nonmetal_args, 'g'=>\@gas_args);
foreach my $e (@elements) {
  my ($s, $r, $c, $p) = ($e->[0], $e->[1], $e->[2], $e->[3]);
  @button_args = @{$arg_refs{$p}};
  if ($r < 7) {			# s p and d atoms
    my $button = $frame -> Button(-text=>$s, -width=>1,
				  @button_args, @button_font,
				  -command=>[\&get_data, $s])
      -> grid(-column=>$c, -row=>$r);
  } else {			# lanthandes and actinides
    my $button = $trans -> Button(-text=>$s, -width=>1,
				  @button_args, @button_font,
				  -command=>[\&get_data, $s])
      -> grid(-column=>$c, -row=>$r-7);
  };
};

## energy and thickness entry widgets (place these in the row 0 gap)
my $energy_label = $frame -> Label(-text=>$apt_language{'energy'}, @label_args)
  -> grid(-column=>1, -columnspan=>4, -row=>0, -sticky=>'e');
my $entry = $frame -> Entry(-width=>9, -textvariable=>\$energy)
  -> grid(-column=>5, -columnspan=>3, -row=>0, -sticky=>'w');
my $units_label = $frame -> Label(-text=>"eV", @label_args)
  -> grid(-column=>8, -row=>0, -sticky=>'w');

$label = $frame -> Label(-text=>$apt_language{'thickness'}, @label_args)
  -> grid(-column=>2, -columnspan=>3, -row=>1, -sticky=>'e');
$entry = $frame -> Entry(-width=>9, -textvariable=>\$thickness)
  -> grid(-column=>5, -columnspan=>3, -row=>1, -sticky=>'w');
$label = $frame -> Label(-text=>$apt_language{'thickness_units'}, @label_args)
  -> grid(-column=>8, -columnspan=>4, -row=>1, -sticky=>'w');


## -------------------------------------------------------------------
## Bottom panel containing the results

my %pages;
my $notebook;
if ($display_fpfpp) {
  $notebook  =  $top -> NoteBook();
  $notebook->pack(-expand => 'y', -fill => 'both', -side => 'top');
  $pages{"Foils"}  = $notebook -> add('Foils', -label=>'Foils',  -anchor=>'center');
} else {
  $pages{"Foils"} = $top -> Frame() ->pack(-fill=>'x', -expand=>'yes');
};

## foils notecard

$frame = $pages{'Foils'} -> Frame(-relief=>'flat', -borderwidth=>2,)
  -> pack( -fill=>'both', -expand=>'yes', -side=>"top");
my @all_entries = ();
$label = $frame -> Label(-width=>3) -> grid(-column=>1, -row=>0);
my $r = 0;
foreach my $l ('Name', 'Number', 'Weight', 'Density',
	       'Absorption Length', 'Attenuation') {
  $label = $frame -> Label(-text=>$apt_language{$l}, @label_args)
    -> grid(-column=>2, -row=>++$r, -sticky=>'w', -padx=>2);
  $entry = $frame -> Entry(-relief=>'flat', -textvariable=>\$data{$l},
			   -width=>15, @answer_args)
    -> grid(-column=>3, -row=>$r, -sticky=>'e', -padx=>2);
  push @all_entries, $entry;
};
$label = $frame -> Label(-text=>'', @label_args)
  -> grid(-column=>2, -row=>++$r, -sticky=>'w', -padx=>2);

## NoteBook for Edge energies
my $edges_label = $frame -> Label(-text=>$apt_language{'edges_ev'}, @label_args)
  -> grid(-column=>4, -row=>0);
my $edges = $frame -> NoteBook(-backpagecolor=>'cornsilk3',
			       -inactivebackground=>'cornsilk3',
			      )
  -> grid(-column=>4, -row=>1, -rowspan=>6, -padx=>6);

my %edges = ('KL' => [qw(K L1 L2 L3)],
	     'M'  => [qw(M1 M2 M3 M4 M5)],
	     'N'  => [qw(N1 N2 N3 N4 N5 N6 N7)],
	     'O'  => [qw(O1 O2 O3 O4 O5)],
	     'P'  => [qw(P1 P2 P3)]);
foreach my $set (qw(KL M N O P)) {
  my $page = $edges -> add($set, -label=>$set, -anchor=>'center');
  $r =0;
  foreach my $l (@{$edges{$set}}) {
    $label = $page -> Label(-text=>$l, @label_args)
      -> grid(-column=>0, -row=>++$r, -sticky=>'w', -padx=>2);
    $entry = $page -> Entry(-relief=>'flat', -textvariable=>\$energies{$l},
			    -width=>6, @answer_args)
      -> grid(-column=>1, -row=>$r, -sticky=>'e', -padx=>2);
    push @all_entries, $entry;
  };
};


## NoteBook for line energies
my $lines_label = $frame -> Label(-text=>$apt_language{'lines_ev'}, @label_args)
  -> grid(-column=>5, -row=>0);
my $lines = $frame -> NoteBook(-relief=>'sunken',
			       -backpagecolor=>'cornsilk3',
			       -inactivebackground=>'cornsilk3',
			      )
  -> grid(-column=>5, -row=>1, -rowspan=>6, -sticky=>'n');

my %lines = ('Ka'  => [qw(Ka1 Ka2 Ka3)],
	     'Kb'  => [qw(Kb1 Kb2 Kb3 Kb4 Kb5)],
	     'La'  => [qw(La1 La2)],
	     'Lb'  => [qw(Lb1 Lb2 Lb3 Lb4 Lb5 Lb6)],
	     'Lg'  => [qw(Lg1 Lg2 Lg3 Lg6)],
	     'etc' => [qw(Ll Ln Ma Mb Mg Mz)]);
foreach my $set (qw(Ka Kb La Lb Lg etc)) {
  my $page = $lines -> add($set, -label=>$set, -anchor=>'center');
  $r =0;
  foreach my $l (@{$lines{$set}}) {
    my $text = Xray::Absorption -> get_Siegbahn_full($l) .
      " (" . Xray::Absorption -> get_IUPAC($l) . ")";
    $label = $page -> Label(-text=>$text, @label_args)
      -> grid(-column=>0, -row=>++$r, -sticky=>'w', -padx=>2);
    $entry = $page -> Entry(-relief=>'flat', -textvariable=>\$energies{$l},
			    -width=>6, @answer_args)
      -> grid(-column=>1, -row=>$r, -sticky=>'e', -padx=>2);
    push @all_entries, $entry;
    if ($show_intensities) {
      $entry = $page -> Entry(-relief=>'flat', -textvariable=>\$probs{$l},
			      -width=>7, @answer_args)
	-> grid(-column=>2, -row=>$r, -sticky=>'e', -padx=>2);
      push @all_entries, $entry;
    };
  };
};
## need to put flat relief entries in a disabled state.  this allows
## the user to cut and paste from them, but not to modify them
map {$_ -> configure(-state=>'disabled')} @all_entries;

## fpfpp notecard
my $canvas;
my %canvas_params;
my (@canvas_plot, @canvas_tics, @canvas_labels);
my ($energy_from, $energy_to, $energy_step);
if ($display_fpfpp) {
  $pages{"FpFpp"} = $notebook -> add('FpFpp', -label=>'F\' F"', -anchor=>'center');
  $notebook -> pageconfigure('FpFpp', -createcmd=>\&make_fpfpp_card);
  %canvas_params = (from	  => '',
		    to		  => '',
		    step	  => '',
		    width	  => 500,
		    height	  => 200,
		    tic_length	  => 5,
		    left_margin	  => 50,
		    right_margin  => 10,
		    top_margin	  => 10,
		    bottom_margin => 20,
		    label_index	  => 0,);
};


## -------------------------------------------------------------------
MainLoop();



## -------------------------------------------------------------------
## subroutines for all notecards
sub get_data {
  if (not $display_fpfpp) {
    &get_foils_data(@_);
  } elsif ($notebook -> raised() eq "Foils") {
    &get_foils_data(@_);
  } elsif ($notebook -> raised() eq "FpFpp") {
    &get_fpfpp_data(@_);
  };
};

sub clear_data {
  if (not $display_fpfpp) {
    &clear_foils_data;
  } elsif ($notebook -> raised() eq "Foils") {
    &clear_foils_data;
  } elsif ($notebook -> raised() eq "FpFpp") {
    &clear_fpfpp_data;
  };
};

sub swap_units {
  if (not $display_fpfpp) {
    &swap_foils_units;
  } elsif ($notebook -> raised() eq "Foils") {
    &swap_foils_units;
  } elsif ($notebook -> raised() eq "FpFpp") {
    my $dialog = $top -> DialogBox(-title=>$apt_language{'apt_warning'},
				   -buttons=>[$apt_language{'ok'}],);
    $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
		   "You cannot currently switch between energy and wavelength$/" .
		   "in the anomalous scattering calculation.")
      -> pack(-side=>'left');
    $dialog -> Show;
  };
};

sub exit_or_dismiss {
  if ($is_apt) {
    exit;
  } else {
    $top -> withdraw;
  };
};

sub display_help {
  my $file;
  if (($^O eq 'MSWin32') or ($^O eq 'cygwin')) {
    $file = File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", "apt.pod");
  } else {
    $file = $0;
  };
  if (-e $file) {
    $top->Pod(-file=>$file);
  } else {
    my $dialog = $top -> DialogBox(-title=>$apt_language{'apt_warning'},
				   -buttons=>[$apt_language{'ok'}],);
    $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
		   "Could not find the APT documentation file.  Sorry.")
      -> pack(-side=>'left');
    $dialog -> Show;
    return;
  };
};



## -------------------------------------------------------------------
## subroutines for Foils

sub get_foils_data {
  my $elem = $_[0];
  my $in_resource = Xray::Absorption -> in_resource($elem);
  map {$probs{$_} = ''} keys(%probs);
  ## enable writing in the entry widgets
  map {$_ -> configure(-state=>'normal')} @all_entries;
  $data{Name}    = get_name($elem);
  $data{Number}  = get_Z($elem);
  my $z          = $data{Number};
  $data{Weight}  = Xray::Absorption -> get_atomic_weight($elem);
  $data{Weight}  = ($data{Weight}) ? $data{Weight} . ' amu' : '' ;
  my $density    = Xray::Absorption -> get_density($elem);
  $data{Density} = ($density) ? $density . ' gr/cm^3' : '' ;

  foreach my $e (qw(K L1 L2 L3 M1 M2 M3 M4 M5 N1 N2 N3 N4 N5 N6 N7
		    O1 O2 O3 O4 O5 P1 P2 P3
		    Ka1 Ka2 Ka3 Kb1 Kb2 Kb3 Kb4 Kb5
		    La1 La2 Lb1 Lb2 Lb3 Lb4 Lb5 Lb6
		    Lg1 Lg2 Lg3 Lg6 Ll Ln Ma Mb Mg Mz )) {
    $energies{$e} = Xray::Absorption -> get_energy($elem, $e);
    $energies{$e} ||= '';
    unless ($e =~ /^(K|([LMNOP][1-7]))$/) {
      next unless $energies{$e};
      $probs{$e} =
	sprintf "(%6.4f)", Xray::Absorption -> get_intensity($elem, $e);
    };
  };

  if (($z >= 22) and ($z <= 29)) {
    $energies{M4} = '';
    $energies{M5} = '';
  };
  if ($z <= 17) {
    $energies{M1} = '';
    $energies{M2} = '';
    $energies{M3} = '';
  };
  ($current_units eq "Wavelengths") and
    map {$energies{$_} = &e2l($energies{$_})} keys(%energies);

  ##my $is_gas = ($elem =~ /\b(Ar|Br|Cl|F|H|He|Kr|N|Ne|O|Rn|Xe)\b/);
  my $is_gas = ($elem =~ /\b(Ar|Cl|H|He|Kr|N|Ne|O|Rn|Xe)\b/);

  $data{'Absorption Length'} = '';
  $data{'Attenuation'}       = '';
  my $bail = 0;
  if ($energy and $in_resource) {
    if (($energy < $odd_value) and ($current_units eq "Energies")) {
      my $dialog = $top -> DialogBox(-title=>$apt_language{'apt_warning'},
				     -buttons=>[$apt_language{'ok'},
						$apt_language{'cancel'},],);
      $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
		     $apt_language{low_energy})
	-> pack(-side=>'left');
      my $answer = $dialog -> Show;
      ($answer eq $apt_language{'cancel'}) and $bail = 1;
    } elsif (($energy > $odd_value) and ($current_units eq "Wavelengths")) {
      my $dialog = $top -> DialogBox(-title=>$apt_language{'apt_warning'},
				     -buttons=>[$apt_language{'ok'},
						$apt_language{'cancel'},],);
      $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
		    $apt_language{high_wavelength})
	-> pack(-side=>'left');
      my $answer = $dialog -> Show;
      ($answer eq $apt_language{'cancel'}) and $bail = 1;
    };
    unless ($bail) {
      my $conv   = Xray::Absorption -> get_conversion($elem);
      ($current_units eq "Wavelengths") and $energy = &e2l($energy);
      my $barns  = Xray::Absorption -> cross_section($elem, $energy);
      ($current_units eq "Wavelengths") and $energy = &e2l($energy);
      my $factor = ($is_gas) ? 1 : 10000;
      my $abslen = ($conv and $barns and $density) ?
	$factor/($barns*$density/$conv) : 0;
      $data{'Absorption Length'} = '';
      if ($abslen) {
	$data{'Absorption Length'}  = 	sprintf "%8.2f", $abslen;
	$data{'Absorption Length'} .= ($is_gas) ? ' cm' : ' µm';
	$data{'Absorption Length'} =~ s/^\s+//;
      };

      $data{'Attenuation'} = '';
      ##print join("  ", $conv, $barns, $density, $thickness, $abslen, $is_gas, $/);
      if ($thickness and $abslen) {
	my $factor = $thickness / $abslen;
	$data{'Attenuation'} = sprintf ("%6.4g", exp(-1 * $factor));
      };
    };
  };
  ## and disable writing in the entry widgets once again
  map {$_ -> configure(-state=>'disabled')} @all_entries;
};

## sub clear_foils_data {
##   map {$data{$_}     = ''} keys(%data);
##   map {$energies{$_} = ''} keys(%energies);
##   map {$probs{$_}    = ''} keys(%probs);
##   map {$_            = ''} ($energy, $thickness);
##   $edges->raise('KL');
##   $lines->raise('Ka');
##   ($current_units eq "Wavelengths") and &swap_foils_units;
## };

sub swap_foils_units {
  if ($display_fpfpp) {
    return if ($notebook -> raised() eq "FpFpp");
  };
  $energy = &e2l($energy);
  map {$energies{$_} = &e2l($energies{$_})} keys(%energies);
  $units_button -> configure(-text=>$current_units);
  $current_units = ($current_units eq "Energies") ? "Wavelengths" : "Energies";
  if ($current_units eq "Energies") {
    $energy_label -> configure(-text=>$apt_language{'energy'});
    $units_label  -> configure(-text=>'eV');
    $edges_label  -> configure(-text=>$apt_language{'edges_ev'});
    $lines_label  -> configure(-text=>$apt_language{'lines_ev'});
  } else {
    $energy_label -> configure(-text=>$apt_language{'wavelength'});
    $units_label  -> configure(-text=>'Å');
    $edges_label  -> configure(-text=>$apt_language{'edges_a'});
    $lines_label  -> configure(-text=>$apt_language{'lines_a'});
  };
};

sub e2l {
  ($_[0] and ($_[0] > 0)) or return "";
  return 2*PI*HBARC / $_[0];
};


## -------------------------------------------------------------------
## subroutines for FpFpp

## set up the notecard -- this is called the first time the card is
## viewed.
sub make_fpfpp_card {
  my $frame = $pages{'FpFpp'} -> Frame(-relief=>'flat', -borderwidth=>2,)
    -> pack( -fill=>'both', -expand=>'yes', -side=>"top");
  my $left = $frame -> Frame(-relief=>'flat', -borderwidth=>2,)
    -> pack( -fill=>'both', -side=>"left", -padx=>10);

  my $label = $left -> Label(-text=>$apt_language{energy_range}, @label_args)
    -> grid(-column=>0, -row=>0, -columnspan=>2, -sticky=>'s');
  $label = $left -> Label(-text=>$apt_language{from}, @label_args)
    -> grid(-column=>0, -row=>1,, -sticky=>'e');
  $label = $left -> Label(-text=>$apt_language{to},   @label_args)
    -> grid(-column=>0, -row=>2,, -sticky=>'e');
  $label = $left -> Label(-text=>$apt_language{step}, @label_args)
    -> grid(-column=>0, -row=>3,, -sticky=>'e');
  my $entry = $left -> Entry(-width=>9, -textvariable=>\$canvas_params{from})
    -> grid(-column=>1, -row=>1, -sticky=>'w');
  $entry = $left -> Entry(-width=>9, -textvariable=>\$canvas_params{to})
    -> grid(-column=>1, -row=>2, -sticky=>'w');
  $entry = $left -> Entry(-width=>9, -textvariable=>\$canvas_params{step})
    -> grid(-column=>1, -row=>3, -sticky=>'w');

  $label = $left -> Label(-text=>$apt_language{edge}, @label_args)
    -> grid(-column=>0, -row=>4, -sticky=>'e');
  my $edge_button = $left
    -> Optionmenu(-textvariable => \$fpfpp_params{edge}, @label_args,
		  -width=>3, -relief=>'groove')
      -> grid(-column=>1, -row=>4, -sticky=>'w');
  foreach my $e ("", qw/K L3 L2 L1/) {
    $edge_button -> command(-label => $e, @label_args,
			    -command=>sub{$fpfpp_params{edge}=$e;});
  };
  @button_args = @action_args;
  ## $button = $left ->
  ##   Checkbutton(-selectcolor => 'firebrick4',
  ## 	      -text        => 'Overplot?', @label_args,
  ## 	      -variable    => \$fpfpp_params{overplot}, )
  ##   -> grid(-column=>0, -row=>5, -columnspan=>2, -sticky=>'w');
  $button = $left ->
    Button(-text=>$apt_language{clear_range}, @button_args,
	   -command=>
	   sub{($canvas_params{from},$canvas_params{to},$fpfpp_params{edge}) =
		 ('','','')})
    -> grid(-column=>0, -row=>6, -columnspan=>2, -sticky=>'w');
  $button = $left -> Button(-text=>$apt_language{save_data}, @button_args,
			    -command=>[\&save_fpfpp_data, \@e, \@fp, \@fpp])
    -> grid(-column=>0, -row=>7, -columnspan=>2, -sticky=>'w');

  $canvas = $frame
    -> Canvas(-width=>$canvas_params{width},
	      -height=>$canvas_params{height}, -background=>'#fff5ee')
      -> pack(-side=>'right', -padx=>5);
  $canvas -> createLine($canvas_params{left_margin},
			$canvas_params{right_margin},
			$canvas_params{left_margin},
			$canvas_params{height}-$canvas_params{bottom_margin});
  $canvas -> createLine($canvas_params{left_margin},
			$canvas_params{height}-$canvas_params{bottom_margin},
			$canvas_params{width}-$canvas_params{right_margin},
			$canvas_params{height}-$canvas_params{bottom_margin});
  foreach my $i (0.25, 0.5, 0.75, 1) {
    push @canvas_tics, make_tic($canvas, 'x', $i, $canvas_params{tic_length});
    push @canvas_tics, make_tic($canvas, 'y', $i, $canvas_params{tic_length});
  };
};

## convert fractional values to canvas coordinates.  by fractional I
## mean the distance of the coordinate from the top or left divided by
## the range of that axis.
sub function2canvas {
  my ($x, $y) = @_;
  my $ny = $canvas_params{height} - $canvas_params{bottom_margin} -
    $canvas_params{top_margin};
  my $nx = $canvas_params{width} - $canvas_params{left_margin} -
    $canvas_params{right_margin};
  $x  = (1-$x)*$nx + $canvas_params{left_margin};
  $y  = $y*$ny + $canvas_params{top_margin};
  return (sprintf("%d", $x), sprintf("%d", $y));
};

## draw a tic at the specified fractional coordinate on the specified
## axis
sub make_tic {
  my ($canvas, $axis, $value) = @_;
  my $size = 5;
  my ($x1, $y1, $x2, $y2);
  if ($axis eq 'x') {
    $value = (1-$value)*$canvas_params{width} +
      $value*$canvas_params{left_margin};
    $x1 = int($value);
    $y1 = $canvas_params{height}-$canvas_params{bottom_margin};
    $x2 = int($value);
    $y2 = $canvas_params{height}-$canvas_params{bottom_margin}-$size;
  } else {
    my $ny = $canvas_params{height} - $canvas_params{bottom_margin} -
      $canvas_params{top_margin};
    $value *= $ny;
    #$value  = $ny-int($value);
    $x1 = $canvas_params{left_margin};
    $y1 = $value+$canvas_params{right_margin};
    $x2 = $canvas_params{left_margin}+$size;
    $y2 = $value+$canvas_params{right_margin};
  };
  return $canvas -> createLine($x1, $y1, $x2, $y2);
}

## read the bounds of the energy grid and fetch f' and f"
sub get_fpfpp_data {
  my $elem = $_[0];
  unless (Xray::Absorption -> in_resource($elem)) {
    $canvas -> delete($canvas_labels[$fpfpp_params{label_index}]);
    push @canvas_labels, $canvas ->
      createText(&function2canvas(0.95,0.05), -anchor=>'w',
		 -text=>$apt_language{no_data}.$elem);
    $fpfpp_params{label_index} = $#canvas_labels;
    return;
  };
  $fpfpp_params{current} = $elem;
  Xray::Absorption -> load($fpfpp_source);
  $fpfpp_params{plotnumber} = ($fpfpp_params{overplot}) ?
    $fpfpp_params{plotnumber}+1 : 0;
  ($fpfpp_params{overplot}) or do {
    map { $canvas -> delete($_) } @canvas_plot;
    map { $canvas -> delete($_) } @canvas_tics;
    map { $canvas -> delete($_) } @canvas_labels;

    unless ($canvas_params{from}) {
      my $edge = $fpfpp_params{edge} || "K";
      (&get_Z($elem) > 57) and $edge = $fpfpp_params{edge} || "L3";
      $fpfpp_params{edge} = $edge;
      my $enot = Xray::Absorption -> get_energy($elem, $edge);
      $canvas_params{from} = $enot - 100;
    };
    $canvas_params{to}   ||= $canvas_params{from} + 200;
    $canvas_params{step} ||= 2;
    ($canvas_params{from} > $canvas_params{to}) and
      ($canvas_params{from}, $canvas_params{to}) =
	($canvas_params{to}, $canvas_params{from});
  };

  my $this_energy = $canvas_params{from};
  my ($fp_min, $fpp_max) = (10000, -10000);
  (@e, @fp, @fpp) = ((), (), ());
  while ($this_energy < $canvas_params{to}) {
    my ($this_fp, $this_fpp) =
      (Xray::Absorption -> cross_section($elem, $this_energy, "f1"),
       Xray::Absorption -> cross_section($elem, $this_energy, "f2"));
    #print join ("  ", $this_fp, $this_fpp, $/);
    ($this_fp  < $fp_min)  and $fp_min  = $this_fp;
    ($this_fpp > $fpp_max) and $fpp_max = $this_fpp;
    push @e,   $this_energy;
    push @fp,  $this_fp;
    push @fpp, $this_fpp;
    $this_energy += $canvas_params{step};
  };
  my $espan = $canvas_params{to} - $canvas_params{from};
  my $yspan = $fpp_max - $fp_min;
  #print join(" ", $fpp_max, $fp_min, $yspan, $/);
  my (@fp_plot, @fpp_plot, @xzero);
  foreach my $i (0..$#e) {
    push @xzero, &function2canvas(($canvas_params{to}-$e[$i])/$espan,
				  $fpp_max/$yspan);
    push @fp_plot,
    &function2canvas(($canvas_params{to}-$e[$i])/$espan,
		     ($fpp_max-$fp[$i])/$yspan);
    push @fpp_plot,
    &function2canvas(($canvas_params{to}-$e[$i])/$espan,
		     ($fpp_max-$fpp[$i])/$yspan);
  };

  ## draw the functions and the yzeroaxis
  push @canvas_plot, $canvas ->
    createLine(@fp_plot,
	       -fill=>$fpfpp_params{colors}[$fpfpp_params{plotnumber}]);
  push @canvas_plot, $canvas ->
    createLine(@fpp_plot,
	       -fill=>$fpfpp_params{colors}[$fpfpp_params{plotnumber}]);
  ($fpfpp_params{overplot}) or do {
    push @canvas_plot, $canvas -> createLine(@xzero);

    ## draw the element label
    push @canvas_labels, $canvas ->
      createText(&function2canvas(0.95,0.05), -anchor=>'w',
		 -text=>$fpfpp_params{current});
    $fpfpp_params{label_index} = $#canvas_labels;

    ## draw and label the x-tics
    &draw_and_label_tic($canvas, 'x', 10*int(($canvas_params{to}-0.1*$espan)/10),
			($canvas_params{to}-
			 10*int(($canvas_params{to}-0.1*$espan)/10))/$espan);
    &draw_and_label_tic($canvas, 'x', 10*int(($canvas_params{to}-0.5*$espan)/10),
			($canvas_params{to}-
			 10*int(($canvas_params{to}-0.5*$espan)/10))/$espan);
    &draw_and_label_tic($canvas, 'x', 10*int(($canvas_params{to}-0.9*$espan)/10),
			($canvas_params{to}-
			 10*int(($canvas_params{to}-0.9*$espan)/10))/$espan);

    ## draw and label the y-tics
    &draw_and_label_tic($canvas, 'y', 0, $fpp_max/$yspan);
    &draw_and_label_tic($canvas, 'y', int($fpp_max),
			($fpp_max-int($fpp_max))/$yspan);
    &draw_and_label_tic($canvas, 'y', int($fp_min/3),
			($fpp_max-int($fp_min/3))/$yspan);
    &draw_and_label_tic($canvas, 'y', 2*int($fp_min/3),
			($fpp_max-2*int($fp_min/3))/$yspan);
    &draw_and_label_tic($canvas, 'y', 3*int($fp_min/3),
			($fpp_max-3*int($fp_min/3))/$yspan);
  };
  Xray::Absorption -> load("Elam");

};

## 1. reference to canvas object,  2. 'x' or 'y',  3. text of label,
## 4. fractional position
sub draw_and_label_tic {
  my ($canvas, $axis, $label, $position) = @_;
  my ($anchor, $other) = ('center', $canvas_params{height} - 5);
  ($axis eq 'y') and ($anchor, $other) = ('e', $canvas_params{left_margin} - 3);
  ($label) and
    push @canvas_tics, make_tic($canvas, $axis, $position,
				$canvas_params{tic_length});
  if ($axis eq 'y') {
    push @canvas_labels, $canvas ->
      createText($other, (&function2canvas(0, $position))[1],
		 -anchor=>$anchor, -text=>$label);
  } else {
    push @canvas_labels, $canvas ->
      createText((&function2canvas($position, 0))[0], $other,
		 -anchor=>$anchor, -text=>$label);
  };
};

sub clear_fpfpp_data {
  map { $canvas -> delete($_) } @canvas_plot;
  map { $canvas -> delete($_) } @canvas_tics;
  map { $canvas -> delete($_) } @canvas_labels;
  foreach my $i (0.25, 0.5, 0.75, 1) {
    push @canvas_tics, make_tic($canvas, 'x', $i, $canvas_params{tic_length});
    push @canvas_tics, make_tic($canvas, 'y', $i, $canvas_params{tic_length});
  };
  map {$_ = ''} ($canvas_params{from}, $canvas_params{to}, $canvas_params{step});
  $fpfpp_params{edge} = '';
};

sub save_fpfpp_data {
  my ($e, $fp, $fpp) = @_;
  return unless (@$e and @$fp and @$fpp);
  require Cwd;
  my $types = [['Data files', '.dat'],
	       ['All Files',  '*'],];
  my $file = $top -> getSaveFile(-defaultextension=>'dat',
				 -filetypes=>$types,
				 -initialdir=>Cwd::cwd(),
				 -initialfile=>
				 "fpfpp_".$fpfpp_params{current}.".dat",
				 -title => 'APT: File Dialog');
  return 0 unless $file;
  open OUT, ">".$file or die $!;
  print OUT "# Cromer-Liberman calculation for $fpfpp_params{current}$/";
  print OUT "# ------------------------------------------------$/";
  print OUT "#  energy        f'        f\"$/";
  map { printf OUT "  %.2f  %9.4f  %8.4f$/", $$e[$_], $$fp[$_], $$fpp[$_] }
         (0..$#{$e});
  close OUT;
};


1;



######################################################################
## End of main program atoms

=head1 NAME

APT - The ATOMS Periodic Table

=head1 SYNOPSIS

Simple graphical interface to the Xray::Absorption package

   apt [-v] [-h]

=head1 DESCRIPTION

This is a simple graphical interface to the x-ray absorption data for
the elements contained in the Xray::Absorption package.  When run, a
window appears displaying a colorful periodic table of the elements.
Clicking on an element causes data about that element to be displayed
in the bottom half of the window.

All energies in this program are in eV.  All wavelengths are in
Angstroms.  All distances are in microns or centimeters as described
above.  The buttons labeled C<Clear>, C<Help>, and C<Exit> do exactly
what their labels suggest, although the C<Clear> button only clears
the currently displayed notecard.  These have keyboard shortcuts of
C<control-c>, C<control-h>, and C<control-q> respectively.
C<Control-t> is the keyboard shortcut for toggling between energy and
wavelength units.

If this program is invoked with a C<-v> switch, version information is
displayed to standard output and the program quits.  If C<-h> is
given, this help document is displayed to standard output and the
program quits.

=head1 THE ENERGIES AND ABSORPTION LENGTHS PROGRAM

This notecard is used to display edge and line energies of the
elements and to make simple calculations of absorption legth and
attenuation.  When you click on an element in the periodic table,
these data about that element are displayed in the notecard.

If an energy in eV is specified, then the absorption length of the
selected element at the specified energy will also be displayed.  If
the selected element is a gas, the absorption length is given in
centimeters, otherwise it is given in microns.

If a length is also specified in the box marks "thickness", then an
attenuation factor will be given for a pure sample of that length and
at the specified energy.  For example, if you enter 8000 eV as the
energy, and "10" as the thickness then select nickel, the attenuation
will be 0.64.  This means that a 10 micron nickel foil absorbs 36% of
the incident beam.  Again, centimeters are assumed for gases.  With
the thickness set to 10, selecting nitrogen gives an attenuation of
0.91 at that energy.  This means that a 10 centimeter ionization
chamber filled with nitrogen will absorb about 9% of the beam.

Not all of the data is available for all the elements.  When data is
missing, the corresponding space will be left blank.  For transuranic
elements, only the name and atomic number are displayed.

All data used in this program comes from the Elam data resource (see
L<Xray::Absorption> and L<Xray::Absorption::Elam>).  Of all the
available xray absorption data resources, the Elam resource has by far
the most complete collection of edge and line energies.  The edge and
line energies are organized into notecards.  Click on the tabs of the
notecards to see the different pages.  The Siegbahn and IUPAC symbols
for the fluorescence lines are displayed, along with the line energy
and the relative intensity of the line.  The relative intensity is
normlized such that the sum of intensities from lines originating in
the same core state sum to 1.

The weight displayed is the isotope-averaged atomic weight.  The
density is for the most common pure from of the element.  The density
displayed for carbon is the density of graphite.  (Diamond has a
specific gravity of about 3.1.)  The densities of fluorine, and
bromine are their liquid phase densities.

The third button from the left at the bottom of the screen is used to
change the units displayed in the program between eV for energy and
Ansgtroms for wavelength.  Clicking this button will toggle all parts
of the program between these two units.  Please note that the entry
box labeled C<Energy> (or C<Wavelength>) also toggles between the two
units.  When you have the program set to use wavelength, you must
enter wavelength values in that box.  If you enter a value that seems
too small for energy units or too large for wavelength units, the
program will pop open a confirmation dialog.

=head1 THE ANOMALOUS SCATTERING PROGRAM

This notecard contains a simple interface to tables of anomalous
scattering factors.  Simply fill in an energy range and a value for
the energy step and click on an element, and the f prime and double
prime functions will be displayed in the canvas on the right.
Alternatively, you can select an absorption edge and click on an
element, and the anomalous scattering factors will be display 100
volts above and below that edge.  You can even simply click on an
element.  If the element is lighter than cerium, the scattering
factors around the K edge will be shown, other wise the scattering
factors around the L3 edge are shown.

Below the widgets allowing you to specify the energy grid and the edge
are two buttons.  The one labeled C<Save data> allows you to save the
most recent calculation to a file.  By default the filename is
C<fpfpp_XX.dat>, where XX is the symbol of the element for which the
anomalous scattering was calculated.  You can change the name of the
output file in the file dialog.

The C<Clear range> button is a bit more complicated.  Because it is
often useful to calculate the anomalous scattering factors of one
element near the absorption edge of another element, the energy range
is not cleared when you press on a new element button.  Instead, the
energy range used for the prior calculation is used for the new
calculation.  If, for example, you want the calculation made around an
edge of the new element, you should hit the C<Clear range> button or
the C<Clear> button at the bottom of the page.

The button which converts between wavelengths and energies currently
does nothing when the anomalous scattering notecard is displayed.

While you certainly may specify very broad energy ranges, for example
to see K and L edges for an element, do remember that perl is an
interpreted language and that such a request will be rather time
consuming even on a speedy computer.

=head1 TO DO

=over 4

=item *

More kinds of useful data about the elements

=back

=head1 ACKNOWLEDGMENTS

Thanks to Stephane Grenier and Matt Newville for their helpful
sugestions and beta testing.

=head1 AUTHOR

  Bruce Ravel, bruce@phys.washington.edu
  http://feff.phys.washington.edu/~ravel
  copyright (c) 1999 Bruce Ravel

=cut
