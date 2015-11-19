# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##
###===================================================================
###  QUICK FIRST SHELL FIT SUBSYSTEM
###===================================================================


sub firstshell {

  my $do_fit = $_[0];
  ## do not do this unless there is one data set imported and no feff calculations
  my ($n,$ok,$d) = (0,0,"");
  foreach (&all_data) {
    ++$n;			# counts data objects
    ++$ok if (-e $paths{$_}->get('file')); # counts actual data files
    $d = $_;
  };

  if ($do_fit) {
    Error("No data!"), return if ($ok == 0);
    Error("Automated first shell fitting is for single data set fits only."), return if (($ok >= 2) or ($n >= 2));
    Error("You need to delete all your Feff calculations before trying an automated first shell fit."), return if data_paths($d);
  };

  my $data = $paths{$current}->data;
  my %fs_params = (coordination => '6-coordinate crystal',
		   scatterer    => 'O',
		   distance     => '2.0',
		   absorber     => $paths{$data}->get('fs_absorber') || 'Cu',
		   edge         => $paths{$data}->get('fs_edge')     || 'K',
		   do_fit       => $do_fit,
	       );
  map {$_ -> configure(-state=>'disabled')}
    ($gsd_menu, $feff_menu, $paths_menu, $data_menu, $sum_menu, $fit_menu); #, $settings_menu);
  $edit_menu -> menu -> entryconfigure(13, -state=>'disabled');
 SWITCH: {
    $opparams  -> packForget(), last SWITCH if ($current_canvas eq 'op');
    $gsd       -> packForget(), last SWITCH if ($current_canvas eq 'gsd');
    $feff      -> packForget(), last SWITCH if ($current_canvas eq 'feff');
    $path      -> packForget(), last SWITCH if ($current_canvas eq 'path');
    $logviewer -> packForget(), last SWITCH if ($current_canvas eq 'logview');
  };
  $current_canvas = 'firstshell';

  my $fs = $fat -> Frame(-relief=>'flat',
			 -borderwidth=>0,
			 -highlightcolor=>$config{colors}{background})
    -> pack(-fill=>'both', -expand=>1);

  my $frm = $fs -> Frame() -> pack(-side=>'top', -anchor=>'w', -padx=>6);
  $frm -> Label(-text=>"Automated first shell fit", @title2)
    -> pack(-side=>'left', -anchor=>'w', -padx=>4);

  $frm = $fs -> LabFrame(-label=>"Automated fit parameters",
			 -labelside=>'acrosstop',
			 -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top');

  $frm -> Label(-text       => 'Absorbing atom: ',
		-width      => 30,
		-anchor     => 'e',
		-foreground => $config{colors}{activehighlightcolor}
	       )
    -> grid(-row=>0, -column=>0, -sticky=>'e', -pady=>2);
  $frm -> Entry(-width=>5,
		-textvariable=>\$fs_params{absorber}
		)
    -> grid(-row=>0, -column=>1, -sticky=>'w', -pady=>2);

  $frm -> Label(-text       => 'Edge: ',
		-width      => 30,
		-anchor     => 'e',
		-foreground => $config{colors}{activehighlightcolor}
	       )
    -> grid(-row=>1, -column=>0, -sticky=>'e', -pady=>2);
  $frm -> Optionmenu(-options=>[qw(K L1 L2 L3)],
		     -textvariable=>\$fs_params{edge},
		     -borderwidth=>1,
		    )
    -> grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'w', -pady=>2);

  $frm -> Label(-text       => 'Scattering atom: ',
		-width      => 30,
		-anchor     => 'e',
		-foreground => $config{colors}{activehighlightcolor}
	       )
    -> grid(-row=>2, -column=>0, -sticky=>'e', -pady=>2);
  $frm -> Entry(-width=>5,
		-textvariable=>\$fs_params{scatterer}
		)
    -> grid(-row=>2, -column=>1, -sticky=>'w', -pady=>2);

  $frm -> Label(-text       => 'Distance: ',
		-width      => 30,
		-anchor     => 'e',
		-foreground => $config{colors}{activehighlightcolor}
	       )
    -> grid(-row=>3, -column=>0, -sticky=>'e', -pady=>2);
  $frm -> Entry(-width=>5,
		-textvariable=>\$fs_params{distance}
		)
    -> grid(-row=>3, -column=>1, -sticky=>'w', -pady=>2);
  $frm -> Label(-text       => "A", #"Å",
		-anchor     => 'w',
		-foreground => $config{colors}{activehighlightcolor}
	       )
    -> grid(-row=>3, -column=>2, -sticky=>'w', -pady=>2);

  $frm -> Label(-text       => 'Coordination: ',
		-width      => 30,
		-anchor     => 'e',
		-foreground => $config{colors}{activehighlightcolor}
	       )
    -> grid(-row=>4, -column=>0, -sticky=>'e', -pady=>2, -padx=>4);
  $frm -> Optionmenu(-options=>['4-coordinate crystal', '6-coordinate crystal',
				'square planar', 'octahedral', 'tetrahedral'],
		     -textvariable=>\$fs_params{coordination},
		     -borderwidth=>1,
		    )
    -> grid(-row=>4, -column=>1, -columnspan=>2, -sticky=>'ew', -pady=>2);

  $fs -> Button(-text=>'Do it!', @button3_list,
		-command => sub{firstshell_fit($fs, \%fs_params)})
    -> pack(-side=>'top', -fill=>'x', -pady=>2, -padx=>2);

  $fs -> Button(-text=>'Cancel and return to the main window', @button3_list,
		 -command=>sub{$fs->packForget;
			       $current_canvas = "";
			       $edit_menu -> menu -> entryconfigure(13, -state=>'normal');
			       &display_properties;
			       Echo("Restored normal view");
			     })
    -> pack(-side=>'top', -fill=>'x', -pady=>8, -padx=>2);

  $fs -> Button(-text    => 'Document: Automated first shell fit',  @button2_list,
		-command => sub{pod_display("artemis_afs.pod")} )
    -> pack(-side=>'bottom', -fill=>'x', -pady=>2);

};

# 1. generate feff.inp from params
# 2. insert feff.inp into feff.inp display
# 3. run feff
# 4. run fit

sub firstshell_fit {
  my ($canvas, $rparams) = @_;

  Echo("Running automated first shell fit ...");

  unless (lc($$rparams{absorber})  =~ /^$Ifeffit::Files::elem_regex$/) {
    Error("The absorber \"$$rparams{absorber}\" is not a valid element symbol.  Automated fit aborted.");
    return;
  };
  unless (lc($$rparams{scatterer}) =~ /^$Ifeffit::Files::elem_regex$/) {
    Error("The scatterer \"$$rparams{scatterer}\" is not a valid element symbol.  Automated fit aborted.");
    return;
  };
  if ($$rparams{distance} < 0) {
    Error("The distance cannot be negative.  Automated fit aborted.");
    return;
  };
  if ($$rparams{distance} < 1.2) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "$$rparams{distance} Angstroms is an unusually small value for distance.  Are you sure you want to continue?",
		     -title          => 'Athena: Reading data',
		     -buttons        => [qw/OK Cancel/],
		     -default_button => 'Cancel',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    Echo("Automated first shell theory aborted."), return if ($response eq 'Cancel');
  };
  if ($$rparams{distance} > 2.9) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "$$rparams{distance} Angstroms is an unusually large value for distance.  Are you sure you want to continue?",
		     -title          => 'Athena: Reading data',
		     -buttons        => [qw/OK Cancel/],
		     -default_button => 'Cancel',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    Echo("Automated first shell theory aborted."), return if ($response eq 'Cancel');
  };

  $canvas->packForget;
  $current_canvas = "";
  $edit_menu -> menu -> entryconfigure(13, -state=>'normal');
  &display_properties;
  Echo("Restored normal view");
  project_state(0);

  $top -> Busy;

  ## override some config params
  my @save = ($config{general}{fit_query},
	      $config{autoparams}{third},
	      $config{autoparams}{third_type},
	      $config{autoparams}{fourth},
	      $config{autoparams}{fourth_type});
  ($config{general}{fit_query},
   $config{autoparams}{third},
   $config{autoparams}{third_type},
   $config{autoparams}{fourth},
   $config{autoparams}{fourth_type}) = (0, 'c3', 'set', 'c4', 'set');

  ## make the feff.inp file from the firstshell params
  if ($$rparams{coordination} =~ /^[46]-coordinate/) {
    make_feffinp_crystal($rparams);
  } else {
    make_feffinp_molecule($rparams);
  };

  ## run the feff calc and import only the first path
  run_feff($current, 'Just the first');

  ## set the degeneracy to 1 so that amp is "directly" interpretable as the
  ## coordination
  set_degeneracy(1);

  ## run the fit
  generate_script(1) if $$rparams{do_fit};

  ## restore the config params
  ($config{general}{fit_query},
   $config{autoparams}{third},
   $config{autoparams}{third_type},
   $config{autoparams}{fourth},
   $config{autoparams}{fourth_type}) = @save;

  my $data = $paths{$current} -> data;
  $paths{$data} -> make(fs_absorber	 => $$rparams{absorber},
			fs_edge		 => $$rparams{edge},
			#fs_scatterer	 => $$rparams{scatterer},
			#fs_distance	 => $$rparams{distance},
			#fs_coordination => $$rparams{coordination},
		       );
  $top -> Unbusy;
  Echo("Running automated first shell fit ... done!");

};

sub make_feffinp_crystal {
  my $rparams = $_[0];

  ## 6 coordinate: space=f m -3 m, a=2*R  abs=000  scat=1/2 1/2 1/2
  ## 4 coordinate: space=F -4 3 m, a=4*R/sqrt(3)   abs=000  scat=1/4 1/4 1/4
  my ($a, $space, $x);
 SWITCH: {
    ($a, $space, $x) = (2*$$rparams{distance},         'F m -3 m', 0.5),  last SWITCH if ($$rparams{coordination} =~ /^6/);
    ($a, $space, $x) = (4*$$rparams{distance}/sqrt(3), 'F -4 3 m', 0.25), last SWITCH if ($$rparams{coordination} =~ /^4/);
  };

  my $keywords = Xray::Atoms -> new(die=>1);
  $keywords -> make(identity => "Artemis $VERSION",
		    quiet    => 1,
		    program  => 'Artemis',
		    core     => $$rparams{absorber},
		    edge     => $$rparams{edge},
		    space    => $space,
		    a	     => $a,
		    rmax     => 1.1*$a,
		   );
  $keywords -> make(title=>"Quick first shell theory: $$rparams{absorber}-$$rparams{scatterer}");
  $keywords -> make(title=>"$$rparams{coordination}, $$rparams{distance} A, $$rparams{edge} edge");
  my $cell = Xray::Xtal::Cell -> new();
  $cell -> make( Space_group=>$space, A=>$a, );

  my @sites;
  $sites[0] = Xray::Xtal::Site -> new();
  $sites[0] -> make( X=>0.0, Y=>0.0, Z=>0.0, Element=>$$rparams{absorber} );
  $sites[1] = Xray::Xtal::Site -> new();
  $sites[1] -> make( X=>$x,  Y=>$x,  Z=>$x,  Element=>$$rparams{scatterer} );
  push @{$keywords->{sites}}, [$$rparams{absorber},  0,  0,  0,  $$rparams{absorber},  1];
  push @{$keywords->{sites}}, [$$rparams{scatterer}, $x, $x, $x, $$rparams{scatterer}, 1];

  $cell -> populate(\@sites);

  my $trouble = $keywords -> verify_keywords($cell, \@sites, 1);
  if ($trouble) {
    $top -> Unbusy();
    Error("Trouble found among the parameters.  Atoms aborted.");
    return;
  };

  my (@neutral, @cluster);
  build_cluster($cell, $keywords, \@cluster, \@neutral);
  my $text;
  my ($default_name, $is_feff) =
    &parse_atp("feff", $cell, $keywords, \@cluster, \@neutral, \$text);
  Echo("Made ATP output (feff6) for automated fit");

  my $to  = File::Spec->catfile($project_folder, "tmp", "feff.inp");
  open F, ">".$to;
  print F $text;
  close F;

  read_feff($to);
  unlink $to;

  my $newname = "$$rparams{absorber} - $$rparams{scatterer}";

  $paths{$current} -> make(lab=>$newname);
  $list -> itemConfigure($current, 0, -text=>$newname);

};

sub make_feffinp_molecule {
  my $rparams = $_[0];

  my $ihole = 1;
 SWITCH: {
    $ihole = 2, last SWITCH if (lc($$rparams{edge}) eq 'l1');
    $ihole = 3, last SWITCH if (lc($$rparams{edge}) eq 'l2');
    $ihole = 4, last SWITCH if (lc($$rparams{edge}) eq 'l3');
  };
  my $x = 0;
 GEOM: {
    $x = $$rparams{distance}, last GEOM if ($$rparams{coordination} eq 'square planar');
    $x = $$rparams{distance}, last GEOM if ($$rparams{coordination} eq 'octahedral');
    $x = sprintf("%.5f", $$rparams{distance}/sqrt(3)), last GEOM if ($$rparams{coordination} eq 'tetrahedral');
  };
  my $rmax = 2.1 * $$rparams{distance};

  my $text = "\n TITLE Quick first shell theory: $$rparams{absorber}-$$rparams{scatterer}\n";
  $text .= " TITLE $$rparams{coordination}, $$rparams{distance} A, $$rparams{edge} edge\n";
  $text .= " HOLE  $ihole   1.0\n\n";

  $text .= " *         mphase,mpath,mfeff,mchi\n";
  $text .= " CONTROL   1      1     1     1\n";
  $text .= " PRINT     1      0     0     0\n\n";

  $text .= " RMAX      $rmax\n\n";

  $text .= " POTENTIALS\n";
  $text .= " *    ipot   Z  element\n";
  my $z = get_Z($$rparams{absorber});
  $text .= "       0     $z   $$rparams{absorber}\n";
  $z    = get_Z($$rparams{scatterer});
  $text .= "       1     $z   $$rparams{scatterer}\n\n";

  $text .= " ATOMS\n";
  $text .= " *   x          y          z           ipot\n";
  $text .= sprintf("   %8.5f   %8.5f   %8.5f       0\n",  0, 0, 0);
  if ($$rparams{coordination} eq 'square planar') {
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  $x, 0,  0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n", -$x, 0,  0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  0,  $x, 0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  0, -$x, 0);
  } elsif ($$rparams{coordination} eq 'octahedral') {
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  $x, 0,  0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n", -$x, 0,  0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  0,  $x, 0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  0, -$x, 0);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  0,  0,  $x);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  0,  0, -$x);
  } elsif ($$rparams{coordination} eq 'tetrahedral') {
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  $x,  $x,  $x);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n", -$x, -$x,  $x);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n", -$x,  $x, -$x);
    $text .= sprintf("   %8.5f   %8.5f   %8.5f       1\n",  $x, -$x, -$x);
  };

  my $to  = File::Spec->catfile($project_folder, "tmp", "feff.inp");
  open F, ">".$to;
  print F $text;
  close F;

  read_feff($to);
  unlink $to;

  my $newname = "$$rparams{absorber} - $$rparams{scatterer}";

  $paths{$current} -> make(lab=>$newname);
  $list -> itemConfigure($current, 0, -text=>$newname);
};

## END OF THE QUICK FIRST SHELL FIT SUBSYSTEM

