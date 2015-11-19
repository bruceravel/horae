# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
## MISCELLANEOUS FUNCTIONALITY FOR ARTEMIS


## turn off the mouse-3 pop-up menu which is normal for a text widget
sub disable_mouse3 {
  my $text = $_[0];
  my @swap_bindtags = $text->bindtags;
  $text -> bindtags([@swap_bindtags[1,0,2,3]]);
  $text -> bind('<Button-3>' => sub{$_[0]->break});
};


sub get_index {
  if ($_[0] =~ /data(\d+)(_(fit|bkg))?/) {
    return $1;
  } elsif ($_[0] =~ /feff(\d+)(\.\d+)?/) {
    return $1;
  };
  return undef;
};

## tell ifeffit to erase all groups that match $_[0] (e.g. all feff0...)
sub erase_many_groups {
  my $match = $_[0];
  $paths{gsd}->dispose("show \@groups", 1);
  my ($lines, $response) = (Ifeffit::get_scalar('&echo_lines'), "");
  my @list = map {Ifeffit::get_echo()} (1 .. $lines);
  ## print $/, join(" ", @list), $/;
  my $string = "";
  foreach (@list) {
    next unless (/^$match/);
    $string .= "erase \@group $_\n";
  };
  $paths{gsd}->dispose($string, $dmode);
  return 0;
};

sub set_status {
  return if (Ifeffit::Tools->vstr < 1.02007);
  my $val = $_[0] || 0;
  $paths{gsd} -> dispose("set \&status = $val", $dmode);
};


## splice words back together to make a multi-word string that is
## almost, but not quite the same as the original line.  take care to
## drop end of line comments and to replace commas in two argument
## math functions.
sub concat {
  my @list = @_;
  my $string = "";
  while (@list) {
    my $this = shift(@list);
    if ($this =~ /^[%!*\#]/) {
      @list = ();
    } else {
      $string .= " " . $this;
    };
  };
  $string =~ s/^ //;
  $string =~ s/(debye|eins|max|min) ?\((\w+) /$1\($2,/;
  return $string;
};



## multiplexer for renaming list entries, bound to Ctrl-n, on the GDS
## page this is the same as clicking the New button
sub rename_this {
  my $type = $paths{$current}->type;
  &gds2_new,       return if ($type eq 'gsd');
  &rename_fit,     return if (($type eq 'fit') and $paths{$current}->get('parent'));
  Error("You cannot rename the head \"Fit\" entry"),        return if ($type eq 'fit');
  Error("You cannot rename a \"Background\" entry"),        return if ($type eq 'bkg');
  Error("You cannot rename a \"Residual\" entry"),          return if ($type eq 'res');
  Error("You cannot rename a \"Difference\" entry"),        return if ($type eq 'diff');
  &rename_feff(0), return if ($type eq 'feff');
  &rename_path,    return if ($type eq 'path');
  &rename_data,    return if ($type eq 'data');
};

## multiplexer for functionality bound to Ctrl-d
sub keyboard_d {
  gds2_define($widgets{gds2list}, \%gds_selected) if ($current_canvas eq 'gsd');
};
## multiplexer for functionality bound to Ctrl-e
sub keyboard_e {
  if ($current_canvas eq 'gsd') {
    if ($gds_selected{showing} eq 'show') {
      $widgets{gds2_show}->packForget;
      $widgets{gds2_editarea}->pack(-side=>=>'top', -fill=>'x', -padx=>4, -pady=>2);
      $gds_selected{showing}="edit";
    };
  };
};
## multiplexer for functionality bound to Ctrl-g
sub keyboard_g {
  grab_gds2($widgets{gds2list}, \%gds_selected) if ($current_canvas eq 'gsd');
};

## multiplexer for functionality bound to Alt-k
sub keyboard_alt_k {
  if ($current_canvas eq 'gsd') {
    gds2_up();
  } elsif (($current_canvas eq 'feff') and ($fefftabs->raised() eq 'Atoms')) {
    atoms_move('up');
  };
};

## multiplexer for functionality bound to Alt-j
sub keyboard_alt_j {
  if ($current_canvas eq 'gsd') {
    gds2_down();
  } elsif (($current_canvas eq 'feff') and ($fefftabs->raised() eq 'Atoms')) {
    atoms_move('down');
  };
};


## read a string from an entry box that temporarily replaces the echo
## area.  $label is the descriptive label to be written before the
## entry box.  $r_string is a ref to the string being prompted for.
## $r_arrow_buffer is a ref to a array containing a buffer of
## responses accessed via the up and down arrows
sub get_string {
  my ($mode, $label, $r_string, $r_arrow_buffer) = @_;
  $top -> packPropagate(0);
  $echo -> packForget;
  my $prior = $top -> focusCurrent;
  my $ren = $ebar -> Frame()
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -ipadx=>3);
  $top -> update();
  $ren -> grab();
  $ren -> Label(-text=>$label,
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  my $entry = $ren -> Entry(-justify=>'center', -background=>$config{colors}{current},
			    -textvariable=>$r_string)
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>10);
  if ($r_arrow_buffer and @$r_arrow_buffer) {
    my $pointer = $#{$r_arrow_buffer} + 1;
    $entry->bind("<KeyPress-Up>",	# previous command in history
		 sub{ --$pointer; ($pointer<0) and ($pointer=0);
		      $entry->delete(0,'end');
		      $entry->insert(0, $$r_arrow_buffer[$pointer]); });
    $entry->bind("<KeyPress-Down>", # next command in history
		 sub{ ++$pointer; ($pointer>$#{$r_arrow_buffer}) and
			($pointer= $#{$r_arrow_buffer});
		      $entry->delete(0,'end');
		      $entry->insert(0, $$r_arrow_buffer[$pointer]); });
  };
  my $pad = 0;
  $entry -> bind("<KeyPress-Return>", sub{&restore_echo($ren, $mode, $entry, $prior)});
  $ren -> Button(-text=>'OK',  @button2_list,
		 -font=>$config{fonts}{small},
		 -borderwidth=>1,
		 -width=>10,
		 -command=>[\&restore_echo, $ren, $mode, $entry, $prior])
    -> pack(-side=>'left');
  foreach ($ren, $entry) {
    my $this = $_;
    $this -> bindtags([($this->bindtags)[1,0,2,3]]);
    map {$this -> bind("<Control-$_>" => sub{$this->break;})}
      qw(a h l n o p r s t u v
	 slash period semicolon minus equal
	 Key-1 Key-2 Key-3 Key-4 Key-5 Key-6);
  };

  $entry -> selectionRange(qw(0 end));
  $entry -> icursor('end');
  $top   -> update;
  $entry -> focus;
  return $ren;
};
## destroy the get_string dialog and return the echo area
sub restore_echo {
  my ($ren, $mode, $entry, $prior) = @_;
  $ren -> grabRelease;
  $ren -> packForget;
  $ren -> destroy;
  $echo -> pack(-side=>'left', -expand=>1, -fill=>'x', -pady=>2);
  $prior -> focus;
};



## return an nleg value
sub get_nlegs {
  my $d = $top->Dialog(-title   => "Artemis: select paths",
		       -text    => "Maximum number of legs in fit:",
		       -buttons => ["2", "3", "4", "Cancel"],
		       -font    => $config{fonts}{med},
		       -popover => 'cursor');
  my $str = sprintf("+%d+%d", 0.4*$top->screenwidth(), 0.4*$top->screenheight());
  $d -> geometry($str);
  &posted_Dialog;
  my $val = $d -> Show();
  return $d -> Show();
};

## return a value for R_eff
sub get_r {
  my $crit;
  my $label = "Maximum Reff of included paths: ";
  my $dialog = get_string($dmode, $label, \$crit);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Error("Maximum Reff must be a positive number."), return 'Cancel'
    unless ($crit =~/^\s*(\d+\.?\d*|\.\d+)\s*$/);
  return $crit;
};

## return a value for ZCWIF
sub get_zcwif {
  my $crit;
  my $label = "Manimum amplitude for included paths: ";
  my $dialog = get_string($dmode, $label, \$crit);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Error("An amplitude factor must be a positive number."), return 'Cancel'
    unless ($crit =~/^\s*(\d+\.?\d*|\.\d+)\s*$/);
  return $crit;
};


sub set_fit_button {
 SWITCH: {
    ($_[0] eq 'fit') and do {
      $fit_button -> configure(-state=>'normal', -text=>'Fit',
			       -command=>[\&generate_script, 1]);
      last SWITCH;
    };
    ($_[0] eq 'apa') and do {
      $fit_button -> configure(-state=>'normal', -text=>'Start the Project Assistant',
			       -command=>sub{Echo("Uh oh! APA is not built in anymore")}); #\&apa);
      last SWITCH;
    };
    ($_[0] eq 'disable') and do {
      $fit_button -> configure(-state=>'disabled', -text=>'Fit',);
      last SWITCH;
    };
  };
};


sub layout {
 LAYOUT: {
    ($config{general}{layout} eq 'mlp') and do {
      $fat     -> pack(-side=>'left', -fill=>'y');
      $skinny  -> pack(-side=>'left', -expand=>1, -fill=>'both');
      $skinny2 -> pack(-side=>'left', -fill=>'y');
      last LAYOUT;
    };
    ($config{general}{layout} eq 'mpl') and do {
      $fat     -> pack(-side=>'left', -fill=>'y');
      $skinny2 -> pack(-side=>'left', -fill=>'y');
      $skinny  -> pack(-side=>'left', -expand=>1, -fill=>'both');
      last LAYOUT;
    };
    ($config{general}{layout} eq 'lmp') and do {
      $skinny  -> pack(-side=>'left', -expand=>1, -fill=>'both');
      $fat     -> pack(-side=>'left', -fill=>'y');
      $skinny2 -> pack(-side=>'left', -fill=>'y');
      last LAYOUT;
    };
    ($config{general}{layout} eq 'lpm') and do {
      $skinny  -> pack(-side=>'left', -expand=>1, -fill=>'both');
      $skinny2 -> pack(-side=>'left', -fill=>'y');
      $fat     -> pack(-side=>'left', -fill=>'y');
      last LAYOUT;
    };
    ($config{general}{layout} eq 'pml') and do {
      $skinny2 -> pack(-side=>'left', -fill=>'y');
      $fat     -> pack(-side=>'left', -fill=>'y');
      $skinny  -> pack(-side=>'left', -expand=>1, -fill=>'both');
      last LAYOUT;
    };
    ($config{general}{layout} eq 'plm') and do {
      $skinny2 -> pack(-side=>'left', -fill=>'y');
      $skinny  -> pack(-side=>'left', -expand=>1, -fill=>'both');
      $fat     -> pack(-side=>'left', -fill=>'y');
      last LAYOUT;
    };
  };
};

## convert backslashes to foreward slashes, remove multiple slashes,
## and remove the trailing slash from each string
sub normalize_directory {
  my $a = $_[0];
  $a =~ s/\\+/\//g;		# multiple backslashes
  $a =~ s/\/{2,}/\//g;		# 2 or more foreslashes
  $a =~ s/\/$//;		# trailing slash
  return $a;
};

sub same_directory {
  my ($a, $b) = @_;
  return 0 unless $a;
  return 0 unless $b;
  if ($is_windows) {
    $a=normalize_directory($a);
    $b=normalize_directory($b);
    return ($a eq $b);
  } else {
    my @a = stat $a;		# compare the inodes
    my @b = stat $b;
    return ($a[1] == $b[1]);
  };
};


## is $a a subdirectory of $b, sub_directory("foo/bar", "/foo")
## returns true
sub sub_directory {
  my ($a, $b) = @_;
  return 0 unless $a;
  return 0 unless $b;
  ##print "$a   $b\n";
  $a=normalize_directory($a);
  $b=normalize_directory($b);
  ##print "$a   $b\n";
  return ($a =~ /^$b/);
};


## move rc and mru files from their 0.6.001 and earlier locations to
## the .horae directory
sub convert_config_files {
  my $horae_dir = $setup -> find('artemis', 'horae');
  (-d $horae_dir) or mkpath($horae_dir);
  my $rcfile    = $setup -> find('artemis', 'oldrc');
  my $rctarget  = $setup -> find('artemis', 'rc_personal');
  my $mrufile   = $setup -> find('artemis', 'oldmru');
  my $mrutarget = $setup -> find('artemis', 'mru');
  ##print join(" ", $horae_dir, $rcfile, $rmrufile), $/;
  move($rcfile,  $rctarget)  if (-e $rcfile);
  move($mrufile, $mrutarget) if (-e $mrufile);
};


sub pod_display {
  my $file = $_[0];
  my $p = $top->Pod(-file=>$file);
  $p->zoom_in foreach (1 .. $config{general}{doc_zoom});
};


## display $str in echo area, $app true means to append $str to what
## is already there
sub Echo {
  my ($string, $append) = @_;
  my ($bg, $fn, $bt) = ($config{colors}{background},
			$config{fonts}{small},
			$config{colors}{button});
  $ebar -> configure(-background => $bg);
  $echo -> configure(-font       => $fn,
		     -foreground => $bt,
		     -background => $bg);
  return unless $string;
  ($append) and ($string = $echo -> cget('-text') . $string);
  $echo -> configure(-text=>(length($string) > 137) ? substr($string, 0, 137) : $string);
  ## push @echo_history, $string;
  ## ($#echo_history > 2000) and shift @echo_history;

  ## next line corrects a hierarchy problem on windows
  my $widg = (ref($notes{echo}) =~ m{Frame}) ? $notes{echo}->Subwidget('rotext') : $notes{echo};
  $widg -> insert('end', $string."\n");
  $widg -> yviewMoveto(1);
  $top -> update;
};
sub Running {
  Echo(@_);
  ## bold white on green
  my ($bg, $fn, $bt) = ($config{colors}{fitbutton}, $config{fonts}{smbold}, $config{colors}{warning_fg});
  $ebar -> configure(-background => $bg);
  $echo -> configure(-font       => $fn,
		     -foreground => $bt,
		     -background => $bg);
  $top -> update;
};
sub Attention {
  Echo(@_);
  ## bold white on red
  my ($bg, $fn, $bt) = ($config{colors}{warning_bg}, $config{fonts}{smbold}, $config{colors}{warning_fg});
  $ebar -> configure(-background => $bg);
  $echo -> configure(-font       => $fn,
		     -foreground => $bt,
		     -background => $bg);
  $top -> update;
};
sub Echo_nosave {
  my ($string, $append) = @_;
  return unless $string;
  ($append) and ($string = $echo -> cget('-text') . $string);
  $echo -> configure(-text=>$string);
  $top -> update;
};

sub Error {
  $top -> bell;
  Echo(@_);
};

sub posted_Dialog {
  Attention("You must respond to the posted dialog.  (These dialogs sometimes get hidden beneath other windows.)");
};

sub show_hint {
  Echo("Hints file was not found"), return unless @hints;
  $hint_n = int(rand $hint_x);
  Echo("HINT: " . $hints[$hint_n]);
  #++$hint_n;
  #($hint_n > $#hints) and $hint_n = 0;
};

sub track {
  no warnings;
  my %hash = %{ $_[0] };
  my @caller = caller(1);
  my $called_from = $caller[3];
  print "-" x 60, $/;
  print "called from: $called_from\n";
  foreach (keys %hash) {
    if (ref($hash{$_}) =~ /CODE/) {
      print &{ $hash{$_} };
    } else {
      print "$_ : $hash{$_}\n";
    };
  };
};

sub dump_paths {
  Echo("Dumping paths to \`artemis.dump\'");
  $Data::Dumper::Indent = 2;
  ##read_gds2(0);
  read_titles;
  $paths{journal} = $notes{journal}->get(qw(1.0 end));
  open DUMP, ">artemis.dump" or die $!;
  print DUMP Data::Dumper->Dump([\%paths], [qw/paths/]);
  print DUMP Data::Dumper->Dump([\%temp], [qw/temp/]);
  close DUMP;
  delete $paths{journal};
  $Data::Dumper::Indent = 0;
  Echo(@done);
};

sub swap_panels {
  Error("Swapping panels is temporarily disabled.");
  ##   if (grep {$_ eq 'right'} ($skinny -> packInfo())) {
  ##     $skinny -> pack(-side=>'left');
  ##     $list   -> configure(-scrollbars=>'w');
  ##   } else {
  ##     $skinny -> pack(-side=>'right');
  ##     $list   -> configure(-scrollbars=>'e');
  ##   };
};

sub BindMouseWheel {		# Mastering Perl/Tk ch. 15, p. 370
  my ($w) = @_;
  if ($^O eq 'MSWin32') {
    $w->bind('<MouseWheel>' =>
	     [ sub { $_[0]->yview('scroll', -($_[1]/120)*3, 'units') },
	       Ev('D') ]
	     );
  } elsif ($^O eq 'linux') {
    ## on linux the mousewheel works by mapping to buttons 4 and 5
    $w->bind('<4>' => sub { $_[0]->yview('scroll', -1, 'units') unless $Tk::strictMotif; });
    $w->bind('<5>' => sub { $_[0]->yview('scroll', +1, 'units') unless $Tk::strictMotif; });
  };
};


## respond to a mouse-3 event in the paths list by posting the
## context-appropriate menu
sub list_mouse_menu {
  return if ($list->entrycget('gsd', '-state') eq 'disabled');
  &anchor_display;
  my ($X, $Y) = @_;
 SWITCH: {
    $menubar -> Post($X, $Y, 4), last SWITCH if
      ($paths{$current}->{type} eq 'gsd');
    $menubar -> Post($X, $Y, 5), last SWITCH if
      ($paths{$current}->{type} =~ /(bkg|data|res)/);
    $menubar -> Post($X, $Y, 7), last SWITCH if
      ($paths{$current}->{type} eq 'fit');
    $menubar -> Post($X, $Y, 8), last SWITCH if
      ($paths{$current}->{type} eq 'feff');
    $menubar -> Post($X, $Y, 9), last SWITCH if
      ($paths{$current}->{type} eq 'path');
  };
}



sub quit_artemis {
  if ($config{general}{query_save} and !$project_saved) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "Would you like to save this project before exiting?",
		     -title          => 'Artemis: Exiting...',
		     -buttons        => [qw/Yes No Cancel/],
		     -default_button => 'Yes',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    Echo("Not quitting."), return if ($response eq 'Cancel');
    Echo("Preparing to quit ...");
    ($response eq 'Yes') and &save_project('all',0);
  };
  SWITCH: {
      $opparams	-> packForget(), last SWITCH if ($current_canvas eq 'op');
      $gsd	-> packForget(), last SWITCH if ($current_canvas eq 'gsd');
      $feff	-> packForget(), last SWITCH if ($current_canvas eq 'feff');
      $path	-> packForget(), last SWITCH if ($current_canvas eq 'path');
    };
  $top  -> update;
  ## clean up project directory
  (-d $project_folder) and rmtree($project_folder);
  ## delete autosave file
  unlink $autosave_filename if (-e $autosave_filename);
  opendir C, $stash_dir;
  map { my $f = File::Spec->catfile($stash_dir, $_);
	-f $f and unlink $f}
    (grep !/(^\.{1,2}|TRAP)$/, readdir C);
  closedir C;

  $mru{config}{last_working_directory} = $current_data_dir;

  ## remember the geometry, save it in the mru file
  my ($width, $height, $x, $y) = split(/[x+]/, $top->geometry);
  $mru{geometry}{height} = $height;
  $mru{geometry}{width}  = $width;
  $mru{geometry}{'x'}    = $x;
  $mru{geometry}{'y'}    = $y;
  ($width, $height, $x, $y) = split(/[x+]/, $update->geometry);
  $mru{geometry}{uheight} = $height;
  $mru{geometry}{uwidth}  = $width;
  $mru{geometry}{'ux'}    = $x;
  $mru{geometry}{'uy'}    = $y;
  tied(%mru) -> WriteConfig($mrufile);


  ## bye bye!
  $top->destroy();
  exit;
};

sub splash_message {
  my ($message) = @_;
  $splash_status -> configure(-text=>$message);
  $top -> update;
  #sleep 1;
};



## I got this off of Usenet.  Do a search at groups.google.com for the
## package to find discussions of slow dialog boxes.  The text of this
## will be among the discussions.
package Patch::SREZIC::Tk::Wm;

use Tk::Wm;
package Tk::Wm;

sub Post
{
 my ($w,$X,$Y) = @_;
 $X = int($X);
 $Y = int($Y);
 $w->positionfrom('user');
 # $w->geometry("+$X+$Y");
 $w->MoveToplevelWindow($X,$Y);
 $w->deiconify;
# $w->idletasks; # to prevent problems with KDE's kwm etc.
# $w->raise;
}

1;
