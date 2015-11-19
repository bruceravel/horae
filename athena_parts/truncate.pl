## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  data truncation


sub truncate_palette {
  Echo("No data!"), return unless $current;
  Echo("You must select a data group to truncate"), return
    if ($current eq "Default Parameters");

  my @keys = ();
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
  };
  Echo("You need at least one xmu group to truncate"), return unless (@keys);
  my $group = $groups{$current}->{group};
  my @e = get_array("$group.energy");
  $groups{$current} -> make(etruncate=> $e[$#e]);
  my %trun_params = ( etruncate	  => sprintf("%.3f", $e[$#e]+0.001),
		      beforeafter => 'after',
		      plot	  => 'mu(E)' );
  $hash_pointer = \%trun_params;
  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emax} = int(1.1*($trun_params{etruncate} - $groups{$current}->{bkg_e0}));
  project_state($ps);		# don't toggle if currently saved

  $fat_showing = 'truncate';
  #$hash_pointer = \%trun_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $trun = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$trun -> packPropagate(0);
  $which_showing = $trun;

  $trun -> Label(-text=>"Data truncation",
		 -font=>$config{fonts}{large},
		 -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  my $frame = $trun -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-ipadx=>3, -ipady=>3, -fill=>'x');
  my $fr = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-ipadx=>3, -ipady=>3, -side=>'top');
  $fr -> Label(-text=>"Group:",
	       -foreground=>$config{colors}{activehighlightcolor},
	      )
    -> pack(-side=>'left');
  $widget{trun_group} = $fr -> Label(-text=>$groups{$current}->{label},
				     -foreground=>$config{colors}{button})
    -> pack(-side=>'right');


  $fr = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -ipady=>3);

  my $fr2 = $fr -> Frame(-borderwidth=>2, -relief=>'flat') -> pack();
  $fr2 -> Label(-text=>'Drop points ',
		-foreground=>$config{colors}{activehighlightcolor},
	       )
    -> pack(-side=>'left');
  $fr2 -> Optionmenu(-variable=>\$trun_params{beforeafter},
		     -textvariable=>\$trun_params{beforeafter},
		     -borderwidth=>1,
		     -options=>['before', 'after'],
		     )
     -> pack(-side=>'left');
  $fr2 -> Label(-text=>' E =',
		-foreground=>$config{colors}{activehighlightcolor},
	       )
    -> pack(-side=>'left');
  $widget{etruncate} = $fr2 -> RetEntry(-textvariable=>\$trun_params{etruncate},
					-command=>sub{$widget{trun_replot}->invoke},
					-width=>10)
    -> pack(-side=>'left');
  $grab{etruncate} = $fr2 -> Button(@pluck_button, @pluck,
				    -command=>
				    sub{Echo("\"$groups{$current}->{label}\" is frozen"), return
					  if $groups{$current}->{frozen};
					&pluck('etruncate');
					$groups{$current} -> make(etruncate=>
								  $widget{etruncate}->get());
					my $str;
					map {$str .= $plot_features{$_}} (qw/e_mu e_norm e_der/);
					($str eq "e")  and ($str = "em");
					($str eq "en") and ($str = "emn");
					($str eq "ed") and ($str = "emd");
					$groups{$current} -> plotE($str,$dmode,\%plot_features, \@indicator);
					$last_plot = 'e';
					my $e = $groups{$current}->{etruncate};
					my $suff = ($str =~ /n/) ? 'norm' : 'xmu';
					($suff = 'flat') if (($str =~ /n/) and $groups{$current}->{bkg_flatten});
					my @x = Ifeffit::get_array("$current.energy");
					my @y = Ifeffit::get_array("$current.$suff");
					my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$current}->{bkg_e0});
					$groups{$current} -> plot_vertical_line($e, $ymin, $ymax,
										$dmode, "truncate",
										$groups{$current}->{plot_yoffset});
					$trun_params{etruncate} = $groups{$current}->{etruncate};
				      })
    -> pack(-side=>'left');

  $widget{trun_replot} =
    $fr -> Button(-text=>'Replot', @button_list,
		  -width=>1,
		  -command=>sub{my $str;
				map {$str .= $plot_features{$_}} (qw/e_mu e_norm e_der/);
				($str eq "e")  and ($str = "em");
				($str eq "en") and ($str = "emn");
				($str eq "ed") and ($str = "emd");
				$groups{$current} -> plotE($str,$dmode,\%plot_features, \@indicator);
				$last_plot='e';
				my $g = $groups{$current}->{group};
				$groups{$current} -> make(etruncate=> $widget{etruncate}->get());
				my $e = $groups{$current}->{etruncate};
				my $suff = ($str =~ /n/) ? 'norm' : 'xmu';
				($suff = 'flat') if (($str =~ /n/) and $groups{$current}->{bkg_flatten});
				my @x = Ifeffit::get_array("$current.energy");
				my @y = Ifeffit::get_array("$current.$suff");
				my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$current}->{bkg_e0});
				$groups{$current} -> plot_vertical_line($e, $ymin, $ymax,
									$dmode, "truncate",
									$groups{$current}->{plot_yoffset});
			      })
    -> pack(-expand=>1, -fill=>'x');

  $widget{trun_truncate} =
    $fr -> Button(-text=>'Truncate data', @button_list,
		  -width=>1,
		  -command=>sub{Echo("Truncation aborted: \"$groups{$current}->{label}\" is frozen"), return
				  if $groups{$current}->{frozen};
				&truncate_data($current,0,$trun_params{beforeafter});
				$widget{trun_replot} -> invoke;
				$top -> update;})
      -> pack(-expand=>1, -fill=>'x');
  $widget{trun_truncate} =
    $fr -> Button(-text=>'Truncate marked groups', @button_list,
		  -width=>1,
		  -command=>sub{
		    Echo("Truncating marked groups ...");
		    $top -> Busy;
		    my $restore = $current;
		    foreach my $g (&sorted_group_list) {
		      next unless $marked{$g};
		      next if $groups{$g}->{frozen};
		      set_properties(0, $g, 0);
		      &truncate_data($current,0,$trun_params{beforeafter});
		      $widget{trun_replot} -> invoke;
		    };
		    set_properties(1, $restore, 0);
		    $top -> Unbusy;
		    Echo("Truncating marked groups ... done!");
		    $top -> update;
		  })
      -> pack(-expand=>1, -fill=>'x');


  ## help button
  $trun -> Button(-text=>'Document section: truncating data', @button_list,
		  -command=>sub{pod_display("process::trun.pod")})
    -> pack(-fill=>'x', -pady=>4);

  $trun -> Button(-text=>'Return to the main window',  @button_list,
		  -background=>$config{colors}{background2},
		  -activebackground=>$config{colors}{activebackground2},
		  -command=>sub{&reset_window($trun, "truncation", \@save)}
		 )
    -> pack(-fill=>'x');
  $trun -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-expand=>1, -fill=>'both');

  my $str;
  map {$str .= $plot_features{$_}} (qw/e_mu e_norm e_der/);
  ($str eq "e")  and ($str = "em");
  ($str eq "en") and ($str = "emn");
  ($str eq "ed") and ($str = "emd");
  $groups{$current} -> plotE($str,$dmode,\%plot_features, \@indicator);
  my $e = $groups{$current}->{etruncate};
  my $suff = ($str =~ /n/) ? 'norm' : 'xmu';
  ($suff = 'flat') if (($str =~ /n/) and $groups{$current}->{bkg_flatten});
  my @x = Ifeffit::get_array("$current.energy");
  my @y = Ifeffit::get_array("$current.$suff");
  my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$current}->{bkg_e0});
  $groups{$current} -> plot_vertical_line($e, $ymin, $ymax, $dmode, "truncate",
					  $groups{$current}->{plot_yoffset});
  $last_plot='e';
  $plotsel -> raise('e');
  $top -> update;
};


sub truncate_data {
  my $g = $_[0];
  Error("Truncation aborted: " . $groups{$g}->{label} . " is not an xmu group."),
    return unless ($groups{$g}->{is_xmu});
  my $etrun = $groups{$g}->{etruncate};
  my $noplot = $_[1];
  my $beforeafter = $_[2];
  my @x = Ifeffit::get_array("$g.energy");
  my @y = Ifeffit::get_array("$g.xmu");
  if (($etrun < $x[0]) or ($etrun > $x[-1])) {
    Echo("Truncation aborted: truncation energy is outside the data range for $groups{$g}->{label}");
    return;
  };
  #my (@newx, @newy);
  my $last = 0;
  foreach (0 .. $#x) {
    $last = $_ -1, last if ($x[$_] > $etrun);
    #$newx[$_] = $x[$_];
    #$newy[$_] = $y[$_];
    #print "$g  $etrun  $x[$_]\n";
  };
  if ($beforeafter eq 'after') {
    $#x = $last; $#y = $last;
  } else {
    @x = @x[$last+1 .. $#x];
    @y = @y[$last+1 .. $#y];
  };
  #$groups{$g}->dispose("erase $g.energy", $dmode);
  #$groups{$g}->dispose("erase $g.xmu", $dmode);
  Ifeffit::put_array("$g.energy", \@x);
  Ifeffit::put_array("$g.xmu", \@y);
  #$groups{$g}->dispose("show $g.energy", $dmode);

  ## reset the various range parameters
  my ($pre1, $pre2, $nor1, $nor2, $spl1, $spl2, $kmin, $kmax) =
    set_range_params($g);
  my $e0 = $groups{$g}->{bkg_e0};
  if ($beforeafter eq 'after') {
    $groups{$g}->dispose("set ___x = ceil($g.energy)\n");
    my $maxe = Ifeffit::get_scalar("___x");
    $groups{$g} -> make(bkg_nor1   => $nor1,
			update_bkg => 1) if ($maxe < $groups{$g}->{bkg_nor1}+$e0);
    $groups{$g} -> make(bkg_nor2   => $nor2,
			update_bkg => 1) if ($maxe < $groups{$g}->{bkg_nor2}+$e0);
    $groups{$g} -> make(bkg_spl1   => $spl1,
			bkg_spl1e  => $groups{$g}->k2e($spl1),
			update_bkg => 1) if ($maxe < $groups{$g}->{bkg_spl1e}+$e0);
    $groups{$g} -> make(bkg_spl2   => $spl2,
			bkg_spl2e  => $groups{$g}->k2e($spl2),
			update_bkg => 1) if ($maxe < $groups{$g}->{bkg_spl2e}+$e0);
    $groups{$g} -> make(fft_kmax   => $kmax,
			update_fft => 1) if ($groups{$g}->e2k($maxe) > $groups{$g}->{fft_kmax});
  } else {
    $groups{$g}->dispose("set ___x = floor($g.energy)\n");
    my $mine = Ifeffit::get_scalar("___x");
    $groups{$g} -> make(bkg_pre1   => $pre1,
			update_bkg => 1) if ($mine >  $groups{$g}->{bkg_pre1}+$e0);
    $groups{$g} -> make(bkg_pre2   => $pre2,
			update_bkg => 1) if ($mine >  $groups{$g}->{bkg_pre2}+$e0);
  };
  $groups{$g} -> kmax_suggest(\%plot_features) if ($groups{$g}->{fft_kmax} == 999);
  unless ($noplot) {
    my $str;
    map {$str .= $plot_features{$_}} (qw/e_mu e_norm e_der/);
    ($str eq "e")  and ($str = "em");
    ($str eq "en") and ($str = "emn");
    ($str eq "ed") and ($str = "emd");
    $groups{$g} -> plotE($str,$dmode,\%plot_features, \@indicator);
    $last_plot='e';
  };
  project_state(0);
};



## END OF DATA TRUNCATION SUBSECTION
##########################################################################################
