## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2009 Bruce Ravel
##



BEGIN {
  ##   ## make sure the pgplot environment is sane...
  ##   ## these defaults assume that the pgplot rpm was installed
  ##   $ENV{PGPLOT_DIR} ||= '/usr/local/share/pgplot';
  ##   $ENV{PGPLOT_DEV} ||= '/XSERVE';

  use Tk;
  die "Athena requires Tk version 800.022 or later\n"  if ($Tk::VERSION < 800.022);
  #require Ifeffit;
  #die "Athena requires Ifeffit.pm version 1.2 or later\n" if ($Ifeffit::VERSION < 1.2);
  #import Ifeffit qw/ifeffit get_array put_array/;
  use Ifeffit qw(ifeffit get_array put_array);
  ifeffit("\&screen_echo = 0\n");
};

use strict;
use warnings;
#use diagnostics;
#use Config;
## need to explicitly state all Tk modules used for the sake of PAR
use Tk::widgets qw(Wm FileSelect FBox Frame NoteBook FileDialog Checkbutton
                   Menu Menu/Item Menubutton Canvas Radiobutton Text Balloon
		   Optionmenu Bitmap Dialog ROText TextUndo Pane Entry Label
		   FireButton NumEntryPlain NumEntry LabFrame
		   Pod Pod/Text Pod/Search Pod/Tree More DirTree
		   Splashscreen Photo waitVariableX ColorEditor
		   KeyEntry RetEntry BrowseEntry HList DialogBox);
### wtf?!?!  PerlApp needs these lines:
use Tk::Pod;
use Tk::TextUndo;
use Tk::FileDialog;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Chemistry::Elements qw(get_Z get_symbol);
use Chemistry::Formula qw(parse_formula);
use Config::IniFiles;
use Compress::Zlib;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;
use Ifeffit::Files;
use Ifeffit::Group;
use Ifeffit::Tools;
use Math::Combinatorics;
use Safe;
use Spreadsheet::WriteExcel;
use Text::Glob qw(glob_to_regex);
use Text::Wrap;
use Tie::IxHash;
use Time::Stopwatch;
use Xray::FluorescenceEXAFS;

use constant PI    => 3.14159265358979323844;
use constant HBARC => 1973.27053324;
use constant EPSI  => 0.00001;
use constant ETOK  => 0.262468292;

$Data::Dumper::Indent = 0;


my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
my $is_darwin  = (lc($^O) eq 'darwin');
my $always_false = 0;


my $absorption_exists = (eval "require Xray::Absorption");
($absorption_exists) and eval "require Ifeffit::Elements";
my $lwp_exists = (eval "require LWP::Simple;");
import LWP::Simple if $lwp_exists;

## use Text::Abbrev;
## my $abbrev_table;
## &make_abbrev_table;

my %groups    = ();		# linked hashes connecting groups,
my %menus     = ();		# parameters, and widgets
my %marked    = ();
my %header    = ();
my %grab      = ();
my %plotcard  = ();
my $list;
my $plotsel;
my $last_plot = "";
my $last_plot_params;
my @indicator;
my %pointfinder;
my %old_cols;
my @echo_history = ();
## history buffers for use with get_string
my @regex_history = ();   # mark_regex buffer
my @rename_history = ();  # rename group buffer
my $colsel_geometry = "";
$| = 1;
my @done = (" ... done!", 1);
my $current = 0;
my $current_group;
my $current_file = "";
my $current_data_dir = Cwd::cwd || $ENV{IFEFFIT_DIR} || $ENV{HOME};
my $project_name = "";
my $VERSION = "0.8.059";
my $mouse_over_cursor = 'mouse';
## need to know if the version of ifeffit is current enough to have the
## sort argument to read_data
my $ifeffit_version = (split(" ", Ifeffit::get_string("\$&build")))[0];
my $echo_pause = 150; # time in miliseconds to pause before echoing
my %key_data;
&set_key_data;

my $prior_string = "";
my $prior_args = {old	      => "",
		  numerator   => "",
		  denominator => "",
		  do_ln	      => "",
		  invert      => "",
		  space	      => "",
		  evkev	      => "",
		  is_xmudat   => "",
		  sort	      => "",
		  multi	      => "",
		  ref	      => "",
		  sorted      => ""
		 };

my $vstr = Ifeffit::Tools->vstr;
my $sort_available = ($vstr > 1.0066);
if ($vstr < 1.0076) {
  my $top = MainWindow->new();
  $top -> withdraw();
  my $message = "This version of Athena requires Ifeffit 1.0076 or later.

You can get the latest Ifeffit from http://cars.uchicago.edu/ifeffit.

If you have recently upgraded Ifeffit, you should also rebuild Athena and Artemis.
";
  my $dialog =
    $top -> Dialog(-bitmap         => 'error',
		   -text           => $message,
		   -title          => 'Athena: Exiting...',
		   -buttons        => [qw/OK/],
		   -default_button => 'OK');
  my $response = $dialog->Show();
  exit;
};

unless ($VERSION eq $Ifeffit::Group::VERSION) {
  my $top = MainWindow->new();
  $top -> withdraw();
  my $grouppm = $INC{'Ifeffit/Group.pm'};
  my $message = "Athena appears to be installed incorrectly.

The main program and the Ifeffit/Group.pm module have different version numbers.

main program: $0
Group.pm: $grouppm
";
  my $dialog =
    $top -> Dialog(-bitmap         => 'error',
		   -text           => $message,
		   -title          => 'Athena: Exiting...',
		   -buttons        => [qw/OK/],
		   -default_button => 'OK');
  my $response = $dialog->Show();
  exit;
};
my $About = "Athena $VERSION  © 2001-2008 Bruce Ravel  <bravel\@anl.gov>  NO warranty, see license for details";




## global variables for setup and accessing Ifeffit::Group methods
my $line_count = -2; # set this to -1 if "Default Parameters" is included
my $group_count = 0;
my $setup = Ifeffit::Group -> new(line=>$line_count, file=>"");
my $dmode = 5;
## ==== DEBUG =====
## $dmode += 16;
## $dmode += 32;
## ==== DEBUG =====
my $use_default = 0;

## Turn this on to see the demonstration of adding a new analysis mode
## to Athena.  This will put an entry in the Analysis menu labeled
## "Foobaricate"
my $demo_page = 0;

## a couple of global variables to facilitate changing between
## different data analysis views.  these are set when a view is
## displayed and unset when the normal view returns
my $fat_showing = 'normal';	# the currently displayed view
my $which_showing;
my $hash_pointer;		# a pointer to an array of parameters
                                #  needed to make the plot specific to
                                #  the current view

## global variables for keeping track of current state
my $reading_project = 0;
my $project_saved = 1;
my %preprocess = (standard=>'None', standard_lab=>'None', ok => 0,
		  deg_do => 0, trun_do => 0, trun_beforeafter => 'after',
		  int_do => 0, al_do => 0, par_do=>0, mark_do=>0);
my %lcf_data = ();
my %mee_energies = ();

## the maximum amount of heap space in Ifeffit as we begin our work.
## This will be used in the memory check each time a group is read in.
my $max_heap = Ifeffit::get_scalar("\&heap_free") || -1;


use vars qw/@ifeffit_buffer @macro_buffer/;
@ifeffit_buffer = ();
@macro_buffer   = ();

$groups{"Default Parameters"} = Ifeffit::Group -> new(line=>$line_count, file=>"",
						      group=>"Default Parameters");


## set up main window and post splashscreen
my $top = MainWindow->new(-class=>'horae');
$top -> withdraw;
$top -> optionAdd('*font', 'Helvetica 14 bold');
$top -> optionAdd('*font', 'Helvetica 10 bold');
my $splash_background = 'cornsilk3';
my $splash = $top->Splashscreen(-background => $splash_background);
my $splash_image = $top -> Photo(-file => $groups{"Default Parameters"} -> find('athena', 'logo'));
$splash -> Label(-image=>$splash_image, -background => $splash_background)
  -> pack(qw/-fill both -expand 1 -padx 0 -pady 0 -side left/);
my $splash_frame = $splash -> Frame(-background => $splash_background,)
  -> pack(qw/-fill both -expand 1 -padx 0 -pady 0 -side right/);
$splash_frame -> Label(-text       => "Athena\nversion $VERSION",
		       -background => $splash_background,
		       -width      => 20,
		       -font       => 'Helvetica 14 bold',)
  -> pack(qw/-fill both -expand 1/);
my $splash_status =   $splash_frame -> Label(-text       => q{},
					     -background => $splash_background,
					     -font       => 'Helvetica 10 bold',
					     -justify    => 'left',
					     -borderwidth=> 2,
					     -relief     => 'ridge')
  -> pack(-anchor=>'w', -fill=>'x');
$splash -> Splash;
$top -> update;


## ---------------------------------------------------------------------
## establish .horae space
&Ifeffit::Tools::initialize_horae_space;

## ---------------------------------------------------------------------
## add document location to the Pod path
my $poddir = $groups{"Default Parameters"} -> find('athena', 'augpod');
Tk::Pod->Dir($poddir);

## ---------------------------------------------------------------------
## read configuration files:

splash_message("Importing configuration files");
&convert_config_files;

my (%plot_features, @op_text);
my $dummy_rcfile = $groups{"Default Parameters"} -> find('athena', 'rc_dummy');
open I, ">".$dummy_rcfile; print I "[general]\ndummy_parameter=1\n"; close I;
my $system_rcfile = $groups{"Default Parameters"} -> find('athena', 'rc_sys');
my $personal_rcfile = $groups{"Default Parameters"} -> find('athena', 'rc_personal');
my $personal_version = $groups{"Default Parameters"} -> find('athena', 'version_marker');

## config values hardwired in the code
my %default_config;
tie %default_config, 'Config::IniFiles', ();
&default_rc(\%default_config); # set defaults
my $default_config_ref = tied %default_config;
$default_config_ref -> SetFileName($dummy_rcfile);

## system-wide rc file (but check to see that it exists...
my %system_config;
tie %system_config, 'Config::IniFiles', (-file=>$system_rcfile, -import=>$default_config_ref)
  if -e $system_rcfile;;

## if the user does not have a personal rc file, create one
if ((! -e $personal_rcfile) or (-z $personal_rcfile)) {
  open I, ">".$personal_rcfile;
  print I "[general]\ndummy_parameter=1\n";
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
    print I "[general]\ndummy_parameter=1\n";
    close I;
    tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$system_config_ref );
  };
} else {			# else import the default
  tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$default_config_ref);
  unless (tied %config) {
    open I, ">".$personal_rcfile;
    print I "[general]\ndummy_parameter=1\n";
    close I;
    tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$default_config_ref );
  };
};
delete $config{general}{dummy_parameter};
my $config_ref = tied %config;
## I have trouble keeping config files up to date when I build the
## windows versions.  the dark red and dark purple are really
## illegible on windows!
if ($is_windows) {
  ($config{colors}{single} eq 'red4')       and ($config{colors}{single} = 'red2');
  ($config{colors}{marked} eq 'darkviolet') and ($config{colors}{marked} = 'mediumorchid');
};
$config_ref -> WriteConfig($personal_rcfile);
unlink $dummy_rcfile;


foreach my $fonttype (keys %{ $config{fonts} }) {
  $top -> optionAdd('*font', $config{fonts}{$fonttype});
};
$top -> optionAdd('*font', $config{fonts}{med});

$config{list}{real_x1} = $config{list}{x1} || 0.8;
$config{list}{real_x2} = $config{list}{x2} || 0.85;
$config{list}{real_y}  = $config{list}{y}  || 0.86;

if ($config{general}{listside} eq 'right') {
  $config{general}{fatside}='left';
} else {
  $config{general}{fatside}='right';
};
## a bit of backwards compatibility for 0.8.010 (this can no longer be 'd')
if (lc($config{plot}{e_marked}) !~ /[en]/) {$config{plot}{e_marked} = 'n'};
## a bit of backwards compatibility for 0.8.050 (half changed to fraction)
if (lc($config{bkg}{e0}) eq "half") {$config{bkg}{e0} = 'fraction'};


my %rebin = (do_rebin => 0,
	     emin     => $config{rebin}{emin},
	     emax     => $config{rebin}{emax},
	     pre      => $config{rebin}{pre},
	     xanes    => $config{rebin}{xanes},
	     exafs    => $config{rebin}{exafs},
	     abs      => "");

$config{general}{quit_query} ||= 'No';

map { $plot_features{$_} = $config{plot}{$_} } (keys %{$config{plot}});
$plot_features{suppress_markers} = 0;
$plot_features{linestyle} = "lines";

$Ifeffit::Group::rmax_out = $config{fft}{rmax_out};

foreach (qw(slight weak medium strong rigid)) {
  $groups{"Default Parameters"} -> set_clamp(ucfirst($_), $config{clamp}{$_});
};


splash_message("Importing recent files list");


## ---------------------------------------------------------------------
## open and read most recently used (MRU) file
my $mrufile = $groups{"Default Parameters"} -> find('athena', 'mru');
# touch an empty file if needed
unless (-e $mrufile) {open M, ">".$mrufile; print M "[mru]\n"; close M};
my %mru;
tie %mru, 'Config::IniFiles', ( -file => $mrufile );
foreach my $i (1 .. $config{general}{mru_limit}) {
  exists $mru{mru}{$i} or ($mru{mru}{$i} = "");
};

$current_data_dir = $mru{config}{last_working_directory}
  if ($config{general}{remember_cwd});


splash_message("Importing plot styles");

## ---------------------------------------------------------------------
## plot_styles
unless (-e $groups{"Default Parameters"} -> find('athena', 'plotstyles')) {
  open P, ">".$groups{"Default Parameters"} -> find('athena', 'plotstyles') or die "could not open plst file";
  print P <<EOH
[default]
emin=-200
emax=800
e_mu=m
e_mu0=
e_norm=
e_pre=p
e_post=t
e_der=
e_marked=n
kmin=0
kmax=15
k_marked=1
k_w=2
k_win=0
rmin=0
rmax=6
r_mag=m
r_env=0
r_re=0
r_im=0
r_pha=0
r_win=0
r_marked=rr
qmin=0
qmax=15
q_mag=0
q_env=0
q_re=r
q_im=0
q_win=0
q_marked=qr
EOH
  ;
##   foreach my $k (keys %plot_features) {
##     next unless ($k =~ /^[ekqr](_|ma|mi)/);
##     print P "$k = $plot_features{$k}\n";
##   };
  close P
};
my %plot_styles;
tie %plot_styles, 'Config::IniFiles', (-file=>$groups{"Default Parameters"} -> find('athena', 'plotstyles'));

## ---------------------------------------------------------------------
## establish web download directory
my $webdir = $groups{"Default Parameters"} -> find('other', 'downloads');
my @web_buffer = ();

splash_message("Initializing stash directory");

## ---------------------------------------------------------------------
## establish stash directory
&stash_directory;
my $stash_dir = $groups{"Default Parameters"} -> find('other', 'stash');
my $trapfile = File::Spec->catfile($stash_dir, "ATHENA.TRAP");


my %click_help =
  ('File:'		  => "The file name from which these data were read",
   'Name:'                => "The name used internally in Ifeffit for this group",
   'E0:'		  => "The edge energy of this scan (absolute energy).  This is typically about half-way up the edge.",
   'E shift:'		  => "The energy alignment shift, which is applied to the data before any other processing chores begin",
   'Edge step:'		  => "The height of the edge step, normally found by the background removal but may be set by hand and fixed",
   'Rbkg:'		  => "The R-space cutoff between the background and the data.  Half the first peak distance is a good first stab.",
   'k-weight:'		  => "The k-weight used in the background removal.  1, 2, and 3 are typical values.",
   'arbitrary k-weight:'  => "The k-weight used to plot in k, R, or q when the \"kw\" plot button is checked.",
   'dk:'		  => "The window sill width used in background removal or FT.  1 to 3 inv. Ang is a typical value.",
   'window type:'	  => "The functional form of the Fourier transform window",
   'Pre-edge range:'	  => "The range in energy of the pre-edge line regression (relative units) (typically about -200 to -30 eV)",
   'Normalization range:' => "The range of the post-edge normalization (relative units) (typically 100 eV to near the end of the data)",
   'Normalization order:' => "The order of the polynomial regressed to normalize and flatten the data (1=constant, 2=line, 3=quadratic)",
   'Spline range:'	  => "The range in over which the background spline is fit (typically about 1 inv. Ang. to the end of the data)",
   'k:'			  => "The background spline range in inverse Angstroms.  0 or 1 until the end of the data is typical.",
   'E:'			  => "The background spline range in relative energy.  0 or a few volts above the edge to the end of the data is typical.",
   'k-range:'		  => "The range of the forward Fourier transform in inverse Angstroms.  This should cover the reliable data range.",
   'dr:'		  => "The width of the window sill used in the backwards FT.  A half to one Angstrom is a typical value.",
   'R-range:'		  => "The range of the backward Fourier transform in Angstroms.  This should cover the peaks to back transform.",
   'Standard:'            => "The group to use as a background removal standard (this is usually None or a chi.dat file from Feff)",
   'plot multiplier:'     => "The data in this group will be multiplied by this amount in most plots",
   'y-axis offset:'       => "The amount of vertical displacement when plotting this group",
   'Background:'          => "Choose AUTOBK or Cromer-Liberman for normalizing the data and isolating chi(k)",
   'Z:'                   => "The atomic symbol of the central atom, needed for CL normalization and phase correction",
   'Edge:',               => "The absorption edge of the data, needed for phase corrected Fourier transforms",
   'Phase correction:'    => "Subtract the central atom phase shift from the data before Fourier transforming",
   'Spline clamps:'       => "Restrain the ends of the background spline by clamping to the data",
   'low:'                 => "Apply a clamp to the low end of the background spline (None is the default)",
   'high:'                => "Apply a clamp to the high end of the background spline (Strong is a good default)",
   'Importance:'          => "The weight of this group relative to other groups included in a merge",
   #'Nclamp:'              => "The number of points to include in the clamping restraint",
  );

## command completion in the ifeffit buffer
use Text::Abbrev;
my %abbrevs = abbrev qw(chi_noise color comment cursor def echo erase
			exit feffit ff2chi fftf fftr findee guess
			history load macro minimize newplot path pause
			plot pre_edge print quit read_data rename
			reset restore save set show spline sync
			write_data zoom @all @arrays @commands @group
			@macros @path @scalars @strings @variables );

splash_message("Importing hints file");

my $hint_file = $groups{"Default Parameters"} -> find('athena', 'hints');
my @hints = ();
my $hint_n;
if (-e $hint_file) {
  open HINT, $hint_file or die "could not open hint file $hint_file for reading\n";
  while (<HINT>) {
    next if (/^\s*($|\#)/);
    chomp;
    push @hints, $_;
  };
  srand;
  $hint_n = int(rand $#hints);
  close HINT;
};

## import multi-electron data
my $system_mee = $groups{"Default Parameters"} -> find('athena', 'system_mee');
my $mee_file   = $groups{"Default Parameters"} -> find('athena', 'mee');
copy($system_mee, $mee_file) if (not -e $mee_file);
my %system;
tie %system, 'Config::IniFiles', (-file=>$system_mee);
my $system_ref = tied %system;
tie %mee_energies, 'Config::IniFiles', (-file=>$mee_file, -import=>$system_ref);




## ---------------------------------------------------------------------
# 


splash_message("Creating key bindings");

#$top -> configure(-font		       => $config{fonts}{small});
$top -> setPalette(-font	       => $config{fonts}{small},
		   foreground	       => $config{colors}{foreground},
		   background	       => $config{colors}{background},
		   activeBackground    => $config{colors}{activebackground},
		   disabledForeground  => $config{colors}{disabledforeground},
		   disabledBackground  => $config{colors}{background},
		   highlightColor      => $config{colors}{highlightcolor},
		   -highlightthickness => 4);
$top -> protocol(WM_DELETE_WINDOW => \&quit_athena);
##my $detached_plot = $top -> Toplevel(-title=>'Athena: detached plot buttons', -class=>'horae');
##$detached_plot -> withdraw;
my $replace;
my $b_frame;			# frame to hold plotting buttons

$top -> title('Athena');
$top -> iconname('Athena');
#my $iconbitmap = $groups{"Default Parameters"} -> find('athena', 'xpm');
#$top -> iconbitmap('@'.$iconbitmap);
my $iconimage = $top -> Photo(-file => $groups{"Default Parameters"} -> find('athena', 'xpm'));
$top -> iconimage($iconimage);

$top -> bind('<Control-a>'     => sub{mark('all')});
$top -> bind('<Control-b>'     => \&about_group);
$top -> bind('<Control-B>'     => sub{about_marked_groups(\%marked)});
$top -> bind('<Control-f>'     => sub{freeze('this')});
$top -> bind('<Control-F>'     => sub{freeze('all')});
$top -> bind('<Control-h>'     => \&show_hint);
$top -> bind('<Control-i>'     => sub{mark('toggle')});
$top -> bind('<Control-j>'     => \&current_down);
$top -> bind('<Control-k>'     => \&current_up);
$top -> bind('<Control-l>'     => \&get_new_name);
$top -> bind('<Control-m>'     => sub{pod_display("index.pod")});
$top -> bind('<Control-M>'     => sub{freeze('marked')});
#$top -> bind('<Control-n>'     => sub{mark('none')});
$top -> bind('<Control-o>'     => sub{&read_file(0)});
$top -> bind('<Control-p>'     =>
	     sub{
	       if ($is_windows) {
		 Error("Print from the plotting window instead!");
	       } else {
		 &replot('print');
	       };
	     });
$top -> bind('<Control-q>'     => \&quit_athena);
$top -> bind('<Control-r>'     => sub{mark_regex(1)});
$top -> bind('<Control-R>'     => sub{freeze('regex')});
$top -> bind('<Control-s>'     => sub{&save_project("all quick")});
$top -> bind('<Control-t>'     => sub{mark('this')});
$top -> bind('<Control-T>'     => \&tie_untie_e0);
$top -> bind('<Control-u>'     => sub{mark('none')});
$top -> bind('<Control-U>'     => sub{freeze('none')});
$top -> bind('<Control-w>'     => \&close_project);
$top -> bind('<Control-y>'     => \&copy_group);
$top -> bind('<Control-0>'     => \&clear_project_name);

$top -> bind('<Meta-k>' => \&group_up);
$top -> bind('<Meta-j>' => \&group_down);
$top -> bind('<Alt-k>'  => \&group_up);
$top -> bind('<Alt-j>'  => \&group_down);
if ($Tk::VERSION < 804) {
  $top -> bind('<Meta-o>' => sub{&read_file(1)});
  $top -> bind('<Alt-o>'  => sub{&read_file(1)});
} else {
  $top -> bind('<Meta-o>' => sub{&read_file(0)});
  $top -> bind('<Alt-o>'  => sub{&read_file(0)});
};
$top -> bind('<Meta-d>' => \&Dumpit);
$top -> bind('<Alt-d>'  => \&Dumpit);

$top -> bind('<Control-period>' => \&cursor);
$top -> bind('<Control-slash>'  => \&swap_panels);
$top -> bind('<Control-minus>'  => sub{&replot('replot')});
$top -> bind('<Control-equal>'  => \&zoom);
my $multikey = "";
$top -> bind('<Control-semicolon>' => \&keyboard_plot);
$top -> bind('<Meta-semicolon>'    => \&keyboard_plot_marked);
$top -> bind('<Alt-semicolon>'     => \&keyboard_plot_marked);

## user configured, user defined key sequences (yikes!)
my $user_key = "<Control-" . $config{general}{user_key} . ">";
$top -> bind($user_key => [\&keys_dispatch, 'control']);
$user_key = "<Meta-" . $config{general}{user_key} . ">";
$top -> bind($user_key => [\&keys_dispatch, 'meta']);
$user_key = "<Alt-" . $config{general}{user_key} . ">";
$top -> bind($user_key => [\&keys_dispatch, 'meta']);
## save, so it can be unbound if changed
$user_key = $config{general}{user_key};

## What buttons look like:
my @pluck_button  = (-foreground	 => $config{colors}{highlightcolor},
		     -activeforeground	 => $config{colors}{activehighlightcolor},
		     -disabledforeground => $config{colors}{disabledhighlightcolor},
		     -background	 => $config{colors}{background},
		     -activebackground	 => $config{colors}{activebackground});
my $pluck_bitmap = '#define pluck_width 9
#define pluck_height 9
static unsigned char pluck_bits[] = {
   0x81, 0x01, 0xc3, 0x00, 0x66, 0x00, 0x3c, 0x00, 0x38, 0x00, 0x78, 0x00,
   0xcc, 0x00, 0x86, 0x01, 0x03, 0x01};
';
my $pluck_X = $top -> Bitmap('pluck', -data=>$pluck_bitmap,
			     -foreground=>$config{colors}{activehighlightcolor});
my @pluck=(-image=>$pluck_X);
my @button_list =   (-foreground         => $config{colors}{button},
		     -activeforeground	 => $config{colors}{button},
		     #-font               => $config{fonts}{small},
		     -background	 => $config{colors}{background},
		     -activebackground	 => $config{colors}{activebackground});
my @r_button_list = (-foreground         => $config{colors}{background},
		     -activeforeground	 => $config{colors}{activebackground},
		     -background	 => $config{colors}{button},
		     -activebackground	 => $config{colors}{activebutton},
		     -disabledforeground => $config{colors}{disabledforeground});
my @m_button_list = (-foreground         => $config{colors}{background},
		     -activeforeground	 => $config{colors}{activebackground},
		     -background	 => $config{colors}{mbutton},
		     -activebackground	 => $config{colors}{activembutton});
my @m2_button_list = (-foreground         => $config{colors}{mbutton},
		      -activeforeground	 => $config{colors}{mbutton},
		      -background	 => $config{colors}{background},
		      -activebackground	 => $config{colors}{activebackground});
my @label_button  = (-relief=>'flat', -borderwidth=>0,);

my @browseentry_list = (-disabledforeground => $config{colors}{foreground},
			-state              => 'readonly');
@browseentry_list = () if $is_windows;

splash_message("Creating menus");

## ============================================================================
## ============================================================================
## menubar
$top -> configure(-menu=> my $menubar = $top->Menu(-relief=>'ridge'));



## --------------------------------------------------------------------
## The following 2 arrays will contain group and editing menus for
## use in the right-click menu and in various menubars.  They are set
## as global variables in &set_menus.
my (@edit_menuitems, @group_menuitems, @values_menuitems);
set_menus();

## --------------------------------------------------------------------
## Set up the right-click menu
my $group_menu = $top -> Menu(-tearoff=>0);
$group_menu ->
  cascade(-label=>"Plot this group ...", -tearoff=>0,
	  -menuitems=>[[ command => "in energy",  -command => \&plot_current_e],
		       [ command => "in k space", -command => \&plot_current_k],
		       [ command => "in R space", -command => \&plot_current_r],
		       [ command => "in q space", -command => \&plot_current_q, #,
		       ]]);

$group_menu ->
  cascade(-label=>"Plot marked groups ...", -tearoff=>0,
	  -menuitems=>[[ command => 'in energy',  -command => \&plot_marked_e],
		       [ command => 'in k-space', -command => \&plot_marked_k],
		       [ command => 'in R-space', -command => \&plot_marked_r],
		       [ command => 'in q-space', -command => \&plot_marked_q, #,
		       ],
		      ]);
$group_menu -> separator(-background=>$config{colors}{background});
my $right_group = $group_menu-> cascade(-label=>"Group actions",
					-tearoff=>0, @group_menuitems);
my $right_values = $group_menu-> cascade(-label=>"Parameter values",
					 -tearoff=>0, @values_menuitems);
$top -> update;

## --------------------------------------------------------------------
## Set up the various menubar menus
my @menu_args = (-foreground       => $config{colors}{foreground},
		 -background       => $config{colors}{background},
		 -activeforeground => $config{colors}{activebutton},); # -font =>


## File menu
##  &read_file recognizes raw data, records, and/or projects
my $file_menu =
  $menubar -> cascade(-label=>'~File', @menu_args,
		      -menuitems=>[[ command =>($Tk::VERSION < 804) ? 'Open file' : 'Open file(s)',
				    -accelerator=>'Ctrl-o',
				    -command =>[\&read_file, 0]],
				   (($Tk::VERSION < 804)
				    ? ([ command =>'Open many files', -accelerator=>'Alt-o',
					 -command =>[\&read_file, 1]],)
				    : ()),
				   [ cascade =>'Recent files', -tearoff=>0],
				   #[ command =>'Open URL',
				   # -command => \&fetch_url,
				   # -state   => 'disabled'],
				    ##-state   => ($lwp_exists) ? "normal" : 'disabled'],
				   #['command'=>'Open SPEC file', -state=>'disabled'],
				   "-",
				   [ command => 'Save entire project', -accelerator=>'Ctrl-s',
				    -command => [\&save_project, 'all quick']],
				   [ command => 'Save entire project as ...',
				    -command => [\&save_project, 'all']],
				   [ command => 'Save marked groups as a project ...',
				    -command => [\&save_project, 'marked']],
				   "-",
				   [ command => 'Save mu(E)',    -command => [\&save_chi, 'e']],
				   [ command => 'Save norm(E)',  -command => [\&save_chi, 'n']],
				   #[ command => 'Save deriv(E)', -command => [\&save_chi, 'd']],
				   [ cascade => 'Save chi(k)',
				    -tearoff => 0,
				    -menuitems => [[ command => "chi(k)",
						    -command => [\&save_chi, 'k']],
						   [ command => "k*chi(k)",
						    -command => [\&save_chi, 'k1']],
						   [ command => "k^2*chi(k)",
						    -command => [\&save_chi, 'k2']],
						   [ command => "k^3*chi(k)",
						    -command => [\&save_chi, 'k3']],
						   [ command => "chi(e)",
						    -command => [\&save_chi, 'ke']],
						  ]],
				   [ command => 'Save chi(R)',   -command => [\&save_chi, 'R']],
				   [ command => 'Save chi(q)',   -command => [\&save_chi, 'q']],
				   "-",
				   [ cascade   => 'Save marked groups to a file as',
				    -tearoff   => 0,
				    -menuitems => [[ command => 'mu(E)',
						    -command => [\&save_marked, 'e']],
						   [ command => 'norm(E)',
						    -command => [\&save_marked, 'n']],
						   [ command => 'deriv mu(E)',
						    -command => [\&save_marked, 'd']],
						   [ command => 'deriv norm(E)',
						    -command => [\&save_marked, 'nd']],
						   "-",
						   [ command => 'chi(k)',
						    -command => [\&save_marked, 'k']],
						   [ command => 'k*chi(k)',
						    -command => [\&save_marked, 'k1']],
						   [ command => 'k^2*chi(k)',
						    -command => [\&save_marked, 'k2']],
						   [ command => 'k^3*chi(k)',
						    -command => [\&save_marked, 'k3']],
						   "-",
						   [ command => '|chi(R)|',
						    -command => [\&save_marked, 'rm']],
						   [ command => 'Re[chi(R)]',
						    -command => [\&save_marked, 'rr']],
						   [ command => 'Im[chi(R)]',
						    -command => [\&save_marked, 'ri']],
						   "-",
						   [ command => '|chi(q)|',
						    -command => [\&save_marked, 'qm']],
						   [ command => 'Re[chi(q)]',
						    -command => [\&save_marked, 'qr']],
						   [ command => 'Im[chi(q)]',
						    -command => [\&save_marked, 'qi']],
						  ]],
				   [ cascade   => 'Save each marked group as',
				    -tearoff   => 0,
				    -menuitems => [[ command => 'mu(E)',
						    -command => [\&save_each, 'e']],
						   [ command => 'norm(E)',
						    -command => [\&save_each, 'n']],
						   ##[ command => 'deriv mu(E)',
						   ## -command => [\&save_each, 'd']],
						   ##[ command => 'deriv norm(E)',
						   ## -command => [\&save_each, 'nd']],
						   "-",
						   [ command => 'chi(k)',
						    -command => [\&save_each, 'k']],
						   [ command => 'k*chi(k)',
						    -command => [\&save_each, 'k1']],
						   [ command => 'k^2*chi(k)',
						    -command => [\&save_each, 'k2']],
						   [ command => 'k^3*chi(k)',
						    -command => [\&save_each, 'k3']],
						   [ command => 'chi(E)',
						    -command => [\&save_each, 'ke']],
						   "-",
						   [ command => 'chi(R)',
						    -command => [\&save_each, 'R']],
						   [ command => 'chi(q)',
						    -command => [\&save_each, 'q']],
						  ]],
				   "-",
				   [ command => "Clear project name", -accelerator=>'Ctrl-zero',
				    -command => \&clear_project_name],
				   "-",
				   [ command => "Close project", -accelerator=>'Ctrl-w',
				    -command => \&close_project],
				   [ command => 'Quit', -accelerator=>'Ctrl-q',
				    -command => \&quit_athena]
				  ]);

## Edit menu (need to disable some when Defaults are current)
$menubar -> cascade(-label=>'~Edit', @menu_args, @edit_menuitems);

## Group menu (need to disable some when Defaults are current)
my $group_menubutton = $menubar
  -> cascade(-label=>'~Group', @menu_args, @group_menuitems);

## Values menu (need to disable some when Defaults are current)
my $values_menubutton = $menubar
  -> cascade(-label=>'~Values', @menu_args, @values_menuitems);

$menubar -> separator;


## ## vertical separator
## $menubar -> Frame(-width=>2, -borderwidth=>2, -relief=>'sunken') ->
##   pack(-side=>'left', -fill=>'y', -pady=>2);

## Plot menu (need to disable some of these when Defaults are displayed in fat)
my $plot_menu;
my @plot_menuitems = ();

push @plot_menuitems,
  [ command => 'Zoom',   -accelerator => 'Ctrl-=', -command => \&zoom],
  [ command => 'Unzoom', -accelerator => 'Ctrl--', -command => [\&replot, 'replot']],
  [ command => 'Cursor', -accelerator => 'Ctrl-.', -command => \&cursor],
  '-',
  [ command => 'Plot merge+std.dev.', -state=>'disabled',
   -command => sub{my $group = $groups{$current}->{group};
		   my $space = $groups{$current}->{is_merge};
		   &plot_merge($group, $space);
		 }],
  [ command => 'Plot mu(E) + I0', -state=>'disabled',
   -command => [\&plot_i0, 1]],
  [ command => 'Plot I0', -state=>'disabled',
   -command => [\&plot_i0, 0]],
  [ command => 'Plot I0, marked', -state=>'normal',
   -command => \&plot_i0_marked],
  "-";

my %image_formats = (gif   => "GIF (landscape)",
		     vgif  => "GIF (portrait)",
		     png   => "PNG (landscape)",
		     vpng  => "PNG (portrait)",
		     tpng  => "PNG (transparent)",
		     ps	   => "B/W Postscript (landscape)",
		     cps   => "Color Postscipt (landscape)",
		     vps   => "B/W Postscript (portrait)",
		     vcps  => "Color Postscipt (portrait)",
		     latex => "LaTeX picture environment",
		     ppm   => "PPM (landscape)",
		     vppm  => "PPM (portrait)",
		     		    );
my @format_list;
foreach my $f ( split(" ", Ifeffit::get_string('plot_devices')) ) {
  next if (lc($f) =~ /(aqt|cgw|null|gw|x(window|serve))/);
  my $format = substr($f,1);
  $image_formats{$format} ||= $format;
  push @format_list, [command =>$image_formats{$format}, -command  =>[\&replot, $f]];
};
push @plot_menuitems,
  [cascade=>"Save image as ...", -tearoff=>0,
   -state=>(@format_list) ? 'normal' : 'disabled',
   @group_menuitems, -menuitems=>\@format_list];
##(@format_list) or $image_save -> configure(-state=>'disabled');
push @plot_menuitems,
  [ command     => 'Print last plot',
   -accelerator => 'Ctrl-p',
   -command     => [\&replot, 'print'],
   -state       => ($is_windows)?'disabled':'normal'];
# push @plot_menuitems, [ command => 'Detach plot buttons',
# 		       -command => \&detach_plot]
#   unless ($is_windows);

my $groupreplot = $config{general}{groupreplot};
push @plot_menuitems,
  "-",
  [ cascade => "Group replot", -tearoff=>0,
    -menuitems=>[
		 [ radiobutton  => 'none',
		   -selectcolor => $config{colors}{single},
		   -variable    => \$groupreplot,
		   -command     => sub{$config{general}{groupreplot}='none'},
		 ],
		 [ radiobutton  => 'E',
		   -selectcolor => $config{colors}{single},
		   -variable    => \$groupreplot,
		   -command     => sub{$config{general}{groupreplot}='e'},
		 ],
		 [ radiobutton  => 'k',
		   -selectcolor => $config{colors}{single},
		   -variable    => \$groupreplot,
		   -command     => sub{$config{general}{groupreplot}='k'},
		 ],
		 [ radiobutton  => 'R',
		   -selectcolor => $config{colors}{single},
		   -variable    => \$groupreplot,
		   -command     => sub{$config{general}{groupreplot}='r'},
		 ],
		 [ radiobutton  => 'q',
		   -selectcolor => $config{colors}{single},
		   -variable    => \$groupreplot,
		   -command     => sub{$config{general}{groupreplot}='q'},
		 ],
		]];



$plot_menu = $menubar -> cascade(-label=>'~Plot', @menu_args,
				 -menuitems=>\@plot_menuitems);
#($Tk::VERSION >= 804) and $plot_menu->menu->entryconfigure(14, -state=>'disabled');



## Mark menu
my $mark_menu = $menubar ->
  cascade(-label=>'Mark', @menu_args, -underline=>2,
	  -menuitems=>[[ command => 'Mark all groups',          -accelerator => 'Ctrl-a',
			-command => sub{mark('all')}],
		       [ command => 'Invert marks',             -accelerator => 'Ctrl-i',
			-command => sub{mark('toggle')}],
		       [ command => 'Clear all marks',          -accelerator => 'Ctrl-u',
			-command => sub{mark('none')}],
		       [ command => "Toggle this group's mark", -accelerator => 'Ctrl-t',
			-command => sub{mark('this')}],
		       [ command => "Mark regex",               -accelerator => 'Ctrl-r',
			-command => sub{mark('regex')}],
		       [ command => "Unmark regex",
		        -command => sub{mark('unregex')}],
		      ]);

## ## vertical separator
## $menubar -> Frame(-width=>2, -borderwidth=>2, -relief=>'ridge') ->
##   pack(-side=>'left', -fill=>'y', -pady=>2);

$menubar -> separator;

## Data munging menu
#my $flatten = $config{bkg}{flatten};
my $data_menu = $menubar ->
  cascade(-label=>'~Data', @menu_args,
	  -menuitems=>[[command => "Calibrate energies",       -command => \&calibrate],
		       [command => 'Align scans',              -command => sub{&align_two($config{align}{align_default})}],
		       [command => "Calibrate dispersive XAS", -command => \&pixel, -state   => ($config{pixel}{do_pixel_check}) ? 'normal' : 'disabled', ],
		       [command => 'Deglitch',	               -command => \&deglitch_palette],
		       [command => 'Truncate',	               -command => \&truncate_palette],
		       [command => 'Rebin mu(E)',	       -command => \&rebin],
		       [command => 'Smooth mu(E)',	       -command => \&smooth],
		       [command => 'Convolute mu(E)',          -command => \&convolve],
		       [command => 'Self Absorption',          -command => \&sa],
		       [command => 'MEE correction',           -command => \&mee, -state => ($config{mee}{enable}) ? 'normal' : 'disabled', ],
		       ##[command => 'Dead time',	             -state   => 'disabled'],
		       ##"-",
		       ##[command => 'How many spline knots?', -command=>sub{Echo(&nknots)}xb,
		       ## -state=>'disabled'],
		      ]);


## Alignment menu
# my $align_menu = $menubar ->
#   cascade(-label=>'~Align', @menu_args,
# 	  -menuitems=>[[ command => 'Align scans',
# 		        -command => sub{&align_two($config{align}{align_default})}],
# 		       [ command => "Calibrate dispersive XAS",
# 		        -state   => ($config{pixel}{do_pixel_check}) ? 'normal' : 'disabled',
# 		        -command => \&pixel],
# 		      ]);


## Merge menu
my $merge_weight='Weight by importance';
my $merge_menu = $menubar ->
  cascade(-label=>'~Merge', @menu_args,
	  -menuitems=>[
		       [command=> 'Merge marked data in mu(E)',   -command => [\&merge_groups, 'e']],
		       [command=> 'Merge marked data in norm(E)', -command => [\&merge_groups, 'n']],
		       [command=> 'Merge marked data in chi(k)',  -command => [\&merge_groups, 'k']],
		       ##"-",
		       ##[command=> 'Merge marked data in chi(R)',  -command => [\&merge_groups, 'r']],
		       ##[command=> 'Merge marked data in chi(q)',  -command => [\&merge_groups, 'q']],
		       "-",
		       [ radiobutton => 'Weight by importance',
			-selectcolor => $config{colors}{single},
			-variable    => \$merge_weight,
			-command     => sub{$config{merge}{merge_weight}='u'},
		       ],
		       [ radiobutton => 'Weight by chi_noise',
			-selectcolor => $config{colors}{single},
			-variable    => \$merge_weight,
			-command     => sub{$config{merge}{merge_weight}='n'},
		       ],
		      ]);

# ## Difference spectrum menu
# my $diff_menu = $menubar ->
#   cascade(-label=>'Diff', @menu_args, -underline=>1,
# 	  -menuitems=>[[ command => 'Difference spectra: norm(E)', -command => [\&difference, 'n']],
# 		       [ command => 'Difference spectra: chi(K)',  -command => [\&difference, 'k']],
# 		       "-",
# 		       [ command => 'Difference spectra: mu(E)',   -command => [\&difference, 'e']],
# 		       [ command => 'Difference spectra: chi(R)',  -command => [\&difference, 'r']],
# 		       [ command => 'Difference spectra: chi(q)',  -command => [\&difference, 'q']],
# 		      ]);

## Analysis menu
my $anal_menu = $menubar ->
  cascade(-label=>'~Analysis', @menu_args, #-underline=>4,
	  -menuitems=>[
		       [command => 'Linear combination fit', -command => \&lcf],
		       [command => 'Peak fit',               -command => \&peak_fit],
		       [command => 'PCA',	             -state   => 'disabled'],
		       [command => 'Log-Ratio',              -command => \&log_ratio],
		       [cascade => 'Difference spectra',     -tearoff => 0,
			-menuitems =>
			[[ command => 'Difference spectra: norm(E)', -command => [\&difference, 'n']],
			 [ command => 'Difference spectra: chi(K)',  -command => [\&difference, 'k']],
			 "-",
			 [ command => 'Difference spectra: mu(E)',   -command => [\&difference, 'e']],
			 [ command => 'Difference spectra: chi(R)',  -command => [\&difference, 'r']],
			 [ command => 'Difference spectra: chi(q)',  -command => [\&difference, 'q']],
			]
		       ],
		       (($demo_page) ?
			([command=>"Foobaricate", -command=>\&foobaricate]) :
			())
		      ]);

$menubar -> separator;

## Preferences menu
my $settings_menu =
  $menubar -> cascade(-label=>'~Settings', @menu_args, -tearoff=>0,
		      -menuitems=>[[ command => 'Swap panels',
				     -command => \&swap_panels,
				     -accelerator => 'Ctrl-/'],
				   ##['command'=>"Purge web download cache",
				   ## -command => \&purge_web_cache],
				   ['command'=>"Show key bindings",
				    -command => \&keys_show_all],
				   "-",
				   ['command'=>"Edit preferences", -command=>\&prefs],
				   ['command'=>"Plugin registry",  -command=>\&registry],
				   ['command'=>"Edit key bindings",
				    -command=>\&key_bindings],
				  ]);
## Help menu
my $help_menu =
  $menubar -> cascade(-label=>'~Help', @menu_args, -tearoff=>0, # -underline=>0,
		      -menuitems=>[['command'=> 'Document', -accelerator=>'Ctrl-m',
				    -command =>sub{pod_display("index.pod")}],
				   ['cascade'=>'Document sections',
				    -menuitems=>
				    [[ cascade => "Importing data",
				       -menuitems=>
				       [[ command => "The column selection dialog",
					 -command => sub{pod_display("import::columns.pod")}],
					[ command => "The project selection dialog",
					 -command => sub{pod_display("import::projsel.pod")}],
					[ command => "Importing multiple data sets",
					 -command => sub{pod_display("import::multiple.pod")}],
					[ command => "Reference channel",
					 -command => sub{pod_display("import::ref.pod")}],
					[ command => "Data preprocessing",
					 -command => sub{pod_display("import::preproc.pod")}],
					[ command => "Filetype plugin",
					 -command => sub{pod_display("import::plugin.pod")}],
				       ]],
				     [ cascade => "Background removal",
				       -menuitems=>
				       [[ command => "Normalization",
					 -command => sub{pod_display("bkg::norm.pod")}],
					[ command => "Understanding Fourier transforms",
					 -command => sub{pod_display("bkg::ft.pod")}],
					[ command => "The Rbkg parameter",
					 -command => sub{pod_display("bkg::rbkg.pod")}],
					[ command => "Spline clamps and k-weights",
					 -command => sub{pod_display("bkg::kweight.pod")}],
					[ command => "Spline range",
					 -command => sub{pod_display("bkg::range.pod")}],
				       ]],
				     [ cascade => "Plotting ",
				       -menuitems=>
				       [[ command => "Plot space tabs",
					 -command => sub{pod_display("plot::tabs.pod")}],
					[ command => "Stacking plots",
					 -command => sub{pod_display("plot::stack.pod")}],
					[ command => "Plot indicators",
					 -command => sub{pod_display("plot::indic.pod")}],
					[ command => "Point finder",
					 -command => sub{pod_display("plot::pf.pod")}],
					[ command => "Group-specific parameters",
					 -command => sub{pod_display("plot::params.pod")}],
					[ command => "Other plotting features",
					 -command => sub{pod_display("plot::etc.pod")}],
				       ]],
				     [ cascade => "User interface",
				       -menuitems=>
				       [[ command => "Using the group list",
					 -command => sub{pod_display("ui::glist.pod")}],
					[ command => "Marking groups",
					 -command => sub{pod_display("ui::mark.pod")}],
					[ command => "Pluck buttons",
					 -command => sub{pod_display("ui::pluck.pod")}],
					[ command => "Plot styles",
					 -command => sub{pod_display("ui::styles.pod")}],
					[ command => "Using k-weights",
					 -command => sub{pod_display("ui::kweight.pod")}],
					[ command => "Frozen groups",
					 -command => sub{pod_display("ui::frozen.pod")}],
					[ command => "Palettes",
					 -command => sub{pod_display("ui::palettes.pod")}],
					[ command => "Setting preferences",
					 -command => sub{pod_display("ui::prefs.pod")}],
				       ]],
				     [ cascade => "Setting parameter values",
				       -menuitems=>
				       [[ command => "Constraining parameters",
					 -command => sub{pod_display("params::constrain.pod")}],
					[ command => "Edge energy",
					 -command => sub{pod_display("params::e0.pod")}],
					[ command => "Default values",
					 -command => sub{pod_display("params::defaults.pod")}],
				       ]],
				     [ cascade => "Output files",
				       -menuitems=>
				       [[ command => "Column output files",
					 -command => sub{pod_display("output::column.pod")}],
					[ command => "Project files",
					 -command => sub{pod_display("output::project.pod")}],
					[ command => "Report files",
					 -command => sub{pod_display("output::report.pod")}],
				       ]],
				     [ cascade => "Data processing           ",
				       -menuitems=>
				       [[ command => "Energy calibration",
					 -command => sub{pod_display("process::cal.pod")}],
					[ command => "Aligning data",
					 -command => sub{pod_display("process::align.pod")}],
					[ command => "Deglitching data",
					 -command => sub{pod_display("process::deg.pod")}],
					[ command => "Truncating data",
					 -command => sub{pod_display("process::trun.pod")}],
					[ command => "Smoothing data",
					 -command => sub{pod_display("process::smooth.pod")}],
					[ command => "Convolving data",
					 -command => sub{pod_display("process::conv.pod")}],
					[ command => "Self-asborption",
					 -command => sub{pod_display("process::sa.pod")}],
					[ command => "Dispersive data",
					 -command => sub{pod_display("process::pixel.pod")}],
					[ command => "Merging data",
					 -command => sub{pod_display("process::merge.pod")}],
				       ]],
				     [ cascade => "Analysis                 ",
				       -menuitems=>
				       [[ command => "Linear combination",
					 -command => sub{pod_display("analysis::lcf.pod")}],
					[ command => "Peak fitting",
					 -command => sub{pod_display("analysis::peak.pod")}],
					[ command => "PCA",
				         -command => sub{pod_display("analysis::pca.pod")}],
					[ command => "Log-ratio",
				         -command => sub{pod_display("analysis::lr.pod")}],
					[ command => "Difference spectra",
					 -command => sub{pod_display("analysis::diff.pod")}],
					##[ command => "Foobaricate",
					## -command => sub{pod_display("process::foobar.pod"))}],
				       ]],
				    ]
				   ],
				   "-",
				   ['command'=>'Import a demo project',
				    -command =>\&read_demo],
				   ['command'=>'About demo projects',
				    -command =>\&about_demos],
				   ['command'=>"Explain Fourier transforms",
				    -command =>\&teach_ft],
				   "-",
				   ['command'=> 'Show a hint', -accelerator=>'Ctrl-h',
				    -command => \&show_hint],
				   [ command => "About current group", -accelerator=>'Ctrl-b',
				    -command => \&about_group],
				   [ command => "About marked groups", -accelerator=>'Ctrl-B',
				    -command => sub{about_marked_groups(\%marked)}],
				   ['command'=> 'Dump groups',
				    -command => \&Dumpit],
				   ['command'=> 'About Ifeffit',
				    -command => sub{Echo("Using Ifeffit ".
							 Ifeffit::get_string("\$&build"))}],
				   ['command'=> 'About Athena',
				    -command => sub{Echo($About)}],
				   ['command'=>"Check Ifeffit's memory usage",
				    -command =>
				    sub{$groups{"Default Parameters"}
					  -> memory_check($top, \&Echo, \%groups, $max_heap, 1, 0)}],
				  ]);


## diable the last item if this is a version of ifeffit that does not
## report max_heap
($max_heap == -1) and $help_menu -> menu -> entryconfigure(10, -state=>'disabled');

# $top -> bind('<Alt-h>' => sub{$help_menu->Post});

splash_message("Creating echo area");


## help & echo area
my $ebar = $top -> Frame(-relief=>'flat', -borderwidth=>3)
  -> pack(-side=>"bottom", -fill=>'x');
my $echo = $ebar -> Label(qw/-relief flat -justify left -anchor w
			  -font/, $config{fonts}{small},
			  -foreground=>$config{colors}{button},
			  -text=> "")
  -> pack(-side=>'left', -expand=>1, -fill=>'x', -pady=>2);
my $balloon = $top -> Balloon(-state=>'status', -statusbar=>$echo, -initwait=>0);
$echo -> bind('<KeyPress>' => sub{$multikey = $Tk::event->K; });

##  hints for the echo area about the various analysis functions
## $balloon -> attach($data_menu->menu,
## 		   -msg=>['',
## 			  'Calibrate the energy scale of mu(E) spectra',
## 			  'Remove spurious data points interactively or algorithmically',
## 			  'Remove all data points beyond a specified energy',
## 			  'Smooth a data set by interpolation or Fourier filtering',
## 			  'Convolute a mu(E) spectrum by a Gaussian or a Lorentzian',
## 			  'Correct data for self-absorption attenuations in fluorescence data',
## 			  'Correct data for detector dead time'
## 			 ]);
## $balloon -> attach($anal_menu->menu -> cget(-menu),
## 		   -msg=>['',
## 			  'Perform a log-ratio/phase-difference analysis using two data groups',
## 			  #'Do Principle Components Analysis on the set of marked groups',
## 			  'Principle Component Analysis is not yet a part of Athena.',
## 			  'Fit peak lineshapes and an arc-tangent to XANES data',
## 			  'Fit data as a linear combination of reference spectra',
## 			 ]);
## sub menubutton_attach {
##   my ($b, $mb, $msg) = @_;
##   $b -> attach($mb, -msg=>$msg);
##   $b -> attach($mb->cget(-menu), -msg=>$msg);
## };
## menubutton_attach($balloon, $align_menu,
## 		  "Align groups in energy by interactively changing energy shifts.");
## menubutton_attach($balloon, $merge_menu,
## 		  "Merge ALL MARKED groups in the chosen space.");
## menubutton_attach($balloon, $diff_menu,
## 		  "Compute difference spectra by subtracting one group from another.");
## menubutton_attach($balloon, $mark_menu,
## 		  "Mark groups by selecting the checkbuttons in the list of data groups.");


splash_message("Creating Groups list");

## left panel (fat) (group properties)
#my $fat = $top -> Scrolled('Pane', -scrollbars=>'oe', -relief=>'sunken',
#			   -borderwidth=>3, -width=>'13c')
my $container = $top -> Frame(-relief=>'flat', -borderwidth=>0)
  -> pack(-fill=>'both', -side=>$config{general}{fatside}, -expand=>1);
my $fat = $container -> Frame(-relief=>'sunken', -borderwidth=>3)
  -> pack(-fill=>'both', -expand=>1);
my %props;


my @bold   = (-foreground => $config{colors}{foreground},
	      -background => $config{colors}{activebackground},
	      -font       => $config{fonts}{small},
	      -cursor     => $mouse_over_cursor,);
my @normal = (-foreground => $config{colors}{foreground},
	      -background => $config{colors}{background},
	      -font       => $config{fonts}{small},
	      -cursor     => "top_left_arrow");

## right panel (skinny) (group list and plotting palette)
my @skinny_list = ();
my $skinny = $top -> Frame(-relief=>'sunken', -borderwidth=>4)
  -> pack(-expand=>1, -fill=>'both', -side=>$config{general}{listside});
my $top_frame = $skinny -> Frame(-relief=>'ridge', -borderwidth=>2)
  -> pack(-side=>'top', -fill => 'x', -anchor=>'n');
my $lab = $top_frame -> Label(-text    => q{},
			      @normal,
			      #-cursor  => $mouse_over_cursor,
			      -justify => 'center',
			      -relief  => 'flat')
  -> pack(-side=>'right', -fill=>'x', -expand=>1);
$lab -> bind("<ButtonPress-1>",  sub{save_project('all quick') unless $project_saved});
$lab -> bind("<ButtonPress-2>",  sub{save_project('all quick') unless $project_saved});
$lab -> bind("<ButtonPress-3>",  sub{save_project('all quick') unless $project_saved});
$lab -> bind('<Any-Enter>'    => sub{shift -> configure(($project_saved) ? @normal : @bold)});
$lab -> bind('<Any-Leave>'    => sub{shift -> configure( @normal);});
$top_frame -> Button(-text=>"A", -font=>$config{fonts}{smbold}, @m2_button_list,
		     -padx=>2,
		     -pady=>0,
		     -borderwidth=>1,
		     -command=>sub{mark('all')})
  -> pack(-side=>'left');
$top_frame -> Button(-text=>"U", -font=>$config{fonts}{smbold}, @m2_button_list,
		     -padx=>2,
		     -pady=>0,
		     -borderwidth=>1,
		     -command=>sub{mark('none')})
  -> pack(-side=>'left');
$top_frame -> Button(-text=>"I", -font=>$config{fonts}{smbold}, @m2_button_list,
		     -padx=>4,
		     -pady=>0,
		     -borderwidth=>1,
		     -command=>sub{mark('toggle')})
  -> pack(-side=>'left');


splash_message("Creating plotting controls");

$list = $skinny -> Scrolled(qw/Canvas -relief flat -borderwidth 0
			    -scrollbars e -width 5c -height 0.1c/,
			    -scrollregion=>['0', '0', '200', '200'])
## $list = $skinny -> Scrolled(qw/Pane -relief flat -borderwidth 0
## 			    -scrollbars e -width 5c -height 0.1c/,)
   -> pack(-side=>'top', -expand=>1, -fill=>'both', -anchor=>'w');
$list->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
#BindMouseWheel($list);
## plot button bar
$b_frame = $skinny -> Frame(-relief=>'flat', -borderwidth=>0, -class=>'horae')
  -> pack(-side=>'top', -anchor=>'n', -fill=>'x');
$plotsel = $skinny -> NoteBook(-background	   => $config{colors}{background},
			       -backpagecolor	   => $config{colors}{background},
			       -inactivebackground => $config{colors}{inactivebackground},
			       -font		   => $config{fonts}{small},
			      );

$plot_features{kw} = $plot_features{k_w};
my $red = $config{colors}{single};
my $kw_frame = $skinny -> Frame(-relief=>'ridge', -borderwidth=>2)
  -> pack(-side=>'top', -anchor=>'n', -fill => 'x');
$kw_frame -> Radiobutton(-text	      => 0,
			 -variable    => \$plot_features{kw},
			 -value	      => 0,
			 -padx	      => 1,
			 -selectcolor => $red,
			 -command     => \&kw_button,
			)
  -> pack(-side=>'left', -expand=>1, -fill=>'x');
$kw_frame -> Radiobutton(-text	      => 1,
			 -variable    => \$plot_features{kw},
			 -value	      => 1,
			 -padx	      => 1,
			 -selectcolor => $red,
			 -command     => \&kw_button,
			)
  -> pack(-side=>'left', -expand=>1, -fill=>'x');
$kw_frame -> Radiobutton(-text	      => 2,
			 -variable    => \$plot_features{kw},
			 -value	      => 2,
			 -padx	      => 1,
			 -selectcolor => $red,
			 -command     => \&kw_button,
			)
  -> pack(-side=>'left', -expand=>1, -fill=>'x');
$kw_frame -> Radiobutton(-text	      => 3,
			 -variable    => \$plot_features{kw},
			 -value	      => 3,
			 -padx	      => 1,
			 -selectcolor => $red,
			 -command     => \&kw_button,
			)
  -> pack(-side=>'left', -expand=>1, -fill=>'x');
$kw_frame -> Radiobutton(-text	      => 'kw',
			 -variable    => \$plot_features{kw},
			 -value	      => 'kw',
			 -padx	      => 1,
			 -selectcolor => $red,
			 -command     => \&kw_button,
			)
  -> pack(-side=>'left', -expand=>1, -fill=>'x');

$plot_features{options_showing} = 1;
my $po_frame = $skinny -> Frame()
  -> pack(-side=>'top', -anchor=>'n', -fill => 'x');
my $po_left  = $po_frame -> Button(-text    => 'v',
				   -font    => $config{fonts}{smbold},
				   -cursor  => $mouse_over_cursor,
				   -padx    => 1,
				   -pady    => 0,
				   -command => \&hide_show_plot_options)
  -> pack(-side=>'left', -anchor=>'n');
my $po       = $po_frame -> Label(-text	   => 'Plotting options',
				  @normal,
				  -cursor  => $mouse_over_cursor,
				  -justify => 'center',
				  -relief  => 'raised')
  -> pack(-side=>'left', -fill => 'x', -expand=>1);
my $po_right = $po_frame -> Button(-text    => 'v',
				   -font    => $config{fonts}{smbold},
				   -cursor  => $mouse_over_cursor,
				   -padx    => 1,
				   -pady    => 0,
				   -command => \&hide_show_plot_options);

$po -> bind('<Any-Enter>'=>sub{my $po = shift;
			       $po -> configure( @bold  );
			     });
$po -> bind('<Any-Leave>'=>sub{my $po = shift;
			       $po -> configure( @normal);
			     });
$po -> bind('<1>' => sub{Echo("Right click to post the Plot styles menu.  Click the arrow button to hide/show the plotting options.")});
$po -> bind('<2>' => \&plst_post_menu);
$po -> bind('<3>' => \&plst_post_menu);
$po_left  -> bind('<2>' => \&hide_show_plot_options);
$po_left  -> bind('<3>' => \&hide_show_plot_options);
$po_right -> bind('<2>' => \&hide_show_plot_options);
$po_right -> bind('<3>' => \&hide_show_plot_options);

# $b_frame -> Label(-text=>"Plot current group in", -relief=>'raised',
# 		  -font=>$config{fonts}{smbold},
# 		  -foreground=>$config{colors}{activehighlightcolor})
#   -> pack(-side=>'top', -anchor=>'n', -fill => 'x');
my $fr = $b_frame -> Frame(-relief=>'ridge', -borderwidth=>2)
  -> pack(-side=>'top', -anchor=>'n', -fill=>'both', -expand=>1);
my %b_red;
$b_red{E} = $fr -> Button(-text=>"E", -font=>$config{fonts}{smbold}, @r_button_list,
			  -pady=>1,
			  (($is_windows) ? (-width=>3) : ()),
			  -command=> \&plot_current_e)
  -> pack(-anchor=>'w', -side=>'left', -expand=>1, -fill=>'both');
$b_red{k} = $fr -> Button(-text=>"k", -font=>$config{fonts}{smbold}, @r_button_list,
			  -pady=>1,
			  (($is_windows) ? (-width=>3) : ()),
			  -command=> \&plot_current_k)
  -> pack(-anchor=>'w', -side=>'left', -expand=>1, -fill=>'both');
$b_red{R} = $fr -> Button(-text=>"R", -font=>$config{fonts}{smbold}, @r_button_list,
			  -pady=>1,
			  (($is_windows) ? (-width=>3) : ()),
			  -command=> \&plot_current_r)
  -> pack(-anchor=>'w', -side=>'left', -expand=>1, -fill=>'both');
$b_red{q} = $fr -> Button(-text=>"q", -font=>$config{fonts}{smbold}, @r_button_list,
			  -pady=>1,
			  (($is_windows) ? (-width=>3) : ()),
			  -command=> \&plot_current_q)
  -> pack(-anchor=>'w', -side=>'left', -expand=>1, -fill=>'both');
$b_red{kq} = $fr -> Button(-text=>"kq", -font=>$config{fonts}{smbold}, @r_button_list,
			  -pady=>1,
			   (($is_windows) ? (-width=>3) : ()),
			   -command=>
			   sub{ my $str = "kq";
				Echo('No data!'), return unless ($current);
				return unless &verify_ranges($current, 'kq');
				$top -> Busy(-recurse=>1,);
				(($plot_features{k_win} eq "w") or ($plot_features{q_win} eq "w"))
				  and ($str = "kqw");
				$groups{$current}->plotkq($str,$dmode,\%plot_features, \@indicator);
				$pointfinder{space} -> configure(-text=>"The last plot was in k");
				&refresh_properties;
				($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot =~ /[kq]/);
				$last_plot='kq';
				$last_plot_params = [$current, 'group', 'kq', $str];
				$plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
				section_indicators();
				foreach (qw(x xpluck xfind y ypluck yfind clear)) {
				  $pointfinder{$_} -> configure(-state=>'normal');
				};
				$top->Unbusy; })
  -> pack(-anchor=>'w', -side=>'left', -expand=>1, -fill=>'both');



# $b_frame -> Label(-text=>"Plot marked group in", -relief=>'raised',
# 		  -font=>$config{fonts}{smbold},
# 		  -foreground=>$config{colors}{activehighlightcolor})
#   -> pack(-side=>'top', -anchor=>'n', -fill => 'x');
$fr = $b_frame -> Frame(-relief=>'ridge', -borderwidth=>2)
  -> pack(-side=>'top', -anchor=>'n', -fill=>'both', -expand=>1);
$fr -> Button(-text=>"q", -font=>$config{fonts}{smbold}, @m_button_list,
	      -pady=>1,
	      (($is_windows) ? (-width=>3) : ()),
	      -command => \&plot_marked_q#foo#
	     )
  -> pack(-anchor=>'e', -side=>'right', -expand=>1, -fill=>'both');
$fr -> Button(-text=>"R", -font=>$config{fonts}{smbold}, @m_button_list,
	      -pady=>1,
	      (($is_windows) ? (-width=>3) : ()),
	       -command => \&plot_marked_r)
  -> pack(-anchor=>'e', -side=>'right', -expand=>1, -fill=>'both');
$fr -> Button(-text=>"k", -font=>$config{fonts}{smbold}, @m_button_list,
	      -pady=>1,
	      (($is_windows) ? (-width=>3) : ()),
	       -command => \&plot_marked_k)
  -> pack(-anchor=>'e', -side=>'right', -expand=>1, -fill=>'both');
$fr -> Button(-text=>"E", -font=>$config{fonts}{smbold}, @m_button_list,
	      -pady=>1,
	      (($is_windows) ? (-width=>3) : ()),
	       -command => \&plot_marked_e)
  -> pack(-anchor=>'e', -side=>'right', -expand=>1, -fill=>'both');



my @pc_args = (-anchor=>'center');
foreach (qw/e k r q/) {
  my $lab = "E";
  ($_ eq 'k') and ($lab = "k");
  ($_ eq 'r') and ($lab = "R");
  ($_ eq 'q') and ($lab = "q");
  $plotcard{$_} = $plotsel -> add(lc($_), -label=>$lab, @pc_args);
};
$plotcard{Stack} = $plotsel -> add('Stack', -label=>'Stack', @pc_args);
$plotcard{Ind}   = $plotsel -> add('Ind',   -label=>'Ind',   @pc_args);
$plotcard{PF}    = $plotsel -> add('PF',    -label=>'PF',    @pc_args);
$plotsel->pack(-fill => 'x', -side => 'bottom', -anchor=>'s');


## pack the groups list last so it expands to fill all the rest of the space
$list -> pack(qw/-expand 1 -fill both/);






splash_message("Creating palettes");

## ----------------------------------------------------------------------
## Setup the toplevel window for various textual interactions,
## including the ifeffit buffer and the raw text edit
my $update = $top -> Toplevel(-class=>'horae');
$update -> withdraw;
$update -> title("Athena palettes");
$update -> bind('<Control-q>' => sub{$update->withdraw});
$update -> protocol(WM_DELETE_WINDOW => sub{$update->withdraw});
#$update -> iconbitmap('@'.$iconbitmap);
$update -> iconimage($iconimage);
my $notebook = $update -> NoteBook(-backpagecolor=>$config{colors}{background},
				   -inactivebackground=>$config{colors}{inactivebackground},);
use vars qw(%notecard %notes %labels);
foreach my $n (qw/ifeffit titles data echo macro journal/) {
  $notecard{$n} = $notebook -> add(lc($n), -label=>ucfirst($n), -anchor=>'center', -underline=>0);
  my $topbar   = $notecard{$n} -> Frame(qw/-relief flat -borderwidth 2/)
    -> pack(qw/-fill x -side top/);
  $topbar  -> Button(-text=>'Dismiss', -command=>sub{$update->withdraw}, @button_list)
    -> pack(-side=>'right');
  ($n eq 'data') and
    $topbar  -> Button(-text=>'Edit current group', -command=>\&setup_data, @button_list)
    -> pack(-side=>'right');
  $labels{$n} = $topbar -> Label(-foreground=>$config{colors}{activehighlightcolor},
				 -font=>$config{fonts}{large})
    -> pack(-side=>'left');
  my ($h, $Text);
 SWITCH: {
    ($h, $Text) = (11, 'ROText'),   last SWITCH if ($n eq 'macro');
    ($h, $Text) = (13, 'TextUndo'), last SWITCH if ($n eq 'data');
    ($h, $Text) = (13, 'ROText'),   last SWITCH if ($n eq 'ifeffit');
    ($h, $Text) = (15, 'ROText'),   last SWITCH if ($n eq 'echo');
    ($h, $Text) = (15, 'TextUndo'), last SWITCH if ($n eq 'journal');
    ($h, $Text) = (15, 'TextUndo'), last SWITCH if ($n eq 'titles');
    ($h, $Text) = (13, 'ROText');
  };
  $notes{$n}    = $notecard{$n} -> Scrolled($Text, qw/-relief sunken -borderwidth 2
					    -wrap none -scrollbars se -width 70 -height/, $h,
					    -font=>$config{fonts}{fixed})
    -> pack(qw(-expand 1 -fill both -side top));
  $notebook -> pageconfigure($n, -raisecmd=>sub{$notes{$n}->focus});
  BindMouseWheel($notes{$n});
  disable_mouse3($notes{$n}->Subwidget(lc($Text)));
  $notes{$n} -> Subwidget("yscrollbar") -> configure(-background=>$config{colors}{background});
  $notes{$n} -> Subwidget("xscrollbar") -> configure(-background=>$config{colors}{background});
  $notes{$n} -> tagConfigure("text", -font=>$config{fonts}{fixedsm});

};
$notebook->pack(-expand => 1, -fill => 'both', -side => 'bottom');
$labels{ifeffit} -> configure(-text=>"Ifeffit interaction buffer");
$notes{ifeffit}  -> tagConfigure ('command',  -foreground=>$config{colors}{foregroun},
				  -lmargin1=>4, -lmargin2=>4);
$notes{ifeffit}  -> tagConfigure ('response', -foreground=>$config{colors}{highlightcolor},
				  -lmargin1=>20, -lmargin2=>20);
$notes{ifeffit}  -> tagConfigure ('comment',  -foreground=>$config{colors}{button},
				  -lmargin1=>4, -lmargin2=>4);
$labels{data}    -> configure(-text=>"Edit raw data");
$labels{echo}    -> configure(-text=>"Record of all text written to the echo area");
$labels{titles}  -> configure(-text=>"Titles for the current group");
$labels{macro}   -> configure(-text=>"Record a macro");
$labels{journal} -> configure(-text=>"Keep a journal of your analysis project");
$notes{journal}  -> configure(-wrap=>"word");
&setup_macro;


## set up the button bar in the data notecard
my $databbar = $notecard{data} -> Frame(qw/-relief flat -borderwidth 2/)
  -> pack(qw/-fill x -side bottom/);
$databbar -> Label(-textvariable=>\$current_file,
		   -foreground=>$config{colors}{activehighlightcolor},
		   -relief=>'groove')
  -> pack(qw/-expand yes -fill x -side left/);
$databbar -> Button(-text=>'Reload', @button_list, -command=>[\&save_and_reload, 0])
  -> pack(qw/-expand yes -fill x -side left/);
$databbar -> Button(-text=>'Save', @button_list, -command=>[\&save_and_reload, 1])
  -> pack(qw/-expand yes -fill x -side left/);
$databbar -> Button(-text=>'Clear', @button_list,
		    -command=>sub{$notes{data}->delete(qw/1.0 end/); $current_file="";})
  -> pack(qw/-expand yes -fill x -side left/);

## set up the button bar in the titles notecard
## $databbar = $notecard{titles} -> Frame(qw/-relief flat -borderwidth 2/)
##   -> pack(qw/-expand yes -fill x -side bottom/);
## $databbar -> Button(-text=>'Insert', -state=>'disabled')
##   -> pack(qw/-expand yes -fill x -side left/);


## set up the command line in the ifeffit interaction buffer
my $cmdline = $notecard{ifeffit} -> Frame(qw/-relief flat -borderwidth 2/)
  -> pack(qw/-fill x -side bottom/);
$cmdline -> Label(-text=>'Ifeffit> ', -font=>$config{fonts}{fixed},
		  -foreground=>$config{colors}{activehighlightcolor})
  -> pack(-side=>'left');
my $cmdbox = $cmdline -> Entry(qw/-width 60 -relief sunken -borderwidth 2/,
			       -font=>$config{fonts}{fixed})
  -> pack(-side=>'left', -fill=>'x', -expand=>'yes');
my @cmd_buffer = ("");
my $cmd_pointer = $#cmd_buffer;
$cmdbox->bind("<KeyPress-Return>", # dispose and push onto history
	      sub{ $setup->dispose($cmdbox->get()."\n", $dmode);
		   $cmd_buffer[$#cmd_buffer] =  $cmdbox->get();
		   push @cmd_buffer, "";
		   $cmd_pointer = $#cmd_buffer;
		   $cmdbox->delete(0,'end'); });
$cmdbox->bind("<KeyPress-Up>",	# previous command in history
	      sub{ --$cmd_pointer; ($cmd_pointer<0) and ($cmd_pointer=0);
		   $cmdbox->delete(0,'end');
		   $cmdbox->insert(0, $cmd_buffer[$cmd_pointer]); });
$cmdbox->bind("<KeyPress-Down>", # next command in history
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
## $cmdbox->bind("<KeyPress-Tab>",
$top -> update;


$top -> bind('<Control-Key-1>' => sub{raise_palette('ifeffit'); $cmdbox->focus;});
$top -> bind('<Control-Key-2>' => sub{raise_palette('titles'); });
$top -> bind('<Control-Key-3>' => sub{raise_palette('data'); &setup_data});
$top -> bind('<Control-Key-4>' => sub{raise_palette('echo'); });
$top -> bind('<Control-Key-5>' => sub{raise_palette('macro'); });
$top -> bind('<Control-Key-6>' => sub{raise_palette('journal'); });



## --------------------------------------------------------------------
## fill in main window

splash_message("Populating main window");

my %widget = ();
my $screen = ", fg=$config{plot}{fg}, bg=$config{plot}{bg}, ";
$screen .= ($config{plot}{showgrid}) ? "grid, gridcolor=\"$config{plot}{grid}\"" : "nogrid";
my @fclist;
map {push @fclist, "color".$_, $config{plot}{'c'.$_}} (0 ..9);

## set default plotting colors
$setup -> SetDefault(screen=>$screen, @fclist,
		     'showmarkers',        $config{plot}{showmarkers},
		     'marker',             $config{plot}{marker},
		     'markersize',         $config{plot}{markersize},
		     'markercolor',        $config{plot}{markercolor},
		     #'indicator',          $config{plot}{indicator},
		     'indicatorcolor',     $config{plot}{indicatorcolor},
		     'indicatorline',      $config{plot}{indicatorline},
		     'bordercolor',        $config{plot}{bordercolor},
		     'borderline',         $config{plot}{borderline},
		     'interp',             $config{general}{interp},
		     'linetypes',          $config{plot}{linetypes},
		     'flatten',            $config{bkg}{flatten});

## set default analysis parameter values
&clear_session_defaults;


$top->update;
draw_properties($fat); #$props);
&set_plotcards;
project_state(1);
foreach my $part (qw(project current bkg bkg_secondary fft bft plot)) {
  my $fill = $config{colors}{disabledforeground};
  $header{$part} -> configure(-foreground=>$fill);
};
foreach ($setup -> Keys) {
  next if ((/^deg/) or ($_ eq "file") or ($_ eq "line"));
  next unless (Exists($widget{$_}));
  $widget{$_} -> configure(-state=>'disabled');
};
$widget{"bkg_$_"} -> configure(-state=>'disabled') foreach (qw(alg fixstep flatten nnorm1 nnorm2 nnorm3));
map {($_ =~ /^(deg|lr)/) or $grab{$_}   -> configure(-state=>'disabled')} (keys %grab);

##undef $setup;
($use_default) and fill_skinny($list, "Default Parameters", 0);


## set up error handlers
#$SIG{__DIE__}  = sub{$groups{"Default Parameters"}->trap('Athena', $VERSION, 'die',  $trapfile, \&Error)};
#$SIG{__WARN__} = sub{$groups{"Default Parameters"}->trap('Athena', $VERSION, 'warn', $trapfile, \&Error)};



## -------------------------------------------------------------------


&clean_old_trap_files;



## -------------------------------------------------------------------
## file type plugins

splash_message("Importing filetype plugins");

## names of standard file type plugins
use vars qw(@plugins);
my $plugindir = ($is_windows) ? File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'pluginiff'),
						    qw(Plugins Filetype Athena))
  : File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'plugininc'),
			qw(Plugins Filetype Athena));
mkdir $plugindir if (not -e $plugindir);
opendir PLUGINS, $plugindir;
@plugins = sort (map {substr($_, 0, -3)} (grep {/\.pm$/} readdir PLUGINS) );
closedir PLUGINS;
#@plugins = (qw(Encoder Lambda X10C BESSRC CMC SSRL X15B));
#pop @plugins if $is_windows;

unless (-e $groups{"Default Parameters"} -> find('athena', 'plugins')) {
  open P, ">".$groups{"Default Parameters"} -> find('athena', 'plugins');
  print P "[___foo]\n_enabled=0\n";
  close P;
};
my %plugin_params;
tie %plugin_params, 'Config::IniFiles', (-file=>$groups{"Default Parameters"} -> find('athena', 'plugins'));

## standard plugins
foreach my $p (@plugins) {
  Echonow("Loading system filetype plugin $p");
  if ($is_windows) {
    unshift @INC, $groups{"Default Parameters"} -> find('athena', 'plugininc');
    eval "require Ifeffit::Plugins::Filetype::Athena::$p;";
  } else {
    eval "require Ifeffit::Plugins::Filetype::Athena::$p;";
  }
  ##eval "import Ifeffit::Plugins::Filetype::Athena::$p;";
  $plugin_params{$p}{_enabled} = 0 unless (exists $plugin_params{$p}{_enabled});
};

## user plugins
my $horae_dir = $groups{"Default Parameters"} -> find('athena', 'userplugininc');
unshift @INC, $horae_dir;
my $filetype_dir = $groups{"Default Parameters"} -> find('athena', 'userfiletypedir');
if (-e $filetype_dir) {
  opendir A, $filetype_dir;
  foreach (reverse (sort (grep {/pm$/} readdir A))) {
    my $this = File::Spec->catfile($filetype_dir, $_);
    my $ns = substr($_, 0 , -3);
    Echonow("Loading user filetype plugin $ns");
    eval "require(\'$this\');";
    unshift @plugins, $ns;
    $plugin_params{$ns}{_enabled} = 1 unless (exists $plugin_params{$ns}{_enabled});
  };
  closedir A;
};
delete $plugin_params{___foo};
tied( %plugin_params )->WriteConfig($groups{"Default Parameters"} -> find('athena', 'plugins'));

## -------------------------------------------------------------------

splash_message("Initializing Ifeffit");

my $macros_string = write_macros();
$groups{"Default Parameters"} -> dispose($macros_string, $dmode);
## set the charsize and charfont
##$groups{"Default Parameters"} -> dispose("plot(charsize=$config{plot}{charsize}, charfont=$config{plot}{charfont})", $dmode);
$groups{"Default Parameters"} -> dispose("startup", $dmode);

my $iffversion = Ifeffit::get_string("\$&build");
$iffversion =~ s{\A\s+}{};
Echonow("Using Ifeffit $iffversion");
$top -> after(2000, [\&Echonow, "Athena may be freely redistributed under the terms of its license."]);
$top -> after(3500, [\&Echonow, "Athena comes with absolutely NO WARRANTY."]);
$top -> after(5500, \&show_hint);

&set_recent_menu();		# establish MRU list
## need to save the geometry of the main window for use by things like
## thepeak fitting interface
my @fatgeom = ('-height', $fat->height, '-width', $fat->width);
#print join(" ", @fatgeom), $/;

splash_message("Ready to start...");
## remove splashscreen and display program
$top -> update;
$splash -> Destroy;
&set_key_params;

my @geom = split(/[+x]/, $top->geometry);
my $extrabit = ($is_windows) ? 0 : 40;
unless ($is_windows) {
  $top -> minsize(    $geom[0], $geom[1]+$extrabit);
  $top -> maxsize(1.3*$geom[0], $geom[1]+$extrabit);
};
## the +30 is kind of ad hoc.... why doesn't the menubar's size
## get reported correctly?
if (exists $mru{geometry}{'x'}) {
  $mru{geometry}{'x'} = 0 if ($mru{geometry}{'x'} < 0);
  $mru{geometry}{'x'} = 0 if ($mru{geometry}{'x'} > $top->screenwidth());
  $mru{geometry}{'y'} = 0 if ($mru{geometry}{'y'} < 0);
  $mru{geometry}{'y'} = 0 if ($mru{geometry}{'y'} > $top->screenheight());
  my $location = "+" . $mru{geometry}{'x'} . "+" . $mru{geometry}{'y'};
  ($location = $mru{geometry}{height} . "x" . $mru{geometry}{width} . $location) unless ($is_windows);
  $top -> geometry($location);
};

$top -> deiconify;
$top -> raise;
$container -> pack(-fill=>'both', -side=>$config{general}{fatside}, -expand=>0);
$container -> packPropagate(0);

## if ($is_windows) {
##   open PARID, ">".$groups{"Default Parameters"} -> find('athena', 'par');;
##   print PARID $ENV{PAR_TEMP}, $/;
##   close PARID;
## };

## process the command line argument
if ($ARGV[0]) {
 CMDARG: {
    (-d $ARGV[0]) and do {	# directory: open extended selection file dialog
      $current_data_dir = $ARGV[0];
      &read_file(1, 0);
      last CMDARG;
    };
    ($ARGV[0] =~ /^-(\d+)$/) and do { # grab something from the MRU list
      &read_file(0, $mru{mru}{$1}) if (exists $mru{mru}{$1} and (-e $mru{mru}{$1}));
      last CMDARG;
    };
    (-e $ARGV[0]) and do {	# open the specified file or project
      my $arg = ($ARGV[0] =~ /^[.\~\/]/) ? $ARGV[0] : File::Spec->catfile(Cwd::cwd, $ARGV[0]);
      &read_file(0, $arg);
      last CMDARG;
    };
  }; # end of CMDARG
};



MainLoop();
