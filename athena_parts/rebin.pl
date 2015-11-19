
## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  rebinning data.

sub rebin {

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

  ## you must define a hash which will contain the parameters needed
  ## to perform the task.  the hash_pointer global variable will point
  ## to this hash for use in set_properties.  you might draw these
  ## values from configuration parameters, as in the commented out
  ## example
  my %rebin_params;
  $rebin_params{abs}  = $groups{$current}->{bkg_z};
  $rebin_params{edge} = $groups{$current}->{bkg_e0};
  foreach (qw(emin emax pre exafs xanes)) {
    $rebin_params{$_}  = $config{rebin}{$_};
  };

  ## you probably do not want the standard and the unknown to be the
  ## same group
  # set_properties(1, $keys[1], 0) if ($current eq $keys[0]);

  ## you may wish to provide a better guess for which should be the
  ## standard and which the unknown.  you may also want to adjust the
  ## view of the groups list to show the unknown -- the following
  ## works...
  my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
  ($here < 0) and ($here = 0);
  my $full = ($list->bbox(@skinny_list))[3] + 5;
  $list -> yview('moveto', $here/$full);

  ## these two global variables must be set before this view is
  ## displayed.  these are used at the level of set_properties to
  ## perform chores appropriate to this dialog when changing the
  ## current group
  $fat_showing = 'rebin';
  $hash_pointer = \%rebin_params;

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
  my $rebin = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$foobar -> packPropagate(0);
  ## global variable identifying which Frame is showing
  $which_showing = $rebin;

  ## the standard label along the top identifying this analysis chore
  $rebin -> Label(-text=>"Data Rebinning",
		  -font=>$config{fonts}{large},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## a good solution to organizing widgets is to stack frames, so
  ## let's make a frame for the standard and the other.  note that the
  ## "labels" are actually flat buttons which display hints in the
  ## echo area
  my $frame = $rebin -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -pady=>4);

  $frame -> Label(-text=>"Group: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widget{rb_group} = $frame -> Label(-text=>$groups{$current}->{label},
				      -foreground=>$config{colors}{button})
    -> grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'w');

  $frame -> Label(-text=>'Edge energy:',
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $frame -> Label(-textvariable=>\$rebin_params{edge})
    -> grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'w', -padx=>2);

  $frame -> Label(-text=>'Edge region from:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin_params{emin},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>2, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>' to ',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>2);
  $frame -> Entry(-width=>5, -textvariable=>\$rebin_params{emax},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>2, -column=>3, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'eV',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>4);

  $frame -> Label(-text=>'Pre edge grid:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin_params{pre},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>3, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'eV',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>2, -sticky=>'w',);

  $frame -> Label(-text=>'XANES grid:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin_params{xanes},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>4, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'eV',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>4, -column=>2, -sticky=>'w',);

  $frame -> Label(-text=>'EXAFS grid:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>5, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin_params{exafs},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>5, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'1/Ang',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>5, -column=>2, -sticky=>'w',);

  $frame -> Label(-text=>" ")
      -> grid(-row=>6, -column=>0, -columnspan=>5, -sticky=>'ew',);

  $widget{rb_plot} =
    $frame -> Button(-text=>'Plot data and rebinned data',  @button_list,
		     -width=>1,
		     -state=>($groups{$current}->{is_xmu}) ? 'normal' : 'disabled',
		     -command=>sub{rebin_do(\%rebin_params)})
      -> grid(-row=>7, -column=>0, -columnspan=>5, -sticky=>'ew',);

  $widget{rb_save} = $frame -> Button(-text=>'Make rebinned data group',  @button_list,
				      -width=>1,
				      -state=>'disabled',
				      -command=>sub{rebin_group($current, \%rebin_params, $dmode)})
    -> grid(-row=>8, -column=>0, -columnspan=>5, -sticky=>'ew',);
  $widget{rb_marked} = $frame -> Button(-text=>'Rebin marked data and make groups',  @button_list,
					-width=>1,
					-command=>sub{
					  Echo("Rebinning marked groups ...");
					  $top -> Busy;
					  my $restore = $current;
					  foreach my $g (&sorted_group_list) {
					    next unless $marked{$g};
					    set_properties(0, $g, 0);
					    rebin_do(\%rebin_params);
					    rebin_group($current, \%rebin_params, $dmode)
					  };
					  set_properties(1, $restore, 0);
					  $top -> Unbusy;
					  Echo("Rebinning marked groups ... done!");
					  $top -> update;
					})
    -> grid(-row=>9, -column=>0, -columnspan=>5, -sticky=>'ew',);


  ## this is a spacer frame which pushes all the widgets to the top
  $rebin -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');

  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $rebin -> Button(-text=>'Return to the main window',  @button_list,
		   -background=>$config{colors}{background2},
		   -activebackground=>$config{colors}{activebackground2},
		   -command=>sub{$groups{$current}->dispose("erase \@group re___bin", $dmode);
				 &reset_window($rebin, "rebinning", 0);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $rebin -> Button(-text=>'Document section: rebinning data', @button_list,
		   -command=>sub{pod_display("process::rebin.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  $top -> update;

};


sub rebin_do {
  my $rparams = $_[0];
  $$rparams{emin}  ||= $config{rebin}{emin};
  $$rparams{emax}  ||= $config{rebin}{emax};
  $$rparams{pre}   ||= $config{rebin}{pre};
  $$rparams{xanes} ||= $config{rebin}{xanes};
  $$rparams{exafs} ||= $config{rebin}{exafs};
  ## these must be positive or bad stuff will happen
  $$rparams{pre}   = abs($$rparams{pre});
  $$rparams{xanes} = abs($$rparams{xanes});
  $$rparams{exafs} = abs($$rparams{exafs});
  ## check if emin, emax out of order
  (($$rparams{emin}, $$rparams{emax}) = ($$rparams{emax}, $$rparams{emin})) if
    ($$rparams{emin} > $$rparams{emax});

  my $group = $groups{$current}->{group};
  Echo("Rebinning data $groups{$group}->{label} ...");
  my $e0shift = $groups{$group}->{bkg_eshift};
  my @e = Ifeffit::get_array("$group.energy");
  my ($efirst, $elast) = ($e[0]+$e0shift, $e[$#e]+$e0shift);
  my $e0 = $groups{$current}->{bkg_e0};
  $groups{$group}->dispose("## Rebinning group $group:", $dmode);
  my @bingrid;
  my $ee = $efirst;
  while ($ee < $$rparams{emin}+$e0) {
    push @bingrid, $ee;
    $ee += $$rparams{pre};
  };
  $ee = $$rparams{emin}+$e0;
  while ($ee < $$rparams{emax}+$e0) {
    push @bingrid, $ee;
    $ee += $$rparams{xanes};
  };
  $ee = $$rparams{emax}+$e0;
  my $kk = $groups{$group}->e2k($$rparams{emax});
  while ($ee < $elast) {
    push @bingrid, $ee;
    $kk += $$rparams{exafs};
    $ee = $e0 + $groups{$group}->k2e($kk);
  };
  push @bingrid, $elast;
  Ifeffit::put_array("re___bin.energy", \@bingrid);
  my $sets = "set($group.eee = $group.energy+$e0shift,\n";
  $sets   .= "    re___bin.xmu = rebin($group.eee, $group.xmu, re___bin.energy)";
  $sets   .= ",\n    re___bin.i0  = rebin($group.eee, $group.i0,  re___bin.energy)"
    if ($groups{$group}->{i0});
  $sets   .= ")";
  $groups{$group}->dispose($sets, $dmode);
  $groups{$group} -> plotE('em', $dmode, \%plot_features, \@indicator);
  my $color = $plot_features{c1};
  $groups{$group} -> dispose("plot(re___bin.energy, re___bin.xmu, style=lines, color=\"$color\", key=rebinned)", $dmode);
  $last_plot='e';
  $widget{rb_save} -> configure(-state=>'normal');
  Echo("Rebinning data $groups{$group}->{label} ... done!");
};

sub rebin_group {
  my ($parent, $rparams, $mode) = @_;
  my ($group, $label) = ("Bin ".$groups{$parent}->{label}, "");
  ($group, $label) = group_name($group);
  my $e0shift = $groups{$parent}->{bkg_eshift};
  $groups{$group} = Ifeffit::Group -> new(group=>$group, label=>$label);
  ## copy the titles
  push @{$groups{$group}->{titles}},
    "$groups{$parent}->{label} rebinned onto a grid with boundaries at $$rparams{emin} eV and $$rparams{emax} eV",
      "and steps sizes of $$rparams{pre} eV, $$rparams{xanes} eV, and $$rparams{exafs} 1/Ang";
  $groups{$group} -> make(file=>"$groups{$parent}->{label} rebinned");
  foreach (@{$groups{$parent}->{titles}}) {
    push   @{$groups{$group}->{titles}}, $_;
  };
  $groups{$group} -> put_titles;
  $groups{$group} -> set_to_another($groups{$parent});
  $groups{$group} -> make(is_xmu => 1, is_chi => 0, is_rsp => 0, is_qsp => 0, is_bkg => 0,
			  not_data => 0,);
  my $sets = "set($group.energy = re___bin.energy-$e0shift,\n";
  $sets   .= "    $group.xmu = re___bin.xmu";
  $sets   .= ",\n    $group.i0 = re___bin.i0"
    if ($groups{$group}->{i0});
  $sets   .= ")";
  $groups{$group} -> dispose($sets, $dmode);

  ## rebin arrays for detector groups
  $groups{$group} -> make(numerator   => "$group.numer",
			  denominator => "$group.denom");
  my $cmd = "set(r___b.array = $groups{$parent}->{numerator},\n";
  $cmd   .= "    $group.numer = rebin($parent.energy, r___b.array, $group.energy),\n";
  $cmd   .= "    r___b.array = $groups{$parent}->{denominator},\n";
  $cmd   .= "    $group.denom = rebin($parent.energy, r___b.array, $group.energy))\n";
  $cmd   .= "erase r___b.array\n";
  $groups{$group} -> dispose($cmd,$dmode);

  ++$line_count;
  fill_skinny($list, $group, 1, 0);
  my $memory_ok = $groups{$group} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};

## END OF REBINNING SUBSECTION
##########################################################################################
