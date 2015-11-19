## -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006, 2008 Bruce Ravel
##

BEGIN {
  ##   ## make sure the pgplot environment is sane...
  ##   ## these defaults assume that the pgplot rpm was installed
  ##   $ENV{PGPLOT_DIR} ||= '/usr/local/share/pgplot';
  ##   $ENV{PGPLOT_DEV} ||= '/XSERVE';

  use Tk;
  die "Artemis requires Tk version 800.022 or later\n"  if ($Tk::VERSION < 800.022);
  #require Ifeffit;
  #die "Artemis requires Ifeffit.pm version 1.2 or later\n" if ($Ifeffit::VERSION < 1.2);
  #import Ifeffit qw/ifeffit/;
  use Ifeffit qw(ifeffit get_array put_array);
  ifeffit("\&screen_echo = 0\n");
};

use strict;
## use diagnostics;

## The next line is not necessary when artemis is run as an
## interpretted script but PAR needs some help knowing which Tk
## modules to load.
use Tk::widgets qw(Wm Derived Frame NoteBook Tree Bitmap Button Optionmenu Dialog
                   DialogBox TextUndo TextUndoQuiet ROText
                   Checkbutton Entry Label Radiobutton Scrollbar Canvas HList
		   Pixmap ItemStyle Splashscreen Photo waitVariableX
		   PathparamEntry Pane NumEntry NumEntryPlain FireButton
		   LabFrame Pod Pod/Text Pod/Search Pod/Tree More Listbox
		   FileSelect Menu BrowseEntry);
### wtf?!?!  PerlApp needs this line:
use Tk::DirTree;
use Tk::Pod;
use Tk::TextUndo;
use Tk::TextUndoQuiet;
##use Tk::bindDump;
use Ifeffit::Path;
use Ifeffit::Parameter;
use Ifeffit::ArtemisLog;
use Ifeffit::Files;
use Ifeffit::ParseFeff;
##my $absorption_exists = (eval "require Xray::Absorption");
use Xray::Absorption;
use Cwd;
use File::Basename;
use File::Copy;
use File::Path;
use File::Compare;
use Chemistry::Elements qw(get_symbol get_name get_Z);
use Compress::Zlib;
use Math::Round qw(round);
use Text::Wrap;
$Text::Wrap::columns = 65;
use Text::ParseWords;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Safe;
use Fcntl;
use Config::IniFiles;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Xray::Xtal;
$Xray::Xtal::run_level = 3;
use Xray::Atoms qw(build_cluster rcfile_name);
use Xray::ATP; # qw(parse_atp);
use Xray::Tk::SGB;
my $STAR_Parser_exists = (eval "require STAR::Parser");
if ($STAR_Parser_exists) {
  import STAR::Parser;
};
use constant PI => 3.14159265358979323844;
use constant THIRD => 1/3;
use constant TWOTH => 2/3;
use constant EPSILON => 0.00001;
use constant DELTA => 0.001;


my $VERSION = "0.8.013";
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
my $mouse_over_cursor = 'mouse';

my $vstr = Ifeffit::Tools->vstr;
if ($vstr < 1.02005) {
  my $mw = MainWindow->new();
  $mw -> withdraw();
  my $message = "This version of Artemis requires Ifeffit 1.2.5 or later.

You can get the latest Ifeffit from http://cars.uchicago.edu/ifeffit.

If you have recently upgraded Ifeffit, you should also rebuild Athena and Artemis.
";
  my $dialog =
    $mw -> Dialog(-bitmap         => 'error',
		  -text           => $message,
		  -title          => 'Artemis: Exiting...',
		  -buttons        => [qw/OK/],
		  -default_button => 'OK',
		  -font           => ($is_windows) ? "Helvetica 8 normal" : "Helvetica 12 normal",
		  -popover        => 'cursor');
  my $response = $dialog->Show();
  exit;
};


unless (($VERSION eq $Ifeffit::Path::VERSION)       and
	($VERSION eq $Ifeffit::Parameter::VERSION)  and
	($VERSION eq $Ifeffit::ArtemisLog::VERSION))    {
  my $mw = MainWindow->new();
  $mw -> withdraw();
  my $message = "Artemis appears to be installed incorrectly.

The main program and one or more of the Ifeffit/Path.pm,
Ifeffit/Parameter.pm, and Ifeffit/ArtemisLog.pm
modules have different version numbers.

main program:  $0
Path.pm:       $INC{'Ifeffit/Path.pm'}
Parameter.pm:  $INC{'Ifeffit/Parameter.pm'}
ArtemisLog.pm: $INC{'Ifeffit/ArtemisLog.pm'}
";
  my $dialog =
    $mw -> Dialog(-bitmap         => 'error',
		  -text           => $message,
		  -title          => 'Artemis: Exiting...',
		  -buttons        => [qw/OK/],
		  -default_button => 'OK',
		  -font           => ($is_windows) ? "Helvetica 8 normal" : "Helvetica 12 normal",
		  -popover        => 'cursor');
  my $response = $dialog->Show();
  exit;
};
my $About = "Artemis $VERSION (c) 2002-2008 Bruce Ravel <bravel\@anl.gov> -- NO WARRANTY -- see license for details";
my $About_Ifeffit = "Using Ifeffit ".Ifeffit::get_string("\$&build");
$About_Ifeffit =~ s{\s+}{ }g;
## family????
my $setup = Ifeffit::Path -> new(type=>'data');

## ============================================================================
## ============================================================================
## Define are some global variables
use vars qw(%notecard %notes %labels %props);
my $is_osx     = ($^O eq 'darwin');
my ($n_gsd, $n_feff, $n_data) = (0, 0, 0);
##  my (@gsd_choice, @gsd_name, @gsd_name_widget, @gsd_mathexp,
##      @gsd_button, @gsd_updated);
my @gds_regex = ();
my @gds = ();
my @bad_params = ();
my %gds_styles = ();
my %gds_selected = (which=>0, name=>"", mathexp=>"", type=>"", showing=>"edit");
my %intrp_styles = ();
my @atoms = ();
my %atoms_styles = ();
my $current_data_dir = '';
my $current = '';
my $current_file = '';
my $project_name = '';
my $project_folder = '';
my $project_saved = 1;
my $autosave_filename = "";
my $parameters_changed = 0;
my @athena_fh = ();
my ($sgb, $fefftabs, %feffcard);
my @done = (" done!", 1);
##my @echo_history = ();
my @rename_buffer;
my $generic_name = "artemis.stuff";
my $last_plot = '';
my %fit = (index=>1, count=>0, count_full=>0, new=>1, label=>"", comment=>"", fom=>0);

## (stack, start, offset, invert, indicator, indicators...)
my @extra = (0,0,0,0,0, "");

my (%paths, %widgets, %grab, $list, %atoms_params, %log_params, %ath_params); #, %apa_params);

## this regex matches the Ifeffit::Path object types that are not plotted
my $no_plot_regex = '(feff\d+|gsd|journal)';
  ## all the functions in ifeffit
  ##   (insert (make-regexp '("abs" "min" "max" "sign" "sqrt" "exp" "log"
  ## 		       "ln" "log10" "sin" "cos" "tan" "asin" "acos"
  ## 		       "atan" "sinh" "tanh" "coth" "gamma" "loggamma"
  ## 		       "erf" "erfc" "gauss" "loren" "pvoight" "debye"
  ## 		       "eins" "npts" "ceil" "floor" "vsum" "vprod"
  ## 		       "indarr" "ones" "zeros" "range" "deriv" "penalty"
  ##		       "smooth" "interp" "qinterp" "splint" "eins" "debye")))
my $function_regex = "a(bs|cos|sin|tan)|c(eil|o(s|th))|" .
  "de(bye|riv)|e(ins|rfc?|xp)|floor|ga(mma|uss)|" .
  "in(darr|terp)|l(n|o(g(|10|gamma)|ren))|m(ax|in)|" .
  "npts|ones|p(enalty|voight)|qinterp|r(ange|ebin)|" .
  "s(i(gn|nh?)|mooth|plint|qrt)|" .
  "tanh?|v(prod|sum)|zeros";


my %limits = (			# Ifeffit's limits on things
	      paths_per_set  => Ifeffit::get_scalar('&max_paths') || 100,
	      total_paths    => Ifeffit::get_scalar('&max_paths') || 100,
	      variables      => Ifeffit::get_scalar('&max_varys') || 128,
	      spline_knots   => 32,
	      data_sets      => Ifeffit::get_scalar('&max_data_sets') || 16,
	      output_columns => Ifeffit::get_scalar('&max_output_cols') || 16,
	      );
--$limits{output_columns}; ## one less than its actual value since
                           ## the first column will always be the abscissa

my $dmode = 5;
## ==== DEBUG =====
## $dmode += 16;
## ==== DEBUG =====
my $debug_menu = 0;
my $debug_file_path = 0;

use vars qw($top);
$top = MainWindow->new(-class=>'horae');
$top -> withdraw;
$top -> optionAdd('*font', 'Helvetica 14 bold');
$top -> optionAdd('*font', 'Helvetica 9 bold');
my $splash_background = 'antiquewhite3';
my $splash = $top->Splashscreen();
my $splash_image = $top -> Photo(-file => $setup -> find('artemis', 'logo'));
$splash -> Label(-image=>$splash_image, -background => $splash_background)
  -> pack(qw/-fill both -expand 1 -padx 0 -pady 0 -side left/);
my $splash_frame = $splash -> Frame(-background => $splash_background,)
  -> pack(qw/-fill both -expand 1 -padx 0 -pady 0 -side right/);
$splash_frame -> Label(-text       => "Artemis\nversion $VERSION",
		       -background => $splash_background,
		       -width      => 22,
		       -font       => 'Helvetica 14 bold',)
  -> pack(qw/-fill both -expand 1/);
my $splash_status =   $splash_frame -> Label(-text       => q{},
					     -background => $splash_background,
					     -font       => 'Helvetica 9 bold',
					     -justify    => 'left',
					     -borderwidth=> 2,
					     -relief     => 'ridge')
  -> pack(-anchor=>'w', -fill=>'x');
$splash -> Splash;
$top -> update;



## ---------------------------------------------------------------------
## add document location to the Pod path
Tk::Pod->Dir($setup -> find('artemis', 'doc'));

## ============================================================================
## ============================================================================
## read configuration files:
splash_message("Importing configuration files");

## check to see if config and mru files from 0.6.001 or earlier are
## around and convert to new location.
&convert_config_files;

my (%plot_features, $screen, @clist, %header, @op_text);
my $dummy_rcfile     = $setup -> find('artemis', 'rc_dummy');
open I, ">".$dummy_rcfile; print I "[meta]\ndummy_parameter=1\n"; close I;
my $system_rcfile    = $setup -> find('artemis', 'rc_sys');
my $personal_rcfile  = $setup -> find('artemis', 'rc_personal');
my $personal_version = $setup -> find('artemis', 'version_marker');

## config values hardwired in the code
my %default_config;
tie %default_config, 'Config::IniFiles', ();
($screen, @clist) = &default_rc(\%default_config); # set defaults
my $default_config_ref = tied %default_config;
$default_config_ref -> SetFileName($dummy_rcfile);

## system-wide rc file (but check to see that it exists...
my %system_config;
tie %system_config, 'Config::IniFiles', (-file=>$system_rcfile, -import=>$default_config_ref)
  if -e $system_rcfile;;

## if the user does not have a personal rc file, create one
if ((! -e $personal_rcfile) or (-z $personal_rcfile)) {
  open I, ">".$personal_rcfile;
  print I "[meta]\ndummy_parameter=1\n";
  close I;
}
## if the user does not have a personal rc file, create one
if (! -e $personal_version) {
  open V, ">".$personal_version;
  print V "";
  close V;
  open I, ">".$personal_rcfile;
  print I "[general]\ndummy_parameter=1\n";
  close I;
};
my %config;
if (-e $system_rcfile) {	# import system-wide file if it exists
  my $system_config_ref = tied %system_config;
  $system_config_ref -> WriteConfig($dummy_rcfile);
  tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$system_config_ref );
  unless (tied %config) {	# crude hack to deal with improper rcfile
    open I, ">".$personal_rcfile;
    print I "[meta]\ndummy_parameter=1\n";
    close I;
    tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$system_config_ref );
  };
} else {			# else import the default
  tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$default_config_ref);
  unless (tied %config) {
    open I, ">".$personal_rcfile;
    print I "[meta]\ndummy_parameter=1\n";
    close I;
    tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$default_config_ref );
  };
};
delete $config{general}{dummy_parameter};
my $config_ref = tied %config;
$config_ref -> WriteConfig($personal_rcfile);
unlink $dummy_rcfile;


foreach my $fonttype (keys %{ $config{fonts} }) {
  $top -> optionAdd('*font', $config{fonts}{$fonttype});
};
$top -> optionAdd('*font', $config{fonts}{med});


## ---------------------------------------------------------------------
## several things that need to be set now that the config file has
## been read
if ($is_windows) {
  ($config{colors}{check} = 'red2') if ($config{colors}{check} eq 'red4');
};
## this fixes a scalar name collision in ifeffit introduced along with
## the reading of Athena projects and the performing of splines in
## Artemis.
($config{autoparams}{e0} = 'enot') if ($config{autoparams}{e0} eq 'e0');
($config{autoparams}{e0} = 'delr') if ($config{autoparams}{delr} eq 'dr');

map { $plot_features{$_} = $config{plot}{$_}} (keys %{$config{plot}});
$plot_features{rmax_out} = $config{plot}{rmax_out} || 10;
$plot_features{bkg} = 0;
$plot_features{res} = 0;
Ifeffit::put_scalar('&plot_key_x',  $config{plot}{key_x});
Ifeffit::put_scalar('&plot_key_y0', $config{plot}{'key_y'});
Ifeffit::put_scalar('&plot_key_dy', $config{plot}{key_dy});
## $config{general}{workspace} =~ s/\~/$ENV{HOME}/;


##$config{general}{query_save} = 0;

## choose the absorption tables for Atoms
##($absorption_exists) and eval "Xray::Absorption -> load($config{atoms}{absorption_tables})";
Xray::Absorption -> load($config{atoms}{absorption_tables});

## default log type
my @log_type = set_log_style($config{log}{style});

splash_message("Making stash directory");
## establish stash directory
&Ifeffit::Tools::initialize_horae_space;
## my $stash_dir = $config{general}{workspace} || $Ifeffit::Tools::horae_stash_dir;
my $stash_dir = $Ifeffit::Tools::horae_stash_dir;

my $trapfile = File::Spec->catfile($stash_dir, "ARTEMIS.TRAP");
## ---------------------------------------------------------------------

## ============================================================================
## ============================================================================
## open and read most recently used (MRU) file
splash_message("Importing recent files list");
my $mrufile = $setup -> find('artemis', 'mru');
# touch an empty file if needed
unless (-e $mrufile) {open M, ">".$mrufile; print M "[mru]\n"; close M};
my %mru;
tie %mru, 'Config::IniFiles', ( -file => $mrufile );
foreach my $i (1 .. $config{general}{mru_limit}) {
  exists $mru{mru}{$i} or ($mru{mru}{$i} = "");
};

$current_data_dir = $mru{config}{last_working_directory}
  if ($config{general}{remember_cwd});

## ============================================================================
splash_message("Setting up context help and hints");
## ============================================================================
## click help text strings
my %click_help =
  (## guess, set, def
   'Param. name'			     => "The names of fixed and varied parameters for use in math expressions",
   'Math expression'			     => "Math expressions used to evaluate path parameters, establish constraints, and build fitting models",
   'Grab best fit'			     => "Click on these buttons to insert the best fit values after a fit is finished",
   ## operational parameters
   'Titles'				     => "User-supplied, editable commentary about these data",
   'Data file'				     => "Name of the project data file containing these chi(k) data.",
   'k-range'				     => "The range of the fit or the Fourier transform in k space (this should cover the range of reliable data)",
   'Data controls'			     => "Variables which control how these data are used in the fit.  The include and plot buttons are only relevant to a multiple data set fit.",
   'Fit k-weights'			     => "Weighting factor for chi(k) used in the fit for these data.  (You may fit using 1 or more k-weightings.)",
   'Fourier and fit parameters'		     => "Parameters which determine how the Fourier transforms are made and the range over which the fit is made.",
   'Other parameters'			     => "Other parameters controlling details of the fit to these data.",
   'dk'					     => "Width of the Fourier transform window sill in k space (this is typicaly a one to a few inverse Angstroms)",
   'k window'				     => "Functional form of the Fourier transform window in k space",
   'R-range'				     => "The range of the fit or the Fourier transform in R space (this should cover the peaks you wish to include in your fit)",
   'dr'					     => "Width of the Fourier transform window sill in R space (typical values are between 0 to 1)",
   'R window'				     => "Functional form of the Fourier transform window in R space",
   'Fitting space'			     => "Data space in which to perform the minimization (the authors of Ifeffit and Artemis prefer R space)",
   'Path to use for phase corrections'	     => "Correct Fourier transforms by the full phase shift of the chosen path",
   'Phase corrected Fourier transforms'	     => "Correct Fourier transforms by the phase shift of the central atom",
   'elem'				     => 'The element of the absorber, needed for phase correctioned FTs',
   'edge'				     => 'The absorbtion edge of these data, needed for phase correctioned FTs',
   'Epsilon'				     => "Explicitly specify the measurement uncertainty (in k)   (useful for weighting components of a multi-data set fit)",
   'Minimum reported correlation'	     => "Smallest value of correlation between variables to report once the fit is finished (0.25 to 0.5 are sensible)",
   ## Feff calculation
   'Interpretation of the FEFF calculation'  => "A schematic representation of the paths from a FEFF run (try right-clicking in different places in the box)",
   'Core'				     => "Use these buttons to select the central atom",
   'El.'				     => "Specify the two-letter atomic symbols of each atom in this column (leave the element blank to skip this site)",
   "X"					     => "Specify the x-axis coordinate of each atom in this column",
   "Y"					     => "Specify the y-axis coordinate of each atom in this column",
   "Z"					     => "Specify the z-axis coordinate of each atom in this column",
   "Tag"				     => "Specify a site-specific tag for each atom in this column",
   "Occ."				     => "Set the occupancy of each site between 0 and 100% (not used in the feff.inp atom list!!)",
   "Cluster size"			     => "Enter the radial extent of the cluster of atoms to write to the feff.inp file",
   "Shift vector"			     => "Insert the shift vector values here if this is a space group that needs one",
   "Space group"			     => "Enter the symbol of your space group (Hermann-Maguin, Schoenflies, and index number are all ok)",
   "Edge"				     => "Select the absorption edge to be used in the Feff calculation",
   "A"					     => "Enter the a lattice constant of the unit cell",
   "B"					     => "Enter the a lattice constant of the unit cell",
   "C"					     => "Enter the a lattice constant of the unit cell",
   "Alpha"				     => "Enter the alpha angle of the unit cell (alpha is the angle between b and c)",
   "Beta"				     => "Enter the beta angle of the unit cell (beta is the angle between a and c)",
   "Gamma"				     => "Enter the gamma angle of the unit cell (gamma is the angle between a and b)",
   ## paths
   'FEFF calculation'			     => "The Feff calculation that this path is a part of",
   'feff:'				     => "The path and name of the feffNNNN.dat file",
   'label:'				     => "User-defined text used to describe this path",
   'N:'					     => "The degeneracy of this path (this must be a number and cannot be a variable)",
   'S02:'				     => "A math expression describing all amplitude terms other than degeneracy for this path",
   'E0:'				     => "A math expression defining the energy shift for this path",
   'delE0:'				     => "A math expression defining the energy shift for this path",
   'delR:'				     => "A math expression defining the change in path length relative to R_effective for this path",
   'sigma^2:'				     => "A math expression defining the relative mean square displacement about R_effective for this path",
   'Ei:'				     => "A math expression for the additional broadening this path, in eV",
   '3rd:'				     => "A math expression defining the third cumulant for this path",
   '4th:'				     => "A math expression defining the fourth cumulant for this path",
   'dphase:'				     => "An math expression defining a constant phase offset (useful for DAFS data)",
   'k_array:'				     => "An array modifying the k-axis of this path (use with care!)",
   'phase_array:'			     => "An array-valued math expression for an additional phase shift (use with care!)",
   'amp_array:'				     => "An array-valued math expression for an amplitude correction (use with care!)",
   ## histogram
   'Path list entry'			     => "The text template for the list entries of each bin the histogram",
   'Position column'			     => "The text column containing the bin positions.",
   'Height column'			     => "The text column containing the bin heights.",

   'null'				     => "???",
  );
$click_help{'Path to FEFF:'} = $click_help{'Path to FEFF calculation'};

## ============================================================================
## ============================================================================
## command completion in the ifeffit buffer
use Text::Abbrev;
my %abbrevs = abbrev qw(chi_noise color comment cursor def echo erase
			exit feffit ff2chi fftf fftr findee guess
			history load macro minimize newplot path pause
			plot pre_edge print quit read_data rename
			reset restore save set show spline sync
			write_data zoom @all @arrays @commands @group
			@macros @path @scalars @strings @variables );


## ============================================================================
## ============================================================================
## read hints file and initialize hints
my $hint_file = $setup -> find('artemis', 'hints');
my @hints = ();
my ($hint_n, $hint_x);
if (-e $hint_file) {
  open HINT, $hint_file or die "could not open hint file $hint_file for reading\n";
  while (<HINT>) {
    next if (/^\s*($|\#)/);
    chomp;
    push @hints, $_;
  };
  srand;
  $hint_x = $#hints;
  $hint_n = int(rand $hint_x);
  close HINT;
};


## ============================================================================
## ============================================================================
## begin drawing main window, initialize splash screen, and establish
## key bindings
$top -> setPalette(foreground	       => $config{colors}{foreground},
		   background	       => $config{colors}{background},
		   activeBackground    => $config{colors}{activebackground},
		   disabledForeground  => $config{colors}{disabledforeground},
		   disabledBackground  => $config{colors}{background},
		   highlightColor      => $config{colors}{button},
		   -highlightthickness => 2,
		   -font               => $config{fonts}{med},
		  );
$top -> protocol(WM_DELETE_WINDOW => \&quit_artemis);
$top -> title('Artemis');
$top -> iconname('Artemis');
#my $iconbitmap = $setup -> find('artemis', 'xbm');
#$top -> iconbitmap('@'.$iconbitmap);
my $iconimage = $top -> Photo(-file => $setup -> find('artemis', 'xpm'));
$top -> iconimage($iconimage);

splash_message("Setting up key bindings");
my $multikey = "";
$top -> bind('<Control-a>'     => \&select_all);
$top -> bind('<Control-d>'     => \&keyboard_d);
$top -> bind('<Control-e>'     => \&keyboard_e);
$top -> bind('<Control-g>'     => \&keyboard_g);
$top -> bind('<Control-h>'     => \&show_hint);
$top -> bind('<Control-i>'     => \&import_atoms);
$top -> bind('<Control-j>'     => \&keyboard_down);
$top -> bind('<Alt-j>'         => \&keyboard_alt_j);
$top -> bind('<Control-k>'     => \&keyboard_up);
$top -> bind('<Alt-k>'         => \&keyboard_alt_k);
$top -> bind('<Control-l>'     => sub{$list->focus});
$top -> bind('<Control-m>'     => sub{pod_display("artemis.pod")});
$top -> bind('<Control-n>'     => \&rename_this);
$top -> bind('<Control-o>'     => \&open_file);
$top -> bind('<Control-p>'     => sub{
	       if ($is_windows) {
		 Error("Print from the plot window instead.");
	       } else {
		 &replot('print')
	       }});
$top -> bind('<Control-q>'     => \&quit_artemis);
$top -> bind('<Control-r>'     => sub{&read_feff(0)});
$top -> bind('<Control-s>'     => sub{&save_project(0,0)});
$top -> bind('<Control-t>'     =>
	     sub {
	       ($current =~ /feff\d+\.\d+$/) ?
		 $widgets{path_include} -> invoke() :
		   Echo('Control-t toggles a path for including in the fit.');
	     });
$top -> bind('<Control-u>'     => \&deselect_all);
##$top -> bind('<Control-w>'     => sub{generate_script(0)});
$top -> bind('<Control-w>'     => sub {
	       my $dialog =
		 $top -> Dialog(-bitmap         => 'questhead',
				-text           => "Save this project before closing?.",
				-title          => 'Artemis: Question...',
				-buttons        => ['Save', 'Just close it', 'Cancel'],
				-default_button => 'Save',
				-font           => $config{fonts}{med},
				-popover        => 'cursor');
	       &posted_Dialog;
	       my $response = $dialog->Show();
	       Echo("Not closing project."), return if $response eq 'Cancel';
	       save_project(0,0) if $response eq 'Save';
	       delete_project(0);
	       Echo("Closed project");
	     });
$top -> bind('<Control-y>'	   => \&gds2_keyboard_type);
$top -> bind('<Control-period>'	   => \&cursor);
$top -> bind('<Control-semicolon>' => \&keyboard_plot);
$top -> bind('<Control-equal>'	   => \&zoom);
$top -> bind('<Control-minus>'	   => sub{&replot('replot')});
$top -> bind('<Shift-Alt-d>'	   => \&dump_paths);


## top level widget for displaying verious interactions
my $update = $top -> Toplevel(-class=>'horae');
$update -> withdraw;
$update -> protocol(WM_DELETE_WINDOW => sub{$update->withdraw});
#$update -> iconbitmap('@'.$iconbitmap);
$update -> iconimage($iconimage);
my $notebook = $update -> NoteBook(-backpagecolor=>$config{colors}{background},
				   -inactivebackground=>$config{colors}{inactivebackground},);
$top -> bind('<Control-Key-1>' => sub{raise_palette('ifeffit')   } );
$top -> bind('<Control-Key-2>' => sub{raise_palette('results')   } );
$top -> bind('<Control-Key-3>' => sub{raise_palette('files')     } );
$top -> bind('<Control-Key-4>' => sub{raise_palette('messages')  } );
$top -> bind('<Control-Key-5>' => sub{raise_palette('echo')      } );
$top -> bind('<Control-Key-6>' => sub{raise_palette('journal')   } );
$top -> bind('<Control-Key-7>' => sub{raise_palette('properties')} );

## $top -> bind('<Control-e>' => sub{print "doing something bad ... \n";
## 				  &foo;
## 				});

## ============================================================================
## ============================================================================
## arrays of commonly used widget arguments
my @button_list    = (-foreground       => $config{colors}{activebackground},
		      -activeforeground => $config{colors}{activebackground},
		      -background       => $config{colors}{button},
		      -activebackground => $config{colors}{activebutton},
		      -font             => $config{fonts}{bold},);
my @button2_list   = (-foreground       => $config{colors}{button},
		      -activeforeground => $config{colors}{button},
		      -background       => $config{colors}{background},
		      -activebackground => $config{colors}{activebackground},
		      -font             => $config{fonts}{smbold},);
my @button3_list =   (-foreground       => $config{colors}{button},
		      -activeforeground => $config{colors}{button},
		      -background	=> $config{colors}{background2},
		      -activebackground	=> $config{colors}{activebackground2});
my @fitbutton_list = (-foreground       => $config{colors}{activebackground},
		      -activeforeground => $config{colors}{activebackground},
		      -background       => $config{colors}{fitbutton},
		      -activebackground => $config{colors}{activefitbutton},
		      -font             => $config{fonts}{bold},);
my @menu_args      = (-foreground       => $config{colors}{foreground},
		      -background       => $config{colors}{background},
		      -activeforeground => $config{colors}{activebutton},
		      );
		      #-font => $config{fonts}{small}, );
my @menu_header_args = (-foreground	  =>'grey20',
			-activeforeground =>'grey20',
			-font		  =>$config{fonts}{smbold}, );
my @title          = (-fill       => $config{colors}{activehighlightcolor},
		      -font       => $config{fonts}{bignbold});
my @title2         = (-foreground => $config{colors}{activehighlightcolor},
		      -font       => $config{fonts}{bignbold});
my @window_size    = (-width      => $config{geometry}{main_width}.'c',
		      -height     => $config{geometry}{main_height}.'c');


## ============================================================================
## ============================================================================
## menubar
## my $menubar = $top -> Frame(-relief=>'ridge', -borderwidth=>2)
##    -> pack(-side=>"top", -anchor=>'nw', -fill=>'x');
splash_message("Creating projectbar and menus");
$top -> configure(-menu=> my $menubar = $top->Menu(-relief=>'ridge'));


## ============================================================================
## ============================================================================
## projectbar
my $projectbar = $top -> Frame(-relief=>'flat', -borderwidth=>2);
$projectbar -> Label(-text=>'Current project: ', -font=>$config{fonts}{bold},
		     -foreground=>$config{colors}{button})
  -> pack(-side=>'left', -padx=>4);
my $project_label;
if ($config{general}{projectbar} eq 'file') {
  $project_label = $projectbar -> Label(-textvariable => \$project_name,
					-font	      => $config{fonts}{med},
					-relief	      => 'flat',
					-anchor	      => 'e')
    -> pack(-side=>'left');
} elsif ($config{general}{projectbar} eq 'title') {
  $project_label = $projectbar -> Label(-textvariable => \$props{'Project title'},
					-font	      => $config{fonts}{med},
					-relief	      => 'flat',
					-anchor	      => 'e')
    -> pack(-side=>'left');
};
$widgets{project_modified} = $projectbar -> Label(-text=>'',
						  -width=>9,
						  -relief=>'groove',
						  -font=>$config{fonts}{small},)
   -> pack(-side=>'right', -padx=>2);
my @hilite = (-foreground => $config{colors}{highlightcolor},
	      -background => $config{colors}{activebackground},
	      -cursor     => $mouse_over_cursor,);
my @normal = (-foreground => $config{colors}{foreground},
	      -background => $config{colors}{background});
$widgets{project_modified} -> bind("<ButtonPress-1>", sub{&save_project(0,0) unless $project_saved});
$widgets{project_modified} -> bind("<ButtonPress-2>", sub{&save_project(0,0) unless $project_saved});
$widgets{project_modified} -> bind("<ButtonPress-3>", sub{&save_project(0,0) unless $project_saved});
$widgets{project_modified} -> bind("<Any-Enter>",     sub{$widgets{project_modified}->configure(@hilite) unless $project_saved});
$widgets{project_modified} -> bind("<Any-Leave>",     sub{$widgets{project_modified}->configure(@normal)});
$projectbar -> pack(-side=>"top", -anchor=>'nw', -fill=>'x')
  unless ($config{general}{projectbar} eq 'none');

## ============================================================================
## ============================================================================
## File menu
my $save_index = 10; # data  all_paths (+1)  selected (+3)
my $file_menu = $menubar
  -> cascade(-label=>'~File', @menu_args,
	     -menuitems=>[[ command => 'Open file', -accelerator => 'Ctrl-o',
			    -command => \&open_file],
			  [ cascade => 'Recent files', -tearoff=>0,
			    -menuitems=>[]],
			  [ cascade => 'Project data', -tearoff=>0,
			    -menuitems => [
					   [ command => 'Import project data', @menu_args,
					     -command => sub{dispatch_read_data(0, "", 1)}],
					     ##-command => sub{dispatch_read_data($paths{$current}->data, "", 1)}],
					   [ command => 'Transfer many data files', @menu_args,
					     -command => \&bulk_data],
					  ]],
			  "-",
			  [ command =>'Convert a feffit input file',
			    -state => ($config{general}{import_feffit}) ? 'normal' : 'disabled',
			    -command=>\&feffit_convert_input],
			  "-",
			  [ command =>'Save project', -accelerator => 'Ctrl-s',
			    -command => [\&save_project, 0, 0]],
			  [ command =>'Save project as ...',
			    -command => [\&save_project, 1, 0]],
			  "-",
			  [ cascade => 'Save data as ...', -tearoff=>0,
			    -state   =>'disabled',
			    -menuitems => [[ command=>'chi(k)', @menu_args,
					     -command=>[\&save_data, 'data', 'k']],
					   [ command=>'chi(R)', @menu_args,
					     -command=>[\&save_data, 'data', 'r']],
					   [ command=>'chi(q)', @menu_args,
					     -command=>[\&save_data, 'data', 'q']]]
			  ],
			  [ cascade => 'Save fit as ...', -tearoff=>0,
			    -state   =>'disabled',
			    -menuitems => [[ command=>'chi(k)', @menu_args,
					     -command=>[\&save_fit, 'fit',  'k']],
					   [ command=>'chi(R)', @menu_args,
					     -command=>[\&save_fit, 'fit',  'r']],
					   [ command=>'chi(q)', @menu_args,
					     -command=>[\&save_fit, 'fit',  'q']]]
			  ],
			  [ cascade => 'Save background as ...', -tearoff=>0,
			    -state   =>'disabled',
			    -menuitems => [[ command=>'chi(k)', @menu_args,
					     -command=>[\&save_fit, 'bkg',  'k']],
					   [ command=>'chi(R)', @menu_args,
					     -command=>[\&save_fit, 'bkg',  'r']],
					   [ command=>'chi(q)', @menu_args,
					     -command=>[\&save_fit, 'bkg',  'q']]]
			  ],
			  [ cascade => 'Save residual as ...', -tearoff=>0,
			    -state   =>'disabled',
			    -menuitems => [[ command=>'chi(k)', @menu_args,
					     -command=>[\&save_fit, 'res',  'k']],
					   [ command=>'chi(R)', @menu_args,
					     -command=>[\&save_fit, 'res',  'r']],
					   [ command=>'chi(q)', @menu_args,
					     -command=>[\&save_fit, 'res',  'q']]]
			  ],
			  [ cascade => 'Save ALL paths as ...', -tearoff=>0,
			    -state   =>'disabled',
			    -menuitems => [[ command=>'chi(k)', @menu_args,
					     -command=>[\&save_all_paths, 'k']],
					   [ command=>'chi(R)', @menu_args,
					     -command=>[\&save_all_paths, 'R']],
					   [ command=>'chi(q)', @menu_args,
					     -command=>[\&save_all_paths, 'q']]]
			  ],
			  "-",
			  [cascade => "Save selected groups as", -tearoff=>0,
			   -state  =>'disabled',
			   -menuitems=>[
					[ command=>"chi(k)", @menu_args,
					  -command=>[\&save_selected, 'k']],
					[ command=>"k*chi(k)", @menu_args,
					  -command=>[\&save_selected, 'k1']],
					[ command=>"k^2*chi(k)", @menu_args,
					  -command=>[\&save_selected, 'k2']],
					[ command=>"k^3*chi(k)", @menu_args,
					  -command=>[\&save_selected, 'k3']],
					"-",
					[ command=>"|chi(R)|", @menu_args,
					  -command=>[\&save_selected, 'rm']],
					[ command=>"Re[chi(R)]", @menu_args,
					  -command=>[\&save_selected, 'rr']],
					[ command=>"Im[chi(R)]", @menu_args,
					  -command=>[\&save_selected, 'ri']],
					"-",
					[ command=>"|chi(q)|", @menu_args,
					  -command=>[\&save_selected, 'qm']],
					[ command=>"Re[chi(q)]", @menu_args,
					  -command=>[\&save_selected, 'qr']],
					[ command=>"Im[chi(q)]", @menu_args,
					  -command=>[\&save_selected, 'qi']],
				       ]],
			  "-",
			  [ command =>'Close project', -accelerator => 'Crtl-w',
			    -command => sub {
			      my $dialog =
				$top -> Dialog(-bitmap         => 'questhead',
					       -text           => "Save this project before closing?.",
					       -title          => 'Artemis: Question...',
					       -buttons        => ['Save', 'Just close it', 'Cancel'],
					       -default_button => 'Save',
					       -font           => $config{fonts}{med},
					       -popover        => 'cursor');
			      &posted_Dialog;
			      my $response = $dialog->Show();
			      Echo("Not closing project"), return if $response eq 'Cancel';
			      save_project(0,0) if $response eq 'Save';
			      delete_project(0);
			      Echo("Closed project.");
			    }],
			  [ command =>'Quit', -accelerator => 'Ctrl-q',
			    -command=>\&quit_artemis]
			 ]);
#  -> pack(-side=>'left');

## ============================================================================
## ============================================================================
## edit menu
my $edit_menu = $menubar
  -> cascade(-label=>'~Edit', @menu_args,
	     -menuitems=>[
			  [ command => "Write Ifeffit script",
			   -command => [\&generate_script, 0]],
			  "-",
			  [ command => "Display Ifeffit buffer", -accelerator => 'Ctrl-1',
			   -command => sub{raise_palette('ifeffit');}],
			  [ command => "Display fit results", -accelerator => 'Ctrl-2',
			   -command => sub{raise_palette('results');}],
			  [ command => "View files", -accelerator => 'Ctrl-3',
			   -command => sub{raise_palette('files');}],
			  [ command => "View messages", -accelerator => 'Ctrl-4',
			   -command => sub{raise_palette('messages');}],
			  [ command => "Display echo buffer", -accelerator => 'Ctrl-5',
			   -command => sub{raise_palette('echo');}],
			  [ command => "Write in journal", -accelerator => 'Ctrl-6',
			   -command => sub{raise_palette('journal');}],
			  [ command => "Edit project properties", -accelerator => 'Ctrl-7',
			   -command => sub{raise_palette('properties');}],
			  "-",
			  [ command => "Compact project",
			   -command => \&compactify_project],
			  "-",
			  [ command => 'Edit preferences',
			   -command => \&prefs],
			 ]);
#  -> pack(-side=>'left');


## ============================================================================
## ============================================================================
## show menu
## my $show_menu = $menubar -> cascade(-label=>'Show', @menu_args,);
## #  -> pack(-side=>'left');
## $show_menu -> AddItems([ command=>"Show groups",
## 			-command=>[\&show_things, 'groups']],
## 		       #[ command=>"Show paths",
## 		       # -command=>[\&show_things, 'paths']],
## 		       [ command=>'Show this path', -state=>'disabled',
## 			-command=>\&show_path],
## 		       [ command=>"Show variables",
## 			-command=>[\&show_things, 'variables']],
## 		       [ command=>"Show def variables",
## 			-command=>[\&show_defs]],
## 		       [ command=>"Show scalars",
## 			-command=>[\&show_things, 'scalars']],
## 		       [ command=>"Show arrays",
## 			-command=>[\&show_things, 'arrays']],
## 		       [ command=>"Show strings",
## 			-command=>[\&show_things, 'strings']],
## 		       #[ command=>"Show all",
## 		       # -command=>[\&show_things, 'all']],
## 		       "-",
## 		       [ command=>"Show project folder",
## 			-command=>sub{Echo("Project folder: $project_folder")}],
## 		      );
##



## ## vertical separator
## $menubar -> Frame(-width=>2, -borderwidth=>2, -relief=>'sunken') ->
##   pack(-side=>'left', -fill=>'y', -pady=>2);

$menubar -> separator;


## ============================================================================
## ============================================================================
## gsd menu
my $gsd_menu = $menubar
  -> cascade(-label=>'~GDS', @menu_args,
	     -menuitems=>[[ command => 'Grab all best fit values',
			    -command => \&grab_all_best_fits],
			  [ command => 'Annotate selected parameter',
			    -command => \&gds2_annotation],
			  [ command => 'Locate parameter',
			    -command => \&gds2_locate],
			  [ command => 'Show all parameters',
			    -command => \&gds2_show],
			  [ command => 'Reset all variables',
			    -command => \&reset_all_variables],
			  [ command => 'Convert all guesses to sets',
			    -command => \&gds2_guess_to_set],
			  [ command => 'Discard all variables',
			    -command => \&clear_all_variables],
			  "-",
			  [ command => 'Highlight parameters matching ...',
			    -command => \&gds2_highlight],
			  [ command => 'Clear parameter highlights',
			    -command => \&gds2_clear_highlights],
			  "-",
			  [ command => 'Import variables from text file',
			    -command => \&gds2_import_text],
			  [ command => 'Export variables to text file',
			    -command => \&gds2_export_text],
			  "-",
			  [ command => 'How many independent points?',
			    -command => \&nidp],
			  [ cascade => 'Quick help',
			   -tearoff => 0,
			   -menuitems => [
					  [ command => 'guess',
					   -command => [\&Echo, "Guesses are varied to best fit the data; math expressions are written in terms of them"]],
					  [ command => 'def',
					   -command => [\&Echo, "A def parameter's math expression is stored and updated througout a fit"]],
					  [ command => 'set',
					   -command => [\&Echo, "A set parameter is a math expression which is evaluated at the time of definition"]],
					  [ command => 'skip',
					   -command => [\&Echo, "A skip parameter is ignored by Artemis but retained in the project"]],
					  [ command => 'restrain',
					   -command => [\&Echo, "A restrain parameter is a math expression which is evaluated and added to chi-square during the fit"]],
					  [ command => 'after',
					   -command => [\&Echo, "An after parameter is a math expression which is evaluated after the fit and written to the log"]],
					 ]],
			 ]);
#  -> pack(-side=>'left');

## ============================================================================
## ============================================================================
## data menu
my $data_menu = $menubar
  -> cascade(-label=>'~Data', @menu_args,
	     -menuitems=>[[ command => 'Fit',
			   -command => [\&generate_script, 1]],
			  ##[ cascade => "Sum of paths (this data set) ...", -tearoff=>0,
			  ## -menuitems=>[[ command => 'All inlcuded paths', @menu_args,
			  ##		 -command => [\&generate_script, 2]],
			  ##		[ command => 'Selected & included paths', @menu_args,
			  ##	         -command => [\&generate_script, 2, 'selected, included']],
			  ##		[ command => 'All selected paths', @menu_args,
			  ##	         -command => [\&generate_script, 2, 'all selected']],
			  ##	       ]],
			  ##[ command => 'Automated first shell fit',
			  ## -state   => 'disabled',
			  ## -command => [\&firstshell, 1]],
			  [ command => 'Save background subtracted as chi(k)',
			   -command => \&save_bkgsub_data,
			   -state   => 'disabled',],
			  [ command => 'Make difference spectra using selected paths',
			   -command => \&make_difference_spectrum],
			  "-",
			  [ cascade   => 'Clone a FEFF calculation ...',
			   -tearoff   => 0,
			   -menuitems =>[
					 [ command => 'link',
					  -command => [\&clone_feff, 'link']],
					 [ command => 'copy',
				          -command => [\&clone_feff, 'copy']],
					]],
			  #[ command => 'Change this data file',
			  #  -command => \&renew_data], #dispatch_read_data],
			  [ command => 'Rename these data', -accelerator=>'Ctrl-n',
			   -command => \&rename_data],
			  [ command => 'View this data file',
			   -command => [\&display_file, 'data', 'this']],
			  [ command => 'Restore default parameter values',
			   -command => [\&restore_default, 'all']],
			  "-",
			  [ command => 'Discard this data set',
			   -command => \&delete_data],
			  "-",
			  [ command => 'What is epsilon_k?',
			   -command => \&fetch_epsilon_k],
			  [ command => 'How many independent points?',
			   -command => \&nidp],
			 ]);
#  -> pack(-side=>'left');

my $sum_menu = $menubar
  -> cascade(-label=>'Sum', @menu_args, -underline=>1,
	     -menuitems=>[[ command => 'All included paths for this data set', @menu_args,
			    -command => [\&generate_script, 2]],
			  [ command => 'Selected & included paths for this data set', @menu_args,
			    -command => [\&generate_script, 2, 'selected, included']],
			  [ command => 'All selected paths for this data set', @menu_args,
			    -command => [\&generate_script, 2, 'all selected']],
			 ]);

my $fit_menu = $menubar
  -> cascade(-label=>'Fits', @menu_args, -underline=>1,
	     -menuitems=>[[ command => "Restore this fit model",
			   -command => \&logview_restore_model,
			   -state => 'disabled'],
			  "-",
			  [ cascade   => 'Save data + this fit, residual (bkg) as ...',
			   -tearoff   => 0,
			   -menuitems =>[
					 [ command =>'chi(k)', @menu_args,
					  -command =>[\&save_full_data, 'k']],
					 "-",
					 [ command =>'|chi(R)|', @menu_args,
					  -command =>[\&save_full_data, 'r_mag']],
					 [ command =>'Re[chi(R)]', @menu_args,
					  -command =>[\&save_full_data, 'r_re']],
					 [ command =>'Im[chi(R)]', @menu_args,
					  -command =>[\&save_full_data, 'r_im']],
					 "-",
					 [ command =>'|chi(q)|', @menu_args,
					  -command =>[\&save_full_data, 'q_mag']],
					 [ command =>'Re[chi(q)]', @menu_args,
					  -command =>[\&save_full_data, 'q_re']],
					 [ command =>'Im[chi(q)]', @menu_args,
					  -command =>[\&save_full_data, 'q_im']],
					],
			  ],
			  [ command => 'Rename this fit',
			   -accelerator=>'Ctrl-n',
			   -command =>\&rename_fit ],
			  [ cascade   => 'This fit\'s comment ...',
			   -tearoff   => 0,
			   -menuitems => [
					  [ command => "Show",
					    -command =>\&logview_show_comment ],
					  [ command => "Change",
					    -command =>\&logview_change_comment ],
					 ],
			  ],
			  [ cascade   => 'This fit\'s figure of merit ...',
			   -tearoff   => 0,
			   -menuitems => [
					  [ command => "Show",
					    -command =>\&logview_show_fom ],
					  [ command => "Change",
					    -command =>\&logview_change_fom ],
					 ],
			  ],
			  [ command => "Show warnings from this fit",
			   -command => \&display_warnings,
			  ],
			  [ cascade => "Plot running R-factor ...", -tearoff=>0,
			   -state   => 'disabled',
			   -menuitems => [[ command=>"computed in k", @menu_args,
					   -command=>[\&running_r_factor, 'k']],
					  [ command=>"computed in R", @menu_args,
					   -command=>[\&running_r_factor, 'r']],
					  [ command=>"computed in q", @menu_args,
					   -command=>[\&running_r_factor, 'q']]]],
			  #"-",
			  #[ command => "Hide this fit",
			  # -command => \&hide_fit],
			  #[ command => "Hide selected fits",
			  # -command => \&hide_selected_fits],
			  #[ command => "Show all fits",
			  # -command => \&show_fits],
			  "-",
			  [ command => "Discard this fit",
			   -command => \&discard_fit],
			  [ command => "Discard selected fits",
			   -command => \&discard_selected_fits],
			  [ command => "Discard all fits",
			   -command => \&discard_all_fits],
			  "-",
			  [ checkbutton => "Make new entry for each fit",
			   -selectcolor => $config{colors}{check},
			   -variable    => \$fit{new},
			   -onvalue     => 1,
			   -offvalue    => 0,],
			  [ checkbutton => "Show fit information dialog",
			   -selectcolor => $config{colors}{check},
			   -variable    => \$config{general}{fit_query},
			   -onvalue     => 1,
			   -offvalue    => 0,],
			 ]);

## ============================================================================
## ============================================================================
## FEFF Menu
my $feff_menu = $menubar
  -> cascade(-label=>'~Theory', @menu_args,
	     -menuitems=>[[ command => "New Atoms page",
			   -command => \&new_atoms],
			  [ command => "New Feff input template",
			   -command => \&feff_template],
			  [ command => "Quick first shell theory",
			   -command => [\&firstshell, 0]],
			  "-",
			  [ command => "Add a feff path",
			   -command => [\&read_feff, '^^']], #\&add_a_path],
			  [ command => 'Rename this FEFF calculation',
			   -accelerator=>'Ctrl-n',
			   -command => \&rename_feff],
			  [ cascade => "View ...", -tearoff=>0,
			    -menuitems=>[[ command => "log of Feff run", @menu_args,
					   -command => [\&display_file, 'feff', 'feff.run']],
					 [ command => "misc.dat", @menu_args,
					   -command => [\&display_file, 'feff', 'misc.dat']],
					 [ command => "files.dat", @menu_args,
					   -command => [\&display_file, 'feff', 'files.dat']],
					 [ command => "paths.dat", @menu_args,
					   -command => [\&display_file, 'feff', 'paths.dat']],
					]],
			  [ cascade => 'Set path degeneracies ...', -tearoff=>0,
			    -menuitems => [
					   [ command => 'to 1', @menu_args,
					     -command => [\&set_degeneracy, 1]],
					   [ command => 'to FEFF', @menu_args,
					     -command => [\&set_degeneracy, 'feff']],
					  ]],
			  "-",
			  [ command => "Atoms", @menu_header_args],
			  [ command => "  Space group browser",
			   -command => \&post_sgb ],
			  [ cascade => '  Write special output', -tearoff=>0,],
			  [ command => "  Clear Atoms page",
			   -command => \&clear_atoms ],
			  "-",
			  [ command => 'Discard this FEFF calculation',
			   -command => [\&delete_feff,0,0],
			   -state   => 'disabled'],
			  "-",
			  [ command => 'Identify this FEFF calculation',
			   -command => \&identify_feff, -state=>'disabled'],
			 ]);
#  -> pack(-side=>'left');
&set_atp_menu;



## ============================================================================
## ============================================================================
## Paths menu
my @paths_menuitems = ([ command => 'View this feffNNNN.dat file', -state=>'disabled',
			 -command => [\&display_file, 'path', 'this']],
		       [ command => 'Show this path', -state=>'disabled',
			 -command => \&show_path],
		       [ cascade => "Save this path as ...", -tearoff=>0,
			 -state=>'disabled',
			 -menuitems=>[[ command=>"chi(k)", @menu_args,
					-command=>[\&save_data, 'path', 'k']],
				      [ command=>"chi(R)", @menu_args,
					-command=>[\&save_data, 'path', 'r']],
				      [ command=>"chi(q)", @menu_args,
					-command=>[\&save_data, 'path', 'q']]]],
		       "-",
		      );

my @add_cascade = ();
my @clear_cascade = ();
foreach (qw(label S02 E0 delR sigma^2 Ei 3rd 4th dphase k_array phase_array amp_array)) {
  push @add_cascade,   [ command=>$_, @menu_args,
		        -command=>[\&add_mathexp, $_]];
  push @clear_cascade, [ command=>$_, @menu_args,
		        -command=>[\&add_to_paths, $_, '^^clear^^', 'this']];
};
push @paths_menuitems, [ cascade => "Add math expression to each path",
			 -tearoff=>0, -menuitems=>\@add_cascade];
push @paths_menuitems, [ cascade => "Clear math expression for each path",
			 -tearoff=>0, -menuitems=>\@clear_cascade];
push @paths_menuitems, [ cascade => "Include paths for fitting", -tearoff=>0,
			-menuitems=>
			 [[ command=>"For THIS feff calculation ...", @menu_header_args],
			  [ command=>"  include all paths", @menu_args,
			   -command=>[\&select_paths, 'all,this']],
			  [ command=>"  exclude all paths after current", @menu_args,
			   -command=>[\&select_paths, 'current']],
			  [ command=>"  include only paths with N or fewer legs", @menu_args,
			   -command=>[\&select_paths, 'nlegs']],
			  [ command=>"  include only paths shorter than R", @menu_args,
			   -command=>[\&select_paths, 'r'],],
			  [ command=>"  include only paths with amplitude larger than A", @menu_args,
			   -command=>[\&select_paths, 'amp'],],
			  [ command=>"  exclude all paths", @menu_args,
			   -command=>[\&select_paths, 'none,this']],
			  [ command=>"  invert the included paths", @menu_args,
			   -command=>[\&select_paths, 'invert,this']],
			  "-",
			  [ command=>"For EACH feff calculation ...", @menu_header_args, ],
			  [ command=>"  include all paths", @menu_args,
			   -command=>[\&select_paths, 'all,each']],
			  [ command=>"  exclude all paths", @menu_args,
			   -command=>[\&select_paths, 'none,each']],
			  [ command=>"  invert the included paths", @menu_args,
			   -command=>[\&select_paths, 'invert']],
			  "-",
			  [ command=>"Include selected paths", @menu_args,
			   -command=>[\&select_paths, 'selon']],
			  [ command=>"Exclude selected paths", @menu_args,
			   -command=>[\&select_paths, 'seloff']],
			 ]];
push @paths_menuitems, [ cascade => "Discard paths", -tearoff=>0,
			 -menuitems=>
			 [[ command=>"Discard this path", @menu_args,
			   -command=>[\&delete_path, 'this']],
			  "-",
			  [ command=>"For THIS feff calculation ...", @menu_header_args,],
			  [ command=>"  discard all paths", @menu_args,
			   -command=>[\&delete_path, 'all']],
			  [ command=>"  discard all paths after current", @menu_args,
			   -command=>[\&delete_path, 'current']],
			  [ command=>"  discard all paths with more than N legs", @menu_args,
			   -command=>[\&delete_path, 'nlegs']],
			  [ command=>"  discard all paths longer than R", @menu_args,
			   -command=>[\&delete_path, 'r']],
			  [ command=>"  discard all paths with amplitude smaller than A", @menu_args,
			   -command=>[\&delete_path, 'amp']],
			  "-",
			  [ command=>"Discard selected paths", @menu_args,
			   -command=>[\&delete_path, 'sel']],
			 ]];
push @paths_menuitems, "-",
  [ command=>"Clone this feff path", -state => 'disabled',
   -command=>\&clone_this_path],
  [ command=>"Rename this path", -state => 'disabled',
   -accelerator=>'Ctrl-n',
   -command=>\&rename_this],
  [ cascade=>"Export these paths parameters ...",
   -menuitems=>[[ command => "to every path in THIS feff calculation",
		 -command => [\&copy_pps, 'this']],
		[ command => "to every path in EACH feff with THIS data set",
		 -command => [\&copy_pps, 'data']],
		[ command => "to every path in EACH feff calculation",
		 -command => [\&copy_pps, 'each']],
		[ command => "to SELECTED paths",
		 -command => [\&copy_pps, 'sel']]
	       ]
    ],
  [ command=>"Add a feff path",
   -command=>[\&read_feff, '^^']],
  "-",
  [ checkbutton=>"Extended path parameters",
   -selectcolor=>$config{colors}{check},
   -variable=>\$config{paths}{extpp},
   -command=>\&manage_extended_params];

my $paths_menu = $menubar
  -> cascade(-label=>'~Paths', @menu_args,
	     -menuitems=>\@paths_menuitems);
#  -> pack(-side=>'left');





## vertical separator
#$menubar -> Frame(-width=>2, -borderwidth=>2, -relief=>'sunken') ->
#  pack(-side=>'left', -fill=>'y', -pady=>2);

## ============================================================================
## ============================================================================
## plot menu
my @plot_menuitems = (['cascade'=>'Plot in ...', -tearoff=>0,
		       -menuitems=>[['command'=>'k-space', @menu_args,
				     -command =>[\&plot, 'k', 0]],
				    ['command'=>'R-space', @menu_args,
				     -command =>[\&plot, 'r', 0]],
				    ['command'=>'q-space', @menu_args,
				     -command =>[\&plot, 'q', 0]]]],
		      ['command'=>'Select all for plotting', -accelerator => 'Ctrl-a',
		       -command =>\&select_all],
		      ['command'=>'Deselect all for plotting', -accelerator => 'Ctrl-u',
		       -command =>\&deselect_all],
		      "-",
		      ['command'=>'Zoom', -accelerator => 'Ctrl-=',
		       -command =>\&zoom], # no trailing newline!!
		      ['command'=>'Unzoom', -accelerator => 'Crtl--',
		       -command=>[\&replot, 'replot']],
		      ['command'=>'Cursor', -accelerator => 'Ctrl-.',
		       -command =>\&cursor], # no trailing newline!!
		      '-');




my %image_formats = (gif  => "GIF (landscape)",
		     vgif => "GIF (portrait)",
		     png  => "PNG (landscape)",
		     vpng => "PNG (portrait)",
		     tpng => "PNG (black background)",
		     ps	  => "B/W Postscript (landscape)",
		     cps  => "Color Postscipt (landscape)",
		     vps  => "B/W Postscript (portrait)",
		     vcps => "Color Postscipt (portrait)",);
my @format_list;
foreach my $f ( split(" ", Ifeffit::get_string('plot_devices')) ) {
  my $format = substr($f,1);	# strip the leading slash
  next if ($format =~ /null/);
  next if ($format =~ /^x/);
  next if ($format =~ /^c?gw/);
  $image_formats{$format} ||= $format;
  push @format_list, ['command' =>$image_formats{$format}, -command  =>[\&replot, $f]];
};
push @plot_menuitems, [cascade=>"Save image as ...", -tearoff=>0,
		       -menuitems=>\@format_list];


push @plot_menuitems, "-",
  ['command'=>'Print last plot',
   -accelerator => 'Ctrl-p',
   -command=>[\&replot, 'print'],
   -state=>($is_windows)?'disabled':'normal'];


my $plot_menu = $menubar -> cascade(-label=>'Plot', @menu_args, -underline=>2,
				    -menuitems=>\@plot_menuitems);
#  -> pack(-side=>'left');
(@format_list) or $plot_menu -> menu -> entryconfigure(9, -state=>'disabled');


$menubar -> separator;

## ============================================================================
## ============================================================================
## settings menu
## my $settings_menu =
##   $menubar -> cascade(-label=>"Settings", @menu_args, -underline=>0,
## 		      -menuitems => [[ command => 'Swap panels', -accelerator => 'Ctrl-/',
## 				       -state=>'disabled',
## 				       -command => \&swap_panels],
## 				     "-",
## 				     [ command => 'Edit preferences',
## 				       -command => \&prefs],
## 				    ]);


## ============================================================================
## ============================================================================
## help menu
$menubar -> cascade(-label=>"~Help", @menu_args,
		    -menuitems=>[['command'=> 'Document', -accelerator=>'Ctrl-m',
				  -command =>sub{pod_display("artemis.pod")}],
				 ['command'=>'Dump paths',
				  -command=>\&dump_paths],
				 ['command'=>'Show a hint', -accelerator => 'Ctrl-h',
				  -command =>\&show_hint],
				 ['command'=>'About Ifeffit',
				  -command =>sub{Echo($About_Ifeffit)}],
				 ['command'=>'About Artemis',
				  -command =>sub{Echo($About)}]
				]
		   );



## ============================================================================
## ============================================================================
## set up the echo area
splash_message("Creating echo area");
my $ebar = $top -> Frame(-relief=>'flat', -borderwidth=>3)
  -> pack(-side=>"bottom", -fill=>'x');
my $echo = $ebar -> Label(qw/-relief flat -justify left -anchor w/,
			  -font       => $config{fonts}{small},
			  -foreground => $config{colors}{button},
			  #-background => 'green',
			  -text=> "Using Ifeffit ".Ifeffit::get_string("\$&build"))
  -> pack(-side=>'left', -fill=>'x');
$echo -> bind('<KeyPress>' => sub{$multikey = $Tk::event->K; });




splash_message("Creating layout");
## ============================================================================
## ============================================================================
## main panel (fat) (operational/path parameters)
my $fat = $top -> Frame(-relief=>'sunken', -borderwidth=>2,)# @window_size)
  -> pack(-fill=>'both', -expand=>1);

## ============================================================================
## ============================================================================
## skinny panel with path list
my $skinny = $top -> Frame(-relief=>'sunken', -borderwidth=>2);

## ============================================================================
## ============================================================================
## plot controls panel
my $skinny2 = $top -> Frame(-relief=>'sunken', -borderwidth=>2);

&layout; # layout panels in user-selected order

## fit and ff2chi buttons
my $fitbar = $skinny2 ->  Frame(-relief=>'ridge', -borderwidth=>2)
   -> pack(-anchor=>'nw', -fill=>'x');
my $fit_button = $fitbar -> Button(-width=>1, @fitbutton_list,)
  -> pack(-side=>'left', -expand=>1, -fill=>'x');
&set_fit_button('disable');
## my $ff2chi_button = $fitbar -> Button(-text=>'ff2chi', -width=>1, @fitbutton_list,
## 				      -command=>[\&generate_script, 2])
##   -> pack(-side=>'left', -expand=>1, -fill=>'x');

my $lab = $skinny -> Label(-text       => 'Data & Paths',
			   -font       => $config{fonts}{smbold},
			   -foreground => $config{colors}{activehighlightcolor},
			   -justify    => 'center',
			   -relief     => 'raised')
  -> pack(-fill => 'x', -anchor=>'n');

$list = $skinny -> Scrolled('Tree',
			    -separator	      => '.',
			    -selectmode	      => 'extended',
			    #-width	      => 30,
			    -height	      => 1,
			    -indent	      => 20,
			    -scrollbars	      => 'se',
			    -itemtype	      => 'imagetext',
			    -font	      => $config{fonts}{med},
			    -selectbackground => $config{colors}{current},
			    -browsecmd	      => [\&display_properties, Ev('b')],
			    -indicatorcmd     => \&hide_branch,
			   )
  -> pack(qw/-expand 1 -fill both -anchor n -side top/);
BindMouseWheel($list);
$list->bind('<ButtonPress-2>',\&anchor_display);
$list->bind('<ButtonPress-3>', [\&list_mouse_menu, Ev('X'), Ev('Y')]);
$list->bind('<Control-ButtonPress-3>', [\&list_mouse_menu, Ev('X'), Ev('Y')]);


$skinny2 -> Label(-text=>'Plot selected groups in',
		  -font=>$config{fonts}{smbold},
		  -foreground=>$config{colors}{foreground},
		  -justify=>'center', -relief=>'raised')
  ->pack(-fill => 'x', -side => 'top');
my $plotbar = $skinny2 ->  Frame(-relief=>'ridge', -borderwidth=>2)
   -> pack(-anchor=>'nw', -fill=>'x');
my $plotq_button = $plotbar -> Button(-text=>'q', @button_list,
				      -command=>[\&plot, 'q', 0])
  -> pack(-side=>'right', -expand=>1, -fill=>'x');
my $plotr_button = $plotbar -> Button(-text=>'R', @button_list,
				      -command=>[\&plot, 'r', 0])
  -> pack(-side=>'right', -expand=>1, -fill=>'x');
my $plotk_button = $plotbar -> Button(-text=>'k', @button_list,
				      -command=>[\&plot, 'k', 0])
  -> pack(-side=>'right', -expand=>1, -fill=>'x');






## ============================================================================
## ============================================================================
## Setup the toplevel window for various textual interactions,
## including the ifeffit buffer and the raw text edit
splash_message("Creating palettes");
$update -> title("Artemis palettes");
$update -> bind('<Control-q>' => sub{$update->withdraw});
foreach my $n (qw(ifeffit results files messages echo journal properties)) {
  $notecard{$n} = $notebook -> add($n, -label=>ucfirst($n), -anchor=>'center', -underline=>0);
  my $topbar   = $notecard{$n} -> Frame(-relief=>'flat', -borderwidth=>2)
    -> pack(-expand=>0, -fill=>'x');
  $topbar  -> Button(-text=>'Dismiss', -command=>sub{$update->withdraw}, @button2_list)
    -> pack(-side=>'right');
  $labels{$n} = $topbar -> Label(-foreground=>$config{colors}{activehighlightcolor},
				 -font=>$config{fonts}{large})
    -> pack(-side=>'left', -fill=>'x');
  my $h;
 SWITCH: {
    $h = 13, last SWITCH if ($n eq 'ifeffit');
    $h = 15, last SWITCH if ($n eq 'results');
    $h = 13, last SWITCH if ($n eq 'files');
    $h = 15, last SWITCH if ($n eq 'messages');
    $h = 15, last SWITCH if ($n eq 'echo');
    $h = 15, last SWITCH if ($n eq 'journal');
    $h = 13;
  };
  if ($n eq 'properties') {
    my $frame = $notecard{$n} -> Scrolled("Pane",
					  -relief=>'flat',
					  -borderwidth=>2,
					  -scrollbars=>"oe",
					 )
      -> pack(-expand=>1, -fill=>'both', -side=>'top');
    $frame -> Subwidget("yscrollbar")
      -> configure(-background=>$config{colors}{background},
		   ($is_windows) ? () : (-width=>8));
    my $r = 0;
    foreach ('Project title', 'Comment', 'Prepared by', 'Contact') {
      my $subfr = $frame -> Frame(-relief=>'groove',
				  -borderwidth=>2,)
	-> pack(-fill=>'x', -expand=>1, -side=>'top');
      $subfr -> Label(-text	  => "$_:",
		      -width	  => 20,
		      -anchor	  => 'e',
		      -foreground => $config{colors}{activehighlightcolor})
	-> pack(-side=>'left', -anchor=>'e', -padx=>4);
      $subfr -> Entry(-width        => 0,
		      -textvariable => \$props{$_},
		     )
	-> pack(-side=>'right', -anchor=>'w', -fill=>'x', -expand=>1);
    };
    $props{'Project title'} = "<insert a title for your project here>";
    $props{'Comment'} = q{};
    $props{'Prepared by'} = "<insert your name and/or the name of your computer here>";
    $props{'Information content'} = q{};
    $props{'Project location'} = q{};
    #$props{'Prepared by'} = ($is_windows) ? "<insert your name and/or the name of your computer here>" :
    #  join("\@", $ENV{USER}||"you", $ENV{HOST}||"your.computer");
    $props{Contact} = "<insert your email address and/or phone number here>";
    foreach ('Started', 'Last fit', 'Environment', 'Project location', 'Information content') {
      my $subfr = $frame -> Frame(-relief=>'groove',
				  -borderwidth=>2,)
	-> pack(-fill=>'x', -expand=>1, -side=>'top');
      $subfr -> Label(-text	  => "$_:",
		      -width	  => 20,
		      -anchor	  => 'e',
		      -foreground => $config{colors}{activehighlightcolor})
	-> pack(-side=>'left', -anchor=>'e', -padx=>4);
      $subfr -> Entry(-width		  => 0,
		      -textvariable	  => \$props{$_},
		      -state		  => 'disabled',
		      -foreground	  => $config{colors}{foreground},
		      (($Tk::VERSION > 804) ? (-disabledforeground => $config{colors}{foreground},) : ()),
		      -relief		  => 'flat',
		 )
		 #-font=>(($_ eq 'Environment') or ($_ eq 'Information content'))
		 #? $config{fonts}{small} : $config{fonts}{med})
	  -> pack(-side=>'right', -anchor=>'w', -fill=>'x');
    };
  } else {
    my $which = ($n eq 'journal') ? 'Text' : 'ROText';
    $notes{$n}    = $notecard{$n} -> Scrolled($which,
					      -relief	   => 'sunken',
					      -borderwidth => 2,
					      -wrap	   => 'none',
					      -scrollbars  => 'se',
					      -width	   => 7,
					      -height	   => $h,
					      -font	   => $config{fonts}{fixed} )
      -> pack(qw/-expand 1 -fill both -side top/);
    $notebook -> pageconfigure($n, -raisecmd=>sub{$notes{$n}->focus});
    BindMouseWheel($notes{$n});
    $notes{$n}   -> Subwidget("yscrollbar")
      -> configure(-background=>$config{colors}{background},
		   ($is_windows) ? () : (-width=>8));
    $notes{$n}   -> Subwidget("xscrollbar")
      -> configure(-background=>$config{colors}{background},
		   ($is_windows) ? () : (-width=>8));
    &disable_mouse3($notes{$n}->Subwidget(lc($which)));
    $notes{$n} -> bind("<Control-a>" => sub{$notes{$n}->selectAll;
					    $notes{$n}->break;});
  };
 SWITCH: {
    ($n =~ /results/) and do {
      $widgets{results_save} =
	$topbar -> Button(-text=>'Save', @button2_list, -state=>'disabled',
			  -command=>sub{
			    my $fname = 'artemis.log';
			    if ($project_name) {
			      ($fname = basename($project_name)) =~ s/apj$/log/;
			      ($fname .= ".log") unless ($fname =~ /.log$/);
			    };
			    &save_from_palette('results', $fname,
					       'Artemis: Saving results to a log file',
					       ['Artemis results', '.log'],
					       "", "")})
	  -> pack(-side=>'right');
      $widgets{results_choose} =
	$topbar -> Optionmenu(-options=>[["Raw log file"      => 'raw'],
					 ["Quick view"        => 'quick'],
					 ["Column view"       => 'column'],
					 ["Operational view"  => 'operational'],
					],
			      -variable=>\$log_type[1],
			      -textvariable=>\$log_type[0],
			      -command=>sub{log_file_display()},
			      -state=>'disabled')
	  -> pack(-side=>'right');
      last SWITCH;
    };
    ($n =~ /ifeffit/) and do {
      $widgets{ifeffit_save} =
	$topbar -> Button(-text=>'Save buffer to file', @button2_list,
			  -command=>sub{&save_from_palette('ifeffit', 'ifeffit.buffer',
							   'Artemis: Saving ifeffit buffer to a file',
							   ['Ifeffit buffer', '.buffer'],
							   "# Artemis version $Ifeffit::Path::VERSION\n" .
							   $paths{data0}->project_header($project_folder),
							   "")})
	  -> pack(-side=>'right');
      last SWITCH;
    };
    ($n =~ /files/) and do {
      $widgets{files_browse} =
	$topbar -> Button(-text=>'Browse', @button2_list,
			  -command=>sub{
			    my $path = $current_data_dir || cwd;
			    my $types = [['Text files', '*.txt'], ['All files', '*'],];
			    my $file = $top -> getOpenFile(-filetypes=>$types,
							   ##(not $is_windows) ?
							   ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
							   -initialdir=>$path,
							   -title => "Artemis: View a file");
			    return unless ($file);
			    my ($name, $pth, $suffix) = fileparse($file);
			    $current_data_dir = $pth;
			    &display_file('file', $file);
			  })
       -> pack(-side=>'right');
      last SWITCH;
    };
    ($n =~ /messages/) and do {
      $widgets{ifeffit_save} =
	$topbar -> Button(-text=>'Save buffer to file', @button2_list,
			  -command=>sub{&save_from_palette('messages', 'artemis.msg',
							   'Artemis: Saving Artemis\' message to a file',
							   ['Artemis message', '.msg'],
							   "# Artemis version $Ifeffit::Path::VERSION\n" .
							   $paths{data0}->project_header($project_folder),
							   "")})
	  -> pack(-side=>'right');
      last SWITCH;
    };
  };
};
$notebook->pack(-expand=>1, -fill => 'both', -side=>'left');
$labels{ifeffit} -> configure(-text=>"Ifeffit interaction buffer");
$notes{ifeffit}  -> tagConfigure ('command',  -foreground=>$config{colors}{foreground},
				  -lmargin1=>4, -lmargin2=>4);
$notes{ifeffit}  -> tagConfigure ('response', -foreground=>$config{colors}{highlightcolor},
				  -lmargin1=>20, -lmargin2=>20);
$notes{ifeffit}  -> tagConfigure ('comment',  -foreground=>$config{colors}{button},
				  -lmargin1=>4, -lmargin2=>4);
$labels{files}   -> configure(-text=>"View files");
$labels{messages}-> configure(-text=>"Messages from Artemis");
$notes{messages} -> tagConfigure('absorber', -foreground=>$config{colors}{button});
$notes{messages} -> tagConfigure('angles',   -font=>$config{fonts}{fixedit}, -foreground=>$config{colors}{disabledforeground});
$notes{messages} -> tagConfigure('bold',     -font=>$config{fonts}{fixedbold}, -underline=>1);
$notes{messages} -> tagConfigure('warning',  -font=>$config{fonts}{fixedbold}, -foreground=>'red3', -background=>'white');
$notes{messages} -> tagConfigure('guess2',   -spacing1=>2, -background=>$config{colors}{background2});
$notes{messages} -> tagConfigure('guess',    -font=>$config{fonts}{fixedbold}, -spacing1=>1, -spacing3=>1, -foreground=>$config{gds}{guess_color}, -background=>$config{colors}{background2});
$notes{messages} -> tagConfigure('def',      -font=>$config{fonts}{fixedbold}, -spacing1=>1, -spacing3=>1, -foreground=>$config{gds}{def_color});
$notes{messages} -> tagConfigure('set',      -font=>$config{fonts}{fixedbold}, -spacing1=>1, -spacing3=>1, -foreground=>$config{gds}{set_color});
$notes{messages} -> tagConfigure('skip',     -font=>$config{fonts}{fixedbold}, -spacing1=>1, -spacing3=>1, -foreground=>$config{gds}{skip_color});
$notes{messages} -> tagConfigure('after',    -font=>$config{fonts}{fixedbold}, -spacing1=>1, -spacing3=>1, -foreground=>$config{gds}{after_color});
$notes{messages} -> tagConfigure('restrain', -font=>$config{fonts}{fixedbold}, -spacing1=>1, -spacing3=>1, -foreground=>$config{gds}{restrain_color});
$labels{echo}    -> configure(-text=>"Record of all text written to the echo area");
$labels{results} -> configure(-text=>"Results from the last fit");
$notes{results}  -> tagConfigure('pathid', -font=>$config{fonts}{fixedit}, -underline=>1);
$notes{results}  -> tagConfigure('warning', -font=>$config{fonts}{fixedbold}, -foreground=>'red3', -background=>'white');
$labels{journal} -> configure(-text=>"Keep a journal of your analysis project");
$notes{journal}  -> configure(-wrap=>"word");
$notes{journal}  -> bind('<Control-s>' => sub{&save_project(0,0)});
$labels{properties} -> configure(-text=>"Properties of this project");

## set up the button bar in the files notecard
my $filesbbar = $notecard{files} -> Frame(qw/-relief flat -borderwidth 2/)
  -> pack(qw/-expand 0 -fill x/);
$filesbbar -> Label(-textvariable=>\$current_file,
		    -foreground=>$config{colors}{foreground},
		    -relief=>'groove')
  -> pack(qw/-expand 1 -fill x -side left/);
$filesbbar -> Button(-text=>'Save', @button2_list,
		     -command=>sub{&save_from_palette('files', $generic_name,
						      'Artemis: Saving to a file',
						      "",
						      "", "")})
  -> pack(qw/-expand 1 -fill x -side left/);
$filesbbar -> Button(-text=>'Clear', @button2_list,
		     -command=>sub{$notes{files}->delete(qw/1.0 end/);
				   $current_file = ''; })
  -> pack(qw/-expand 1 -fill x -side left/);


## set up the command line in the ifeffit interaction buffer
my $cmdline = $notecard{ifeffit} -> Frame(qw/-relief flat -borderwidth 2/)
  -> pack(qw/-expand 0 -fill x/);
$cmdline -> Label(-text	      => 'Ifeffit> ',
		  -foreground => $config{colors}{activehighlightcolor},
		  -font	      => $config{fonts}{fixed},)
  -> pack(-side=>'left');
my $cmdbox = $cmdline -> Entry(-width	    => 75,
			       -relief	    => 'sunken',
			       -borderwidth => 2)
  -> pack(-side=>'bottom', -expand=>1, -fill=>'x');
my @cmd_buffer = ("");
my $cmd_pointer = $#cmd_buffer;
$cmdbox->bind("<KeyPress-Return>",
	      sub{ $paths{data0}->dispose($cmdbox->get()."\n", $dmode);
		   $cmd_buffer[$#cmd_buffer] =  $cmdbox->get();
		   push @cmd_buffer, "";
		   $cmd_pointer = $#cmd_buffer;
		   $cmdbox->delete(0,'end'); });
$cmdbox->bind("<KeyPress-Up>",
	      sub{ --$cmd_pointer; ($cmd_pointer<0) and ($cmd_pointer=0);
		   $cmdbox->delete(0,'end');
		   $cmdbox->insert(0, $cmd_buffer[$cmd_pointer]); });
$cmdbox->bind("<KeyPress-Down>",
	      sub{ ++$cmd_pointer; ($cmd_pointer>$#cmd_buffer) and ($cmd_pointer= $#cmd_buffer);
		   $cmdbox->delete(0,'end');
		   $cmdbox->insert(0, $cmd_buffer[$cmd_pointer]); });
$cmdbox->bind("<KeyPress-Tab>", # command completion
	      sub{ my $str = $cmdbox -> get;
		   my $i   = $cmdbox -> index('insert');
		   $str = substr($str, 0, $i);
		   $str = reverse $str;
		   $i = index($str, " ");
		   ($i != -1) and ($str = substr($str, 0, $i));
		   $str = reverse $str;
		   my $rep = $abbrevs{$str} || "";
		   ($rep) and ($rep = substr($rep, length($str)));
		   $cmdbox->insert('insert', $rep);
		   $cmdbox->break; # halt further searching of
                                   # bindtags list to avoid loosing
                                   # focus on this widget see Mastering
                                   # Perl/Tk, ch. 15, p. 374
		 });
## reserved word/group name completion


## define various types of text for the paths list
my %list_styles = (
		   enabled      => $list->ItemStyle ('imagetext',
						     -foreground       => 'black',
						     -selectforeground => 'black',
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{current},),
		   enabled_ss   => $list->ItemStyle ('imagetext',
						     -foreground       => 'black',
						     -background       => $config{intrp}{ss},
						     -selectforeground => 'black',
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{current},),
		   enabled_col  => $list->ItemStyle ('imagetext',
						     -foreground       => 'black',
						     -background       => $config{intrp}{focus},
						     -selectforeground => 'black',
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{current},),
		   hidden       => $list->ItemStyle ('imagetext',
						     -foreground       => $config{colors}{hidden},
						     -selectforeground => $config{colors}{hidden},
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{current},),
		   noplot       => $list->ItemStyle ('imagetext',
						     -foreground       => 'black',
						     -selectforeground => 'black',
						     -font	       => $config{fonts}{noplot},
						     -selectbackground => 'yellow'),
		   disabled     => $list->ItemStyle ('imagetext',
						     -foreground       => $config{colors}{exclude},
						     -activeforeground => $config{colors}{exclude},
						     -selectforeground => $config{colors}{exclude},
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{activebackground},),
		   disabled_ss  => $list->ItemStyle ('imagetext',
						     -foreground       => $config{colors}{exclude},
						     -background       => $config{intrp}{ss},
						     -activeforeground => $config{colors}{exclude},
						     -selectforeground => $config{colors}{exclude},
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{activebackground},),
		   disabled_col => $list->ItemStyle ('imagetext',
						     -foreground       => $config{colors}{exclude},
						     -background       => $config{intrp}{focus},
						     -activeforeground => $config{colors}{exclude},
						     -selectforeground => $config{colors}{exclude},
						     -font	       => $config{fonts}{smbold},
						     -selectbackground => $config{colors}{activebackground},),
		   noplotdis    => $list->ItemStyle ('imagetext',
						     -foreground       => $config{colors}{exclude},
						     -activeforeground => $config{colors}{exclude},
						     -selectforeground => $config{colors}{exclude},
						     -font	       => $config{fonts}{noplot},
						     -selectbackground => 'yellow'),
		  );

$list -> add('gsd', -text=>'Guess, Def, Set         ', -style=>$list_styles{noplot});
$list -> setmode('gsd', 'none');
$list -> add('data0', -text=>'Data', -style=>$list_styles{enabled});
$list -> setmode('data0', 'none');
$list -> autosetmode();

$list -> add("data0.0", -text=>'Fit', -style=>$list_styles{enabled},);
$list -> setmode('data0.0', 'close');
## $list -> add("data0.1", -text=>'Residual', -style=>$list_styles{enabled},);
## $list -> setmode('data0.1', 'none');
## $list -> add("data0.2", -text=>'Background', -style=>$list_styles{enabled},);
## $list -> setmode('data0.2', 'none');
$list -> hide('entry', "data0.0");
## $list -> hide('entry', "data0.1");
## $list -> hide('entry', "data0.2");

$list->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
$list->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});


my %temp = ();
&set_temp;
sub set_temp {
  $temp{op_kwindow}  = $config{data}{kwindow};
  $temp{op_rwindow}  = $config{data}{rwindow};
  $temp{op_fitspace} = 'R';
  $temp{op_include}  = 0;
  $temp{op_plot}     = 0;
  $temp{op_do_bkg}   = 'no';
  $temp{op_pcplot}   = 'No';
  $temp{op_pcpath}   = 'None';
  $temp{op_pcpath_label}   = 'None';
  $temp{op_k1}       = 0;
  $temp{op_k2}       = 0;
  $temp{op_k3}       = 0;
  $temp{op_karb_use} = 0;
  $temp{bkg_fixstep} = 0;
  $temp{bkg_flatten} = 0;
  $temp{bkg_clamp2}  = 'None';
};

## ============================================================================
## ============================================================================


## set up error handlers
#$SIG{__DIE__} = sub{$setup->trap('Artemis',$VERSION, 'die', $trapfile, \&Error, $project_folder)};
#$SIG{__WARN__} = sub{$setup->trap("Artemis", $VERSION, "warn", $trapfile, \&Error, $project_folder)};
$SIG{__DIE__}  = sub{Carp::cluck(@_); print STDERR $/; Error("Artemis trapped one or more warnings!  Warning message dumped to screen.")};
$SIG{__WARN__} = sub{Carp::cluck(@_); print STDERR $/; Error("Artemis trapped one or more errors!  Error message dumped to screen.")};

splash_message("Setting up initial data objects");
$setup -> SetDefault(fit_space	    => $config{data}{fit_space},
		     do_bkg	    => ($config{data}{fit_bkg}) ? 'yes' : 'no',
		     kmin	    => $config{data}{kmin},
		     kmax	    => $config{data}{kmax} || 15,
		     dk		    => $config{data}{dk},
		     k1		    => ($config{data}{kweight} == 1),
		     k2		    => ($config{data}{kweight} == 2),
		     k3		    => ($config{data}{kweight} == 3),
		     rmin	    => $config{data}{rmin},
		     rmax	    => $config{data}{rmax},
		     dr		    => $config{data}{dr},
		     kwindow	    => $config{data}{kwindow},
		     rwindow	    => $config{data}{rwindow},
		     cormin	    => $config{data}{cormin},
		     nindicators    => $config{plot}{nindicators},
		     indicatorcolor => $config{plot}{indicatorcolor},
		     indicatorline  => $config{plot}{indicatorline},
		    );
$paths{data0}     = Ifeffit::Path -> new(id	 => 'data0',
					 group   => 'data0',
					 type    => 'data',
					 sameas  => 0,
					 file    => "",
					 include => 1,
					 family  => \%paths);
$paths{"data0.0"} = Ifeffit::Path -> new(id	=> "data0.0",
					 type   => 'fit',
					 group  => 'data0_fit',
					 sameas => 'data0',
					 lab    => 'Fit',
					 parent => 0,
					 family => \%paths);
## $paths{"data0.2"} = Ifeffit::Path -> new(id=>"data0.2", type=>'bkg',
## 					 group=>'data0_bkg',
## 					 sameas=>'data0', lab=>'Background',
## 					 family=>\%paths);
## $paths{"data0.1"} = Ifeffit::Path -> new(id=>"data0.1", type=>'res',
## 					 group=>'data0_res',
## 					 sameas=>'data0', lab=>'Residual',
## 					 family=>\%paths);
$paths{gsd} = Ifeffit::Path -> new(id=>'gsd', type=>'gsd', family=>\%paths);
$props{Environment} = (split(/\n/, $paths{data0} -> project_header))[1];
$props{Environment} =~ s/\# /Artemis $VERSION /;
$props{Started} = $paths{data0} -> date_of_file;


splash_message("Populating main window");
my $current_canvas = 'op';
my $opparams  = make_opparams($fat);
my $gsd       = make_gds2($fat);
my $feff      = make_feff($fat);
my $path      = make_path($fat);
my $logviewer = logviewer($fat);
map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'disabled')} (keys %widgets);
map {$grab{$_}->configure(-state=>'disabled')} (keys %grab);

$opparams -> pack();
# select and anchor the first data file and give the list initial focus
$list->Subwidget("tree")->anchorSet('data0');
$list->Subwidget("tree")->selectionSet('data0');
$list->Subwidget("tree")->focus();
$current = 'data0';

## ============================================================================
## ============================================================================
splash_message("Setting up plotting options");
$skinny2 -> Label(-text=>'Plotting options',
		  -font=>$config{fonts}{smbold},
		  -foreground=>$config{colors}{foreground},
		  -justify=>'center', -relief=>'raised')
  ->pack(-fill => 'x', -side => 'top');
my $kweights = $skinny2 -> Frame(-borderwidth=>2, -relief=>'ridge');
$kweights -> Radiobutton(-text		   => '0',
			 -selectcolor	   => $config{colors}{check},
			 -font		   => $config{fonts}{med},
			 -foreground	   => $config{colors}{activehighlightcolor},
			 -activeforeground => $config{colors}{activehighlightcolor},
			 -value		   => '0',
			 -variable	   => \$plot_features{kweight},
			 -command	   => sub{&plot($last_plot, 0)})
  -> pack(-side=>'left');
$kweights -> Radiobutton(-text		   => '1',
			 -selectcolor	   => $config{colors}{check},
			 -font		   => $config{fonts}{med},
			 -foreground	   => $config{colors}{activehighlightcolor},
			 -activeforeground => $config{colors}{activehighlightcolor},
			 -value		   => '1',
			 -variable	   => \$plot_features{kweight},
			 -command	   => sub{&plot($last_plot, 0)})
  -> pack(-side=>'left');
$kweights -> Radiobutton(-text		   => '2',
			 -selectcolor	   => $config{colors}{check},
			 -font		   => $config{fonts}{med},
			 -foreground	   => $config{colors}{activehighlightcolor},
			 -activeforeground => $config{colors}{activehighlightcolor},
			 -value		   => '2',
			 -variable	   => \$plot_features{kweight},
			 -command	   => sub{&plot($last_plot, 0)})
  -> pack(-side=>'left');
$kweights -> Radiobutton(-text		   => '3',
			 -selectcolor	   => $config{colors}{check},
			 -font		   => $config{fonts}{med},
			 -foreground	   => $config{colors}{activehighlightcolor},
			 -activeforeground => $config{colors}{activehighlightcolor},
			 -value		   => '3',
			 -variable	   => \$plot_features{kweight},
			 -command	   => sub{&plot($last_plot, 0)})
  -> pack(-side=>'left');
$kweights -> Radiobutton(-text		   => 'kw',
			 -selectcolor	   => $config{colors}{check},
			 -font		   => $config{fonts}{med},
			 -foreground	   => $config{colors}{activehighlightcolor},
			 -activeforeground => $config{colors}{activehighlightcolor},
			 -value		   => 'kw',
			 -variable	   => \$plot_features{kweight},
			 -command	   => sub{&plot($last_plot, 0)})
  -> pack(-side=>'left');

$kweights -> pack(-fill => 'x');

$widgets{plot_extra_frame} = $skinny2 -> Frame(-borderwidth=>0, -relief=>'flat');
$widgets{plot_extra} = $widgets{plot_extra_frame} -> NoteBook(-backpagecolor=>$config{colors}{background},
							      -inactivebackground=>$config{colors}{inactivebackground},
							      -font=>$config{fonts}{med}
							     )
  -> pack(-fill=>'both', -side=>'top', -expand=>1, -padx=>2, -pady=>2);
$widgets{plot_Main} = $widgets{plot_extra} -> add('main',       -label=>'Main',   -anchor=>'center');
$widgets{plot_Ind}  = $widgets{plot_extra} -> add('indicators', -label=>'Indic',  -anchor=>'center');
&setup_indicators;
$widgets{plot_Sta}  = $widgets{plot_extra} -> add('traces',     -label=>'Traces', -anchor=>'center');
&setup_stack;
## $widgets{plot_Inv}  = $widgets{plot_extra} -> add('invert',     -label=>'Inv',  -anchor=>'center');
## &setup_invert;
## $widgets{plot_extra_frame} -> Button(-text=>'Hide extra features',
## 				     @button2_list,
## 				     -command=>\&remove_extra_plot)
##   -> pack(-fill=>'x', -side=>'bottom', -padx=>2);

&set_plotoptions($widgets{plot_Main});
$widgets{plot_extra} -> raise('main');


$widgets{help_plot} =
  $skinny2 -> Button(-text=>'Document: Plotting',  @button2_list,
		     -command=>sub{pod_display("artemis_plot.pod")} )
  -> pack(-side=>'bottom', -fill=>'x', -padx=>2, -pady=>2);

$widgets{plot_extra_frame}  -> pack(-fill => 'both', -side => 'top', -expand=>1);



##my $plotsel = $skinny -> NoteBook();
my %plotcard;
## foreach (qw/k r q/) {
##   my $lab;
##   ($_ eq 'k') and ($lab = "  k  ");
##   ($_ eq 'r') and ($lab = "  R  ");
##   ($_ eq 'q') and ($lab = "  q  ");
##   $plotcard{$_} = $plotsel -> add($_, -label=>$lab, -anchor=>'center');
## };
## $plotcard{Help} = $plotsel -> add('Help', -label=>'Help', -anchor=>'center');
#&set_plotcards;
##$plotsel-> pack(-fill => 'x', -side => 'bottom');
##$plotsel -> raise('r');
#$fr -> pack(-side=>'bottom', -fill=>'x', -anchor=>'s');
#$list -> createWindow('0.1c', '18c', -anchor=>'sw', -width=>'5.3c', -window => $fr);

$list->Subwidget("tree")->anchorSet('gsd');
&display_properties;
$top -> update;





## ============================================================================
## ============================================================================
## remove splashscreen and display program
splash_message("Initializing Ifeffit");
$list->Subwidget("tree")->anchorSet('data0');
&display_properties;

my $macros_string = write_macros();
$paths{data0} -> dispose($macros_string, $dmode);
## set the charsize and charfont
##$paths{data0} -> dispose("plot(charsize=$config{plot}{charsize}, charfont=$config{plot}{charfont})", $dmode);
$paths{data0} -> dispose("startup", $dmode);


&set_recent_menu;

splash_message("Ready to start...");
$top -> update;
$splash -> Destroy;

&clean_old_trap_files;
&initialize_project(1);

Echo($About_Ifeffit);
$top -> after(2000, [\&Echo, "Artemis may be freely redistributed under the terms of its license."]);
$top -> after(3500, [\&Echo, "Artemis comes with absolutely NO WARRANTY."]);
if ($STAR_Parser_exists) {
  $top -> after(5500, \&show_hint);
} else {
  $top -> after(5500, [\&Echo, "You cannot import CIF files because STAR::Parser is not installed."]);
};

##&bindDump($update);

## make sure that the parameters will be updated the first time a plot
## or show is done.
$parameters_changed = 1;

my $chdir_to = Cwd::cwd || $current_data_dir || dirname($0) || $ENV{IFEFFIT_DIR};
$chdir_to = Cwd::abs_path($chdir_to);
chdir $chdir_to;

delete $config{general}{devel_greetings} if (exists $config{general}{devel_greetings});
($config{general}{greetings} = "0.0.0") unless (exists $config{general}{greetings});
my $vv = sprintf("%d.%2.2d%3.3d", split(/\./, $VERSION));
my $vg = sprintf("%d.%2.2d%3.3d", split(/\./, $config{general}{greetings}));

if ($vv > $vg) {
  #   my $text = <<EOH
  # EOH
  #   ;
  #   $text =~ s/\n/ /g;
  #   $text =~ s/\| /\n\n/g;

  #   my $greeting = $top -> Toplevel(-class=>'horae');
  #   $greeting -> protocol(WM_DELETE_WINDOW => sub{$greeting->destroy});
  #   $greeting -> iconbitmap('@'.$iconbitmap);
  #   $greeting -> title("Welcome to the new version Artemis");
  #   my $textbox = $greeting -> Scrolled('ROText',
  # 				      -scrollbars=>'oe',
  # 				      -width=>80,
  # 				      -height=>30,
  # 				      -wrap=>'word',
  # 				      -font=>'Courier 14')
  #     -> pack(-side=>'top');
  #   $textbox -> Subwidget("yscrollbar")
  #     -> configure(-background=>$config{colors}{background});
  #   $textbox -> insert('end', $text);
  #   $greeting -> Button(-text=>'OK', -command=>sub{$greeting->destroy})
  #     -> pack(-side=>'bottom');
  #   $greeting -> waitWindow;

  $config{general}{greetings} = $VERSION;
  $config_ref -> WriteConfig($personal_rcfile);
};


## if ($is_windows) {
##   open PARID, ">".$paths{data0} -> find('artemis', 'par');
##   print PARID $ENV{PAR_TEMP}, $/;
##   close PARID;
## };


$top -> update;
my $w = $mru{geometry}{uwidth} || 600;
my $h = $mru{geometry}{uheight} || 300;
$update->geometry(join("x", $w, $h));

my @geom = split(/[+x]/, $top->geometry);
## if (exists $mru{geometry}{uheight}) {
##   my $w = ($mru{geometry}{uwidth}  > $geom[0]) ? $mru{geometry}{uwidth}  : $geom[0];
##   my $h = ($mru{geometry}{uheight} > $geom[1]) ? $mru{geometry}{uheight} : $geom[1];
##   $top->geometry(join("x", $w, $h));
## };
my $extrabit = ($Tk::VERSION < 804) ? 30 : 0;
($extrabit = 0) if ($is_windows);
$top -> minsize($geom[0], $geom[1]+$extrabit);
$top -> update;
if (exists $mru{geometry}{'x'}) {
  my $location = "+" . $mru{geometry}{'x'} . "+" . $mru{geometry}{'y'};
  #$mru{geometry}{height} . "x" . $mru{geometry}{width} .
  $top -> geometry($location);
};
if (exists $mru{geometry}{width}) {
  my $size = $mru{geometry}{width} . "x" . $mru{geometry}{height};
  $top -> geometry($size);
};

$top -> update;


$fat -> pack(-expand => 0);
$fat -> packPropagate(0);
$skinny2 -> packPropagate(0);


# else {
## the next line serves to make the DPL a bit wider
##$top -> geometry(sprintf("%dx%d",$config{geometry}{window_multiplier}*$geom[0], $geom[1]+$extrabit));
##};

$top -> resizable(1,1);
$top -> deiconify;
$top -> raise;


## read a project specified from the command line or an actuve
## autosave file
my $response = 'No';
if (-e $autosave_filename) {
  my $message = "Artemis found an autosave file, perhaps from a previous failure of Artemis.  Would you like to import it?";
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => $message,
		   -title          => 'Artemis: Import autosave file?',
		   -buttons        => [qw/Yes No/],
		   -default_button => 'Yes',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  $response = $dialog->Show();
};
if ($response eq 'Yes') {
  Echo("Importing autosave file ...");
  my $save_cdd = $current_data_dir;
  ##&dispatch_mru($autosave_filename, 0);
  &dispatch_read_data(0, $autosave_filename, 0);
  $current_data_dir = $save_cdd;
  $project_name = "";
  Echo("Importing autosave file ... done!");
} elsif ($ARGV[0]) {
  Echo("Processing filename from command line");
  if ($ARGV[0] =~ /^-(\d+)$/) {
    &dispatch_mru($mru{mru}{$1});
  } elsif (-e $ARGV[0]) {
    my $arg = ($ARGV[0] =~ /^[\~\/]/) ? $ARGV[0] : File::Spec->catfile(Cwd::cwd, $ARGV[0]);
    $top -> after(500, sub{read_data(0, $arg)});
    #($project_name = $arg) if (&dispatch_mru($arg) eq "project");
  };
};


MainLoop();

