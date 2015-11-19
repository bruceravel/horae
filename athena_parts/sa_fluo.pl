## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006, 2009 Bruce Ravel


## possible features:
##  * plot buttons for E, k , R
##  * checkbutton for constraining phi+theta=90
##  * weight percentages in formula


sub sa {

  ## do not change modes unless there is xmu data
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  my @keys = ();
  foreach my $k (&sorted_group_list) {
    (($groups{$k}->{is_xmu}) or ($groups{$k}->{is_chi})) and push @keys, $k;
  };
  Error("You need at least one xmu or chi group to do self-absorption corrections"), return unless (@keys);

  #$top -> Busy;

  ## you must define a hash which will contain the parameters needed
  ## to perform the task.  the $hash_pointer global variable will point
  ## to this hash for use in set_properties.  you might draw these
  ## values from configuration parameters, as in the commented out
  ## example
  my %safluo_params = (angle_in  => $config{sa}{angle_in},
		       angle_out => $config{sa}{angle_out},
		       formula   => "",
		       thickness => $config{sa}{thickness},
		       algorithm => $config{sa}{algorithm});
  my %explain = (fluo   => "Correct XANES spectra, mu(E), and EXAFS, chi(k).  The sample is presumed to be infinitely thick.",
		 booth  => "Correct EXAFS spectra, chi(k), for samples of any thickness.",
		 troger => "Correct EXAFS spectra, chi(k), but only for thick samples.",
		 atoms  => "Correct EXAFS spectra, chi(k), using corrections to S0^2 and sigma^2, but only for thick samples.",
		);
  my $grey  = $config{colors}{disabledforeground};
  my $black = $config{colors}{foreground};
  my $blue  = $config{colors}{activehighlightcolor};
  ## The Athena standard for analysis chores that need a specialized
  ## plotting range is to save the plotting range from the main view
  ## and restore it when the main view is restored
  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = $config{sa}{emin};
  $plot_features{emax} = $config{sa}{emax};
  project_state($ps);		# don't toggle if currently saved

  ## these two global variables must be set before this view is
  ## displayed.  these are used at the level of set_properties to
  ## perform chores appropriate to this dialog when changing the
  ## current group
  $fat_showing = 'sa';
  $hash_pointer = \%safluo_params;

  ## disable many menus.  this makes the chore of managing the views
  ## much easier.  the idea is that the main view is "home base".  if
  ## you want to do a different analysis chore, you must first return
  ## to the main view
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);

  ## this removes the currently displayed view without destroying its
  ## contents
  $fat -> packForget;

  ## define the parent Frame for this analysis chore and pack it in
  ## the correct location
  my $safluo = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);

  ## global variable identifying which Frame is showing
  $which_showing = $safluo;

  ## the standard label along the top identifying this analysis chore
  $safluo -> Label(-text       => "Self Absorption Corrections",
		   -font       => $config{fonts}{large},
		   -foreground => $config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## a good solution to organizing widgets is to stack frames, so
  ## let's make a frame for the standard and the other.  note that the
  ## "labels" are actually flat buttons which display hints in the
  ## echo area
  my $top = $safluo -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x');
  my $frame = $top -> LabFrame(-label	   => 'Algorithm',
			       -foreground => $config{colors}{activehighlightcolor},
			       -labelside  => 'acrosstop')
    -> pack(-side=>'left', -fill=>'both', -expand=>1);
  $widget{safluo_fluo} = $frame -> Radiobutton(-text	     => 'XANES (Fluo)',
					      -selectcolor => $config{colors}{single},
					      -foreground  => $config{colors}{activehighlightcolor},
					      -activeforeground  => $config{colors}{activehighlightcolor},
					      -command     => sub{$widget{safluo_thickness} -> configure(-state=>'disabled');
								  map { $widget{$_}->configure(-foreground=>$grey) } (qw(safluo_thickness safluo_thickness_lab safluo_thickness_lab2));
								  $widget{safluo_make} -> configure(-state=>'disabled');
								  $groups{$current}->plotE('emn', $dmode, \%plot_features, \@indicator)
								    if $groups{$current}->{is_xmu};
								  $last_plot = 'e';
								  $plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
								  Echo($explain{fluo});
								},
					      -value	   => 'fluo',
					      -variable    => \$safluo_params{algorithm})
    -> pack(-side=>'top', -anchor=>'w', -padx=>2, -pady=>2);
  $frame -> Radiobutton(-text	     => 'EXAFS (Booth)',
			-selectcolor => $config{colors}{single},
			-foreground  => $config{colors}{activehighlightcolor},
			-activeforeground  => $config{colors}{activehighlightcolor},
			-command     => sub{$widget{safluo_thickness} -> configure(-state=>'normal');
					    map { $widget{$_}->configure(-foreground=>$blue) } (qw(safluo_thickness_lab safluo_thickness_lab2));
					    $widget{safluo_thickness}->configure(-foreground=>$black);
					    $widget{safluo_make} -> configure(-state=>'disabled');
					    my $str = 'k'.$plot_features{k_w};
					    $groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
					    $last_plot='k';
					    $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
					    Echo($explain{booth});
					  },
			-value	     => 'booth',
			-variable    => \$safluo_params{algorithm})
    -> pack(-side=>'top', -anchor=>'w', -padx=>2, -pady=>2);
  $frame -> Radiobutton(-text	     => 'EXAFS (Troger)',
			-selectcolor => $config{colors}{single},
			-foreground  => $config{colors}{activehighlightcolor},
			-activeforeground  => $config{colors}{activehighlightcolor},
			-command     => sub{$widget{safluo_thickness} -> configure(-state=>'disabled');
					    map { $widget{$_}->configure(-foreground=>$grey) } (qw(safluo_thickness safluo_thickness_lab safluo_thickness_lab2));
					    $widget{safluo_make} -> configure(-state=>'disabled');
					    my $str = 'k'.$plot_features{k_w};
					    $groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
					    $last_plot='k';
					    $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
					    Echo($explain{troger});
					  },
			-value	     => 'troger',
			-variable    => \$safluo_params{algorithm})
    -> pack(-side=>'top', -anchor=>'w', -padx=>2, -pady=>2);
  $frame -> Radiobutton(-text	     => 'EXAFS (Atoms)',
			-selectcolor => $config{colors}{single},
			-foreground  => $config{colors}{activehighlightcolor},
			-activeforeground  => $config{colors}{activehighlightcolor},
			-command     => sub{$widget{safluo_thickness} -> configure(-state=>'disabled');
					    map { $widget{$_}->configure(-foreground=>$grey) } (qw(safluo_thickness safluo_thickness_lab safluo_thickness_lab2));
					    $widget{safluo_make} -> configure(-state=>'disabled');
					    my $str = 'k'.$plot_features{k_w};
					    $groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
					    $last_plot='k';
					    $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
					    Echo($explain{atoms});
					  },
			-value	     => 'atoms',
			-variable    => \$safluo_params{algorithm})
    -> pack(-side=>'top', -anchor=>'w', -padx=>2, -pady=>2);

  $frame = $top -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'right', -fill=>'x');
  $frame -> Label(-text=>"Group:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>0, -column=>0, -sticky=>'e', -pady=>3);
  $widget{safluo_group} = $frame -> Label(-anchor=>'w')
    -> grid(-row=>0, -column=>1, -columnspan=>4, -sticky=>'ew', -pady=>3);

  $frame -> Label(-text=>"Element:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>1, -column=>0, -sticky=>'e', -pady=>3);
  $widget{safluo_elem} = $frame -> Label(-width=>5, -anchor=>'w')
    -> grid(-row=>1, -column=>1, -sticky=>'w', -pady=>3);
  $frame -> Label(-text=>"      ",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>1, -column=>2, -sticky=>'e', -pady=>3);
  $frame -> Label(-text=>"Edge:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>1, -column=>3, -sticky=>'e', -pady=>3);
  $widget{safluo_edge} = $frame -> Label(-width=>3, -anchor=>'w')
    -> grid(-row=>1, -column=>4, -sticky=>'w', -pady=>3);

  $frame -> Label(-text=>"Formula:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>2, -column=>0, -sticky=>'e', -pady=>3);
  $widget{safluo_formula}= $frame -> Entry(-textvariable=>\$safluo_params{formula})
    -> grid(-row=>2, -column=>1, -columnspan=>4, -sticky=>'ew', -pady=>3);
  $widget{safluo_formula} -> bind("<KeyPress-Return>"=>sub{dispatch_sa(\%safluo_params)});

  $frame -> Label(-text=>"Angle in:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>3, -column=>0, -sticky=>'e', -pady=>3);
  $widget{safluo_angle_in} = $frame -> NumEntry(-width	      => 4,
						-orient	      => 'horizontal',
						-foreground   => $config{colors}{foreground},
						-textvariable => \$safluo_params{angle_in},
						-minvalue     => 0,
						-maxvalue     => 90,
					       )
    -> grid(-row=>3, -column=>1, -sticky=>'w', -pady=>3);
  $widget{safluo_angle_in} -> bind("<KeyPress-Return>"=>sub{dispatch_sa(\%safluo_params)});
  $frame -> Label(-text=>"Angle out:",
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>3, -column=>3, -sticky=>'e', -pady=>3);
  $widget{safluo_angle_out} = $frame -> NumEntry(-width	       => 4,
						 -orient       => 'horizontal',
						 -foreground   => $config{colors}{foreground},
						 -textvariable => \$safluo_params{angle_out},
						 -minvalue     => 0,
						 -maxvalue     => 90,
						)
    -> grid(-row=>3, -column=>4, -sticky=>'w', -pady=>3);
  $widget{safluo_angle_out} -> bind("<KeyPress-Return>"=>sub{dispatch_sa(\%safluo_params)});
  $widget{safluo_thickness_lab} = $frame -> Label(-text=>"Thickness:",
						  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>4, -column=>0, -sticky=>'e', -pady=>3);
  $widget{safluo_thickness} = $frame -> Entry(-width	       => 8,
					      -foreground      => $config{colors}{foreground},
					      -textvariable    => \$safluo_params{thickness},
					      -validate        => 'key',
					      -validatecommand => [\&set_variable, 'safluo_thickness']
					     )
    -> grid(-row=>4, -column=>1, -sticky=>'ew', -pady=>3);
  $widget{safluo_thickness} -> bind("<KeyPress-Return>"=>sub{dispatch_sa(\%safluo_params)});
  $widget{safluo_thickness_lab2} = $frame -> Label(-text       => "mic.",
						   -foreground => $config{colors}{activehighlightcolor},)
    -> grid(-row=>4, -column=>2, -sticky=>'w', -pady=>3);



  ## this is a spacer frame which pushes all the widgets to the top
  #$safluo -> Frame(-background=>$config{colors}{darkbackground})
  #  -> pack(-side=>'bottom', -expand=>1, -fill=>'both');

  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $safluo -> Button(-text=>'Return to the main window',  @button_list,
		    -background=>$config{colors}{background2},
		    -activebackground=>$config{colors}{activebackground2},
		    -command=>sub{## restore the main view
				  ##$groups{$current} -> dispose("erase s___a.resid s___a.postline s___a___nor\n", $dmode);
				  $groups{$current} -> dispose("erase s___a___nor\n", $dmode);
				  $groups{$current} -> dispose("erase \@group s___a\n", $dmode);
		                  &reset_window($safluo, "self absorption", \@save);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $safluo -> Button(-text=>'Document section: self absorption corrections', @button_list,
		    -command=>sub{pod_display("process::sa.pod") })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  ## now begin setting up the widgets you need for your new analysis
  ## feature

  ## now a new frame buttons
  $frame = $safluo -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -pady=>8);
  $widget{safluo_plot} = $frame -> Button(-text=>"Plot data and correction", @button_list,
					  -command=>sub{dispatch_sa(\%safluo_params)})
    -> pack(-fill=>'x');
  $frame -> Button(-text=>'Plot information depth', @button_list,
		    -command=>sub{dispatch_sa(\%safluo_params, 'info')})
    -> pack(-fill=>'x');
  $widget{safluo_make} = $frame -> Button(-text=>"Make corrected data group", @button_list,
					  -command=>sub{sa_group($current,\%safluo_params)})
    -> pack(-fill=>'x');


  $frame = $safluo -> LabFrame(-label=>'Feedback',
			       -foreground=>$config{colors}{activehighlightcolor},
			       -labelside=>'acrosstop')
    -> pack(-pady=>3, -padx=>3, -ipady=>3, -ipadx=>3, -fill=>'both', -expand=>1);
  $widget{safluo_feedback} = $frame -> Scrolled('ROText',
						-height	    => 1,
						-width	    => 1,
						-scrollbars => 'osoe',
						-wrap	    => 'none',
						-font	    => $config{fonts}{entry})
    -> pack(-fill=>'both', -padx=>2, -pady=>2, -expand=>1);
  $widget{safluo_feedback} -> Subwidget("xscrollbar") -> configure(-background=>$config{colors}{background});
  $widget{safluo_feedback} -> Subwidget("yscrollbar") -> configure(-background=>$config{colors}{background});
  $widget{safluo_feedback} -> tagConfigure('margin', -lmargin1=>4, -lmargin2=>4);
  $widget{safluo_feedback} -> tagConfigure('error', -lmargin1=>4, -lmargin2=>4, -foreground=>'red3');
  BindMouseWheel($widget{safluo_feedback});
  ## disable mouse-3
  my @swap_bindtags = $widget{safluo_feedback}->Subwidget('rotext')->bindtags;
  $widget{safluo_feedback} -> Subwidget('rotext') -> bindtags([@swap_bindtags[1,0,2,3]]);
  $widget{safluo_feedback} -> Subwidget('rotext') -> bind('<Button-3>' => sub{$_[0]->break});
  $widget{safluo_feedback} -> tagConfigure("text", -font=>$config{fonts}{fixedsm});


  ## disable thickness for Fluo, Troger, Atoms correction
  unless ($safluo_params{algorithm} eq 'booth') {
    $widget{safluo_thickness} -> configure(-state=>'disabled');
    ##map { print $_, "  ", ref $widget{$_}, $/ }
    foreach my $w ('safluo_thickness', 'safluo_thickness_lab', 'safluo_thickness_lab2') {
      #print $w, "  ", ref $widget{$w}, "  ", $config{colors}{disabledforeground}, $/;
      $widget{$w}->configure(-foreground=>$grey);
    };
  };

  ## insert group dependent data
  $widget{safluo_group} -> configure(-text=>$groups{$current}->{label});
  $widget{safluo_elem}  -> configure(-text=>$groups{$current}->{bkg_z});
  $widget{safluo_edge}  -> configure(-text=>$groups{$current}->{fft_edge});

  ## configure the buttons, insert the formula if it exists
  my $is_xmu = $groups{$current}->{is_xmu};
  $widget{safluo_plot} -> configure(-state=>($is_xmu) ? 'normal' : 'disabled');
  $widget{safluo_make} -> configure(-state=>'disabled');
  $widget{safluo_formula} -> focus;

  ## disable the Fluo button for chi data
  unless ($is_xmu) {
    ($safluo_params{algorithm} = "booth") if ($safluo_params{algorithm} eq 'fluo');
    $widget{safluo_fluo} -> configure(-state=>'disabled');
  };

  foreach my $k (qw(formula thickness angle_in angle_out)) {
    $safluo_params{$k} = $groups{$current}->{"sa_$k"} if (exists $groups{$current}->{"sa_$k"} and
							  $groups{$current}->{"sa_$k"} !~ /^\s*$/);
  };

  ## make a nice plot
  if ($safluo_params{algorithm} eq 'fluo') {
    $groups{$current}->plotE('emn', $dmode, \%plot_features, \@indicator) if $is_xmu;
    $last_plot = 'e';
    $plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  } else {
    my $str = 'k'.$plot_features{k_w};
     $groups{$current}->plotk($str, $dmode, \%plot_features, \@indicator) if $is_xmu;
    $last_plot = 'k';
    $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  };

  $top -> update;

  ## and finally....
  #$top -> Unbusy;

};


sub dispatch_sa {
  my $rparams = $_[0];
  my $algorithm = $_[1] || 'correction';
  unless ($$rparams{formula}) {
    $widget{safluo_feedback} -> insert('end', "\nInput error:\n\tYou did not specify a chemical formula", ['error']);
    Error("You did not specify a chemical formula");
    return;
  };
  if ($$rparams{thickness} <= 0) {
    $widget{safluo_feedback} -> insert('end', "\nInput error:\n\tThe thickness must be a positive number", ['error']);
    Error("The thickness must be a positive number");
    return;
  };
 SWITCH: {
    sa_info_depth($rparams), last SWITCH if ($algorithm eq 'info');
    do_safluo($rparams),     last SWITCH if ($$rparams{algorithm} eq 'fluo');
    do_sabooth($rparams),    last SWITCH if ($$rparams{algorithm} eq 'booth');
    do_satroger($rparams),   last SWITCH if ($$rparams{algorithm} eq 'troger');
    do_saatoms($rparams),    last SWITCH if ($$rparams{algorithm} eq 'atoms');
  };
};


sub do_safluo {
  my $rparams = $_[0];
  Echo("Doing Fluo correction");
  $top -> Busy;

  my $e0shift = $groups{$current}->{bkg_eshift};
  my ($ok, $efluo, $rcount) = sa_feedback($rparams);
  unless ($ok) {
    Error("Error parsing formula.");
    $top -> Unbusy;
    return;
  };

  my $eplus = $groups{$current}->{bkg_e0} + $groups{$current}->{bkg_nor1} + $e0shift;
  my $enominal = Xray::Absorption -> get_energy($groups{$current}->{bkg_z}, $groups{$current}->{fft_edge});
  ($eplus = $enominal + 10) if ($eplus < $enominal);
  my ($barns_fluo, $barns_plus) = (0,0);
  my $mue_plus = 0;

  if ($ok) {
    foreach my $k (keys(%$rcount)) {

      ## compute contribution to mu_total at the fluo energy
      $barns_fluo += $$rcount{$k} * Xray::Absorption -> cross_section($k, $efluo);

      if (lc($k) eq lc(get_symbol($groups{$current}->{bkg_z}))) {
	## compute contribution to mu_abs at the above edge energy
	$mue_plus = $$rcount{$k} * Xray::Absorption -> cross_section($k, $eplus);
      } else {
	## compute contribution to mu_back at the above edge energy
	$barns_plus += $$rcount{$k} * Xray::Absorption -> cross_section($k, $eplus);
      };
    };
  };

  unless ($mue_plus > 0) {
    $widget{safluo_feedback} -> insert('end', "\nUnable to compute cross section of absorber above the edge", ['error']);
    $top -> Unbusy;
    return;
  };

  my $mut_fluo    = $barns_fluo;
  my $mub_plus    = $barns_plus;
  my $beta        = sprintf("%.6f", $mut_fluo/$mue_plus);
  my $gammaprime  = sprintf("%.6f", $mub_plus/$mue_plus);
  my $angle_ratio = sprintf("%.6f", sin(PI*$$rparams{angle_in}/180) / sin(PI*$$rparams{angle_out}/180));

  my @energy = Ifeffit::get_array($current.".energy");
  my @mub = ();
  foreach my $e (@energy) {
    my $barns = 0;
    foreach my $k (keys(%$rcount)) {
      next if (lc($k) eq lc(get_symbol($groups{$current}->{bkg_z})));
      $barns += Xray::Absorption -> cross_section($k, $e+$e0shift) * $$rcount{$k};
    };
    push @mub, $barns;
  };
  $groups{$current} -> dispose("## inserted s___a.mub into ifeffit's memory...", $dmode);
  Ifeffit::put_array("s___a.mub", \@mub);
  my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
  my $cmd = "## compute self absorption corrected data array using method of Haskel's Fluo\n";
  $cmd   .= "set(s___a.energy = $current.energy+$e0shift,\n";
  $cmd   .= "    s___a.num = $current.$suff * ($beta*$angle_ratio + s___a.mub/$mue_plus),\n";
  $cmd   .= "    s___a.den = ($beta*$angle_ratio + $gammaprime + 1) - $current.$suff,\n";
  $cmd   .= "    s___a.sacorr = s___a.num / s___a.den,\n";
  $cmd   .= "    ___x = max(ceil(s___a.sacorr), abs(floor(s___a.sacorr))) )";
  $groups{$current} -> dispose($cmd, $dmode);
  my $maxval = Ifeffit::get_scalar("___x");

  $groups{$current} -> plotE('emn', $dmode, \%plot_features, \@indicator);
  my $color = $plot_features{c1};
  $groups{$current} -> dispose("plot(s___a.energy, s___a.sacorr, style=lines, color=\"$color\", key=\"SA corrected\")", $dmode);
  $last_plot='e';
  $plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  if ($maxval > 30) {
    my $message = "
Yikes!

This correction seems to be numerically unstable.
Among the common reasons for this are:

  1. Providing the wrong chemical formula

  2. Having data from a sample that is not in the
     infinitely thick limit (the Fluo algorithm
     is not valid in the thin sample limit)

  3. Not including the matrix containing the sample
     in the formula for the stoichiometry (for
     instance, the formula for an aqueous solution
     must include the amount of H2O relative to the
     sample)

";
    $widget{safluo_feedback} -> insert('1.0', $message, ['error']);
  };

  $groups{$current} -> MAKE(sa_formula   => $$rparams{formula},
			    sa_thickness => $$rparams{thickness},
			    sa_angle_in  => $$rparams{angle_in},
			    sa_angle_out => $$rparams{angle_out},
			   );
  project_state(0);
  $widget{safluo_make} -> configure(-state=>'normal');

  Echo("Doing Fluo correction ... done!");
  $top -> Unbusy;
};


## all calculations done in microns!!
sub do_sabooth {
  my $rparams = $_[0];
  Echo("Doing Booth/Bridges correction");
  $top -> Busy;

  my $e0shift = $groups{$current}->{bkg_eshift};
  my ($ok, $efluo, $rcount) = sa_feedback($rparams);
  unless ($ok) {
    Error("Error parsing formula.");
    $top -> Unbusy;
    return;
  };


  my ($barns_fluo, $barns_plus) = (0,0);
  my $mue_plus = 0;

  my ($barns, $amu) = (0,0);
  foreach my $el (keys(%$rcount)) {
    $barns += Xray::Absorption -> cross_section($el, $efluo) * $$rcount{$el};
    $amu   += Xray::Absorption -> get_atomic_weight($el) * $$rcount{$el};
  };
  my $muf = sprintf("%.6f", $barns / $amu / 1.6607143);

  unless ($muf > 0) {
    $widget{safluo_feedback} -> delete('1.0', 'end');
    $widget{safluo_feedback} -> insert('end', "\nUnable to compute cross section of absorber at the fluorescence energy", ['error']);
    Error("Unable to compute cross section of absorber at the fluorescence energy");
    $top -> Unbusy;
    return;
  };

  $groups{$current} -> dispose("erase \@group s___a", $dmode);

  $groups{$current}->dispatch_bkg if $groups{$current}->{update_bkg};
  my @k = Ifeffit::get_array($current.".k");
  my @mut = ();
  my @mua = ();
  my $abs = ucfirst( lc(get_symbol($groups{$current}->{bkg_z})) );
  my $amuabs = Xray::Absorption -> get_atomic_weight($abs);
  foreach my $kk (@k) {
    my ($barns, $amu) = (0,0);
    my $e = $groups{$current}->k2e($kk) + $groups{$current}->{bkg_e0} + $e0shift;
    foreach my $el (keys(%$rcount)) {
      ##next if (lc($el) eq lc(get_symbol($groups{$current}->{bkg_z})));
      $barns += Xray::Absorption -> cross_section($el, $e) * $$rcount{$el};
      $amu   += Xray::Absorption -> get_atomic_weight($el) * $$rcount{$el};
    };
    ## 1 amu = 1.6607143 x 10^-24 gm
    push @mua, $$rcount{$abs} * Xray::Absorption -> cross_section($abs, $e) / $amu / 1.6607143;
    push @mut, $barns / $amu / 1.6607143;
  };
  $groups{$current} -> dispose("## inserted s___a.mut and s___a.mua into ifeffit's memory...", $dmode);
  $groups{$current} -> dispose("## compute self absorption corrected data array using method of Booth and Bridges", $dmode);
  Ifeffit::put_array("s___a.mut", \@mut);
  Ifeffit::put_array("s___a.mua", \@mua);

  my $dd = $$rparams{thickness} * 10e-4;

#   my $avg = 0;
#   map { $avg += $_ } @mua;
#   $avg /= ($#mua + 1);
#   $groups{$current} -> dispose("set ___x = ceil($current.chi)", 1);
#   my $chimax = Ifeffit::get_scalar("___x");


  my $angle_ratio = sprintf("%.6f", sin(PI*$$rparams{angle_in}/180) / sin(PI*$$rparams{angle_out}/180));
  my $precmd = "set(s___a.alpha   = s___a.mut + $angle_ratio*$muf,\n";
  $precmd   .= "    s___a.exparg  = $dd*s___a.alpha/sin(pi*$$rparams{angle_in}/180),\n";
  $precmd   .= "    s___a.beta    = s___a.mua * exp(-1 * s___a.exparg) * s___a.exparg,\n";
  $precmd   .= "    s___a.gamma   = 1 - exp(-1 * s___a.exparg),\n";
  $precmd   .= "    s___a.term1   = s___a.gamma*(s___a.alpha - s___a.mua*($current.chi+1)) + s___a.beta,\n";
  $precmd   .= "    s___a.term2   = 4*s___a.alpha*s___a.beta*s___a.gamma*$current.chi,\n";
  $precmd   .= "    s___a.sqrtarg = s___a.term1**2 + s___a.term2)\n";


  $groups{$current} -> dispose($precmd, $dmode);
  $groups{$current} -> dispose("set(___x = floor(s___a.beta), ___xx = floor(s___a.sqrtarg))", 1);
  my $betamin = Ifeffit::get_scalar("___x");
  my $isneg = Ifeffit::get_scalar("___xx");
  my $thickcheck = ($betamin < 10e-7) || ($isneg < 0);
  my $message;

  my $cmd = "";
  if ($thickcheck > 0.005) {
    $widget{safluo_feedback} -> insert('end', "\nYou are in the thick sample limit.\nUsing the thick limit approximation.\n", ['margin']);
    $cmd .= "## thick limit\n";
    $cmd .= "set(s___a.s     = s___a.mua/s___a.alpha,\n";
    $cmd .= "    s___a.denom = (1 - s___a.s*($current.chi + 1)),\n";
    $cmd .= "    s___a.chi   = $current.chi / s___a.denom)\n";
    $message = "(thick sample limit)";
  } else {
    $widget{safluo_feedback} -> insert('end', "\nYou are in the thin sample regime.\nUsing the nearly exact expression.\n", ['margin']);
    $cmd .= "## thin regime\n";
    $cmd .= "set(s___a.chi    = (-1 * s___a.term1 + sqrt(s___a.sqrtarg)) / (2*s___a.beta))\n";
    $message = "(thin sample regime)";
  };

  $groups{$current} -> dispose($cmd, $dmode);

  my $str = 'k'.$plot_features{k_w};
  $groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
  my $color = $plot_features{c1};
  $groups{$current} -> dispose("plot($current.k, \"s___a.chi*$current.k**$plot_features{k_w}\", style=lines, color=\"$color\", key=\"SA corrected\")", $dmode);
  $last_plot='k';
  $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);

  $groups{$current} -> MAKE(formula=>$$rparams{formula});
  project_state(0);
  $widget{safluo_make} -> configure(-state=>'normal');

  Echo("Doing Booth/Bridges correction $message ... done!");
  $top -> Unbusy;
};


sub do_satroger {
  my $rparams = $_[0];
  Echo("Doing Troger et al. correction");
  $top -> Busy;

  my $e0shift = $groups{$current}->{bkg_eshift};
  my ($ok, $efluo, $rcount) = sa_feedback($rparams);
  unless ($ok) {
    Error("Error parsing formula.");
    $top -> Unbusy;
    return;
  };

  my ($barns, $amu) = (0,0);
  foreach my $el (keys(%$rcount)) {
    $barns += Xray::Absorption -> cross_section($el, $efluo) * $$rcount{$el};
    $amu   += Xray::Absorption -> get_atomic_weight($el) * $$rcount{$el};
  };
  my $muf = sprintf("%.6f", $barns / $amu / 1.6607143);
  my $angle_ratio = sprintf("%.6f", sin(PI*$$rparams{angle_in}/180) / sin(PI*$$rparams{angle_out}/180));

  my @k = Ifeffit::get_array($current.".k");
  my @mut = ();
  my @mua = ();
  my $abs = ucfirst( lc(get_symbol($groups{$current}->{bkg_z})) );
  foreach my $kk (@k) {
    my $barns = 0;
    my $e = $groups{$current}->k2e($kk) + $groups{$current}->{bkg_e0} + $e0shift;
    foreach my $el (keys(%$rcount)) {
      $barns += Xray::Absorption -> cross_section($el, $e) * $$rcount{$el};
    };
    ## 1 amu = 1.6607143 x 10^-24 gm
    push @mut, $barns / $amu / 1.6607143;
    push @mua, $$rcount{$abs} * Xray::Absorption -> cross_section($abs, $e) / $amu / 1.6607143;
  };
  $groups{$current} -> dispose("## compute self absorption corrected data array using method of Troger et al", $dmode);
  $groups{$current} -> dispose("## inserted s___a.mut and s___a.mua into ifeffit's memory...", $dmode);
  Ifeffit::put_array("s___a.mut", \@mut);
  Ifeffit::put_array("s___a.mua", \@mua);

  my $sets = "set(s___a.alpha = s___a.mut + $angle_ratio*$muf,";
  $sets   .= "    s___a.s     = s___a.mua / s___a.alpha,";
  $sets   .= "    s___a.chi   = $current.chi / (1 - s___a.s) )";
  $groups{$current} -> dispose($sets, $dmode);

  my $str = 'k'.$plot_features{k_w};
  $groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
  my $color = $plot_features{c1};
  $groups{$current} -> dispose("plot($current.k, \"s___a.chi*$current.k**$plot_features{k_w}\", style=lines, color=\"$color\", key=\"SA corrected\")", $dmode);
  $last_plot='k';
  $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);

  $groups{$current} -> MAKE(formula=>$$rparams{formula});
  project_state(0);
  $widget{safluo_make} -> configure(-state=>'normal');

  Echo("Doing Troger correction ... done!");
  $top -> Unbusy;
};



sub do_saatoms {
  my $rparams = $_[0];
  Echo("Doing Atoms correction");
  $top -> Busy;

  my $e0shift = $groups{$current}->{bkg_eshift};
  my ($ok, $efluo, $rcount) = sa_feedback($rparams);
  unless ($ok) {
    Error("Error parsing formula.");
    $top -> Unbusy;
    return;
  };

  my $mm_sigsqr = Xray::FluorescenceEXAFS->mcmaster($groups{$current}->{bkg_z},
						    $groups{$current}->{fft_edge});
  my $i0_sigsqr = Xray::FluorescenceEXAFS->i_zero($groups{$current}->{bkg_z},
						  $groups{$current}->{fft_edge},
						  {nitrogen=>1,argon=>0,krypton=>0});
  my ($self_amp, $self_sigsqr) = Xray::FluorescenceEXAFS->self($groups{$current}->{bkg_z},
							       $groups{$current}->{fft_edge},
							       $rcount);
  my $net = sprintf("%.6f", $self_sigsqr+$i0_sigsqr+$i0_sigsqr);

  my $answer .= sprintf("\nSelf amplitude : %6.3f\n",   $self_amp);
  $answer    .= sprintf("Self           : %8.5f A^2\n", $self_sigsqr);
  $answer    .= sprintf("Normalization  : %8.5f A^2\n", $mm_sigsqr);
  $answer    .= sprintf("I0             : %8.5f A^2\n", $i0_sigsqr);
  $answer    .= sprintf("   net sigma^2 : %8.5f A^2\n", $net);
  $widget{safluo_feedback} -> insert('end', $answer, ['margin']);

  $groups{$current} -> dispose("set(s___a.chi = $self_amp * $current.chi * exp($net*$current.k^2))", $dmode);
  my $str = 'k'.$plot_features{k_w};
  $groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
  my $color = $plot_features{c1};
  $groups{$current} -> dispose("plot($current.k, \"s___a.chi*$current.k**$plot_features{k_w}\", style=lines, color=\"$color\", key=\"SA corrected\")", $dmode);
  $last_plot='k';
  $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);

  $groups{$current} -> MAKE(formula=>$$rparams{formula});
  project_state(0);
  $widget{safluo_make} -> configure(-state=>'normal');

  Echo("Doing Atoms correction ... done!");
  $top -> Unbusy;
};




sub sa_group {
  my ($parent, $rparams) = @_;
  my ($group, $label) = ("SA ".$groups{$parent}->{label}, "");
  ($group, $label) = group_name($group);
  $label = "SA ".$groups{$parent}->{label};
  $groups{$group} = Ifeffit::Group -> new(group=>$group, label=>$label);
  ## copy the titles
  my $line = Xray::Absorption->get_Siegbahn_full($$rparams{line});
  my $method = "";
 SWITCH: {
    $method = "Haskel's Fluo",     last SWITCH if ($$rparams{algorithm} eq 'fluo');
    $method = "Booth and Bridges", last SWITCH if ($$rparams{algorithm} eq 'booth');
    $method = "Troger et al.",     last SWITCH if ($$rparams{algorithm} eq 'troger');
    $method = "correction terms from Atoms", last SWITCH if ($$rparams{algorithm} eq 'atoms');
  };
  push @{$groups{$group}->{titles}},
    "Self absorption correction of \"$groups{$parent}->{label}\" using method of $method";
  if ($$rparams{algorithm} eq 'booth') {
    push @{$groups{$group}->{titles}},
      "+  $groups{$parent}->{bkg_z} $groups{$parent}->{fft_edge} edge, computed using the $groups{$parent}->{bkg_z} $line line",
	"+  Formula=$$rparams{formula}, Thickness=$$rparams{thickness} microns",
	  "+  Incident angle=$$rparams{angle_in} degrees, Outgoing angle=$$rparams{angle_out} degrees";
  } else {
    push @{$groups{$group}->{titles}},
      "+  $groups{$parent}->{bkg_z} $groups{$parent}->{fft_edge} edge, computed using the $groups{$parent}->{bkg_z} $line line",
	"+  Formula=$$rparams{formula}, Incident/Outgoing angles: [$$rparams{angle_in}, $$rparams{angle_out}] degrees";
  };
  $groups{$group} -> make(file=>"Self absorption correction of \"$groups{$parent}->{label}\"");
  foreach (@{$groups{$parent}->{titles}}) {
    push   @{$groups{$group}->{titles}}, $_;
  };
  $groups{$group} -> put_titles;
  $groups{$group} -> set_to_another($groups{$parent});
  $groups{$group} -> make(is_rsp => 0, is_qsp => 0, is_bkg => 0, not_data => 0, bkg_eshift=>0);
  if ($$rparams{algorithm} eq 'fluo') {
    ## xanes correction
    $groups{$group} -> make(is_xmu => 1, is_chi => 0);
    $groups{$group} -> dispose("set($group.energy = s___a.energy, $group.xmu = s___a.sacorr)", $dmode);
  } else {
    ## exafs correction
    $groups{$group} -> make(is_xmu => 0, is_chi => 1);
    $groups{$group} -> dispose("set($group.k = $parent.k, $group.chi = s___a.chi)", $dmode);
  };
  ++$line_count;
  fill_skinny($list, $group, 1, 1);
  Echo("Saved absorption corrected data group.");
  my $memory_ok = $groups{$group} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};




## do some chores common to all algorithms
sub sa_feedback {
  my $rparams = $_[0];

  $widget{safluo_feedback} -> delete('1.0', 'end');
 SWITCH: {
    $$rparams{line} = 'Ka1', last SWITCH if (lc($groups{$current}->{fft_edge}) eq 'k');
    $$rparams{line} = 'La1', last SWITCH if (lc($groups{$current}->{fft_edge}) eq 'l3');
    $$rparams{line} = 'Lb1', last SWITCH if (lc($groups{$current}->{fft_edge}) eq 'l2');
    $$rparams{line} = 'Lb3', last SWITCH if (lc($groups{$current}->{fft_edge}) eq 'l1');
    $$rparams{line} = 'Ma',  last SWITCH if (lc($groups{$current}->{fft_edge}) =~ /^m/);
  };
  my $efluo = Xray::Absorption -> get_energy($groups{$current}->{bkg_z}, $$rparams{line});

  my %count;
  my $ok = parse_formula($$rparams{formula}, \%count);
  my $answer = "\nEdge energy = " . $groups{$current}->{bkg_e0} . $/;
  $answer   .= sprintf("The dominant fluorescence line is %s (%s)\n",
		       Xray::Absorption -> get_Siegbahn_full($$rparams{line}),
		       Xray::Absorption -> get_IUPAC($$rparams{line}));
  $answer   .= sprintf("Fluorescence energy = %.2f\n", $efluo);
  if ($ok) {
    $answer .= "\n  element   number \n";
    $answer .= " --------- ----------------\n";
    foreach my $k (sort (keys(%count))) {
      if ($count{$k} > 0.001) {
	$answer  .= sprintf("    %-2s %11.3f\n", $k, $count{$k});
      } else {
	$answer  .= sprintf("    %-2s      %g\n", $k, $count{$k});
      };
    };
    $widget{safluo_feedback} -> insert('end', $answer, ['margin']);
  } else {
    $widget{safluo_feedback} -> insert('end', "\nInput error:\n\t".$count{error}, ['error']);
    return
  };

  return ($ok, $efluo, \%count);
};

sub sa_info_depth {
  my $rparams = $_[0];
  Echo("Computing information depth");
  $top -> Busy;

  my $e0shift = $groups{$current}->{bkg_eshift};
  my ($ok, $efluo, $rcount) = sa_feedback($rparams);
  unless ($ok) {
    Error("Error parsing formula.");
    $top -> Unbusy;
    return;
  };

  my ($barns, $amu) = (0,0);
  foreach my $el (keys(%$rcount)) {
    $barns += Xray::Absorption -> cross_section($el, $efluo) * $$rcount{$el};
    $amu   += Xray::Absorption -> get_atomic_weight($el) * $$rcount{$el};
  };
  my $muf = sprintf("%.6f", $barns / $amu / 1.6607143);
  my $angle_ratio = sprintf("%.6f", sin(PI*$$rparams{angle_in}/180) / sin(PI*$$rparams{angle_out}/180));

  my @k = Ifeffit::get_array($current.".k");
  my $kmax = ($k[$#k] > $plot_features{kmax}) ? $plot_features{kmax} : $k[$#k];
  my @mut = ();
  foreach my $kk (@k) {
    my ($barns, $amu) = (0,0);
    my $e = $groups{$current}->k2e($kk) + $groups{$current}->{bkg_e0} + $e0shift;
    foreach my $el (keys(%$rcount)) {
      ##next if (lc($el) eq lc(get_symbol($groups{$current}->{bkg_z})));
      $barns += Xray::Absorption -> cross_section($el, $e) * $$rcount{$el};
      $amu   += Xray::Absorption -> get_atomic_weight($el) * $$rcount{$el};
    };
    ## 1 amu = 1.6607143 x 10^-24 gm
    push @mut, $barns / $amu / 1.6607143;
  };

  $groups{$current} -> dispose("## inserted s___a.mut into ifeffit's memory...", $dmode);
  Ifeffit::put_array("s___a.mut", \@mut);
  my $sets = "set(s___a.alpha = s___a.mut + $angle_ratio*$muf,";
  $sets   .= "    s___a.info = 10000*sin(pi*$$rparams{angle_in}/180) / s___a.alpha)";
  $groups{$current} -> dispose($sets, $dmode);
  my $command = "($current.k, s___a.info, xmin=$plot_features{kmin}, xmax=$kmax, ";
  $command   .= "xlabel=k (\\A\\u-1\\d), ylabel=\"Depth (\\gmm)\", ";
  my $screen = "fg=$config{plot}{fg}, bg=$config{plot}{bg}, ";
  $screen .= ($config{plot}{grid} eq $config{plot}{bg}) ? "nogrid, " :
    "grid, gridcolor=$config{plot}{grid}, ";
  $command   .= $screen;
  $command   .= "style=lines, color=blue, key=\"\\gl(k)\", title=\"Information Depth\")";
  $command    = wrap("newplot", "       ", $command) . $/;
  $groups{$current} -> dispose($command, $dmode);
  $top -> Unbusy;
  Echo("Computing information depth ... done!");
};


## END OF SELF-ABSORPTION SUBSECTION
##########################################################################################
