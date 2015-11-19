#!/usr/bin/perl -w
######################################################################
## Molecule notecard module for Atoms 3.0beta9
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

package Xray::Tk::Molecule;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(molecule);
$cvs_info = '$Id: Molecule.pm,v 1.7 2001/09/20 17:55:04 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

use Tk;
use Tk::widgets qw/ColorEditor/;
use Xray::Atoms qw/number/;
use Xray::ATP;
## File ##
use Xray::File;
use File::Basename qw(dirname);

## ------- set up some variables ---------------------------------
my ($e, $x, $y, $z) = (0,1,2,3);
## File ##
my $molecule = Xray::File -> new();
my $core_index = 0;
my @site_entry;
my @skip_list;
my $selected_atp;
my %mol_values = ('edge' => '', 'rmax' => 0, 'atp' => 'molecule6');
my ($ecenter, $xcenter, $ycenter, $zcenter);
my ($skip_window, $format_window);
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));

my ($sites_table, $mol_frame, %pages, $menubar, $rmax_box);

sub molecule {
  #$mol_frame = $_[0] -> Frame() -> pack(-fill=>'x');
  $mol_frame = $::pages{Molecule} -> Frame() -> pack(-fill=>'x');

  ## ------- Menubar -----------------------------------------------
  $menubar = $mol_frame -> Frame(-borderwidth=>2, -relief=>'ridge',)
    -> pack(-anchor=>'nw', -fill=>'x', -pady=>4, -padx=>4);
  my $file_menu = $menubar ->
    Menubutton(-text=>$$::labels{'file'}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($file_menu, "menu");

  my $this;
  $this = $file_menu ->
    command(-label=>$$::labels{'load_data'}, @::menu_args,
	    -command=>[\&read_data, $::top], -accelerator=>'Control+l',);
  &::manage($this, "menu");
  ##   my $sep = $file_menu -> separator();
  ##   &::manage($sep, "separator");
  ##   $this = $file_menu -> command(@::apt_args);
  ##   &::manage($this, "menu");
  $sep = $file_menu -> separator();
  &::manage($sep, "separator");
  $this = $file_menu ->
    command(-label=>$$::labels{'quit'}, @::menu_args,
	    -command=>sub{exit}, -accelerator=>'Control+q',);
  &::manage($this, "menu");

  my $clear_menu = $menubar ->
    Menubutton(-text=>$$::labels{'clear_menu'}, @::menu_args) ->
      pack(-side=>'left');
  &::manage($clear_menu, "menu");
  $this = $clear_menu
  -> command(-label=>$$::labels{'clear_molecule'}, @::menu_args,
	     -command=>\&clear_molecule);
  &::manage($this, "menu");
  $this = $clear_menu
  -> command(-label=>$$::labels{'clear_lattice'}, @::menu_args,
	     -command=>\&::clear_lattice);
  &::manage($this, "menu");
  $this = $clear_menu
  -> command(-label=>$$::labels{'clear_all'}, @::menu_args,
	     -command=>sub{&clear_molecule; &::clear_lattice});
  &::manage($this, "menu");

  my $skip_menu = $menubar ->
    Menubutton(-text=>$$::labels{'skip'}, @::menu_args) -> pack(-side=>'left');
  &::manage($skip_menu, "menu");
  $this = $skip_menu ->
    command(-label=>$$::labels{'skip_rules'}, @::menu_args,
	    -command=>[\&skip_by, $mol_frame], );
  &::manage($this, "menu");
  $this = $skip_menu ->
    command(-label=>$$::labels{'unselect_skip'}, @::menu_args,
	    -command=>sub{map {$$_{'skip'}->deselect;} @site_entry});
  &::manage($this, "menu");


  my $help_menu = $menubar ->
    Menubutton(@::help_menubutton)  -> pack(-side=>'right');
  &::set_help_menu($help_menu);

  my $pref_menu = $menubar ->
    Menubutton(@::pref_menubutton)  -> pack(-side=>'right');
  &::set_pref_menu($pref_menu);

  &::manage($help_menu, "menu");
  &::manage($pref_menu, "menu");

  my $top_frame = $mol_frame -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-pady=>4, -side=>'top');
  my $mol_label = $top_frame ->
    Label(-text=>$$::labels{'molecule_description'}, @::header_args, ) ->
      pack();
  &::manage($mol_label, "header");

  ## ------- Widgets Frame -----------------------------------------
  my $params_frame = $mol_frame -> Frame(-relief=>'flat', -border=>2)
    -> pack(-side=>'left', -fill=>'both', -pady=>4, -padx=>4);

  my $run_button = $params_frame ->
    Button(-text=>$$::labels{'run_molecule'}, @::button_args, -borderwidth=>4,
	   -command=>\&run_molecule, )
      -> pack(-side=>'top');
  $::balloon->attach($run_button, -msg=>$$::help{'run_mol'},);
  &::manage($run_button, "button");

  my $rmax_frame = $params_frame -> Frame()
    -> pack(-fill=>'both', -expand=>1);
  my $rmax_label = $rmax_frame ->
    Label(-text=>$$::labels{rmax}, @::label_args, -anchor=>'w') ->
      pack(-side=>'left');
  &::manage($rmax_label, "label");
  $::balloon->attach($rmax_label, -msg=>$$::help{'rmax'},);
  $rmax_box = $rmax_frame ->
    Entry(-width=>9, @::entry_args,
	  -textvariable=>\$mol_values{'rmax'}) ->
      pack(-side=>'left');
  &::manage($rmax_box, "entry");

  my $atp_frame = $params_frame -> Frame()
    -> pack(-side=>'bottom', -fill=>'both');
  my $atp_label = $atp_frame ->
    Label(-text=>$$::labels{outfiles}, @::label_args)
      -> pack(-side=>'top');
  $::balloon->attach($atp_label, -msg=>$$::help{'atp_mol'},);
  &::manage($atp_label, "label");
  my $atp_button = $atp_frame
    -> Optionmenu(-textvariable     => \$mol_values{'atp'},
		  -background       => $::colors{'entry'},
		  -activeforeground => $::colors{'label'},
		  -activebackground => $::colors{'entry'},
		  -width=>15, -font=>$::fonts{'label'}, -relief=>'groove')
      -> pack(-side=>'left');
  &::manage($atp_button, "menu");
  foreach my $e (@::atpfiles) {
    if ($e =~ /^molec/i) {
      my $this = $atp_button -> command(-label => $e, @::menu_args,
					-command=>sub{$mol_values{'atp'}=$e;});
      &::manage($this, "menu");
    };
  };


  ## ------- Sites Table -------------------------------------------
  my $sites_frame = $mol_frame -> Frame(-border=>2, -relief=>'groove')
    -> pack(-side=>'left');
  $sites_table = $sites_frame
    -> Table(-fixedrows => 1,
	     -rows => 7,
	     -columns => 1,
	     -scrollbars => 'e',
	     -borderwidth=>0,)
      -> pack(-side=>'left');
  $sites_table -> put(0, 0, &site_labels(\$sites_table));
  foreach my $i (0 .. 14) {
    $sites_table -> put($i+1, 0, &site_line(\$sites_table, $i));
  };
};

## ----- functions for sites table -----------------------------------

## make a frame and populate it with site information. Return that frame.
sub site_line {
  my ($parent, $which) = @_;
  my $frame = $$parent -> Frame();
  my $site_label   = $frame -> Label(-text  => $which+1, @::header_args,
				     -font  => $::fonts{entry},
				     -width => 4,
				     -justify=>'right', -anchor=>'e' )
    -> pack(-side=>'left');
  &::manage($site_label, "header");
  $site_entry[$which]{'core'} = $frame ->
    Radiobutton(-value       => $which,
		-selectcolor => $::colors{radio},
		-variable    => \$core_index,
		-command     => sub{$core_index = $which;}, )
      -> pack(-side=>'left');
  &::manage($site_entry[$which]{'core'}, "radio");
  my %width = ('elem'=>5, 'x'=>9, 'y'=>9, 'z'=>9, 'tag'=>10);
  foreach my $coord ('elem', 'x', 'y', 'z', 'tag') {
    $site_entry[$which]{$coord}  = $frame
      -> Entry(-width=>$width{$coord},  @::entry_args,)
	-> pack(-side=>'left');
    &::manage($site_entry[$which]{$coord}, "entry");
    ($coord =~ /^[xyz]$/) and $site_entry[$which]{$coord} -> insert(0,0);
    $site_entry[$which]{$coord} ->
      bind("<$::meta{unused_modifier}-Key-Right>",
	   [\&::site_navigate, \$sites_table, \@site_entry,
	    $which, $coord, 0, 0]);
    $site_entry[$which]{$coord} ->
      bind("<$::meta{unused_modifier}-Key-Left>",
	   [\&::site_navigate, \$sites_table, \@site_entry,
	    $which, $coord, 1, 0]);
    $site_entry[$which]{$coord} ->
      bind("<$::meta{unused_modifier}-Key-Up>",
	   [\&::site_navigate, \$sites_table, \@site_entry,
	    $which, $coord, 0, 1]);
    $site_entry[$which]{$coord} ->
      bind("<$::meta{unused_modifier}-Key-Down>",
	   [\&::site_navigate, \$sites_table, \@site_entry,
	    $which, $coord, 1, 1]);
  };
  $site_entry[$which]{'skip'} = $frame ->
    Checkbutton(-selectcolor => $::colors{radio},
		-variable    => \$skip_list[$which], )
      -> pack(-side=>'left');
  &::manage($site_entry[$which]{'skip'}, "check");
  $skip_list[$which] = 0;
  return $frame;
};

## This subroutine writes out the column labels at the top of the
## sites list.
sub site_labels {
  my $parent = $_[0];
  my $frame = $$parent -> Frame() -> pack();
  my $site_label   = $frame -> Label(-width=>4,)
    -> pack(-side=>'left');
  &::manage($site_label, "label");
  my %width = ('core'=> 4, 'elem'=>5, 'x'=>9, 'y'=>9,
	       'z'=>9, 'tag'=>10, 'skip'=>5);
  foreach my $coord ('core', 'elem', 'x', 'y', 'z', 'tag', 'skip') {
    my $field = $frame
      -> Label(-text=>$$::labels{$coord}, -width=>$width{$coord},
	       -foreground=>$::colors{label},
	       -font=>$::fonts{entry}, )
	-> pack(-side=>'left');
    &::manage($field, "label");
    $::balloon->attach($field, -msg=>$$::help{'mol_'.$coord},);
  };
  return $frame;
};

## ----- functions for reading input data ----------------------------

## read an external data file.  This will have to be replaced with an
## object oriented scheme..
sub read_data {
  require Cwd;
  local $Tk::FBox::a;
  local $Tk::FBox::b;
  my $path = $::default_filepath || Cwd::cwd();
  my $types = [['All Files', '*', ],];
  $inputfile = $top -> getOpenFile(-filetypes=>$types,
				   #(not $is_windows) ?
				   #   (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				   -title => $$::labels{'file_dialog'});
  return 0 unless $inputfile;
  $::default_filepath = dirname($inputfile);
  &clear_molecule;

  my $filetype;
 TYPE: {
    $filetype='alchemy', last TYPE if ($inputfile =~ /\.alc$/);
    $filetype='xyz',     last TYPE if ($inputfile =~ /\.xyz$/);
    $filetype='PDB',     last TYPE if ($inputfile =~ /\.pdb$/);
    $filetype='generic';
  };
  if (not Exists $format_window) {
    $format_window =  $mol_frame -> Toplevel(-class=>'horae');
    $format_window -> title($$::labels{'mol_format'});
    $format_window -> resizable(0,0);
    my $label = $format_window ->
      Label(-text=>$$::labels{'mol_format_explain'},
	    @::header_args) -> pack(-side=>'top');
    &::manage($label, "header");
    foreach my $ftype ('generic', 'xyz', 'alchemy', 'PDB') {
      my $frame = $format_window ->
	Frame(-borderwidth=>2, -relief=>'ridge') ->
	  pack(-expand=>1, -fill=>'x', -side=>'top');
      my $choice = $frame ->
	Radiobutton(-text        => $ftype,
		    -value       => $ftype,
		    -selectcolor => $::colors{radio},
		    -variable    => \$filetype,
		    -command     => sub{$filetype = $ftype;},
		   )
	  -> pack(-side=>'left');
      &::manage($choice, "radio");
    };
    my $frame = $format_window ->
      Frame(-borderwidth=>2, -relief=>'ridge') ->
	pack(-expand=>1, -fill=>'x', -side=>'top');
    my $button = $frame -> Button(-text=>$$::labels{'ok'}, @::button_args,
				  -command=>sub{
				    $molecule -> read($inputfile, $filetype);
				    &fill_sites($molecule->{'coordinates'});
  				    $format_window->withdraw})
      -> pack(-side=>'left');
    &::manage($button, "button");
    $button = $frame -> Button(-text=>$$::labels{'dismiss'}, @::button_args,
			       -command=>sub{$format_window->withdraw})
      -> pack(-side=>'right');
    &::manage($button, "button");
  } else {
    $format_window->deiconify;
    $format_window->raise;
  };

##   open DAT, $inputfile or die $!;
##   my @cluster;
##   while (<DAT>) {
##     next if (/^\s*$/);		# skip blank lines
##     next if (/^\s*\#/);		# skip comment lines
##     chomp;
##     my @line = split;
##     my ($tag, $xx, $yy, $zz) = ($line[$e], $line[$x], $line[$y], $line[$z]);
##     ##($xx, $yy, $zz) = map {$scale*$_} ($xx, $yy, $zz);
##     (my $ee = $tag) =~ s/(.+)\([^\)]+\)/$1/;
##     ## load data into a temporary structure
##     push @cluster, [$xx, $yy, $zz, $ee, $tag];
##   };
##   close DAT;
##   &clear_molecule;
##   &fill_sites(\@cluster);
};

#sub add_site(\$sites_table, $na);

## fill up the sites table with the values read from the data file
sub fill_sites {
  my $r_clus = $_[0];
  my $space;
  my $nw = $#site_entry;
  my $na = 0;
  foreach my $s (@$r_clus) {
    if ($na > $nw) {
      $sites_table -> put($na+1, 0, &site_line(\$sites_table, $na));
    };
    $site_entry[$na]{'elem'} -> insert(0, $$s[3]);
    $space = " " x (9-length($$s[0])); # right justify
    $site_entry[$na]{'x'}    -> insert(0, $space.$$s[0]);
    $space = " " x (9-length($$s[1]));
    $site_entry[$na]{'y'}    -> insert(0, $space.$$s[1]);
    $space = " " x (9-length($$s[2]));
    $site_entry[$na]{'z'}    -> insert(0, $space.$$s[2]);
    ## make sure tags are unique
    my $tag = (lc($$s[3]) eq lc($$s[4])) ? $$s[3] . "_" . ($na+1) : $$s[4];
    $site_entry[$na]{'tag'}  -> insert(0, $tag);
    ++$na;
  };
  $site_entry[0]{'core'} -> select(); # select first atom
};


sub run_molecule {
  ## fetch the coordinates of the central atom
  my ($ecenter, $xcenter, $ycenter, $zcenter, $elcenter) =
    ($site_entry[$core_index]{'tag'}  -> get(),
     $site_entry[$core_index]{'x'}    -> get(),
     $site_entry[$core_index]{'y'}    -> get(),
     $site_entry[$core_index]{'z'}    -> get(),
     $site_entry[$core_index]{'elem'} -> get());
  ($ecenter) or ($ecenter = $elcenter."_".$core_index);
  ## build a sites array
  my $nsites = -1;
  my $i = -1;
  my @cluster;
  my @sites;
  undef $::keywords;
  $::keywords = Xray::Atoms -> new();
  ## fetch rmax indicated on the molecule notecard
  $mol_values{'rmax'} = $rmax_box->get();
  $mol_values{'rmax'} = number($mol_values{'rmax'});
  $mol_values{'rmax'} = sprintf "%8.5f", $mol_values{'rmax'};
  my $rsq = ($mol_values{'rmax'} > 0.01) ? $mol_values{'rmax'}**2 : 100000;

  $Xray::Xtal::Site::molecule = 1;
  foreach my $s (@site_entry) {
    my $el = $$s{'elem'} -> get();
    ++$i;
    next if ($el =~ /^\s*$/);
    next if $skip_list[$i];
    ++$nsites;
    $sites[$nsites] = Xray::Xtal::Site -> new();
    my ($x, $y, $z, $e, $t) = ($$s{'x'}	   -> get(),
			       $$s{'y'}	   -> get(),
			       $$s{'z'}	   -> get(),
			       $$s{'elem'} -> get(),
			       $$s{'tag'}  -> get());
    ($t) or ($t = $e."_".$i);
    ($x, $y, $z) = ($x-$xcenter, $y-$ycenter, $z-$zcenter);
    $sites[$nsites] -> make(Element=>$e, Tag=>$t, X=>$x, Y=>$y, Z=>$z,
			    Occupancy=>1);
    my $r_squared = $x**2 + $y**2 + $z**2;
    $r_squared = sprintf "%9.5f", $r_squared;
    ($r_squared <= $rsq) and
      push(@cluster, [$x, $y, $z, \$sites[$nsites], $r_squared,
		      sprintf("%9.5f", $x),
		      sprintf("%9.5f", $y),
		      sprintf("%9.5f", $z)]);
    #print join(" | ", @{$cluster[$nsites]}[4..7], $/);
  };
  unless ($nsites > 0) {
    return &::tkatoms_dialog(\$::top, 'no_molecule_data', 'warning');
  };

  @cluster = sort {
    ($a->[4] cmp $b->[4])	# sort by distance squared or ...
      or
    ($a->[7] cmp $b->[7])	# by z value or ...
      or
    ($a->[6] cmp $b->[6])	# by y value or ...
      or
    ($a->[5] cmp $b->[5]);	# by x value
  } @cluster;

  ($mol_values{'rmax'} < 0.01) and
    $mol_values{'rmax'} = 1.1 * sqrt($cluster[$#cluster] -> [4]);
  $::keywords -> make('rmax' => $mol_values{'rmax'});

  ## fetch the title lines and edge from the crystallography panel
  my $eol = $/ . "+";	# split title text into lines
  my @t = split /$eol/, $::atoms_widgets{'title'}->get(qw/1.0 end/);
  $::keywords->{'title'} = [];
  foreach my $t (@t) {
    $::keywords->make('title'=>$t);
  };
  my $ed = $::atoms_values{'edge'};

  ## make a trivial cell to keep parse_atp happy and set some other keywords
  my $cell = Xray::Xtal::Cell -> new();
  $cell -> make('Space_group' => 'p 1');
  map { $cell->make( $_=>1  ) } ('a', 'b', 'c');
  map { $cell->make( $_=>90 ) } ('alpha', 'beta', 'gamma');
  $::keywords -> make('identity'=>"the Molecule notecard $VERSION");
  $::keywords -> make('quiet'=> 0);
  $::keywords -> make('core' => $ecenter);
  my $z = Chemistry::Elements::get_Z($elcenter);
  if ($ed) {
    $::keywords -> make('edge' => $ed);
  } else {
    $::keywords -> make('edge' => 'K');
    ($z > 57) and $::keywords -> make('edge' => 'L3');
  };
  $cell -> populate(\@sites);
  $Xray::Xtal::Site::molecule = 0;

  ## generate and display the output file
  my ($contents, @neutral);
  my ($default_name, $is_feff) =
    parse_atp($mol_values{'atp'}, $cell, $::keywords, \@cluster,
	      \@::neutral, \$contents);

  &::display_in_frame($::top, \$contents, $mol_values{'atp'},
		      $default_name, $is_feff);
};


## this does not currently reduce the number of rows back down to
## 15. getting rid of the rows works, but then I don't know how to
## shrink the table back down to 15.
sub clear_molecule {
  $core_index = 0;
  foreach my $s (@site_entry) {
    map {$$s{$_} -> delete(qw/0 end/)} (qw/elem x y z tag/);
    $$s{'skip'} -> deselect;
  };
  ##   my ($switch, $i, $which) = (0, 0, 0);
  ##   foreach my $w ($sites_table->children()) {
  ##     if ("$w" =~ /scrollbar/i) {
  ##       $switch = 1;
  ##       $which = $i;
  ##       next;
  ##     };
  ##     next unless $switch;
  ##     $w->UnmanageGeometry;
  ##     $sites_table -> Tk::Table::LostSlave($w);
  ##     ++$i;
  ##   };
  ##   $#site_entry = $which;
};


## ----- subroutines for entering and applying skip rule ------------
sub skip_by {
  my $parent = $_[0];
  if (not Exists $skip_window) {
    $skip_window = $parent -> Toplevel(-class=>'horae');
    $skip_window ->title($$::labels{'mol_skip_rules'});
    $skip_window->resizable(0,0);
    ##-- explanation
    my $label_frame = $skip_window -> Frame() -> pack();
    my $this;
    $this = $label_frame -> Label(-text=>$$::labels{'explain_skip'},
				  @::header_args)
      -> pack();
    &::manage($this, "header");
    ##-- skip rules
    my $widgets_frame = $skip_window -> Frame(-borderwidth=>2, -relief=>'ridge')
      -> pack(-padx=>4, -pady=>4);
    my (%check, %entry, %relation);
    my %rel = ('x'=>'>', 'y'=>'>', 'z'=>'>') ;
    my $r = 0;
    foreach my $c (qw/elements tags/) { # ---- elem,tag -----
      $check{$c} = 0;
      $rel{$c}   = '';
      $this = $widgets_frame ->
	Checkbutton(-selectcolor => $::colors{radio},
		    -foreground=> $::colors{'label'},
		    -text=>$$::labels{'skip_sites'} . " " .
		    $$::labels{'skip_'.$c},
		    -variable=>\$check{$c}, )
	  -> grid(-column=>0, -row=>$r, -sticky=>'w');
      &::manage($this, "check");
      $this = $widgets_frame -> Label(-text=>$$::labels{'skip_matching'},
				      -foreground=> $::colors{'label'}, )
	-> grid(-column=>1, -row=>$r, -sticky=>'w');
      &::manage($this, "label");
      $this = $entry{$c} = $widgets_frame ->
	Entry(-width=>10, @::entry_args)
	  -> grid(-column=>2, -row=>$r, -sticky=>'w');
      &::manage($this, "entry");
      $this = $widgets_frame -> Label(-text=>$$::labels{'skip_re'},
				      -foreground=> $::colors{'label'}, )
	-> grid(-column=>3, -row=>$r++, -sticky=>'w');
      &::manage($this, "label");
    };
    foreach my $c (qw/x y z/) {	# ---- x,y,z -----
      $check{$c} = 0;
      $this = $widgets_frame ->
	Checkbutton(-selectcolor => $::colors{radio},
		    -foreground	 => $::colors{'label'},
		    -text	 =>$$::labels{'skip_sites'} . " $c",
		    -variable	 =>\$check{$c}, )
	  -> grid(-column=>0, -row=>$r, -sticky=>'w');
      &::manage($this, "check");
      $this = $relation{$c} = $widgets_frame ->
	Optionmenu(-textvariable     => \$rel{$c},
		   -foreground       => $::colors{'label'},
		   -background       => $::colors{'entry'},
		   -activeforeground => $::colors{'label'},
		   -activebackground => $::colors{'entry'},
		   -width=>3, -font=>$::fonts{'label'}, -relief=>'groove')
	  -> grid(-column=>1, -row=>$r);
      &::manage($this, "menu");
      foreach my $e (qw/> >= == <= < /) {
	$this = $relation{$c} -> command(-label => $e, @::menu_args,
					 -command=>sub{$rel{$c}=$e;});
	&::manage($this, "menu");
      };
      $this = $entry{$c} = $widgets_frame ->
	Entry(-width=>10, @::entry_args)
	  -> grid(-column=>2, -row=>$r, -sticky=>'w');
      &::manage($this, "entry");
      $this = $widgets_frame -> Label(-text=>$$::labels{'skip_numeric'},
				      -foreground=> $::colors{'label'}, )
	-> grid(-column=>3, -row=>$r++, -sticky=>'w');
      &::manage($this, "label");
    };
    ##-- OK button
    my $buttons_frame = $skip_window -> Frame() -> pack(-fill=>'x', -expand=>1);
    $this = $buttons_frame ->
      Button(-text=>$$::labels{'dismiss'}, @::button_args,
	     -command=>sub{$skip_window->withdraw; })
      -> pack(-side=>'right', -padx=>4);
    &::manage($this, "button");
    $::balloon->attach($this, -msg=>$$::help{'dismiss_skip'},);
    $this = $buttons_frame ->
      Button(-text=>$$::labels{'apply'}, @::button_args,
	     -command=>sub{&apply_skip(\%check, \%rel, \%entry);})
      -> pack(-side=>'right', -padx=>10);
    &::manage($this, "button");
    $::balloon->attach($this, -msg=>$$::help{'apply_skip'},);
  } else {
    $skip_window->deiconify;
    $skip_window->raise;
  };
};

sub apply_skip {
  my ($r_check, $r_rel, $r_entry) = @_;
  foreach my $k (qw/elements tags/) { # regular expressions
    next unless ($$r_check{$k});
    my $skip_re = $$r_entry{$k} -> get();
    next unless $skip_re;
    my $t = ($k eq 'elements') ? 'elem' : substr($k,0,-1);
    foreach my $s (@site_entry) {
      ($$s{$t}->get() =~ /$skip_re/i) and $$s{'skip'} -> select();
    };
  };
  foreach my $k (qw/x y z/) {	# simple math relations
    next unless ($$r_check{$k});
    my $bound = $$r_entry{$k} -> get();
    ($bound eq "0") and $bound = "0.0";
    next unless $bound;
    foreach my $s (@site_entry) {
      my $val = $$s{$k}->get();
      my $string = join(" ", $val, $$r_rel{$k}, $bound);
      eval $string and $$s{'skip'} -> select();
    };
  };
};


1;
__END__
