## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  data deglitching

sub choose_a_point {
  my $group = $_[1];
  my $space = $_[2];
  Error("Point selection aborted: " . $groups{$group}->{label} . " is not an xmu group."),
	  return unless ($groups{$current}->{is_xmu});
  Echonow("Select a point by clicking on the plot");
  my ($yoffset, $kw, $plot_scale) = ($groups{$group}->{plot_yoffset},
				     $groups{$group}->{fft_kw},
				     $groups{$group}->{plot_scale});
  my (@x, @y);
  if ($space eq 'emg') {
    $plot_features{linestyle} = "linespoints3";
    $groups{$group} -> plotE('em',$dmode,\%plot_features, \@indicator);
    $plot_features{linestyle} = "lines";
    @x = Ifeffit::get_array($group.".energy");
    @y = Ifeffit::get_array($group.".xmu");
    $groups{$group} -> dispose("set(___y = ceil($group.xmu), ___z = floor($group.xmu))");
    $last_plot = 'e';
  } else {
    &plot_chie($group,1);
    @x = Ifeffit::get_array($group.".energy");
    @y = Ifeffit::get_array($group.".chie");
    $groups{$group} -> dispose("set(___y = ceil($group.chie), ___z = floor($group.chie))");
    $last_plot = 'e';
  };
  my $maxy = Ifeffit::get_scalar('___y');
  my $miny = Ifeffit::get_scalar('___z');
  $groups{$group} -> dispose('cursor(crosshair=true)', 1);
  my ($xx, $yy) = (Ifeffit::get_scalar('cursor_x'), Ifeffit::get_scalar('cursor_y'));
  my ($dist, $ii) = (1e10, -1);
  foreach my $i (0 .. $#x) {	# need to scale these appropriately
    #my $px = ($x[$i] - $x[0])/($x[$#x] - $x[0]);
    #my $py = ($y[$i] - $y[0])/($y[$#y] - $y[0]);
    #my $xn = ($xx    - $x[0])/($x[$#x] - $x[0]);
    #my $yn = ($yy    - $y[0])/($y[$#y] - $y[0]);
    #my $d = sqrt(($px - $xn)**2 + ($py - $yn)**2);

    #print join(" ", $px, $py, $xn, $yn, $d), $/;

    my $px = ($x[$i] - $xx)/($x[-1] - $x[0]);
    ##my $py = ($y[$i] - $yy)/($y[$#y] - $y[0]);
    my $py = ($y[$i] - $yy)/($maxy - $miny);
    my $d  = sqrt($px**2 + $py**2);
    #print join(" ", $px, $py, $d), $/;

    ($d < $dist) and ($dist, $ii) = ($d, $i);
  };
  if ($space eq 'emg') {
    $groups{$group} -> dispose("pmarker $group.energy, $group.xmu, $x[$ii], " .
			       "$plot_features{marker}, $plot_features{markercolor}, $yoffset", $dmode);
  } else {
    $groups{$group} -> dispose("pmarker $group.energy, $group.chie, $x[$ii], " .
			       "$plot_features{marker}, $plot_features{markercolor}, $yoffset", $dmode);
  };
  #$_[0]->raise;
  Echo("You selected (" . sprintf("%.3f", $x[$ii]) . ", " . sprintf("%.5f", $y[$ii]) . ").");

  return $ii;
};


sub deglitch_a_point {
  my $ii = $_[0];
  my $group = $_[1];
  my $space = $_[2];
  Echo("Point -1?"), return if ($ii < 0);
  my @x = Ifeffit::get_array($group.".energy");
  my @y = Ifeffit::get_array($group.".xmu");
  my $str = "Removed point $ii at x=$x[$ii], y=$y[$ii]";
  splice(@x, $ii, 1);
  splice(@y, $ii, 1);
  Ifeffit::put_array($group.".energy", \@x);
  Ifeffit::put_array($group.".xmu", \@y);
  $groups{$group} -> make(update_bkg=>1);
  if ($space eq 'emg') {
    $groups{$group} -> plotE($space,$dmode,\%plot_features, \@indicator);
    $last_plot = 'e';
  } else {
    &plot_chie($group,0);
    $last_plot = 'e';
  };
  project_state(0);
  &refresh_properties;
  Echo($str);
};


sub deglitch_palette {
  Echo("You must select a data group to deglitch"), return
    if ($current eq "Default Parameters");
  Echo("No data!"), return unless $current;

  my %degl_params;
  my @keys = ();
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
  };
  Echo("You need at least one group to deglitch"), return unless (@keys);
  $degl_params{standard} = ($groups{$current}->{is_xmu}) ? $current : $keys[0];
  $groups{$degl_params{standard}}->dispatch_bkg if $groups{$degl_params{standard}}->{update_bkg};
  $degl_params{standard_label} = $groups{$degl_params{standard}}->{label};
  $degl_params{deg_emin} = $groups{$degl_params{standard}}->{bkg_nor1} +
    $groups{$degl_params{standard}}->{bkg_e0};
  $groups{$degl_params{standard}} ->
    dispose("set ___x = ceil($degl_params{standard}.energy)\n", 1);
  my $maxE = Ifeffit::get_scalar("___x");
  $degl_params{deg_emax} = $config{deglitch}{emax} ? $maxE+$config{deglitch}{emax} : $maxE*1.1;
  $degl_params{deg_emin} = sprintf("%.3f",$degl_params{deg_emin});
  $degl_params{deg_emax} = sprintf("%.3f",$degl_params{deg_emax});
  $degl_params{deg_tol} = sprintf("%.4f", $groups{$degl_params{standard}}->{bkg_step} * $config{deglitch}{margin});
  $degl_params{space} = 'emg';
  $degl_params{space_label} = 'mu(E)';
  my @save = ($plot_features{emin}, $plot_features{emax});

  set_deglitch_params(\%degl_params);

  my $point_choice = -1;

  $fat_showing = 'deglitch';
  $hash_pointer = \%degl_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $degl = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$degl -> packPropagate(0);
  $which_showing = $degl;

  $degl -> Label(-text=>"Deglitch data",
		 -font=>$config{fonts}{large},
		 -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## which group ...?
  my $fr = $degl -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -pady=>8, -fill=>'x');
  my $frame = $fr -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-pady=>1, -fill=>'x');
  $frame -> Label(-text=>"Group: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> pack(-side=>'left', -anchor=>'e', -fill=>'x');
  $widget{deg_group} = $frame -> Label(-text=>$groups{$current}->{label},
				       -foreground=>$config{colors}{button})
    -> pack(-side=>'left', -anchor=>'w', -fill=>'x');


  ## this frame has all the active elements
  $frame = $fr -> LabFrame(-label=>'Deglitch a single point',
			   -foreground=>$config{colors}{activehighlightcolor},
			   -labelside=>'acrosstop')
    -> pack(-pady=>3, -padx=>3, -ipady=>3, -ipadx=>3, -fill=>'x');

  my $upper = $frame -> Frame ()
    -> pack(-side=>'top');
  $upper -> Label(-text=>'Plot as:',
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> pack(-side=>'left');
  my $menu = $upper -> Optionmenu(-textvariable => \$degl_params{space_label},
				  -borderwidth=>1,
				  -width=>12, -justify=>'right')
    -> pack(-side=>'left');
  foreach my $sp ('mu(E)', 'chi(E)') {
    my $how = 'emg';
    ($how = 'k' . $plot_features{k_w} . 'e') if ($sp eq 'chi(E)');
    $menu -> command(-label => $sp,
		     -command=>sub{$degl_params{space} = $how;
				   $degl_params{space_label} = $sp;
				   set_deglitch_params(\%degl_params);
				   if ($degl_params{space} eq 'emg') {
				     $plot_features{emin} = $save[0];
				     $groups{$degl_params{standard}} -> plotE($degl_params{space},$dmode,\%plot_features, \@indicator);
				     $last_plot = 'e';
				     map {$widget{"deg_$_"}->configure(-state=>'normal')} (qw(tol emin emax replot remove));
				     map {$grab{"deg_$_"}  ->configure(-state=>'normal')} (qw(emin emax));
				   } else {
				     $plot_features{emin} = $config{deglitch}{chie_emin};
				     &plot_chie($degl_params{standard},0);
				     #$groups{$degl_params{standard}} -> plotk($degl_params{space},$dmode,\%plot_features, \@indicator);
				     $last_plot = 'e';
				     map {$widget{"deg_$_"}->configure(-state=>'disabled')} (qw(tol emin emax replot remove));
				     map {$grab{"deg_$_"}  ->configure(-state=>'disabled')} (qw(emin emax));
				   };
				   $top -> update;});
  };


  my $fr1 = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-expand=>1, -fill=>'x');
  my $help = "Choose a point with the cursor, then press the \"Remove\" button to delete it";
  $fr1 -> Button(-text=>"Help", @button_list,
		   -width=>1,
		   -command=>[\&Echo, $help])
    -> pack(-side=>'right', -expand=>1, -fill=>'x');
  $widget{deg_sreplot} = $fr1 -> Button(-text=>"Replot", @button_list,
					  -width=>1,
					  -command=>sub{
					    if ($degl_params{space} eq 'emg') {
					      $groups{$current} -> plotE('emg',$dmode,\%plot_features, \@indicator);
					    } else {
					      &plot_chie($current,0);
					    };
					  })
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $widget{deg_point} = $fr1 -> Button(-text=>"Remove point", @button_list,
				      -width=>1,
				      -command=>sub{Echo("Deglitching aborted: \"$groups{$current}->{label}\" is frozen"), return
						      if $groups{$current}->{frozen};
						    &deglitch_a_point($point_choice, $degl_params{standard},  $degl_params{space});
						    $widget{deg_point}->configure(-state=>'disabled');
						    #$degl->raise;
						    $top -> update;
						  },
				      -state=>'disabled')
    -> pack(-side=>'right', -expand=>1, -fill=>'x');
  $widget{deg_single} = $fr1 -> Button(-text=>"Choose a point", @button_list,
					 -width=>1,
					 -command=>sub{$point_choice = &choose_a_point($degl, $degl_params{standard}, $degl_params{space});
						       $widget{deg_point}->configure(-state=>'normal')})
    -> pack(-side=>'left', -expand=>1, -fill=>'x');

  $frame = $fr -> LabFrame(-label=>'Deglitch many points',
			   -foreground=>$config{colors}{activehighlightcolor},
			   -labelside=>'acrosstop')
    -> pack(-pady=>3, -padx=>3, -ipady=>3, -ipadx=>3, -fill=>'x');
  my $fr2 = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'bottom', -fill=>'x', -expand=>1);
  #$fr2 -> Label(-width=>1) -> pack(-side=>'left', -fill=>'x', -expand=>1);
  $fr2 -> Label(-text=>'Tolerance:',
		-foreground=>$config{colors}{activehighlightcolor},
	       )
    -> pack(-side=>'left');
  $widget{deg_tol} = $fr2 -> Entry(-textvariable=>\$degl_params{deg_tol}, -width=>7)
    -> pack(-side=>'left');
  $fr2 -> Label(-width=>1) -> pack(-side=>'left', -fill=>'x', -expand=>1);
  $fr2 -> Label(-text=>'Emin:',
		-foreground=>$config{colors}{activehighlightcolor},
	       )
    -> pack(-side=>'left');
  $widget{deg_emin} = $fr2 -> Entry(-textvariable=>\$degl_params{deg_emin},
				    -validate=>'key',
				    -validatecommand=>[\&set_variable, 'deg_emin'],
				    -width=>9)
    -> pack(-side=>'left');
  $grab{deg_emin} = $fr2 -> Button(@pluck_button, @pluck,
				   -command=>sub{Echo("\"$groups{$current}->{label}\" is frozen"), return
						   if $groups{$current}->{frozen};
						 &pluck('deg_emin');
						 $groups{$degl_params{standard}} -> plotE('emg',$dmode,\%plot_features, \@indicator);
						 $last_plot='e';
					       })
    -> pack(-side=>'left');
  $fr2 -> Label(-width=>1) -> pack(-side=>'left', -fill=>'x', -expand=>1);
  $fr2 -> Label(-text=>'Emax:',
		-foreground=>$config{colors}{activehighlightcolor},
	       )
    -> pack(-side=>'left');
  $widget{deg_emax} = $fr2 -> Entry(-textvariable=>\$degl_params{deg_emax},
				    -validate=>'key',
				    -validatecommand=>[\&set_variable, 'deg_emax'],
				    -width=>9)
    -> pack(-side=>'left');
  $grab{deg_emax} = $fr2 -> Button(@pluck_button, @pluck,
				  -command=>sub{Echo("\"$groups{$current}->{label}\" is frozen"), return
						  if $groups{$current}->{frozen};
						&pluck('deg_emax');
						$groups{$degl_params{standard}} -> plotE('emg',$dmode,\%plot_features, \@indicator);
						$last_plot='e';
					      })
    -> pack(-side=>'left');
  #$fr2 -> Label(-width=>1) -> pack(-side=>'left', -fill=>'x', -expand=>1);

  $fr2 = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-expand=>1, -fill=>'x');
  $widget{deg_replot} =
    $fr2 -> Button(-text=>'Replot', @button_list,
		   -width=>1,
		   -command=> sub{set_deglitch_params(\%degl_params);
				  $groups{$degl_params{standard}} -> plotE('emg',$dmode,\%plot_features, \@indicator);
				  $last_plot = 'e'; $top -> update;})
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $widget{deg_remove} =
    $fr2 -> Button(-text=>'Remove glitches', @button_list,
		   -width=>1,
		   -command=>sub{Echo("Deglitching aborted: \"$groups{$current}->{label}\" is frozen"), return
				   if $groups{$current}->{frozen};
				 &remove_glitches($degl_params{standard});
				 $top -> update;
			       })
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $fr2 -> Button(-text=>"Help", @button_list,
		 -width=>1,
		 -command=>[\&Echo, "Remove all points which fall outside the tolerance margins defined by the parameters below"])
    -> pack(-side=>'left', -expand=>1, -fill=>'x');

  ## help button
  $degl -> Button(-text=>'Document section: deglitching data', @button_list,
		  -command=>sub{pod_display("process::deg.pod")})
    -> pack(-fill=>'x', -pady=>4);

  $degl -> Button(-text=>'Return to the main window',  @button_list,
		  -background=>$config{colors}{background2},
		  -activebackground=>$config{colors}{activebackground2},
		  -command=>sub{&reset_window($degl, "deglitching", \@save)})
    -> pack(-fill=>'x');
  $degl -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-expand=>1, -fill=>'both');

  ($groups{$degl_params{standard}}->{update_bkg}) and $groups{$degl_params{standard}}->dispatch_bkg($dmode);
  $groups{$degl_params{standard}} -> plotE('emg',$dmode,\%plot_features, \@indicator);
  $last_plot = 'e';
  $plotsel -> raise('e');
  $top -> update;
};



sub set_deglitch_params {
  my $hash_pointer = $_[0];
  my $standard = $$hash_pointer{standard};
  ## set deg_emin
  #my $emin = $widget{deg_emin} -> get;
  $groups{$standard} -> make(deg_emin=>$$hash_pointer{deg_emin} ||
			     $groups{$standard}->{bkg_nor1} + $groups{$standard}->{bkg_e0});
  ## set deg_emax
  #my $emax = $widget{deg_emax} -> get;
  $groups{$standard}->dispose("set ___x = ceil($standard.energy)\n", 1);
  my $maxE = Ifeffit::get_scalar("___x") * 1.1;
  $groups{$standard} -> make(deg_emax=>$$hash_pointer{deg_emax} || $maxE);
  ## set deg_tol
  #my $tol = $widget{deg_tol} -> get;
  $groups{$standard} -> make(deg_tol=>$$hash_pointer{deg_tol} ||
			     sprintf("%.4f", $groups{$standard}->{bkg_step} * $config{deglitch}{margin}));
};


sub remove_glitches {
  my $group  = $_[0];
  Error("Deglitching aborted: " . $groups{$group}->{label} . " is not an xmu group."),
	  return unless ($groups{$current}->{is_xmu});
  my $noplot = $_[1];
  my @e  = Ifeffit::get_array("$group.energy");
  my @ee = Ifeffit::get_array("$group.energy");
  my @x  = Ifeffit::get_array("$group.xmu");
  my $tol = $groups{$group}->{deg_tol};
  my $emin = $groups{$group}->{deg_emin};
  my $emax = $groups{$group}->{deg_emax};
  my @p;
  if ($emin > $groups{$group}->{bkg_e0}) {
    @p  = Ifeffit::get_array("$group.postline");
  } else {
    @p  = Ifeffit::get_array("$group.preline");
  };
  my ($i, $j) = (-1, 0);
  foreach (@ee) {
    ++$i;
    next if ($_ < $emin);
    next if ($_ > $emax);
    my ($up, $dn) = ($p[$i] + $tol, $p[$i] - $tol); ## bug here
    next if (($x[$i-$j] > $dn) and ($x[$i-$j] < $up));
    splice(@e, $i-$j, 1);
    splice(@x, $i-$j, 1);
    ++$j;
  };
  Ifeffit::put_array("$group.energy", \@e);
  Ifeffit::put_array("$group.xmu", \@x);
  $groups{$group}->make(update_bkg=>1);
  unless ($noplot) {
    ($groups{$group}->plotE('emtg',$dmode,\%plot_features, \@indicator));
    $last_plot='e';
    &refresh_properties;
  };
  project_state(0);
};


sub plot_chie {
  my $group = $_[0];
  my $how = $_[1];
  $groups{$group}->dispatch_bkg if $groups{$group}->{update_bkg};
  my $e0    = $groups{$group}->{bkg_e0};
  my $label = $groups{$group}->{label};
  my $emin  = $e0 + $plot_features{emin};
  my $emax  = $e0 + $plot_features{emax};
  my $style = ($how) ? 'linespoints3' : 'lines';
  my $command .= "set $group.chie = ($group.xmu-$group.bkg)*($group.energy-$e0)\n";
  $command    .= "newplot($group.energy, $group.chie,\n        ";
  $command    .= "xmin=$emin, xmax=$emax, xlabel=\"E (eV)\",\n        ";
  $command    .= "title=\"$label\",\n        ";
  $command    .= "ylabel=\"\\gx(E)\", fg=$config{plot}{fg}, bg=$config{plot}{bg},\n        ";
  $command    .= "style=$style, color=\"$config{plot}{c0}\", key=\"\\gm\")";
  $groups{$group} -> dispose($command, $dmode);

  if ($indicator[0]) {
    foreach my $i (@indicator) {
      next if ($i =~ /^[01]$/);
      next if (lc($i->[1]) =~ /[r\s]/);
      my $suff = "chie";
      my $val = $i->[2];
      ($val = $groups{$group}->k2e($val)+$groups{$group}->{bkg_e0})
	if (lc($i->[1]) =~ /[kq]/);
      next if ($val < 0);
      my $cmd = "set(___x = ceil($group.$suff+$groups{$group}->{plot_yoffset}),";
      $cmd   .= "    ___n = floor($group.$suff+$groups{$group}->{plot_yoffset}))";
      ifeffit($cmd);
      my $ymax = Ifeffit::get_scalar("___x") * 1.05;
      my $ymin = Ifeffit::get_scalar("___n");
      $groups{$group}->plot_vertical_line($val, $ymin, $ymax, $dmode, "", 0, 0, 1)
    };
  };


};



## END OF DATA DEGLITCHING SUBSECTION
##########################################################################################
