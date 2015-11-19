#! /usr/bin/perl -w

## ===========================================================================
##  This is the formulas portion of hephaestus

sub formulas {
  $periodic_table -> packForget() if $current =~ /$uses_periodic_regex/;
  switch({page=>"formulas", text=>'Absorption Lengths of Compounds'});
};


sub setup_formulas {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  $data{form_energy} ||= 9000;

  my $left = $frame -> Frame()
    -> pack(-side=>'left', -expand=>1, -fill=>'both');
  my $right = $frame -> Frame()
    -> pack(-side=>'right', -expand=>1, -fill=>'both', -pady=>2, -padx=>6);

  my $labframe = $left -> LabFrame(-label=>'Known materials',
				   -labelside=>'acrosstop', @label_args)
    -> pack(-expand=>1, -fill=>'both');
  $data{form_lb} = $labframe
    -> Scrolled('Listbox',
		-font	    => $config{fonts}{small},
		-selectmode => 'single',
		-scrollbars => 'e',
		-width	    => 25,
		-height	    => 10)
      -> pack(-expand=>1, -fill=>'both');
  $data{form_lb} -> Subwidget("yscrollbar") -> configure(-background=>$bgcolor);
  BindMouseWheel($data{form_lb});

  $data{form_lb} -> insert('end', '-- none --');

  my $userformulas = Ifeffit::FindFile->find("hephaestus", "data");
  tie %userformulas, 'Config::IniFiles', (-file=>$userformulas) if (-e $userformulas);
  foreach my $s (sort(keys %formula)) {
    next if ($s eq '^^^^');
    $data{form_lb} -> insert('end', $s);
  };

  $data{form_lb} -> bind('<ButtonRelease-1>' =>
	      sub{
		my $s = $data{form_lb}->get('active');
		(($data{form_name}, $data{form_string}, $data{form_density}) =
		 ("", "", "")), return if ($s =~ /none/);
		$data{form_name}    = $s;
		$data{form_type}    = "Density";
		$data{form_string}  = $formula{$s};
		$data{form_density} = $density{$s};
	      });


  my $frm = $right -> Frame()
    -> pack(-side=>'top', -anchor=>'w', -padx=>8);
  $frm -> Label(-text=>'Formula:', @label_args)
    -> grid(-row=>0, -column=>0, -sticky=>'w');
  $data{form_formula_entry} =
    $frm -> Entry(-width=>35, -textvariable=>\$data{form_string})
      -> grid(-row=>0, -column=>1, -sticky=>'w', -columnspan=>4, -padx=>2);

  $data{form_type} = 'Density';
  $frm -> Optionmenu(-options	       => ['Density', 'Molarity'],
		     -command	       => sub{$data{form_density_units} -> configure(-text=>($data{form_type} eq 'Density') ? 'gram/cm^3' : 'mole/liter');
					      $data{form_density}="";
					      if ($data{form_type} eq 'Density') {
						$data{form_add_button}    -> configure(-state=>'normal');
						$data{form_remove_button} -> configure(-state=>'normal');
					      } else {
						$data{form_add_button}    -> configure(-state=>'disabled');
						$data{form_remove_button} -> configure(-state=>'disabled');
					      };
					    },
		     -textvariable     => \$data{form_type},
		     -font             => $config{fonts}{smbold},
		     -foreground       => 'blue4',
		     -activeforeground => 'blue4',
		     -borderwidth      => 1,)
    -> grid(-row=>1, -column=>0, -sticky=>'w');
  $data{form_density_entry} =
    $frm -> Entry(-width=>7, -font=>$config{fonts}{smfixed}, -textvariable=>\$data{form_density},
		  -validate=>'key', -validatecommand=>\&set_variable)
    -> grid(-row=>1, -column=>1, -sticky=>'w', -padx=>2);
  $data{form_density_units} = $frm -> Label(-text=>'gram/cm^3', @label_args)
    -> grid(-row=>1, -column=>2, -sticky=>'w');
  $data{form_add_button} = $frm -> Button(-text=>'Add', @button_args,
					  -command=>\&user_formulas_add)
    -> grid(-row=>1, -column=>3, -sticky=>'e', -pady=>2);
  $data{form_remove_button} = $frm -> Button(-text=>'Remove', @button_args,
					     -command=>\&user_formulas_remove)
    -> grid(-row=>1, -column=>4, -sticky=>'e', -pady=>2);

  $data{form_energy_label} = $frm -> Label(-text=>'Energy:', @label_args)
    -> grid(-row=>2, -column=>0, -sticky=>'w');
  $data{form_energy_entry} =
    $frm -> Entry(-width=>7, -font=>$config{fonts}{smfixed}, -textvariable=>\$data{form_energy},
		  -validate=>'key', -validatecommand=>\&set_variable)
      -> grid(-row=>2, -column=>1, -sticky=>'w', -padx=>2);
  $data{form_energy_units}= $frm -> Label(-text=>'eV', @label_args)
    -> grid(-row=>2, -column=>2, -sticky=>'w');

  $frm -> Button(-text=>'Compute', @button_args,
		 -width=>9,
		 -command=>\&get_formula_data)
    -> grid(-row=>3, -column=>0, -columnspan=>5, -sticky=>'ew', -pady=>4);


  $labframe = $right -> LabFrame(-label=>'Results',
				 -labelside=>'acrosstop', @label_args)
    -> pack(-expand=>1, -fill=>'both');
#  $right -> Button(-text=>'Plot information depth', @button_args,
#		   -width=>9,
#		   -command=>\&plot_information_depth)
#    -> pack(-fill=>'x');

  $data{form_results} = $labframe -> Scrolled("ROText",
					      -scrollbars=>'osoe',
					      -height=>1, -width=>1,
					      -relief=>'sunken',
					      -wrap=>'none',
					      -font=>$config{fonts}{smfixed},
					     )
    -> pack(-fill=>'both', -expand=>1);
  $data{form_results} -> Subwidget("xscrollbar") -> configure(-background=>$bgcolor);
  $data{form_results} -> Subwidget("yscrollbar") -> configure(-background=>$bgcolor);
  $data{form_results} -> tagConfigure('margin',   -lmargin1=>4, -lmargin2=>4);
  $data{form_results} -> tagConfigure('molarity', -lmargin1=>4, -lmargin2=>4, -foreground=>'blue4');
  $data{form_results} -> tagConfigure('error',    -lmargin1=>4, -lmargin2=>4, -foreground=>'red3');
  $data{form_results} -> tagConfigure('xsec',     -lmargin1=>4, -lmargin2=>4, -foreground=>'black');
  ## disable mouse-3
  my @swap_bindtags = $data{form_results}->Subwidget('rotext')->bindtags;
  $data{form_results}->Subwidget('rotext') -> bindtags([@swap_bindtags[1,0,2,3]]);
  $data{form_results}->Subwidget('rotext') -> bind('<Button-3>' => sub{$_[0]->break});

  $data{form_formula_entry} -> bind("<KeyPress-Return>"=>\&get_formula_data);
  $data{form_density_entry} -> bind("<KeyPress-Return>"=>\&get_formula_data);
  $data{form_energy_entry}  -> bind("<KeyPress-Return>"=>\&get_formula_data);

  return $frame;
};


sub get_formula_data {
  if ((lc($data{resource}) eq "henke") and ($data{form_energy} > 30000)) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'info',
		     -text           => "The Henke tables only include data up to 30 keV.",
		     -title          => 'Hephaestus warning',
		     -buttons        => [qw/OK/],
		     -default_button => 'OK')
	-> Show();
    return;
  };
  $data{form_results} -> delete(qw/1.0 end/);
  my %count;
  unless ($data{form_string}) {
    $data{form_results} -> insert('end', "\nNo formula.\n", ['error']);
    return;
  };
  $data{form_density} ||= 0;
  if (($data{form_type} eq 'Molarity') and not ($data{form_density} > 0)) {
    $data{form_results} -> insert('end', "\nMolarity was not given.\n", ['error']);
    return;
  };

  my @edges = ();

  my $ok = parse_formula($data{form_string}, \%count);
  my $energy  = ($data{units} eq 'Energies') ? $data{form_energy} : e2l($data{form_energy});
  my $units   = ($data{units} eq 'Energies') ? 'eV' : 'Å';
  my $density = $data{form_density};
  if ($data{form_type} eq 'Molarity') {
    ## 1 mole is 6.0221415 x 10^23 particles
    ## 1 amu = 1.6605389 x 10^-24 gm
    ## mole*amu = 1 gram/amu  wow!
    $density = 0;
    foreach my $k (keys(%count)) {
      $density += Xray::Absorption -> get_atomic_weight($k) * $count{$k};
    };
    ## number_of_amus * molarity(moles/liter) * 1 gram/amu = density of solute
    $density *= $data{form_density};
  };
  # molarity is moles/liter, density is g/cm^3, 1000 is the conversion
  # btwn liters and cm^3
  ($density /= 1000) if ($data{form_type} eq 'Molarity');
  if ($ok) {
    my ($weight, $xsec, $answer, $dens) = (0,0,"\n",$density);
    #$dens = ($density =~ /^(\d+\.?\d*|\.\d+|\d\.\d+[eEdD][-+]?\d+)$/) ? $density : 0;
    $dens = ($density > 0) ? $density : 0;
    $answer .= "  element   number   barns/atom     cm^2/gm\n";
    $answer .= " --------- ----------------------------------\n";
    my ($barns_per_formula_unit, $amu_per_formula_unit) = (0,0);  # 1.6607143
    foreach my $k (sort (keys(%count))) {
      $weight  += Xray::Absorption -> get_atomic_weight($k) * $count{$k};
      my $scale = Xray::Absorption -> get_conversion($k);
      my $this = Xray::Absorption -> cross_section($k, $energy, $data{xsec});
      $barns_per_formula_unit += $this * $count{$k};
      $amu_per_formula_unit += Xray::Absorption -> get_atomic_weight($k) * $count{$k};
      if ($count{$k} > 0.001) {
	$answer  .= sprintf("    %-2s %11.3f %11.3f  %11.3f\n",
			    $k, $count{$k}, $this, $this/$scale);
      } else {
	$answer  .= sprintf("    %-2s      %g      %g      %g\n",
			    $k, $count{$k}, $this, $this/$scale);
      };
      ## notice if any of this atoms edges are within 100 eV of the given energy
      foreach my $edge (qw(k l1 l2 l3)) {
	my $enot = Xray::Absorption -> get_energy($k, $edge);
	push @edges, [$k, $edge] if (abs($enot - $data{form_energy}) < 100);
      };
    };
    ## 1 amu = 1.6605389 x 10^-24 gm
    $xsec = $barns_per_formula_unit / $amu_per_formula_unit / 1.6605389;
    $answer .= sprintf("\nThis weighs %.3f amu.\n", $weight);
    if ($xsec == 0) {
      $answer .= "\n(Energy too low or not provided.\n Absorption calculation skipped.)";
    } else {
      my $xx = $xsec;
      $xsec *= $dens;
      if ($xsec > 0) {
	if (10000/$xsec > 1500) {
	  $answer .=
	    sprintf("\nAbsorbtion length = %.3f cm at %.2f %s",
		    1/$xsec, $data{form_energy}, $units);
	  $answer .= ($data{form_type} eq 'Molarity') ? "\nfor a $data{form_density} molar sample.\n" : ".\n";
	  $answer .=
	    sprintf("\nA sample of 1 absorption length with area of\n1 square cm requires %.3f milligrams of sample\nat %.2f %s\n",
	  	    1000*$density/$xsec, $data{form_energy}, $units) if ($data{form_type} eq 'Density');
	} elsif (10000/$xsec > 500) {
	  $answer .=
	    sprintf("\nAbsorbtion length = %.3f cm at %.2f %s",
		    1/$xsec, $data{form_energy}, $units);
	  $answer .= ($data{form_type} eq 'Molarity') ? "\nfor a $data{form_density} molar sample.\n" : ".\n";
	  $answer .=
	    sprintf("\nA sample of 1 absorption length with area of\n1 square cm requires %.3f miligrams of sample\nat %.2f %s.\n",
	  	    1000*$density/$xsec, $data{form_energy}, $units) if ($data{form_type} eq 'Density');
	} else {
	  $answer .=
	    sprintf("\nAbsorbtion length = %.1f micron at %.2f %s",
		    10000/$xsec, $data{form_energy}, $units);
	  $answer .= ($data{form_type} eq 'Molarity') ? "\nfor a $data{form_density} molar sample.\n" : ".\n";
	  $answer .=
	    sprintf("\nA sample of 1 absorption length with area of\n1 square cm requires %.3f miligrams of sample\nat %.2f %s.\n",
		    1000*$density/$xsec, $data{form_energy}, $units) if ($data{form_type} eq 'Density');
	}
      } else {
	$answer .=
	  "\n(The absorption length calculation\n requires a value for density.)";
	$answer .=
	  sprintf("\n\nA sample of 1 absorption length with area of\n1 square cm requires %.3f miligrams of sample\nat %.2f %s.\n",
		  1000/$xx, $data{form_energy}, $units);
      };
    };
    ## compute unit edge step lengths for all the relevant edges in this material
    foreach my $e (@edges) {
      my $enot = Xray::Absorption -> get_energy(@$e);
      my @abovebelow = ();
      foreach my $step (-50, +50) {
	my ($bpfu, $apfu) = (0, 0);
	my $energy = $enot + $step;
	foreach my $k (keys(%count)) {
	  my $this = Xray::Absorption -> cross_section($k, $energy, "full");
	  $bpfu   += $this * $count{$k};
	  $apfu   += Xray::Absorption -> get_atomic_weight($k) * $count{$k};
	};
	## 1 amu = 1.6605389 x 10^-24 gm
	push @abovebelow, $bpfu / $apfu / 1.6605389;
      };
      my $xabove = $abovebelow[1] * $density;
      my $xbelow = $abovebelow[0] * $density;
      my $step   = 10000 / ($xabove - $xbelow);
      $answer .= sprintf "\nUnit edge step length at %s %s edge (%.1f eV)\nis %.1f microns\n",
	ucfirst($e->[0]), uc($e->[1]), $enot, $step;
    };

    $data{form_results} -> insert('end', $answer, ['margin']);
    if ($data{form_type} eq 'Molarity') {
      $data{form_results} -> insert('end', "\n\nRemember that a molarity calculation only\nconsiders the absorption of the solute.\nThe solvent also absorbs.",
				    ['molarity']);
    };
    my $which = "photoelectric";
    if ((lc($data{resource}) eq "mcmaster") or (lc($data{resource}) eq "elam")) {
      ($which = "total")      if ($data{xsec} eq "full");
      ($which = $data{xsec})  if ($data{xsec} =~ /coherent/);
    } elsif (lc($data{resource}) eq "chantler") {
      ($which = "total")      if ($data{xsec} eq "full");
      ($which = "scattering") if ($data{xsec} =~ /coherent/);
    };
    $data{form_results} -> insert('end', "\n\nThe $data{resource} database and the $which cross-sections\nwere used in the calculation.",
				  ['xsec']);
  } else {
    $data{form_results} -> insert('end', "\nInput error:\n\t".$count{error}, ['error']);
  };
  $data{form_results} -> yviewMoveto(1);
};


##  algorithm for finding unit edge step length
##
## foreach my $e (-50, +50) {
##   my $energy = $enot + $e;
##   foreach my $k (sort (keys(%count))) {
##     $weight  += Xray::Absorption -> get_atomic_weight($k) * $count{$k};
##     my $scale = Xray::Absorption -> get_conversion($k);
##     my $this = Xray::Absorption -> cross_section($k, $energy, "xsec");
##     $barns_per_formula_unit += $this * $count{$k};
##     $amu_per_formula_unit += Xray::Absorption -> get_atomic_weight($k) * $count{$k};
##   };
##   ## 1 amu = 1.6605389 x 10^-24 gm
##   push @xsec, $barns_per_formula_unit / $amu_per_formula_unit / 1.6605389;
## };
##
## my $answer = 10000/(($xsec[1]-$xsec[0])*$density);
## printf "%.3f microns\n", $answer;



sub user_formulas_remove {
  return unless ($data{form_name});

  my $answer = $top -> Dialog(-title=>"Remove a formula?",
			      -text=>"Really remove $data{form_name} from the list?",
			      -buttons=>["Remove", "Cancel"],
			      -default_button=>'Cancel',
			      -bitmap=>'questhead') -> Show();
  return if ($answer eq 'Cancel');

  ## remove in this session
  my $which = $data{form_lb} -> curselection();
  $data{form_lb} -> delete($which);
  $data{form_lb} -> selectionSet(0);

  ## remove for future sessions
  my $ini_ref = tied %userformulas;
  $userformulas{data}{$data{form_name}} = "^^remove^^";
  my $userformulas = File::Spec->catfile($horae_lib, 'hephaestus.data');
  $ini_ref -> WriteConfig($userformulas);

  ($data{form_name}, $data{form_string}, $data{form_density}) = ("", "", "");

};

sub user_formulas_add {
  return unless ($data{form_string} and $data{form_density});
  my $db = $top -> DialogBox(-title=>"Add a formula",
			     -buttons=>[qw(OK Cancel)],
			     -default_button=>'OK');
  $db -> add('Label', -text=>"Formula: $data{form_string}") -> pack();
  $db -> add('Label', -text=>"Density: $data{form_density}") -> pack();
  $db -> add('LabEntry', -label=>'Name: ', -textvariable=>\$data{form_name},
	     -labelPack=>[-side=>'left']) -> pack();
  my $answer = $db -> Show;
  return if ($answer eq 'Cancel');
  #print $data{form_name} if ($answer eq 'OK');
  $data{form_lb} -> insert('end', $data{form_name});
  $data{form_lb} -> see('end');
  $data{form_lb} -> selectionSet('end');

  ## for use in this session
  $formula{$data{form_name}} = $data{form_string};
  $density{$data{form_name}} = $data{form_density};

  return 0 if ($data{form_name} =~ /^\s*$/);
  return 0 if ($data{form_string} =~ /^\s*$/);
  ## for use in future sessions
  my $ini_ref = tied %userformulas;
  $userformulas{data}{$data{form_name}} = join("|", $data{form_string}, $data{form_density});
  my $userformulas = Ifeffit::FindFile->find("hephaestus", "data");
  $ini_ref -> WriteConfig($userformulas);
};

sub plot_information_depth {
  my $energy  = ($data{units} eq 'Energies') ? $data{form_energy} : e2l($data{form_energy});
  if ((lc($data{resource}) eq "henke") and ($energy > 30000)) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'info',
		     -text           => "The Henke tables only include data up to 30 keV.",
		     -title          => 'Hephaestus warning',
		     -buttons        => [qw/OK/],
		     -default_button => 'OK')
	-> Show();
    return;
  };
  my %count;
  my $ok = parse_formula($data{form_string}, \%count);
  my $units   = ($data{units} eq 'Energies') ? 'eV' : 'Å';
  my $density = $data{form_density};

  my @edges;
  foreach my $el (keys(%count)) {
    foreach my $edge (qw(k l1 l2 l3)) {
      my $enot = Xray::Absorption -> get_energy($el, $edge);
      if (abs($enot - $energy) < 1000) {
	my $line = ($edge eq 'k')  ? "kalpha1"
	         : ($edge eq 'l3') ? "lalpha1"
	         : ($edge eq 'l2') ? "lbeta1"
		 :                   "lbeta3";
	push @edges, [$el, $line, $edge];
      };
    };
  };
  my ($angle_in, $angle_out) = (45, 45);
  my $efluo = (@edges) ? Xray::Absorption->get_energy(@{$edges[0]}) : 0;

  my ($barns, $amu) = (0,0);
  foreach my $el (keys(%count)) {
    $barns += Xray::Absorption -> cross_section($el, $efluo) * $count{$el};
    $amu   += Xray::Absorption -> get_atomic_weight($el) * $count{$el};
  };
  my $muf = sprintf("%.6f", $barns / $amu / 1.6607143);
  my $angle_ratio = sprintf("%.6f", sin(PI*$angle_in/180) / sin(PI*$angle_out/180));

  my @e;
  foreach my $i (-100 .. 100) {
    push @e, $i*10 + $energy;
  };
  my (@mut, @muf);
  foreach my $e (@e) {
    my ($barns, $amu) = (0,0);
    foreach my $el (keys(%count)) {
      ##next if (lc($el) eq lc(get_symbol($groups{$current}->{bkg_z})));
      $barns += Xray::Absorption -> cross_section($el, $e) * $count{$el};
      $amu   += Xray::Absorption -> get_atomic_weight($el) * $count{$el};
#      if ($e > Xray::Absorption -> get_energy($edges[0]->[0], $edges[0]->[2])) {
	push @muf, $muf;
#      } else {
#	push @muf, 0;
#      };
    };
    ## 1 amu = 1.6607143 x 10^-24 gm
    push @mut, $barns / $amu / 1.6607143;
  };

  Ifeffit::ifeffit("## inserted d___epth.mut into ifeffit's memory...");
  Ifeffit::put_array("d___epth.energy", \@e);
  Ifeffit::put_array("d___epth.mut", \@mut);
  Ifeffit::put_array("d___epth.muf", \@muf);
  my $sets = "set(d___epth.alpha = d___epth.mut + $angle_ratio*d___epth.muf,";
  $sets   .= "    d___epth.info = 10000*sin(pi*$angle_in/180) / d___epth.alpha)";
  Ifeffit::ifeffit($sets);
  my $command = "newplot(d___epth.energy, d___epth.info, xmin=$e[0], xmax=$e[$#e], ";
  $command   .= "xlabel=k (\\A\\u-1\\d), ylabel=\"Depth (\\gmm)\", ";
  $command   .= "fg=black, bg=white, grid, gridcolor=grey82, ";
  $command   .= "style=lines, color=blue, key=\"depth\", title=\"Information Depth\")\n";
  #$command    = wrap("newplot", "       ", $command) . $/;
  Ifeffit::ifeffit($command);
  $top -> Unbusy;
};
