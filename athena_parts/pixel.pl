## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  converting pixel data to energy

sub pixel {
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  my %pixel_params = (offset    => 0,
		      linear    => $config{pixel}{resolution},
		      quad      => 0,
		      constrain => 1,);

  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = $config{pixel}{emin};
  $plot_features{emax} = $config{pixel}{emax};


  my @keys = ();
  my $count_pixel = 0;
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
    ($pixel_params{standard} = $k) if (($k eq $current) and not $groups{$current}->{is_pixel});
    ++$count_pixel if ($groups{$k}->{is_pixel});
  };
  Echo("You need two or more xmu groups to do pixel to energy conversion"),
    return unless ($#keys >= 1);
  Echo("You need at least one pixel group to do pixel to energy conversion"),
    return unless ($count_pixel >= 1);

  $pixel_params{keys} = \@keys;
  $pixel_params{standard} ||= $keys[0];
  my $standard_lab = "1: ".$groups{$keys[0]}->{label};
  unless ($groups{$current}->{is_pixel}) {
    foreach my $k (&sorted_group_list) {
      if ($groups{$k}->{is_pixel}) {
	set_properties(1, $k, 0);
	last;
      };
    };
    # adjust the view
    my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
    ($here < 0) and ($here = 0);
    my $full = ($list->bbox(@skinny_list))[3] + 5;
    $list -> yview('moveto', $here/$full);
  };

  $fat_showing = 'pixel';
  $hash_pointer = \%pixel_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $pixel = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$pixel -> packPropagate(0);
  $which_showing = $pixel;

  $pixel -> Label(-text=>"Dispersive XAS: convert pixels to energy",
		  -font=>$config{fonts}{large},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');


  ## select the alignment standard
  my $frame = $pixel -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -ipady=>6);
  $widget{pixel_standard} = $frame -> Button(-text=>"Standard: ", @label_button,
					    -foreground=>$config{colors}{activehighlightcolor},
					    -activeforeground=>$config{colors}{activehighlightcolor},
					    -command=>[\&Echo, "The spectrum to which the pixel data will be aligned in energy."]
		  )
    -> grid(-row=>0, -column=>0, -sticky=>'e', -ipady=>2);

  my $menu = $frame -> BrowseEntry(-variable => \$standard_lab,
				   @browseentry_list,
				   -browsecmd => sub {
				     my $text = $_[1];
				     my $this = $1 if ($text =~ /^(\d+):/);
				     Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless $this;
				     $this -= 1;
				     $pixel_params{standard}=$pixel_params{keys}->[$this];
				     #$standard_lab="$groups{$s}->{label} ($s)";
				     &pixel_setup(\%pixel_params);
				   })
    -> grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'w');
  ##print join("\n",(($menu->children)[0]->children)[1]->children), $/;
  ##Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
  my $i = 1;
  foreach my $s (@keys) {
    $menu -> insert("end", "$i: $groups{$s}->{label}");
    ++$i;
  };



#   my $menu = $frame -> Optionmenu(-textvariable => \$standard_lab,
# 				  -borderwidth=>1, )
#     -> grid(-row=>0, -column=>1, -sticky=>'w');
#   foreach my $s (@keys) {
#     next if $groups{$s}->{is_pixel};
#     $menu -> command(-label => $groups{$s}->{label},
# 		     -command=>sub{$pixel_params{standard}=$s;
# 				   $standard_lab=$groups{$s}->{label};
# 				   &pixel_setup(\%pixel_params);
# 				 });
#   };

  ## the group for alignment is the current group in the group list
  $frame -> Button(-text=>"Other: ",
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   @label_button,
		   -command=>[\&Echo, "The group currently selected for alignment to the standard."]
		  )
    -> grid(-row=>1, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{pixel_unknown} = $frame -> Label(-text=>$groups{$current}->{label},
					   -foreground=>$config{colors}{button},
					   -width=>20)
    -> grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'w', -pady=>2, -padx=>2);
  my $other_label;

  $widget{pixel_refine} = $frame ->
    Button(-text=>'Refine alignment parameters', @button_list,
	   -command=>sub{
	     #pixel_refine(\%pixel_params, 1);
	     pixel_refine(\%pixel_params, 2);
	     #$widget{pixel_make} -> configure(-state=>'normal');
	   })
    -> grid(-row=>2, -column=>0, -columnspan=>3, -sticky=>'ew', -padx=>4);


  $frame -> Button(-text=>"Offset: ",
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   @label_button,
		   -command=>[\&Echo, "The constant term in the calibration refinement."])
    -> grid(-row=>3, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{pixel_offset} = $frame -> Entry(-width=>8,
					  -textvariable=>\$pixel_params{offset})
    -> grid(-row=>3, -column=>1, -sticky=>'w', -ipady=>2);
  $widget{pixel_constrain} = $frame ->
    Checkbutton(-text=>'constrain offset to linear term',
		-onvalue=>1, -offvalue=>0,
		-selectcolor=> $config{colors}{single},
		-variable=>\$pixel_params{constrain})
      -> grid(-row=>3, -column=>2, -sticky=>'w', -ipady=>2);

  $frame -> Button(-text=>"Linear: ",
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   @label_button,
		   -command=>[\&Echo, "The linear term in energy in the calibration refinement."])
    -> grid(-row=>4, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{pixel_linear} = $frame -> Entry(-width=>8,
					-textvariable=>\$pixel_params{linear})
    -> grid(-row=>4, -column=>1, -sticky=>'w', -ipady=>2);
  $widget{pixel_linear_button} = $frame -> Button(-text=>'Reset offset',
						  @button_list,
						  -command=>
						  sub {
						    my $stan  = $groups{$pixel_params{standard}}->{group};
						    $pixel_params{offset} = $groups{$stan}->{bkg_e0} - $groups{$current}->{bkg_e0}*$pixel_params{linear};
						  } )
    -> grid(-row=>4, -column=>2, -sticky=>'w', -ipady=>2, -padx=>4);


  $frame -> Button(-text=>"Quadratic: ",
		   -foreground=>$config{colors}{activehighlightcolor},
		   -activeforeground=>$config{colors}{activehighlightcolor},
		   @label_button,
		   -command=>[\&Echo, "The quadratic term in energy in the calibration refinement."])
    -> grid(-row=>5, -column=>0, -sticky=>'e', -ipady=>2);
  $widget{pixel_quad} = $frame -> Entry(-width=>8,
					-textvariable=>\$pixel_params{quad})
    -> grid(-row=>5, -column=>1, -sticky=>'w', -ipady=>2);


  $widget{pixel_replot} = $frame ->
    Button(-text=>'Replot standard and pixel data', @button_list,
	   -command=>sub{pixel_setup(\%pixel_params)},
	  )
    -> grid(-row=>6, -column=>0, -columnspan=>3, -sticky=>'ew', -padx=>4);
  $widget{pixel_make} = $frame ->
    Button(-text=>'Make data group', @button_list,
	   -command=>sub{&pixel_make_group(\%pixel_params)},)
    -> grid(-row=>7, -column=>0, -columnspan=>3, -sticky=>'ew', -padx=>4,);

  $widget{pixel_all} = $frame ->
    Button(-text=>'Convert all MARKED pixel groups', @button_list,
	   -command=>sub{&pixel_make_all(\%pixel_params)},)
    -> grid(-row=>8, -column=>0, -columnspan=>3, -sticky=>'ew', -pady=>3, -padx=>4);




  $pixel -> Button(-text=>'Return to the main window',  @button_list,
		   -background=>$config{colors}{background2},
		   -activebackground=>$config{colors}{activebackground2},
		   -command=>sub{foreach my $g (keys %groups) {	# clean up def-ed arrays
				   next unless $groups{$g}->{made_pixel};
				   $groups{$g}->make(made_pixel=>0);
				   $groups{$g}->dispose("erase $g.ec $g.xc", $dmode);
				   ##$groups{$g}->dispose("erase $g.xc", $dmode);
				 };
				 $groups{$current}->dispose("unguess", $dmode);
				 &reset_window($pixel, "dispersive XAS calibration", \@save);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $pixel -> Button(-text=>'Document section: converting pixel data to energy', @button_list,
		   -command=>sub{pod_display("process::pixel.pod")},)
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  &pixel_setup(\%pixel_params);
  $plotsel -> raise('e');
  $top -> update;
};


sub pixel_initial {
  my $rhash = $_[0];
  my $stan  = $groups{$$rhash{standard}}->{group};
  $$rhash{linear} ||= 0.4;
  $$rhash{quad}   ||= 0;
  $$rhash{offset} ||= $groups{$stan}->{bkg_e0} - $groups{$current}->{bkg_e0}*$$rhash{linear};
};

sub pixel_setup {
  my $rhash = $_[0];
  my $stan  = $groups{$$rhash{standard}}->{group};
  my $group = $groups{$current}->{group};
  $groups{$stan} ->dispatch_bkg if $groups{$stan} ->{update_bkg};
  $groups{$group}->dispatch_bkg if $groups{$group}->{update_bkg};
  &pixel_initial($rhash);
  my $command = "set(pixel___b=$$rhash{linear}, pixel___c=$$rhash{quad},\n";
  $command   .= "    pixel___a = $$rhash{offset})\n";
  $command   .= "def($group.ec = pixel___a + pixel___b*$group.energy + abs(pixel___c)*$group.energy**2,\n";
  $command   .= "    $group.xc = qinterp($group.ec, $group.flat, $stan.energy))\n";
  $groups{$current} -> dispose($command, $dmode);
  $groups{$current} -> make(made_pixel=>1);
  &pixel_plot($rhash);
};

sub pixel_refine {
  my $rhash = $_[0];
  my $order = $_[1];
  Echonow("Refining pixel calibration parameters ...");
  my $stan  = $groups{$$rhash{standard}}->{group};
  my $group = $groups{$current}->{group};
  $groups{$stan} ->dispatch_bkg if $groups{$stan} ->{update_bkg};
  $groups{$group}->dispatch_bkg if $groups{$group}->{update_bkg};
  my $e0 = $groups{$$rhash{standard}}->{bkg_e0};
  my $ee = $groups{$$rhash{standard}}->{bkg_e0} + 20;
  my $ed = $groups{$current}->{bkg_e0};
  my $command = "guess(pixel___b=$$rhash{linear}, pixel___c=$$rhash{quad})\n" if ($order == 2);
  if ($$rhash{constrain}) {
    $command   .= "def(pixel___a=$e0-pixel___b*$ed)\n";
  } else {
    $command   .= "guess(pixel___a=$$rhash{offset},)\n";
  };
  $command   .= "step $stan.energy $ee 0 p___ixel.step\n";
  $command   .= "set p___ixel.drop   = -1*(p___ixel.step - 1)\n";
  $command   .= "def(p___ixel.first  = $stan.flat*p___ixel.drop - $group.xc*p___ixel.drop,\n";
  $command   .= "    p___ixel.second = p___ixel.step * sqrt(abs($stan.energy-$e0)) * (($stan.flat-1) - ($group.xc-1)),\n";
  $command   .= "    p___ixel.diff   = p___ixel.first + p___ixel.second)\n";
  $command   .= "set(pixel___xmin = floor($group.ec),\n";
  $command   .= "    pixel___xmax = ceil($group.ec))\n";
  $command   .= "minimize(p___ixel.diff, x=$stan.energy, xmin=pixel___xmin, xmax=pixel___xmax)\n";
  ##$command   .= "minimize($group.diff)\n";
  $groups{$current} -> dispose($command, $dmode);
  $$rhash{offset} = sprintf("%.5f", Ifeffit::get_scalar("pixel___a"));
  $$rhash{linear} = sprintf("%.5f", Ifeffit::get_scalar("pixel___b"));
  $$rhash{quad}   = sprintf("%.5g", Ifeffit::get_scalar("pixel___c"));
  Echonow("Refining pixel calibration parameters ... replotting ...");
  &pixel_plot($rhash);
  Echo("Refining pixel calibration parameters ... replotting ... done!");
};

sub pixel_plot {
  my $rhash = $_[0];
  my $stan  = $groups{$$rhash{standard}}->{group};
  my $group = $groups{$current}->{group};
  $groups{$$rhash{standard}}->plotE('emn', $dmode, {emin=>$plot_features{emin},
						    emax=>$plot_features{emax},
						   }, \@indicator);
  my $fitcolor  = $config{plot}{c1};
  my $command = "plot($group.ec, $group.flat, style=lines, color=$fitcolor, key=$groups{$current}->{label})\n";
  $groups{$current} -> dispose($command, $dmode);
};

sub pixel_make_group {
  my $rhash = $_[0];
  my $stan  = $groups{$$rhash{standard}}->{group};
  my $was   = $groups{$current}->{group};
  (my $group = $groups{$current}->{label}) =~ s/_pixel/_data/;
  my ($new, $label) = group_name($group);
  $groups{$new} = Ifeffit::Group -> new(group=>$new, label=>$label);
  $groups{$new} -> set_to_another($groups{$$rhash{standard}});
  $groups{$new} -> make(is_xmu => 1, is_chi => 0, is_rsp => 0,
			is_qsp => 0, is_bkg => 0, is_pixel => 0,
			not_data => 0);
  $groups{$new} -> make(bkg_e0 => $groups{$$rhash{standard}}->{bkg_e0},
			file => $groups{$current}->{label} . " converted to energy",
		       );

  $groups{$new}->{titles} = [];
  push @{$groups{$new}->{titles}},
    ("Converted from pixel data $groups{$current}->{label}",
     "Calibrated to $groups{$$rhash{standard}}->{label}",
     "Offset: $$rhash{offset}",
     "Linear term: $$rhash{linear}",
     "Quadratic term: $$rhash{quad}");
  $groups{$new} -> put_titles;
  my $sets = "set($new.energy = $was.ec + " . $groups{$$rhash{standard}}->{bkg_eshift} . ",\n";
  $sets   .= "    $new.xmu = $was.xmu)";
  $groups{$new} -> dispose($sets, $dmode);

  my ($pre1, $pre2, $nor1, $nor2, $spl1, $spl2, $kmin, $kmax) =
    set_range_params($new);
  $groups{$new} -> make(
			bkg_pre1  => $pre1,
			bkg_pre2  => $pre2,
			bkg_nor1  => $nor1,
			bkg_nor2  => $nor2,
			bkg_spl1  => $spl1,
			bkg_spl2  => $spl2,
			bkg_spl1e => $groups{$new}->k2e($spl1),
			bkg_spl2e => $groups{$new}->k2e($spl2),
			fft_kmin  => $kmin,
			fft_kmax  => $kmax,
		       );
  $groups{$new} -> kmax_suggest(\%plot_features) if ($groups{$new}->{fft_kmax} == 999);

  $groups{$new} -> make(update_bkg => 1);
  ++$line_count;
  fill_skinny($list, $new, 1);
  my $memory_ok = $groups{$new}
    -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);

};

sub pixel_make_all {
  my $rhash = $_[0];
  my $m = 0;
  map {$m += $_} values %marked;
  Error("Batch conversion aborted.  There are no marked groups."),   return 1 unless ($m);
  ##Error("Merging aborted.  There is just 1 marked group."), return 1 if ($m==1);
  Echonow("Batch converting marked groups from pixel to energy ...");
  foreach my $g (&sorted_group_list) {
    next unless $marked{$g};
    next unless $groups{$g}->{is_pixel};
    set_properties(0, $g, 0);
    &pixel_make_group($rhash);
  };
  Echo("Batch converting marked groups from pixel to energy ... done!");
};
