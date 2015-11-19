## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This section of the code contains miscellaneous subroutine which
##  do not fit in other sections


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


## turn off the mouse wheel
sub disable_mouse_wheel {
  my $w = $_[0];
  my @swap_bindtags = $w->bindtags;
  $w -> bindtags([@swap_bindtags[1,0,2,3]]);
  if ($^O eq 'MSWin32') {
    $w -> Tk::bind('<MouseWheel>' => sub{$_[0]->break});
  } else {
    $w -> Tk::bind('<4>' => sub{$_[0]->break});
    $w -> Tk::bind('<5>' => sub{$_[0]->break});
  };
};

## turn off the mouse-3 pop-up menu which is normal for a text widget
sub disable_mouse3 {
  my $text = $_[0];
  my @swap_bindtags = $text->bindtags;
  $text -> bindtags([@swap_bindtags[1,0,2,3]]);
  $text -> bind('<Button-3>' => sub{$_[0]->break});
};


sub about_demos {
  my $info = <<EOH
Demo projects are the best way to learn about the many features of
Athena.

They are project files that have been specially prepared to
demonstrate different aspects of Athena.  The name of the project
should give a hint as to which feature is being demonstrated.  Each of
the demo projects has extensive documentation and many hints about
things to try written in the journal.

To read the journal once you have imported the demo project, either
select "Write in project journal" from the Edit menu or hit Control-6.

EOH
  ;
  ## tidy up for display
  $info =~ s/\n/ /g;
  $info =~ s/ /\n\n/g;
  my $dialog =
    $top -> Dialog(-bitmap         => 'info',
		   -text           => $info,
		   -title          => 'Athena: About demo projects',
		   -buttons        => [qw/OK/],
		   -default_button => 'OK');
  my $response = $dialog->Show();
};


## this should probably be called "doc_display" or some such
sub pod_display {
  my ($file) = @_;

  ## a pm file goes straight to the pod browser
  if ($file =~ m{pm$}) {
    pod_post($file);
    return 1;
  };

  ## fire up a browser with the local html version of the pod  WWWBrowser vs. Tk::Pod::WWWBrowser ???
  my $succeeded = 0;
  if (($config{doc}{prefer} eq "html") and (eval { require WWWBrowser })) {
    my @list = @WWWBrowser::unix_browsers;
    unshift @list, $config{doc}{browser} if not $is_windows;
    @WWWBrowser::unix_browsers = @list;
    my $url = File::Spec->catfile(File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'aughtml'),
						      split("::", $file)));
    $url =~ s{pod$}{html};
    $succeeded = WWWBrowser::start_browser($url) if (-e $url);
  };
  return 1 if $succeeded;

  ## fire up browser with remote version of html
  ##  -- need a way to determine if we are online

  ## pod version of user's guide is installed
  if (-e File::Spec->catfile($groups{"Default Parameters"} -> find('athena', 'augpod'), "index.pod")) {
    pod_post($file);
    $succeeded = 1;
  };
  return 1 if $succeeded;

  ## cannot find any form of the document
  my $info = <<EOH
It seems that you have not installed the Athena User's Guide.

The User's Guide is distributed separately from the rest of Athena.
Go to

http://cars9.uchicago.edu/iffwiki/BruceRavel/EvolvingSoftware

and follow the simple installation instructions.

EOH
  ;
  $info =~ s{\n}{ }g;		## tidy up for display
  $info =~ s{ }{\n\n}g;
  my $dialog =
    $top -> Dialog(-bitmap         => 'info',
		   -text           => $info,
		   -title          => 'Athena: Missing document',
		   -buttons        => [qw/OK/],
		   -default_button => 'OK');
  my $response = $dialog->Show();
  return 0

};

sub pod_post {
  my ($file) = @_;
  my $p = $top->Pod(-file=>$file);
  $p->zoom_in foreach (1 .. $config{doc}{zoom});
};


sub quit_athena {
  my $ngroups = 0;
  foreach (keys %marked) { ++$ngroups };
  if ($ngroups and $config{general}{query_save} and !$project_saved) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "Would you like to save this project before exiting?",
		     -title          => 'Athena: Exiting...',
		     -buttons        => [qw/Yes No Cancel/],
		     -default_button => $config{general}{quit_query});
    my $response = $dialog->Show();
    ($response eq 'Cancel') and return;
    $config{general}{quit_query} = $response;
    my $config_ref = tied %config;
    $config_ref -> WriteConfig($personal_rcfile);
    ($response eq 'Yes') and &save_project('all');
  };

  ## clean up stash directory
  if ($config{general}{purge_stash}) {
    opendir C, $stash_dir;
    map { my $f = File::Spec->catfile($stash_dir, $_);
	  -f $f and unlink $f}
      (grep !/(^\.{1,2}|TRAP)$/, readdir C);
    closedir C;
  };
  unlink($groups{"Default Parameters"}->find('athena', 'temp_lcf'))
    if (-e $groups{"Default Parameters"}->find('athena', 'temp_lcf'));

  $mru{config}{last_working_directory} = $current_data_dir;

  ## remember the geometry, save it in the mru file
  my ($height, $width, $x, $y) = split(/[x+]/, $top->geometry);
  $mru{geometry}{height} = $height;
  $mru{geometry}{width}  = $width;
  $mru{geometry}{'x'}    = $x;
  $mru{geometry}{'y'}    = $y;
  tied(%mru) -> WriteConfig($mrufile);

  $top->destroy();
  exit;
};


## move rc and mru files from their 0.8.016 and earlier locations to
## the .horae directory
sub convert_config_files {
  my $horae_dir = $groups{"Default Parameters"} -> find('athena', 'horae');
  (-d $horae_dir) or mkpath($horae_dir);
  my $rcfile    = $groups{"Default Parameters"} -> find('athena', 'oldrc');
  my $rctarget  = $groups{"Default Parameters"} -> find('athena', 'rc_personal');
  my $mrufile   = $groups{"Default Parameters"} -> find('athena', 'oldmru');
  my $mrutarget = $groups{"Default Parameters"} -> find('athena', 'mru');
  ##print join(" ", $horae_dir, $rcfile, $rmrufile), $/;
  move($rcfile,  $rctarget)  if (-e $rcfile);
  move($mrufile, $mrutarget) if (-e $mrufile);
};

sub clean_old_trap_files {
  opendir S, $stash_dir;
  my @list = grep {/ATHENA/} readdir S;
  closedir S;
  map {unlink File::Spec->catfile($stash_dir, $_)} @list;
};


sub stash_directory {
  my $dir = $groups{"Default Parameters"} -> find('athena', 'horae');
  (-d $dir) or mkpath($dir);
  $dir = File::Spec->catfile($dir, "stash");
  (-d $dir) or mkpath($dir);
  $dir = $groups{"Default Parameters"} -> find('athena', 'userfiletypedir');
  (-d $dir) or mkpath($dir);
  $dir = $groups{"Default Parameters"} -> find('other', 'downloads');
  (-d $dir) or mkpath($dir);
  return $stash_dir;
};


## display $str in echo area, $app true means to append $str to what
## is already there
sub Echo {
  my ($str, $app) = @_;
  my $text = $echo -> cget('-text');
  ($str eq " ... done!") and ($text =~ s/ ... done!$//);
  ($app) and ($str = $text . $str);

  push @echo_history, $str;
  ## ($#echo_history > 2000) and shift @echo_history;
  $notes{echo} -> insert('end', $str."\n", "text");
  $notes{echo} -> yviewMoveto(1);

  ## strip off the character identifying the echo string as coming from Group.pm
  $str =~ s/^\>\s*//;
  if ($echo_pause) {
    $top -> after($echo_pause,
		  sub{$echo -> configure(-text=>(length($str) > 110) ?
					 substr($str, 0, 110)." ..." : $str);
		    });
  } else {
    $echo -> configure(-text=>(length($str) > 110) ?
		       substr($str, 0, 110)." ..." : $str);
  };
  $top -> update;
};

sub Error { $top->bell; Echonow(@_); };

sub Echonow { my $old=$echo_pause; $echo_pause=0; Echo(@_); $echo_pause=$old};


sub show_hint {
  Echo("Hints file was not found"), return unless @hints;
  $hint_n = int(rand $#hints);
  Echo("HINT: " . $hints[$hint_n]);
  #++$hint_n;
  #($hint_n > $#hints) and $hint_n = 0;
};

## this brings up the menu when a group in the skinny panel is
## right-clicked upon
sub GroupsPopupMenu {
 my ($w, $item, $X, $Y) = @_;
 set_properties(2, $item, 0);
 if (@_ < 3) {
   my $e = $w->XEvent;
   $X = $e->X;
   $Y = $e->Y;
 };
 $group_menu->Post($X,$Y) if defined $group_menu;
}

sub Leave {
  my $this = shift;
  my @normal   = (-fill => $config{colors}{foreground},); # -font => $config{fonts}{med},
  my @rect_out = (-fill => $config{colors}{background}, -outline=>$config{colors}{background});
  $this->configure(-cursor => 'top_left_arrow');
  return if not exists($groups{$current}->{bindtag});
  return if not $this->itemcget('current', '-tags');
  if ($this->itemcget('current', '-tags')->[0] ne $groups{$current}->{bindtag}) {
    my $x = $this->find(below=>'current');
    $this->itemconfigure($x, @rect_out,);
  };
};


## Dump the current states of important hashes to a file
sub Dumpit {
  Echo("Dumping groups and marked to \`athena.dump\'");
  $Data::Dumper::Indent = 2;
  open DUMP, ">athena.dump" or die $!;
  print DUMP Data::Dumper->Dump([\$current, \%groups, \%marked, \%lcf_data],
				[qw/current groups marked lcf_data/]);
  close DUMP;
  $Data::Dumper::Indent = 0;
  Echo("Dumping groups and marked to \`athena.dump\' ... done!");
};


sub reset_window {
  my ($parent, $which, $r_save) = @_;
  $parent -> packForget;
  undef $parent;
  $fat -> pack(-fill=>'both', -expand=>1);
  ##$peak->grabRelease; $peak->destroy;
  map {$_ -> configure(-state=>'normal')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat_showing = 'normal';
  $which_showing = undef;
  $hash_pointer = undef;
  set_properties(1, $current, 0) if ($current);
  ##print join(" ", $r_save, @$r_save), $/;
  if ($r_save) {
    my $ps = $project_saved;
    ($plot_features{emin}, $plot_features{emax}) = @$r_save;
    project_state($ps);		# don't toggle if currently saved
  };
  Echo("Done with $which.  Normal view has been returned.");
};

sub swap_panels {
  if (grep {$_ eq 'right'} ($skinny -> packInfo())) {
    $config{general}{fatside}  = 'right';
    $config{general}{listside} = 'left';
    $list -> configure(-scrollbars=>'w');
    $po_left -> packForget;
    $po -> packForget;
    $po_right -> packForget;
    $po -> pack(-side=>'left', -fill => 'x', -expand=>1);
    $po_right -> pack(-side=>'left', -anchor=>'n');
  } else {
    $config{general}{fatside}  = 'left';
    $config{general}{listside} = 'right';
    $list -> configure(-scrollbars=>'e');
    $po_left -> packForget;
    $po -> packForget;
    $po_right -> packForget;
    $po_left -> pack(-side=>'left', -anchor=>'n');
    $po -> pack(-side=>'left', -fill => 'x', -expand=>1);
  };
  $skinny -> pack(-side=>$config{general}{listside});
  $container -> pack(-side=>$config{general}{fatside});
};


sub z_popup {
  return if ($groups{$current}->{frozen});
  my ($curr, $which) = @_;
  ($menus{bkg_z}, $menus{fft_edge}) = find_edge($groups{$current}->{bkg_e0});
  $groups{$current} -> make(bkg_cl=>($which =~ /^cl/) ? 1 : 0,
			    bkg_z=>$menus{bkg_z},
			    fft_edge=>$menus{fft_edge},
			    update_fft=>($which eq 'pc'),
			   );
  $groups{$current} -> make(update_bkg=>($which eq 'cl')) unless $groups{$current}->{update_bkg};
  $groups{$current} -> plotE('emzn',$dmode,\%plot_features, \@indicator), return if ($which =~ /update/);
  my $popup = $top -> Toplevel(-class=>'horae');
  $popup -> protocol(WM_DELETE_WINDOW => sub{$popup->destroy});
  $popup -> title("Athena: Central atom species");
  $popup -> bind('<Control-d>' => sub{($which eq 'cl') and
					$groups{$current} -> plotE('emzn',$dmode,\%plot_features, \@indicator);
				      $popup->destroy;});
  $popup -> bind('<Control-q>' => sub{($which eq 'cl') and
					$groups{$current} -> plotE('emzn',$dmode,\%plot_features, \@indicator);
				      $popup->destroy;});
  my $note = ($absorption_exists) ? "\nA guess has been made, but it may not be correct" : "";
  $popup -> Label(-text=>"You have selected a feature of Athena that\nneeds to know the species\nof the central atom in this data set.".$note)
    -> pack();
  my $frame = $popup -> Frame(-borderwidth=>2, -relief=>'groove')
    -> pack(-pady=>4);
  $frame -> Label(-text=>'Choose an atom type:')
    -> pack(-side=>'left');
  my $menu = $frame -> Optionmenu(-textvariable => \$menus{bkg_z}, -width=>4)
    -> pack(-side=>'right');
  foreach my $l ([1..20], [21..40], [41..60], [61..80], [81..92]) {
    my $cas = $menu ->
      cascade(-label => get_symbol($$l[0]) . " to " . get_symbol($$l[$#{$l}]),
	      -tearoff=>0 );
    foreach my $i (@$l) {
      $cas -> command(-label => $i . ": " . get_symbol($i),
		      -command=>
		      sub{$menus{bkg_z}=get_symbol($i);
			  $groups{$current}->make(bkg_cl=>($which =~ /^cl/),
						  bkg_z=>$menus{bkg_z},
						  update_bkg=>($which =~ /^cl/),
						  update_fft=>($which eq 'pc'));
			  project_state(0);
			  ($which eq 'cl') and
			    $groups{$current} -> plotE('emzn',$dmode,\%plot_features, \@indicator);
			  $popup->destroy;
			});
    };
  };
  $frame = $popup -> Frame() -> pack(-expand=>1, -fill=>'x');
  $frame -> Button(-text=>'OK',                            # emzn ?
		   -command=>sub{($which eq 'cl') and
				   $groups{$current} -> plotE('emzn',$dmode,\%plot_features, \@indicator);
				 $popup->destroy; })
    -> pack(-expand=>1, -fill=>'x');
  $top->update;
  $popup -> raise;
  $popup -> grab;
};


## From the current value of the edge energy for the current group,
## attempt to determine what element this is.  The criterion is
## closeness to a tabulated edge energy found by brute force,
## linear searching.  That requires that Xray::Absorption is installed.
sub find_edge {
  return ('H', 'K') unless ($absorption_exists);
  my $input = $_[0];
  my ($edge, $answer, $this) = ("K", 1, 0);
  my $diff = 100000;
  foreach my $ed (qw(K L1 L2 L3)) {  # M1 M2 M3 M4 M5
  Z: foreach (1..104) {
      last Z unless (Xray::Absorption->in_resource($_));
      my $e = Xray::Absorption -> get_energy($_, $ed);
      next Z unless $e;
      $this = abs($e - $input);
      last Z if (($this > $diff) and ($e > $input));
      if ($this < $diff) {
	$diff = $this;
	$answer = $_;
	$edge = $ed;
	#print "$answer  $edge\n";
      };
    };
  };
  my $elem = get_symbol($answer);
  if ($config{general}{rel2tmk}) {
    ## give special treatment to the case of fe oxide.
    ($elem, $edge) = ("Fe", "K")  if (($elem eq "Nd") and ($edge eq "L1"));
    ## give special treatment to the case of mn oxide.
    ($elem, $edge) = ("Mn", "K")  if (($elem eq "Ce") and ($edge eq "L1"));
    ## prefer Bi K to Ir L1
    ($elem, $edge) = ("Bi", "L3") if (($elem eq "Ir") and ($edge eq "L1"));
    ## prefer Se K to Tl L2
    ($elem, $edge) = ("Se", "K")  if (($elem eq "Tl") and ($edge eq "L3"));
    ## prefer Pt L3 to W L2
    #($elem, $edge) = ("Pt", "L3") if (($elem eq "W") and ($edge eq "L2"));
    ## prefer Se K to Pb L2
    ($elem, $edge) = ("Rb", "K")  if (($elem eq "Pb") and ($edge eq "L2"));
    ## prefer Np L3 to At L1
    #($elem, $edge) = ("Np", "L3")  if (($elem eq "At") and ($edge eq "L1"));
    ## prefer Cr K to Ba L1
    ($elem, $edge) = ("Cr", "K")  if (($elem eq "Ba") and ($edge eq "L1"));
  };
  return ($elem, $edge);
};



sub set_status {
  return if (Ifeffit::Tools->vstr < 1.02007);
  my $val = $_[0] || 0;
  $groups{"Default Parameters"} -> dispose("set \&status = $val", $dmode);
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

## work around an issue in the 18 Dec 2008 release of Tk 804.028
package Patch::BR::Tk::FBox;
use Tk::FBox;
package Tk::FBox;
sub _get_select_Path {
    my($w) = @_;
    $w->_encode_filename($w->{'selectPath'});
};

1;


## END OF MISCELLANEOUS SUBSECTION
##########################################################################################
