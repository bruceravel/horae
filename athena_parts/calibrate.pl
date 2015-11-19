## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006, 2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  data calibration.


sub calibrate {
  Echo("No data!"), return unless $current;
  my $space = $_[0];

  ##Echo("You cannot align to the Default Parameters"), return
  Echo("No data!"), return if ($current eq "Default Parameters");

  my @keys = ();
  #sort {($list->bbox($groups{$a}->{text}))[1] <=>
  #		     ($list->bbox($groups{$b}->{text}))[1]} (keys (%marked));
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
  };

  ($groups{$current}->{bkg_z}, $groups{$current}->{fft_edge})
    = find_edge($groups{$current}->{bkg_e0});
  my %cal_params = (cal_to => Xray::Absorption->get_energy($groups{$current}->{bkg_z},
							   $groups{$current}->{fft_edge}),
		    e0 => $groups{$current}->{bkg_e0},
		    display => "deriv(E)",
		    iterations => 0,
		   );
 SWITCH: {
    $cal_params{display} = 'mu(E)',        last SWITCH if ($config{calibrate}{calibrate_default} eq 'x');
    $cal_params{display} = 'norm(E)',      last SWITCH if ($config{calibrate}{calibrate_default} eq 'n');
    $cal_params{display} = 'deriv(E)',     last SWITCH if ($config{calibrate}{calibrate_default} eq 'd');
    $cal_params{display} = 'second deriv', last SWITCH if ($config{calibrate}{calibrate_default} eq '2');
  };

  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = $config{calibrate}{emin};
  $plot_features{emax} = $config{calibrate}{emax};
  project_state($ps);		# don't toggle if currently saved

  $fat_showing = 'calibrate';
  $hash_pointer = \%cal_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $cal = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$cal -> packPropagate(0);
  $which_showing = $cal;


  $cal -> Label(-text=>"Data calibration",
		-font=>$config{fonts}{large},
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## select the data set to calibrate
  my $frame = $cal -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -padx=>8);
  $frame -> Label(-text=>"Group: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widget{cal_group} = $frame -> Label(-text=>$groups{$current}->{label},
				       -foreground=>$config{colors}{button})
    -> grid(-row=>0, -column=>1, -sticky=>'w', -padx=>3);


  $cal -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');
  $cal -> Button(-text=>'Return to the main window',  @button_list,
		 -background=>$config{colors}{background2},
		 -activebackground=>$config{colors}{activebackground2},
		 -command=>sub{set_properties(1, $current, 0);
			       reset_window($cal, "calibration", \@save);
			     })
    -> pack(-side=>'bottom', -fill=>'x');

  ## help button
  $cal -> Button(-text=>'Document section: energy calibration', @button_list,
		   -command=>sub{pod_display("process::cal.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  # pick display mode (mu, norm, deriv)
  #$frame = $cal -> Frame(-borderwidth=>2, -relief=>'sunken')
  #  -> pack(-fill=>'x');
  $frame -> Label(-text=>"Display: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $widget{display} = $frame -> Optionmenu(-textvariable => \$cal_params{display},
					  -borderwidth=>1,
					  -options => [qw(mu(E) norm(E) deriv(E)), 'second deriv'],
					  -command => sub{
					    $widget{calib_zero} -> configure(-state=>($cal_params{display} eq 'second deriv') ? 'normal' : 'disabled');
					    my $str = 'em';
					    ($str = 'emn') if ($cal_params{display} eq 'norm(E)');
					    ($str = 'emd') if ($cal_params{display} eq 'deriv(E)');
					    ($str = 'em2') if ($cal_params{display} eq 'second deriv');
					    $str .= 's' x $cal_params{iterations};
					    $cal_params{str} = $str;
					    $plot_features{suppress_markers} = 1;
					    $groups{$current}->plotE($str, $dmode, \%plot_features, \@indicator);
					    $plot_features{suppress_markers} = 0;
					    &cal_marker($current, $cal_params{e0}, $cal_params{str});
					  } )
    -> grid(-row=>1, -column=>1, -sticky =>'w', -padx=>3);

  $frame -> Label(-text=>'Smoothing: ',
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $frame -> NumEntry(-width	   => 4,
		     -orient	   => 'horizontal',
		     -foreground   => $config{colors}{foreground},
		     -textvariable => \$cal_params{iterations},
		     -minvalue	   => 0,
		     -browsecmd	   => sub{ $widget{calib_replot}->invoke },
		     -command	   => sub{ $widget{calib_replot}->invoke },
		    )
    -> grid(-row=>2, -column=>1, -sticky =>'w', -padx=>3);
  $frame -> Label(-text=>'Reference at: ',
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $frame -> Entry(-textvariable=> \$cal_params{e0}, -width=>12)
    -> grid(-row=>3, -column=>1, -sticky =>'w', -padx=>3);
  $frame -> Label(-text=>'Calibrate to: ',
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $frame -> Entry(-textvariable=> \$cal_params{cal_to}, -width=>12)
    -> grid(-row=>4, -column=>1, -sticky =>'w', -padx=>3);

  ## pluck button
  $widget{calib_select} =
    $frame -> Button(-text=>'Select a point', @button_list,
		     -command=>sub{
		       Error("Calibration selection aborted: " .
			     $groups{$current}->{label} . " is not an xmu group."),
			       return unless ($groups{$current}->{is_xmu});
		       $cal_params{e0} = &cal_pluck($current, $cal_params{str});
		       my $str = 'em';
		       ($str = 'emn') if ($cal_params{display} eq 'norm(E)');
		       ($str = 'emd') if ($cal_params{display} eq 'deriv(E)');
		       ($str = 'em2') if ($cal_params{display} eq 'second deriv');
		       $str .= 's' x $cal_params{iterations};
		       $cal_params{str} = $str;
		       $plot_features{suppress_markers} = 1;
		       $groups{$current}->plotE($str, $dmode, \%plot_features, \@indicator);
		       $plot_features{suppress_markers} = 0;
		       &cal_marker($current, $cal_params{e0}, $cal_params{str});
		       Echo("You chose $cal_params{e0}");
		     })
    -> grid(-row=>5, -column=>0, -columnspan=>2, -sticky=>'we');

  $widget{calib_zero} =
    $frame -> Button(-text=>'Find zero-crossing', @button_list,
		     -state=>'disabled',
		     -command=>sub{cal_zero($current, \%cal_params)},
		    )
    -> grid(-row=>6, -column=>0, -columnspan=>2, -sticky=>'we');

  ## replot button
  $widget{calib_replot} =
    $frame -> Button(-text=>'Replot', @button_list,
		     -command=>sub{
		       Error("Replot aborted: " .
			     $groups{$current}->{label} . " is not an xmu group."),
			       return unless ($groups{$current}->{is_xmu});
		       my $str = 'em';
		       ($str = 'emn') if ($cal_params{display} eq 'norm(E)');
		       ($str = 'emd') if ($cal_params{display} eq 'deriv(E)');
		       ($str = 'em2') if ($cal_params{display} eq 'second deriv');
		       $str .= 's' x $cal_params{iterations};
		       ##print $str, $/;
		       $cal_params{str} = $str;
		       $plot_features{suppress_markers} = 1;
		       $groups{$current}->plotE($str, $dmode, \%plot_features, \@indicator);
		       $plot_features{suppress_markers} = 0;
		       &cal_marker($current, $cal_params{e0}, $cal_params{str});
		       Echo("Replotted $groups{$current}->{label}");
		     })
      -> grid(-row=>7, -column=>0, -columnspan=>2, -sticky=>'we');

  ## calibrate button
  $widget{calib_calibrate} =
    $frame -> Button(-text=>'Calibrate', @button_list,
		     -command=>sub{
		       Echo("Calibration aborted: \"$groups{$current}->{label}\" is frozen"), return
			 if $groups{$current}->{frozen};
		       Error("Calibration aborted: " .
			     $groups{$current}->{label} . " is not an xmu group."),
			       return unless ($groups{$current}->{is_xmu});
		       my $delta = $cal_params{cal_to} - $cal_params{e0};
		       $cal_params{e0} = $cal_params{cal_to};
		       $groups{$current}->{bkg_eshift} += $delta;
		       $groups{$current}->{bkg_eshift} = sprintf("%.4f", $groups{$current}->{bkg_eshift});
		       if ($groups{$current}->{reference} and exists $groups{$groups{$current}->{reference}}) {
			 $groups{$groups{$current}->{reference}}->make(bkg_eshift=>$groups{$current}->{bkg_eshift});
			 $groups{$groups{$current}->{reference}}->make(bkg_e0=>$groups{$groups{$current}->{reference}}->{bkg_e0}+$groups{$current}->{bkg_eshift});
		       };
		       $groups{$current}->{bkg_e0}      = $cal_params{e0};
		       $groups{$current} -> make(update_bkg=>1);
		       my $str = 'em';
		       ($str = 'emn') if ($cal_params{display} eq 'norm(E)');
		       ($str = 'emd') if ($cal_params{display} eq 'deriv(E)');
		       ($str = 'em2') if ($cal_params{display} eq 'second deriv');
		       $str .= 's' x $cal_params{iterations};
		       $cal_params{str} = $str;
		       $plot_features{suppress_markers} = 1;
		       $groups{$current}->plotE($str, $dmode, \%plot_features, \@indicator);
		       $plot_features{suppress_markers} = 0;
		       &cal_marker($current, $cal_params{e0}, $cal_params{str});
		       $groups{$current}->make(update_bkg=>1);
		       project_state(0);
		       Echo("Calibrated to $cal_params{cal_to}");
		     })
      -> grid(-row=>8, -column=>0, -columnspan=>2, -sticky=>'we');


  $widget{calib_zero} -> configure(-state=>($cal_params{display} eq 'second deriv') ? 'normal' : 'disabled');
  $groups{$current} -> dispose("set $current.deriv = deriv($current.xmu)/deriv($current.energy)\n", $dmode);
  my $str = 'em';
  ($str = 'emn') if ($cal_params{display} eq 'norm(E)');
  ($str = 'emd') if ($cal_params{display} eq 'deriv(E)');
  ($str = 'em2') if ($cal_params{display} eq 'second deriv');
  $str .= 's' x $cal_params{iterations};
  $cal_params{str} = $str;
  $plot_features{suppress_markers} = 1;
  $groups{$current}->plotE($str, $dmode, \%plot_features, \@indicator);
  $plot_features{suppress_markers} = 0;
  &cal_marker($current, $cal_params{e0}, $cal_params{str});
  $plotsel -> raise('e');
  $top -> update;
};



sub cal_pluck {
  my ($group, $str) = @_;
  Error("Calibration display aborted: " . $groups{$group}->{label} . " is not an xmu group."),
    return unless ($groups{$group}->{is_xmu});
  Echonow("Select a point from the plot");
  $groups{$group} -> dispose('cursor(crosshair=true)', 1);
  my ($xx, $yy) = (Ifeffit::get_scalar('cursor_x'), Ifeffit::get_scalar('cursor_y'));
  return sprintf("%.3f", $xx);
};

## show the edge energy marker in a calibration plot, take care to
## deal well with derivative
sub cal_marker {
  my ($g, $e, $str) = @_;
  Error("Calibration display aborted: " . $groups{$g}->{label} . " is not an xmu group."),
    return unless ($groups{$g}->{is_xmu});
  my $command = "";
  my $xarr = "\"$g.energy+$groups{$g}->{bkg_eshift}\"";

  if ($str =~ /(s+)/) {
    my $iterations = length($1);
    my $suff = 'xmu';
    if ($groups{$g}->{not_data}) {
      $suff = 'det';
    } elsif ($str =~ /n/) {
      $suff = 'norm';
    };
    $groups{$g}->dispose("set $g.smooth = $g.$suff", $dmode);
    foreach (1 .. $iterations) {
      $groups{$g}->dispose("set $g.smooth = smooth($g.smooth)", $dmode);
    };
  };

  my $suff = "xmu";
  ($str =~ /n/) and ($suff = "norm");
  ($str =~ /s/) and ($suff = "smooth");
  ($str =~ /d/) and ($suff = "deriv");
  if ($str =~ /2/) {
    $command .= "set $g.second = deriv($g.deriv)/deriv($g.energy)\n";
    $suff = "second";
  };
  my $yarr = "$g.$suff";
  my $yoff = $groups{$g}->{plot_yoffset};

  $command .= "pmarker $xarr, $yarr, $e, $plot_features{marker}, $plot_features{markercolor}, $yoff\n";
  ##($str =~ /^d/) and ($command .= "erase $g.deriv\n");

  $groups{$g} -> dispose($command, $dmode);
  $last_plot='e';
};

sub cal_zero {
  my ($g, $r_hash) = @_;
  my $str = $$r_hash{str};
  $$r_hash{zero_skip_plot} ||= 0;
  my $suff = 'xmu';
  if ($groups{$g}->{not_data}) {
    $suff = 'det';
  } elsif ($str =~ /n/) {
    $suff = 'norm';
  };
  if ($str =~ /(s+)/) {
    my $iterations = length($1);
    $groups{$g}->dispose("set $g.smooth = $g.$suff", $dmode);
    foreach (1 .. $iterations) {
      $groups{$g}->dispose("set $g.smooth = smooth($g.smooth)", $dmode);
    };
    $suff = 'smooth';
  };
  $groups{$g}->dispose("set($g.y = deriv($g.$suff)/deriv($g.energy), $g.y = deriv($g.y)/deriv($g.energy))\n", $dmode);

  my @x = map {$_ + $groups{$g}->{bkg_eshift}} Ifeffit::get_array("$g.energy");
  my @y = Ifeffit::get_array("$g.y");

  my $e0index = 0;
  foreach my $e (@x) {
    last if ($e > $$r_hash{e0});
    ++$e0index;
  };
  my ($enear, $ynear) = ($x[$e0index], $y[$e0index]);
  my ($ratio, $i) = (1, 1);
  my ($above, $below) = (0,0);
  while (1) {			# find points that bracket the zero crossing
    (($above, $below) = (0,0)), last unless (exists($y[$e0index + $i]) and $y[$e0index]);
    $ratio = $y[$e0index + $i] / $y[$e0index]; # this ratio is negative for a points bracketing the zero crossing
    ($above, $below) = ($e0index+$i, $e0index+$i-1);
    last if ($ratio < 0);
    (($above, $below) = (0,0)), last unless exists($y[$e0index - $i]);
    $ratio = $y[$e0index - $i] / $y[$e0index]; # this ratio is negative for a points bracketing the zero crossing
    ($above, $below) = ($e0index-$i+1, $e0index-$i);
    last if ($ratio < 0);
    ++$i;
    Error("Could not find zero crossing."), return 0 if ($i == 4000);
  };
  Error("Could not find zero crossing."), return if (($above == 0) and ($below == 0));

  ## linearly interpolate between points that bracket the zero crossing
  $$r_hash{e0} = sprintf("%.3f", $x[$below] - ($y[$below]/($y[$above]-$y[$below])) * ($x[$above] - $x[$below]));
  return if $$r_hash{zero_skip_plot};

  $plot_features{suppress_markers} = 1;
  $groups{$current}->plotE($$r_hash{str}, $dmode, \%plot_features, \@indicator);
  $plot_features{suppress_markers} = 0;
  &cal_marker($current, $$r_hash{e0}, $$r_hash{str});

  $groups{$g}->dispose("erase $g.y $g.smooth", $dmode);
  Echo("Found zero crossing at $$r_hash{e0} in group \"$groups{$g}->{label}\".");
};



## END OF DATA CALIBRATION SUBSECTION
##########################################################################################
