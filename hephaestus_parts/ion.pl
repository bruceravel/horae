#! /usr/bin/perl -w      # -*- cperl -*-

## ===========================================================================
##  This is the ion chamber portion of hephaestus

sub ion {
  $periodic_table -> packForget() if $current =~ /$uses_periodic_regex/;
  switch({page=>"ion", text=>'Compute Absorption of Ion Chambers'});
};

sub setup_ion {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  $data{ion_energy}   ||= 9000;
  $data{ion_length}   ||= 15;
  $data{ion_userlength} = 20;
  $data{ion_gas1}     ||= 'N2';
  $data{ion_gas2}       = 'He';
  $data{ion_frac1}      = 100;
  $data{ion_frac2}      = 0;
  $data{ion_pressure} ||= 760;
  $data{ion_gain}     ||= 8;
  $data{ion_voltage}    = 0;
  $data{ion_flux}       = 0;

  my $top = $frame -> Frame()
    -> pack(-side=>'top', -padx=>4, -pady=>8);
  my $left = $top -> Frame()
    -> pack(-side=>'left', -padx=>8, -pady=>0, -anchor=>'n');
  my $right = $top -> Frame()
    -> pack(-side=>'right', -pady=>0);

  $left -> Label(-textvariable=>\$data{ion_resource}, -width=>30, @label_args)
    -> pack(-side=>'top');

  my $frm = $left -> Frame()
    -> pack(-side=>'top', -pady=>0);
  $data{ion_energy_label} = $frm -> Label(-text=>'Photon energy:', @label_args)
    -> pack(-side=>'left');
  my $entry = $frm -> Entry(-textvariable=>\$data{ion_energy}, -width=>6,
			    -font=>$config{fonts}{smfixed},
			    -validate=>'key', -validatecommand=>[\&set_variable, 'ion_energy'])
    -> pack(-side=>'left', -padx=>4);

  $frm = $left -> LabFrame(-label=>'Chamber Length',
			   -labelside=>'acrosstop', @label_args)
    -> pack(-side=>'top');

  $frm -> Radiobutton(-text=>"3.3 cm Lytle Detector",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>3.3)
    -> grid(-column=>0, -row=>0, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"6.6 cm Lytle Detector",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>6.6)
    -> grid(-column=>0, -row=>1, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"5 cm",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>5)
    -> grid(-column=>0, -row=>2, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"10 cm",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>10)
    -> grid(-column=>0, -row=>2, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"15 cm",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>15)
    -> grid(-column=>0, -row=>3, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"30 cm",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>30)
    -> grid(-column=>0, -row=>4, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"45 cm",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>45)
    -> grid(-column=>0, -row=>5, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"60 cm",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>60)
    -> grid(-column=>0, -row=>6, -sticky=>'w', -columnspan=>2);
  $frm -> Radiobutton(-text=>"Choose your own",
		      -font=>$config{fonts}{small},
		      -command=>[\&get_ion_data, 0],
		      -variable=>\$data{ion_length},
		      -value=>0)
    -> grid(-column=>0, -row=>7, -sticky=>'w');
  $data{ion_user_entry} = $frm -> Entry(-width=>8,
					-state=>'disabled',
					(($Tk::VERSION > 804) ? (-disabledbackground=>$bgcolor) : ()),
					-foreground=>'grey50',
					-font=>$config{fonts}{smfixed},
					-textvariable=>\$data{ion_userlength},
					-validate=>'key',
					-validatecommand=>\&set_variable,)
    -> grid(-column=>0, -row=>8, -sticky=>'e');
  $data{ion_user_label} = $frm -> Label(-text	    => 'cm',
					-font	    => $config{fonts}{small},
					-foreground => 'grey50')
    -> grid(-column=>1, -row=>8, -sticky=>'w');


  $right -> Label(-text=>"Primary Gas ", -font=>$config{fonts}{smbold},)
    -> grid(-column=>0, -row=>0,);
  my $be = $right -> Optionmenu(-options=> [qw(N2 He Ne Ar Kr Xe)],
				-font=>$config{fonts}{smbold},
				-command => [\&get_ion_data, 0],
				-variable => \$data{ion_gas1},
				-borderwidth => 1,)
    -> grid(-column=>1, -row=>0, -sticky=>'w', -padx=>4);
  my $sc = $right -> Scale(-from	 => 100,
			   -to		 => 0,
			   -orient	 => 'vertical',
			   -tickinterval => 20,
			   -length	 => 250,
			   #-foreground	 => '#640096',
			   -variable	 => \$data{ion_frac1},
			   -font         => $config{fonts}{small},
			   -command	 => [\&get_ion_data, 1])
    -> grid(-column=>0, -columnspan=>2, -row=>1);
  #BindMouseWheel($sc);

  $right -> Label(-text=>"Secondary Gas ", -font=>$config{fonts}{smbold},)
    -> grid(-column=>3, -row=>0,);
  $be = $right -> Optionmenu(-options	  => [qw(He N2 Ne Ar Kr Xe)],
			     -command	  => [\&get_ion_data, 0],
			     -font	  =>$config{fonts}{smbold},
			     -variable	  => \$data{ion_gas2},
			     -borderwidth => 1,)
    -> grid(-column=>4, -row=>0, -sticky=>'w', -padx=>4);

##   $be = $right -> BrowseEntry(-label => "Secondary Gas ",
## 			      -width=>5,
## 			      #-listwidth=>30,
## 			      #-listheight=>6,
## 			      #-foreground=>'darkgreen',
## 			      -variable => \$data{ion_gas2},
## 			      -choices => [qw(He N2 Ne Ar Kr Xe)],
## 			      -browsecmd=>[\&get_ion_data, 0],)
##     -> grid(-column=>4, -row=>0, -sticky=>'e', -padx=>4);

  $sc = $right -> Scale(-from	      => 100,
			-to           => 0,
			-orient	      => 'vertical',
			-tickinterval => 20,
			-length	      => 250,
			#-foreground  => 'darkgreen',
			-variable     => \$data{ion_frac2},
			-font         => $config{fonts}{small},
			-command      => [\&get_ion_data, 2])
    -> grid(-column=>3, -columnspan=>2, -row=>1);
  #BindMouseWheel($sc);

  $right -> Label(-text=>'Pressure (Torr)', -font=>$config{fonts}{smbold}, )
     -> grid(-column=>5, -row=>0, -sticky=>'e', -padx=>4);
  $right -> Scale(-from		=> 2300,
		  -to		=> 0,
		  -orient	=> 'vertical',
		  -tickinterval	=> 500,
		  -length	=> 250,
		  #-foreground	=> 'darkgreen',
		  -variable	=> \$data{ion_pressure},
		  -font=>$config{fonts}{small},
		  -command	=> [\&get_ion_data, 2]
		 )
    -> grid(-column=>5, -row=>1);
   #BindMouseWheel($sc);


  $frame -> Label(-text=>'Rules of thumb: 10% absorption in I0; 70% absorption in It or If  (1 Atm = 760 Torr)',
		  -font=>$config{fonts}{small})
    -> pack(-side=>'bottom', -anchor=>'center', -pady=>8);

  $frm = $frame -> LabFrame(-label=>"Photon flux",
			    -labelside=>'acrosstop',@label_args)
    -> pack(-side=>'bottom', -anchor=>'center', -pady=>8, -fill =>'x', -padx=>12);
  $frm -> Label(-text=>"    Amplifier gain", @label_args)
    -> pack(-side=>'left');
  $frm -> NumEntry(-orient => 'horizontal',
		   -increment => 1,
		   -minvalue => 0,
		   -width => 4,
		   -textvariable => \$data{ion_gain},
		   -font=>$config{fonts}{smfixed},
		   -command => [\&get_ion_data, 0],
		   -browsecmd => [\&get_ion_data, 0]
		   )
     -> pack(-side=>'left');
  $frm -> Label(-text=>" with ", @label_args)
    -> pack(-side=>'left');
  my $e = $frm -> Entry(-width => 7,
			-font=>$config{fonts}{smfixed},
			-textvariable=>\$data{ion_voltage},
			-validate=>'key',
			-validatecommand=>\&set_variable,)
    -> pack(-side=>'left');
  $e -> bind("<KeyPress-Return>"=>[\&get_ion_data, 0]);

  $frm -> Label(-text=>" volts gives ", @label_args)
    -> pack(-side=>'left');
  $frm -> Label(-width => 11,
		-font=>$config{fonts}{smfixed},
		-textvariable=>\$data{ion_flux})
    -> pack(-side=>'left');
  $frm -> Label(-text=>"photons/second", @label_args)
    -> pack(-side=>'left');


  my $bottom = $frame -> Frame()
    -> pack(-side=>'bottom', -padx=>8, -pady=>4);
  $bottom -> Label(@label_args, -text=>"Percentage absorbed:")
    -> pack(-side=>'left');
  $bottom -> Label(-textvariable=>\$data{ion_absorbed},
		   -font=>$config{fonts}{smfixed},
		   -relief=>'groove',
		   -width=>10)
    -> pack(-side=>'left', -padx=>4);
  $bottom -> Button(-text=>'Reset', @button_args,
		    -command=>sub{
		      $data{ion_energy}	    = 9000;
		      $data{ion_length}	    = 15;
		      $data{ion_userlength} = 20;
		      $data{ion_gas1}	    = 'N2';
		      $data{ion_gas2}	    = 'He';
		      $data{ion_frac1}	    = 100;
		      $data{ion_frac2} 	    = 0;
		      $data{ion_pressure}   = 760;
		      $data{ion_gain}       = 8;
		      $data{ion_voltage}    = 0;
		      $data{ion_flux}       = 0;
		      &get_ion_data(0);
		   }
		  )
    -> pack(-side=>'left', -padx=>4);
  $entry -> bind("<KeyPress-Return>"=>[\&get_ion_data, 0]);
  $data{ion_user_entry} -> bind("<KeyPress-Return>"=>[\&get_ion_data, 0]);

  return $frame;
};


sub get_ion_data {
  if ((lc($data{resource}) eq "henke") and ($data{ion_energy} > 30000)) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'info',
		     -text           => "The Henke tables only include data up to 30 keV.",
		     -title          => 'Hephaestus warning',
		     -buttons        => [qw/OK/],
		     -default_button => 'OK')
	-> Show();
    return;
  };

  my $which = $_[0];
  if ($which eq 1) {
    $data{ion_frac2} = 100 - $data{ion_frac1};
  } elsif ($which eq 2) {
    $data{ion_frac1} = 100 - $data{ion_frac2};
  };

  $data{ion_user_entry} ->
    configure(-state=>($data{ion_length}==0) ? 'normal' : 'disabled',
	      -foreground=>($data{ion_length}==0) ? 'black' : 'grey50');
  $data{ion_user_label} ->
    configure(-foreground=>($data{ion_length}==0) ? 'black' : 'grey50');

  my ($barns_per_component, $amu_per_component, $dens) = (0,0, 0);
  my $energy = ($data{units} eq 'Energies') ? $data{ion_energy} : e2l($data{ion_energy});
  foreach my $i (1, 2) {
    my $g = $data{"ion_gas$i"};
    $g = 'N' if ($g eq 'N2');
    $dens += $data{"ion_frac$i"} * $density{ucfirst(get_name($g))} / 100;
    my $this;
    my $one_minus_g = 1; #Xray::Absorption->get_one_minus_g($g, $data{ion_energy});
    #print "$g    $one_minus_g\n";
    if ((lc($data{resource}) eq "henke") or (lc($data{resource}) eq "cl")) {
      $this = Xray::Absorption -> cross_section($g, $energy, 'total');
    } else {
      $this = (Xray::Absorption -> cross_section($g, $energy, 'photo') +
               Xray::Absorption -> cross_section($g, $energy, 'incoherent'))
	     * $one_minus_g;
    };
    ##     my $how = 'photo';
    ##     ($how = 'xsec') if ((lc($data{resource}) eq "henke") or (lc($data{resource}) eq "cl"));
    ##     my $this = Xray::Absorption -> cross_section($g, $energy, $how);
    my $mass_factor = ($g eq 'N') ? 2 : 1;
    $barns_per_component += $this * $data{"ion_frac$i"} * $mass_factor;
    $amu_per_component += Xray::Absorption -> get_atomic_weight($g) * $data{"ion_frac$i"} * $mass_factor;
  };
  ## this is in cm ...
  my $xsec = $dens * $barns_per_component / $amu_per_component / 1.6607143;
  my $len = $data{ion_length} || $data{ion_userlength} || 0;
  #print 1/$xsec, "  $len\n";
  my $atm = $data{ion_pressure} / 760;
  $atm ||= EPSILON;
  $xsec *= $atm;
  $data{ion_absorbed} = sprintf("%.2f %%", 100*(1-exp(-1*$xsec*$len)));

  ## flux calculation
  if ($data{ion_voltage} > 0) {
    my $flux = (30/16) * (10**(20-$data{ion_gain})) * $data{ion_voltage} / $data{ion_energy};
    ($data{ion_flux} = 0), return unless ($xsec);
    $flux /= (1-exp(-1*$xsec*$len)); # account for fraction absorbed
    $data{ion_flux} = sprintf("%.3e", $flux);
  } else {
    $data{ion_flux} = 0;
  };
};
