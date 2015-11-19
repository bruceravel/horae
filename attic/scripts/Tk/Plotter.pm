#!/usr/bin/perl -w
######################################################################
## Plotter notecard module for Atoms 3.0beta9 using Ifeffit
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

package Xray::Tk::Plotter;

use strict;
use vars qw($VERSION $cvs_info @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(plotter);
$cvs_info = '$Id: Plotter.pm,v 1.2 2001/09/20 17:55:28 bruce Exp $ ';
$VERSION = (split(' ', $cvs_info))[2] || 'pre_release';

require Tk;
require Xray::Atoms;
use Ifeffit qw(ifeffit put_array get_scalar put_scalar get_echo);
my $is_windows = (($^O eq 'MSWin32') or ($^O eq 'cygwin'));

ifeffit('set &screen_echo = 0');

my ($plot_frame, $menubar);
my $this;
my (%plotter_values, @plotter_history, $plotter_pointer);

$plotter_values{command} = '';
push @plotter_history, $plotter_values{command};
$plotter_pointer = $#plotter_history;


my %function_refs = ('cursor'   => \&cursor,
		     'zoom'	=> \&zoom,
		     'unzoom'	=> \&unzoom,
		     'read'	=> \&read_data,
		     'previous'	=> [\&history, -1],
		     'next'	=> [\&history, 1],
		    );



sub plotter {
  $plot_frame = $::pages{Plotter} -> Frame() -> pack(-fill=>'x');
  ##$plot_frame -> Tk::bind('<Up>',   sub{&history(-1)});
  ##$plot_frame -> Tk::bind('<Down>', sub{\&history(1)});

  ## ---- menubar -----------
  $menubar = $plot_frame -> Frame(-borderwidth=>2, -relief=>'ridge',)
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

  my $show_menu = $menubar ->
    Menubutton(-text=>'Show', @::menu_args) ->
      pack(-side=>'left');
  &::manage($show_menu, "menu");
  foreach my $l (qw(@scalars @arrays @groups @strings @commands @macros)) {
    my $this = $show_menu ->
      command(-label=>$l, @::menu_args,
	      -command=>sub{&write_command("show $l"); &send_command()});
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
  my $top_frame = $plot_frame -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-pady=>1, -side=>'top');
  my $plot_label = $top_frame ->
    Label(-text=>"Plotter: ".$$::labels{'plotter_description'}, @::header_args, ) ->
      pack();
  &::manage($plot_label, "header");


  ## ----- frame containing the command line
  my $command_frame = $plot_frame -> Frame(-borderwidth=>1)
    -> pack(-pady=>1);
  my $command_label = $command_frame -> Label(-text=>$$::labels{plotter_command},
					      @::label_args)
    -> pack(-side=>'left', -padx=>2);
  &::manage($command_label, "label");
  my $command_button = $command_frame ->
    Button(-text=>$$::labels{'plotter_enter'},
	   @::button_args, -command=>\&send_command)
    -> pack(-side=>'right', -padx=>2);
  &::manage($command_button, "button");
  my $command_entry = $command_frame ->
    Entry(-textvariable=>\$plotter_values{command},
	  @::entry_args, -width=>60, -justify=>'left', -relief=>'sunken')
    -> pack(-side=>'right', -padx=>2);
  &::manage($command_entry, "entry");
  $command_entry -> Tk::bind('<Key-Return>', \&send_command);
  $command_entry -> Tk::bind('<Up>',   sub{&history(-1)});
  $command_entry -> Tk::bind('<Down>', sub{\&history(1)});

  $::balloon->attach($command_label,  -msg=>$$::help{plotter_command},);
  $::balloon->attach($command_button, -msg=>$$::help{plotter_command},);


  ## ----- frame containing various utility buttons
  my $button_frame = $plot_frame -> Frame(-borderwidth=>1)
    -> pack(-pady=>1);
  foreach (qw(cursor zoom unzoom read previous next)) {
    my $button = $button_frame -> Button(-text=>$$::labels{'plotter_'.$_},
					 @::button_args,
					 -command=>$function_refs{$_})
      -> pack(-side=>'left', -padx=>2);
    &::manage($button, "button");
    $::balloon->attach($button, -msg=>$$::help{"plotter_".$_},);
  };

  ## ----- frame containing the scrolling output buffer
  my $output_frame = $plot_frame -> Frame(-borderwidth=>0)
    -> pack(-pady=>4, -padx=>4, -expand=>1, -fill=>'both');
  $plotter_values{output_box} = $output_frame
    -> Scrolled('Text', qw/-scrollbars e -height 7 -wrap word/);
  $plotter_values{output_box}->Subwidget("yscrollbar")->configure(-background=>$::colors{background});
  $plotter_values{output_box}->pack(qw/-side left -expand 1 -fill both/);
  $plotter_values{output_box}->configure(qw/-state disabled/);
};

sub command {
  &write_command($_[0]);
  &send_command;
};

sub write_command {
  $plotter_values{command} = $_[0];
};

sub send_command {
  return if ($plotter_values{command} =~ /^\s*$/);
  ifeffit($plotter_values{command});
  $plotter_history[$#plotter_history] = $plotter_values{command};
  push @plotter_history, '';
  $plotter_pointer = $#plotter_history;
  $plotter_values{command} = '';
  my $string;
  map {$string .= Ifeffit::get_echo().$/} (0..Ifeffit::get_scalar('&echo_lines'));
  return if ($string =~ /^\s*$/);
  $plotter_values{output_box} -> configure(qw/-state normal/);
  $plotter_values{output_box} -> insert('end', $string);
  $plotter_values{output_box} -> yview('end');
  $plotter_values{output_box} -> configure(qw/-state disabled/);
};

sub history {
  $plotter_pointer += $_[0];
  ($plotter_pointer < 0) and ($plotter_pointer = 0);
  ($plotter_pointer > $#plotter_history) and
    ($plotter_pointer = $#plotter_history);
  write_command($plotter_history[$plotter_pointer]);
};

sub read_data {
  require Cwd;
  local $Tk::FBox::a;
  local $Tk::FBox::b;
  my $path = $::default_filepath || Cwd::cwd();
  my $types = [['Data files', '.dat' ],
	       ['All Files',  '*', ],];
  my $fname = $::top -> getOpenFile(-filetypes=>$types,
				    #(not $is_windows) ?
				    #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				    -initialdir=>$path,
				    -title => $$::labels{'save_dialog'});
  return 0 unless $fname;
  ($path !~ /\/$/) and $path .= '/';
  $fname =~ s/$path//;
  write_command("read_data(file=$fname, type=raw, group=my)");
};

sub cursor {
  &command('cursor');
  &command('echo (X ,Y) of the selected point:');
  &command('print   cursor_x   cursor_y');
};

## need to build a zoom stack which gets emptied with every newplot
sub zoom {
  &command('zoom');
};

sub unzoom {
  my $string = "Unzooming is not yet available.$/";
  $plotter_values{output_box} -> configure(qw/-state normal/);
  $plotter_values{output_box} -> insert('end', $string);
  $plotter_values{output_box} -> yview('end');
  $plotter_values{output_box} -> configure(qw/-state disabled/);
};


sub plot_with_Ifeffit {
  my ($x, $y, $newplot, $id, $group, $key) = @_;
  unless (@$x and @$y) {
    $::top -> messageBox(-icon    => 'error',
			 -message => "You have not made a calculation yet!",
			 -title   => 'Atoms: Error',
			 -type    => 'OK');
    return;
  };
  ifeffit('set &screen_echo = 0');
  ifeffit('macro; cursor; print cursor_x corsor_y; end macro');
  put_scalar("foo", 5);
  $group = $$group || "my";
  put_array($group.'.x', $x);
  put_array($group.'.y', $y);
  my $args = '';
 SWITCH: {
    ((lc($id) eq 'powder') and ($newplot)) and do {
      $args = "xlabel=2theta, ylabel=intensity, title=\"Powder simulation\", key=$key";
      last SWITCH;
    };
    ((lc($id) eq 'powder') and (not $newplot)) and do {
      $args = "key=$key";
      last SWITCH;
    };
    ((lc($id) eq 'dafs') and ($newplot)) and do {
      $args = "xlabel=energy, ylabel=intensity, title=\"DAFS simulation\", key=$key";
      last SWITCH;
    };
    ((lc($id) eq 'dafs') and (not $newplot)) and do {
      $args = "key=$key";
      last SWITCH;
    };
  };
  my $string = ($newplot) ? "newplot($group.x, $group.y, $args)" :
    "plot($group.x, $group.y, $args)";
  &write_command($string);
  &send_command();
};

sub saveplot {
  my ($format, $fname) = @_;
  my $dev;
 SWITCH: {
    (lc($format) eq 'gif') and do {
      $dev = '/gif';
      last SWITCH;
    };
    (lc($format) eq 'ps') and do {
      $dev = '/cps';
      last SWITCH;
    };
    $dev = '/gif';
  };

  my $path = $::default_filepath || Cwd::cwd();
  my $types = [[uc($format), ".".lc($format) ],
	       ['All Files',   '*', ],];
  my $file = $::top -> getSaveFile(-defaultextension=>'inp',
				   -filetypes=>$types,
				   #(not $is_windows) ?
				   #(-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				   -initialfile=>$fname,
				   -title => $$::labels{'save_dialog'});
  if ($file) {
    ifeffit("plot(device=\"$dev\", file=\"$file\")\n");
    ifeffit("plot(device=\"/xserve\", file=\"\")\n");
  };

};

1;
__END__
