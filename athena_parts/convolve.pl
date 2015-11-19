
## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This file contains the data convolution dialog



sub convolve {

  ## generally, we do not change modes unless there is data.
  ## exceptions include things like the prefernces and key bindings,
  ## which are data-independent
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");

  ## this is a way of testing the current list of data groups for some
  ## necessary property.  for the demo, this will just be the list of
  ## groups
  my @keys = ();
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
  };
  Echo("You need at least one xmu group to do convolution"), return unless (@keys);

  ## you must define a hash which will contain the parameters needed
  ## to perform the task.  the hash_pointer global variable will point
  ## to this hash for use in set_properties.  you might draw these
  ## values from configuration parameters
  my %conv_params;
  $conv_params{econv} = 0;
  $conv_params{noise} = 0;
  $conv_params{function} = "Lorentizan";
  $conv_params{current} = $groups{$current}->{label};


  ## The Athena standard for analysis chores that need a specialized
  ## plotting range is to save the plotting range from the main view
  ## and restore it when the main view is restored
  # my @save = ($plot_features{emin}, $plot_features{emax});
  # $plot_features{emin} = $config{foobar}{emin};
  # $plot_features{emax} = $config{foobar}{emax};

  ## these two global variables must be set before this view is displayed
  $fat_showing = 'convolve';
  $hash_pointer = \%conv_params;

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
  my $conv = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$conv -> packPropagate(0);
  ## global variable identifying which Frame is showing
  $which_showing = $conv;

  ## the standard label along the top identifying this analysis chore
  $conv -> Label(-text=>"Data convolution",
		   -font=>$config{fonts}{large},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## a good solution to organizing widgets is to stack frames, so
  ## let's make a frame for the standard and the other.  note that the
  ## "labels" are actually flat buttons which display hints in the
  ## echo area
  my $frame = $conv -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -pady=>8);
  $frame -> Label(-text=>"Group: ", -foreground => $config{colors}{button},)
    -> grid(-row=>0, -column=>0, -sticky=>'e', -pady=>2, -ipadx=>6);
  $frame -> Label(-textvariable=>\$conv_params{current},)
    -> grid(-row=>0, -column=>1, -sticky=>'w', -pady=>2);
  $frame -> Label(-text=>"Convolution function: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>1, -column=>0, -sticky=>'e', -pady=>2);
  $frame -> Optionmenu(-textvariable => \$conv_params{function},
		       -variable => \$conv_params{function},
		       -borderwidth=>1,
		       -options => ['Lorentzian', 'Gaussian'])
    -> grid(-row=>1, -column=>1, -sticky=>'w');

  $frame -> Label(-text=>"Convolution width: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>2, -column=>0, -sticky=>'e', -pady=>2);
  $widget{conv_econv} = $frame -> Entry(-width=>8,
					-textvariable => \$conv_params{econv},
					-validate=>'key',
					-validatecommand=>[\&set_variable, 'conv_econv']
				       )
    -> grid(-row=>2, -column=>1, -sticky=>'w', -pady=>2);

  $frame -> Label(-text=>"Noise (fraction of edge step): ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>3, -column=>0, -sticky=>'e', -pady=>2);
  $widget{conv_noise} = $frame -> Entry(-width=>8,
					-textvariable => \$conv_params{noise},
					-validate=>'key',
					-validatecommand=>[\&set_variable, 'conv_noise']
				       )
    -> grid(-row=>3, -column=>1, -sticky=>'w', -pady=>2);


#  $frame = $conv -> Frame(-borderwidth=>2, -relief=>'flat')
#    -> pack(-side=>'top', -fill=>'x', -pady=>4);
  $frame -> Button(-text=>'Plot data and convolution',  @button_list,
		   -width=>1,
		   -command=>sub{convolve_plot(\%conv_params)}
		  )
    -> grid(-row=>4, -column=>0, -columnspan=>2, -sticky=>'ew', -pady=>6);

  $widget{conv_group} = $frame -> Button(-text=>'Make data group',
					 -width=>1,
					 @button_list,
					 -state=>'disabled',
					 -command=>sub{convolve_group(\%conv_params)}
					)
    -> grid(-row=>5, -column=>0, -columnspan=>2, -sticky=>'ew', -pady=>2);

  ## this is a spacer frame which pushes all the widgets to the top
  $conv -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');


  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $conv -> Button(-text=>'Return to the main window',  @button_list,
		  -background=>$config{colors}{background2},
		  -activebackground=>$config{colors}{activebackground2},
		  -command=>sub{&reset_window($conv, "convolution", 0);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $conv -> Button(-text=>'Document section: Convoluting data', @button_list,
		   -command=>sub{pod_display("process::conv.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  ## and finally....
  $groups{$current}->plotE('emn', $dmode, \%plot_features, \@indicator);
  $top -> update;

};

sub convolve_plot {
  my $rhash = $_[0];
  Error("The convolution width must be positive."), return if ($$rhash{econv} < 0);
  Error("The noise level is a fraction of the edge step) and must be non-negative."), return if ($$rhash{noise} < 0);
  Echonow("Convoluting is time consuming (patience is a virtue!) ...");
  $top->Busy;
  my $group = $groups{$current}->{group};
  my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
  my $function = ($$rhash{function} eq 'Lorentzian') ? 'lconvolve' : 'gconvolve';
  my $color = $config{plot}{c1};
  my $key = 'convolution';
  my $eshift = $groups{$current}->{bkg_eshift};
  my $step = $groups{$current}->{bkg_step};
  my $yoff = $groups{$current}->{plot_yoffset};
  my $command = "## make convoluted spectrum:\n";
  if ($$rhash{noise}) {
    $command .= "set(c___onv_nn = npts($group.energy),\n";
    $command .= "    c___onv_noise = $$rhash{noise})\n";
    $command .= "random(output=$group.random, npts=c___onv_nn, dist=normal, sigma=c___onv_noise)\n";
    if ($$rhash{econv} == 0) {
      $command .= "set c___onv.y = $group.$suff+$group.random\n";
    } else {
      $command .= "set c___onv.y = $function($group.energy, $group.$suff, $$rhash{econv})+$group.random\n";
    };
  } else {
    if ($$rhash{econv} == 0) {
      $command .= "set c___onv.y = $group.$suff\n";
    } else {
      $command .= "set c___onv.y = $function($group.energy, $group.$suff, $$rhash{econv})\n";
    };
  };
  $command   .= "plot(\"$group.energy+$eshift\", \"c___onv.y+$yoff\",  key=$key, style=lines, color=$color)\n",
  $groups{$current}->plotE('emn', $dmode, \%plot_features, \@indicator);
  $groups{$current}->dispose($command, $dmode);
  $widget{conv_group}->configure(-state=>'normal');
  Echo("Convoluting ... done!");
  $top->Unbusy;
};



## make a new data group out of the convolved function, make this an
## xmu group so it can be treated like normal data
sub convolve_group {
  my $rhash = $_[0];
  my $group = $groups{$current}->{group};
  my ($new, $label) = group_name("Conv ".$$rhash{econv}." ".$group);
  $groups{$new} = Ifeffit::Group -> new(group=>$new,
					label=>"Conv " . $$rhash{econv} . $groups{$current}->{label});
  $groups{$new} -> set_to_another($groups{$group});
  $groups{$new} -> make(is_xmu => 1, is_chi => 0, is_rsp => 0,
			is_qsp => 0, is_bkg => 0, is_nor => 1,
			not_data => 0);
  $groups{$new} -> make(bkg_e0 => $groups{$group}->{bkg_e0});
  $groups{$new} -> make(file => "$$rhash{function} conv. of $groups{$current}->{label} by $$rhash{econv} volts with $$rhash{noise} noise");
  $groups{$new}->{titles} = [];
  push @{$groups{$new}->{titles}},
    "$$rhash{function} convolution of $groups{$current}->{label} by $$rhash{econv} volts",
      "with noise of $$rhash{noise} (compared to normalized spectrum)";
  $groups{$new} -> put_titles;
  my $sets = "set($new.energy = $group.energy,";
  $sets   .= "    $new.xmu = c___onv.y)";
  $groups{$new} -> dispose($sets, $dmode);
  ++$line_count;
  fill_skinny($list, $new, 1, 1);
  project_state(0);
  my $memory_ok = $groups{$new}
    -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo("WARNING: Ifeffit is out of memory!"), return if ($memory_ok == -1);
  Echo("Saved convolution of $groups{$current}->{label} as a new data group");
};


## END OF CONVOLUTION SUBSECTION
##########################################################################################
