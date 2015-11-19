#!/usr/bin/perl -w
######################################################################
## Absorption notecard module for Atoms 3.0beta9
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

package Xray::Tk::Absorption;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(absorption);
$cvs_info = '$Id: Absorption.pm,v 1.6 2001/09/20 17:53:14 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

use Tk;
require Xray::Atoms;
use Xray::ATP;
use File::Basename qw(dirname);
use constant EPSILON => 0.00001;
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));

$$::labels{edge_energy} = 'Edge energy:';
$$::help{edge_energy} = 'Blah blah blah';


my ($abs_frame, $menubar);
my ($abs_units, %absorption_label, %absorption_calculation,
    %absorption_entry, %absorption_widgets);


######################################################################
#########                                           ##################
#########  Notecard containing Absorption keywords  ##################
#########                                           ##################
######################################################################
sub absorption {
  #$abs_frame = $_[0] -> Frame() -> pack(-fill=>'x');
  $abs_frame = $::pages{Absorption} -> Frame() -> pack(-fill=>'x');

  ## ---- menubar -----------
  $menubar = $abs_frame -> Frame(-borderwidth=>2, -relief=>'ridge',)
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
  $this = $file_menu -> command(-label=>$$::labels{'save_absorption'},
				@::menu_args,
				-command=>\&save_absorption,);
  &::manage($this, "menu");
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
    Menubutton(-text=>$$::labels{'clear_menu'}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($clear_menu, "menu");
  $this = $clear_menu
    -> command(-label=>$$::labels{'clear_absorption'}, @::menu_args,
	       -command=>\&clear_absorption);
  &::manage($this, "menu");
  $this = $clear_menu
    -> command(-label=>$$::labels{'clear_lattice'}, @::menu_args,
	       -command=>\&::clear_lattice);
  &::manage($this, "menu");
  $this = $clear_menu
  -> command(-label=>$$::labels{'clear_all'}, @::menu_args,
	     -command=>sub{&clear_absorption; &::clear_lattice});
  &::manage($this, "menu");

  my $data_menu = $menubar ->
    Menubutton(-text=>$$::labels{'data_menu'}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($data_menu, "menu");

  ##   $this = $data_menu ->
  ##     command(-label=>$$::labels{'dump'}, @::menu_args,
  ## 	    -command=>[\&::display_in_frame, $::top, '', 0],
  ## 	    -accelerator=>'Control+d', );
  ##   &::manage($this, "menu");


  $abs_units = 'cm^-1';
  my $abs_units_menu = $data_menu ->
    cascade(-label=>$$::labels{abs_units},
	    -tearoff=>0,
	    -foreground=>$::colors{'label'}, );
  &::manage($abs_units_menu, "menu");
  foreach my $units ('cm^-1', 'mic.') {
    my $this = $abs_units_menu ->
      radiobutton(-label => $units, @::menu_args,
		  -selectcolor=>$::colors{button},
		  -variable=>\$abs_units,
		  -value=>$units,
		  -command=>[\&swap_absorption, $units],
		 );
    &::manage($this, "menu");
    &::manage($this, "radio");
  };


  my $abs_abs_data = $data_menu ->
    cascade(-label=>$$::labels{data_resources},
	    -tearoff=>0,
	    -foreground=>$::colors{'label'}, );
  &::manage($abs_abs_data, "menu");
  my %abs_menu_abs_button;

  foreach my $resource (sort(Xray::Absorption->available)) {
    my $r = lc($resource);
    next if ($r eq 'none');
    $abs_menu_abs_button{lc($r)} = $abs_abs_data
      -> radiobutton(-label => $resource, @::menu_args,
		     -selectcolor=>$::colors{button},
		     -variable=>\$::meta{absorption_tables},
		     -value=>$r,
		     -command=>sub{ Xray::Absorption->load($r);
				    $::meta{absorption_tables} = $r; });
    &::manage($abs_menu_abs_button{lc($r)}, "menu");
    &::manage($abs_menu_abs_button{lc($r)}, "radio");
  };

  my $help_menu = $menubar ->
    Menubutton(@::help_menubutton)  -> pack(-side=>'right');
  &::set_help_menu($help_menu);

  my $pref_menu = $menubar ->
    Menubutton(@::pref_menubutton)  -> pack(-side=>'right');
  &::set_pref_menu($pref_menu);

  &::manage($help_menu, "menu");
  &::manage($pref_menu, "menu");
  ## ------------------------

  ## Descripton
  my $top_frame = $abs_frame -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-pady=>2, -side=>'top');
  my $abs_label = $top_frame ->
    Label(-text=>$$::labels{'absorption_description'}, @::header_args, ) ->
      pack();
  &::manage($abs_label, "header");


  ## ---- frames ------------
  my $abframe = $abs_frame -> Frame() -> pack(-fill=>'x', -pady=>2);
  my $abf1 = $abframe -> Frame() -> pack(-side=>'left', -pady=>0); # results

  my $abf3 = $abframe -> Frame() -> pack(-side=>'right', -pady=>2); # gasses

  my $abf2 = $abframe -> Frame()	# run button and resources
    -> pack(-side=>'right', -padx=>2, -anchor=>'n');

  my $ablf = $abf3 -> LabFrame(-label=>$$::labels{fill_gases},
			       -foreground=>$::colors{label},
			       -labelside=>'acrosstop',
			       -borderwidth=>2)
    -> pack(-side=>'bottom', -padx=>5);
  $::balloon->attach(($ablf->children)[1], -msg=>$$::help{fill_gases},);
  &::manage($ablf, "labframe");
  ## ------------------------


  ## ---- frame contents -----
  my $col = 0;
  foreach my $which ('nitrogen', 'argon', 'krypton') {
    my $label = $ablf -> Label(-text=>$$::labels{$which}, @::label_args,)
      -> grid(-column=>$col, -row=>0,);
    &::manage($label, "label");
    my $scale = $ablf -> Scale(-from         => 0,
			       -to           => 1,
			       -orient       => 'vertical',
			       -resolution   => 0.01,
			       '-length'     => 100,
			       -sliderlength => 15,
			       -command      => [\&::set_gas, $which],
			       #-variable     => \$keywords->{$which},
			       -foreground   => $::colors{label},
			      )
      -> grid(-column=>$col++, -row=>1, -padx=>2);
    $absorption_widgets{$which} = $scale;
    &::manage($scale, "scale");
    $::balloon->attach($label, -msg=>$$::help{$which},);
  };


  my $absorption_button = $abf2
    -> Button(-text=>$$::labels{'run_absorption'},
	      @::button_args,
	      -command=>\&run_absorption,
	      -borderwidth=>4,
	     ) -> pack(-side=>"top");
  $::balloon->attach($absorption_button, -msg=>$$::help{'run_absorption'},);
  &::manage($absorption_button, "button");


  my $abrf = $abf2 -> LabFrame(-label=>$$::labels{data_resources},
			       -foreground=>$::colors{label},
			       -labelside=>'acrosstop',
			       -borderwidth=>2)
    -> pack(-side=>'bottom', -pady=>2, -padx=>5);
  $::balloon->attach(($abrf->children)[1], -msg=>$$::help{data_resources},);
  &::manage($abrf, "labframe");

  my %absorption_resource_button;
  my $absorption_resource_frame = $abrf
    -> Scrolled("Text", -scrollbars=>'e', -height=>5, -width=>13,
		-relief=>'flat',)
      -> pack(-side=>"top");
  $absorption_resource_frame->Subwidget("yscrollbar")->configure(-background=>$::colors{background});
  foreach my $resource (sort(Xray::Absorption->available)) {
    my $r = lc($resource);
    next if ($r eq 'none');
    $absorption_resource_button{lc($r)} = $absorption_resource_frame
      -> Radiobutton(-text => $resource, @::menu_args,
		     -selectcolor=>$::colors{radio},
		     -variable=>\$::meta{absorption_tables},
		     -value=>$r,
		     -justify=>'left',
		     -command=>sub{ Xray::Absorption->load($r);
				    $::meta{absorption_tables} = $r; });
    &::manage($absorption_resource_button{lc($r)}, "radio");
    $absorption_resource_frame
      -> windowCreate('end', -window=>$absorption_resource_button{lc($r)});
    $absorption_resource_frame -> insert('end', $/);
    $::balloon->attach($absorption_resource_button{lc($r)},
		       -msg=>$$::help{lc($r)});
  }
  $absorption_resource_frame -> configure(-state=>'disabled');

  my $aben = $abf2 -> Frame(-borderwidth=>2)
    -> pack(-side=>'bottom', -pady=>4); #, -padx=>5);
  my $aben_lab = $aben -> Label(-text=>$$::labels{absen}, @::label_args)
    -> pack(-side=>'left', -pady=>2);
  &::manage($aben_lab, "label");
  $::balloon->attach($aben_lab, -msg=>$$::help{absen});
  my $aben_ent = $aben -> Entry(-textvariable=>\$absorption_calculation{absen},
				-font=>$::fonts{label},
				-width=>9, -justify=>'center')
    -> pack(-side=>'right', -pady=>2);
  &::manage($aben_ent, "entry");


  my $absorption_row = 0;
  ## 'edge_energy',
  foreach my $w ('total_abs', 'edge_step', 'density',
		 'mcmaster_corr', 'i0_corr',
		 'self_sigma', 'sum_sigma', 'self_amp') {
    $absorption_calculation{$w} = 0;
    $absorption_label{$w} = $abf1 ->
      Label(-text=>$$::labels{$w}, @::label_args, -height=>0.7)
	-> grid(-column=>0, -row=>$absorption_row,
		-sticky=>'e', -padx=>3, -pady=>0);
    &::manage($absorption_label{$w}, "label");
    $::balloon->attach($absorption_label{$w}, -msg=>$$::help{$w},);

    $absorption_entry{$w} = $abf1 ->
      Entry(-textvariable=>\$absorption_calculation{$w},
	    -foreground=>$::colors{foreground},
	    -background=>$::colors{background},
	    ($Tk::VERSION >= 804) ? (-disabledforeground=>$::colors{foreground},
				     -disabledbackground=>$::colors{background},) :
	     (),
	    -font=>$::fonts{label},
	    -width=>14, -justify=>'left', -relief=>'flat')
	-> grid(-column=>1, -row=>$absorption_row++, -sticky=>'w',
		-padx=>2, -pady=>0);
    #&::manage($absorption_entry{$w}, "entry");  # why is this commented?
    $absorption_entry{$w} -> configure(-state=>'disabled');
  };

};




### > absorption subroutines
## --------------------------------------------------------------------

## change the labels and units on mu and delta mu
sub swap_absorption {
  my $units = $_[0];
  $units = $abs_units;
  if ($units =~ /mic/) {
    $absorption_label{'total_abs'} -> configure(-text=>$$::labels{abs_length});
    $absorption_label{'edge_step'} -> configure(-text=>$$::labels{unit_edge});
  } else {
    $absorption_label{'total_abs'} -> configure(-text=>$$::labels{total_abs});
    $absorption_label{'edge_step'} -> configure(-text=>$$::labels{edge_step});
  };
  foreach my $w ('total_abs', 'edge_step') {
    if ($absorption_calculation{$w} =~ /([\d.]+) +(cm\^-1|mic\.)/ )  {
      $absorption_entry{$w} -> configure(-state=>'normal');
      if ($1 > 0.00001) {
	($absorption_calculation{$w} =
	 (sprintf "%8.2f", 10000/$1) . " " . $units) =~ s/^\s+//;
      } else {
	$absorption_calculation{$w} = $1 . " " . $units;
      };
      $absorption_entry{$w} -> configure(-state=>'disabled');
    };
  };
  $abs_units = $units;
};


## run the absorption calculation and display the results
sub run_absorption {
  $::cell -> make( Occupancy=>1 );
  undef $::keywords;
  $::keywords = Xray::Atoms -> new();
  &::validate_lattice(0);
  my $core_tag = $::site_entries[$::core_index]{'tag'}->get();
  ($core_tag =~ /^\s*$/) and
    $core_tag = $::site_entries[$::core_index]{'elem'}->get();
  $::keywords -> make('core'=>$core_tag);
  &absorption_validate(0);
  $::keywords -> verify_keywords($::cell, \@::sites, 1);
  foreach my $w (keys %absorption_entry) {
    $absorption_entry{$w} -> configure(-state=>'normal');
  };
  foreach my $k (keys %absorption_calculation) {
    next if ($k eq 'absen');
    $absorption_calculation{$k} = 0;
  };
  my ($c, $x, $y, $z) = $::cell->central($::keywords->{'core'});
  my $e = $absorption_calculation{absen} || $::keywords->{'edge'};
  unless ($e =~ /^(?:\d+(?:\.\d*)?|\.\d+)$/) { ## an energy value was entered
    if ( ($e =~ /^[mnop]/i) or ## or the edge of the chosen atom is used
	 (not Xray::Absorption->data_available($c, $e)) ) {
      &::tkatoms_text_dialog(\$::top, $$::dialogs{'no_absorption'}, 'center');
      return 0;
    };
  };
  ##$absorption_calculation{edge_energy} =
  ##  Xray::Absorption->get_energy($c, $e) . " eV";
  ($absorption_calculation{total_abs},
   $absorption_calculation{edge_step},
   $absorption_calculation{density}) =
     map {sprintf "%8.2f", $_}
  Xray::Atoms::absorption($::cell, $c, $e);
  if ($abs_units eq 'mic.') {
    $absorption_calculation{total_abs} =
      sprintf "%8.2f", 10000/$absorption_calculation{total_abs};
    if ($absorption_calculation{edge_step} > 0.00001) {
      $absorption_calculation{edge_step} =
	sprintf "%8.2f", 10000/$absorption_calculation{edge_step};
    };
  };

  unless ($e =~ /^(?:\d+(?:\.\d*)?|\.\d+)$/) {
                             ## if an energy is specified, it does not
                             ## make sense to do the exafs corrections
    $absorption_calculation{mcmaster_corr} =
      sprintf "%8.5f", Xray::Atoms::mcmaster($c, $e);
    $absorption_calculation{sum_sigma} = $absorption_calculation{mcmaster_corr};

    my ($n, $a, $k) =
      ($::keywords->{nitrogen}, $::keywords->{argon}, $::keywords->{krypton});
    if ( ($n > EPSILON) || ($a > EPSILON) || ($k > EPSILON) ) {
      $absorption_calculation{i0_corr} =
	sprintf "%8.5f", Xray::Atoms::i_zero($c, $e, $n, $a, $k);
      ($absorption_calculation{self_amp}, $absorption_calculation{self_sigma}) =
	Xray::Atoms::self($c, $e, $::cell);
      $absorption_calculation{self_amp} =
	sprintf "%8.2f", $absorption_calculation{self_amp};
      $absorption_calculation{self_sigma} =
	sprintf "%8.5f", $absorption_calculation{self_sigma};
      $absorption_calculation{sum_sigma} +=
	$absorption_calculation{i0_corr} +
	  $absorption_calculation{self_sigma};
      $absorption_calculation{i0_corr}	 .= " cm^2";
      $absorption_calculation{self_sigma}	 .= " cm^2";
    };
  };

  ## units
  $absorption_calculation{total_abs}	 .= " " . $abs_units;
  $absorption_calculation{edge_step}	 .= " " . $abs_units;
  $absorption_calculation{mcmaster_corr} .= " cm^2";
  $absorption_calculation{sum_sigma}     .= " cm^2" ;

  foreach my $w (keys %absorption_entry) {
    $absorption_entry{$w} -> configure(-state=>'disabled');
  };
  foreach my $k (keys %absorption_calculation) {
    next if ($k eq 'absen');
    $absorption_calculation{$k} =~ s/^\s+//;
  };
  #unless ($e =~ /^(?:\d+(?:\.\d*)?|\.\d+)$/) {
  #  $absorption_calculation{absen} = Xray::Absorption->get_energy($c, $e);
  #};
};


## save a calculation using the absorption.atp file
sub save_absorption {
  $::cell -> make( Occupancy=>1 );
  undef $::keywords;
  $::keywords = Xray::Atoms -> new();
  my $eol = $/ . "+";	# split title text into lines
  my @t = split /$eol/, $::atoms_widgets{'title'}->get(qw/1.0 end/);
  $::keywords->{'title'} = [];
  foreach my $t (@t) {
    $::keywords->make('title'=>$t);
  };
  &::validate_lattice(0);
  my $core_tag = $::site_entries[$::core_index]{'tag'}->get();
  ($core_tag =~ /^\s*$/) and
    $core_tag = $::site_entries[$::core_index]{'elem'}->get();
  $::keywords -> make('core'=>$core_tag);
  &absorption_validate(0);
  $::keywords -> verify_keywords($::cell, \@::sites, 1);

  my $contents = "";
  $::keywords -> make('identity'=>"TkAtoms $Xray::Atoms::VERSION");
  my ($ofname, $is_feff)
    = parse_atp('absorption', $::cell, $::keywords,
		\@::cluster, \@::neutral, \$contents);

  require Cwd;
  my $path = $::default_filepath || Cwd::cwd();
  my $types = [['All Files', '*', ],];
  my $inputfile = $::top -> getSaveFile(-filetypes=>$types,
					-initialdir=>$path,
					#(not $is_windows) ?
					#(-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
					-initialfile=>$ofname,
					-title => $$::labels{'save_dialog'});
  return 0 unless $inputfile;
  $::default_filepath = dirname($inputfile);

  open (INP, ">".$inputfile) or
    die $$Xray::Atoms::messages{cannot_write} . $inputfile . $/;
  print INP $contents;
  close INP;
};


## make sure all the values make sense
sub absorption_validate {
  my $verbose = $_[0];
  my $is_ok = 1;

  foreach my $word (qw/argon krypton nitrogen/) {
    $::keywords->make($word=>$absorption_widgets{$word}->get);
    if (($::keywords->{$word} < 0) || ($::keywords->{$word} > 1)) {
      $::keywords->make($word=>0);
      my $message = "\"$word\": $$::messages{'one_gas'}$/";
      $::keywords->warn_or_die($message, 1);
    };
  };
  if (($::keywords->{nitrogen} + $::keywords->{argon} + $::keywords->{krypton}) > 1) {
    my $message = $$::messages{'all_gases'} . $/;
    $::keywords->make('nitrogen'=> 0);
    $::keywords->make('argon'=>    0);
    $::keywords->make('krypton'=>  0);
    $::keywords->warn_or_die($message, 1);
    return 0;
  };

  $::keywords->make('edge' => $::atoms_values{'edge'});;
  $::keywords->set_edge($::cell, 1);
  $::atoms_values{'edge'} = $::keywords->{'edge'};

  if ($verbose and $is_ok) {
    &tkatoms_dialog(\$::top, 'atoms_ok', 'info');
  };
};


## clear the absorption notecard
sub clear_absorption {
  ## clear all calculations
  foreach my $k (keys %absorption_calculation) {
    $absorption_calculation{$k} = 0;
  };
  ## reset the gas sliders
  foreach my $w ('nitrogen', 'argon', 'krypton') {
    $absorption_widgets{$w} -> set(0);
  };
  ## reset the edge menu
  ##$abs_edge_symbol = "";
};

1;
__END__
