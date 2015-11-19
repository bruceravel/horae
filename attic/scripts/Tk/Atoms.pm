#!/usr/bin/perl -w
######################################################################
## Atoms notecard module for Atoms 3.0beta9
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

package Xray::Tk::Atoms;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(absorption);
$cvs_info = '$Id: Atoms.pm,v 1.7 2001/09/20 17:53:37 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

use Tk;
use Xray::Atoms qw/number/;
use Xray::ATP;

my ($atoms_frame, $menubar);
use vars qw/$selected_atp/;

######################################################################
#########                                      #######################
#########  Notecard containing Atoms keywords  #######################
#########                                      #######################
######################################################################
sub atoms {

  $atoms_frame = $_[0] -> Frame() -> pack(-fill=>'x');

  ## ---- menubar -----------
  $menubar = $atoms_frame -> Frame(-borderwidth=>2, -relief=>'ridge',)
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
  my $recent = $file_menu
    -> cascade(-label=>"Recent files", @::menu_args, -tearoff=>0);
  &::manage($recent, "menu");
  push @::recent_registry, $recent;
  my $sep = $file_menu -> separator();
  &::manage($sep, "separator");
  $this = $file_menu
    -> command(-label=>$$::labels{save_input}, @::menu_args,
	       -command=>\&::save_input,
	       -accelerator=>'Control+s', );
  &::manage($this, "menu");
  $sep = $file_menu -> separator();
  &::manage($sep, "separator");
  $this = $file_menu
    -> command(-label=>$$::labels{write_template_6}, @::menu_args,
	       -command=>[\&write_template, "6"],);
  &::manage($this, "menu");
  $this = $file_menu
    -> command(-label=>$$::labels{write_template_8}, @::menu_args,
	       -command=>[\&write_template, "8"],);
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

  $this = $clear_menu ->
    command(-label=>$$::labels{'clear_atoms'}, @::menu_args,
	    -command=>\&clear_atoms);
  &::manage($this, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{'clear_lattice'}, @::menu_args,
			 -command=>\&::clear_lattice);
  &::manage($this, "menu");
  $this = $clear_menu ->
    command(-label=>$$::labels{'clear_all'}, @::menu_args,
	    -command=>sub{&clear_atoms; &::clear_lattice});
  &::manage($this, "menu");



  my $data_menu = $menubar ->
    Menubutton(-text=>$$::labels{'data_menu'}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($data_menu, "menu");
  $this = $data_menu -> command(-label=>$$::labels{'insert_shift'},
				@::menu_args,
				-command=>\&insert_shift);
  &::manage($this, "menu");
  ##   $this = $data_menu -> command(-label=>$$::labels{'dump'},
  ## 				@::menu_args,
  ## 				-command=>[\&::display_in_frame, $::top, '', 0],
  ## 				-accelerator=>'Control+d', );
  ##   &::manage($this, "menu");
  my $abs_data =
    $data_menu -> cascade(-label=>'Absorption data resource',
			  -tearoff=>0,
			  -foreground=>$::colors{'label'}, );
  &::manage($abs_data, "menu");

  my %menu_abs_button;
  foreach my $resource (sort(Xray::Absorption->available)) {
    my $r = lc($resource);
    next if ($r eq 'none');
    $menu_abs_button{lc($r)} = $abs_data
      -> radiobutton(-label => $resource, @::menu_args,
		     -selectcolor=>$::colors{button},
		     -variable=>\$::meta{absorption_tables},
		     -value=>$r,
		     -command=>sub{ Xray::Absorption->load($r);
				    $::meta{absorption_tables} = $r; });
    &::manage($menu_abs_button{lc($r)}, "menu");
    &::manage($menu_abs_button{lc($r)}, "radio");
  }


  my $help_menu = $menubar ->
    Menubutton(@::help_menubutton)  -> pack(-side=>'right');
  &::set_help_menu($help_menu);

  my $pref_menu = $menubar ->
    Menubutton(@::pref_menubutton)  -> pack(-side=>'right');
  &::set_pref_menu($pref_menu);

  &::manage($help_menu, "menu");
  &::manage($pref_menu, "menu");

  ## Descripton
  my $top_frame = $atoms_frame -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-pady=>4, -side=>'top');
  my $atoms_label = $top_frame ->
    Label(-text=>$$::labels{'atoms_description'}, @::header_args, ) ->
      pack();
  &::manage($atoms_label, "header");

  ## --------------------------------------------------------------------
  ## frame for edge, rmax, shift, fill gases
  my $af1 = $atoms_frame -> Frame() -> pack(-fill=>'x', -pady=>2);
  my ($label, $entry);

  my $af1_left  = $af1 -> Frame() -> pack(-side=>'left', -expand=>1);
  my $af1_right = $af1 -> LabFrame(-label=>$$::labels{fill_gases},
				   -foreground=>$::colors{label},
				   -labelside=>'acrosstop',
				   -borderwidth=>2)
    -> pack(-side=>'right', -expand=>1);
  $::balloon->attach(($af1_right->children)[1], -msg=>$$::help{fill_gases},);
  &::manage($af1_right, "labframe");

  ##    --------------------------- rmax
  my $col = 0;
  $label = $af1_left -> Label(-text=>$$::labels{'rmax'}, @::label_args, )
    -> grid(-column=>$col++, -row=>0, -sticky=>'e');
  &::manage($label, "label");
  $entry = $af1_left -> Entry(-width=>7, @::entry_args)
    -> grid(-column=>$col++, -row=>0, -pady=>5);
  &::manage($entry, "entry");
  push @::all_entries, $entry;
  $::atoms_widgets{'rmax'} = $entry;
  $::balloon->attach($label, -msg=>$$::help{'rmax'},);

  $col+=2;
  my $button = $af1_left -> Button(-text=>$$::labels{'run_atoms'},
				   @::button_args,
				   -command=>$::function_refs{'run_atoms'},
				   -borderwidth=>4, );
  $button  -> grid(-column=>$col++, -row=>0, -columnspan=>3,
		   -sticky=>'e', -pady=>5);
  $::balloon->attach($button, -msg=>$$::help{'run_atoms'},);
  &::manage($button, "button");


  ##    --------------------------- shift vector
  $col=0;
  $::atoms_widgets{'shift'} = [];
  do {
    my $label = $af1_left -> Label(-text=>$$::labels{'shift'}, @::label_args,)
      ->  grid(-column=>$col++, -row=>1, -sticky=>'e', -pady=>5);
    &::manage($label, "label");
    foreach my $i (0..2) {
      my $entry = $af1_left -> Entry(-width=>7, @::entry_args)
	->  grid(-column=>$col++, -row=>1, -sticky=>'w', -pady=>5);
      unless ($i == 2) {
	my $comma = $af1_left -> Label(-text=>',', @::label_args,)
	  ->  grid(-column=>$col++, -row=>1, -pady=>5);
	&::manage($comma, "label");
      };
      push @{$::atoms_widgets{'shift'}}, $entry;
      &::manage($entry, "entry");
    };
    $::balloon->attach($label, -msg=>$$::help{'shift'},);
  };

  ## optionmenu for selecting an output file type
  my $out_label = $af1_left -> Label(-text=>$$::labels{outfiles},
				@::label_args)
    -> grid(-column=>0, -row=>2, -columnspan=>2, -sticky=>'e', -pady=>5);
  &::manage($out_label, "label");
  $::balloon->attach($out_label, -msg=>$$::help{'outfiles'},);

  $selected_atp = "feff";
  ($::prefer_feff_eight) and $selected_atp = "feff8";
  my $atp_button = $af1_left
    -> Optionmenu(-textvariable     => \$selected_atp,
		  -background       => $::colors{'entry'},
		  -activeforeground => $::colors{'label'},
		  -activebackground => $::colors{'entry'},
		  -width=>15, -font=>$::fonts{'label'}, -relief=>'groove')
      -> grid(-column=>2, -row=>2, -columnspan=>4, -sticky=>'e', -pady=>5);
  &::manage($atp_button, "menu");
  foreach my $e (@::atpfiles) {
    next if ($e =~ /^\s*$/);	  # remove atp files for
    next if ($e =~ /^molec/i);	  #    molecules,
    next if ($e =~ /^template/i); #    templates,
    next if ($e =~ /^dafs/i);	  #    dafs sims,
    next if ($e =~ /^powder/i);   #    powder sims,
    next if ($e =~ /a(bsorption|toms)/); # atoms.inp, and absorption reports
    my $this = $atp_button -> command(-label => $e, @::menu_args,
				      -command=>sub{$selected_atp=$e;});
    &::manage($this, "menu");
  };




  ## --------------------------------------------------------------------
  ## sliders for fill gases
  $col = 1;
  ##$::balloon->attach($label, -msg=>$$::help{fill_gases},);
  foreach my $which ('nitrogen', 'argon', 'krypton') {
    my $label = $af1_right -> Label(-text=>$$::labels{$which}, @::label_args,)
      -> grid(-column=>$col, -row=>0,);
    &::manage($label, "label");
    my $scale = $af1_right -> Scale(-from         => 0,
				    -to           => 1,
				    -orient       => 'vertical',
				    -resolution   => 0.05,
				    '-length'     => 100,
				    -sliderlength => 15,
				    -command      => [\&::set_gas, $which],
				    #-variable     => \$keywords->{$which},
				    -foreground   => $::colors{label},
				   )
      -> grid(-column=>$col++, -row=>1, -padx=>2);
    $::atoms_widgets{$which} = $scale;
    $::balloon->attach($label, -msg=>$$::help{$which},);
    &::manage($scale, "scale");
  };
  ## --------------------------------------------------------------------


};



### > atoms subroutines
## --------------------------------------------------------------------


sub run_atoms {
  $::cell -> make( Occupancy=>0 );
  ($selected_atp =~ /(p1|unit)/) and $::cell -> make( Occupancy=>1 );
  &::validate_lattice(0);
  my $core_tag = $::site_entries[$::core_index]{'tag'}->get();
  ($core_tag =~ /^\s*$/) and
    $core_tag = $::site_entries[$::core_index]{'elem'}->get();
  $::keywords -> make('core'=>$core_tag);
  &atoms_validate(0);
  $::keywords -> verify_keywords($::cell, \@::sites, 1);
  Xray::Atoms::build_cluster($::cell, $::keywords, \@::cluster, \@::neutral);
  my $contents = "";
  $::keywords -> make('identity'=>"TkAtoms $Xray::Atoms::VERSION");
  my ($ofname, $is_feff)
    = parse_atp($selected_atp, $::cell, $::keywords,
		\@::cluster, \@::neutral, \$contents);
  &::display_in_frame($::top, \$contents, $selected_atp, $ofname, $is_feff);
};






## titles:      do not need error checking -- they can say anything
## check:       that edge is a valid edge symbol or whitespace
## core:        cannot be checked here
## fill gases:  check that they add to less than 1
## rmax:        cannot be checked here
## shift:       it either evaluates to a number or it doesn't
## edge:        it's a menu, it cannot be wrong
sub atoms_validate {
  my $verbose = $_[0];
  my $is_ok = 1;

  $::keywords->make('edge' => $::atoms_values{'edge'});;
  $::keywords->set_edge($::cell, 1);
  $::atoms_values{'edge'} = $::keywords->{'edge'};

 KEYWORDS: foreach my $key (keys %::atoms_widgets) {
    #print $key, $/;
    next KEYWORDS if ($key =~ /argon|krypton|nitrogen/);
    ($key eq 'shift') && do {	# vector valued
      my ($x, $y, $z) = (&number($::atoms_widgets{'shift'}[0]->get()),
			 &number($::atoms_widgets{'shift'}[1]->get()),
			 &number($::atoms_widgets{'shift'}[2]->get()));
      $::keywords->make('shift'=>$x, $y, $z);
      next KEYWORDS;
    };				# number valued
    ($key =~ /rmax/) && do {
      $::keywords->
	make($key => number($::atoms_widgets{$key}->get()) );
      next KEYWORDS;
    };
    #($key eq 'dopant_core') && do {
    #  $::keywords->
    #	make('dopant_core' => $::atoms_widgets{'dopant_core'}->get() );
    #  next KEYWORDS;
    #};
    ($key eq 'title') && do {
      my $eol = $/ . "+";	# split title text into lines
      my @t = split /$eol/, $::atoms_widgets{'title'}->get(qw/1.0 end/);
      $::keywords->{'title'} = [];
      foreach my $t (@t) {
	$::keywords->make('title'=>$t);
      };
      next KEYWORDS;
    };
    do {			# string valued
      unless (($key eq 'edge') || ($key =~ /_button$/))  {
	$::keywords->make($key => $::atoms_widgets{$key}->get() );
      };
      ## my $atp_regex = join('|', @::atpfiles);
      ## if ($key =~ /^($atp_regex)$/) {
	## my $l = $key . ": " . $::keywords->{$key};
	## my $f = 0;
	## ($key eq 'feff')  && ($f = 6);
	## ($key eq 'feff8') && ($f = 8);
	##$atp_menu_widgets{$key} -> configure(-label=>$l);
	##$atp_menu_widgets{$key}
	##  -> configure(-command=>
	##	       [\&display_in_frame, $top, $::keywords->{$key}, $f]);
      ## };
      next KEYWORDS;
    };
  };				# verify that the keyword values make sense
  $::keywords->verify_keywords($::cell,\@::sites,1);
  $::atoms_widgets{'rmax'} -> delete(qw/0 end/);
  $::atoms_widgets{'rmax'} -> insert(0, $::keywords->{'rmax'});
  if ($verbose and $is_ok) {
    &tkatoms_dialog(\$::top, 'atoms_ok', 'info');
  };
};






sub clear_atoms {
  ##$::atoms_widgets{'edge'} -> configure(-textvariable=>\$::keywords->{'edge'});
  foreach my $key (keys %::atoms_widgets) {
    next if ($key eq 'edge');	  # handle edge specially
    next if ($key =~ /_button$/); # handle atp button below
    if ($key eq 'title') {
      1;			# do this in clear_littice
      ##$::atoms_widgets{$key} -> delete(qw/1.0 end/);
    } elsif ($key eq 'shift') {
      foreach my $i (0..2) {
	$::atoms_widgets{$key}[$i] -> delete(qw/0 end/);
      };
    } elsif ($key =~ /argon|krypton|nitrogen/) {
      $::atoms_widgets{$key} -> set(0.00);
    } else {
      $::atoms_widgets{$key} -> delete(qw/0 end/);
    };
  };
  $selected_atp = ($::prefer_feff_eight) ? "feff8" : "feff";
  ##($::prefer_feff_eight) and $selected_atp = "feff8";
};


sub insert_shift {
  my $group = $::space_field -> get;
  if ($group   =~ /^\s*$/) {
    $::top -> messageBox(-icon    => 'error',
			 -message => $$::dialogs{'no_space_group'},
			 -title   => 'Atoms: Error',
			 -type    => 'OK');
    return;
  };
  my @vec = Xray::Xtal::Cell::get_shift($group);
  if ($group =~ /^\s*$/) {
    $::top -> messageBox(-icon    => 'error',
			 -message => $$::dialogs{'no_space_group'},
			 -title   => 'Atoms: Error',
			 -type    => 'OK');
    return -1;
  } elsif (@vec) {
    $::keywords -> make('shift'=>@vec);
    $ {$::atoms_widgets{'shift'}}[0] -> insert(0, $vec[0]);
    $ {$::atoms_widgets{'shift'}}[1] -> insert(0, $vec[1]);
    $ {$::atoms_widgets{'shift'}}[2] -> insert(0, $vec[2]);
  } else {
    &::tkatoms_text_dialog(\$::top, "`" . $group . "'" . $$::dialogs{'no_shift'});
  };
};


sub write_template {
  my $atp = "template" . $_[0];
  my $cell = Xray::Xtal::Cell -> new();
  my $keywords = Xray::Atoms -> new();
  $keywords -> make('identity'=>"the Feff template generator");
  my (@cluster, @neutral, $contents);
  my ($default_name, $is_feff) =
    &parse_atp($atp, $cell, $keywords, \@cluster, \@neutral, \$contents);
  &::display_in_frame($::top, \$contents, $selected_atp, $default_name, $is_feff);
};




1;
__END__
