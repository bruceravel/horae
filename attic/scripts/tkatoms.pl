#!/usr/bin/perl
######################################################################
## TkAtoms using Atoms version 3.0beta9
##                                copyright (c) 1998,1999 Bruce Ravel
##                                          ravel@phys.washington.edu
##                            http://feff.phys.washington.edu/~ravel/
##
##	  The latest version of Atoms can always be found at
##	    http://feff.phys.washington.edu/~ravel/atoms/
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
## $Id: tkatoms.pl,v 1.24 2001/09/20 17:21:34 bruce Exp $
######################################################################
## This file is the main program for TkAtoms (graphical interface).
##
## This version of atoms is wrapped behind a GUI.  All of the input
## information is entered using various button and text widgets on the
## screen, although it is also capable of loading crystallographic
## data from input files or from a fast, portable database format.
##
## Hopefully, the use of this program is fairly self-explanatory to
## anyone with a knowledge of crystallographic notation.  To aid the
## user, many widgets have help balloons attached.  Let the mouse
## linger for a half a second near certain widgets and an explanatory
## balloon will pop up.
######################################################################
## Code:



### > introduction

BEGIN {
  ##use lib '/usr/local/share/ifeffit/perl';
  ##(($^O eq 'MSWin32') or ($^O eq 'cygwin')) and
  #local $^W = 0;
  use lib $ENV{IFEFFIT_DIR} . "/share/perl";
  use Tk;
  use Xray::Xtal;
  $Xray::Xtal::run_level = 1;
  use Xray::Atoms qw(number);
  use Xray::ATP;
  if (@ARGV and ($ARGV[0] =~ /^-{1,2}v(ersion)?$/)) {
    print &about_tkatoms;
    exit;
  };
  sub about_tkatoms {
    eval '
    local $^W = 0;
    require Xray::Tk::Atoms;
    require Xray::Tk::Absorption;
    require Xray::Tk::Dafs;
    require Xray::Tk::Powder;
    require Xray::Tk::Plotter;
    require Xray::Tk::Config;
    return "
    This is TkAtoms 3.0beta9

    by Bruce Ravel copyright (c) 1999
    ravel\@phys.washington.edu
    http://feff.phys.washington.edu/~ravel/software/atoms/

    using:
      Atoms.pm $Xray::Atoms::module_version
      Xtal.pm $Xray::Xtal::VERSION with space groups database $Xray::Xtal::sg_version
      Absorption.pm $Xray::Absorption::cvs_version
      Tk/Atoms.pm $Xray::Tk::Atoms::VERSION
      Tk/Absorption.pm $Xray::Tk::Absorption::VERSION
      Tk/Dafs.pm $Xray::Tk::Dafs::VERSION
      Tk/Powder.pm $Xray::Tk::Powder::VERSION
      Tk/Plotter.pm $Xray::Tk::Plotter::VERSION
      Tk/Config.pm $Xray::Tk::Config::VERSION

    You are running perl $] and Tk $Tk::VERSION on $^O.
"'
  };
};
##       Tk/Molecule.pm $Xray::Tk::Molecule::VERSION

require 5.004;
use warnings;
use strict;
use constant EPSILON => 0.00001;
#use diagnostics;

use vars qw/$v/;
$v = $Xray::Atoms::VERSION;

use Tk::widgets qw(Table DialogBox LabFrame Balloon ErrorDialog
		   Checkbutton Text Entry Button Optionmenu
		   Radiobutton Scale Bitmap Photo Pod Pod/Text
		   Pod/Search Pod/Tree Menubar More ROText Canvas Config);
### wtf?!?!  PerlApp needs these lines:
use Tk::ErrorDialog;
use Tk::Menubar;

use Xray::Tk::SGB;
use File::Basename qw(dirname basename);
use Cwd;

use vars qw($is_windows $ifeffit_exists $LWP_simple_exists);
$is_windows        = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
$ifeffit_exists    = (eval "require Ifeffit");
## $LWP_simple_exists = (eval "require LWP::Simple");
$LWP_simple_exists = 0;
($is_windows) and ($LWP_simple_exists = 0);
#WINDOWS# $ifeffit_exists    = 1;
#WINDOWS# use Ifeffit;
my $plot_group;

## --------------------------------------------------------------------
## rc file variables
use vars qw(%meta %colors %fonts $titles $labels $help $dialogs $file_dialog
	    $sgb $messages $config);
## use vars qw($always_write_feff $atoms_language $write_to_pwd
## 	    $prefer_feff_eight $absorption_tables $dafs_default
## 	    $plotting_hook $default_filepath $unused_modifier
##             $display_balloons $no_crystal_warnings $one_frame $convolve_dafs
## 	    $never_ask_to_save $ADB_location);

%meta = (ADB_location        => "http://cars9.uchicago.edu/atomsdb/",
	 absorption_tables   => 'elam',
	 always_write_feff   => 0,
	 atoms_language	     => 'english',
	 convolve_dafs	     => 1,
	 dafs_default	     => 'henke',
	 default_filepath    => cwd,
	 display_balloons    => 1,
	 never_ask_to_save   => 0,
	 no_crystal_warnings => 0,
	 one_frame	     => 1,
	 plotting_hook	     => '',
	 prefer_feff_eight   => 0,
	 unused_modifier     => 'Shift',
	 write_to_pwd	     => 1,
	);

%colors = (foreground   => 'black',
	   background   => 'cornsilk3',
	   trough       => 'cornsilk4',
	   entry        => 'ivory2',
	   label        => 'blue3',
	   balloon      => 'coral',
	   button       => 'red4',
	   buttonActive => 'red3',
	   radio        => ($is_windows) ? 'red2' : 'red4',
	   sgbActive    => 'blue3',
	   sgbGroup     => 'darkviolet',
	   todo         => 'seashell',
	   plot         => 'blue',
	  );

%fonts = (balloon => "Arial 10 normal",		# font for text in help ballons
	  label   => "Arial 12 normal",		# font for text labels
	  menu    => "Arial 12 normal",		# font for text labels
	  button  => "Arial 10 bold",		# font for push buttons
	  header  => "Arial 14 bold",		# font for text headers
	  entry   => "Arial 12 normal",		# font for editable fields
	  sgb     => "Arial 12 normal",		# font used in space group browser
	 );


## this sets the name and location of tkatoms.pod
Tk::Pod->Dir($Xray::Atoms::lib_dir);
my $pod_name = 'tkatoms.pod';
if ($is_windows) {
  Tk::Pod->Dir(File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray"));
  $pod_name = 'tkatoms.pod';
};

## read the system rc file then read the user's rc file
use vars qw($xtal_dir $rcfile);
$xtal_dir = ($is_windows) ?
   File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", 'lib') :
   $Xray::Atoms::lib_dir;
$rcfile = ($is_windows) ?
  File::Spec->catfile($xtal_dir, 'tkatoms.ini') :
  File::Spec->catfile($xtal_dir, 'atomsrc');
(-e $rcfile) and &read_rc($rcfile);
my $users_rc = &Xray::Atoms::rcfile_name;
(-e $users_rc) and &read_rc($users_rc);

$meta{absorption_tables} = lc($meta{absorption_tables});
Xray::Absorption -> load($meta{absorption_tables});
($meta{unused_modifier}  =~ /Alt|Control|Meta|Shift/) or
  $meta{unused_modifier} = 'Shift';
$meta{unused_modifier}   = ucfirst($meta{unused_modifier});
($meta{ADB_location}     =~ /\/$/) or $meta{ADB_location} .= '/';


## ($colors or $fonts) and
##   warn "
## As of alpha17 fonts and colors are no longer set in the
## atomsrc file using anonymous hashes.  See
##          $rcfile
## for the new scheme.
##
## ";


## ----------------------------------------------------------------------
## Internationalization:
$meta{atoms_language} = lc($meta{atoms_language});
my $language_file = "";
##   = "tkatomsrc." . $$Xray::Atoms::languages{$meta{atoms_language}};
## $language_file = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
##   File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", "lib", $language_file):
##   File::Spec->catfile($xtal_dir, $language_file);

unless (-e $language_file) {
  $language_file = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
    File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", "lib", "tkatomsrc.en"):
      File::Spec->catfile($xtal_dir, "tkatomsrc.en");
};
eval "do '$language_file'";	# read strings
(lc($meta{atoms_language}) eq 'english') or
  Xray::Xtal::set_language($meta{atoms_language});
## --------------------------------- handle a few specially ---------#
$$help{'mol_core'} = $$help{'core'};                                 #
$$help{'mol_elem'} = $$help{'elem'};                                 #
$$labels{cancel}   = $$file_dialog{-CancelButtonLabel};              #
## ------------------------------------------------------------------#
## ---------------------------warehouse for new text strings --------#
$$labels{plotgif} = 'Save GIF image';
$$labels{plotps}  = 'Save postscript image';
## ------------------------------------------------------------------#

## ----------------------------------------------------------------------
## use vars qw($apt_program);
## ($apt_program = $0) =~ s/tkatoms/apt/;
## ($is_windows) and
##     ($apt_program = File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", "apt.pl"));

## --------------------------------------------------------------------
## various global variables and variables used for the bottom panel
my $nsites = 3;
my $pnsites = $nsites+1;
my $initial_sites = 4;
my ($sites_list, $status);
my %lattice = ();       # hash of space group and lattice constant widgets
my @unique_sites = ();  # list of site widgets
my @occupancy = ();
use vars qw/%atoms_widgets/;
%atoms_widgets = ();

## --------------------------------------------------------------------
## fetch names of all available atp files
## -- atpfiles is the list of all atp files found
## -- atplist is the list for use with atoms
my @atp_dir_list = ();
my %atp_seen = ();
my @found;
use vars qw/@atpfiles @atplist/;
my $atp_direc = ($is_windows) ?
  File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", "atp"):
  $Xray::Atoms::atp_dir;
push @atp_dir_list, $atp_direc;
push @atp_dir_list, Xray::Atoms::rcdirectory;

foreach my $dir (@atp_dir_list) {
  next if ($dir eq '???');
  $dir = File::Spec->canonpath($dir);
  next unless opendir (ATPDIR, $dir);
    ## die "could not open directory $dir for reading$/";
  push @found, grep /\.atp/, readdir ATPDIR;
  closedir ATPDIR;
};
@found = sort( map {if ($_ =~ /(.+)\.atp$/) {$1}} @found );
foreach my $item (@found) {
  push(@atpfiles, $item) unless $atp_seen{$item}++;
};
@atplist = ('feff', 'feff8');
foreach my $a (@atpfiles) {
  next if ($a =~ /^\s*$/);
  next if ($a =~ /absorption|atoms|test/);
  next if ($a =~ /^molec/);
  next if ($a =~ /^template/);
  next if ($a =~ /dafs/);
  unless ($a =~ /^feff8?$/) {
    push @atplist, $a;
  };
};
push @atplist, 'test';

## --------------------------------------------------------------------
## this is a hash of references to functions.  The hash keys are the
## same as the keys to the help and labels array from tkatomsrc.??
## This aids in algorithmic generation of chunks of screen real
## estate.
use vars qw/%function_refs/;
%function_refs = ('quit_tkatoms'    => \&quit_tkatoms,
		  'atoms_validate'  => \&Xray::Tk::Atoms::atoms_validate,
		  'run_atoms'       => \&Xray::Tk::Atoms::run_atoms,
		  'run_absorption'  => \&Xray::Tk::Absorption::run_absorption,
		  'clear_atoms'     => \&Xray::Tk::Atoms::clear_atoms,
		  'clear_site'      => \&clear_site,
		  'clear_lattice'   => \&clear_lattice,
		  'remove'	    => \&remove_site,
		  'add'	            => \&add_one_site,
		 );
## --------------------------------------------------------------------

## need to define the top before setting widget properties
use vars qw/$top/;
$top = MainWindow->new(-class=>'horae');


## --------------------------------------------------------------------
## define widget properties
use vars qw/@button_args @label_args @header_args @entry_args @menu_args
            @sgb_args/;

&set_arg_arrays;
sub set_arg_arrays {
  @button_args = (-foreground       => $colors{entry},
		  -background       => $colors{button},
		  -activeforeground => $colors{entry},
		  -activebackground => $colors{buttonActive},
		  -font             => $fonts{button},);
  @label_args  = (-foreground       => $colors{label},
		  -font             => $fonts{label}, );
  @entry_args  = (-background       => $colors{entry},
		  -font             => $fonts{entry},
		  -insertbackground => $colors{foreground}, );
  @header_args = (-foreground       => $colors{button},
		  -font             => $fonts{header}, );
  @menu_args   = (-foreground       => $colors{label},
		  -activeforeground => $colors{label},
		  -font             => $fonts{menu}, );
};

my @lattice_label_args = (-width=>6, -height=>1, @label_args,);

my @lattice_entry_args  = (-width=>10, @entry_args);

my @sites_label_args = (-width=>17, -height=>1, @label_args,);

my @sites_entry_args = (-width=>5, @entry_args);

sub set_sgb_args {
  @sgb_args = (-sgbActive    => $colors{'sgbActive'},
	       -sgbGroup     => $colors{'sgbGroup'},
	       -button       => $colors{'button'},
	       -buttonActive => $colors{'buttonActive'},
	       -buttonLabel  => $colors{'entry'},
	       -buttonFont   => $fonts{'button'},
	       -sgbFont      => $fonts{'sgb'},
	       -dismiss      => $$labels{'dismiss'},
	       -back         => $$labels{'back'},
	       -restore      => $$labels{'restore'},
	      );
};

use vars qw/@file_menubutton/;
@file_menubutton = (-text=>$$labels{file}, @menu_args,);
use vars qw(@recent_files @recent_registry);
my $recent_menu;
@recent_files = ();
@recent_registry = ();
sub set_file_menu {
  my $menu = $_[0];
  my $this = $menu
    -> command(-label=>$$::labels{'load_input'}, @::menu_args,
	       -command=>\&load_input,
	       -accelerator=>'Control+o', );
  &::manage($this, "menu");
  ($LWP_simple_exists) and do {
    my $sep = $menu -> separator();
    manage($sep, "separator");
    $this = $menu
      -> command(-label=>$$::labels{'load_adb'}, @::menu_args,
		 -command=>\&load_adb, );
    &::manage($this, "menu");
    #$this = $menu
    #  -> command(-label=>$$::labels{'download_adb'}, @::menu_args,
    #		 -command=>\&download_adb, );
    #&::manage($this, "menu");
  };
  my $sep = $menu -> separator();
  manage($sep, "separator");
  $this = $menu
    -> command(-label=>$$::labels{'save_input'}, @::menu_args,
	       -command=>\&save_input,
	       -accelerator=>'Control+s', );
  &::manage($this, "menu");
  unless ($_[1]) {
    $this = $menu
      -> command(-label=>$$::labels{'quit'}, @::menu_args,
		 -command=>\&quit_tkatoms, #sub{exit},
		 -accelerator=>'Control+q', );
    &::manage($this, "menu");
  };
};



## $$dialogs{'no_molecule_data'} = 'You have not read in any molecule data.';
## $$dialogs{'no_absorption'} =
##   'Absorption calculations are unreliable for very low energies.
## They cannot be made for your chosen edge and central atom.';
use vars qw/@pref_menubutton/;
@pref_menubutton =  (-text=>$$labels{pref_menu}, @menu_args,);
sub set_pref_menu {
  my $menu = $_[0];
  my $this = $menu
    -> command(-label=>$$labels{'pref_var'}, @menu_args,
	       -command=>
	       sub{require Xray::Tk::Config;
		   my ($cwin,$cnote) = &Xray::Tk::Config::atoms_config($top);
		   ($^O eq "MSWin32") or $cnote -> raise('variables'); }, );
  &::manage($this, "menu");
  $this = $menu
    -> command(-label=>$$labels{'pref_col'}, @menu_args,
	       -command=>
	       sub{require Xray::Tk::Config;
		   my ($cwin,$cnote) = &Xray::Tk::Config::atoms_config($top);
		   ($^O eq "MSWin32") or $cnote -> raise('colors'); }, );
  &::manage($this, "menu");
  $this = $menu
    -> command(-label=>$$labels{'pref_fon'}, @menu_args,
	       -command=>
	       sub{require Xray::Tk::Config;
		   my ($cwin,$cnote) = &Xray::Tk::Config::atoms_config($top);
		   ($^O eq "MSWin32") or $cnote -> raise('fonts'); }, );
  &::manage($this, "menu");
};

## use vars qw/@apt_args/;
## @apt_args =
##   (-label => "Periodic Table",
##    #-borderwidth => 0,	# hackery to get the words aligned
##    #-relief=>"raised",
##    -command=>
##    sub{ local $^W = 0;
## 	unless (my $return = do $::apt_program) {
## 	  die "couldn't parse $::apt_program: $@" if $@;
## 	  die "couldn't do $::apt_program: $!"    unless defined $return;
## 	  die "couldn't run $::apt_program:"      unless $return;
## 	}},
##    @::menu_args);


use vars qw/@help_menubutton/;
@help_menubutton =  (-text=>$$labels{help_menu}, @menu_args,);
sub set_help_menu {
  my $menu = $_[0];
  my $this = $menu
    -> command(-label=>$$labels{'help_atoms'}, @menu_args,
	       -command=>sub{
		 #if ($^O eq 'MSWin32') {
		 #  my $dialog = $top -> DialogBox(-title=>'Windows warning',
		 #				  -buttons=>['OK'],);
		 #  $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
		 #		  "The on-line help is broken on MS Windows.  Sorry.")
		 #    -> pack(-side=>'left');
		 #  $dialog -> Show;
		 #  return;
		 #};
		 $top->Pod(-file=>$pod_name);}, );
		 ## my $file = $Xray::Atoms::atoms_dir;
		 ## $file = File::Spec->catfile($file,
		 ## 			     'tkatoms_use.pod');
		 ## $top->Pod(-file=>$file);}, );
  push @::all_menus, $this;
  $this = $menu
    -> command(-label=>$$labels{'about_atoms'}, @menu_args,
	       -command=>[\&tkatoms_text_dialog,
			  \$top, &about_tkatoms, 'left']);
  push @::all_menus, $this;
};

use vars qw/@clear_menubutton/;
@clear_menubutton = (-text=>$$labels{clear_menu}, @menu_args,);

use vars qw/@data_menubutton/;
@data_menubutton =  (-text=>$$labels{data_menu}, @menu_args,);


my @balloon_args = (-background=>$colors{balloon},
		    -foreground=>$colors{foreground},
		    -font=>$fonts{balloon},
		    -borderwidth=>0,);
use vars qw/$balloon/;
$balloon = $top -> Balloon(@balloon_args);
&configure_balloons;

my $pod;

my @palette = (background         =>$colors{background},
	       activeBackground   =>$colors{entry},
	       highlightBackground=>$colors{background},
	       selectForeground   =>$colors{foreground},
	       foreground         =>$colors{foreground},
	       highlightForeground=>$colors{foreground},
	       activeForeground   =>$colors{entry},
	       selectColor        =>$colors{entry},
	       activeForeground   =>$colors{foreground},
	       selectBackground   =>$colors{background},
	       highlightColor     =>$colors{button},
	       #disabledForeground =>$colors{disabledforeground},
	       insertBackground   =>$colors{entry},
	       troughColor        =>$colors{trough},);
## --------------------------------------------------------------------

## globals used in the display frame
my ($dump_frame, $dump_frame_text, $dump_frame_buttons, @dump_frames,
    $dump_frame_buttons_run, $dump_frame_buttons_save);
my $dump_count = 1;

## --------------------------------------------------------------------
use vars qw(@all_labels @all_entries @all_buttons @all_radio
            @all_headers @all_menus @all_canvas @all_progress
	    @all_labframes @all_scales @all_check @all_sliders
	    @all_separators);
## --------------------------------------------------------------------

## --------------------------------------------------------------------
## crystallography variables
use vars qw/$cell @sites $keywords @cluster @neutral/;
$cell = Xray::Xtal::Cell -> new();
@sites = ();
$keywords = Xray::Atoms -> new();
@cluster = ();		# spherical cluster
@neutral = ();		# charge neutral rhomboidal cluster
## --------------------------------------------------------------------

## --------------------------------------------------------------------
## now set the rest of the $top properties
$top -> title($$labels{tkatoms_title});
$top -> iconname($$labels{tkatoms_title});
$top -> iconbitmap('@'.File::Spec->catfile($Xray::Atoms::lib_dir, "tkatoms3.xbm"))
  unless $is_windows;

$top -> setPalette(@palette);
$top -> bind('<Control-q>' => \&quit_tkatoms); # sub{exit}
$top -> bind('<Control-l>' => \&load_input); # what about Molecule?
$top -> bind('<Control-o>' => \&load_input); # what about Molecule?
$top -> bind('<Control-s>' => \&save_input);
$top -> bind('<Control-d>' => sub{&display_in_frame($top, '', 0)});
##$top -> bind('<Control-t>' => sub{require Xray::Tk::Sites;
##				  &Xray::Tk::Sites::display_sites($top)});
## my $icon = File::Spec->catfile($xtal_dir, 'tkatoms.xbm');
## $top -> iconbitmap('@'.$icon);
## --------------------------------------------------------------------



### > crystallography panel

######################################################################
#########                                          ###################
#########  Panel containing crystallography data   ###################
#########                                          ###################
######################################################################

my $lower_panel = $top -> Frame(-relief=>'ridge', -borderwidth=>4)
  -> pack(-side=>'bottom', -fill=>'both', -expand=>'y');

my $upper_frame = $lower_panel -> Frame() -> pack(-side=>'top', -expand=>'y');
my $image_frame = $upper_frame -> Frame() -> pack(-side=>'left');

## ------------------------------------------------------------
## ball and stick image
use vars qw($data_dir);
#my $ballnstick_xpm = '';
#while (<DATA>) { $ballnstick_xpm .= $_; };
#my $ballnstick_image = $image_frame -> Pixmap('ballnstick',
#					      -data=>$ballnstick_xpm);

my $ballnstick_file = (($^O eq 'MSWin32') or ($^O eq 'cygwin')) ?
  File::Spec->catfile($ENV{IFEFFIT_DIR}, "share", "perl", "Xray", "tkatoms.gif"):
  File::Spec->catfile($xtal_dir, "tkatoms.gif");
my $ballnstick = $image_frame -> Photo(-file => $ballnstick_file,);
$image_frame -> Label(-image => $ballnstick) -> pack(-padx=>4);
## ------------------------------------------------------------

use vars qw/%atoms_values/;
%atoms_values = ('edge' => '',
		 'titles' => '',
		);


## ------------------------------------------------------------
## area with titles, space group and lattice parameters
my $rest_frame = $upper_frame -> Frame() -> pack(-side=>'left');

## titles
my $titles_frame = $rest_frame -> Frame() -> pack(qw/-padx 4/);
my $titles_label = $titles_frame
  -> Label(-text=>$$labels{title}, @label_args) -> pack(-side=>'left');
$balloon->attach($titles_label, -msg=>$$help{'titles'},);
manage($titles_label, "label");
my $atoms_titles = $titles_frame
  -> Scrolled(qw/Text -relief sunken -borderwidth 2 -width 50
	      -height 4 -scrollbars e -wrap none/,
	      @entry_args)
  -> pack(-side=>'left', -pady=>2);
$atoms_titles->Subwidget("yscrollbar")->configure(-background=>$colors{background});
manage($atoms_titles, "entry");
$atoms_widgets{'title'} = $atoms_titles;

#print $/, join("\n", $atoms_titles -> children()), $/;

##print $/, ($atoms_titles -> children())[1] -> cget('-background'), $/;
($atoms_titles -> children())[1] -> configure(-background=>$colors{background});
manage(($atoms_titles -> children())[1], "slider");
##print $/, ($atoms_titles -> children())[1] -> cget('-background'), $/;

## use Tk::Pretty;
## my $str = Pretty (($atoms_titles -> children())[1]->configure());
## $str =~ s/\],\[/]\n[/g;
## print $/, $str, $/;



## space group and lattice constants
my $lattice_frame = $rest_frame -> Frame(-relief=>'flat',) -> pack();


## space group symbol
my $space_label = $lattice_frame -> Label(-text=>$$labels{space},
					  -width=>12, -height=>1, @label_args,)
  -> grid(-column=>0, -row=>0, -columnspan=>3, -padx=>2);
$balloon->attach($space_label, -msg=>$$help{space},);
manage($space_label, "label");
use vars qw/$space_field/;
$space_field = $lattice_frame -> Entry(@lattice_entry_args,
				       -width=>10,)
  -> grid(-column=>3, -row=>0, -columnspan=>2, -sticky=>'w', -padx=>2);
$lattice{'space'} = $space_field;
manage($space_field, "entry");
my $space_browser;
my $space_button = $lattice_frame
  -> Button(-text=>$$labels{space_browse},
	    @button_args,
	    -command=>sub{ if (Exists($space_browser)) {
			     $space_browser -> raise;
			   } else {
			     &set_sgb_args;
			     $space_browser = $top
			       -> SGB(-SpaceWidget=>\$space_field);
			     $space_browser->configure(@sgb_args, %$sgb,);
			     $space_browser->Show;
			   };
			 } )
  -> grid(-column=>4, -row=>0, -padx=>2, -columnspan=>2);
$balloon->attach($space_button, -msg=>$$help{space_browse},);
manage($space_button, "button");

##    --------------------------- edge
my $edge_label = $lattice_frame ->
  Label(-text=>$$labels{'edge'}, @label_args, )
  ->  grid(-column=>6, -row=>0, -padx=>2);
$balloon->attach($edge_label, -msg=>$$help{'edge'},);
manage($edge_label, "label");
my $edge_button = $lattice_frame
  -> Optionmenu(-textvariable     => \$atoms_values{'edge'},
		-background       => $colors{entry},
		-activeforeground => $colors{label},
		-activebackground => $colors{entry},
		-width=>3, -font=>$fonts{'label'}, -relief=>'groove')
  -> grid(-column=>7, -row=>0, -padx=>2);
manage($edge_button, "menu");
foreach my $e (qw/K L3 L2 L1 none/) {
  my $this = $edge_button -> command(-label => $e, @menu_args,
				     -command=>sub{$atoms_values{'edge'}=$e;});
  manage($this, "menu");
};
## for now only get cascading menus with pTk 800+
if ($Tk::VERSION > 800) {
  my $mcas = $edge_button -> cascade(-label=>'M', -tearoff=>0,
				     -foreground=>$colors{'label'},
				    );
  manage($mcas, "menu");
  foreach my $e (qw/M1 M2 M3 M4 M5/) {
    my $this = $mcas -> command(-label => $e, @menu_args,
				-command=>sub{$atoms_values{'edge'}=$e;});
    manage($this, "menu");
  };
  my $ncas = $edge_button -> cascade(-label=>'N', -tearoff=>0,
				     -foreground=>$colors{'label'}
				    );
  manage($ncas, "menu");
  foreach my $e (qw/N1 N2 N3 N4 N5 N6 N7/) {
    my $this = $ncas -> command(-label => $e, @menu_args,
				-command=>sub{$atoms_values{'edge'}=$e;});
    manage($this, "menu");
  };
  my $ocas = $edge_button -> cascade(-label=>'O', -tearoff=>0,
				     -foreground=>$colors{'label'},
				    );
  manage($ocas, "menu");
  foreach my $e (qw/O1 O2 O3 O4 O5 O6 O7/) {
    my $this = $ocas -> command(-label => $e, @menu_args,
				-command=>sub{$atoms_values{'edge'}=$e;});
    manage($this, "menu");
  };
  my $pcas = $edge_button -> cascade(-label=>'P', -tearoff=>0,
				     -foreground=>$colors{'label'},
				    );
  manage($pcas, "menu");
  foreach my $e (qw/P1 P2 P3/) {
    my $this = $pcas -> command(-label => $e, @menu_args,
				-command=>sub{$atoms_values{'edge'}=$e;});
    manage($this, "menu");
  };
};
$atoms_widgets{'edge'} = $edge_button;


## lattice constant entry fields
my $r_lcf = \$lattice_frame;

$lattice{a}     = &lattice_constant_widget($r_lcf, "a", 1, 1);
$lattice{b}     = &lattice_constant_widget($r_lcf, "b", 2, 1);
$lattice{c}     = &lattice_constant_widget($r_lcf, "c", 3, 1);

$lattice{alpha} = &lattice_constant_widget($r_lcf, "alpha", 1, 2);
$lattice{beta}  = &lattice_constant_widget($r_lcf, "beta" , 2, 2);
$lattice{gamma} = &lattice_constant_widget($r_lcf, "gamma", 3, 2);

sub lattice_constant_widget {
  my($parent, $which, $col, $row) = @_;
  my $label = $$parent -> Label(-text=>$$labels{$which}, @lattice_label_args)
    -> grid(-column=>2*$col, -row=>$row, -padx=>2);
  manage($label, "label");
  my $field = $$parent -> Entry(@lattice_entry_args)
    -> grid(-column=>2*$col+1,   -row=>$row, -padx=>2, -sticky=>'w');
  $balloon->attach($label, -msg=>$$help{$which},);
  manage($field, "entry");
  return $field;
};
## ----------------------------------------------------------------------


## ----------------------------------------------------------------------
## ----- Table of sites -----------------------------------------
use vars qw/@site_entries $core_index/;
@site_entries = ();
$core_index = 0;	# pointer to the currently selected central site
my $sites_frame   = $lower_panel -> Frame(-borderwidth=>2,
					  -relief=>'ridge', )
  -> pack(-padx=>4, -pady=>2);

my $sites_title_frame = $sites_frame -> Frame() ->pack();

my $sites_label = $sites_title_frame -> Label(-text=>$$labels{"unique"},
					      @header_args,
					      -width=>length($$labels{"unique"}))
  -> pack(-side=>'left', -anchor=>'e', -expand=>1);
$balloon -> attach($sites_label, -msg=>$$help{'unique'});
manage($sites_label, "header");

my $nsites_label = $sites_title_frame
  -> Label(-text=>$$labels{"nsites"},
	   @sites_label_args)
  -> pack(-side=>'left');
manage($nsites_label, "label");
my $nsites_field = $sites_title_frame
  -> Label(@sites_label_args, -width=>3,
	   -textvariable=>\$pnsites,)
  -> pack(-side=>'left');
manage($nsites_field, "label");
my $add_site_button = $sites_title_frame
  -> Button(-text => $$labels{"add"},
	    -anchor  => 'se', @button_args,
	    -command => $function_refs{"add"},)
  -> pack(-side=>'right', -padx=>5);
$balloon->attach($add_site_button,
	   -msg=>$$help{'add'},);
manage($add_site_button, "button");

$sites_list = $sites_frame
  -> Table(-fixedrows	 => 1,
	   -fixedcolumns => 1,
	   -rows	 => $initial_sites,
	   -columns	 => 8,
	   -scrollbars	 => 'sw',
	   -borderwidth	 => 0,
	   -background   => $colors{background}
	  )
  -> pack(-anchor=>'center', -fill=>'both', -padx=>4);
#$sites_list->Subwidget("xscrollbar")->configure(-background=>$colors{background});
#$sites_list->Subwidget("yscrollbar")->configure(-background=>$colors{background});
&site_labels($sites_list);
foreach my $i (0..3) {
  $unique_sites[$i] = &site_widget($sites_list, $i);
};


### > program control panels

######################################################################
#########                                          ###################
#########  Control panel for the various programs  ###################
#########                                          ###################
######################################################################


use Tk::NoteBook;

## make the pages of the notebook, one for each program
my ($notebook, $noteframe);
if ($meta{one_frame}) {		# both panels in one frame
  $notebook  =  $top -> NoteBook(-backpagecolor=>$colors{background},
				 -inactivebackground=>$colors{background},);
} else {			# split frame in half (good for low-res)
  $noteframe =  $top -> Toplevel(-class=>'horae');
  $noteframe -> iconbitmap('@'.File::Spec->catfile($Xray::Atoms::lib_dir, "tkatoms3.xbm"))
    unless $is_windows;
  $notebook  =  $noteframe -> NoteBook(-backpagecolor=>$colors{background},
				       -inactivebackground=>$colors{background},);
  $noteframe -> bind('<Control-q>' => \&quit_tkatoms); #sub{exit});
  $noteframe -> bind('<Control-l>' => \&load_input); # what about Molecule?
  $noteframe -> bind('<Control-s>' => \&save_input);
  $noteframe -> bind('<Control-d>' => sub{&display_in_frame($top, '', 0)});
  $noteframe -> title($$labels{tkatoms_title});
  ## $noteframe -> iconname($$labels{tkatoms_title});
  ## $noteframe -> iconbitmap('@'.$icon);
};
## my %fr = ();
require Xray::Tk::Atoms;
($ifeffit_exists) and require Xray::Tk::Plotter;
use vars qw/%pages/;  ## 'Molecule',
foreach my $f0 ('Atoms', 'Absorption', 'Powder', 'DAFS', 'Plotter') {
  next if (($f0 eq 'Plotter') and (not $ifeffit_exists));
  $pages{$f0}  = $notebook -> add(lc($f0), -label=>$f0, -anchor=>'center');
  if ($f0 eq 'Atoms') {
    &Xray::Tk::Atoms::atoms($pages{$f0});
    next;
  #} elsif ($f0 eq 'Molecule') {
  #  $notebook ->
  #    pageconfigure(lc($f0), -createcmd=>sub{require Xray::Tk::Molecule;
  #					     &Xray::Tk::Molecule::molecule});
  #  next;
  } elsif ($f0 eq 'Absorption') {
    $notebook ->
      pageconfigure(lc($f0), -createcmd=>sub{require Xray::Tk::Absorption;
					     &Xray::Tk::Absorption::absorption});
    next;
  } elsif ($f0 eq 'DAFS') {
    $notebook ->
      pageconfigure(lc($f0), -createcmd=>sub{require Xray::Tk::Dafs;
					     &Xray::Tk::Dafs::dafs});
    next;
  } elsif ($f0 eq 'Powder') {
    $notebook ->
      pageconfigure(lc($f0), -createcmd=>sub{require Xray::Tk::Powder;
					     &Xray::Tk::Powder::powder});
    next;
 } elsif ($f0 eq 'Plotter') {
   ($ifeffit_exists) && eval '&Xray::Tk::Plotter::plotter($pages{$f0})';
   next;
  };
};
$notebook->pack(-expand => 'y', -fill => 'both', -side => 'bottom');

#print $INC{'Xray/Tk/Absorption.pm'}, $/;

## --------- About to begin the main loop -----------------------------

my $file;
if (@ARGV) {
 INPUT:{
    $file = $ARGV[0],          last INPUT if (-e  $ARGV[0]);
    $file = $ARGV[0] . ".inp", last INPUT if (-e "$ARGV[0].inp");
    $file = $ARGV[0] . "inp",  last INPUT if (-e "$ARGV[0]inp");
    $file = 0;
  };
};
($file) and load_input($file);

## print join($/,@all_labels, @all_entries, @all_buttons, @all_radio,
##             @all_headers, @all_menus),$/;
## exit;

######################################################################
#########                                   ##########################
                  MainLoop();               ##########################
#########                                   ##########################
######################################################################


######################################################################
#########                             ################################
#########  Miscellaneous subroutines  ################################
#########                             ################################
######################################################################



## ------------------------------------------------------------ ##
##             loading and saving input files                   ##
## ------------------------------------------------------------ ##

sub load_input {
  my $inputfile;
  #local $Tk::FBox::a;
  #local $Tk::FBox::b;
  unless (($_[0] and -e $_[0]) or ($_[0] and $_[0] =~ /^http:/)) {
    my $path = $meta{default_filepath} || cwd();
    my $types = [['input files', '.inp'],
		 ['All Files',   '*'],];
    $inputfile = $top -> getOpenFile(-defaultextension=>'inp',
				     -filetypes=>$types,
				     -initialdir=>$path,
				     #($is_windows) ? () :
				     # (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}),
				     -title => $$labels{'file_dialog'});
    return 0 unless $inputfile;
  } else {
    $inputfile = $_[0];
  };
  ($inputfile =~ /^http:/) or $meta{default_filepath} = dirname($inputfile);
  &Xray::Tk::Atoms::clear_atoms();
  &clear_lattice();
  $keywords -> make(quiet=>1, die=>1);
  $keywords -> parse_input($inputfile, 1);
  foreach my $key (keys %atoms_widgets) {
    next if ($key =~ /_button$/);
  KEYWORDS: {
      ($key eq 'title') && do {
	$atoms_widgets{'title'} -> delete(qw/1.0 end/);
	foreach my $t (@{$keywords->{'title'}}) {
	  $atoms_widgets{'title'} -> insert('end', $t.$/);
	};
	last KEYWORDS;
      };
      ($key eq 'shift') && do {
	foreach my $i (0..2) {
	  $atoms_widgets{'shift'}[$i] -> delete(qw/0 end/);
	  $atoms_widgets{'shift'}[$i] -> insert(0, $keywords->{'shift'}[$i]);
	};
	last KEYWORDS;
      };
      ($key eq 'edge') && do {
	$atoms_values{'edge'} = $keywords->{'edge'};
	last KEYWORDS;
      };
      ($key =~ /argon|krypton|nitrogen/) && do {
	$atoms_widgets{$key} -> set($keywords->{$key});
	last KEYWORDS;
      };
      do {
	$atoms_widgets{$key} -> delete(qw/0 end/);
	$keywords->{$key} and
	  $atoms_widgets{$key} -> insert(0, $keywords->{$key});
	last KEYWORDS;
      };
    };
  };
  foreach my $key (keys %lattice) {
  LATTICE: {
      ($key eq 'space') && do {
	$lattice{$key} -> delete(qw/0 end/);
	$lattice{$key} -> insert(0, $keywords->{$key});
      };
      ($key =~ /^(a|b|c)$/) && do {
	if (abs($keywords->{$key}) > EPSILON) {
	  $lattice{$key} -> delete(qw/0 end/);
	  $lattice{$key} -> insert(0, $keywords->{$key});
	};
	last LATTICE;
      };
      ($key =~ /^(alpha|beta|gamma)$/) && do {
	last LATTICE if (abs($keywords->{$key}-90) < EPSILON);
	last LATTICE if (abs($keywords->{$key})    < EPSILON);
	$lattice{$key} -> delete(qw/0 end/);
	$lattice{$key} -> insert(0, $keywords->{$key});
	last LATTICE;
      };
    };
  };
  my $count = 1;
  $site_entries[0]{'core'} -> select;
  foreach my $s (@{$keywords->{'sites'}}) {
    if ($count == 1) {
      ($keywords->{'core'}) or $keywords->{'core'} = $$s[0] || $$s[4];
    };
    ($count > $pnsites) && &add_one_site;
    $site_entries[$count-1]{'elem'}  -> insert(0,$$s[0]);
    $site_entries[$count-1]{'x'}     -> insert(0,$$s[1]);
    $site_entries[$count-1]{'y'}     -> insert(0,$$s[2]);
    $site_entries[$count-1]{'z'}     -> insert(0,$$s[3]);
    ($$s[4]) &&
      $site_entries[$count-1]{'tag'} -> insert(0,$$s[4]);
    ($$s[5]) &&
      $site_entries[$count-1]{'occ'} -> set($$s[5]);
    if ( (lc($keywords->{"core"}) eq lc($$s[4])) or
	 (lc($keywords->{"core"}) eq lc($$s[0])) ) {
      $site_entries[$count-1]{'core'} -> select;
    };
    ++$count;
  };
  $_[1] or register_recent($inputfile);
};


sub register_recent {
  my $file = $_[0];
  my $name = basename($file);
  ## put this one on the list
  unshift @recent_files, $file;
  ($#recent_files > 8) and pop @recent_files;
  $recent_menu = $top -> Menu(@menu_args, -tearoff=>0,
			      -menuitems=>\@recent_files);
  ## update the list in each of the tabs
  foreach my $r (@recent_registry) {
    $r -> command(-label=>$file, -command=>sub{&load_input($file, 1)});
    #$r -> delete(0, 'end');
    #foreach my $f (@recent_files) {
    #  $r -> command(-label=>$f, -command=>sub{print $f,$/});
    #};
  };
  #print @recent_files, $/;
  #print join($/, @recent_registry), $/;
};

sub load_adb {
  my $adb_box = $top -> Toplevel(-class=>'horae');
  $adb_box -> iconbitmap('@'.File::Spec->catfile($Xray::Atoms::lib_dir, "tkatoms3.xbm"))
    unless $is_windows;
  $adb_box -> title('ADB');
  $adb_box -> iconname('ADB');
  my $frame = $adb_box -> Frame() -> pack(-expand=>1);
  my $label = $frame -> Label(-text=>$$labels{adb_header},
			      @::header_args)
    -> pack();
  &::manage($label, "header");
  $frame = $adb_box -> Frame(-borderwidth=>4, -relief=>'ridge')
    -> pack();
  my $list = $frame
    -> Scrolled('Text', qw/-scrollbars e -height 20 -width 20/)
      -> pack();
  $list->Subwidget("yscrollbar")->configure(-background=>$colors{background});
  my @inps;
  fetch_adb_list(\@inps);
  foreach (@inps) {
    my $b = $list -> Button(-text=>$_, -width=>16, -relief=>'groove',
			    @label_args,
			    -command=>[\&fetch_adb_file, $_, $adb_box]);
    $list -> windowCreate('end', -window=>$b);
    manage($b, "label");
  };
  $frame = $adb_box -> Frame() -> pack(-expand=>1);
  my $button => $frame -> Button(-text=>$$labels{'dismiss'},
				 @button_args,
				 -command=>sub{$adb_box -> destroy})
    -> pack();
  manage($button, "button");
};

sub fetch_adb_file {
  my ($name, $parent) = @_;
  load_input($meta{ADB_location}.$name);
  #$parent -> destroy;
};

sub fetch_adb_list {
  my $r_list = $_[0];
  my %found = ();
  my $list = LWP::Simple::get($meta{ADB_location});
  while ($list =~ /([A-Za-z0-9_-]+\.inp\b)/g) {
    next if ($1 eq 'feff.inp');
    next if $found{$1} ++;
    push @$r_list, $1;
  };
  return $r_list;
};


sub download_adb {
  require Tk::FileSelect;
  my $path = $meta{default_filepath} || cwd();
  my $FSel = $top->FileSelect(-title => $$labels{adb_dldir},
			      -create => 1,
			      -directory => $path,
			      -SelDir => 1,);
			      ##%$file_dialog,);
  my $dir = $FSel->Show(-Horiz => 1);
  (-d $dir) or do {
    require File::Path;
    File::Path::mkpath($dir, 0, 0755);
  };
  my @inps;
  fetch_adb_list(\@inps);
  my $box   = $top -> Toplevel(-class=>'horae');
  my $frame = $box -> Frame() -> pack(-expand=>1);
  my $num   = $#inps + 1;
  my $label = $frame -> Label(-text=>$$labels{adb_dlnum} . " $num",
			      @::header_args)
    -> pack();
  &::manage($label, "header");
  $frame = $box -> Frame() -> pack(-expand=>1);
  my $text = $frame -> Label(-relief=>'flat',
			     -text=>$$labels{adb_dldirname}." \n$dir", @label_args)
    -> pack();
  &::manage($text, "label");
  $text = $frame -> Text(-relief=>'flat', -width=>40, -height=>1)
    -> pack();
  &::manage($text, "entry");
  my $quit = 0;
  my $button => $box -> Button(-text=>$$labels{'quit'},
			       @button_args,
			       -command=>sub{$quit = 1;})
    -> pack();
  manage($button, "button");
  $top->update;
  my $i = 0;
  foreach (@inps) {
    last if ($quit);
    ++$i;
    $text -> delete(qw/1.0 end/);
    $text -> insert('1.0', $$labels{adb_dling}." $i: $_");
    $top  -> update;
    open DL, '>'.$dir.'/'.$_;
    my $file = LWP::Simple::get($meta{ADB_location}.$_);
    print DL $file;
    close DL;
  };
  $box -> destroy;
};

sub save_input {
  $cell -> make( Occupancy=>0 );
  &set_core($core_index);
  &validate_lattice(0);
  &Xray::Tk::Atoms::atoms_validate(0);
  $keywords -> verify_keywords($cell, \@sites, 1);
  my $contents = "";
  $keywords -> make('identity'=>"TkAtoms $v");
  my ($ofname, $is_feff)
    = parse_atp('atoms', $cell, $keywords, \@cluster, \@neutral, \$contents);
  my $path = $meta{default_filepath} || cwd();
  my $types = [['input files', '.inp' ],
	       ['All Files',   '*', ],];
  my $inputfile = $top -> getSaveFile(-defaultextension=>'inp',
				      -filetypes=>$types,
				      #(not $is_windows) ?
				      #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				      -initialdir=>$path,
				      -initialfile=>$ofname,
				      -title => $$labels{'save_dialog'});
  return 0 unless $inputfile;
  $meta{default_filepath} = dirname($inputfile);
  open (INP, ">".$inputfile) or
    die $$Xray::Atoms::messages{cannot_write} . $inputfile . $/;
  print INP $contents;
  close INP;
};


sub quit_tkatoms {
  ## only want to offer the possibility of saving if it need be done.
  ## also want to suppress warning messages.
  ($meta{never_ask_to_save}) and exit;
  $meta{no_crystal_warnings} = 1;
  @sites = ();
  my $cancel = 0;
  my $axis = ($lattice{a}->get or $lattice{b}->get or $lattice{c}->get);
  if (($lattice{space}->get) and ($axis)) { # space group defined?
    &validate_lattice(0);
    (@sites) and do {		# any sites defined?
      my $dialog = $top ->
	DialogBox(-title=>$$labels{'save_data'},
		  -buttons=>[$$labels{'yes'}, $$labels{'no'},$$labels{'cancel'}]);
      $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
		     $$labels{'save_data_message'})
	-> pack(-side=>'left');
      my $button = $dialog -> Show;
      ($button eq $$labels{'yes'}) and &save_input;
      ($button eq $$labels{'cancel'}) and $cancel = 1;
    };
  };
  ($cancel) or exit;
};


### >> site widget subroutines

## ------------------------------------------------------------ ##
##             subroutines for the site widgets                 ##
## ------------------------------------------------------------ ##


## This subroutine returns the frame containing the widgets used to
## define a site.  It also filled the LoH @site_entries with the
## widgets containing the element, coordinates, and tag of the site.
## The list part is an index indicating the site, the hash part is
## words like 'elem', 'x', and so on.
my @valance_values;
sub site_widget {
  my ($parent, $which) = @_;
  my $site_label   = $parent -> Label(-text  => $which+1, @header_args,
				      -font  => $fonts{entry},
				      -width => 2,);
  $parent -> put($which+1, 0, $site_label);
  manage($site_label, "header");
  $site_entries[$which]{'core'} = $parent
    -> Radiobutton(-value       => $which,
		   -selectcolor => $colors{radio},
		   -variable    => \$core_index,
		   -command     => [\&set_core, $which],
		  );
  $parent -> put($which+1, 1, $site_entries[$which]{'core'});
  $balloon->attach($site_entries[$which]{'core'}, -msg=>$$help{'core'},);
  manage($site_entries[$which]{'core'}, "radio");
  my %width = ('elem'=>5, 'x'=>9, 'y'=>9, 'z'=>9, 'tag'=>10);
  my $count = 1;
  foreach my $coord ('elem', 'x', 'y', 'z', 'tag') {
    $site_entries[$which]{$coord}  = $parent
      -> Entry(-width=>$width{$coord},  @entry_args,);
    $parent -> put($which+1, ++$count, $site_entries[$which]{$coord});
    manage($site_entries[$which]{$coord}, "entry");
    if ($coord =~ /^(x|y|z)$/) {
      $site_entries[$which]{$coord} -> insert(0,"0");
    };
    $site_entries[$which]{$coord} ->
      bind("<$meta{unused_modifier}-Key-Right>",
	   [\&site_navigate, \$sites_list, \@site_entries,
	    $which, $coord, 0, 0]);
    $site_entries[$which]{$coord} ->
      bind("<$meta{unused_modifier}-Key-Left>",
	   [\&site_navigate, \$sites_list, \@site_entries,
	    $which, $coord, 1, 0]);
    $site_entries[$which]{$coord} ->
      bind("<$meta{unused_modifier}-Key-Up>",
	   [\&site_navigate, \$sites_list, \@site_entries,
	    $which, $coord, 0, 1]);
    $site_entries[$which]{$coord} ->
      bind("<$meta{unused_modifier}-Key-Down>",
	   [\&site_navigate, \$sites_list, \@site_entries,
	    $which, $coord, 1, 1]);
  };
  $occupancy[$which] = 1.00;
  $site_entries[$which]{'occ'}  = $parent
    -> Scale(-from         => 0,
	     -to           => 1,
	     -orient       => 'horizontal',
	     -resolution   => 0.01,
	     '-length'     => 50,
	     -sliderlength => 15,
	     -showvalue    => 0,
	     -variable     => \$occupancy[$which],
	     -foreground   => $colors{label},);
  $parent -> put($which+1, ++$count, $site_entries[$which]{'occ'});
  ## this Scale one needs to go into some list
  $site_entries[$which]{'occ_label'} = $parent
    -> Label(-width=>4, -textvariable=>\$occupancy[$which],
	     -font=>$fonts{label}, -foreground=>$colors{label},);
  $parent -> put($which+1, ++$count, $site_entries[$which]{'occ_label'});
  manage($site_entries[$which]{'occ_label'}, "label");
  foreach my $b ('clear_site') { # ('clear_site', 'remove') {
    my $button = $parent -> Button(-text=>$$labels{$b}, @button_args,
				   -command=>[$function_refs{$b}, $which]);
    $parent -> put($which+1, ++$count, $button);
    $balloon->attach($button, -msg=>$$help{$b},);
    manage($button, "button");
  };

  # valance
  my $up_bitmap = "#define up_width 14
#define up_height 13
static unsigned char up_bits[] = {
   0xc0, 0x00, 0xc0, 0x00, 0xe0, 0x01, 0xe0, 0x01, 0xf0, 0x03, 0xf0, 0x03,
   0xf8, 0x07, 0xf8, 0x07, 0xfc, 0x0f, 0xfc, 0x0f, 0xfe, 0x1f, 0xfe, 0x1f,
   0x00, 0x00};";
  my $up_img = $parent -> Bitmap('up', -data=>$up_bitmap,
			      -foreground=>$colors{entry});
  my $dn_bitmap = "#define dn_width 14
#define dn_height 13
static unsigned char dn_bits[] = {
   0xfe, 0x1f, 0xfe, 0x1f, 0xfc, 0x0f, 0xfc, 0x0f, 0xf8, 0x07, 0xf8, 0x07,
   0xf0, 0x03, 0xf0, 0x03, 0xe0, 0x01, 0xe0, 0x01, 0xc0, 0x00, 0xc0, 0x00,
   0x00, 0x00};";
  my $dn_img = $parent -> Bitmap('dn', -data=>$dn_bitmap,
			      -foreground=>$colors{entry});
  ##my $up_img = File::Spec->catfile($xtal_dir, 'up.xbm');
  ##my $dn_img = File::Spec->catfile($xtal_dir, 'dn.xbm');
  my $valance_frame = $parent -> Frame(-borderwidth=>2, -relief=>'sunken');
  my $up = $valance_frame -> Button(#-text=>"^",
				    @button_args,
				    -command=>sub{++$valance_values[$which]},
				    -image => $up_img,
				   )
    -> pack(-side=>'left');
  $site_entries[$which]{'Val'}  = $valance_frame
    -> Entry(-width=>2,  @::entry_args, -textvariable=>\$valance_values[$which])
      -> pack(-side=>'left');
  my $dn = $valance_frame -> Button(#-text=>"v",
				    @button_args,
				    -command=>sub{--$valance_values[$which]},
				    -image => $dn_img,
				   )
    -> pack(-side=>'left');
  $parent -> put($which+1, ++$count, $valance_frame);
  $balloon -> attach($up, -msg=>$$::help{valance_up});
  $balloon -> attach($dn, -msg=>$$::help{valance_dn});
  manage($up, "button");
  manage($dn, "button");
  manage($site_entries[$which]{'Val'}, "entry");

  # thermal factors
  $site_entries[$which]{B}  = $parent
    -> Entry(-width=>8,  @::entry_args,);
  $parent -> put($which+1, ++$count, $site_entries[$which]{B});
  manage($site_entries[$which]{B}, "entry");
  #foreach my $l ('Bx', 'By', 'Bz') {
  #  $site_entries[$which]{$l}  = $parent
  #    -> Entry(-width=>8,  @::entry_args,);
  #  $parent -> put($which+1, ++$count, $site_entries[$which]{$l});
  #  manage($site_entries[$which]{$l}, "entry");
  #};

  # color column
  my $fr = $parent -> Frame(-borderwidth=>2, -relief=>'sunken');
  my $site = Xray::Xtal::Site -> new();
  my $this_color = $site->default_color($which);
  $site_entries[$which]{color} =
    $fr -> Label(-text=>'   ',
		 -background=>$this_color,
		 -borderwidth=>1, -relief=>'raised')
    -> pack(-side=>'left', -padx=>2);
  undef $site;
  my $button = $fr ->
    Button(-text=>$$::config{'set'},
	   @::button_args,
	   -command=>sub{1;
	     #$current = ($ce->children())[11] -> get();
	     #$values{$name} = $current;
	     #$color_button{$name} -> configure(-background=>$current);
	   })
      -> pack(-side=>'left');
  manage($button, "button");
  (exists $$help{set_site_color}) and
    $::balloon->attach($button, -msg=>$$help{set_site_color},);
  $parent -> put($which+1, ++$count, $fr); #$site_entries[$which]{$l});

  #file column
  $fr = $parent -> Frame(-borderwidth=>2, -relief=>'sunken');
  my $this_file = "";
  $site_entries[$which]{file} =
    $fr -> Entry(-width=>10,  @::entry_args, -textvariable=>$this_file)
    -> pack(-side=>'left');
  manage($site_entries[$which]{file}, "entry");
  my $current = cwd();
  my $home;
  eval '$home = $ENV{"HOME"} || $ENV{"LOGDIR"} || (getpwuid($<))[7];'
    or $home = "";
  $button = $fr ->
    Button(-text=>$$config{'browse'},
	   @::button_args,
	   -command=>sub{
	     #local $Tk::FBox::a;
	     #local $Tk::FBox::b;
	     my $path = $meta{default_filepath} || cwd();
	     my $types = [['data files', '.dat' ],
			  ['All Files',  '*',  ],];
	     $this_file = $top -> getOpenFile(-filetypes=>$types,
					      -initialdir=>$path,
					      #(not $is_windows) ?
					      #(-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
					      -title => "TkAtoms: " .
					      $$labels{'site_aux_file'});
	     $site_entries[$which]{file} -> delete(0,'end');
	     $site_entries[$which]{file} -> insert(0,$this_file);
	     $site_entries[$which]{file} -> xview(moveto=>1);
	     ($this_file) and $meta{default_filepath} = dirname($this_file);
	     return 0;
	   })
      -> pack(-side=>'left');
  manage($button, "button");
  (exists $$config{browse_help}) and
    $::balloon->attach($button, -msg=>$$config{browse_help},);
  $parent -> put($which+1, ++$count, $fr);
};



## general scheme for moving around a table of the sort use in TkAtoms
## for sites, typically boud to <mod-arrow> where "mod" is defined in
## rcfile.
sub site_navigate {
  shift @_;
  my ($widget, $r_list, $which, $coord, $direction, $dimension) = @_;
  if ($dimension) {
    my %col  = ('elem'=>0, 'x'=>1, 'y'=>2, 'z'=>3, 'tag'=>4);
    my $row = ($direction) ? $which+1 : $which-1;
    my $inc = ($direction) ? 1 : -1;
    ($row < 0)	     and $row = $#{$r_list}; # wrap
    ($row > $#{$r_list}) and $row = 0;
    $$widget -> yview('moveto',($row/($#{$r_list})),'pages');
    $$r_list[$row]{$coord} -> focus();
    $$r_list[$row]{$coord} -> selectionRange(0, 'end');
  } else {
    my %forward  =
      ('elem'=>'x',   'x'=>'y',    'y'=>'z', 'z'=>'tag', 'tag'=>'elem');
    my %backward =
      ('elem'=>'tag', 'x'=>'elem', 'y'=>'x', 'z'=>'y',   'tag'=>'z');
    my $point = ($direction) ? $backward{$coord} : $forward{$coord};
    $$r_list[$which]{$point} -> focus();
    $$r_list[$which]{$point} -> selectionRange(0, 'end');
    return;
  };
};

sub set_core {
  my $which = $_[0];
  my $tag = $site_entries[$which]{'tag'} -> get();
  ($tag =~ /^\s*$/ ) and $tag = $site_entries[$which]{'elem'} -> get();
  $keywords -> make('core'=> $tag);
  $core_index = $which;
};

## This subroutine writes out the column labels at the top of the
## sites list.
sub site_labels {
  my $parent = $_[0];
  #my $frame = $$parent -> Frame() -> pack();
  my @site_label_args = (-foreground=>$colors{"label"},
			 -font=>$fonts{'entry'},);
  my $count = 0;
  my $site_label = $parent -> Label(-width=>2,);
  $parent -> put(0, $count++, $site_label);
  manage($site_label, "label");
  my %width = ('core'=> 4, 'elem'=>5,
	       'x'=>8, 'y'=>8, 'z'=>8, 'tag'=>10, 'occ'=>8,
	       'valence'=>8, 'file'=>12, 'b'=>8, 'bx'=>8, 'by'=>8,
	       'bz'=>8, 'color'=>8);
  foreach my $coord ('core', 'elem', 'x', 'y', 'z', 'tag', 'occ', ' ', ' ',
		     'valence', 'B', 'color', 'file') { # 'Bx', 'By', 'Bz'
    my $field = $parent
      -> Label(-text=>$$labels{$coord}, -width=>$width{$coord}||2,
	       @site_label_args);
    $parent -> put(0, $count++, $field);
    $balloon->attach($field, -msg=>$$help{$coord},);
    manage($field, "label");
  };
};

sub add_one_site {
  ++$nsites; ++$pnsites;
  $unique_sites[$nsites] = &site_widget($sites_list, $nsites);
  #$sites_list -> put($nsites+1, 0, $unique_sites[$nsites]);
};

sub clear_site {
  my $site = $_[0];
  (defined $sites[$site]) and $sites[$site] -> clear;
  ##foreach my $key (keys %{$site_entries[$site]}) {
  foreach my $key (qw/elem x y z tag Val B file/) { # reset color too!
                                                    # Bx By Bz
    $site_entries[$site]{$key} -> delete(qw/0 end/);
    if ($key =~ /^(x|y|z)$/) {
      $site_entries[$site]{$key} -> insert(0,0);
    };
    $site_entries[$site]{'occ'} -> set(1);
  };
};

sub remove_site {print "remove site$/"};


### >> lattice data subroutines

## ------------------------------------------------------------ ##
##             subroutines for lattice data                     ##
## ------------------------------------------------------------ ##


## check the lattice and fill up the Cell and Site data structures.
## If the argument is true, then display an info dialog if the cell is
## ok.  Display warning or error dialogs as problems are found.
sub validate_lattice {
  my $display_ok = $_[0];
  ## read space group, lattice constants and angles
  my $sg = $lattice{space} ->get;
  my $a  = &number($lattice{a}     ->get, 1);
  my $b  = &number($lattice{b}     ->get, 1);
  my $c  = &number($lattice{c}     ->get, 1);
  my $al = &number($lattice{alpha} ->get, 1);
  my $be = &number($lattice{beta}  ->get, 1);
  my $ga = &number($lattice{gamma} ->get, 1);
  if ($sg =~ /^\s*$/) {
    return &tkatoms_dialog(\$top, 'no_space_group', 'warning');
  };
  ## make a cell
  $cell -> make( Space_group=>$sg );
  my ($rg) = $cell -> attributes("Space_group");
  unless ($rg) {
    return &tkatoms_dialog(\$top, 'not_a_group', 'warning');
  };
  $cell -> make( A=>$a, B=>$b, C=>$c, Alpha=>$al, Beta=>$be, Gamma=>$ga );
  ($a, $b, $c, $al, $be, $ga) =
    $cell -> attributes("A", "B", "C", "Alpha", "Beta", "Gamma");
  ## update cell fields
  $lattice{a}     -> delete(qw/0 end/);  $lattice{a}     -> insert(0, $a);
  $lattice{b}     -> delete(qw/0 end/);  $lattice{b}     -> insert(0, $b);
  $lattice{c}     -> delete(qw/0 end/);  $lattice{c}     -> insert(0, $c);
  $lattice{alpha} -> delete(qw/0 end/);  $lattice{alpha} -> insert(0, $al);
  $lattice{beta}  -> delete(qw/0 end/);  $lattice{beta}  -> insert(0, $be);
  $lattice{gamma} -> delete(qw/0 end/);  $lattice{gamma} -> insert(0, $ga);
  ## read unique site widgets and make list of site objects
  my ($i, $is)=(0,0);
  @sites = ();			# refresh sites array
  $keywords -> {'sites'} = ();
  foreach my $s (@site_entries) {
    ++$is;
    my ($e, $x, $y, $z, $t, $o) =
      ($$s{elem}->get,
       &number($$s{'x'}->get, 1),
       &number($$s{'y'}->get, 1),
       &number($$s{'z'}->get, 1),
       $$s{tag}->get,
       &number($$s{occ}->get, 1) );
    my $ee = Chemistry::Elements::get_symbol($e);
    if ($e and not defined($ee)) {
      $top -> messageBox(-icon    => 'error',
			 -message => join("", '"', $e, '" ',
					  $$messages{not_an_element}, " ",
					  $$messages{at_site},
					  " ", $is, $/),
			 -title   => 'Atoms: Error',
			 -type    => 'OK');
      return;
    };
    my ($val, $b, $color, $file) =  ## $bx, $by, $bz,
      (&number($$s{Val}->get, 1),  ## should have some more error checking here
       &number($$s{B} ->get, 1),
       ## &number($$s{Bx}->get, 1),
       ## &number($$s{By}->get, 1),
       ## &number($$s{Bz}->get, 1),
       $$s{color}->cget('-background'),
       $$s{file}->get);
    next unless defined $e;
    next if ($e =~ /^\s*$/);
    $sites[$i] = Xray::Xtal::Site -> new($i);
    $keywords -> make("sites"=> $e, $x, $y, $z, $t, $o);
    #print join("  ", $e, $x, $y, $z, $t, $o, $/);
    $sites[$i] -> make(Element=>$e,
		       X=>$x+$ {$keywords->{"shift"}}[0],
		       Y=>$y+$ {$keywords->{"shift"}}[1],
		       Z=>$z+$ {$keywords->{"shift"}}[2],
		       Occupancy=>$o,
		       Valence=>$val,
		       B=>$b,
		       ## Bx=>$bx, By=>$by, Bz=>$bz,
		       Color=>$color, File=>$file );
    ($t !~ /^\s*$/) && ( $sites[$i] -> make(Tag=>$t) );
    ++$i;
  };
  $cell -> populate(\@sites);
  $cell -> verify_cell();
  my $message = $cell -> warn_shift();
  (($message) and (not $meta{no_crystal_warnings})) and
    &tkatoms_text_dialog(\$top, $message);
  $message = $cell -> cell_check();
  (($message) and (not $meta{no_crystal_warnings})) and
    &tkatoms_text_dialog(\$top, $message);
  ($display_ok) and &tkatoms_dialog(\$top, 'cell_ok', 'info');
  return 0;
};

sub clear_lattice {
  $core_index = 0;
  $keywords = Xray::Atoms -> new();
  $keywords->make('edge' => '');
  $atoms_values{'edge'} = '';
  $atoms_titles -> delete(qw/1.0 end/);
  $cell -> Xray::Xtal::Cell::clear();
  foreach my $x ("space", "a", "b", "c", "alpha", "beta", "gamma") {
    $lattice{$x} -> delete(qw/0 end/);
  };
  foreach my $i (0..$#site_entries) {
    &clear_site($i);
  };
  undef @sites;
  @sites = ();
  $nsites = 3;
  $pnsites = $nsites+1;
  ## it would be nice to remove these lines from the Table, but the
  ## following causes noisy badness
  ##foreach my $i ($pnsites..$#unique_sites) {
  ##  $unique_sites[$i] -> destroy();
  ##};
};




### >> user communication

## ------------------------------------------------------------ ##
##             subroutines for communication with user          ##
## ------------------------------------------------------------ ##

## how do these dialogs need to interact with @all_ lists

## This is a generic "communicate with the user" dialog box
## it displayes a message and has an OK button to continue
##   $parent is the parent widget
##   $which is the help message key from tkatomsrc.??
##   $level is 'info', 'warning', or 'error'
sub tkatoms_dialog {
  my ($parent, $which, $level) = @_;
  my $dlevel = $level . '_title';
  my $dialog = $$parent -> DialogBox(-title=>$$dialogs{$dlevel},
				 -buttons=>[$$labels{ok}],);
  $dialog -> add("Label", -bitmap=>$level, -width=>'1c',
		 -foreground=>$colors{"label"},
		)
    -> pack(-side=>'left');
  $dialog -> add("Label", -text=>$$dialogs{$which},
		 qw/-padx .25c -pady .25c/,
		 -foreground=>$colors{"label"},
		 -font=>$fonts{'label'},
		)
    -> pack(-side=>'left');
  #return $dialog;
  my $ok = $dialog -> Show;
  $top->update;
  return $ok;
};
sub tkatoms_text_dialog {
  my ($parent, $text, $justification) = @_;
  $justification ||= "center";
  my $dialog = $$parent -> DialogBox(-title=>$$dialogs{info_title},
				     -buttons=>[$$labels{ok}],);
  $dialog -> add("Label", -text=>$text,
		 qw/-padx .25c -pady .25c/,
		 -foreground=>$colors{"label"},
		 -font=>$fonts{label},
		 -justify=>$justification,
		)
    -> pack(-side=>'left');
  my $ok = $dialog -> Show;
  $top->update;
  return $ok;
};


## frame for displaying data or output files
sub display_in_frame {
  my ($parent, $which, $atp, $ofname, $feff) = @_;
  if (not Exists $dump_frame) {
    $dump_frame = $parent->Toplevel(-class=>'horae');
    $dump_frame -> bind('<Control-q>' => sub{$dump_frame->destroy});
    $dump_frame -> bind('<Control-d>' => sub{$dump_frame->destroy});
    $dump_frame -> title("TkAtoms ".$$labels{'display'}." $dump_count");
    $dump_frame -> iconname("TkAtoms ".$$labels{'display'}." $dump_count");
    $dump_frame -> iconbitmap('@'.File::Spec->catfile($Xray::Atoms::lib_dir, "tkatoms3.xbm"))
      unless $is_windows;
    $dump_frame_buttons = $dump_frame->Frame;
    $dump_frame_buttons->pack(qw/-side bottom -expand 1 -fill x/);
    my $dump_frame_buttons_dismiss = $dump_frame_buttons
      -> Button(
		-text    => $$labels{'dismiss'}, @button_args,
		-command => [$dump_frame => 'withdraw'],
	       );
    manage($dump_frame_buttons_dismiss, "button");
    $balloon -> attach($dump_frame_buttons_dismiss, -msg=>$$help{dump_dismiss},);
    $dump_frame_buttons_dismiss->pack(qw/-side left -expand 1/);
    $dump_frame_buttons_save = $dump_frame_buttons
      -> Button(
		-text    => $$labels{'save'}, @button_args,
		-command => [\&save_file, \$dump_frame_text, $atp, $ofname],
		-state   => 'disabled',
	       );
    manage($dump_frame_buttons_save, "button");
    $balloon -> attach($dump_frame_buttons_save, -msg=>$$help{dump_save},);
    $dump_frame_buttons_save->pack(qw/-side left -expand 1/);

    my $dump_frame_buttons_preserve = $dump_frame_buttons
      -> Button(-text    => $$labels{'preserve'}, @button_args, );
    $dump_frame_buttons_preserve ->
      configure(-command => sub{push @dump_frames, $dump_frame;
				undef($dump_frame);
				++$dump_count;
				$dump_frame_buttons_preserve->
				  configure(-state=>'disabled');
				$balloon -> detach($dump_frame_buttons_preserve);
			      });

    manage($dump_frame_buttons_preserve, "button");
    $balloon -> attach($dump_frame_buttons_preserve, -msg=>$$help{dump_preserve});
    $dump_frame_buttons_preserve->pack(qw/-side left -expand 1/);

    $dump_frame_buttons_run = $dump_frame_buttons
      -> Button(-text    => $$labels{run_feff}, @button_args,
		-command => [\&tkatoms_text_dialog, \$top,
			     $$labels{no_feff_yet}],
		-state   => 'disabled',
	       );
    $dump_frame_buttons_run->pack(qw/-side left -expand 1/);
    manage($dump_frame_buttons_run, "button");
    $balloon -> attach($dump_frame_buttons_run, -msg=>$$help{dump_run},);
    $dump_frame_text = $dump_frame
      -> Scrolled('Text', qw/-scrollbars se -height 40 -wrap none/);
    $dump_frame_text->pack(qw/-side left -expand 1 -fill both/);
    $dump_frame_text->Subwidget("xscrollbar")->configure(-background=>$colors{background});
    $dump_frame_text->Subwidget("yscrollbar")->configure(-background=>$colors{background});
    #($dump_frame_text -> children())[1]->configure(-background=>$colors{background});
    manage(($dump_frame_text -> children())[1], "slider");
  } else {
    $dump_frame->deiconify;
    $dump_frame->raise;
    $dump_frame_buttons_save -> configure(-state=>'disabled');
    $dump_frame_buttons_run  -> configure(-state=>'disabled');
  };
  $dump_frame_text->configure(qw/-state normal/);
  $dump_frame_text->delete(qw/1.0 end/);
 WHICH: {
    ($which eq '') && do {
      use Data::Dumper;
      $Data::Dumper::Purity = 1;
      $dump_frame_text->
	insert('1.0', Data::Dumper->Dump([$Xray::Atoms::VERSION],
					 [qw(version)]));
      $dump_frame_text->
	insert('end', Data::Dumper->Dump([$cell],     [qw(cell)]));
      $dump_frame_text->
	insert('end', Data::Dumper->Dump([\@sites],   [qw(*sites)]));
      $dump_frame_text->
	insert('end', Data::Dumper->Dump([$keywords], [qw(*keywords)]));
      $dump_frame_text->
	insert('end', Data::Dumper->Dump([\%meta],
					 [qw(*meta)]));
      $dump_frame_text->
	insert('end', Data::Dumper->Dump([$core_index], [qw(core_index)]));
      #$dump_frame_text->
	#insert('end', Data::Dumper->Dump([$Xray::Tk::Atoms::selected_atp],
	#				 [qw(selected_atp)]));
      $dump_frame_buttons_save ->
	configure(-state=>'normal',
		  -command => [\&save_file, \$dump_frame_text, "", ""]
		 );
      last WHICH;
    };
    do {
      $dump_frame_text -> insert('end', $$which);
      $dump_frame_buttons_save ->
	configure(-state=>'normal',
		  -command => [\&save_file, \$dump_frame_text, $atp, $ofname]
		 );
      if ($feff) {$dump_frame_buttons_run -> configure(-state=>'normal');};
      last WHICH;
    };
  };
  $dump_frame_text->markSet(qw/insert 1.0/);
  ($which eq '') && ($dump_frame_text->configure(qw/-state disabled/));
  $top->update;
}; # end display_in_frame


sub save_file {
  my $r_text_widget = $_[0];
  my $atp = $_[1];
  my $ofname = $_[2];
  my $path = $meta{default_filepath} || cwd();
  my $types = [['All Files', '*', ],];
  my $fname = $top -> getSaveFile(-defaultextension=>'inp',
				  -filetypes=>$types,
				  #(not $is_windows) ?
				  #    (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				  -initialdir=>$path,
				  -initialfile=>$ofname,
				  -title => $$labels{'save_dialog'});
  return 0 unless $fname;
  $meta{default_filepath} = dirname($fname);
  open OUT, ">".$fname or die $!;
  print OUT $$r_text_widget->get(qw/1.0 end/);
  close OUT;
};


sub set_gas {
  $keywords->make($_[0]=>$atoms_widgets{$_[0]}->get);
};


sub configure_balloons {
  if ($meta{display_balloons}) {
    $balloon -> configure(-state=>'balloon', -initwait=>500);
  } else {
    $balloon -> configure(-state=>'none');
  };
};

sub set_variables {
  my $r_hash = $_[0];
  foreach my $vvv (qw(always_write_feff atoms_language write_to_pwd
		      prefer_feff_eight absorption_tables dafs_default
		      plotting_hook default_filepath unused_modifier
                      display_balloons no_crystal_warnings one_frame
		      ADB_location)) {
    eval "\$meta{$vvv} = \$\$r_hash{$vvv};";
  };
  &configure_balloons;
  #print STDOUT join($/, $always_write_feff, $atoms_language,
		    #$write_to_pwd, $prefer_feff_eight,
		    #$absorption_tables, $dafs_default,
		    #$plotting_hook,     $default_filepath,
		    #$unused_modifier, $/);
};


sub read_rc {
  open RC, $_[0] or die "could not open $_[0] as a configuration file\n";
  my $mode = "";
  while (<RC>) {
    next if (/^\s*$/);
    next if (/^\s*\#/);
    #warn ("old style rc file, line $.!\n"), next if (/^\s*\$/);
    if (/\[(\w+)\]/) {
      $mode = lc($1);
      next;
    };
    chomp;
    s/^\s+//;
    unless ($_ =~ /\$c_/) {s/\s*\#.*$//;};
    my @line = split(/[ \t]*[ \t=][ \t]*/, $_);
    (defined $line[1]) and
      (($line[1] eq "''") or ($line[1] eq '""'))
	and $line[1] = '';
  MODE: {
      ($line[0] =~ /^\s*\$([a-zA-Z_]+)/) and do {
	my $var = $1;
	$line[1] =~ s/[;\'\"]//g;
	if ($var =~ /^c_/) {	# colors
	  my $v = substr($var, 2);
	  $colors{$v} = $line[1];
	  if (($colors{$v} =~ /^[0-9a-fA-F]{6}$/) or
	      ($colors{$v} =~ /^[0-9a-fA-F]{12}$/)) {
	    $colors{$v} = '#'.$line[1];
	  };
	  #print $var, "  ", $colors{$v}, $/;
	} elsif ($var =~ /^f_/) { # fonts
	  my $v = substr($var, 2);
	  $fonts{$v} = join(" ", @line[1..$#line]);
	  $fonts{$v} =~ s/[;\'\"]//g;
	  #print $var, "  ", $fonts{$v}, $/;
	} else {		# meta
	  $meta{$var} = $line[1];
	  #print $var, "  ", $meta{$var}, $/;
	};
	last MODE;
      };
      ($mode eq 'meta') and do {
	$meta{$line[0]} = $line[1];
	last MODE;
      };
      ($mode eq 'colors') and do {
	$colors{$line[0]} = $line[1];
	(($colors{$line[0]} =~ /[0-9a-fA-F]{6}/) or
	 ($colors{$line[0]} =~ /[0-9a-fA-F]{12}/)) and
	   $colors{$line[0]} = '#'.$line[1];
	last MODE;
      };
      ($mode eq 'fonts') and do {
	$fonts{$line[0]} = join(" ", @line[1..$#line]);
	last MODE;
      };
    };
  };
};

## As widgets are created, push them onto lists for use with the color
## and font configurator.
sub manage {
  my ($widget, $type) = @_;
 SWITCH: {
    ($type eq 'label') and do {
      push @all_labels, $widget;
      last SWITCH;
    };
    ($type eq 'entry') and do {
      push @all_entries, $widget;
      last SWITCH;
    };
    ($type eq 'button') and do {
      push @all_buttons, $widget;
      last SWITCH;
    };
    ($type eq 'radio') and do {
      push @all_radio, $widget;
      last SWITCH;
    };
    ($type eq 'header') and do {
      push @all_headers, $widget;
      last SWITCH;
    };
    ($type eq 'menu') and do {
      push @all_menus, $widget;
      last SWITCH;
    };
    ($type eq 'canvas') and do {
      push @all_canvas, $widget;
      last SWITCH;
    };
    ($type eq 'progress') and do {
      push @all_progress, $widget;
      last SWITCH;
    };
    ($type eq 'labframe') and do {
      push @all_labframes, $widget;
      last SWITCH;
    };
    ($type eq 'scale') and do {
      push @all_scales, $widget;
      last SWITCH;
    };
    ($type eq 'check') and do {
      push @all_check, $widget;
      last SWITCH;
    };
    ($type eq 'slider') and do {
      push @all_sliders, $widget;
      last SWITCH;
    };
    ($type eq 'separator') and do {
      push @all_separators, $widget;
      last SWITCH;
    };
    warn "unknown widget type: $type\n";
  };
};

1;
