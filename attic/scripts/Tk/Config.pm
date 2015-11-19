#!/usr/bin/perl -w
######################################################################
## TkAtoms configuration module for Atoms 3.0beta9
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

package Xray::Tk::Config;
use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(atoms_config);
$cvs_info = '$Id: Config.pm,v 1.7 2001/09/20 17:54:19 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

use Tk;
use Tk::widgets qw/ColorEditor/;
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));

my (%values, %initial);
my @variables = (		## variables
		 ['write_to_pwd',      'boolean'],
		 ['prefer_feff_eight', 'boolean'],
		 ['always_write_feff', 'boolean'],
		 ['display_balloons',  'boolean'],
		 ['no_crystal_warnings',  'boolean'],
		 ['one_frame',         'boolean'],
		 #['convolve_dafs',     'boolean'],
		 ['never_ask_to_save', 'boolean'],
		 ['atoms_language',    'list', \&Xray::Atoms::available_languages],
		 ['absorption_tables', 'list', \&Xray::Absorption::available],
		 ['dafs_default',      'list', \&Xray::Absorption::scattering],
		 ['unused_modifier',   'list',
		  sub{return ('Shift', 'Alt', 'Control', 'Meta')}],
		 ['default_filepath',  'directory'],
		 #['plotting_hook',     'string'],
		 ['ADB_location',      'string'],
				## colors
		 ['foreground',      'colors'],
		 ['background',      'colors'],
		 ['trough',          'colors'],
		 ['entry',           'colors'],
		 ['label',           'colors'],
		 ['balloon',         'colors'],
		 ['button',          'colors'],
		 ['buttonActive',    'colors'],
		 ['radio',           'colors'],
		 ['sgbActive',       'colors'],
		 ['sgbGroup',        'colors'],
		 #['done',            'colors'],
		 ['todo',            'colors'],
		 ['plot',            'colors'],
				## fonts
		 ['f_balloon',         'fonts'],
		 ['f_label',           'fonts'],
		 ['f_menu',            'fonts'],
		 ['f_button',          'fonts'],
		 ['f_header',          'fonts'],
		 ['f_entry',           'fonts'],
		 ['f_sgb',             'fonts'],
		);


my @label_args = ('-justify', 'left', '-width', 17, '-anchor', 'w',
		  '-foreground', $::colors{label},
		  '-font', $::fonts{label}, );
my @menu_args = (-foreground=>$::colors{label},
		 -activeforeground=>$::colors{label},
		 -font=>$::fonts{menu}, );
my @entry_args  = (-background=>$::colors{entry},
		   -font=>$::fonts{entry},
		   -insertbackground=>$::colors{foreground}, );
my @button_args = (-foreground => $::colors{entry},
		   -background => $::colors{button},
		   -activeforeground => $::colors{entry},
		   -activebackground => $::colors{buttonActive},
		   -font=>$::fonts{button},);

my ($count_colors, $count_variables) = (0,0);
my $force_restore = 0;
my ($top, $notebook, $ce);	# some widgets
my %color_button;
my $max_var_rows = 7;

sub atoms_config {
  my $parent = $_[0];
  ##   if ($^O eq 'MSWin32') {
  ##     my $dialog = $parent -> DialogBox(-title=>'TkAtoms: warning',
  ## 				      -buttons=>['OK'],);
  ##     $dialog -> add("Label", qw/-padx .25c -pady .25c -text/,
  ## 		   "The preferences selector has a high probability of$/" .
  ## 		   "hanging Windows 95 and 98, so it is currently disabled.$/" .
  ## 		   "on all Windows platforms.  Sorry.  Something to$/" .
  ## 		   "look forward to...")
  ##       -> pack(-side=>'left');
  ##     $dialog -> Show;
  ##     return;
  ##   };
  if (not Exists $top) {
    $top = $parent -> Toplevel(-class=>'horae');
    $top -> iconbitmap('@'.File::Spec->catfile($Xray::Atoms::lib_dir, "tkatoms3.xbm"))
      unless $is_windows;
    $top ->resizable(0,0);
    $notebook = $top -> NoteBook(-backpagecolor=>$::colors{background},
				 -inactivebackground=>$::colors{background},);
    $top -> bind('<Control-d>' => \&dump_values);
    my %pages;
    ($count_colors, $count_variables) = (0,0);
    my @note_args = (-anchor=>'center',);
    foreach my $f0 ('variables', 'colors', 'fonts') {
      $pages{$f0}  = $notebook -> add($f0, -label=>$$::config{$f0}, @note_args);
    };
    $notebook->pack(-expand => 'y', -side => 'top');

    my $button_frame = $top -> Frame(-relief=>'ridge', '-border'=>2)
      -> pack(-side=>'bottom', -fill=>'x');
    my $save_button = $button_frame
      -> Button(-text=>$$::config{'save_values'}, @button_args,
		-command=>\&write_new_rcfile)
	-> pack(-side=>'left', -fill=>'x', -padx=>2, -pady=>2, );
    &::manage($save_button, "button");
    exists ($$::config{'save_values_help'}) and
      $::balloon -> attach($save_button, -msg=>$$::config{'save_values_help'});
    my $dismiss_button = $button_frame -> Button(-text=>$$::config{dismiss},
						 @button_args,
						 -command=>sub{
						   $top->withdraw})
      -> pack(-side=>'right', -fill=>'x', -padx=>2, -pady=>2);
    &::manage($dismiss_button, "button");
    exists ($$::config{'dismiss_help'}) and
      $::balloon -> attach($dismiss_button, -msg=>$$::config{'dismiss_help'});

    ## ----- set up page of colors ---------------------------------------
    my $top_frame = $pages{'colors'} ->
      Frame(-border=>2, -relief=>'ridge') ->
	pack(-side=>'top',-fill=>'x', -expand=>1);
    my $palette_button = $top_frame ->
      Button(-text=>$$::config{'set_palette'},
	     @button_args,
	     -command=>[\&atoms_set_palette,$parent])
	-> pack(-side=>'left');
    &::manage($palette_button, "button");
    exists ($$::config{'set_palette_help'}) and
      $::balloon -> attach($palette_button, -msg=>$$::config{'set_palette_help'});
    my $restore_button = $top_frame ->
      Button(-text=>$$::config{'restore'},
	     @button_args,
	     -command=>[\&reset_values,'colors'])
	-> pack(-side=>'left');
    &::manage($restore_button, "button");
    exists ($$::config{'restore_palette_help'}) and
      $::balloon -> attach($restore_button,
			   -msg=>$$::config{'restore_palette_help'});
    my $color_explain = $top_frame ->
      Label(#-width=>100,
	    -foreground=>$::colors{label},
	    -text=>$$::config{'explain_colors'}) ->
	      pack(-side=>'left');
    &::manage($color_explain, "label");
    my $color_frame = $pages{'colors'} -> Frame() -> pack(-side=>'right');
    $ce = $color_frame -> ColorSelect() -> pack();
    ## yipes!!!  Rearrange some stuff in the color selector
    ##push @::all_menus, (($ce->children())[3]->children())[0]->children();
    ($ce->children())[1] -> configure('-width'=>18);
    unless ($^O eq 'MSWin32') {
      ($ce->children())[5] -> configure('-length'=>'4c');
      ($ce->children())[7] -> configure('-length'=>'4c');
      ($ce->children())[9] -> configure('-length'=>'4c');
      ((($ce->children())[3]->children())[0]->children())[0]
	-> invoke('RGB color space');
    };
    ## need to load color selector widgets into all_ arrays (ugh!)
    my $color_list_frame = $pages{'colors'} ->
      Frame(-border=>1, -relief=>'groove') ->
	pack(-side=>'left');

    ## ----- set up page of variables ------------------------------------
    $top_frame = $pages{'variables'} ->
      Frame(-border=>2, -relief=>'ridge') ->
	pack(-side=>'top',-fill=>'x', -expand=>1, -anchor=>'n');
    my $variables_frame = $pages{'variables'} ->
      Frame(-border=>2, -relief=>'groove') ->
      pack(-side=>'left', -padx=>2, -pady=>2, -fill=>'y');

    my $set_button = $top_frame ->
      Button(-text=>$$::config{'set_variables'}, @button_args,
	     -command=>[\&::set_variables, \%values])
	-> pack(-side=>'left');
    &::manage($set_button, "button");
    exists ($$::config{'set_variables_help'}) and
      $::balloon -> attach($set_button, -msg=>$$::config{'set_variables_help'});

    $restore_button = $top_frame ->
      Button(-text=>$$::config{'restore'},
	     @button_args,
	     -command=>[\&reset_values,'variables'])
	-> pack(-side=>'left');
    &::manage($restore_button, "button");
    exists ($$::config{'restore_variables_help'}) and
      $::balloon -> attach($restore_button,
			   -msg=>$$::config{'restore_variables_help'});

    foreach my $v (@variables) {
      if ($v->[1] eq 'colors') {
	&add_color($color_list_frame, $v->[0]);
      } elsif ($v->[1] eq 'fonts') {
	&add_font($pages{'fonts'}, $v->[0]);
      } elsif ($v->[1] eq 'boolean') {
	&add_boolean($variables_frame, $v->[0]);
	++$count_variables;
      } elsif ($v->[1] eq 'directory') {
	&add_directory($variables_frame, $v->[0]);
	++$count_variables;
      } elsif ($v->[1] eq 'string') {
	&add_string($variables_frame, $v->[0]);
	++$count_variables;
      } elsif ($v->[1] eq 'list') {
	&add_list($variables_frame, $v->[0], $v->[2]);
	++$count_variables;
      };
    };


    ## ----- set up page of fonts ----------------------------------------
    my $label = $pages{'fonts'} ->
      Label(-text=>'Sorry.  No font configuration yet.')
	->pack();
    &::manage($label, "label");

    $top -> title($$::config{config_title});
    $top -> iconname($$::config{config_title});
    $top -> bind('<Control-q>' => sub{$top->destroy});
  } else {
    $top->deiconify;
    $top->raise;
  }
  foreach my $k (keys %values) {
    $initial{$k} = $values{$k};
  };
  return ($top, $notebook);
};


######################################################################
## subroutines for filling configuration notecards

sub display_name {
  my $name = $_[0];
  my @name = split(/_/, $name);
  ($name[0] =~ /^[fc]$/i) and shift @name;
  @name = map {ucfirst($_)} @name;
  return join(" ", @name);
};

sub add_list {
  my ($parent, $name, $r_function) = @_;
  my $this_row = $count_variables % $max_var_rows;
  my $col_add  = int($count_variables / $max_var_rows);
  $col_add &&= $col_add*3+1;
  my $current = $::meta{$name};
  $current = ucfirst($current);
  ($current eq 'Cl') and $current = 'CL';
  ($current eq 'Mcmaster') and $current = 'McMaster';
  $values{$name}  = $current;
  my $space = $parent -> Label(-text=>' ') ->
    grid(-row=>$this_row, -column=>0+$col_add, -sticky=>'w');
  my $label = $parent -> Label(-text=>&display_name($name), @label_args) ->
    grid(-row=>$this_row, -column=>1+$col_add, -sticky=>'w');
  &::manage($label, "label");
  exists ($$::config{$name}) and
    $::balloon -> attach($label, -msg=>$$::config{$name});
  my $menu = $parent
    -> Optionmenu(-textvariable     => \$current,
		  -background       => $::colors{entry},
		  -activeforeground => $::colors{label},
		  -activebackground => $::colors{entry},
		  -width=>10, -font=>$::fonts{label},
		  -relief=>'groove')
      -> grid(-row=>$this_row, -column=>2+$col_add, -sticky=>'we');
  &::manage($menu, "menu");
  foreach my $s (&$r_function) {
    my $this = $menu -> command(-label => $s, @menu_args,
				-command=>sub{$values{$name}=$s; $current=$s});
    &::manage($menu, "menu");
  };
};


sub add_string {
  my ($parent, $name) = @_;
  my $this_row = $count_variables % $max_var_rows;
  my $col_add  = int($count_variables / $max_var_rows);
  $col_add &&= $col_add*3+1;
  my $current = $::meta{$name};
  $values{$name}  = $current;
  my $space = $parent -> Label(-text=>' ') ->
    grid(-row=>$this_row, -column=>0+$col_add, -sticky=>'w');
  my $label = $parent -> Label(-text=>&display_name($name), @label_args)
    -> grid(-row=>$this_row, -column=>1+$col_add, -sticky=>'w');
  &::manage($label, "label");
  exists ($$::config{$name}) and
    $::balloon -> attach($label, -msg=>$$::config{$name});
  my $entry = $parent -> Entry(-textvariable=>\$values{$name}, @entry_args)
    -> grid(-row=>$this_row, -column=>2+$col_add);
  #$entry -> delete(qw/0 end/);
  #$entry -> insert(0,$current);
  &::manage($entry, "entry");
};

sub add_directory {
  my ($parent, $name) = @_;
  my $this_row = $count_variables % $max_var_rows;
  my $col_add  = int($count_variables / $max_var_rows);
  $col_add &&= $col_add*3+1;
  my $current = $::meta{$name};
  $values{$name}  = $current;
  my $space = $parent -> Label(-text=>' ') ->
    grid(-row=>$this_row, -column=>0+$col_add, -sticky=>'w');
  my $label = $parent -> Label(-text=>&display_name($name), @label_args)
    -> grid(-row=>$this_row, -column=>1+$col_add, -sticky=>'w');
  &::manage($label, "label");
  exists ($$::config{$name}) and
    $::balloon -> attach($label, -msg=>$$::config{$name});
  my $entry = $parent -> Entry(-textvariable=>$current, @entry_args)
    -> grid(-row=>$this_row, -column=>2+$col_add);
  &::manage($entry, "entry");
  my $home;
  eval '$home = $ENV{"HOME"} || $ENV{"LOGDIR"} || (getpwuid($<))[7];'
    or $home = "";
  my $button = $parent ->
    Button(-text=>$$::config{'browse'},
	   @button_args,
	   -command=>sub{
	     local $Tk::FBox::a;
	     local $Tk::FBox::b;
	     my $types = [['All Files', '*'],];
	     my $path = $::meta{default_filepath} || Cwd::cwd();
	     $current = $top ->
	       getOpenFile(-defaultextension=>'inp',
			   -filetypes=>$types,
			   #(not $is_windows) ?
		  	   #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : (),
			   -initialdir=>$path,
			   -title => "Configure TkAtoms");
	     $values{$name}=$current;
	     $entry -> delete(0,'end');
	     $entry -> insert(0,$current);
	     return 0;
	   })
      -> grid(-row=>$this_row, -column=>3+$col_add, -padx=>2, -sticky=>'w');
  exists ($$::config{browse_help}) and
    $::balloon -> attach($button, -msg=>$$::config{browse_help});
  &::manage($button, "button");
}

sub add_boolean {
  my ($parent, $name) = @_;
  my @args = qw/-offvalue 0 -onvalue 1/;
  my $this_row = $count_variables % $max_var_rows;
  my $col_add  = int($count_variables / $max_var_rows);
  $col_add &&= $col_add*3+1;
  my $current = $::meta{$name};
  $values{$name}  = $current;
  my $space = $parent -> Label(-text=>' ') ->
    grid(-row=>$this_row, -column=>0+$col_add, -sticky=>'w');
  my $button = $parent -> Checkbutton(@args, -text=>&display_name($name),
				      -selectcolor=>$::colors{radio},
				      -variable=>\$current, @label_args,
				      -command=>sub{$values{$name}=$current} )
    -> grid(-row=>$this_row, -column=>1+$col_add, -sticky=>'w');
  &::manage($button, "check");
  exists ($$::config{$name}) and
    $::balloon -> attach($button, -msg=>$$::config{$name});
};

sub add_color {
  my ($parent, $name) = @_;
  my $frame = $parent -> Frame(-borderwidth=>1, -relief=>'sunken')
    -> grid(-column=>($count_colors%2), -row=>int($count_colors/2));
  ++$count_colors;
  my $current = $::colors{$name};
  $values{$name}  = $current;
  $color_button{$name} = $frame -> Label(-text=>'   ', -background=>$current,
			      -borderwidth=>1, -relief=>'raised')
    -> pack(-side=>'left', -padx=>4);
  my $label = $frame -> Label(-text=>&display_name($name),
			      -width=>12, @label_args)
    -> pack(-side=>'left');
  &::manage($label, "label");
  exists ($$::config{$name}) and
    $::balloon -> attach($label, -msg=>$$::config{$name});
  my $button = $frame ->
    Button(-text=>$$::config{'set'},
	   @button_args,
	   -command=>sub{
	     $current = ($ce->children())[11] -> get();
	     $values{$name} = $current;
	     $color_button{$name} -> configure(-background=>$current);
	   })
      -> pack(-side=>'left');
  &::manage($button, "button");
  exists ($$::config{set_color_help}) and
    $::balloon -> attach($button, -msg=>$$::config{set_color_help});
}

sub add_font {
  my ($parent, $name) = @_;
  my $n = substr($name, 2);
  my $current = $::fonts{$n};
  $values{$name}  = $current;
  1;
}

sub reset_values {
  my $which = $_[0];
  $force_restore = 1;
  foreach my $k (keys %values) {
    if ( (($which eq 'colors') or ($which eq 'all'))
	 and
	 ($k =~ /^c_/) ) {
      $values{$k} = $initial{$k};
      $color_button{$k} -> configure(-background=>$values{$k});
    };
    if ( (($which eq 'variables') or ($which eq 'all'))
	 and
	 ($k !~ /^[cf]_/) ) {
      $values{$k} = $initial{$k};
      eval "\$$k = $values{$k};";
    };
    ## fonts
  };
};


sub atoms_set_palette {
  my @palette = (background  => $values{background},
 		 foreground  => $values{foreground},
		 troughColor => $values{trough},);
  ## set $colors hash to its new values for future widgets
  my $noisy = 0;

  ## set overall palette stuff (if necessary)
  my $do_palette = ( $force_restore
		     or
		     (lc($values{background}) ne lc($initial{background}))
		     or
		     (lc($values{foreground}) ne lc($initial{foreground}))
		     or
		     (lc($values{trough})     ne lc($initial{trough}))
		   );
  $do_palette and $::top -> setPalette(@palette);
  $force_restore = 0;
  ## balloon colors
  $::balloon -> configure(-background=>$values{balloon},
			  -foreground=>$values{balloon});

  ## labels
  $noisy and print "labels\n";
  foreach my $w (@::all_labels) {
    next unless (Exists($w));
    $w -> configure(-foreground => $values{label});
  };
  ## buttons
  $noisy and print "buttons\n";
  foreach my $w (@::all_buttons) {
    next unless (Exists($w));
    $w -> configure(-foreground => $values{entry},
		    -background => $values{button},
		    -activeforeground => $values{entry},
		    -activebackground => $values{buttonActive},);
  };
  ## entries
  $noisy and print "entries\n";
  foreach my $w (@::all_entries) {
    next unless (Exists($w));
    $w -> configure(-background=>$values{entry},
		    #-font=>$values{f_entry},
		    -insertbackground=>$values{foreground},);
  };
  ## radio buttons (menu)
  $noisy and print "radio\n";
  foreach my $w (@::all_radio) {
    #next unless (Exists($w));
    $w -> configure(-selectcolor => $values{button},
		    -foreground=>$values{label},
		    -activeforeground=>$values{label},
		    -activebackground => $values{entry},
		   );
  };
  ## check buttons (label)
  $noisy and print "check\n";
  foreach my $w (@::all_check) {
    next unless (Exists($w));
    $w -> configure(-selectcolor => $values{button},
		    -foreground => $values{label}
		   );
  };
  ## headers
  $noisy and print "headers\n";
  foreach my $w (@::all_headers) {
    next unless (Exists($w));
    $w -> configure(-foreground=>$values{button},
		    #-font=>$values{f_header},
		    );
  };
  ## menu buttons and entries
  $noisy and print "menus\n";
  foreach my $w (@::all_menus) {
    ## next unless (("$w" !~ /cascade|command/i) and Exists($w));
    $w -> configure(-foreground	      => $values{label},
		    -activeforeground => $values{label},
		    -activebackground => $values{entry},
		    -background       => $values{background},
		    ##-font=>$$fonts{menu},
		   );
    ($w =~ /Option/) and
      $w -> configure(-background       => $values{background},
		      -activebackground => $values{entry},);
    ($w =~ /Menu::[CR]/) and
      $w -> configure(-background       => $values{background},
		      -activebackground => $values{entry},);
  };
  ## separators
  ## $noisy and print "separators\n";
  ## foreach my $w (@::all_separators) {
  ##   print $w -> configure(), $/; #-background => $values{background});
  ## };
  ## LabFrames
  $noisy and print "labframes\n";
  foreach my $w (@::all_labframes) {
    next unless (Exists($w));
    $w -> configure(-foreground=>$values{label});
  };
  ## scales
  $noisy and print "scales\n";
  foreach my $w (@::all_scales) {
    next unless (Exists($w));
    $w -> configure(-foreground=>$values{label});
  };
  ## canvases
  $noisy and print "canvases\n";
  foreach my $w (@::all_canvas) {
    next unless (Exists($w));
    $w -> configure(-background=>$values{todo});
  };
  my @toss = @::all_progress;
  while (@toss) {
    my $w = shift(@toss);
    next unless (Exists($w));
    my $id = shift(@toss);
    $w -> itemconfigure($id, -fill=>$values{done});
  };

  ## set $::colors hash to this set of values
  foreach my $c (qw/foreground background trough entry label
		 balloon button buttonActive sgbActive
		 sgbGroup done todo plot/) {
    my $t = substr($c, 2);
    $::colors{$t} = $values{$c};
  };
  &::set_arg_arrays;

};


sub write_new_rcfile {
  my $file = &Xray::Atoms::rcfile_name;
  die "could not determine config file\n", return if ($file =~ /\?/);
  if (-e $file) { rename ($file, $file.".bak") or die $!; };
  open RC, ">".$file or die $!;
  print RC <<EOH
## -*- mode: perl -*-
## This atomsrc file was generated automatically by TkAtoms $Xray::Atoms::VERSION
## using Tk/Config.pm $VERSION

EOH
  ;

  print RC $/, '[meta]', $/;
  foreach my $v (@variables) {
    my $key = $v->[0];
    if (($v->[1] ne 'colors') and ($v->[1] ne 'fonts')) {
      printf RC "   %-20s = %s$/", $key, $values{$key};
    };
  };
  print RC $/, '[colors]', $/;
  foreach my $v (@variables) {
    my $key = $v->[0];
    if ($v->[1] eq 'colors') {
      printf RC "   %-20s = %s$/", $key, $values{$key};
    };
  };
  print RC $/, '[fonts]', $/;
  foreach my $v (@variables) {
    my $key = $v->[0];
    if ($v->[1] eq 'fonts') {
      printf RC "   %-20s = %s$/", substr($key,2), $values{$key};
    };
  };
  close RC;
  my $text = "Saved configurations to $file.
Saved old rcfile to $file.bak.";
  &main::tkatoms_text_dialog (\$top, $text, 'left');
  $top->update;
};

sub dump_values {
  my $string =  <<EOH
## This is what your atomsrc file would like if you were to push the
## "Save values" button now.

EOH
  ;

  $string .= $/ . '[meta]' . $/;
  foreach my $v (@variables) {
    my $key = $v->[0];
    if (($v->[1] ne 'colors') and ($v->[1] ne 'fonts')) {
      $string .= sprintf("   %-20s = %s$/", $key, $values{$key});
    };
  };
  $string .= $/ . '[colors]' . $/;
  foreach my $v (@variables) {
    my $key = $v->[0];
    if ($v->[1] eq 'colors') {
      $string .= sprintf("   %-20s = %s$/", $key, $values{$key});
    };
  };
  $string .= $/ . '[fonts]' . $/;
  foreach my $v (@variables) {
    my $key = $v->[0];
    if ($v->[1] eq 'fonts') {
      $string .= sprintf("   %-20s = %s$/", substr($key,2), $values{$key});
    };
  };
  &::display_in_frame($top, \$string,);
};

1;
__END__
