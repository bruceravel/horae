## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  data alignment.

## pop-up a palette for interactively aligning one scan ralative to
## another by comparing norm(E) or deriv(E)
sub align_two {
  Echo("No data!"), return unless $current;
  my %align_params;
  $align_params{space} = $_[0];
  $align_params{space} = ($align_params{space} eq 'x') ? 'em' : 'em'.$align_params{space};
  ($align_params{space} = 'emdsss') if ($align_params{space} eq 'ems');
  my $color = $plot_features{c1};

  ##Echo("You cannot align to the Default Parameters"), return
  Echo("No data!"), return if ($current eq "Default Parameters");

  my @keys = ();
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
  };
  Echo("You need two or more xmu groups to align"), return unless ($#keys >= 1);

  $align_params{fit} = $config{align}{fit} || 'd';
  $align_params{keys} = \@keys;
  $align_params{standard} = $keys[0];
  my $standard_lab = "1: " . $groups{$keys[0]}->{label};
  if ($align_params{standard} eq $current) {	# make sure $current is sensible given
    set_properties(1, $keys[1], 0);# that $keys[0] is the standard
    # adjust the view
    my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
    ($here < 0) and ($here = 0);
    my $full = ($list->bbox(@skinny_list))[3] + 5;
    $list -> yview('moveto', $here/$full);
  };

  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = $config{align}{emin};
  $plot_features{emax} = $config{align}{emax};
  project_state($ps);		# don't toggle if currently saved


  $align_params{shift} = $groups{$current}->{bkg_eshift};
  $align_params{prior_shift} = $groups{$current}->{bkg_eshift};

  $fat_showing = 'align';
  $hash_pointer = \%align_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $align = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$align -> packPropagate(0);
  $which_showing = $align;

  $align -> Label(-text=>"Data alignment",
		  -font=>$config{fonts}{large},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## select the alignment standard
  my $frame = $align -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -pady=>8);
  $frame -> Label(-text=>"Standard: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>0, -column=>0, -sticky=>'e', -ipady=>2);

  $widget{align_menu} = $frame -> BrowseEntry(-variable => \$standard_lab,
					      @browseentry_list,
					      -browsecmd => sub {
						my $text = $_[1];
						my $this = $1 if ($text =~ /^(\d+):/);
						Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless $this;
						$this -= 1;
						$align_params{standard}=$align_params{keys}->[$this];
						#$standard_lab="$groups{$s}->{label} ($s)";
						&do_eshift(\%align_params, $current);
					      })
    -> grid(-row=>0, -column=>1, -sticky=>'w');
  my $i = 1;
  foreach my $s (@keys) {
    $widget{align_menu} -> insert("end", "$i: $groups{$s}->{label}");
    ++$i;
  };

  ## the group for alignment is the current group in the group list
  $frame -> Label(-text=>"Other: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>1, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{align_unknown} = $frame -> Label(-text=>$groups{$current}->{label},
					   -foreground=>$config{colors}{button},
					  )
    -> grid(-row=>1, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);
  my $other_label;

  ## select the way to plot the data
  $frame -> Label(-text=>"Plot as: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>2, -column=>0, -sticky=>'e', -ipady=>2);
  my $space_label = 'xmu';
  ($space_label = 'normalized xmu')      if ($align_params{space} eq 'emn');
  ($space_label = 'derivative')          if ($align_params{space} eq 'emd');
  ($space_label = 'smoothed derivative') if ($align_params{space} eq 'emdsss');
  my $menu = $frame -> Optionmenu(-textvariable => \$space_label,
				  -borderwidth=>1,
				  -width=>19, -justify=>'right')
    -> grid(-row=>2, -column=>1, -sticky=>'w');
  foreach my $p (qw(em emn emd emdsss)) {
    my $label = 'xmu';
    ($label = 'normalized xmu')      if ($p eq 'emn');
    ($label = 'derivative')          if ($p eq 'emd');
    ($label = 'smoothed derivative') if ($p eq 'emdsss');
    $menu -> command(-label => $label,
		     -command=>sub{$align_params{space}=$p;
				   $space_label=$label;
				   &do_eshift(\%align_params, $current);
				 });
  };

  ## select the fitting function
  $frame -> Label(-text=>"Fit as: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>3, -column=>0, -sticky=>'e', -ipady=>2);
  my $fit_label = 'derivative';
  ($fit_label = 'smoothed derivative') if ($align_params{fit} eq 's');
  $menu = $frame -> Optionmenu(-textvariable => \$fit_label,
			       -borderwidth=>1,
			       -width=>19, -justify=>'right')
    -> grid(-row=>3, -column=>1, -sticky=>'w');
  foreach my $p (qw(d s)) {
    my $label = 'derivative';
    ($label = 'smoothed derivative') if ($p eq 's');
    $menu -> command(-label => $label,
				   -command=>sub{$align_params{fit}=$p;
						 $fit_label=$label;
					       });
  };


  $align -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');
  $align -> Button(-text=>'Return to the main window',  @button_list,
		   -background=>$config{colors}{background2},
		   -activebackground=>$config{colors}{activebackground2},
		   -command=>sub{$groups{$current} -> make(bkg_eshift=>$align_params{shift},
							   update_bkg=>1);
				 ## tie together data and reference
				 if ($groups{$current}->{reference} and exists($groups{$groups{$current}->{reference}})) {
				   $groups{$groups{$current}->{reference}} -> make(bkg_eshift=>$align_params{shift},
										   update_bkg=>1);
				 };
				 &reset_window($align, "alignment", \@save);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $align -> Button(-text=>'Document section: aligning data', @button_list,
		   -command=>sub{pod_display("process::align.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);



  ## frame with buttons in
  $frame = $align -> Frame(-borderwidth=>2, -relief=>'groove')
    -> pack(-side=>'bottom', -fill=>'x');

  my $bbox =  $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'bottom');

  my $lab =  $bbox -> Frame(-borderwidth=>2, -relief=>'flat')
    ->grid(-columnspan=>2, -row=>0, -column=>0, -padx=>2, -pady=>4, -sticky=>'ew');

  $widget{align_other_label} = $lab ->
    Label(
	  ##-text=>"Shift \"$groups{$current}->{label}\" by ",
	  -text=>"Shift by ",
	  -foreground=>$config{colors}{activehighlightcolor},
	 )
    -> pack(-side=>'left');
  $widget{align_result} = $lab -> RetEntry(-textvariable=>\$align_params{shift},
					   -validate=>'key',
					   -command=>sub{
					     $groups{$current} -> make(bkg_eshift=>$align_params{shift}, update_bkg=>1); # update object then plot
					     ## tie together data and reference
					     if ($groups{$current}->{reference} and exists($groups{$groups{$current}->{reference}})) {
					       $groups{$groups{$current}->{reference}} -> make(bkg_eshift=>$align_params{shift});
					     };
					   },
					   -validatecommand=>[\&set_variable, 'al_en'],
					   -width=>6)
    -> pack(-side=>'left');
  $lab -> Label(-text=>" eV.",
		-foreground=>$config{colors}{activehighlightcolor},)
    -> pack(-side=>'left');



  $widget{align_auto} = $bbox -> Button(-text=>"Auto align", @button_list,
					-command=>sub{Echo("Not aligning: \"$groups{$current}->{label}\" is a frozen group."), return if $groups{$current}->{frozen};
						      $align_params{shift} = auto_align($align_params{standard}, $current, $align_params{fit});
						      do_eshift(\%align_params, $current)})
    ->grid(-columnspan=>2, -row=>1, -column=>0, -padx=>2, -pady=>4, -sticky=>'ew');
  $widget{align_replot} = $bbox -> Button(-text=>"Replot", @button_list,
					  -command=>sub{do_eshift(\%align_params, $current)})
    ->grid(-columnspan=>2, -row=>2, -column=>0, -padx=>2, -pady=>4, -sticky=>'ew');

  my $row = 3;
  foreach my $e (5, 1, 0.5, 0.1) {
    $widget{"align_plus".$e} =
      $bbox -> Button(-text=>"-".$e, -width=>6, @button_list,
		      -command=>sub{Echo("Not aligning: \"$groups{$current}->{label}\" is a frozen group."), return if $groups{$current}->{frozen};
				    $align_params{shift} -= $e;
				    ($align_params{shift} = 0) if (abs($align_params{shift}) < EPSI);
				    do_eshift(\%align_params, $current)})
	->grid(-row=>$row, -column=>0, -padx=>2, -pady=>4);
    $widget{"align_minus".$e} =
      $bbox -> Button(-text=>"+".$e, -width=>6, @button_list,
		      -command=>sub{Echo("Not aligning: \"$groups{$current}->{label}\" is a frozen group."), return if $groups{$current}->{frozen};
				    $align_params{shift} += $e;
				    ($align_params{shift} = 0) if (abs($align_params{shift}) < EPSI);
				    do_eshift(\%align_params, $current)})
	->grid(-row=>$row, -column=>1, -padx=>2, -pady=>4);
    ++$row;
  };
  $widget{align_restore} =
    $bbox -> Button(-text=>"Restore value", @button_list,
		    -command=>sub{Echo("Not aligning: \"$groups{$current}->{label}\" is a frozen group."), return if $groups{$current}->{frozen};
				  $align_params{shift} = $align_params{prior_shift};
				  do_eshift(\%align_params, $current)})
      ->grid(-columnspan=>2, -row=>++$row, -column=>0, -padx=>2, -pady=>4, -sticky=>'ew');

  $widget{align_marked} =
    $bbox -> Button(-text=>"Align all\nmarked groups", @button_list,
		    -command=>sub{
		      Echonow("Aligning marked groups ...");
		      $top -> Busy;
		      foreach my $g (&sorted_group_list) {
			next unless $marked{$g};
			next if ($align_params{standard} eq $g);
			Echonow("Auto-aligning \"$groups{$g}->{label}\"");
			my $sh = auto_align($align_params{standard}, $g, $align_params{fit});
			$groups{$g} -> make(bkg_eshift=>$sh, update_bkg=>1); # update object then plot
			## tie together data and reference
			if ($groups{$g}->{reference} and exists($groups{$g}->{reference})) {
			  $groups{$groups{$g}->{reference}} -> make(bkg_eshift=>$sh);
			};
		      };
		      $align_params{shift} = $groups{$current}->{bkg_eshift};
		      do_eshift(\%align_params, $current);
		      $top -> Unbusy;
		      Echonow("Aligning marked groups ... done!");
		    })
      ->grid(-columnspan=>2, -rowspan=>2, -row=>1, -column=>2,
	     -padx=>12, -pady=>4, -sticky=>'new');

  do_eshift(\%align_params, $current);
  $plotsel -> raise('e');
  $top -> update;
};




## perform the e0 shift requested by the align_two subroutine and replot
sub do_eshift {
  my ($r, $gr) = @_;
  my ($sp, $st, $sh) = ($$r{space}, $$r{standard}, $$r{shift});

  Echo("Not aligning: \"$groups{$gr}->{label}\" is a frozen group.") if $groups{$gr}->{frozen};
  Error("Alignment aborted: " . $groups{$gr}->{label} . " is not an xmu group."),
    return unless ($groups{$gr}->{is_xmu});

  my $color = $plot_features{c1};
  my $scale = $groups{$gr}->{plot_scale};
  my $key   = $groups{$gr}->{label};
  my $other_string = q{};
 SWITCH: {
    ($sp eq 'emn')  and do {
      if ($groups{$gr}->{bkg_flatten}) {
	$other_string = "plot($gr.energy+$sh, $gr.flat, style=lines, color=$color, key=\"$key\")";
      } else {
	$other_string = "plot($gr.energy+$sh, $gr.norm, style=lines, color=$color, key=\"$key\")";
      };
      last SWITCH;
    };
    ($sp eq 'emd')  and do {
      $other_string = "plot($gr.energy+$sh, $scale*deriv($gr.xmu)/deriv($gr.energy), style=lines, color=$color, key=\"$key\")";
      last SWITCH;
    };
    ($sp eq 'emdsss')  and do {
      $other_string  = "set $gr.der = deriv(smooth(smooth(smooth($gr.xmu))))/deriv($gr.energy)\n";
      $other_string .= "plot($gr.energy+$sh, $scale*$gr.der, style=lines, color=$color, key=\"$key\")";
      last SWITCH;
    };
    ($sp eq 'em')  and do {
      $other_string = "plot($gr.energy+$sh, $gr.xmu, style=lines, color=$color, key=\"$key\")";
      last SWITCH;
    };
  };
  $groups{$gr} -> dispose("## aligning $gr to $st", $dmode);
  $groups{$gr} -> make(bkg_eshift=>$sh, update_bkg=>1); # update object then plot
  ## tie together data and reference
  if ($groups{$gr}->{reference} and exists($groups{$groups{$gr}->{reference}})) {
    $groups{$groups{$gr}->{reference}} -> make(bkg_eshift=>$sh);
  };
  if ($current eq $gr) {
    my $v = $groups{$gr}->{bkg_eshift};
    $widget{bkg_eshift} -> configure(-validate=>'none');
    $widget{bkg_eshift} -> delete(qw/0 end/);
    $widget{bkg_eshift} -> insert(0, $sh);
    $widget{bkg_eshift} -> configure(-validate=>'key');
    ##$widget{bkg_eshift} -> configure(-text=>$sh);
  };
  $groups{$st} -> plotE($sp,$dmode,\%plot_features, \@indicator);
  $groups{$gr} -> dispatch_bkg($dmode) if ($$r{space} eq 'emn');
  $groups{$gr} -> dispose($other_string, $dmode);
  $last_plot='e';
  ## keep detector groups aligned with their parent xmu group
  foreach my $g (@{$groups{$gr}->{detectors}}) {
    $groups{$g}->make(bkg_eshift=>$sh);
  };
  project_state(0);
  $top -> update;
};


## align two groups by computing a difference of derivative spectrum
## and minimizing an applied e0 shift
sub auto_align {
  my ($standard, $other, $how) = @_;
  return 0 if (($standard eq 'None') or ($other eq 'None'));

  $standard = $groups{$standard}->{group};
  my $st_e0 = $groups{$standard}->{bkg_eshift};
  my ($xmin, $xmax) = (int($groups{$standard}->{bkg_e0}-50),
		       int($groups{$standard}->{bkg_e0}+100));
  $other    = $groups{$other}->{group};
  my $ot_e0 = $groups{$other}->{bkg_eshift};
  my $command = "## auto aligning $other to $standard\n";
  $command   .= "guess(aa___esh=$ot_e0, aa___scale=1)\n";
  $command   .= "def($other.xmui = interp($other.energy+aa___esh, $other.xmu, $standard.energy+$st_e0),\n";
  if ($how eq 'd') {
    $command   .= "    aa___.res = deriv($standard.xmu)/deriv($standard.energy) - aa___scale*deriv($other.xmui)/deriv($other.energy))\n";
  } else {
    $command   .= "    aa___.res = smooth(smooth(smooth(deriv($standard.xmu)/deriv($standard.energy)))) - aa___scale*smooth(deriv($other.xmui)/deriv($other.energy)))\n";
  };
  $command   .= "minimize(aa___.res, x=$standard.energy, xmin=$xmin, xmax=$xmax)\n";
  $groups{$standard} -> dispose($command, $dmode); # do it
  my $esh = Ifeffit::get_scalar("aa___esh");
  ($esh=0) unless ($esh =~ /-?(\d+\.?\d*|\.\d+)/);
  $command    = "set(aa___.res = aa___.res, $other.xmui = $other.xmui)\n";
  $command   .= "unguess\n";
  $command   .= "erase aa___esh aa___scale aa___.res $other.xmui\n";
  $command   .= "## done auto aligning\n";
  $groups{$standard} -> dispose($command, $dmode); # clean up
  project_state(0);
  return sprintf("%.3f",$esh);	# return the e0 shift
};



## END OF DATA ALIGNMENT SUBSECTION
##########################################################################################
