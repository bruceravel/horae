#!/usr/bin/perl -w
######################################################################
## Hephaestus: a souped-up periodic table for the absorption
##             spectroscopist
##
##                  Hephaestus is copyright (c) 2004-2008 Bruce Ravel
##                                                     bravel@bnl.gov
##                                  http://cars9.uchicago.edu/~ravel/
##
##                   Ifeffit is copyright (c) 1992-2007 Matt Newville
##                                         newville@cars.uchicago.edu
##                       http://cars9.uchicago.edu/~newville/ifeffit/
##
##	 The latest version of Hephaestus can always be found at
##	       http://cars9.uchicago.edu/~ravel/software/
##
## -------------------------------------------------------------------
##     All rights reserved. This program is free software; you can
##     redistribute it and/or modify it provided that the above notice
##     of copyright, these terms of use, and the disclaimer of
##     warranty below appear in the source code and documentation, and
##     that none of the names of Argonne National Laboratory, The
##     Naval Research Laboratory, The University of Chicago,
##     University of Washington, or the authors appear in advertising
##     or endorsement of works derived from this software without
##     specific prior written permission from all parties.
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
## In his workshop he has handmaidens he has forged out of gold who
## can move and who help him in his work. ...  With Athena, he [is]
## important in the life of the city.  The two [are] the patrons of
## handicrafts, the arts which along with agriculture are the support
## of civilization.
##
##                          Mythology, Edith Hamilton
######################################################################



## BEGIN {
##   ## make sure the pgplot environment is sane...
##   ## these defaults assume that the pgplot rpm was installed
##   $ENV{PGPLOT_DIR} ||= '/usr/local/share/pgplot';
##   $ENV{PGPLOT_DEV} ||= '/XSERVE';
## };

use warnings;
use strict;
use File::Spec;
use File::Basename;
use File::Path;
use Tk;
## need to make PAR happy....
use Tk::widgets qw(Wm Frame DialogBox Checkbutton Entry Label Photo
		   LabFrame Scrollbar Pod Pod/Text Pod/Search Pod/Tree
		   Menu More ROText Optionmenu Dialog BrowseEntry
		   Splashscreen LabEntry DialogBox Pane NumEntry
		   NumEntryPlain FireButton);
use Tk::Pane;
use Tk::Photo;
use Tk::Pod;
use Config::IniFiles;
use Chemistry::Elements qw(get_name get_Z get_symbol);
use Chemistry::Formula qw(parse_formula formula_data);
use Xray::Absorption;
##use Ifeffit::Tools;
use Ifeffit::FindFile;
use Tie::IxHash;
use Storable;
use Math::Spline;
use Math::Derivative;
use constant PI      => 4 * atan2 1, 1;
use constant HBARC   => 1973.27053324;
use constant EPSILON => 0.00001;

use Cwd;
use File::Basename;
my $save_dir = Cwd::cwd || dirname($0) || $ENV{IFEFFIT_DIR};


use vars qw($VERSION @LINELIST);
$VERSION = '0.18';
@LINELIST = qw(Ka1 Ka2 Ka3 Kb1 Kb2 Kb3 Kb4 Kb5
	       La1 La2 Lb1 Lb2 Lb3 Lb4 Lb5 Lb6
	       Lg1 Lg2 Lg3 Lg6 Ll Ln Ma Mb Mg Mz);

my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));
## my $is_darwin  = (lc($^O) eq 'darwin');

## this regex matches the utilities that use the periodic table
my $uses_periodic_regex = '(?:absorption|data|f1f2)';

## Initialization files
my $horae_dir = Ifeffit::FindFile->find("other", "horae");
(-d $horae_dir) or mkpath($horae_dir);

## system-wide rc file (but check to see that it exists...
my $system_rcfile = Ifeffit::FindFile->find("hephaestus", "rc_system");
my %system_config;
tie %system_config, 'Config::IniFiles', (-file=>$system_rcfile) if -e $system_rcfile;
my $system_config_ref = tied %system_config;

## if the user does not have a personal rc file, create one
my $personal_rcfile = Ifeffit::FindFile->find("hephaestus", "rc_personal");
if (! -e $personal_rcfile) {
  open I, ">".$personal_rcfile;
  print I "[general]\ndummy_parameter=1\n";
  close I;
};
my %config;
tie %config, 'Config::IniFiles', (-file=>$personal_rcfile, -import=>$system_config_ref);
#my $config_ref = tied %config;

## sanity check the config file and transfer the values into the %data hash
my %data;
verify_config(tied %config);

if ($config{general}{ifeffit}) {
  require Ifeffit;
  import Ifeffit;
};


my $current = "";
## absorption data
my %energies = ();
my %probs = ();
## chemical data
my %kalzium;
my %userformulas;
## formula data
my (%formula, %density);
&formula_data(\%formula, \%density);

my $bgcolor = '#cdc7ba';

my $hephaestus_lib = Ifeffit::FindFile->find("hephaestus", "hephaestus");
my $aug_lib        = Ifeffit::FindFile->find("athena", "augpod");
my $horae_lib = Ifeffit::FindFile->find("hephaestus", "horae");
Tk::Pod->Dir($aug_lib);

mkdir $horae_lib unless ($is_windows or (-e $horae_lib));

if ((not -e Ifeffit::FindFile->find("hephaestus", "data")) and (-w $horae_lib)) {
  open I, ">".Ifeffit::FindFile->find("hephaestus", "data");
  print I "[data]\n^^^^=1\n";
  close I;
};

if (-e Ifeffit::FindFile->find("hephaestus", "data")) {
  tie %userformulas, 'Config::IniFiles', (-file=>Ifeffit::FindFile->find("hephaestus", "data"));
  #    if (-e File::Spec->catfile($horae_lib, 'hephaestus.data'));
  foreach my $k (keys %{$userformulas{data}}) {
    next if ($k eq '^^^^');
    if ($userformulas{data}->{$k} eq "^^remove^^") {
      delete $formula{$k};
      delete $density{$k};
    } else {
      my ($s, $d) = split(/\|/, $userformulas{data}->{$k});
      $formula{$k} = $s;
      $density{$k} = $d;
    };
  };
};


my  $top = MainWindow->new(-class=>'horae');
$top -> withdraw;
$top -> optionAdd('*font', $config{fonts}{small});

my ($r, $g, $bl) = $top -> rgb($bgcolor);
my $acolor = sprintf("#%4.4x%4.4x%4.4x", int($r*1.10), int($g*1.10), int($bl*1.10));
($acolor = "#c000c000c000") if ($acolor eq "#ffffffffffff");

my $splash = $top->Splashscreen();
$splash -> Label(-image      => $top -> Photo(-file => File::Spec->catfile($hephaestus_lib, "vulcan.gif")),
		 -background => 'white')
  -> pack(qw/-fill both -expand 1 -side left/);
$splash -> Label(-text       => " Hephaestus $VERSION\nis starting ...",
		 -background => 'white',
		 -font       => $config{fonts}{largebold},)
  -> pack(qw/-fill both -expand 1 -side right/);
$splash -> Splash;
$top -> update;

$top -> setPalette(foreground	  => 'black',
		   background	  => $bgcolor,
		   highlightColor => 'DarkSlateBlue',
		   -font	  => $config{fonts}{smbold},
		   );
#my $iconbitmap = File::Spec->catfile($hephaestus_lib, "hephaestus_icon.xbm");
#$top -> iconbitmap('@'.$iconbitmap);
my $iconimage = $top -> Photo(-file => File::Spec->catfile($hephaestus_lib, "vulcan.gif"));
$top -> iconimage($iconimage);
$top -> bind('<Control-q>' => sub{exit});
$top -> bind('<Control-Key-0>' => \&help);


$top -> configure(-menu=> my $menubar = $top->Menu(-relief=>'ridge', -font=>$config{fonts}{smbold}));


## common widget arguments
my $l_text = $config{fonts}{smbold};
my $b_text = $config{fonts}{smbold};
my @label_args     = (-foreground       => 'blue4',
		      -font             => $l_text);
my @button_args	   = (-foreground	=> 'seashell',
		      -background	=> 'darkslateblue',
		      -activeforeground	=> 'seashell',
		      -activebackground	=> 'slateblue',
		      -font		=> $b_text),


my @answer_args = (-foreground=>'black',
		   -background=>$bgcolor,
		  );


my $buttonbox = $top -> Frame(-background=>'white',
			      -width=>128,
			      -relief=>'flat',
			      -borderwidth=>2)
  -> pack(-side=>'left', -padx=>8, -pady=>8, -fill=>'y', -ipady=>0);
use vars qw($main);
$main = $top -> Frame(-background=>$bgcolor)
  -> pack(-side=>'right', -expand=>1, -fill=>'both');

use vars qw($title);
$title = $main -> Label(-foreground=>'#49007a',
			#-background=>'white',
			-font=>$config{fonts}{medbold},
			-relief=>'ridge')
  -> pack(-fill=>'x', -pady=>8, -padx=>4);

my @colors = ('white', '#cac4ff');
my @frame_props = (-height=>40, -relief=>'flat', -borderwidth=>2),
my @frame_pack  = (-side=>'top', -padx=>1, -pady=>0, -fill=>'x', -anchor=>'n');
my @button_pack = (-side=>'left', -padx=>0, -pady=>2);


=for Explain:
     IxHash allows this to be the master array for the layout of the
     application.  The order specified here will be the order for an
     loop over the keys.  Very handy.  To add a new utility, just put it
     in the right position in this hash.  Forgetting to add to the label
     hash should not cause the app to go klunk, but it will make for a
     confusing button bar.  The functions associated with the utility
     should be named according to the hash key, as should the image used
     in the button bar.  Thus "formulas" has a sub called formulas and
     an image called formulas.gif.

=cut

tie my %frames, "Tie::IxHash";
my $count = -1;
%frames  = (absorption => $buttonbox -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	    formulas => $buttonbox   -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	    data => $buttonbox       -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	    ion  => $buttonbox       -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	    trans => $buttonbox      -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	    find => $buttonbox       -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	    line => $buttonbox       -> Frame(-background=>$colors[++$count%2], @frame_props)
	    -> pack(@frame_pack),
	   );

=for Explain:
     This: $colors[++$count%2] runs a risk of being just too cute.
     Its intent is to toggle between the two colors each time a %frame
     entry is created.  The reason I want to toggle algorithmically is
     so that the color of the document button comes out right
     regardless of whether the f1f2 utility is displayed.  It'll also
     be easier to add new utilities in the future.  $count%2 return 0
     for even numbers and 1 for odd numbers.

=cut

my %label = (absorption	=> 'Absorption',
	     formulas	=> "Formulas",
	     data	=> "Data",
	     ion	=> "Ion Chamber",
	     trans	=> "Transitions",
	     find	=> "Edge Finder",
	     line	=> "Line Finder",
	     );
if ($config{general}{ifeffit}) {
  $frames{f1f2} = $buttonbox -> Frame(-background=>$colors[++$count%2], @frame_props) -> pack(@frame_pack);
  $label{f1f2}  = "f' & f\"";
};
$frames{help} = $buttonbox -> Frame(-background=>$colors[++$count%2], @frame_props) -> pack(@frame_pack);
$label{help}  = "Document";


$buttonbox -> Frame(-background=>$colors[0], -height=>0)
  -> pack(-side=>"bottom", -fill=>'y', -anchor=>'s', -expand=>1);

## load up the button bar
my (%buttons, %text, %callbacks, @menuitems);
my ($i, $c) = (1, "");
foreach my $k (keys %frames) {
  ## fallback, in case one forgets to fill the %label hash
  $label{$k} ||= ucfirst(lc($k));

  ## fill in the frames
  $buttons{$k} = $frames{$k} -> Label(-image      => $frames{$k}->Photo(-file => File::Spec->catfile($hephaestus_lib, "$k.gif")),
				      -background => $frames{$k}->cget("-background"),
				     )
    -> pack(@button_pack);
  $text{$k}    = $frames{$k} -> Label(-text       => sprintf("%-11s",$label{$k}),
				      -height     => 2,
				      -background => $frames{$k}->cget("-background"),
				      @label_args,
				     )
    -> pack(@button_pack);

  ## turn these into image-text "buttons"
  eval "\$callbacks{$k} = \\\&$k";
  $buttons{$k} -> bind('<ButtonPress-1>',$callbacks{$k});
  $text{$k}    -> bind('<ButtonPress-1>',$callbacks{$k});
  $buttons{$k} -> bind('<ButtonPress-3>',$callbacks{$k});
  $text{$k}    -> bind('<ButtonPress-3>',$callbacks{$k});

  if ($label{$k} ne 'Document') {
    ## bind Ctl-number sequences, but not to doc, which is C-0
    ## use C-a, C-b, etc should the number of utilities exceeds 9
    ## also build File menu items
    if ($i<10) {
      eval "\$top -> bind('<Control-Key-$i>' => \\\&$k)";
      eval "push \@menuitems, [ command	=> \$label{$k},
	                     -accelerator => \"Ctrl-\$i\",
		             -command	=> \\\&$k]";
    } else {
      $c = chr(87+$i);
      eval "\$top -> bind('<Control-Key-$c>' => \\\&$k)";
      eval "push \@menuitems, [ command	=> \$label{$k},
	                     -accelerator => \"Ctrl-\$c\",
		             -command	=> \\\&$k]";
    };
    ++$i;
  };
};

=for Explain:
     so, you see, we are turning these label pairs into buttons because
     perl/Tk buttons can have text or an image, but not both.  this is
     sort of the functional equivalent to an image-text button but
     without the additional bindings (activation, relief change, release
     event, and input focus)

=cut

my $file_menu = $menubar ->
  cascade(-label => '~File',
	  -font => $config{fonts}{smbold},
	  -menuitems =>[@menuitems,
			"-",
			[ command      =>'~Quit',
			 -accelerator  =>'Ctrl-q',
			 -command      => sub{exit}]
		       ] );
my $units_menu = $menubar ->
  cascade(-label => '~Units',
	  -menuitems => [
			 [ radiobutton =>'Energies',
			   -value      =>'Energies',
			   -variable   =>\$data{units},
			   -command    =>\&swap_energy_units],
			 [ radiobutton =>'Wavelengths',
			   -value      =>'Wavelengths',
			   -variable   =>\$data{units},
			   -command    =>\&swap_energy_units],
			]
	 );
my $resource_menu = $menubar ->
  cascade(-label => '~Resource',
	  -menuitems => [
			 [radiobutton => 'Elam',
			  -variable   => \$data{resource},
			  -command    => sub{Xray::Absorption -> load("elam");
					     set_xsec("elam");
					     &set_pt_explain; }],
			 [radiobutton => 'McMaster',
			  -variable   => \$data{resource},
			  -command    => sub{Xray::Absorption -> load("mcmaster");
					     set_xsec("mcmaster");
					     &set_pt_explain; }],
			 [radiobutton => 'Henke',
			  -variable   => \$data{resource},
			  -command    => sub{Xray::Absorption -> load("henke");
					     set_xsec("henke");
					     &set_pt_explain; }],
			 [radiobutton => 'Chantler',
			  -variable   => \$data{resource},
			  -command    => sub{Xray::Absorption -> load("chantler");
					     set_xsec("chantler");
					     &set_pt_explain; }],
			 [radiobutton => 'Cromer-Liberman',
			  -variable   => \$data{resource},
			  -state      => ($config{general}{ifeffit}) ? 'normal' : 'disabled',
			  -command    => sub{Xray::Absorption -> load("cl");
					     set_xsec("cl");
					     &set_pt_explain; }],
			 [radiobutton => 'Shaltout',
			  -variable   => \$data{resource},
			  -command    => sub{Xray::Absorption -> load("shaltout");
					     set_xsec("shaltout");
					     &set_pt_explain; }],
			]
	 );
my $xsec_menu = $menubar ->
  cascade(-label => '~Xsection',
	  -menuitems => [
			 [radiobutton => 'Total',
			  -variable   => \$data{cross_section},
			  -command    => sub{$data{xsec} = 'full'; &set_pt_explain;} ],
			 [radiobutton => 'Photoelectric',
			  -variable   => \$data{cross_section},
			  -command    => sub{$data{xsec} = 'photo'; &set_pt_explain;} ],
			 [radiobutton => 'Coherent',
			  -variable   => \$data{cross_section},
			  -command    => sub{$data{xsec} = 'coherent'; &set_pt_explain;} ],
			 [radiobutton => 'Incoherent',
			  -variable   => \$data{cross_section},
			  -command    => sub{$data{xsec} = 'incoherent'; &set_pt_explain;} ]
			]
	 );

my $About_text = "Hephaestus Version $VERSION.

A souped-up periodic table for the X-ray absorption spectroscopist.

You are using Perl $] and Perl/Tk $Tk::VERSION

copyright © 2004-2008 Bruce Ravel
http://cars9.uchicago.edu/~ravel/software/
bravel\@anl.gov";
my $help_menu = $menubar ->
  cascade(-label => '~Help',
	  -menuitems => [[ command=>'~Document',
			   -accelerator=>'Ctrl-0',
			   -command=> \&help],
			 [ command=>'~About',
			   -command=> sub{$top->Dialog(-title   => "About Hephaestus",
						       -text    => $About_text,
						       -font    => $config{fonts}{small},
						       -buttons => ["OK"],
						       -bitmap  => "info")
					    -> Show;
					}],
			]
	 );


## set up the various frames needed by the utilities
use vars qw($periodic_table %bottom);
$periodic_table = periodic_table($main);
$top -> packPropagate(1);
foreach my $k (keys %frames) {
  eval "\$bottom{$k} = setup_$k(\$main)";
};
## $bottom{help} = $main->PodText(-file => ($is_windows) ? "hephaestus.pod" : $0,
##			       -scrollbars=>'ose');
##$bottom{help} -> zoom_in;
##$bottom{help} -> zoom_in;

## display the absorption utility at startup, but make sure the window
## is big enough for both the transition chart and the periodic table
&trans;
$top -> update;
my @geom = ($top->width, $top->height);
&ion;
$top -> update;
if (not $is_windows) {
  ($geom[0] = $top->width)  if ($geom[0] < $top->width);
  ($geom[1] = $top->height) if ($geom[1] < $top->height);
  &ion;
  $top -> update;
  ($geom[0] = $top->width)  if ($geom[0] < $top->width);
  ($geom[1] = $top->height) if ($geom[1] < $top->height);
  &absorption;
  $top -> update;
  ($geom[0] = $top->width)  if ($geom[0] < $top->width);
  ($geom[1] = $top->height) if ($geom[1] < $top->height);
};
$top -> geometry(join("x", @geom)) unless $is_windows;
$top -> update;
$top -> packPropagate(0);

STARTUP: {
  &absorption, last STARTUP if  (lc($config{general}{startup}) eq 'absorption');
  &formulas,   last STARTUP if  (lc($config{general}{startup}) eq 'formulas');
  &data,       last STARTUP if  (lc($config{general}{startup}) eq 'data');
  &ion,	       last STARTUP if  (lc($config{general}{startup}) eq 'ion');
  &trans,      last STARTUP if  (lc($config{general}{startup}) eq 'trans');
  &find,       last STARTUP if  (lc($config{general}{startup}) eq 'find');
  &line,       last STARTUP if  (lc($config{general}{startup}) eq 'line');
  &f1f2,       last STARTUP if ((lc($config{general}{startup}) eq 'f1f2') and ($config{general}{ifeffit}));
  &absorption;
};


$top -> title('Hephaestus');
$top -> iconname('Hephaestus');
$top -> update;
$splash -> Destroy;
#$top -> resizable(0,0);
$top -> deiconify;
$top -> raise;
MainLoop();



=for Explain:
     this is a dispatcher for a click on the periodic table. what
     happens depends on which utility is showing

=cut
sub multiplexer {
 SWITCH: {
    get_foils_data($_[0]),    last SWITCH if ($current eq 'absorption');
    get_chemical_data($_[0]), last SWITCH if ($current eq 'data');
    get_f1f2_data($_[0]),     last SWITCH if ($current eq 'f1f2');
    warn "Yikes!  Hephaestus' multiplexer failed to catch a periodic table click event: $_[0] ($current)\n";
  };
};

=for Explain:
     build the periodic table and return the frame which contains it

=cut
sub periodic_table {
  my $table = $_[0] -> Frame(-borderwidth=>2, -relief=>'ridge');
  my $frame = $table -> Frame()
    -> pack(-side=>'top', -fill=>'x', -padx=>2, -pady=>2);
  my $trans = $table -> Frame()
    -> pack(-side=>'bottom', -padx=>2, -pady=>2);


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
		  ['Mt', 6, 8,  'm'],
		 );

  my @metal_args     = (-foreground       => 'seashell',
			-background       => 'darkslategrey',
			-activeforeground => 'black',
			-activebackground => 'slategrey',
			-font             => $config{fonts}{smbold});
  my @semimetal_args = (-foreground       => 'seashell',
			-background       => 'khaki4',
			-activeforeground => 'black',
			-activebackground => 'khaki3',
			-font             => $config{fonts}{smbold});
  my @nonmetal_args  = (-foreground       => 'seashell',
			-background       => 'cadetblue4',
			-activeforeground => 'black',
			-activebackground => 'cadetblue3',
			-font             => $config{fonts}{smbold});
  my @gas_args	     = (-foreground       => 'seashell',
			-background       => 'goldenrod4',
			-activeforeground => 'black',
			-activebackground => 'goldenrod3',
			-font             => $config{fonts}{smbold});

  ## -------------------------------------------------------------------
  ## set up periodic table
  my $label = $trans -> Label(-text=>'Lanthanides ', @label_args)
    -> grid(-column=>0, -columnspan=>3, -row=>0, -sticky=>'e');
  $label = $trans -> Label(-text=>'Actinides ', @label_args)
    -> grid(-column=>0, -columnspan=>3, -row=>1, -sticky=>'e');
  my %arg_refs = ('m'=>\@metal_args,
		  's'=>\@semimetal_args,
		  'n'=>\@nonmetal_args,
		  'g'=>\@gas_args);
  foreach my $e (@elements) {
    my ($s, $r, $c, $p) = ($e->[0], $e->[1], $e->[2], $e->[3]);
    my @button_args = @{$arg_refs{$p}};
    if ($r < 7) {			# s p and d atoms
      my $button = $frame -> Button(-text    => $s,
				    -width   => ($is_windows) ? 3 : 1,
				    @button_args,
				    -command => [\&multiplexer, $s])
	-> grid(-column=>$c, -row=>$r, -sticky=>'ew');
      $button -> bind('<ButtonPress-3>' =>
		      sub {
			return if ($current ne "absorption");
			$data{abs_filter} = $s;
		      });
    } else {			# lanthandes and actinides
      my $button = $trans -> Button(-text    => $s,
				    -width   => ($is_windows) ? 3 : 1,
				    @button_args,
				    -command => [\&multiplexer, $s])
	-> grid(-column=>$c, -row=>$r-7, -sticky=>'ew');
      $button -> bind('<ButtonPress-3>' =>
		      sub {
			return if ($current ne "absorption");
			$data{abs_filter} = $s;
		      });
    };
  };

  $data{pt_resource} = $frame -> Label(-textvariable=>\$data{pt_explain}, @label_args)
    -> grid(-column=>3, -columnspan=>7, -row=>0, -rowspan=>3, -sticky=>'w');

  return $table;
};


sub verify_config {
  my ($config_ref) = @_;
  delete $config{general}{dummy_parameter};

  ## general
  $data{resource} = (lc($config{general}{resource}) =~ /^(elam|mcmaster|henke|chantler|cl)$/)
    ? ucfirst(lc($config{general}{resource})) : 'Elam';
  ($data{resource} = 'McMaster') if ($data{resource} eq 'Mcmaster');
  $data{units}    = (lc($config{general}{units}) =~ /^(energies|wavelengths)$/)
    ? ucfirst(lc($config{general}{units}))    : 'Energies';
  $data{xsec}     = (lc($config{general}{xsec}) =~ /^(full|photo|coherent|incoherent)$/)
    ? lc($config{general}{xsec})          : 'full';
  ($data{cross_section} = 'Total')         if ($data{xsec} eq 'full');
  ($data{cross_section} = 'Photoelectric') if ($data{xsec} eq 'photo');
  ($data{cross_section} = 'Coherent')      if ($data{xsec} eq 'coherent');
  ($data{cross_section} = 'Incoherent')    if ($data{xsec} eq 'incoherent');

  # absorption
  $data{abs_linewidth} = ($config{absorption}{linewidth} > 0)
    ? $config{absorption}{linewidth} : 30;
  $data{abs_offset} = ($config{absorption}{offset} > 0)
    ? $config{absorption}{offset} : 3;

  # formulas
  $data{form_energy} = ($config{formulas}{energy} > 0)
    ? $config{formulas}{energy} : 9000;

  # data

  # ion
  $data{ion_energy}   = ($config{ion}{energy} > 0)
    ? $config{ion}{energy}            : 9000;
  $data{ion_length}   = ($config{ion}{length} =~ /^(3.3|6.6|10|15|30|45|60)$/)
    ? $config{ion}{length}            : 15;
  $data{ion_gas1}     = (lc($config{ion}{gas1}) =~ /^(he|n2|ar|ne|kr|xe)$/)
    ? $config{ion}{gas1}              : 15;
  $data{ion_pressure} = ((lc($config{ion}{pressure}) > 0) and (lc($config{ion}{pressure}) < 2300))
    ? int($config{ion}{pressure})     : 760;
  $data{ion_gain}     = (lc($config{ion}{pressure}) > 0)
    ? int($config{ion}{gain})         : 8;

  # trans

  # find
  $data{find_energy} = ($config{find}{energy} > 0)
    ? $config{find}{energy} : 9000;
  $data{find_harmonic} = ($config{find}{harmonic} =~ /^[123]$/)
    ? $config{find}{harmonic} : 1;

  # line
  $data{line_energy} = ($config{line}{energy} > 0)
    ? $config{line}{energy} : 8047;

  # f1f2
  $data{f1f2_emin} = ($config{f1f2}{emin} > 0)
    ? $config{f1f2}{emin} : 3000;
  $data{f1f2_emax} = ($config{f1f2}{emax} > 0)
    ? $config{f1f2}{emax} : 7000;
  $data{f1f2_grid} = ($config{f1f2}{grid} > 0)
    ? $config{f1f2}{grid} : 5;

  $data{sample_energy} = 9000;
  $data{pt_explain}    = "Using Elam database\nComputing total cross-section";
  $data{ion_resource}  = "Using Elam database";
  $data{abs_odd_value} = 40;
  if ($data{units} eq 'Wavelengths') {
    map {$data{$_} = &e2l($data{$_})} (qw(form_energy ion_energy));
    $data{sample_energy} = e2l(9000);
  };
  Xray::Absorption -> load($data{resource});

  ## fallbacks for font settings
  $config{fonts}{small}	    ||= 'Helvetica 10';
  $config{fonts}{smfixed}   ||= 'Courier 10';
  $config{fonts}{fixed}	    ||= 'Courier 11';
  $config{fonts}{largebold} ||= 'Helvetica 14 bold';
  $config{fonts}{medbold}   ||= 'Helvetica 12 bold';
  $config{fonts}{smbold}    ||= 'Helvetica 10 bold';

  ## use Data::Dumper;
  ## print Data::Dumper->Dump([$config_ref], [qw(*config)]);

  $config_ref -> WriteConfig(Ifeffit::FindFile->find("hephaestus", "rc_personal"));
};

sub help {
  my $podfile = File::Spec->catfile(Ifeffit::FindFile->find("athena", "augpod"),
				    "hephaestus.pod");
  if (-e $podfile) {
    ## redisplay the pod file every time in case the user has clicked elsewhere
    ## in the Athena User's Guide
    $bottom{help} = $main->PodText(-file => "hephaestus.pod", -scrollbars=>'ose');
    $periodic_table -> packForget() if $current =~ /$uses_periodic_regex/;
    switch({page=>"help", text=>'Hephaestus Document'});
    $top -> title('Hephaestus'); # Tk::Pod overwrites top's title, grrr...!
  } else {
    my $info = <<'EOH'
It seems that you have not installed the Athena User's Guide, which includes
the Hephaestus document.

The User's Guide is distributed separately from the rest of the horae
software.  Go to

http://cars9.uchicago.edu/iffwiki/BruceRavel/AthenaUsersGuide

and follow the simple installation instructions.

EOH
      ;
    $info =~ s{\n}{ }g;		## tidy up for display
    $info =~ s{ }{\n\n}g;
    my $dialog =
      $top -> Dialog(-bitmap         => 'info',
		     -text           => $info,
		     -title          => 'Hephaestus: Missing document',
		     -buttons        => [qw/OK/],
		     -default_button => 'OK');
    my $response = $dialog->Show();
  };
};
