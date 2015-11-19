#!/usr/bin/perl -w
######################################################################
## DAFS notecard module for Atoms 3.0beta9
##                                     copyright (c) 1999 Bruce Ravel
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

package Xray::Tk::Dafs;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Xray::Tk::Utils);
@EXPORT_OK = qw(dafs);
$cvs_info = '$Id: Dafs.pm,v 1.8 2001/09/22 00:54:23 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

require Tk;
require Xray::Atoms;
use Xray::ATP;
use Xray::Scattering;
($::ifeffit_exists) && require Xray::Tk::Plotter;
use Xray::Tk::Utils;
#use Ifeffit qw(ifeffit);
use constant PI    => 3.14159265358979323844;
use constant RE    => 0.00002817938;
use constant HBARC => 1973.27053324;
use File::Basename qw(dirname);
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));


### >> dafs control panel

######################################################################
#########                                     ########################
#########  Notecard containing DAFS keywords  ########################
#########                                     ########################
######################################################################

my %dafs_values = ('h'	       => 0,	   # miller indeces
		   'k'	       => 0,       #
		   'l'	       => 0,       #
		   'emin'      => 300, 	   # energy grid
		   'emax'      => 500,     #
		   'estep'     => 15,      #
		   'table'     => 'cl',    # default data resource
		   ##'edge'     => '',	   # initial edge symbol
		   'progress'  => 152,	   # y size of progress meter
		   'canvas'    => 282,	   # x size of plot canvas
		   'npoints'   => 12,	   # number of points in calc.
		   'atp'       => 'dafs',
		   'thickness' => 1,
		   'plot_group' => '',
		  );
## widgets:
my ($dafs_progress, $dafs_done, $dafs_todo, $dafs_plot, $dafs_data,
    @dafs_tics, $dafs_title, %dafs_buttons, @dafs_calculation);
use vars qw(@dafs_x @dafs_y);
@dafs_x = (); @dafs_y = ();
## array for passing to parse_atp
my ($dafs_frame, $menubar);
my $dafs_running = 0;

##my $up_img = File::Spec->catfile($::xtal_dir, 'up.xbm');
##my $dn_img = File::Spec->catfile($::xtal_dir, 'dn.xbm');


sub dafs {
  ##$dafs_frame = $_[0] -> Frame() -> pack(-fill=>'x');
  $dafs_frame = $::pages{DAFS} -> Frame() -> pack(-fill=>'x');

  ## ---- menubar -----------
  $menubar = $dafs_frame -> Frame(-borderwidth=>2, -relief=>'ridge',)
    -> pack(-anchor=>'nw', -fill=>'x', -pady=>4, -padx=>4);

  my $file_menu = $menubar ->
    Menubutton(@::file_menubutton)  -> pack(-side=>'left');
  &::manage($file_menu, "menu");
  my $this = $file_menu
    -> command(-label=>$$::labels{load_input}, @::menu_args,
	       -command=>\&::load_input,
	       -accelerator=>'Control+o', );
  &::manage($this, "menu");
  ($::LWP_simple_exists) and do {
    $this = $file_menu
      -> command(-label=>$$::labels{load_adb}, @::menu_args,
		 -command=>\&::load_adb, );
    &::manage($this, "menu");
    $this = $file_menu
      -> command(-label=>$$::labels{download_adb}, @::menu_args,
		 -command=>\&::download_adb, );
    &::manage($this, "menu");
  };
  my $recent = $file_menu ->
    cascade(-label=>"Recent files", @::menu_args, -tearoff=>0,);
  &::manage($recent, "menu");
  push @::recent_registry, $recent;
  foreach my $f (@::recent_files) {
    $recent -> command(-label=>$f, -command=>sub{&::load_input($f, 1)});
  };

  my $sep = $file_menu -> separator();
  &::manage($sep, "separator");
  $this = $file_menu
    -> command(-label=>$$::labels{save_input}, @::menu_args,
	       -command=>\&::save_input,
	       -accelerator=>'Control+s', );
  &::manage($this, "menu");
  $this = $file_menu ->
    command(-label=>$$::labels{save_dafs_data}, @::menu_args,
	    -command=>[\&save_dafs, 'dat'],);
  &::manage($this, "menu");
  unless ($::ifeffit_exists) {
    $this = $file_menu ->
      command(-label=>$$::labels{save_dafs_ps}, @::menu_args,
	      -command=>[\&save_dafs, 'ps'],);
    &::manage($this, "menu");
  };
  ##   $sep = $file_menu -> separator();
  ##   &::manage($sep, "separator");
  ##   $this = $file_menu -> command(@::apt_args);
  ##   &::manage($this, "menu");
  $sep = $file_menu -> separator();
  &::manage($sep, "separator");
  $this = $file_menu
    -> command(-label=>$$::labels{quit}, @::menu_args,
	       -command=>\&::quit_tkatoms,
	       -accelerator=>'Control+q', );
  &::manage($this, "menu");


  my $clear_menu = $menubar ->
    Menubutton(-text=>$$::labels{clear_menu}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($clear_menu, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{clear_dafs}, @::menu_args,
	    -command=>\&clear_dafs);
  &::manage($this, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{clear_lattice}, @::menu_args,
	    -command=>\&::clear_lattice);
  &::manage($this, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{clear_all}, @::menu_args,
	    -command=>sub{&clear_dafs; &::clear_lattice});
  &::manage($this, "menu");

  if ($::ifeffit_exists) {
    my $plot_menu = $menubar ->
      Menubutton(-text=>$$::labels{plot_menu}, @::menu_args) ->
	pack(-side=>'left');
    &::manage($plot_menu, "menu");
    $this = $plot_menu ->
      command(-label=>$$::labels{newplot}, @::menu_args,
	      -command=>\&newplot,);
    &::manage($this, "menu");
    $this = $plot_menu ->
      command(-label=>$$::labels{overplot}, @::menu_args,
	      -command=>\&overplot,);
    &::manage($this, "menu");
    $this = $plot_menu ->
      command(-label=>$$::labels{plotgif}, @::menu_args,
	      -command=>[\&saveplot, 'gif', 'dafs'],);
    &::manage($this, "menu");
    $this = $plot_menu ->
      command(-label=>$$::labels{plotps}, @::menu_args,
	      -command=>[\&saveplot, 'ps', 'dafs'],);
    &::manage($this, "menu");
  };

  my $help_menu = $menubar ->
    Menubutton(@::help_menubutton)  -> pack(-side=>'right');
  &::set_help_menu($help_menu);

  my $pref_menu = $menubar ->
    Menubutton(@::pref_menubutton)  -> pack(-side=>'right');
  &::set_pref_menu($pref_menu);

  &::manage($help_menu, "menu");
  &::manage($pref_menu, "menu");


  ## Descripton
  my $top_frame = $dafs_frame -> Frame()
    -> pack();
  my $label_frame = $top_frame -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-pady=>0, -side=>'left');
  my $dafs_label = $label_frame ->
    Label(-text=>$$::labels{'dafs_description'}, @::header_args, ) ->
      pack();
  &::manage($dafs_label, "header");


  my $dframe = $dafs_frame -> Frame() -> pack(-fill=>'x', -pady=>2);


  ## ---- frame with reflection widgets -------------------------
  my $dfleft = $dframe -> Frame()
    -> pack(-side=>'left', -padx=>0, -pady=>0, -anchor=>'n');

  my $dfhkl = $dfleft -> LabFrame(-label=>$$::labels{reflection},
				  -foreground=>$::colors{label},
				  -labelside=>'acrosstop',
				  -borderwidth=>2,)
    -> pack(-side=>'top', -pady=>2, -padx=>2);
  $::balloon->attach(($dfhkl->children)[1], -msg=>$$::help{reflection},);
  &::manage($dfhkl, "labframe");


  my $up_bitmap = "#define up_width 14
#define up_height 13
static unsigned char up_bits[] = {
   0xc0, 0x00, 0xc0, 0x00, 0xe0, 0x01, 0xe0, 0x01, 0xf0, 0x03, 0xf0, 0x03,
   0xf8, 0x07, 0xf8, 0x07, 0xfc, 0x0f, 0xfc, 0x0f, 0xfe, 0x1f, 0xfe, 0x1f,
   0x00, 0x00};";
  my $up_img = $dfhkl -> Bitmap('up', -data=>$up_bitmap,
				-foreground=>$::colors{entry});
  my $dn_bitmap = "#define dn_width 14
#define dn_height 13
static unsigned char dn_bits[] = {
   0xfe, 0x1f, 0xfe, 0x1f, 0xfc, 0x0f, 0xfc, 0x0f, 0xf8, 0x07, 0xf8, 0x07,
   0xf0, 0x03, 0xf0, 0x03, 0xe0, 0x01, 0xe0, 0x01, 0xc0, 0x00, 0xc0, 0x00,
   0x00, 0x00};";
  my $dn_img = $dfhkl -> Bitmap('dn', -data=>$dn_bitmap,
				-foreground=>$::colors{entry});

  my $dcol = 0;
  foreach my $m ('h', 'k', 'l') {
    $this = $dfhkl -> Label(-text=>$m, -font=>$::fonts{header},
			    -foreground=>$::colors{label})
      -> grid(-column=>$dcol, -row=>1);
    &::manage($this, "label");
    my $up = $dfhkl -> Button(#-text=>"^",
			      @::button_args,
			      -command=>sub{++$dafs_values{$m}},
			      -image => $up_img,
			     )
      -> grid(-column=>$dcol, -row=>2);
    $::balloon -> attach($up, -msg=>$$::help{reflection_up});
    &::manage($up, "button");
    $this = $dfhkl -> Entry(-textvariable=>\$dafs_values{$m}, @::entry_args,
			    -width=>3, -justify=>'center', -relief=>'sunken')
      -> grid(-column=>$dcol, -row=>3);
    &::manage($this, "entry");
    my $dn = $dfhkl -> Button(#-text=>"v",
			      @::button_args,
			      -command=>sub{--$dafs_values{$m}},
			      -image => $dn_img,
			     )
      -> grid(-column=>$dcol, -row=>4);
    $::balloon -> attach($dn, -msg=>$$::help{reflection_dn});
    &::manage($dn, "button");
    ++$dcol;
  };



  my $atp_frame = $dfleft -> Frame() -> pack(-side=>'bottom', -pady=>1);
  my $atp_button = $atp_frame
    -> Optionmenu(-textvariable     => \$dafs_values{'atp'},
		  -background       => $::colors{'entry'},
		  -activeforeground => $::colors{'label'},
		  -activebackground => $::colors{'entry'},
		  -width=>6, -font=>$::fonts{'label'}, -relief=>'groove')
      -> pack(-side=>'right');
  &::manage($atp_button, "menu");
  my $atp_label = $atp_frame ->
    Label(-text=>$$::labels{outfiles}, @::label_args)
      -> pack(-side=>'left');
  $::balloon->attach($atp_label, -msg=>$$::help{'output_files'},);
  &::manage($atp_label, "label");

  foreach my $e (@::atpfiles) {
    if ($e =~ /dafs/i) {
      $this = $atp_button ->
	command(-label => $e, @::menu_args,
		-command=>sub{$dafs_values{'atp'}=$e;});
      &::manage($this, "menu");
    };
  };


  my $thickness_frame = $dfleft -> Frame() -> pack(-side=>'bottom', -pady=>1);
  my $thickness_label = $thickness_frame ->
    Label(-text=>$$::labels{thickness}, @::label_args)
      -> pack(-side=>'left');
  $::balloon->attach($thickness_label, -msg=>$$::help{'thickness'},);
  &::manage($thickness_label, "label");
  my $thickness_entry = $thickness_frame ->
    Entry(-textvariable=>\$dafs_values{thickness}, @::entry_args,
	  -width=>6, -relief=>'sunken')
      -> pack(-side=>'left');
  &::manage($thickness_entry, "entry");
  my $angstrom_label = $thickness_frame ->
    Label(-text=>'A', @::label_args)
      -> pack(-side=>'left');
  &::manage($angstrom_label, "label");



  ## -------------------------------------------------------------



  ## ---- frame with energy grid and data resource widgets -------
  my $dfright = $dframe -> Frame()
    -> pack(-side=>'left', -padx=>0, -pady=>2, -anchor=>'n');


  $dcol = 0;
  my $dfenergy = $dfright -> LabFrame(-label=>$$::labels{energy_grid},
				      -foreground=>$::colors{label},
				      -labelside=>'acrosstop',
				      -borderwidth=>2)
    -> pack(-side=>'top', -padx=>0, -anchor=>'n');
  &::manage($dfenergy, "labframe");
  foreach my $e ('emin', 'emax', 'estep') {
    my $label = $dfenergy -> Label(-text=>$$::labels{$e}, @::label_args)
      -> grid(-column=>$dcol, -row=>1);
    $::balloon -> attach($label, -msg=>$$::help{$e});
    &::manage($label, "label");
    my $entry = $dfenergy ->
      Entry(-textvariable=>\$dafs_values{$e}, @::entry_args,
	    -width=>6, -justify=>'center', -relief=>'sunken')
	-> grid(-column=>$dcol, -row=>2);
    &::manage($entry, "entry");
    ++$dcol;
  };
  $::balloon->attach(($dfenergy->children)[1], -msg=>$$::help{energy_grid},);


  my %dafs_resource_button;
  my $dfresource = $dfright -> LabFrame(-label=>$$::labels{data_resources},
					-foreground=>$::colors{label},
					-labelside=>'acrosstop',
					-borderwidth=>2)
    -> pack(-side=>'top');
  $::balloon->attach(($dfresource->children)[1], -msg=>$$::help{data_resources},);
  &::manage($dfresource, "labframe");
  my $dafs_resource_frame = $dfresource
    -> Scrolled("Text", -scrollbars=>'e', -height=>5, -width=>13,
		-relief=>'flat',)
      -> pack();
  $dafs_resource_frame->Subwidget("yscrollbar")->configure(-background=>$::colors{background});
  foreach my $resource (sort(Xray::Absorption->available)) {
    next if ($resource =~ /(elam|mcmaster|none)/i);
    my $r = lc($resource);
    $dafs_resource_button{lc($r)} = $dafs_resource_frame
      -> Radiobutton(-text => $resource, @::menu_args,
		     -selectcolor=>$::colors{radio},
		     -variable=>\$::absorption_tables,
		     -value=>$r,
		     -justify=>'left',
		     -command=>sub{ Xray::Absorption->load($r);
				    $::absorption_tables = $r; });
    &::manage($dafs_resource_button{lc($r)}, "radio");
    $dafs_resource_frame
      -> windowCreate('end', -window=>$dafs_resource_button{lc($r)});
    $dafs_resource_frame -> insert('end', $/);
    $::balloon->attach($dafs_resource_button{lc($r)}, -msg=>$$::help{lc($r)});
  }
  $dafs_resource_frame -> configure(-state=>'disabled');
  ## -------------------------------------------------------------

  my $dfrun = $dframe -> Frame()
    -> pack(-side=>'left', -pady=>2, -anchor=>'n');

  my $dfrun_buttons  = $top_frame -> Frame()
    -> pack(-side=>'right', -padx=>10, -pady=>0);
  my $dfrun_canvases = $dfrun -> Frame()
    -> pack(-side=>'bottom', -pady=>2);


  ## put buttons above canvas
  ## foreach my $s (qw/run_dafs save_dafs_data save_dafs_ps/) {
  ## $dafs_buttons{'run_dafs'} =
  do {
    my $button = $dfrun_buttons
      -> Button(-text=>$$::labels{'run_dafs'}, @::button_args, -borderwidth=>4,
		-command=>\&run_dafs)
	-> pack(-side=>'left', -padx=>2, -expand=>1 );
    $::balloon -> attach($button, -msg=>$$::help{'run_dafs'});
    &::manage($button, "button");
  };

##   $dafs_progress = $dfrun_canvases
##     -> Canvas(-width=>22, -height=>$dafs_values{'progress'},
## 	      -background=>$::colors{'todo'})
##       -> pack(-side=>'left', -anchor=>'e');
##   &::manage($dafs_progress, "canvas");
##   $::balloon -> attach($dafs_progress, -msg=>$$::help{'progress_meter'});
##   $dafs_done = $dafs_progress ->
##     createRectangle(1, $dafs_values{'progress'}, 21, $dafs_values{'progress'}-1,
## 		    -fill=>$::colors{'done'}, -tags=>"done");
##   &::manage($dafs_done, "progress");  ## ??????
##   ##push @::all_progress, $dafs_progress, "done";
##   $dafs_todo = $dafs_progress ->
##     createRectangle(1,1,21, $dafs_values{'progress'}-1,
## 		    -fill=>$::colors{'todo'});


  $dafs_plot = $dfrun_canvases
    -> Canvas(-width=>$dafs_values{'canvas'},
	      -height=>$dafs_values{'progress'},
	      -background=>$::colors{'todo'}
	     )
      -> pack(-side=>'right', -anchor=>'w');
  &::manage($dafs_plot, "canvas");
  ##if ((defined $::plotting_hook) and $::plotting_hook) {
  $::balloon ->
    attach($dafs_plot,
	   -msg=>$$::help{dafs_plot} . $/ . $$::help{plot_bindings});
  ##} else {
  ##  $::balloon -> attach($dafs_plot, -msg=>$$::help{dafs_plot});
  ##};
  $dafs_plot -> Tk::bind('<Button-1>', \&newplot);
  $dafs_plot -> Tk::bind('<Button-3>', \&overplot);
  $dafs_plot ->
    createRectangle(1,1,$dafs_values{'canvas'}, $dafs_values{'progress'},);
                    # -fill=>$::colors{'todo'});
  $dafs_plot ->
    createLine(36, 11, 36, $dafs_values{'progress'}-21);
  $dafs_plot ->
    createLine(36, $dafs_values{'progress'}-21, $dafs_values{'canvas'}-11,
	       $dafs_values{'progress'}-21);
  $dafs_plot ->
    createText($dafs_values{'canvas'}/2, $dafs_values{'progress'}-5,
	       -anchor=>'center', -font=>'Arial 10 normal',
	       -text=>$$::labels{energy_axis});
  $dafs_plot -> createText(qw/40 10 -anchor w -font/, 'Arial 10 normal',
			   -text=>$$::labels{intensity_axis});

  foreach my $i (0.25, 0.5, 0.75, 1) {
    tkatoms_make_tic(\$dafs_plot, $dafs_values{'canvas'},
		     $dafs_values{'progress'}, 'x', $i, 5);
    tkatoms_make_tic(\$dafs_plot, $dafs_values{'canvas'},
		     $dafs_values{'progress'}, 'y', $i, 5);
  };


};


sub newplot {
  require Xray::Tk::Plotter;
  my $key = join(" ", (map {sprintf "%d", $_} @{$::keywords->{'qvec'}}));
  &Xray::Tk::Plotter::plot_with_Ifeffit(\@dafs_x, \@dafs_y, 1, 'dafs',
					\$dafs_values{plot_group}, $key);
};
sub overplot {
  require Xray::Tk::Plotter;
  my $key = join(" ", (map {sprintf "%d", $_} @{$::keywords->{'qvec'}}));
  &Xray::Tk::Plotter::plot_with_Ifeffit(\@dafs_x, \@dafs_y, 0, 'dafs',
					\$dafs_values{plot_group}, $key);
};

### > dafs subroutines
## --------------------------------------------------------------------

## $dafs_running is an imperfect way of preventing problems from
## double clicking the run dafs button
sub run_dafs {
  ($dafs_running) and return;
  $dafs_running = 1;
  @dafs_calculation = ();
  $::cell -> make( Occupancy=>1 );
  undef $::keywords;
  $::keywords = Xray::Atoms -> new();
				# read the lattice and core data
  $dafs_running = 0;
  &::validate_lattice(0);
  $dafs_running = 1;
  my $core_tag = $::site_entries[$::core_index]{'tag'}->get();
  ($core_tag =~ /^\s*$/) and
    $core_tag = $::site_entries[$::core_index]{'elem'}->get();
  $::keywords -> make('core'=>$core_tag);
				# get reflection
  my ($h, $k, $l) = map {int} ($dafs_values{'h'}, $dafs_values{'k'},
			       $dafs_values{'l'});
  $::keywords -> make('thickness'=>$dafs_values{'thickness'});
  unless ($h or $k or $l) {
    $dafs_running = 0;
    die $$::messages{'no_reflection'}.$/;
  };
  $::keywords -> make('qvec'=> $h, $k, $l);
				# get central atom element
  my ($central, $xc, $yc, $zc) = $::cell -> central($::keywords->{'core'});
				# get edge
  $::keywords->make('edge' => $::atoms_values{'edge'});;
  $dafs_running = 0;
  $::keywords->set_edge($::cell, 1);
  $dafs_running = 1;
  $::atoms_values{'edge'} = $::keywords->{'edge'};
				# energy grid
  my ($e0, $emin, $emax, $estep, $npoints);
  ($e0, $emin, $emax, $estep, $npoints) =
    dafs_set_grid($central, $::keywords->{'edge'}, $dafs_values{'emin'},
		  $dafs_values{'emax'}, $dafs_values{'estep'});
  $::keywords -> make('emin'=>$emin, 'emax'=>$emax, 'estep'=>$estep);
  ($dafs_values{'emin'}, $dafs_values{'emax'}, $dafs_values{'estep'},
   $dafs_values{'npoints'}) = ($e0-$emin, $emax-$e0, $estep, $npoints);
  my ($e, $cnt) = ($emin, 0);
				# finish up cell
  $dafs_running = 0;
  $::keywords -> verify_keywords($::cell, \@::sites, 1);
  $dafs_running = 1;
				# cache f0 and phases
  my (%fnot, @phase, @dwf);
  &dafs_set_cache($::cell, \%fnot, \@phase, \@dwf, $h, $k, $l);
				# clean up previous plot
##   update_progress_bar(\$dafs_progress, \$dafs_done, \$dafs_todo,
## 		      0, $dafs_values{'progress'});
  $dafs_plot -> delete($dafs_data);
  $dafs_plot -> delete($dafs_title);
  @dafs_tics = map {$dafs_plot -> delete($_)} @dafs_tics;
				# calculate
  my (%fp, %fpp, $r, $i, $la, %mu, $mutot, @plot);
  my ($contents) = $::cell -> attributes("contents");
  (Xray::Absorption -> current_resource =~ /$::meta{absorption_tables}/i) or do {
    $::meta{absorption_tables} =
      grep (/CL/, Xray::Absorption -> available()) ? "CL" : "Henke";
    Xray::Absorption -> load($::meta{absorption_tables});
  };
  (Xray::Absorption->current_resource =~ /\b(Henke|Chantler|CL|Sasaki)\b/i)
    or do {
      $::meta{absorption_tables} =
	grep (/CL/, Xray::Absorption -> available()) ? "CL" : "Henke";
      Xray::Absorption -> load($::meta{absorption_tables});
    };
  my ($min, $max) = (100000, 0);

  ## normalization terms for Lorentz-Absorption correction
  ($::keywords->{thickness} > 0) or ($::keywords->{thickness} = 1);
  my $lambda = 2*PI*HBARC / $e;
  my $dsp = $::cell -> d_spacing($h, $k, $l);
  my $sinthnot = $lambda / (2 * $::cell -> d_spacing($h, $k, $l));
  my $munot = Xray::Atoms::xsec($::cell, $central, $e);
  $munot *= 10e-8; #undef $dens;
  my $absnot = (1 - exp(-2*$::keywords->{thickness}*$munot/$sinthnot)) /
    (2*$munot);
  $sinthnot = sin(2*asin($sinthnot));
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
      $ {$mu{$l}}[$i] = 2*RE * $lambda * $ {$fpp{$l}}[$i] *
	0.6022045 * 1e8 * $factor / $weight;
    };
    ##@{$mu{$_}}  = Xray::Absorption -> cross_section($_, \@energies, 'xsec');
  };
  my @total = Xray::Atoms::xsec($::cell, $central, \@energies);
  ## ------------------------------------------------------------------------

  my $pt = 0;
  while ($e < $emax) {
    ($r, $i) = (0,0);		 ## clear these at each energy
    my $counter = 0;
    $mutot = 0;
    $lambda = 2*PI*HBARC / $e;
    $sinth = $lambda / (2 * $dsp);
    foreach my $s (@{$contents}) {
      my ($el, $sym, $occ, $id) =
	$ {$$s[3]} -> attributes('Element', 'CromerMann', 'Occupancy', 'Id');
      my $phase = $phase[$counter];
      my $dwf   = $dwf[$counter];
      my $fone  = $fnot{$sym} + $ {$fp{$el}}[$pt];
      my $ftwo  = $ {$fpp{$el}}[$pt];
      ## do the complex arithmatic by hand
      $r += $occ * $dwf * ($fone * cos($phase) - $ftwo * sin($phase));
      $i += $occ * $dwf * ($fone * sin($phase) + $ftwo * cos($phase));
      $mutot += $occ * $ {$mu{$el}}[$pt];
      ++$counter;
    };
    ## Lorentz and absoprtion correction
    ##my ($total, $density) = map {sprintf "%8.2f", $_}
    ##  Xray::Atoms::xsec($::cell, $central, $e);
    $total[$pt] *= 10e-8;
    $la     = (1 - exp(-2*$::keywords->{thickness}*$total[$pt]/$sinth)) /
      (2*$total[$pt]);
    $la    /= $absnot;
    $sinth  = sin(2*asin($sinth));
    $la    *= ($emin**3 * $sinthnot) / ($e**3 * $sinth);
    my $this_energy = [$e, $r, $i, $la];
    my $as = $la*($r**2 + $i**2);
    my $this_point = [$e, $as];
    ($as > $max) and $max = $as;
    ($as < $min) and $min = $as;
    #print join(" ", $e, $r, $i), $/;
    push @dafs_calculation, $this_energy;
    push @plot, $this_point;
    ++$cnt;
    ## ($cnt % 10) or
    ##   update_progress_bar(\$dafs_progress, \$dafs_done, \$dafs_todo,
    ##			  $cnt/$dafs_values{'npoints'},
    ##			  $dafs_values{'progress'});
    $e += $estep;			# increment energy
    ++$pt;
  };
  ## if ($::convolve_dafs) { do a convolution };
  ## update_progress_bar(\$dafs_progress, \$dafs_done, \$dafs_todo,
  ##		      1, $dafs_values{'progress'});

  ($min, $max) = (int(0.9*$min), int(1.1*$max));
  my $yspan = ($max-$min) || (0.1);
  my $espan = ($emax-$emin);

  my @to_plot;
  @dafs_x = (); @dafs_y = ();
  foreach my $p (@plot) {
    my ($x,$y) = @$p;
    push @dafs_x, $x;		# for external plot
    push @dafs_y, $y;		#
    ($x, $y) = ((($x-$emin)/$espan), (($y-$min)/$yspan)); # fractional
    ($x, $y) = tkatoms_fraction2canvas($dafs_values{canvas},
				       $dafs_values{progress},$x, $y); # on canvas
    push @to_plot, $x, $y; 			          # integers
  };
  $dafs_data = $dafs_plot -> createLine(@to_plot, -fill=>$::colors{'plot'});
    foreach my $i (0..4) {
    my $f = $i * 0.25;
    my @font = ('-font', 'Arial 9 normal');
				# x tics
    my ($xp, $yp) = tkatoms_fraction2canvas($dafs_values{canvas},
					    $dafs_values{progress},$f, 0);
    $dafs_tics[$i] = $dafs_plot
      -> createText($xp, $yp+8, qw/-anchor center/,
		    -text=>int($emin+$f*$espan), @font);
				# y tics
    next unless $i; # 1st y label overlaps 1st x label
    ($xp, $yp) = tkatoms_fraction2canvas($dafs_values{canvas},
					 $dafs_values{progress},0,$f);
    $dafs_tics[$i+5] = $dafs_plot
      -> createText($xp-30, $yp, qw/-anchor w/,
		    -text=>int($min+$f*$yspan), @font);
  };
  my $title = ucfirst($central) . " " . ucfirst($dafs_values{'edge'}) .
    " (" . join(" ", $h, $k, $l) . ")";
  $dafs_title = $dafs_plot -> createText(200, 15, -text=>$title);
  $dafs_values{plot_group} = join("", $central, $h, $k, $l);

  $dafs_running = 0;
};


## ref to canvas, 'x' or 'y', percentage of full span, height in
## pixels of tic
sub dafs_make_tic {
  my ($canvas, $axis, $value, $size) = @_;
  my ($x1, $y1, $x2, $y2);
  if ($axis eq 'x') {
    $value *= ($dafs_values{'canvas'}-36-11);
    $x1 = int($value)+36;
    $y1 = $dafs_values{'progress'}-21;
    $x2 = int($value)+36;
    $y2 = $dafs_values{'progress'}-21-$size;
  } else {
    $value *= $dafs_values{'progress'}-21-11;
    $value  = $dafs_values{'progress'}-21-11-int($value);
    $x1 = 36;
    $y1 = $value+11;
    $x2 = 36+$size;
    $y2 = $value+11;
  };
  $$canvas -> createLine($x1, $y1, $x2, $y2);
  1;
}

sub dafs_fraction2canvas {
  my ($x, $y) = @_;
  $x  = $x*($dafs_values{'canvas'}-36-11) + 36;
  $y *= $dafs_values{'progress'}-16-11;
  $y  = $dafs_values{'progress'}-16-11 - $y + 11;
  return (sprintf("%d", $x), sprintf("%d", $y));
};



## turn relative bounds into absolute bounds, and do error checking
sub dafs_set_grid {
  my ($central, $edge, $emin, $emax, $estep) = @_;
  my $e0 = Xray::Absorption -> get_energy($central, $edge);
  $emin ||= 300;
  $emax ||= 500;
  ($emin, $emax) = ($e0-$emin, $e0+$emax);
  $estep ||= 15;
  ($estep <= 0) and $estep = 15;	# some error checking
  ($emin > $emax) and ($emin, $emax) = ($emax, $emin);
  my $npoints = int(($emax - $emin)/$estep) + 1;
  return ($e0, $emin, $emax, $estep, $npoints);
}


## my (%fnot, @phase);
## &dafs_set_cache($::cell, \%fnot, \@phase, $h, $k, $l);
sub dafs_set_cache {
  my ($cell, $r_fnot, $r_phase, $r_dwf, $h, $k, $l) = @_;
  my ($contents) = $cell -> attributes("contents");
  my $counter = 0;
  my $d = $cell -> d_spacing($h, $k, $l);
  foreach my $s (@{$contents}) {
    my ($e, $v, $b, $bx, $by, $bz) =
      $ {$$s[3]} -> attributes('Element', 'Valence', 'B', 'Bx', 'By', 'Bz');
    ##--## ($bx, $by, $bz) = &dafs_interpret_dwf($bx, $by, $bz);
    ## print join("  ", $b, $/);
    my $sym = Xray::Scattering->get_valence($e, $v);
    $ {$$s[3]} -> make('CromerMann'=>$sym);
    $$r_fnot{$sym} = Xray::Scattering->get_f($sym, $d);
    $$r_phase[$counter]  = $$s[0] * $h + $$s[1] * $k + $$s[2] * $l;
    $$r_phase[$counter] *= 2*PI;
    $$r_dwf[$counter]    = $b * ($h**2 + $k**2 + $l**2);
    ##--## $$r_dwf[$counter]    = $bx*$h**2 + $by*$k**2 + $bz*$l**2;
    ## is this right?  or should it be -1/2 for when the structure
    ## factor gets squared
    $$r_dwf[$counter]    = exp(-1 * $$r_dwf[$counter]);
    ++$counter;
  };
};

sub dafs_interpret_dwf {
  my ($bx, $by, $bz) = @_;
  my $epsi = $Xray::Atoms::epsilon;
  my $default = 0;
  if ($bx > $epsi) {
    $default = $bx;
  } elsif ($by > $epsi) {
    $default = $by;
  } elsif ($bz > $epsi) {
    $default = $bz;
  };
  ($bx < $epsi) and $bx = $default;
  ($by < $epsi) and $by = $default;
  ($bz < $epsi) and $bz = $default;
  return ($bx, $by, $bz);
};

sub update_progress_bar {
  my ($canvas, $done, $todo, $percent, $scale) = @_;
  --$scale;
  ($percent > 1) and $percent = 1;
  ($percent < 0) and $percent = 0;
  my $h = int($percent*$scale);
  $h = $scale - $h;
  my $hp = $h+1;
  ($hp > $scale) and $hp = $scale;
  $$canvas ->delete($$done);
  $$canvas ->delete($$todo);
  $$done = $$canvas -> createRectangle(1, $hp, 21, $scale, -fill=>$::colors{'done'});
  $$todo = $$canvas -> createRectangle(1, 1, 21, $h, -fill=>$::colors{'todo'});
  $::top->update;
};

sub save_dafs {
  my $ext = $_[0];
  (@dafs_calculation) or die $$::dialogs{'no_calculation'}.$/;
  my $showall = ($ext eq 'dat') ? 'YES' : 'NO';
  require Cwd;
  my $path = $::default_filepath || Cwd::cwd();
  my $fname =
    join("", 'dafs_', (map {sprintf "%d", $_} @{$::keywords->{'qvec'}}),
	 ".", $ext);
  my $types = [['Dat files', '.dat'],
	       ['All Files', '*', ],];
  my $ofile = $::top -> getSaveFile(-filetypes=>$types,
				    -initialdir=>$path,
				    #(not $is_windows) ?
				    #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				    -initialfile=>$fname,
				    -title => $$::labels{'save_dialog'});
  return 0 unless $ofile;
  $::default_filepath = dirname($ofile);
  if ($ext eq 'dat') {		# save data using dafs.atp
    my $contents = "";
    $::keywords->make('identity'=>"TkAtoms $Xray::Atoms::VERSION");
    my ($ofname, $is_feff)
      = parse_atp($dafs_values{'atp'}, $::cell, $::keywords,
		  \@dafs_calculation, \@::neutral,\$contents);
    open (OUT, ">".$ofile) or
      die $$Xray::Atoms::messages{cannot_write} . $ofile . $/;
    print OUT $contents;
    close OUT;
  } else {			# save canvas as postscript
    $dafs_plot->postscript(-file=>$ofile);
  };
}

sub clear_dafs {
  $dafs_values{'h'}     = 0;
  $dafs_values{'k'}     = 0;
  $dafs_values{'l'}     = 0;
  $dafs_values{'emin'}  = 300;
  $dafs_values{'emax'}  = 500;
  $dafs_values{'estep'} = 15;
  ##$dafs_values{'edge'}  = '';
  ##update_progress_bar(\$dafs_progress, \$dafs_done, \$dafs_todo,
  ##		      0, $dafs_values{'progress'});
  $dafs_plot -> delete($dafs_data);
  $dafs_plot -> delete($dafs_title);
  @dafs_tics = map {$dafs_plot -> delete($_)} @dafs_tics;
  1;
};

sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) };


1;
__END__
