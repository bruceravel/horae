## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  multi-electron excitation removal

sub mee {
  Echo("No data!"), return unless $current;

  my $key = join("_", lc($groups{$current}->{bkg_z}), lc($groups{$current}->{fft_edge}));
  my %mee_params = (
		    shift => $groups{$current}->{mee_en} || $mee_energies{energies}{$key} || $config{mee}{shift},
		    width => $groups{$current}->{mee_wi} || $config{mee}{width},
		    amp   => $groups{$current}->{mee_am} || $config{mee}{amp},
		    key   => $key,
		   );
  my $color = $plot_features{c1};
  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = -200; #$config{mee}{emin};
  $plot_features{emax} = 1100; #$config{mee}{emax};
  project_state($ps);		# don't toggle if currently saved

  Echo("No data!"), return if ($current eq "Default Parameters");

  my @label = (-font=>$config{fonts}{small}, -foreground=>'black', );

  $fat_showing = 'mee';
  $hash_pointer = \%mee_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $mee = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  $which_showing = $mee;

  $mee -> Label(-text=>"Multi-electron excitation removal",
		-font=>$config{fonts}{large},
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## select the alignment standard
  my $frame = $mee -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -pady=>8);
  $frame -> Label(-text=>"Data: ", @label,)
    -> grid(-row=>0, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{mee_data} = $frame -> Label(-text=>$groups{$current}->{label},
				      -foreground=>$config{colors}{button})
    -> grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'w', -pady=>2, -padx=>2);

  my $t = $frame -> Label(-text=>"Energy offset: ", @label,)
    -> grid(-row=>1, -column=>0, -sticky=>'e', -ipady=>2);
  &click_help($t,"mee_en");
  $widget{mee_en} = $frame -> RetEntry(-textvariable=>\$mee_params{shift},
				       -validate=>'key',
				       -command=>sub{ mee_plot($config{mee}{plot}, \%mee_params)},
				       -validatecommand=>[\&set_variable, 'mee_en'],
				       -width=>6)
    -> grid(-row=>1, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);
  $frame -> Label(-text=>" eV", @label,)
    -> grid(-row=>1, -column=>2, -sticky=>'w', -ipady=>2);

  $t = $frame -> Label(-text=>"Broadening: ", @label,)
    -> grid(-row=>2, -column=>0, -sticky=>'e', -ipady=>2);
  &click_help($t,"mee_wi");
  $widget{mee_wi} = $frame -> RetEntry(-textvariable=>\$mee_params{width},
				       -validate=>'key',
				       -command=>sub{ mee_plot($config{mee}{plot}, \%mee_params)},
				       -validatecommand=>[\&set_variable, 'mee_wi'],
				       -width=>6)
    -> grid(-row=>2, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);
  $frame -> Label(-text=>" eV", @label,)
    -> grid(-row=>2, -column=>2, -sticky=>'w', -ipady=>2);

  $t = $frame -> Label(-text=>"Amplitude: ", @label,)
    -> grid(-row=>3, -column=>0, -sticky=>'e', -ipady=>2);
  &click_help($t,"mee_am");
  $widget{mee_am} = $frame -> RetEntry(-textvariable=>\$mee_params{amp},
				       -validate=>'key',
				       -command=>sub{ mee_plot($config{mee}{plot}, \%mee_params)},
				       -validatecommand=>[\&set_variable, 'mee_am'],
				       -width=>6)
    -> grid(-row=>3, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);

  $frame = $mee -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -pady=>8);
  $frame -> Label(-text=>"Plot data and correction in:",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> pack(-side=>'top', -fill=>'x', -pady=>2);
  my $fr = $frame -> Frame()
    -> pack(-side=>'top', -pady=>2);
  $widget{mee_e} = $fr -> Button(-text    => 'E', @button_list,
				 -command => sub{mee_plot('e', \%mee_params)})
    -> pack(-side=>'left', -padx=>2);
  $widget{mee_k} = $fr -> Button(-text    => 'k', @button_list,
				 -command => sub{mee_plot('k', \%mee_params)})
    -> pack(-side=>'left', -padx=>2);
  $widget{mee_r} = $fr -> Button(-text    => 'R', @button_list,
				 -command => sub{mee_plot('r', \%mee_params)})
    -> pack(-side=>'left', -padx=>2);
  $widget{mee_q} = $fr -> Button(-text    => 'q', @button_list,
				 -command => sub{mee_plot('q', \%mee_params)})
    -> pack(-side=>'left', -padx=>2);
  $widget{mee_make} = $mee
    -> Button(-text=>"Make corrected data group", @button_list,
	      -command=>sub{mee_group(\%mee_params)})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');
  $widget{mee_store} = $mee
    -> Button(-text=>"Store this MEE offset energy", @button_list,
	      -command=>
	      sub {
		$mee_energies{energies}{$mee_params{key}} = $mee_params{shift};
		my $tenergies = tied %mee_energies;
		$tenergies -> WriteConfig($groups{"Default Parameters"} -> find('athena', 'mee'));
		my $message = sprintf("Stored %s as the energy shift for the %s %s edge.",
				      $mee_params{shift},
				      ucfirst($groups{$current}->{bkg_z}),
				      ucfirst($groups{$current}->{fft_edge}));
		Echo($message);
	      })
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w', -pady=>4);

  $mee -> Button(-text=>'Return to the main window',  @button_list,
		 -background=>$config{colors}{background2},
		 -activebackground=>$config{colors}{activebackground2},
		 -command=>sub{
		   &reset_window($mee, "multi-electron removal", \@save);
		 })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $mee -> Button(-text=>'Document section: multi-electron excitation removal', @button_list,
		 -command=>sub{pod_display("process::mee.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  if (not $groups{$current}->{is_xmu}) {
    map {$widget{"mee_$_"}  -> configure(-state=>'disabled')} qw(store make e k r q);
  };
  $top -> update;
};


sub mee_correct {
  my ($rmp, $plot) = @_;;

  ($groups{$current}->{update_bkg}) and $groups{$current}->dispatch_bkg($dmode);


  my $commands = "##\n## performing multi-electron excitation removal\n";
  $commands   .= "set(m___ee.nn     = lconvolve($current.energy, $current.norm, $$rmp{width}),\n";
  $commands   .= "    m___ee.energy = $current.energy,\n";
  $commands   .= "    m___ee.ee     = m___ee.energy +  $$rmp{shift},\n";
  $commands   .= "    m___ee.xint   = interp(m___ee.ee, m___ee.nn, $current.energy))\n";
  $commands   .= "## use perl to pad zeros at the beginning of the shifted array\n";
  $groups{$current} -> dispose($commands, $dmode);

  my @x  = Ifeffit::get_array("$current.energy");
  my $e1 = $x[0] + $$rmp{shift};
  my @y  = Ifeffit::get_array("m___ee.xint");
  my $yoff = 0;
  my $edgestep = $groups{$current}->{bkg_step};
  foreach my $i (0 .. $#x) {
    if ($x[$i] < $e1) {
      ## this replaces the extrapolated part of the shifted spectrum
      ## with zeros in the pre-edge
      $yoff = $y[$i];
      $y[$i] = 0;
    } else {
      ## this corrects for the pre-edge not going to the baseline
      ## after the convolution and approximately corrects the edge
      ## step of the convoluted mu(E) data
      ## $y[$i] = ($y[$i] - $yoff);# * (1 + $yoff);
    };
  };
  Ifeffit::put_array("m___ee.xint", \@y);

  $commands = "set(m___ee.xmu = $current.norm - $$rmp{amp}*m___ee.xint)\n";
  $groups{$current} -> dispose($commands, $dmode);

  mee_plot($config{mee}{plot}, $rmp) if $plot;;


  #$groups{$current} -> plotE('em',$dmode,\%plot_features, \@indicator);
  #$groups{$current} -> dispose("plot($current.energy, m___ee.corr)");

};

sub mee_plot {
  my ($space, $rmp) = @_;
  Echonow("Correcting multi-electron excitation in \"$groups{$current}->{label}\" ...");
  $top->Busy;
  my $mode = $dmode;
  ($mode & 2) or ($mode += 2);
  @ifeffit_buffer = ();
  mee_correct($rmp, 0);
  my $save = $groups{$current}->{bkg_flatten};
  $groups{$current} -> make(update_bkg=>1, bkg_flatten=>0);
  my $command = q{};
  SWITCH: {
    ($space eq 'e') and do {
      $groups{$current} -> plotE('emn',$mode,\%plot_features, \@indicator);
      last SWITCH;
    };
    ($space eq 'k') and do {
      $groups{$current} -> plotk('k',$mode,\%plot_features, \@indicator);
      last SWITCH;
    };
    ($space eq 'r') and do {
      my $str = $plot_features{r_marked};
      $groups{$current} -> plotR($str,$mode,\%plot_features, \@indicator);
      last SWITCH;
    };
    ($space eq 'q') and do {
      my $str = $plot_features{q_marked};
      $groups{$current} -> plotq($str,$mode,\%plot_features, \@indicator);
      last SWITCH;
    };
  };
  foreach my $line (@ifeffit_buffer) {
    ($command .= $line) =~ s{$current\.}{m___ee.}g;
  };
  $command =~ s{newplot}{plot}g;
  $command =~ s{\.norm}{.xmu}g;
  $command =~ s{pre1=}{find_e0=F, pre1=}g;
  $command =~ s{$config{plot}{c0}}{$config{plot}{c1}}g;
  @ifeffit_buffer = ();
  ## print $command;
  $groups{$current} -> dispose($command, $dmode);
  $groups{$current} -> make(bkg_flatten=>$save);
  Echonow("Correcting multi-electron excitation in \"$groups{$current}->{label}\" ... done!");
  $top->Unbusy;
};



## make a new data group out of the mee-corrected data, make this an
## xmu group so it can be treated like normal data
sub mee_group {
  my $rhash = $_[0];
  $top->Busy;
  mee_correct($rhash, 0);
  my $group = $groups{$current}->{group};
  my ($new, $label) = group_name("MEE $group");
  $label = "MEE " . $groups{$current}->{label} . ": e " . $$rhash{shift} . " a " . $$rhash{amp};
  $groups{$new} = Ifeffit::Group -> new(group=>$new, label=>$label);
  $groups{$new} -> set_to_another($groups{$group});
  $groups{$new} -> make(is_xmu => 1, is_chi => 0, is_rsp => 0,
			is_qsp => 0, is_bkg => 0, is_nor => 1,
			not_data => 0);
  $groups{$new} -> make(bkg_e0 => $groups{$group}->{bkg_e0});
  $groups{$new} -> make(file => "MEE correction of $groups{$current}->{label} at $$rhash{shift} eV");
  $groups{$new}->{titles} = [];
  push @{$groups{$new}->{titles}},
    "MEE correction of $groups{$current}->{label}: shift=$$rhash{shift} eV",
      "broadening=$$rhash{width}, amplitude=$$rhash{amp}";
  $groups{$new} -> put_titles;
  $groups{$new} -> dispose("set($new.energy = $group.energy, $new.xmu = m___ee.xmu)", $dmode);
  ++$line_count;
  $reading_project = 1;		# sloppy ... see main_window.pl
  fill_skinny($list, $new, 1, 1);
  $reading_project = 0;
  project_state(0);
  my $memory_ok = $groups{$new}
    -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo("WARNING: Ifeffit is out of memory!"), return if ($memory_ok == -1);
  Echo("Saved MEE correction of \"$groups{$current}->{label}\" as a new data group");
  $top->Unbusy;
};
