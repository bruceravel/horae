## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  smoothing data.



sub smooth {
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  my @keys = ();
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu}) and push @keys, $k;
  };
  my $g = ($groups{$current}->{is_xmu}) ? $current : $keys[0];
  my $g_label = $groups{$g}->{label};

  my $mode = 0;
  my $grey = '#9c9583';
  my $ahc  = $config{colors}{activehighlightcolor};
  my %smooth_params = (rmax=>$config{smooth}{rmax},
		       nit =>$config{smooth}{iterations});

  $fat_showing = 'smooth';
  $hash_pointer = \%smooth_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $sm = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$sm -> packPropagate(0);
  $which_showing = $sm;

  $sm -> Label(-text=>"Data smoothing",
	       -font=>$config{fonts}{large},
	       -foreground=>$ahc)
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  my $frame = $sm -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-ipadx=>3, -ipady=>3, -fill=>'x');  ## select the group to smooth
  my $fr = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -ipady=>3, -ipady=>3);
  $fr -> Label(-text=>"Group: ",
	       -foreground=>$config{colors}{activehighlightcolor},
	      )
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widget{sm_group} = $fr -> Label(-text=>$groups{$current}->{label},
				      -foreground=>$config{colors}{button})
    -> grid(-row=>0, -column=>1, -sticky=>'w');

  $sm -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');
  $sm -> Button(-text=>'Return to the main window',  @button_list,
		-background=>$config{colors}{background2},
		-activebackground=>$config{colors}{activebackground2},
		-command=>sub{&reset_window($sm, "smoothing", 0);})
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $sm -> Button(-text=>'Document section: data smoothing', @button_list,
		-command=>sub{pod_display("process::smooth.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  ## frame with widgets in
  $fr = $frame -> Frame()
    -> pack(-fill=>'both');
  ## choose smoothing method
  $widget{sm_it_button} =
  $fr ->
    Radiobutton(-text=>"Interpolative smoothing", -variable=>\$mode, -value=>0,
		-foreground=>$config{colors}{activehighlightcolor},
		-activeforeground=>$config{colors}{activehighlightcolor},
		-command=>sub{$widget{sm_it_lab}->configure(-foreground=>$ahc);
			      $widget{sm_it_ent}->configure(-state=>'normal');
			      $widget{sm_ff_lab}->configure(-foreground=>$grey);
			      $widget{sm_ff_ent}->configure(-state=>'disabled');
			    })
    -> grid(-row=>0, -column=>0, -ipady=>4);
  $widget{sm_it_lab} = $fr -> Label(-text=>"     ",)
    -> grid(-row=>0, -column=>1, -sticky=>'e');
  $widget{sm_it_lab} = $fr -> Label(-text=>"Number of iterations:",
				    -foreground=>$config{colors}{activehighlightcolor},
				   )
    -> grid(-row=>0, -column=>2, -sticky=>'e');
  $widget{sm_it_ent} = $fr -> NumEntry(-width=>4, -value=>10, -minvalue=>1,
				       -foreground=>$config{colors}{foreground})
    -> grid(-row=>0, -column=>3, -sticky=>'w');
  $widget{sm_ff_button} =
  $fr -> Radiobutton(-text=>"Fourier filter smoothing", -variable=>\$mode, -value=>1,
		     -foreground=>$config{colors}{activehighlightcolor},
		     -activeforeground=>$config{colors}{activehighlightcolor},
		     -command=>sub{$widget{sm_it_lab}->configure(-foreground=>$grey);
				   $widget{sm_it_ent}->configure(-state=>'disabled');
				   $widget{sm_ff_lab}->configure(-foreground=>$ahc);
				   $widget{sm_ff_ent}->configure(-state=>'normal');
				 })
    -> grid(-row=>1, -column=>0, -ipady=>4);
  $widget{sm_ff_lab} = $fr -> Label(-text=>"Rmax:",
				    -foreground=>$grey,
				   )
    -> grid(-row=>1, -column=>2, -sticky=>'e');
  $widget{sm_ff_ent} = $fr -> Entry(-width=>8, )
    -> grid(-row=>1, -column=>3, -sticky=>'w');

  ## buttons for doing smoothing and making smoothed group
  $fr = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -padx=>2, -pady=>2, -ipadx=>2, -ipady=>2);
  $widget{sm_plot} =
    $fr -> Button(-text=>'Plot data and smoothed spectrum',  @button_list,
		  -width=>1,
		  -command=>sub{&do_smoothing($current, $mode, $widget{sm_it_ent}->get,
					      $widget{sm_ff_ent}->get);
				$widget{sm_save} -> configure(-state=>'normal'); })
    -> pack(-fill=>'x', -expand=>1, -side=>'left');
  $widget{sm_save} = $fr -> Button(-text=>'Make smoothed data group',  @button_list,
				   -width=>1,
				   -state=>'disabled',
				   -command=>sub{&smooth_group($current, $mode,
							       $widget{sm_it_ent}->get,
							       $widget{sm_ff_ent}->get)})
    -> pack(-fill=>'x', -expand=>1, -side=>'left');

  $widget{sm_ff_ent} -> insert(0, '6');
  $widget{sm_ff_ent} -> configure(-state=>'disabled');

  $plotsel -> raise('e');
};


sub do_smoothing {
  my ($group, $mode, $nit, $rmax) = @_;
  Error("Smoothing aborted: " . $groups{$group}->{label} . " is not an xmu group."),
    return unless ($groups{$group}->{is_xmu});
  my $e0shift = $groups{$group}->{bkg_eshift};

 SWITCH: {
    ($mode == 0) and do {	# interpolative
      $groups{$group} -> dispose("set $group.smoothed = $group.xmu", $dmode);
      foreach (1 .. $nit) {
	$groups{$group} -> dispose("set $group.temp = smooth($group.smoothed)  # $_", $dmode);
	$groups{$group} -> dispose("set $group.smoothed = $group.temp", $dmode);
	$groups{$group} -> dispose("erase $group.temp", $dmode);
	Echo("Smoothed $groups{$group}->{label} using $nit smoothing iterations");
      };
      last SWITCH;
    };
    ($mode == 1) and do {	# Fourier filter
      $groups{$group} -> dispose("min_e = floor($group.energy)", $dmode);
      $groups{$group} -> dispose("set tem___p.k  = sqrt(($group.energy + $e0shift - min_e)*etok)", $dmode);
      $groups{$group} -> dispose("set max_k = ceil(tem___p.k)", $dmode);
      $groups{$group} -> dispose("set tem___p.kk = range(0, max_k, 0.01)", $dmode);
      $groups{$group} -> dispose("set tem___p.xk = interp(tem___p.k, $group.xmu, tem___p.kk)",
				 $dmode);
      ## build a symmetric function by doing a mirror transform at the end
      ## of the data range
      my @xarr = get_array("tem___p.kk");
      my @x = ();
      push @x, @xarr;
      map {push @x, $xarr[$#xarr]+$_} @xarr; # this doubles the x-axis grid

      my @backhalf = get_array("tem___p.xk");
      my @y = ();
      push @y, @backhalf;
      @backhalf = reverse @backhalf;
      push @y, @backhalf; # this is the data + the mirror of the data

      ## stuff the mirrored data back into ifeffit
      put_array("tem___p.x", \@x);
      put_array("tem___p.y", \@y);

      $groups{$group} -> dispose("## put mirrored arrays back into Ifeffit's memory ...", $dmode);
      $groups{$group} -> dispose("fftf(tem___p.y, k=tem___p.x, kmin=0, kmax=2*max_k, dk=0)", $dmode);
      #$groups{$group} -> dispose("show \@group tem___p", $dmode);
      $groups{$group} -> dispose("fftr(real=tem___p.chir_re, imag=tem___p.chir_im, rmin=0, rmax=$rmax, dr=0)", $dmode);
      $groups{$group} -> dispose("set $group.smoothed = interp(tem___p.q, tem___p.chiq_re, tem___p.k)", $dmode);
      $groups{$group} -> dispose("erase \@group tem___p", $dmode);
      Echo("Smoothed $groups{$group}->{label} by Fourier filtering to $rmax Angstroms");
      last SWITCH;
    };
  };
  ## plot it up
  $groups{$group} -> plotE('em', $dmode, \%plot_features, \@indicator);
  my $color = $plot_features{c1};
  $groups{$group} -> dispose("plot(\"$group.energy+$e0shift\", $group.smoothed, style=lines, color=\"$color\", key=smoothed)", $dmode);
  $last_plot='e';
};


sub smooth_group {
  my ($parent, $mode, $nit, $rmax) = @_;
  my ($group, $label) = ("SM ".$groups{$parent}->{label}, "");
  ($group, $label) = group_name($group);
  $groups{$group} = Ifeffit::Group -> new(group=>$group, label=>$label);
  ## copy the titles
  if ($mode == 0) {
    push @{$groups{$group}->{titles}},
      "$groups{$parent}->{label} smoothed by interpolative smoothing with $nit iterations";
    $groups{$group} -> make(file=>"$groups{$parent}->{label} smoothed by interpolative smoothing with $nit iterations");
  } elsif ($mode == 1) {
    push @{$groups{$group}->{titles}},
      "$groups{$parent}->{label} smoothed by Fourier filtering to $rmax Angstroms";
    $groups{$group} -> make(file=>"$groups{$parent}->{label} smoothed by Fourier filtering to $rmax Angstroms");
  };
  foreach (@{$groups{$parent}->{titles}}) {
    push   @{$groups{$group}->{titles}}, $_;
  };
  $groups{$group} -> put_titles;
  $groups{$group} -> set_to_another($groups{$parent});
  $groups{$group} -> make(is_xmu => 1, is_chi => 0, is_rsp => 0, is_qsp => 0, is_bkg => 0,
			  not_data => 0,);
  $groups{$group} -> dispose("set($group.energy = $parent.energy, $group.xmu = $parent.smoothed)", $dmode);
  $groups{$group} -> dispose("erase $parent.smoothed", $dmode);
  ++$line_count;
  fill_skinny($list, $group, 1);
  my $memory_ok = $groups{$group} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};



## END OF DATA SMOOTHING SUBSECTION
##########################################################################################
