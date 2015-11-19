#!/usr/bin/perl -w
######################################################################
## Powder notecard module for Atoms 3.0beta9
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

package Xray::Tk::Powder;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(powder);
$cvs_info = '$Id: Powder.pm,v 1.3 2001/09/22 00:52:39 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

require Tk;
require Xray::Atoms;
use Xray::ATP qw(parse_atp);
use Xray::Scattering;
($::ifeffit_exists) && require Xray::Tk::Plotter;
use Xray::Tk::Utils;
use constant EPSI  => 0.01;
use constant PI    => 4 * atan2 1, 1;
use constant HBARC => 1973.27053324;


my $plot_cmd = \&Xray::Tk::Plotter::plot_with_Ifeffit;

my ($pow_frame, $menubar);
my $this;



Xray::Absorption -> load('Elam');
my %powder_values = (running      => 0,
		     energy_given => Xray::Absorption->get_energy('Cu', 'Kalpha1'),
		     line         => '',
		     order        => 12,
		     atp          => 'powder',
		     height       => 152, # y size of plot canvas
		     width        => 282, # x size of plot canvas
		     powder_group => '',
		     );
my @all_lines = ('cu_kalpha1', 'cu_kalpha2', 'co_kalpha1', 'co_kalpha2', 'mo_kalpha1', 'mo_kalpha2');
my @powder_tics;
my ($powder_plot, @powder_data);
my (@powder_x, @powder_y);

sub powder {
  $pow_frame = $::pages{Powder} -> Frame() -> pack(-fill=>'x');

  ## ---- menubar -----------
  $menubar = $pow_frame -> Frame(-borderwidth=>2, -relief=>'ridge',)
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
  unless ($::ifeffit_exists) {
    $this = $file_menu ->
      command(-label=>$$::labels{save_dafs_ps}, @::menu_args,
	      -command=>[\&save_dafs, 'ps'],);
    &::manage($this, "menu");
    $sep = $file_menu -> separator();
    &::manage($sep, "separator");
  };
  ## $this = $file_menu -> command(@::apt_args);
  ## &::manage($this, "menu");
  $sep = $file_menu -> separator();
  &::manage($sep, "separator");
  $this = $file_menu
    -> command(-label=>$$::labels{quit}, @::menu_args,
	       -command=>\&::quit_tkatoms,
	       -accelerator=>'Control+q', );
  &::manage($this, "menu");


  my $clear_menu = $menubar ->
    Menubutton(-text=>$$::labels{'clear_menu'}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($clear_menu, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{'clear_powder'}, @::menu_args,
	    -command=>\&clear_powder);
  &::manage($this, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{'clear_lattice'}, @::menu_args,
	    -command=>\&::clear_lattice);
  &::manage($this, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{'clear_all'}, @::menu_args,
	    -command=>sub{&clear_powder; &::clear_lattice});
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
	      -command=>[\&saveplot, 'gif', 'powder'],);
    &::manage($this, "menu");
    $this = $plot_menu ->
      command(-label=>$$::labels{plotps}, @::menu_args,
	      -command=>[\&saveplot, 'ps', 'powder'],);
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
  my $top_frame = $pow_frame -> Frame()
    -> pack(-pady=>4, -side=>'top');
  my $pow_label_frame = $top_frame -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-side=>'left');
  my $pow_label = $pow_label_frame ->
    Label(-text=>$$::labels{'powder_description'}, @::header_args, ) ->
      pack(-side=>'left');
  &::manage($pow_label, "header");

  my $pow_button = $top_frame
    -> Button(-text=>$$::labels{'run_powder'}, @::button_args, -borderwidth=>4,
	      -command=>\&run_powder)
      -> pack(-side=>'right', -padx=>45, -expand=>1 );
  $::balloon -> attach($pow_button, -msg=>$$::help{'run_powder'});
  &::manage($pow_button, "button");


  my $bottom_frame = $pow_frame -> Frame() -> pack(-side=>'bottom');
  my $left_frame = $bottom_frame -> Frame() -> pack(-side=>'left', -padx=>5);

  ## --------- energy selection
  my $pow_energy = $left_frame -> LabFrame(-label=>$$::labels{energy},
					   -foreground=>$::colors{label},
					   -labelside=>'acrosstop',
					   -relief=>'flat',
					   -borderwidth=>2)
    -> pack(-pady=>5);
  $::balloon->attach(($pow_energy->children)[1],
		     -msg=>$$::help{powder_energy},);
  &::manage($pow_energy, "labframe");

  my $entry = $pow_energy
    -> Entry(-textvariable=>\$powder_values{energy_given}, @::entry_args,
	     -width=>10, -relief=>'sunken')
      -> pack(-side=>'top', -padx=>2, -pady=>2);
  &::manage($entry, "entry");

  my $line_button = $pow_energy
    -> Optionmenu(-textvariable     => \$$::labels{choose_line},
		  -background       => $::colors{'entry'},
		  -activeforeground => $::colors{'label'},
		  -activebackground => $::colors{'entry'},
		  -width=>12, -font=>$::fonts{'label'}, -relief=>'groove')
      -> pack(-side=>'bottom', -padx=>2, -pady=>2);
  &::manage($line_button, "menu");


  foreach my $en (@all_lines) {
    my $label = join(" ", map {ucfirst($_)} (split(/_/, $en)));
    my $this = $line_button ->
      command(@::menu_args,
	     -label	  => $label,
	     -command	  => sub{&powder_set_line($en)},
	    );
    &::manage($this, "menu");
  };

  ## --------- atp choice
  my $atp_frame = $left_frame -> Frame() -> pack(-side=>'bottom', -pady=>5);
  my $atp_label = $atp_frame ->
    Label(-text=>$$::labels{outfiles}, @::label_args)
      -> pack();
  $::balloon->attach($atp_label, -msg=>$$::help{'output_files'},);
  &::manage($atp_label, "label");

  my $atp_button = $atp_frame
    -> Optionmenu(-textvariable     => \$powder_values{'atp'},
		  -background       => $::colors{'entry'},
		  -activeforeground => $::colors{'label'},
		  -activebackground => $::colors{'entry'},
		  -width=>6, -font=>$::fonts{'label'}, -relief=>'groove')
      -> pack();
  &::manage($atp_button, "menu");

  foreach my $e (@::atpfiles) {
    if ($e =~ /powder/i) {
      $this = $atp_button ->
	command(-label => $e, @::menu_args,
		-command=>sub{$powder_values{'atp'}=$e;});
      &::manage($this, "menu");
    };
  };





  ## --------- canvas
  my $canvas_frame = $bottom_frame -> Frame() -> pack(-side=>'right', -padx=>5);

  $powder_plot = $canvas_frame
    -> Canvas(-width=>$powder_values{'width'},
	      -height=>$powder_values{'height'},
	      -background=>$::colors{'todo'}
	     )
      -> pack(-side=>'right', -anchor=>'w');
  &::manage($powder_plot, "canvas");
  #if ((defined $::plotting_hook) and $::plotting_hook) {
  $::balloon ->
    attach($powder_plot,
	   -msg=>$$::help{powder_plot} . $/ . $$::help{plot_bindings});
  #} else {
  #  $::balloon -> attach($powder_plot, -msg=>$$::help{powder_plot});
  #};
  $powder_plot -> Tk::bind('<Button-1>', \&newplot);
  $powder_plot -> Tk::bind('<Button-3>', \&overplot);
  $powder_plot ->
    createRectangle(1,1,$powder_values{'width'}-1,
		    $powder_values{'height'}-1,);# -fill=>$::colors{'todo'});
  $powder_plot ->
    createLine(36, 11, 36, $powder_values{'height'}-21);
  $powder_plot ->
    createLine(36, $powder_values{'height'}-21, $powder_values{'width'}-11,
	       $powder_values{'height'}-21);
  $powder_plot ->
    createText($powder_values{'width'}/2, $powder_values{'height'}-5,
	       qw/-anchor center -font
	       -*-Courier-Medium-R-Normal--11-*-*-*-*-*-*-*/,
	       -text=>$$::labels{twotheta_axis});
  $powder_plot -> createText(qw/40 10 -anchor w -font
			   -*-Courier-Medium-R-Normal--11-*-*-*-*-*-*-*/,
			   -text=>$$::labels{intensity_axis});

  foreach my $i (0.25, 0.5, 0.75, 1) {
    tkatoms_make_tic(\$powder_plot, $powder_values{'width'},
		     $powder_values{'height'}, 'x', $i, 5);
    tkatoms_make_tic(\$powder_plot, $powder_values{'width'},
		     $powder_values{'height'}, 'y', $i, 5);
  };

  foreach my $i (0, 45, 90, 135, 180) {
    my @font = qw/-font -*-Courier-Medium-R-Normal--11-*-*-*-*-*-*-*/;
				# x tics
    my ($xp, $yp) = tkatoms_fraction2canvas($powder_values{'width'},
					    $powder_values{'height'}, $i/180, 0);
    $powder_plot
      -> createText($xp, $yp+8, qw/-anchor center/, -text=>$i, @font);
				# y tics
    next unless $i; # 1st y label overlaps 1st x label
    my $yy = $i/1.8;
    ($xp, $yp) = tkatoms_fraction2canvas($powder_values{'width'},
					 $powder_values{'height'}, 0, $i/180);
    $powder_plot
      -> createText($xp-30, $yp+6, qw/-anchor w/, -text=>int($yy), @font);
  };




  my $middle_frame = $bottom_frame -> Frame() -> pack(-side=>'right', -padx=>5);

  ## --------- LabFrame for data resource
  my %pow_resource_button;
  my $pow_resource = $middle_frame -> LabFrame(-label=>$$::labels{data_resources},
					       -foreground=>$::colors{label},
					       -labelside=>'acrosstop',
					       -borderwidth=>2)
    -> pack(-side=>'top', -pady=>5);
  $::balloon->attach(($pow_resource->children)[1],
		     -msg=>$$::help{data_resources},);
  &::manage($pow_resource, "labframe");
  my $pow_resource_frame = $pow_resource
    -> Scrolled("Text", -scrollbars=>'e', -height=>5, -width=>13,
		-relief=>'flat',)
      -> pack();
  $pow_resource_frame->Subwidget("yscrollbar")->configure(-background=>$::colors{background});
  foreach my $resource (sort(Xray::Absorption->scattering)) {
    my $r = lc($resource);
    $pow_resource_button{lc($r)} = $pow_resource_frame
      -> Radiobutton(-text => $resource, @::menu_args,
		     -selectcolor=>$::colors{radio},
		     -variable=>\$::absorption_tables,
		     -value=>$r, -font=>$::fonts{label},
		     -justify=>'left',
		     -command=>sub{ Xray::Absorption->load($r);
				    $::absorption_tables = $r; });
    &::manage($pow_resource_button{lc($r)}, "radio");
    $pow_resource_frame
      -> windowCreate('end', -window=>$pow_resource_button{lc($r)});
    $pow_resource_frame -> insert('end', $/);
    $::balloon->attach($pow_resource_button{lc($r)}, -msg=>$$::help{lc($r)});
  }
  $pow_resource_frame -> configure(-state=>'disabled');

  ## --------- entry box for max order
  my $order_frame = $middle_frame -> Frame() -> pack(-pady=>5);
  my $order_label = $order_frame
    -> Label(-text=>$$::labels{order}, @::label_args)
      -> pack(-side=>'left', -padx=>2);
  $::balloon -> attach($order_label, -msg=>$$::help{'powder_order'});
  &::manage($order_label, "label");

  $entry = $order_frame
    -> Entry(-textvariable=>\$powder_values{order}, @::entry_args,
	     -width=>3, -relief=>'sunken') -> pack(-side=>'right', -padx=>2);
  &::manage($entry, "entry");


};


sub newplot {
  require Xray::Tk::Plotter;
  #shift;
  my $key = $powder_values{energy_given} . " eV";
  &Xray::Tk::Plotter::plot_with_Ifeffit(\@powder_x, \@powder_y, 1, 'powder',
					\$powder_values{plot_group}, $key);
};
sub overplot {
  require Xray::Tk::Plotter;
  #shift;
  my $key = $powder_values{energy_given} . " eV";
  &Xray::Tk::Plotter::plot_with_Ifeffit(\@powder_x, \@powder_y, 0, 'powder',
					\$powder_values{plot_group}, $key);
};


sub powder_set_line {
  my $this = $_[0];
  my ($el, $en) = split(/_/, $this);
  my $res = Xray::Absorption -> current_resource;
  (lc($res) eq "elam") or Xray::Absorption -> load('Elam');
  $powder_values{energy_given} = Xray::Absorption -> get_energy($el, $en);
};


sub run_powder {

  ($powder_values{running}) and return;
  @powder_x = ();
  @powder_y = ();
  $powder_values{running} = 1;
  my @powder_calculation = ();
  $::cell -> make( Occupancy=>1 );
  undef $::keywords;
  $::keywords = Xray::Atoms -> new();
				# read the lattice and core data
  $powder_values{running} = 0;
  &::validate_lattice(0);
  $powder_values{running} = 1;
  $::keywords->make(identity => "Powder in TkAtoms $VERSION");
  $::keywords->make(energy   => $powder_values{energy_given});;
  $::keywords->make(maxorder => $powder_values{order});;
  my $max_order = $::keywords->{maxorder} || 12;
  ($max_order =~ /\d{1,3}/) or ($max_order = 12); # this will effectively untaint

  $powder_values{running} = 0;		# finish up cell
  $::keywords -> verify_keywords($::cell, \@::sites, 0, 1);
  $powder_values{running} = 1;

				# fixy up energy/lambda
  my $energy = $::keywords->{energy};
  my $lambda = 2*PI*HBARC / $energy;
  ## the cutoff with this trick is about 111.3
  ($lambda > $energy) and (($lambda, $energy) = ($energy, $lambda));
  $::keywords->make('energy'=>$energy, 'lambda'=>$lambda);

  # clean up previous plot
  map {$powder_plot -> delete($_)} @powder_data;

  my $match = "(" . join("|", Xray::Absorption->scattering) . ")";
  (Xray::Absorption->current_resource =~ /$match/i) or
     Xray::Absorption->load('CL');

   my $class = $::cell -> crystal_class;
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
    do {			# ortho, mono, tri
      $hrange = "(0 .. \$max_order)";
      $krange = "(0 .. \$max_order)";
      $lrange = "(0 .. \$max_order)";
      last CLASS;
    };
  };


  ## cache f' and f" for this site and this energy
  foreach my $this (@::sites) {
    my ($el) = $this -> attributes('Element');
    $this -> make(F1=>scalar Xray::Absorption->cross_section($el,$energy,'f1'));
    $this -> make(F2=>scalar Xray::Absorption->cross_section($el,$energy,'f2'));
  };

  my %peaks;
  foreach my $h (eval $hrange) {
    foreach my $k (eval $krange) {
      foreach my $l (eval $lrange) {
	next unless $h||$k||$l;	# watch out for (0,0,0)

	my %f0 = ();
	my $d = $::cell -> d_spacing($h, $k, $l);
	next if (($lambda / (2*$d)) > 1); # unreachable reflections at this energy

	my $theta   = asin($lambda / (2*$d));
	$theta     *= 180/PI;
	my $twoth   = $theta * 2;

	my ($real, $imag, $m) = (0, 0, 0);
	foreach my $s (@::sites) {
	  my ($positions, $tag, $elem, $occ, $f1, $f2, $b) =
	    $s -> attributes('Positions', 'Tag', 'Element',
			     'Occupancy', 'F1', 'F2', 'B');
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


  my $contents;
  my ($ofname, $is_feff)
    = parse_atp('powder', $::cell, $::keywords,
		\@calculation, \@::neutral, \$contents);
  &::display_in_frame($::top, \$contents, 'powder', $ofname, $is_feff);


  foreach my $line (split(/\n/, $contents)) {
    next if ($line =~/^\s*\#/);
    my @line = split(" ", $line);
    push @powder_x, $line[0], $line[0], $line[0];
    push @powder_y,       0,  $line[4],       0;
    my ($x, $y) = ($line[0]/180, $line[4]/100);
    my ($xz, $yz) = tkatoms_fraction2canvas($powder_values{width},
					    $powder_values{height}, $x, 0);
    ($x, $y) = tkatoms_fraction2canvas($powder_values{width},
				       $powder_values{height}, $x, $y);
    push @powder_data, $powder_plot -> createLine($xz, $yz, $x, $y,
						  -fill=>$::colors{plot});
  };

  $powder_values{plot_group} = "pow" . int($energy);
  $powder_values{running} = 0;

  1;
};


sub clear_powder {
  $powder_values{order} = 12;
  $powder_values{atp} = 'powder';
  $powder_values{energy_given} = Xray::Absorption->get_energy('Cu', 'Kalpha1');
  map {$powder_plot -> delete($_)} @powder_data;
};


sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }


1;
__END__
