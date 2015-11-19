
## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This file contains the fourier transform teaching dialog



sub teach_ft {

  ## you must define a hash which will contain the parameters needed
  ## to perform the task.  the hash_pointer global variable will point
  ## to this hash for use in set_properties.  you might draw these
  ## values from configuration parameters
  my %tft_params = (r1	  => 2,
		    r2	  => 3,
		    r3	  => 0,
		    ext   => 20,
		    npts  => 400,
		    kmin  => 2,
		    kmax  => 18,
		    rmin  => 1.75,
		    rmax  => 2.25,
		    dk	  => 2,
		    dr	  => 0.5,
		    kwin  => "Kaiser-Bessel",
		    rwin  => "Kaiser-Bessel",
		    plot  => 0,
		   );

  ## these two global variables must be set before this view is displayed
  $fat_showing = 'teach_ft';
  $hash_pointer = \%tft_params;

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
  my $tft = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$conv -> packPropagate(0);
  ## global variable identifying which Frame is showing
  $which_showing = $tft;

  ## the standard label along the top identifying this analysis chore
  $tft -> Label(-text=>"Understanding Fourier transforms",
		-font=>$config{fonts}{large},
		-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');


  my @lab = (-foreground=>$config{colors}{activehighlightcolor});
  my $fr = $tft -> Frame(-relief=>'sunken', -borderwidth=>2)
    -> pack(-side=>'top', -fill=>'x',  -anchor=>'w', -padx=>2, -pady=>2, -ipady=>8);
  my $row = 0;

  $fr -> Label(-text=>'Wave #1', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_r1} = $fr -> Entry(-width=>5,
				 -validate=>'key',
				 -validatecommand=>[\&set_variable, 'tft_r1'],
				 -textvariable=>\$tft_params{r1},
				)
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'Angstroms', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'w');

  ++$row;
  $fr -> Label(-text=>'Wave #2', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_r2} = $fr -> Entry(-width=>5,
				 -validate=>'key',
				 -validatecommand=>[\&set_variable, 'tft_r2'],
				 -textvariable=>\$tft_params{r2},
				)
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'Angstroms', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'w');

  ++$row;
  $fr -> Label(-text=>'Wave #3', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_r3} = $fr -> Entry(-width=>5,
				 -validate=>'key',
				 -validatecommand=>[\&set_variable, 'tft_r3'],
				 -textvariable=>\$tft_params{r3},
				)
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'Angstroms', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'w');

  ++$row;
  $fr -> Label(-text=>'k extent', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_ext} = $fr -> Entry(-width=>5,
				  -validate=>'key',
				  -validatecommand=>[\&set_variable, 'tft_ext'],
				  -textvariable=>\$tft_params{ext},
				  )
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'Angstroms', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'w');


  ++$row;
  $fr -> Label(-text=>'kmin', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_kmin} = $fr -> Entry(-width=>5,
				   -validate=>'key',
				   -validatecommand=>[\&set_variable, 'tft_kmin'],
				   -textvariable=>\$tft_params{kmin},
				  )
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'kmax', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'e');
  $widget{tft_kmax} = $fr -> Entry(-width=>5,
				   -validate=>'key',
				   -validatecommand=>[\&set_variable, 'tft_kmax'],
				   -textvariable=>\$tft_params{kmax},
				  )
    -> grid(-row=>$row, -column=>3, -sticky=>'w');


  ++$row;
  $fr -> Label(-text=>'dk', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_dk} = $fr -> Entry(-width=>5,
				 -validate=>'key',
				 -validatecommand=>[\&set_variable, 'tft_dk'],
				 -textvariable=>\$tft_params{dk},
				)
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'k window', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'e');
  $fr -> Optionmenu(-options=>[qw(Kaiser-Bessel Hanning Parzen Welch)],
		    -variable=>\$tft_params{kwin},)
    -> grid(-row=>$row, -column=>3, -sticky=>'w');

  ++$row;
  $fr -> Label(-text=>'Rmin', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_rmin} = $fr -> Entry(-width=>5,
				   -validate=>'key',
				   -validatecommand=>[\&set_variable, 'tft_rmin'],
				   -textvariable=>\$tft_params{rmin},
				  )
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'Rmax', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'e');
  $widget{tft_rmax} = $fr -> Entry(-width=>5,
				   -validate=>'key',
				   -validatecommand=>[\&set_variable, 'tft_rmax'],
				   -textvariable=>\$tft_params{rmax},
				  )
    -> grid(-row=>$row, -column=>3, -sticky=>'w');

  ++$row;
  $fr -> Label(-text=>'dR', @lab)
    -> grid(-row=>$row, -column=>0, -sticky=>'e');
  $widget{tft_dr} = $fr -> Entry(-width=>5,
				 -validate=>'key',
				 -validatecommand=>[\&set_variable, 'tft_dr'],
				 -textvariable=>\$tft_params{dr},
				)
    -> grid(-row=>$row, -column=>1, -sticky=>'w');
  $fr -> Label(-text=>'R window', @lab)
    -> grid(-row=>$row, -column=>2, -sticky=>'e');
  $fr -> Optionmenu(-options=>[qw(Kaiser-Bessel Hanning Parzen Welch)],
		    -variable=>\$tft_params{rwin},)
    -> grid(-row=>$row, -column=>3, -sticky=>'w');


  my $red = $config{colors}{single};
  ++$row;
  $fr -> Radiobutton(-text        =>"Plot waves in k",
		     -variable    =>\$tft_params{plot},
		     -selectcolor =>$red,
		     -value       =>0,
		     -command     => sub{tft_plot_waves(\%tft_params)})
    -> grid(-row=>$row, -column=>0, -columnspan=>4, -sticky=>'w');

  ++$row;
  $fr -> Radiobutton(-text	  => "Plot sum*window in k", ,
		     -variable	  => \$tft_params{plot},
		     -selectcolor => $red,
		     -value	  => 1,
		     -command	  => sub{tft_plot_windowed(\%tft_params)},)
    -> grid(-row=>$row, -column=>0, -columnspan=>4, -sticky=>'w');

  ++$row;
  $fr -> Radiobutton(-text=>"Plot magnitude of FT", ,
		     -variable	  => \$tft_params{plot},
		     -selectcolor => $red,
		     -value	  => 2,
		     -command => sub{tft_plot_r(\%tft_params, 'm')},)
    -> grid(-row=>$row, -column=>0, -columnspan=>4, -sticky=>'w');

  ++$row;
  $fr -> Radiobutton(-text=>"Plot real part of FT", ,
		     -variable	  => \$tft_params{plot},
		     -selectcolor => $red,
		     -value	  => 3,
		     -command => sub{tft_plot_r(\%tft_params, 'r')},)
    -> grid(-row=>$row, -column=>0, -columnspan=>4, -sticky=>'w');

  ++$row;
  $fr -> Radiobutton(-text=>"Plot BFT + sum*window", ,
		     -variable	  => \$tft_params{plot},
		     -selectcolor => $red,
		     -value	  => 4,
		     -command => sub{tft_plot_kq(\%tft_params)},)
    -> grid(-row=>$row, -column=>0, -columnspan=>4, -sticky=>'w');

  ++$row;
  $fr -> Radiobutton(-text=>"Plot edge step", ,
		     -variable	  => \$tft_params{plot},
		     -selectcolor => $red,
		     -value	  => 5,
		     -command => sub{tft_plot_step(\%tft_params)},)
    -> grid(-row=>$row, -column=>0, -columnspan=>4, -sticky=>'w');
  ++$row;
  $fr -> Radiobutton(-text=>"Plot FT of edge step", ,
		     -variable	  => \$tft_params{plot},
		     -selectcolor => $red,
		     -value	  => 6,
		     -command => sub{tft_plot_stepft(\%tft_params)},)
    -> grid(-row=>$row, -column=>0, -columnspan=>3, -sticky=>'w');
  $fr -> Button(-text=>"Replot", @button_list,
		-command => sub{tft_replot(\%tft_params)}
	       )
    -> grid(-row=>$row, -column=>3, -sticky=>'ew');

  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $tft -> Button(-text=>'Return to the main window',  @button_list,
		  -background=>$config{colors}{background2},
		  -activebackground=>$config{colors}{activebackground2},
		  -command=>sub{&reset_window($tft, "understanding FTs", 0);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $tft -> Button(-text=>'Document section: Understanding Fourier transforms', @button_list,
		 -command=>sub{pod_display("bkg::ft.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  ## and finally....
  tft_plot_waves(\%tft_params);
  $top -> update;

};

sub tft_replot {
  my ($rhash) = @_;
  my @callbacks = (sub{tft_plot_waves($rhash)},
		   sub{tft_plot_windowed($rhash)},
		   sub{tft_plot_r($rhash, 'm')},
		   sub{tft_plot_r($rhash, 'r')},
		   sub{tft_plot_kq($rhash)},
		   sub{tft_plot_step($rhash)},
		   sub{tft_plot_stepft($rhash)},
		  );
  my $this = $callbacks[$$rhash{plot}];
  &$this;
};


sub tft_make_arrays {
  my ($rhash) = @_;
  $$rhash{npts} = int($$rhash{ext}/0.05);
  my $command = q{};
  $command .= sprintf("set t___ft.k = indarr(%d)*0.05\n", $$rhash{npts});
  foreach my $w (qw(r1 r2 r3)) {
    if ($$rhash{$w} > 0) {
      $command .= sprintf("set t___ft.%s = 0.5*sin(t___ft.k*2*%.4f)\n", $w, $$rhash{$w});
    } else {
      $command .= sprintf("set t___ft.%s = zeros(%d)\n", $w, $$rhash{npts});
    };
  };
  $command .= "set t___ft.sum = t___ft.r1 + t___ft.r2 + t___ft.r3\n";
  $command .= sprintf("fftf(t___ft.sum, k=t___ft.k, kweight=0, kmin=%.4f, kmax=%.4f, dk=%.4f, kwindow=%s)\n",
		      $$rhash{kmin}, $$rhash{kmax}, $$rhash{dk}, $$rhash{kwin});
  $command .= sprintf("fftr(real=t___ft.chir_re, imag=t___ft.chir_im, rmin=%.4f, rmax=%.4f, dr=%.4f, rwindow=%s)\n",
		      $$rhash{rmin}, $$rhash{rmax}, $$rhash{dr}, $$rhash{rwin});
  $groups{"Default Parameters"} -> dispose($command, $dmode);
};

sub tft_plot_waves {
  my ($rhash) = @_;
  $top -> Busy;
  tft_make_arrays($rhash);
  my $command = q{};
  $command .= "newplot(t___ft.k, t___ft.sum, color=blue, key=sum, xlabel=\"k (\\A\\u-1\\d)\", ylabel=\"sum of waves\")\n";
  $command .= "plot(title=\"understanding Fourier transforms\")\n";
  my $offset = -1;
  if ($$rhash{r1}>0) {
    $command .= "plot(t___ft.k, \"t___ft.r1+$offset\", color=red, key=\"first wave\")\n";
    $offset--;
  };
  if ($$rhash{r2}>0) {
    $command .= "plot(t___ft.k, \"t___ft.r2+$offset\", color=darkgreen, key=\"second wave\")\n";
    $offset--;
  };
  if ($$rhash{r3}>0) {
    $command .= "plot(t___ft.k, \"t___ft.r3+$offset\", color=darkviolet, key=\"third wave\")\n";
    $offset--;
  };
  $groups{"Default Parameters"} -> dispose($command, $dmode);
  $top -> Unbusy;
  return $offset;
};

sub tft_plot_windowed {
  my ($rhash) = @_;
  $top -> Busy;
  tft_make_arrays($rhash);
  my $command = q{};
  $command .= "newplot(t___ft.k, t___ft.sum, color=blue, key=sum, xlabel=\"k (\\A\\u-1\\d)\", ylabel=\"sum of waves\")\n";
  $command .= "plot(title=\"understanding Fourier transforms\")\n";
  $command .= "plot(t___ft.k, t___ft.win, color=darkgreen, key=window)\n";
  $command .= "plot(t___ft.k, \"t___ft.sum*t___ft.win\", color=red, key=\"windowed sum\")\n";
  $groups{"Default Parameters"} -> dispose($command, $dmode);
  $top -> Unbusy;
};

sub tft_plot_r {
  my ($rhash, $part) = @_;
  $part = ($part =~ m{[impr]}) ? $part : 'r';
  $top -> Busy;
  tft_make_arrays($rhash);
  my $command = q{};
  my %suff = ('m'=>'chir_mag', r=>'chir_re', i=>'chir_im', p=>'chir_pha');
  $command .= "newplot(t___ft.r, t___ft.$suff{$part}, xmax=7, color=blue, key=\"FT of sum\", xlabel=\"R (\\A)\", ylabel=\"FT of sum of waves\")\n";
  $command .= "plot(t___ft.r, \"t___ft.$suff{$part}*t___ft.rwin\", color=red, key=\"windowed FT\")\n";
  $command .= "plot(t___ft.r, t___ft.rwin, color=darkgreen, key=window)\n";
  $groups{"Default Parameters"} -> dispose($command, $dmode);
  $top -> Unbusy;
};

sub tft_plot_kq {
  my ($rhash) = @_;
  $top -> Busy;
  tft_make_arrays($rhash);
  my $offset = abs(tft_plot_waves($rhash));
  my $command = q{};
  #$command .= "newplot(t___ft.k, \"t___ft.sum*t___ft.win\", xmax=$$rhash{ext}, key=\"windowed sum\", color=blue, xlabel=\"k (\\A\\u-1\\d)\", ylabel=\"sum of waves\")\n";
  #$command .= "plot(title=\"understanding Fourier transforms\")\n";
  $command .= "plot(t___ft.q, t___ft.chiq_re, color=deeppink, xmax=$$rhash{ext}, key=backtransform)\n";
  $groups{"Default Parameters"} -> dispose($command, $dmode);
  $top -> Unbusy;
};

sub tft_step_arrays {
  my ($rhash) = @_;
  my $command = q{};
  $command .= sprintf("set t___ft.k = indarr(%d)*0.05\n", $$rhash{npts});
  $command .= sprintf("set t___ft.r%s = 0.5*sin(t___ft.k*2*%.4f)\n", 1, $$rhash{r1});
  $command .= sprintf("set t___ft.step = 0.5*(1+erf(t___ft.k-%.3f))*(1+0.1*t___ft.r%s)\n",  $$rhash{npts}/4*0.05, 1);
  return $command;
};

sub tft_plot_step {
  my ($rhash) = @_;
  $top -> Busy;
  my $command = tft_step_arrays($rhash);
  $command .= "newplot(t___ft.k, t___ft.step, color=blue, xmax=$$rhash{ext}, key=\"step function + 2 \\A wave\")\n";
  $groups{"Default Parameters"} -> dispose($command, $dmode);
  $top -> Unbusy;
};

sub tft_plot_stepft {
  my ($rhash) = @_;
  $top -> Busy;
  my $command = tft_step_arrays($rhash);
  $command .= sprintf("fftf(t___ft.step, k=t___ft.k, kweight=0, kmin=%.4f, kmax=%.4f, dk=%.4f, kwindow=%s)\n",
		      0, $$rhash{kmax}, $$rhash{dk}, $$rhash{kwin});
  $command .= "newplot(t___ft.r, t___ft.chir_mag, color=blue, xmax=7, key=\"FT of step function + 2\\A wave\")\n";
  $command .= "plot_arrow(x1=2, y1= 2, x2=2, y2=0.5,  barb=0, size=1)\n";
  $command .= "plot_text(x=2,y=2.3, text='location of 2\\A peak')\n";
  $groups{"Default Parameters"} -> dispose($command, $dmode);
  $top -> Unbusy;
};
