# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
## THE MAIN WINDOW


###===================================================================
### set up widgets in main windows
###===================================================================

sub make_opparams {
  my $parent = $_[0];

  my @pluck_button  = (-foreground       => $config{colors}{highlightcolor},
		       -activeforeground => $config{colors}{activehighlightcolor},
		       -background       => $config{colors}{background},
		       -activebackground => $config{colors}{activebackground});
  my @start = ("-foreground", $config{colors}{activehighlightcolor}, "-font", $config{fonts}{med});
  my $pluck_bitmap = '#define pluck_width 9
#define pluck_height 9
static unsigned char pluck_bits[] = {
   0x81, 0x01, 0xc3, 0x00, 0x66, 0x00, 0x3c, 0x00, 0x38, 0x00, 0x78, 0x00,
   0xcc, 0x00, 0x86, 0x01, 0x03, 0x01};
';
  my $pluck_X = $top -> Bitmap('pluck', -data=>$pluck_bitmap,
			       -foreground=>$config{colors}{activehighlightcolor});
  my @pluck=(-image=>$pluck_X);

  my $c = $parent -> Frame(-relief=>'flat',
			   #@window_size,
			   -borderwidth=>0,
			   -highlightcolor=>$config{colors}{background})
    -> pack(-fill=>'both', -expand=>1);

  ## titles
  my $lfr = $c -> LabFrame(-label      => 'Titles',
			   -font       => $config{fonts}{med},
			   -foreground => $config{colors}{activehighlightcolor},
			   -labelside  => 'acrosstop',
			   -width      => 14)
    -> pack(-side=>'top', -padx=>4, -fill=>'x');
  &labframe_help($lfr);
  push @op_text, $lfr;
  $widgets{op_titles} = $lfr -> Scrolled('Text',
					 -height=>5,
					 -font=>$config{fonts}{fixed},
					 -scrollbars=>'se',
					 -width=>50,
					 -wrap=>'none')
    -> pack(-fill=>'x', -padx=>4, -pady=>4);
  &disable_mouse3($widgets{op_titles}->Subwidget("text"));
  BindMouseWheel($widgets{op_titles});
  $widgets{op_titles}->Subwidget("xscrollbar")
    ->configure(-background=>$config{colors}{background},
		($is_windows) ? () : (-width=>8));
  $widgets{op_titles}->Subwidget("yscrollbar")
    ->configure(-background=>$config{colors}{background},
		($is_windows) ? () : (-width=>8));


  ## data and background files
  my $fr = $c -> Frame()
    -> pack(-side=>'top', -fill=>'x', -padx=>12, -pady=>0);
  my $t = $fr -> Label(-text=>"Data file", @start,
		       -font=>$config{fonts}{bold},)
    -> pack(-side=>'left');
  &click_help($t);
  push @op_text, $t;
  $widgets{op_file} = $fr -> Entry(-relief=>'groove',
				   -width=>43,
				   -borderwidth=>2,
				   -foreground=>$config{colors}{foreground},
				   -background  => $config{colors}{background2},
				   ($Tk::VERSION > 804) ? (-disabledforeground=>$config{colors}{foreground}) : (),
				 )
    -> pack(-side=>'right', -fill=>'x', -expand=>1, -padx=>4, -pady=>2);
  $widgets{op_file} -> configure(-state=>'disabled');

  $temp{data_showing} = "chi";
  $fr = $c -> Frame();
  #$fr -> pack(-side=>'top', -padx=>6, -pady=>0,);
  $widgets{show_chi} = $fr -> Radiobutton(-text     => 'Show chi(k)',
					  -value    => 'chi',
					  -variable => \$temp{data_showing},
					  -state    => 'disabled',
					  -command  => sub{
					    $widgets{mu_frame}  -> packForget;
					    $widgets{chi_frame} -> pack(-side=>'top', -padx=>6, -pady=>0,);
					 })
    -> pack(-side=>'left', -padx=>6);
  $widgets{show_mu}  = $fr -> Radiobutton(-text     => 'Show mu(E)',
					  -value    => 'mu',
					  -variable => \$temp{data_showing},
					  -state    => 'disabled',
					  -command  => sub{
					    $widgets{chi_frame} -> packForget;
					    $widgets{mu_frame}  -> pack(-side=>'top', -padx=>6, -pady=>0,);
					 })
    -> pack(-side=>'left', -padx=>6);

  $widgets{mu_frame} = $c -> Frame();
  $widgets{chi_frame} = $c -> Frame()
    -> pack(-side=>'top', -padx=>6, -pady=>0,);
  $fr = $widgets{chi_frame} -> Frame()
    -> pack(-side=>'top');
  my $left = $fr -> LabFrame(-label	 => 'Data controls',
			     -font	 => $config{fonts}{med},
			     -foreground => $config{colors}{activehighlightcolor},
			     -labelside	 => 'acrosstop',
			     -width	 => 14)
    -> pack(-side=>'left', -padx=>4, -fill=>'x', -anchor=>'n');
  &labframe_help($left);
  push @op_text, $left;
  $widgets{controls_frame} = $left;
  $widgets{op_include} = $left -> Checkbutton(-text=>'Include in the fit',
					      -foreground=>$config{colors}{foreground},
					      -activeforeground=>$config{colors}{foreground},
					      -selectcolor=>$config{colors}{check},
					      -font=>$config{fonts}{med},
					      -variable=>\$temp{op_include},
					      -onvalue=>1, -offvalue=>0,
					      -command=>
					      sub{my $this = $paths{$current}->data;
						  $paths{$this}->make(include=>$temp{op_include});
						  &toggle_data($this);
						  project_state(0);
						},
					     )
    -> pack(-side=>'top', -anchor=>'w');
  $widgets{op_plot} =
    $left -> Checkbutton(-text=>'Plot after the fit',
			 -foreground=>$config{colors}{foreground},
			 -activeforeground=>$config{colors}{foreground},
			 -selectcolor=>$config{colors}{check},
			 -font=>$config{fonts}{med},
			 -variable=>\$temp{op_plot},
			 -onvalue=>1, -offvalue=>0,
			 -command=>
			 sub{my $this = $paths{$current}->data;
			     $paths{$this}->make(plot=>$temp{op_plot});
			     project_state(0);
			     #my @all = &all_data;
			     #if ($#all == 1) {
			     #  foreach my $d (@all) {
			     #	 next if ($d eq $this);
			     #	 $paths{$d}->make(plot=>abs($temp{op_plot}-1));
			     #  };
			     #} else {
			     #  foreach my $d (@all) {
			     # 	 next if ($d eq $this);
			     #	 $paths{$d}->make(plot=>0);
			     #  };
			     #};
			   },
			)
    -> pack(-side=>'top', -anchor=>'w');

  $widgets{op_do_bkg} = $left -> Checkbutton(-text=>'Fit background',
					     -foreground=>$config{colors}{foreground},
					     -activeforeground=>$config{colors}{foreground},
					     -selectcolor=>$config{colors}{check},
					     -font=>$config{fonts}{med},
					     -variable=>\$temp{op_do_bkg},
					     -onvalue=>"yes", -offvalue=>'no',
					     -command=>
					     sub{my $this = $paths{$current}->data;
						 $paths{$this}->make(do_bkg=>$temp{op_do_bkg});
						 project_state(0);
					       },
					    )
    -> pack(-side=>'top', -anchor=>'w');







  ## k parameters
  $fr = $fr -> LabFrame(-label	    => 'Fourier and fit parameters',
			-font	    => $config{fonts}{med},
			-foreground => $config{colors}{activehighlightcolor},
			-labelside  => 'acrosstop',
			-width	    => 14)
    -> pack(-side=>'right', -padx=>4, -fill=>'x', -anchor=>'n');
  &labframe_help($fr);
  push @op_text, $fr;

  $t = $fr -> Label(@start, -text=>'k-range')
    -> grid(-column=>0, -row=>0, -sticky=>'w', -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_kmin} = $fr -> Entry(-width=>6,
				   -validate=>'key',
				   -validatecommand=>[\&set_opparam, 'kmin'])
    -> grid(-column=>1, -row=>0, -sticky=>'w');
  $grab{op_kmin} = $fr -> Button(@pluck_button, @pluck,
				 -command=>[\&pluck, 'op_kmin'])
    -> grid(-column=>2, -row=>0, -sticky=>'w');
  $t = $fr -> Label(@start, -text=>'  to  ')
    -> grid(-column=>3, -row=>0, -sticky=>'w', -padx=>2);
  push @op_text, $t;
  $widgets{op_kmax} = $fr -> Entry(-width=>6,
				   -validate=>'key',
				   -validatecommand=>[\&set_opparam, 'kmax'])
    -> grid(-column=>4, -row=>0, -sticky=>'w');
  $grab{op_kmax} = $fr -> Button(@pluck_button, @pluck,
				-command=>[\&pluck, 'op_kmax'])
    -> grid(-column=>5, -row=>0, -sticky=>'w');

  ## R parameters
  $t = $fr -> Label(@start, -text=>'R-range')
    -> grid(-column=>0, -row=>1, -sticky=>'w', -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_rmin} = $fr -> Entry(-width=>6,
				   -validate=>'key',
				   -validatecommand=>[\&set_opparam, 'rmin'])
    -> grid(-column=>1, -row=>1, -sticky=>'w');
  $grab{op_rmin} = $fr -> Button(@pluck_button, @pluck,
				 -command=>[\&pluck, 'op_rmin'])
    -> grid(-column=>2, -row=>1, -sticky=>'w');
  $t = $fr -> Label(@start, -text=>'  to  ')
    -> grid(-column=>3, -row=>1, -sticky=>'w', -padx=>2);
  push @op_text, $t;
  $widgets{op_rmax} = $fr -> Entry(-width=>6,
				   -validate=>'key',
				   -validatecommand=>[\&set_opparam, 'rmax'])
    -> grid(-column=>4, -row=>1, -sticky=>'w');
  $grab{op_rmax} = $fr -> Button(@pluck_button, @pluck,
				 -command=>[\&pluck, 'op_rmax'])
    -> grid(-column=>5, -row=>1, -sticky=>'w');

  $t = $fr -> Label(@start, -text=>'dk')
    -> grid(-column=>0, -row=>2, -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_dk} = $fr -> Entry(-width=>6,
				 -validate=>'key',
				 -validatecommand=>[\&set_opparam, 'dk'])
    -> grid(-column=>1, -row=>2, -sticky=>'w');
  $t = $fr -> Label(@start, -text=>'dr')
    -> grid(-column=>3, -row=>2, -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_dr} = $fr -> Entry(-width=>6,
				 -validate=>'key',
				 -validatecommand=>[\&set_opparam, 'dr'])
    -> grid(-column=>4, -row=>2, -sticky=>'w');

  $t = $fr -> Label(@start, -text=>'k window')
    -> grid(-column=>0, -row=>3, -sticky=>'e', -columnspan=>2, -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_kwindow} = $fr -> Optionmenu(-textvariable => \$temp{op_kwindow},
					   -borderwidth=>1)
    -> grid(-column=>2, -row=>3, -sticky=>'w', -columnspan=>4, -pady=>2);
  foreach my $i ($paths{data0}->Windows) {
    my $l = ucfirst($i);
    ($i eq "kaiser-bessel") and ($l = "Kaiser-Bessel");
    $widgets{op_kwindow} -> command(-label => $l,
				    -command=>
				    sub {
				      my $this = $paths{$current}->data;
				      $paths{$this}->make(kwindow=>$i);
				      &toggle_do('r');
				      $temp{op_kwindow} = ucfirst($l);
				      ($temp{op_kwindow} eq "kaiser-bessel") and
					($temp{op_kwindow} = "Kaiser-Bessel");
				      project_state(0);
				    });
  };
  $t = $fr -> Label(@start, -text=>'R window')
    -> grid(-column=>0, -row=>4, -sticky=>'e', -columnspan=>2, -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_rwindow} = $fr -> Optionmenu(-textvariable => \$temp{op_rwindow},
					   -borderwidth=>1,)
    -> grid(-column=>2, -row=>4, -sticky=>'w', -columnspan=>4);
  foreach my $i ($paths{data0}->Windows) { #($setup->Windows) {
    my $l = ucfirst($i);
    ($i eq "kaiser-bessel") and ($l = "Kaiser-Bessel");
    $widgets{op_rwindow} -> command(-label => $l,
				    -command=>
				    sub{
				      my $this = $paths{$current}->data;
				      $paths{$this}->make(rwindow=>$i);
				      &toggle_do('q');
				      $temp{op_rwindow} = ucfirst($l);
				      ($temp{op_rwindow} eq "kaiser-bessel") and
					($temp{op_rwindow} = "Kaiser-Bessel");
				      project_state(0);
				    })
  };



  ## k-weighting
  $fr = $widgets{chi_frame} -> Frame()
    -> pack(-side=>'bottom', -padx=>12, -pady=>4);

  ## fitting space and other fit params
  $left = $fr -> LabFrame(-label      => 'Other parameters',
			  -font	      => $config{fonts}{med},
			  -foreground => $config{colors}{activehighlightcolor},
			  -labelside  => 'acrosstop',
			  -width      => 14)
    -> pack(-side=>'left', -padx=>4, -fill=>'x', -anchor=>'n');
  &labframe_help($left);
  push @op_text, $left;
  my $inner = $left -> Frame()
    -> pack(-side=>'top', -fill=>'x', -padx=>2, -pady=>2);
  $t = $inner -> Label(@start, -text=>'Fitting space ',)
    -> pack(-side=>'left', -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_fitspace} = $inner -> Optionmenu(-textvariable => \$temp{op_fitspace},
					       -borderwidth=>1,)
    -> pack(-side=>'left');
  foreach my $i (qw(k R q)) {
    $widgets{op_fitspace} -> command(-label => $i,
				     -command=>sub{my $curr;
						   ($current =~ /(\d+)$/) and ($curr = $1);
						   foreach my $d (&every_data) {
						     $paths{$d}->make(fit_space=>$i);
						   };
						   project_state(0);
						   $temp{op_fitspace} = $i; })
  };
  $t = $inner -> Label(-text=>' ',)
    -> pack(-side=>'left');
  $t = $inner -> Label(-text=>'Epsilon ', @start,)
    -> pack(-side=>'left', -padx=>0);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_epsilon_k} = $inner -> Entry(-width=>6,
					   -validate=>'key',
					   -validatecommand=>[\&set_opparam, 'epsilon_k'])
    -> pack(-side=>'left');

  $inner =  $left -> Frame()
    -> pack(-side=>'top', -fill=>'x', -padx=>2, -pady=>2);
  $t = $inner -> Label(@start, -text=>'Minimum reported correlation ')
    -> pack(-side=>'left', -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_cormin} = $inner -> Entry(-width=>6,
					-validate=>'key',
					-validatecommand=>[\&set_opparam, 'cormin'])
    -> pack(-side=>'left');


  ## phase corrections and epsilon_k
  $t = $left -> Label(@start, -text=>'Path to use for phase corrections  ',)
    -> pack(-side=>'top', -anchor=>'w', -padx=>2);
  &click_help($t);
  push @op_text, $t;
  $widgets{op_pcpath} = $left -> Optionmenu(-textvariable => \$temp{op_pcpath_label},
					    -borderwidth=>1,)
    -> pack(-side=>'top', -anchor=>'e', -padx=>5);

  $widgets{help_op} = $left -> Button(-text => "Document: Fitting parameters", @button2_list,
				      -command=>sub{pod_display("artemis_opparams.pod")},
				      )
    -> pack(-side=>'bottom', -padx=>2, -fill=>'x', -pady=>2);




  my $right = $fr -> LabFrame(-label	  => 'Fit k-weights',
			      -font	  => $config{fonts}{med},
			      -foreground => $config{colors}{activehighlightcolor},
			      -labelside  => 'acrosstop',
			      -width	  => 14)
    -> pack(-side=>'right', -padx=>4, -fill=>'x', -anchor=>'n');
  &labframe_help($right);
  push @op_text, $right;
  $widgets{op_k1} = $right ->
    Checkbutton(-text=>'kw=1',
		-foreground=>$config{colors}{foreground},
		-activeforeground=>$config{colors}{foreground},
		-selectcolor=>$config{colors}{check},
		-font=>$config{fonts}{med},
		-variable=>\$temp{op_k1},
		-onvalue=>1, -offvalue=>0,
		-command=>
		sub{
		  $paths{$current}->make(k1=>$temp{op_k1});
		  project_state(0);
		}
	       )
    -> pack(-side=>'top', -anchor=>'w');
  $widgets{op_k2} = $right ->
    Checkbutton(-text=>'kw=2',
		-foreground=>$config{colors}{foreground},
		-activeforeground=>$config{colors}{foreground},
		-selectcolor=>$config{colors}{check},
		-font=>$config{fonts}{med},
		-variable=>\$temp{op_k2},
		-onvalue=>1, -offvalue=>0,
		-command=>
		sub{
		  $paths{$current}->make(k2=>$temp{op_k2});
		  project_state(0);
		}
	       )
    -> pack(-side=>'top', -anchor=>'w');
  $widgets{op_k3} = $right ->
    Checkbutton(-text=>'kw=3',
		-foreground=>$config{colors}{foreground},
		-activeforeground=>$config{colors}{foreground},
		-selectcolor=>$config{colors}{check},
		-font=>$config{fonts}{med},
		-variable=>\$temp{op_k3},
		-onvalue=>1, -offvalue=>0,
		-command=>
		sub{
		  $paths{$current}->make(k3=>$temp{op_k3});
		  project_state(0);
		}
	       )
    -> pack(-side=>'top', -anchor=>'w');
  $widgets{op_karb_use} = $right ->
    Checkbutton(-text=>'other k weight',
		-foreground=>$config{colors}{foreground},
		-activeforeground=>$config{colors}{foreground},
		-selectcolor=>$config{colors}{check},
		-font=>$config{fonts}{med},
		-variable=>\$temp{op_karb_use},
		-onvalue=>1, -offvalue=>0,
		-command=>
		sub{
		  $widgets{op_karb} ->
		    configure(-state=>$temp{op_karb_use} ? 'normal' : 'disabled');
		  $paths{$current}->make(karb_use=>$temp{op_karb_use});
		  project_state(0);
		}
	       )
    -> pack(-side=>'top', -anchor=>'w');
  $widgets{op_karb} = $right -> Entry(-width=>6,
				      -validate=>'key',
				      -validatecommand=>[\&set_opparam, 'karb'])
    -> pack(-side=>'right', -anchor=>'se');


  ## fill in the mu(E) tab
  $fr = $widgets{mu_frame} -> LabFrame(-label	   => 'Background Removal Parameters',
				       -font	   => $config{fonts}{med},
				       -foreground => $config{colors}{activehighlightcolor},
				       -labelside  => 'acrosstop',)
    -> pack(-fill=>'x', -anchor=>'n', -pady=>2);
  $fr -> Label(@start, -text=>'E0')
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widgets{bkg_e0} = $fr -> Entry(-width=>9,
				  -validate=>'key',
				  -validatecommand=>[\&set_opparam, 'bkg_e0'])
    -> grid(-row=>0, -column=>1, -sticky=>'w');

  $fr -> Label(@start, -text=>'E shift')
    -> grid(-row=>0, -column=>3, -sticky=>'e');
  $widgets{bkg_eshift} = $fr -> Entry(-width=>9,
				      -validate=>'key',
				      -validatecommand=>[\&set_opparam, 'bkg_eshift'])
    -> grid(-row=>0, -column=>4, -sticky=>'w');

  $fr -> Label(@start, -text=>'Rbkg')
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $widgets{bkg_rbkg} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_rbkg'])
    -> grid(-row=>1, -column=>1, -sticky=>'w');

  $fr -> Label(@start, -text=>'kw')
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $widgets{bkg_kw} = $fr -> Entry(-width=>9,
				  -validate=>'key',
				  -validatecommand=>[\&set_opparam, 'bkg_kw'])
    -> grid(-row=>2, -column=>1, -sticky=>'w');

  $fr -> Label(@start, -text=>'step')
    -> grid(-row=>2, -column=>3, -sticky=>'e');
  $widgets{bkg_step} = $fr -> NumEntry(-width=>6,
				       -orient=>'horizontal',
				       -increment=>0.1)
    -> grid(-row=>2, -column=>4, -sticky=>'w');
  $widgets{bkg_fixstep} = $fr -> Checkbutton(-text=>'fix step',
					     -foreground=>$config{colors}{foreground},
					     -activeforeground=>$config{colors}{foreground},
					     -selectcolor=>$config{colors}{check},
					     -font=>$config{fonts}{med},
					     -variable=>\$temp{bkg_fixstep},
					     -onvalue=>1, -offvalue=>0,
					     -command=> sub{ $paths{$current}->make(bkg_fixstep=>$temp{bkg_fixstep});
							     project_state(0);
							   },
					    )
    -> grid(-row=>2, -column=>5, -sticky=>'w');
  $widgets{bkg_flatten} = $fr -> Checkbutton(-text=>'flatten',
					     -foreground=>$config{colors}{foreground},
					     -activeforeground=>$config{colors}{foreground},
					     -selectcolor=>$config{colors}{check},
					     -font=>$config{fonts}{med},
					     -variable=>\$temp{bkg_flatten},
					     -onvalue=>1, -offvalue=>0,
					     -command=> sub{ $paths{$current}->make(bkg_flatten=>$temp{bkg_flatten});
							     project_state(0);
							   },
					    )
    -> grid(-row=>1, -column=>5, -sticky=>'w');


  $fr -> Label(@start, -text=>'Pre-edge')
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $widgets{bkg_pre1} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_pre1'])
    -> grid(-row=>3, -column=>1, -sticky=>'w');
  $grab{bkg_pre1} = $fr -> Button(@pluck_button, @pluck,
				  #-command=>[\&pluck, 'op_rmax']
				 )
    -> grid(-row=>3, -column=>2, -sticky=>'w');
  $fr -> Label(@start, -text=>' to ')
    -> grid(-row=>3, -column=>3, -sticky=>'e');
  $widgets{bkg_pre2} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_pre2'])
    -> grid(-row=>3, -column=>4, -sticky=>'w');
  $grab{bkg_pre2} = $fr -> Button(@pluck_button, @pluck,
				  #-command=>[\&pluck, 'op_rmax']
				 )
    -> grid(-row=>3, -column=>5, -sticky=>'w');

  $fr -> Label(@start, -text=>'Normalization')
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $widgets{bkg_nor1} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_nor1'])
    -> grid(-row=>4, -column=>1, -sticky=>'w');
  $grab{bkg_nor1} = $fr -> Button(@pluck_button, @pluck,
				  #-command=>[\&pluck, 'op_rmax']
				 )
    -> grid(-row=>4, -column=>2, -sticky=>'w');
  $fr -> Label(@start, -text=>' to ')
    -> grid(-row=>4, -column=>3, -sticky=>'e');
  $widgets{bkg_nor2} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_nor2'])
    -> grid(-row=>4, -column=>4, -sticky=>'w');
  $grab{bkg_nor2} = $fr -> Button(@pluck_button, @pluck,
				  #-command=>[\&pluck, 'op_rmax']
				 )
    -> grid(-row=>4, -column=>5, -sticky=>'w');

  $fr -> Label(@start, -text=>'Spline')
    -> grid(-row=>5, -column=>0, -sticky=>'e');
  $widgets{bkg_spl1} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_spl1'])
    -> grid(-row=>5, -column=>1, -sticky=>'w');
  $grab{bkg_spl1} = $fr -> Button(@pluck_button, @pluck,
				  #-command=>[\&pluck, 'op_rmax']
				 )
    -> grid(-row=>5, -column=>2, -sticky=>'w');
  $fr -> Label(@start, -text=>' to ')
    -> grid(-row=>5, -column=>3, -sticky=>'e');
  $widgets{bkg_spl2} = $fr -> Entry(-width=>9,
				    -validate=>'key',
				    -validatecommand=>[\&set_opparam, 'bkg_spl2'])
    -> grid(-row=>5, -column=>4, -sticky=>'w');
  $grab{bkg_spl2} = $fr -> Button(@pluck_button, @pluck,
				  #-command=>[\&pluck, 'op_rmax']
				 )
    -> grid(-row=>5, -column=>5, -sticky=>'w');

  $fr -> Label(@start, -text=>'High end clamp')
    -> grid(-row=>6, -column=>0, -sticky=>'e');
  $widgets{bkg_clamp2} = $fr -> Optionmenu(-options  => ['None', 'Slight', 'Weak', 'Medium', 'Strong', 'Rigid'],
					   -command  => sub{ $paths{$current}->make(bkg_clamp2=>$temp{bkg_clamp2}, do_xmu=>1);
							     project_state(0);
							   },
					   -textvariable => \$temp{bkg_clamp2},
					  )
    -> grid(-row=>6, -column=>1, -columnspan=>2, -sticky=>'w');



#  $fr = $widgets{mu_frame} -> LabFrame(-label=>'mu(E) plot controls',
#                                      -font=>$config{fonts}{med},
#				       -foreground=>$config{colors}{activehighlightcolor},
#				       -labelside=>'acrosstop',)
  $fr = $widgets{mu_frame} -> Frame(-borderwidth => 2,
				    -relief      => 'groove')
    -> pack(-anchor=>'n', -pady=>0);

  $fr -> Checkbutton(-text=>'mu(E) data')
    -> grid(-column=>0, -row=>0, -sticky=>'w');
  $fr -> Checkbutton(-text=>'background')
    -> grid(-column=>1, -row=>0, -sticky=>'w');
  $fr -> Checkbutton(-text=>'pre edge line')
    -> grid(-column=>0, -row=>1, -sticky=>'w');
  $fr -> Checkbutton(-text=>'post edge line')
    -> grid(-column=>1, -row=>1, -sticky=>'w');
  $fr -> Checkbutton(-text=>'normalized')
    -> grid(-column=>0, -row=>2, -sticky=>'w');
  $fr -> Checkbutton(-text=>'derivative')
    -> grid(-column=>1, -row=>2, -sticky=>'w');
  $fr -> Button(-text=>'Plot in energy', -width=>20, @button_list)
    -> grid(-column=>2, -row=>0, -sticky=>'ew');
  $fr -> Button(-text=>'Save chi(k)', -width=>20, @button_list)
    -> grid(-column=>2, -row=>2, -sticky=>'ew');

  return $c;
};

sub pluck {
  my $widg = $_[0];
  my $parent = $_[1] || $top;
  Echo("You have not made a plot yet."), return 0
    unless ($last_plot);

  if (($last_plot eq 'r') and ($widg =~ /^op_k/)) {
    Echo("You cannot pluck an k value from the last plot, which was an R plot.");
    return 0;
  } elsif (($last_plot eq 'k') and ($widg =~ /^op_r/)) {
    Echo("You cannot pluck an R value from the last plot, which was an k plot.");
    return 0;
  } elsif (($last_plot eq 'q') and ($widg =~ /^op_r/)) {
    Echo("You cannot pluck an R value from the last plot, which was an q plot.");
    return 0;
  };
  Echo("Select a value for $widg from the plot...");
  my ($cursor_x, $cursor_y) = (0,0);
  $grab{$widg} -> grab();
  $top -> Busy();
  my $data = &first_data;
  $paths{$data}->dispose("cursor(crosshair=true)\n", 1);
  ($cursor_x, $cursor_y) = (Ifeffit::get_scalar("cursor_x"),
			    Ifeffit::get_scalar("cursor_y"));
  $top -> Unbusy;
  $grab{$widg} -> grabRelease();
  my $value = sprintf("%.3f", $cursor_x);
  my $which = substr($widg, 3);
  set_opparam($which, $value, 1);
  #Echo("Plucked the value of $value for " . (split(/_/, $widg))[1] );
  $widgets{$widg} -> configure(-validate=>'none');
  $widgets{$widg} -> delete(qw/0 end/);
  $widgets{$widg} -> insert(0, $value);
  $widgets{$widg} -> configure(-validate=>'key');
  return 1;
};


## lab frame labels...
sub click_help {
  my $t = shift;
  my $text = $t->cget('-text');
  $text =~ s/\s+$//;

  ## don't post mouse-3 menu for some parameters
  my $skip = ($text =~ /^(Data|Epsilon|Path)/);

  my @bold   = (-foreground => $config{colors}{mbutton},
		-background => $config{colors}{activebackground},
		-cursor     => $mouse_over_cursor,
		-font       => ($text =~ /Data file/) ? $config{fonts}{bold} : $config{fonts}{med});
  my @normal = (-foreground => $config{colors}{activehighlightcolor},
		-background => $config{colors}{background},
		-font       => ($text =~ /Data file/) ? $config{fonts}{bold} : $config{fonts}{med});
  my @nodata = (-foreground => $config{colors}{activehighlightcolor},
		-background => $config{colors}{background},
		-font       => ($text =~ /Data file/) ? $config{fonts}{bold} : $config{fonts}{med});

  $t -> bind("<Any-Enter>", sub {shift->configure(@bold)});
  $t -> bind("<Any-Leave>", sub {my $tt=shift;
				 if ($n_data) {
				   $tt->configure(@normal);
				 } else {
				   $tt->configure(@nodata);
				 }
			       });

  my $str = $click_help{$text} || "$text ???";
  $t -> bind('<ButtonPress-1>' => sub{Echo("$str")});
  $t -> bind("<ButtonPress-3>",
	     sub{ return unless $n_data;
	          my @every = &every_data;
		  my $menu=$top->Menu(-tearoff=>0,
				      -menuitems=>[(($text =~ /^(Minimum)/) ? () :
						    (["command"=>"Set all data sets to this value of \`$text\'",
						      -command => [\&constrain_param, $text, 'all'],
						      -state=>($#every)?'normal':'disabled'],
						     "-",
						     ["command"=>"Grab \`$text\' from previous data set",
						      -command => [\&constrain_param, $text, 'prev'],
						      -state=>($#every)?'normal':'disabled' ],
						     ["command"=>"Grab \`$text\' from next data set",
						      -command => [\&constrain_param, $text, 'next'],
						      -state=>($#every)?'normal':'disabled' ],
						     "-",)),
						   [ command => "Restore default value for \`$text\'",
						     -command => [\&restore_default, $text]],
						  ]);
		  $menu ->Popup(-popover=>'cursor', -popanchor=>'w');
		})
    unless $skip;
};

sub labframe_help {
  my $lf = $_[0];
  my $t = $lf->Subwidget("label");
  my $text = $t->cget('-text');
  $text =~ s/\s+$//;

  my $skip = ($text !~ /^(Fit|Fourier|Space)/);

  my @bold   = (-foreground => $config{colors}{mbutton},
		-cursor     => $mouse_over_cursor,
	       );
  my @normal = (-foreground => $config{colors}{activehighlightcolor},);
  my @nodata = (-foreground => $config{colors}{activehighlightcolor},);

  $t -> bind("<Any-Enter>", sub {shift->configure(@bold)});
  $t -> bind("<Any-Leave>", sub {my $tt=shift;
				 if (($n_data) or ($text =~ /^Space/)) {
				   $tt->configure(@normal);
				 } else {
				   $tt->configure(@nodata);
				 }});
  my $str = $click_help{$text} || "$text ???";
  $t -> bind('<ButtonPress-1>' => sub{Echo("$str")});
  $t -> bind("<ButtonPress-3>",
	     sub{ return unless $n_data;
	          my @every = &every_data;
		  my $menu=$top->Menu(-tearoff=>0,
				      -menuitems=>[["command"=>"Set all data sets to this value of \`$text\'",
						    -command => [\&constrain_param, $text, 'all'],
						    -state=>($#every)?'normal':'disabled'],
						   "-",
						   ["command"=>"Grab \`$text\' from previous data set",
						    -command => [\&constrain_param, $text, 'prev'],
						    -state=>($#every)?'normal':'disabled' ],
						   ["command"=>"Grab \`$text\' from next data set",
						    -command => [\&constrain_param, $text, 'next'],
						    -state=>($#every)?'normal':'disabled' ],
						   "-",
						   [ command => "Restore default value for \`$text\'",
						     -command => [\&restore_default, $text]],
						  ]);
		  $menu ->Popup(-popover=>'cursor', -popanchor=>'w');
		})
    unless $skip;

};


sub constrain_param {
  my ($which, $how) = @_;
  $which = lc($which);
  my $this = $paths{$current}->data;
  my @vars = ();
WHICH: {
    @vars = (qw(kmin kmax)), last WHICH if ($which eq 'k-range');
    @vars = (qw(rmin rmax)), last WHICH if ($which eq 'r-range');
    @vars = (qw(dk)),        last WHICH if ($which eq 'dk');
    @vars = (qw(dr)),        last WHICH if ($which eq 'dr');
    @vars = (qw(kwindow)),   last WHICH if ($which eq 'k window');
    @vars = (qw(rwindow)),   last WHICH if ($which eq 'r window');
    @vars = (qw(pcpath)),    last WHICH if ($which =~ /^Path/);
    @vars = (qw(epsilon_k)), last WHICH if ($which eq 'epsilon');
    @vars = (qw(k1 k2 k3 karb karb_use)),
      last WHICH if ($which =~ /^fit/);
    @vars = (qw(kmin kmax dk rmin rmax dr kwindow rwindow)),
      last WHICH if ($which =~ /^fourier/);
  };
 HOW: {
    ($how eq 'all') and do {
      foreach my $d (&every_data) {
	foreach my $v (@vars) {
	  next if ($d eq $this);
	  $paths{$d} -> make($v=>$paths{$this}->get($v));
	};
      };
      &display_properties;
      project_state(0);
      Echo("Set \`$which\' for all data sets");
      last HOW;
    };
    ($how eq 'next') and do {
      my $found = 0;
      my $next  = "";
      foreach my $d (sort(&all_data)) {
	($next = $d), last if $found;
	($found = 1) if ($d eq $this);
      };
      Error("This is the last data set"), last HOW unless $next;
      foreach my $v (@vars) {
	$paths{$this} -> make($v=>$paths{$next}->get($v));
      };
      &display_properties;
      project_state(0);
      Echo("Grabbed \`$which\' from the next data set");
      last HOW;
    };
    ($how eq 'prev') and do {
      my $found = 0;
      my $prev  = "";
      foreach my $d (sort(&all_data)) {
	last if ($d eq $this);
	$prev = $d;
      };
      Error("This is the first data set"), last HOW unless $prev;
      foreach my $v (@vars) {
	$paths{$this} -> make($v=>$paths{$prev}->get($v));
      };
      &display_properties;
      project_state(0);
      Echo("Grabbed \`$which\' from the previous data set");
      last HOW;
    };
  };

};


sub restore_default {
  my $which = $_[0];
  $which = lc($which);
  my $this = $paths{$current}->data;
  my @vars = ();
WHICH: {
    @vars = (qw(kmin kmax)), last WHICH if ($which eq 'k-range');
    @vars = (qw(rmin rmax)), last WHICH if ($which eq 'r-range');
    @vars = (qw(dk)),        last WHICH if ($which eq 'dk');
    @vars = (qw(dr)),        last WHICH if ($which eq 'dr');
    @vars = (qw(kwindow)),   last WHICH if ($which eq 'k window');
    @vars = (qw(rwindow)),   last WHICH if ($which eq 'r window');
    @vars = (qw(fit_space)), last WHICH if ($which eq 'fitting space');
    @vars = (qw(cormin)),    last WHICH if ($which =~ /^minimum/);
    #@vars = (qw(pcpath)),    last WHICH if ($which =~ /^Path/);
    @vars = (qw(k1 k2 k3 karb karb_use)),
      last WHICH if ($which =~ /^fit/);
    @vars = (qw(kmin kmax dk rmin rmax dr kwindow rwindow)),
      last WHICH if ($which =~ /^fourier/);
    @vars = (qw(kmin kmax rmin rmax dk dr kwindow rwindow k1 k2 k3 karb karb_use)),
      last WHICH if ($which eq 'all');
  };
  foreach my $v (@vars) {
    if ($v =~ /^k(1|2|3|arb(|_use))/) {
      $temp{'op_'.$v} = ($v eq "k".$config{data}{kweight}) ? 1 : 0;
      $paths{$this} -> make($v=>($v eq 'k1') ? 1 : 0);
      $widgets{op_karb} -> delete(0,'end') if $v eq 'karb_use';
    } else {
      $paths{$this} -> make($v=>$config{data}{$v});
    }
  };
  $paths{$this} -> fix_values;
  &display_properties;
  project_state(0);
  ($which eq 'all') ? Echo("Restored all parameters to their defaults")
    : Echo("Restored \`$which\' to it's default");
};


sub set_spline {
  my $how = $_[0];
 HOW: {
    ($how eq 'allon') and do {
      foreach my $d (&all_data) {
	$paths{$d} -> make(do_bkg => 'yes');
      };
      &display_properties;
      last HOW;
    };
    ($how eq 'alloff') and do {
      foreach my $d (&all_data) {
	$paths{$d} -> make(do_bkg => 'no');
      };
      &display_properties;
      last HOW;
    };
  };
};

sub toggle_do {
  my $sp = "do_" . $_[0];
  my $this = $paths{$current}->data;
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($k =~ /$this/);
    $paths{$k} -> make($sp=>1);
  };
};



sub set_plotoptions {

  my $container = $_[0];
  my %parts = (m=>'Magnitude', r=>'Real part', i=>'Imaginary part', p=>'Phase');

  my $frm = $container -> Frame(-borderwidth=>2, -relief=>'groove')
    -> pack(-fill=>'x', -anchor=>'w', -pady=>4);

  $plot_features{r_pl} ||= 'm';
  $plot_features{r_pl_label} = $parts{$plot_features{r_pl}};
  $frm -> Label(-text	    => 'Plot in R: ',
		-font	    => $config{fonts}{med},
		-foreground => $config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  ##   $widgets{plot_r} = $frm -> Optionmenu(-textvariable => \$plot_features{r_pl_label},
  ## 					-width=>12,
  ## 					-borderwidth=>1,)
  ##     -> grid(-row=>0, -column=>1, -sticky=>'w');
  my $r = 0;
  my @list = ($config{plot}{plot_phase}) ? (qw(m r i p)) : (qw(m r i));
  foreach my $p (@list) {
    $frm -> Radiobutton(-value	  => $p,
			-font	  => $config{fonts}{med},
			-text	  => $parts{$p},
			-selectcolor=>$config{colors}{check},
			-variable => \$plot_features{r_pl},
			-command  => sub{$plot_features{r_pl} = $p;
					 &plot('r', 0) }
		       )
      -> grid(-row=>$r++, -column=>1, -sticky=>'w');
    ##     $widgets{plot_r} -> command(-label => $parts{$p},
    ##  				-command=>sub{$plot_features{r_pl} = $p;
    ## 					      $plot_features{r_pl_label} = $parts{$p};
    ##  					      &plot('r', 0) }
    ## 			       );
  };


  $plot_features{q_pl} ||= 'r';
  $plot_features{q_pl_label} = $parts{$plot_features{q_pl}};
  $frm -> Label(-text	    => 'Plot in q: ',
		-font	    => $config{fonts}{med},
		-foreground => $config{colors}{activehighlightcolor})
    -> grid(-row=>$r, -column=>0, -sticky=>'e');
  foreach my $p (@list) {
    $frm -> Radiobutton(-value	  => $p,
			-font	  => $config{fonts}{med},
			-text	  => $parts{$p},
			-selectcolor=>$config{colors}{check},
			-variable => \$plot_features{q_pl},
			-command  => sub{$plot_features{q_pl} = $p;
					 &plot('q', 0) }
		       )
      -> grid(-row=>$r++, -column=>1, -sticky=>'w');
  };

  $plot_features{win} ||= 0;
  $widgets{plot_win} = $container ->
    Checkbutton(-text		  => 'Window',
		-font		  => $config{fonts}{med},
		-onvalue	  => 'w',
		-offvalue         => "",
		-selectcolor	  => $config{colors}{check},
		-foreground	  => $config{colors}{activehighlightcolor},
		-activeforeground => $config{colors}{activehighlightcolor},
		-variable	  => \$plot_features{win},
		-command	  => sub{&plot($last_plot, 0)}
	       )
      -> pack();
  $widgets{plot_bkg} = $container ->
    Checkbutton(-text		  => 'Background',
		-font		  => $config{fonts}{med},
		-onvalue	  => 'b',
		-offvalue         => "",
		-selectcolor	  => $config{colors}{check},
		-activeforeground => $config{colors}{activehighlightcolor},
		-foreground	  => $config{colors}{activehighlightcolor},
		-variable	  => \$plot_features{bkg},
		-command	  => sub{&plot($last_plot, 0)}
	       )
      -> pack();

  $widgets{plot_res} = $container ->
    Checkbutton(-text		  => 'Residual',
		-font		  => $config{fonts}{med},
		-onvalue	  => 'z',
		-offvalue	  => "",
		-selectcolor	  => $config{colors}{check},
		-foreground	  => $config{colors}{activehighlightcolor},
		-activeforeground => $config{colors}{activehighlightcolor},
		-variable	  => \$plot_features{res},
		-command	  => sub{&plot($last_plot, 0)}
	       )
      -> pack();


  $frm = $container -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -anchor=>'s');
  $plot_features{kmin} ||= 0;
  $plot_features{rmin} ||= 0;
  $plot_features{qmin} ||= 0;
  $plot_features{kmax} ||= 15;
  $plot_features{rmax} ||= 6;
  $plot_features{qmax} ||= 15;
  my $row = 0;
  foreach my $s (qw(k R q)) {
    $frm -> Label(-text	      => $s.'min:',
		  -font	      => $config{fonts}{med},
		  -foreground => $config{colors}{activehighlightcolor})
      -> grid(-row=>$row, -column=>0);
    $widgets{'plot_'.lc($s).'min'} = $frm ->
      Entry(-width=>5, -textvariable=>\$plot_features{lc($s).'min'}, -state=>'normal')
      -> grid(-row=>$row, -column=>1);
    $frm -> Label(-text	      => $s.'max:',
		  -font	      => $config{fonts}{med},
		  -foreground => $config{colors}{activehighlightcolor})
      -> grid(-row=>$row, -column=>2);
    $widgets{'plot_'.lc($s).'max'} = $frm ->
      Entry(-width=>5, -textvariable=>\$plot_features{lc($s).'max'}, -state=>'normal')
      -> grid(-row=>$row++, -column=>3);
  };
};


sub show_extra_plot {
  $widgets{plot_extra_button} -> packForget;
  $widgets{plot_extra_frame}  -> pack(-fill => 'both', -side => 'top', -expand=>1);
};
sub remove_extra_plot {
  $widgets{plot_extra_frame}  -> packForget;
  $widgets{plot_extra_button} -> pack(-fill => 'x', -side => 'bottom', -padx=>2, -pady=>4);
};

sub setup_indicators {
  my @pluck_button  = (-foreground       => $config{colors}{highlightcolor},
		       -activeforeground => $config{colors}{activehighlightcolor},
		       -background       => $config{colors}{background},
		       -activebackground => $config{colors}{activebackground});
  my $pluck_bitmap = '#define pluck_width 9
#define pluck_height 9
static unsigned char pluck_bits[] = {
   0x81, 0x01, 0xc3, 0x00, 0x66, 0x00, 0x3c, 0x00, 0x38, 0x00, 0x78, 0x00,
   0xcc, 0x00, 0x86, 0x01, 0x03, 0x01};
';
  my $pluck_X = $top -> Bitmap('pluck', -data=>$pluck_bitmap,
			       -foreground=>$config{colors}{activehighlightcolor});
  my @pluck=(-image=>$pluck_X);
  my $frame = $widgets{plot_Ind} -> Frame() -> pack(-anchor=>'n', -fill=>'both');
  $frame -> Label(-text=>"Plot indicators",
		  -font=>$config{fonts}{bold},
		  -foreground=>$config{colors}{activehighlightcolor})
     -> pack(-side=>'top');
  $extra[5] = 0;
  $frame -> Checkbutton(-text=>'Display indicators',
			-selectcolor=>$config{colors}{check},
			-variable=>\$extra[5])
    -> pack(-expand=>1, -fill=>'x', -side=>'top', -anchor=>'n');
##   my $t = $frame -> Scrolled('Pane',
## 			     -scrollbars  => 'oe',
## 			     -width	      => 1,
## 			     -height      => 1,
## 			     -borderwidth => 0,
## 			     -relief      => 'flat')
  my $t = $frame -> Frame()
    -> pack(-expand=>1, -fill=>'both', -side=>'top', -padx=>3, -pady=>3, -anchor=>'n');
##   $t -> Subwidget("yscrollbar")
##     -> configure(-background=>$config{colors}{background},
## 		 ($is_windows) ? () : (-width=>9));
  #BindMouseWheel($t);
  #&disable_mouse3($t->Subwidget('rotext'));
  foreach my $r (7 .. $config{plot}{nindicators}+6) {
    $extra[$r] = ["", " ", " "];
    my $rr = $r-6;
    $t -> Label(-text=>$rr.":", -foreground=>$config{colors}{activehighlightcolor})
      -> grid(-row=>$r, -column=>0, -ipadx=>3);
    $t -> Label(-textvariable=>\$extra[$r][1],
		-width=>3)
      -> grid(-row=>$r, -column=>1);
    my $this = $t -> Entry(-width	    => 10,
			   -textvariable    => \$extra[$r][2],
			   -validate	    => 'key',
			   -validatecommand => [\&set_opparam, "extra"],
			  )
      -> grid(-row=>$r, -column=>2);
    $extra[$r][0] = $t -> Button(@pluck_button, @pluck, -command=>sub{&indicator_pluck($r)})
      -> grid(-row=>$r, -column=>3);
  };
};
sub indicator_pluck {
  my $which = $_[0];
  Error("You have not made a plot yet."), return 0 unless ($last_plot);

  Echo("Select a point from the plot...");
  my ($cursor_x, $cursor_y) = (0,0);
  $extra[$which][0] -> grab();
  $paths{data0}->dispose("cursor(crosshair=true)\n", $dmode);
  ($cursor_x, $cursor_y) = (Ifeffit::get_scalar("cursor_x"),
			    Ifeffit::get_scalar("cursor_y"));
  $paths{data0}->dispose("\n", $dmode);
  $extra[$which][0] -> grabRelease();
  $extra[$which][1] = ($last_plot =~ /[kq]/) ? $last_plot : uc($last_plot);
  $extra[$which][2] = sprintf("%.3f", $cursor_x);
  Echo("Made an indicator at $extra[$which][2] in $extra[$which][1]");
  #$Data::Dumper::Indent = 2;
  #print Data::Dumper->Dump([\@extra], [qw(extra)]);
  #$Data::Dumper::Indent = 0;
};

sub setup_stack {
  my $frame = $widgets{plot_Sta} -> Frame(-borderwidth=>2, -relief=>'ridge')
    -> pack(-anchor=>'n', -fill=>'x', -side=>'top');
  $frame -> Label(-text=>"Stack plots",
		  -font=>$config{fonts}{bold},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -columnspan=>2, -sticky=>'ew');
  $frame -> Radiobutton(-text	  => 'Never',
			-font	  => $config{fonts}{med},
			-selectcolor=>$config{colors}{check},
			#-width	  => 12,
			-variable => \$extra[0],
			-value    => 0)
    -> grid(-row=>1, -column=>0, -columnspan=>2, -sticky=>'w');
  $frame -> Radiobutton(-text	  => 'Only chi(k)',
			-font	  => $config{fonts}{med},
			-selectcolor=>$config{colors}{check},
			#-width	  => 12,
			-variable => \$extra[0],
			-value	  => 1)
    -> grid(-row=>2, -column=>0, -columnspan=>2, -sticky=>'w');
  $frame -> Radiobutton(-text	  => 'Always',
			-font	  => $config{fonts}{med},
			-selectcolor=>$config{colors}{check},
			#-width	  => 12,
			-variable => \$extra[0],
			-value	  => 2)
    -> grid(-row=>3, -column=>0, -columnspan=>2, -sticky=>'w');
  $frame -> Label(-text => 'Starting value:',
		  -font => $config{fonts}{med},)
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $frame -> Entry(-width	=> 8,
		  -textvariable	=> \$extra[1],
		  -validate     => 'key',
		  -validatecommand => [\&set_opparam, 'extra'])
    -> grid(-row=>4, -column=>1, -sticky=>'w');
  $frame -> Label(-text => 'Increment:',
		  -font => $config{fonts}{med},)
    -> grid(-row=>5, -column=>0, -sticky=>'e');
  $frame -> Entry(-width	=> 8,
		  -textvariable	=> \$extra[2],
		  -validate     => 'key',
		  -validatecommand => [\&set_opparam, 'extra'])
    -> grid(-row=>5, -column=>1, -sticky=>'w');

  ## invert
  $frame = $widgets{plot_Sta} -> Frame(-borderwidth=>2, -relief=>'ridge')
    -> pack(-anchor=>'n', -fill=>'x', -side=>'top');
  $frame -> Label(-text=>"Invert paths",
		  -font=>$config{fonts}{bold},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0);
  $frame -> Radiobutton(-text	  => 'Never',
			-font	  => $config{fonts}{med},
			-selectcolor=>$config{colors}{check},
			#-width	  => 12,
			-variable => \$extra[4],
			-value	  => 0)
    -> grid(-row => 1, -column=>0, -sticky=>'w');
  $frame -> Radiobutton(-text	  => 'Only |chi(R)|',
			-font	  => $config{fonts}{med},
			-selectcolor=>$config{colors}{check},
			#-width	  => 12,
			-variable => \$extra[4],
			-value	  => 1)
    -> grid(-row => 2, -column=>0, -sticky=>'w');
  $frame -> Radiobutton(-text	  => '|chi(R)| and |chi(q)|',
			-font	  => $config{fonts}{med},
			-selectcolor=>$config{colors}{check},
			#-width	  => 12,
			-variable => \$extra[4],
			-value	  => 2)
    -> grid(-row=>3, -column=>0, -sticky=>'w');

  ## MDS offset
  $frame = $widgets{plot_Sta} -> Frame(-borderwidth=>2, -relief=>'ridge')
    -> pack(-anchor=>'n', -fill=>'x', -side=>'top');
  $frame -> Label(-text=>"Stack data sets",
		  -font=>$config{fonts}{bold},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -columnspan=>2, );
  $frame -> Label(-text => 'Offset:',
		  -font => $config{fonts}{med},)
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $frame -> Entry(-width	=> 8,
		  -textvariable	=> \$extra[3],
		  -validate     => 'key',
		  -validatecommand => [\&set_opparam, 'extra'])
    -> grid(-row=>1, -column=>1, -sticky=>'w');

};


sub display_page {
  $list->anchorSet($_[0]);
  $list->selectionClear;
  $list->selectionSet($_[0]);
  $list->see($_[0]);
  &display_properties;
};

sub display_properties {
  if ($_[1] and ($_[0] !~ /^\d+$/)) { # only respond to button press events
                                      # and not button release events
    #print "button event: ", join(" ", @_), $/;
    return unless defined $_[2];
  }; # the check on $_[0] does the right thing for mouse-2
  if (ref($paths{$current}) =~ /Ifeffit/) {
    &read_titles($current) if ($current =~ /data\d+(\.\d+)?$/);

    ## some chores to be done when clicking away from a feff calc
    if ($paths{$current}->type eq 'feff') {
      ## remember scrollbar positions in feff.inp and interpretation
      set_feff_showing($fefftabs->raised());
      ## save the atoms titles
      my $titles = $widgets{atoms_titles}->get('1.0', 'end');
      $titles =~ s/\n/<NL>/g;
      $paths{$current} -> make(atoms_titles=>$titles);
      ## save the feff.inp text
      my $feff_file = File::Spec->catfile($project_folder,
					  $paths{$current}->get('id'),
					  "feff.inp");
      $widgets{feff_inptext} -> Save($feff_file);
    } elsif ($paths{$current}->type eq 'data') {
      ##--bkg-- $paths{$current} -> make(data_showing=>$widgets{data_notebook}->raised);
    };

  };

  ## correct a hierarchy problem on windows...
  my $thelist = (ref($list) =~ m{Frame}) ? $list->Subwidget('tree') : $list;
  my $anchor = $thelist->info('anchor');
  $current = $anchor;
  return if (($current_canvas eq 'prefs') or
	     ($current_canvas eq 'histogram') or
	     ($current_canvas eq 'athena') or
	     ($current_canvas eq 'firstshell')
	    );
  foreach ($gsd_menu, $feff_menu, $paths_menu, $data_menu, $sum_menu, $fit_menu) { # , $settings_menu) {
    $_ -> configure(-state=>'normal');
  };
  $feff_menu  -> menu -> entryconfigure($_, -state=>'disabled') for (5..8, 11, 12, 13, 15, 17);
  $paths_menu -> menu -> entryconfigure($_, -state=>'disabled') for (1..3, 5..8, 10..13);
  $fit_menu   -> menu -> entryconfigure(1,  -state=>'disabled', -label=>"Restore this fit model");
  $fit_menu   -> menu -> entryconfigure($_, -state=>'disabled') for (3..8, 10..11, 14..15);
  unless ($thelist->info('hidden', $paths{$current}->data.".0")) {
    $file_menu  -> menu -> entryconfigure($_, -state=>'normal')   for ($save_index+1..$save_index+3)
  };
  ## worry about whether most recent fit had a bkg

  my $dd = $paths{$current}->data;
  my $latest = (exists $paths{$dd.".0"}) ? $paths{$dd.".0"}->get('thisfit') : 0;
  if ($latest and
      (-e File::Spec->catfile($project_folder, "fits", $paths{$latest}->get('folder'), $dd.".bkg"))) {
    $data_menu -> menu -> entryconfigure(2, -state=>'normal');
  } else {
    $file_menu -> menu -> entryconfigure($save_index+2, -state=>'disabled');
  };


  ## it is dangerous to leave focus on a widget when switching
  ## views. in that case typing while Artemis has mouse focus will
  ## result in typing in a widget out of view.  bad juju!
  $plotr_button -> focus();
  my $this_data = $paths{$current}->data;
  if ($anchor =~ /data\d+\.0(\.\d+)?$/) { # matches any fit
    $top -> Busy;
  SWITCH: {
      $opparams->packForget(), last SWITCH if ($current_canvas eq 'op');
      $gsd ->packForget(), last SWITCH if ($current_canvas eq 'gsd');
      $feff->packForget(), last SWITCH if ($current_canvas eq 'feff');
      $path->packForget(), last SWITCH if ($current_canvas eq 'path');
    };
    $logviewer->pack(-expand=>1, -fill=>'both');
    my $skip = 1 if ($current_canvas eq 'logview');
    $skip = 0 if $log_params{force};
    $current_canvas = 'logview';
    unless ($skip) {
      $log_params{param} ||= $gds[0]->name;
      &populate_logview;
    };
    map { $file_menu -> menu -> entryconfigure($_, -state=>'normal') } ($save_index..$save_index+4, $save_index+6);
    $fit_menu   -> menu -> entryconfigure($_, -state=>'normal') for (3..8, 10..11, 14..15);
    if ($anchor =~ /(data\d+)\.0.\d+$/) {   # not head of branch
      $fit_menu -> menu -> entryconfigure(1, -state=>'normal', -label=>"Restore the \"".$paths{$current}->get('lab')."\" fit model");
      ## disable save bkg menu entry if no bkg file exists
      $file_menu -> menu -> entryconfigure($save_index+2, -state=>'disabled')
	unless (-e File::Spec->catfile($project_folder, "fits", $paths{$current}->get('folder'), $1.".bkg"));
    };
    my $latest = $paths{$current}->parent;
    $latest = $paths{$latest}->get('thisfit');
##    $widgets{log_latest}  -> configure(-text=>($latest) ? $paths{$latest}->get('lab') : "");
    $widgets{log_current} -> configure(-text=>$paths{$latest}->get('lab'));
    $top -> Unbusy;
  } elsif ($anchor =~ /data\d+(\.\d+)?$/) { # matches data
    $top -> Busy;
  SWITCH: {
      $gsd ->packForget(), last SWITCH if ($current_canvas eq 'gsd');
      $feff->packForget(), last SWITCH if ($current_canvas eq 'feff');
      $path->packForget(), last SWITCH if ($current_canvas eq 'path');
      $logviewer ->packForget(), last SWITCH if ($current_canvas eq 'logview');
    };
    $opparams->pack(-expand=>1, -fill=>'both');
    $current_canvas = 'op';
    #my $this = ($current;
    #($anchor =~ /(data\d+)/) and ($this = $1);
    #$this and populate_op($this);
    populate_op($this_data);
    map { $file_menu -> menu -> entryconfigure($_, -state=>'normal') } ($save_index..$save_index+4, $save_index+6);
    #$file_menu -> menu -> entryconfigure($save_index+2, -state=>'disabled')
    #  unless (-e File::Spec->catfile($project_folder, "fits", $paths{$current}->get('folder'), $1.".bkg"));
    $top -> Unbusy;
  } elsif ($anchor eq 'gsd') {
  SWITCH: {
      $opparams->packForget(), last SWITCH if ($current_canvas eq 'op');
      $feff    ->packForget(), last SWITCH if ($current_canvas eq 'feff');
      $path    ->packForget(), last SWITCH if ($current_canvas eq 'path');
      $logviewer ->packForget(), last SWITCH if ($current_canvas eq 'logview');
    };
    $gsd->pack(-expand=>1, -fill=>'both');
    foreach ($feff_menu, $paths_menu, $fit_menu, $data_menu, $sum_menu) {
      $_ -> configure(-state=>'disabled');
    };
    map { $file_menu->menu->entryconfigure($_, -state=>'disabled') }
      ($save_index .. $save_index+3);

    $widgets{gds2_name} -> focus();
    $current_canvas = 'gsd';
  } elsif ($anchor =~ /feff\d+$/) {
  SWITCH: {
      $opparams->packForget(), last SWITCH if ($current_canvas eq 'op');
      $gsd     ->packForget(), last SWITCH if ($current_canvas eq 'gsd');
      $path    ->packForget(), last SWITCH if ($current_canvas eq 'path');
      $logviewer ->packForget(), last SWITCH if ($current_canvas eq 'logview');
    };
    $feff->pack(-expand=>1, -fill=>'both');
    $current_canvas = 'feff';
    populate_feff($current);
    map { $feff_menu  -> menu -> entryconfigure($_, -state=>'normal') } (5..8, 11, 12, 13, 11, 12, 13, 15, 17);
    map { $paths_menu -> menu -> entryconfigure($_, -state=>'normal') } (5..8, 13);
    ## disabled atoms options in theory menu if the atoms data is not present
    my $state = $fefftabs -> pagecget("Atoms", "-state");
    map { $feff_menu  -> menu -> entryconfigure($_, -state=>$state) } (10 .. 13);
  } elsif ($anchor =~ /feff\d+\.\d+$/) {
  SWITCH: {
      $opparams->packForget(), last SWITCH if ($current_canvas eq 'op');
      $gsd     ->packForget(), last SWITCH if ($current_canvas eq 'gsd');
      $feff    ->packForget(), last SWITCH if ($current_canvas eq 'feff');
      $logviewer ->packForget(), last SWITCH if ($current_canvas eq 'logview');
    };
    $path->pack(-expand=>1, -fill=>'both');
    $current_canvas = 'path';
    populate_path($current);
    map { $feff_menu  -> menu -> entryconfigure($_, -state=>'normal') } (5..8, 11, 12, 13, 15, 17);
    map { $paths_menu -> menu -> entryconfigure($_, -state=>'normal') } (1..3, 5..8, 10..13);
    $paths_menu -> menu -> entryconfigure(3, -state=>'normal') if $n_feff;
    #$show_menu  -> menu -> entryconfigure(3, -state=>'normal') if $n_feff;
  };

};



sub populate_op {
  my $this = $_[0];
  next unless (ref($paths{$this}) =~ /Ifeffit/);
  return unless ($paths{$this}->get('file'));

  ##--bkg-- $widgets{data_notebook} -> raise($paths{$this}->get('data_showing'));

  ## file
  $widgets{op_file} -> configure(-state=>'normal');
  $widgets{op_file} -> delete(qw(0 end));
  $widgets{op_file} -> insert(0, basename($paths{$this}->{file}));
  $widgets{op_file} -> xview('end');;
  $widgets{op_file} -> configure(-state=>'disabled');
  ## include
  my @every = &every_data;
  my @all   = &all_data;
  my $data  = $paths{$this}->data;;
  my $label = $paths{$this}->get('lab') || ucfirst($this);
  ($label = substr($label, 0, 11)."...") if (length($label) > 11);
  ##$widgets{controls_frame} -> configure(-label=>$label);
  $widgets{op_include}  -> configure(-state=>($#every) ? 'normal' : 'disabled' );
  $paths{$this}->make(plot=>1) unless $#all; # just one group
  $widgets{op_plot}     -> configure(-state=>($#all) ? 'normal' : 'disabled' );

  ## titles
  $widgets{op_titles} -> delete(qw(1.0 end));
  $widgets{op_titles} -> insert('end', $paths{$this}->get('titles'));

  ## entry widgets
  foreach (qw(kmin kmax dk rmin rmax dr cormin epsilon_k)) {
    my $key = 'op_'.$_;
    $widgets{$key} -> configure(-validate=>'none');
    $widgets{$key} -> delete(qw(0 end));
    $widgets{$key} -> insert(0, $paths{$this}->get($_));
    $widgets{$key} -> configure(-validate=>'key');
  };
  ## text
  ##if ($n_data) {
  ##  map {$_->configure(-foreground => $config{colors}{activehighlightcolor})} @op_text;
  ##};
  ## optionmenus and checkbuttons
  $temp{op_fitspace} = $paths{$this}->get('fit_space');
  $temp{op_kwindow}  = ucfirst $paths{$this}->get('kwindow');
  ($temp{op_kwindow} eq 'Kaiser-bessel') and ($temp{op_kwindow} = 'Kaiser-Bessel');
  $temp{op_rwindow}  = ucfirst $paths{$this}->get('rwindow');
  ($temp{op_rwindow} eq 'Kaiser-bessel') and ($temp{op_rwindow} = 'Kaiser-Bessel');
  $temp{op_do_bkg}   = $paths{$this}->get('do_bkg');
  $temp{op_include}  = $paths{$this}->get('include');
  $temp{op_plot}     = $paths{$this}->get('plot');
  $temp{op_k1}       = $paths{$this}->get('k1');
  $temp{op_k2}       = $paths{$this}->get('k2');
  $temp{op_k3}       = $paths{$this}->get('k3');
  $temp{op_karb_use} = $paths{$this}->get('karb_use');
  ## arbitrary k-weight box
  $widgets{op_karb} -> configure(-state=>($temp{op_karb}) ? 'normal' : 'disabled');
  $temp{op_pcplot}   = $paths{$this}->get('pcplot');
  $temp{op_pcpath}   = (exists $paths{$paths{$this}->get('pcpath')}) ?
    $paths{$this}->get('pcpath') : 'None';
  if ($temp{op_pcpath} eq 'None') {
    $temp{op_pcpath_label} = 'None';
  } elsif (exists $paths{$temp{op_pcpath}}) {
    $temp{op_pcpath_label} = $paths{$temp{op_pcpath}}->descriptor();
  } else {
    $temp{op_pcpath_label} = 'None';
  };

  ## restock the pcpath menu with the current path list
  $widgets{op_pcpath} -> configure(-options => []);
  $widgets{op_pcpath} -> command(-label => 'None',
				 -command=>sub{$temp{op_pcpath}='None';
					       $temp{op_pcpath_label}='None';
					       project_state(0);
					       $paths{$this}->make(pcpath=>'None', do_r=>1); });
  my @paths = grep {/feff\d+\.\d+/} (&pcpath_list);
  foreach my $p (@paths) {
    next unless ($paths{$p}->data eq $this);
    my $label = $paths{$p}->descriptor();
    $widgets{op_pcpath} -> command(-label => $label,
  				   -command=>sub{$temp{op_pcpath} = $p;
						 $temp{op_pcpath_label}=$label;
						 my $data = $paths{$current}->data;
						 $paths{$data}->make(pcpath=>$p, do_r=>1);
						 my $ii = $paths{$p}->index;
						 my $pathto = $paths{$p}->get('path');
						 my $command = $paths{$p}->write_path($ii, $pathto, $config{paths}{extpp}, $stash_dir);
						 $paths{$p} -> dispose($command, $dmode);
						 project_state(0);
					       })
  };

  &nidp;

  ##--bkg--
  ## enable the background tweaking panel
  if ($paths{$this}->get('is_xmu')) {
    map {$widgets{$_} -> configure(-state=>'normal')} (qw(show_chi show_mu));

  ## fill the mu(E) tab
    foreach my $k (qw(e0 eshift kw rbkg pre1 pre2 nor1 nor2 spl1 spl2 step)) {
      my $key = "bkg_".$k;
      $widgets{$key} -> configure(-validate=>'none');
      $widgets{$key} -> delete(qw(0 end));
      $widgets{$key} -> insert(0, $paths{$this}->get($key));
      $widgets{$key} -> configure(-validate=>'key');
    };
    $temp{bkg_fixstep} = $paths{$this}->get('bkg_fixstep');
    $temp{bkg_flatten} = $paths{$this}->get('bkg_flatten');
    $temp{bkg_clamp2}  = $paths{$this}->get('bkg_clamp2');
  } else {
    1;
  };
};




sub clear_op {
  my $this = $_[0];
  return unless defined $paths{$this};
  ###!!! do i really need to be sure there is always a data0 ??
  if ($this =~ /0$/) {
    delete $paths{$this};
    $paths{$this} = Ifeffit::Path -> new(id	 => 'data0',
					 group   => 'data0',
					 type    => 'data',
					 sameas  => 0,
					 kwindow => $config{data}{kwindow},
					 rwindow => $config{data}{rwindow},
					 family  => \%paths);
  } else {
    delete $paths{$this};
    $list->delete('entry',$this);
  };
  ## file
  $widgets{op_file} -> configure(-state=>'normal');
  $widgets{op_file} -> delete(qw(0 end));
  $widgets{op_file} -> configure(-state=>'disabled');
  $widgets{controls_frame} -> configure(-label=>'Data controls');
  ## titles
  $widgets{op_titles} -> delete(qw(1.0 end));
  foreach (qw(kmin kmax dk rmin rmax dr cormin)) {  #  epsilon_k
    my $key = 'op_'.$_;
    $widgets{$key} -> configure(-validate=>'none');
    $widgets{$key} -> delete(qw(0 end));
    $widgets{$key} -> configure(-validate=>'key');
  };
  ##map {$_->configure(-foreground=>$config{colors}{disabledforeground})} @op_text
  ##  if $n_data;
  $temp{op_kwindow}  = $config{data}{kwindow};
  $temp{op_rwindow}  = $config{data}{rwindow};
  $temp{op_fitspace} = 'R';
  $temp{op_do_bkg}   = 'no';
  $temp{op_include}  = 1;
  $temp{op_plot}     = 0;
  $temp{op_pcplot}   = 'No';
  $temp{op_k1}       = 0;
  $temp{op_k2}       = 0;
  $temp{op_k3}       = 0;
  $temp{op_karb_use} = 0;
  $temp{op_pcpath}   = 'None';
  $temp{op_pcpath_label}   = 'None';
};



sub set_opparam {
  my ($k, $entry, $prop) = (shift, shift, shift);
  ($entry =~ /^\s*$/) and ($entry = 0);	     # error checking ...
  ($entry =~ /^\s*\.\s*$/) and ($entry = 0); # a sole .
  ($entry =~ /^\s*\-\s*$/) and ($entry = 0); # a sole -
  ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
  return 1 if ($k =~ /extra/);
  return 0 if (($entry < 0) and ($k !~ /^bkg/));
  my $which;
  if ($k =~ /^bkg/)                          { $which = 'do_xmu' };
  if ($k =~ /(k(max|min|weight|window)|dk)/) { $which = 'do_r' };
  if ($k =~ /(r(max|min|window)|dr)/)        { $which = 'do_q' };
  my $this = $paths{$current}->data;
  $paths{$this} -> make($k=>$entry, $which=>1);
  my $i = get_index($this);
  unless ($k =~ /(cormin|epsilon_k)/) {
    foreach ("", ".0", ".2", ".1") { # flag data for updating
      next unless exists $paths{"data$i".$_};
      $paths{"data$i".$_} -> make($which=>1);
    };
    foreach (keys %paths) {	 # flag paths for updating
      next unless (ref($paths{$_}) =~ /Ifeffit/);
      next unless (/feff$i\.\d+/);
      $paths{$_} -> make($which=>1);
    };
  };
  if ($k =~ /cormin/) {
    foreach my $d (&all_data) {	# force cormin to be the same for all data sets
      $paths{$d} -> make(cormin=>$entry);
    };
  };
  &nidp if (($k !~ /cormin/) and ($k =~ /((km(in|ax))|(rm(in|ax)))/));
  project_state(0);
  return 1;
  ## need to flag that fit needs to be redone and that project needs
  ## to be saved
};

## change the anchor in the path list AND change the display in the
## main window, but do not change the path selection.  this is bound
## to mouse-2
sub anchor_display {
  ## this first bit swiped from HList.pm
  my $w = shift;
  my $Ev = $w->XEvent;
  delete $w->{'shiftanchor'};
  my $entry = $w->GetNearest($Ev->y, 1);
  return unless (defined($entry) and length($entry));

  $w->anchorSet($entry);
  &display_properties;
};



sub read_titles {
  my $this = $_[0] || $paths{$current}->data;
  return unless $this;
  return unless exists $paths{$this};
  return if ($current =~ /data\d+\.3$/);
  ## next line corrects a hierarchy problem on windows
  my $widg = (ref($widgets{op_titles}) =~ m{Frame}) ? $widgets{op_titles}->Subwidget('text') : $widgets{op_titles};
  $paths{$this} -> make(titles => $widg->get(qw(1.0 end)));
};



sub keyboard_up {
  if ($current_canvas eq 'gsd') {
    &gds2_update_mathexp($widgets{gds2list}, \%gds_selected);
    my $moveto = ($gds_selected{which}) ? # bottom if none selected
      $widgets{gds2list}->infoPrev($gds_selected{which}) : $#gds+1;
    $moveto ||= $#gds+1;	# wrap around to bottom
    gds2_display($moveto);
  } else {
    my $moveto = $list->infoPrev($current);
    return unless $moveto;
    $list->anchorSet($moveto);
    &display_properties;
    $list->see($moveto);
  };
};

sub keyboard_down {
  if ($current_canvas eq 'gsd') {
    &gds2_update_mathexp($widgets{gds2list}, \%gds_selected);
    my $moveto = ($gds_selected{which}) ? # top if none selected
      $widgets{gds2list}->infoNext($gds_selected{which}) : 1;
    $moveto ||= 1;		# wrap around to top
    gds2_display($moveto);
  } else {
    my $moveto = $list->infoNext($current);
    return unless $moveto;
    $list->anchorSet($moveto);
    &display_properties;
    $list->see($moveto);
  };
};

sub project_state {
  $project_saved = $_[0];
  $widgets{project_modified} -> configure(-text=>($_[0]) ?
					  "" : "modified");
  $top->update;
};



##  END OF THE MAIN WINDOW SUBSECTION

