

## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006, 2009 Bruce Ravel
##
##  This section of the code contains subroutines for drawing the
##  frame which contains all the parameters of the selected group


## This is just a lot of boring layout of widgets.  It's some really
## dense, repititious, and uninteresting code.

sub draw_properties {
  #my $c = $_[0];
  my $frame = $_[0];
  my ($f_label, $f_text, $f_bold, $f_tiny) = ($config{fonts}{bold},
					      $config{fonts}{small},
					      $config{fonts}{small},
					      $config{fonts}{tiny});
  my $bigtextcolor = $config{colors}{activehighlightcolor};
  my ($t, $y) = ("", '0.4c');
  my @rectangle = ("-fill",    $config{colors}{background},
		   "-outline", $config{colors}{background},
		   "-width", 3);

  my $gap = 10;
  my $jump = 0;
  $y = 7;


  ## ============================================================================
  ## ============================================================================
  ## projectbar
  my $c = $frame -> Frame(qw/-relief ridge -borderwidth 2 -width 12.5c/,
			  -highlightcolor=>$config{colors}{background})
    -> pack(qw/-expand 1 -fill both/);
#  disable_mouse_wheel($c);
  $widget{main_canvas} = $c;
  my @bbox_list = ();
  $props{project} = $c;
  my $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>3);
  $header{project} = $box -> Label(-text=>"  Project",
				   -foreground=>$bigtextcolor,
				   -font=>$f_label)
    -> pack(-side=>'left');
  &group_click($header{project}, 'project');
  my $project_label = $box -> Label(-textvariable => \$project_name,
				    -width	  => 1,
				    #-justify	  => 'right',
				    -anchor       => 'e')
    -> pack(-side=>'left', -padx=>12, -expand=>1, -fill=>'x');


  ## Current group section
  $c = $frame -> Frame(qw(-relief ridge -borderwidth 2 -width 12.5c),
		       -highlightcolor=>$config{colors}{background})
    -> pack(qw/-expand 1 -fill x/); #disable_mouse_wheel($c);
  $props{current} = $c;
  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>3);
  $header{current} = $box -> Label(-text       => "  Current group",
				   -foreground => $bigtextcolor,
				   -font       => $f_label)
    -> pack(-side=>'left');
  &group_click($header{current}, 'current');
  $widget{current} = $box -> Entry(-width=>30, -relief=>'flat', -font=>$f_bold,
				   -foreground=>$config{colors}{button},
				   (($Tk::VERSION >= 804) ? (-disabledforeground=>$config{colors}{button}) : ()),
				   -state=>'disabled')
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>12);
  ## not displaying the ifeffit data group
  $widget{group} = $box -> Entry(-width=>10, -relief=>'flat', -font=>$f_bold,
			       -foreground=>$config{colors}{button},
			       -state=>'disabled');
  ##  -> pack(-side=>'left', -expand=>1, -fill=>'x');



  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>3);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"File:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,0);
  $widget{file} = $box -> Entry(-width=>45, -state=>'disabled', -relief=>'groove',
				-foreground=>$config{colors}{foreground},
				(($Tk::VERSION >= 804) ? (-disabledforeground=>$config{colors}{foreground}) : ()),
			       )
    -> pack(-side=>'left', -expand=>1, -fill=>'x', -padx=>6);



  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>3);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"Z: ",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_z');
  $widget{z} = $box -> Optionmenu(-font=>$config{fonts}{small},
				  -textvariable => \$menus{bkg_z},
				  -borderwidth=>1, -state=>'disabled',
				 )
    -> pack(-side=>'left', -padx=>6);
  my $last = 90;
  while ($last < 104) {
    last unless (Xray::Absorption->in_resource($last));
    ++$last;
  };
  --$last;
  foreach my $l ([1..20], [21..40], [41..60], [61..80], [81..$last]) {
    my $cas = $widget{z} ->
      cascade(-label => get_symbol($$l[0]) . " (" . $$l[0] . ") to " . get_symbol($$l[-1]) . " (" .  $$l[-1] . ") ",
	      -tearoff=>0 );
    foreach my $i (@$l) {
      $cas -> command(-label => $i . ": " . get_symbol($i),
		      -command=>
		      sub{$menus{bkg_z}=get_symbol($i);
			  if ($groups{$current}->{frozen}) {
			    $menus{bkg_z}=$groups{$current}->{bkg_z};
			    return;
			  };
			  $groups{$current}->make(bkg_z=>$menus{bkg_z},
						  update_bkg=>1);
			  #
			  if ($groups{$current}->{reference} and $groups{$current}->{refsame}) {
			    $groups{$groups{$current}->{reference}}->make(bkg_z=>$menus{bkg_z},
			  						  update_bkg=>1);
			   };
			  #$groups{$current} ->
			  #  plotE('emzn',$dmode,\%plot_features, \@indicator);
			  project_state(0);
			});
    };
  };
  $t = $box -> Label(-text=>"Edge:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'fft_edge');
  $menus{fft_edge} = 'K';
  $widget{edge} = $box -> Optionmenu(-font=>$config{fonts}{small},
				   -borderwidth=>1, -state=>'disabled',
				   -textvariable => \$menus{fft_edge},)
    -> pack(-side=>'left', -padx=>6);
  foreach my $i (qw(K L1 L2 L3 M1 M2 M3 M4 M5)) {
    $widget{edge} -> command(-label => $i,
			     -command=>
			     sub{$menus{fft_edge}=$i;
				 if ($groups{$current}->{frozen}) {
				   $menus{fft_edge}=$groups{$current}->{fft_edge};
				   return;
				 };
				 $groups{$current}->make(fft_edge=>$menus{fft_edge},
							 update_fft=>1);
				 if ($groups{$current}->{reference} and $groups{$current}->{refsame}) {
				   $groups{$groups{$current}->{reference}}->make(fft_edge=>$menus{fft_edge},
										 update_bkg=>1);
				 };
				 project_state(0);
			       });
  };

  $t = $box -> Label(-text=>"E shift:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
 &click_help($t,'bkg_eshift');
  $widget{bkg_eshift} = $box -> Entry(-width=>5, -font=>$config{fonts}{entry},
				    -validate=>'key', -validatecommand=>[\&set_variable, 'bkg_eshift'])
    -> pack(-side=>'left', -padx=>6);


  $t = $box -> Label(-text=>"Importance:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
 &click_help($t,'importance');
  $widget{importance} = $box -> Entry(-width=>4,
				    -font=>$config{fonts}{entry},
				    #-disabledforeground=>$config{colors}{disabledforeground},
				    -validate=>'key',
				    -validatecommand=>[\&set_variable, 'importance'])
    -> pack(-side=>'left', -padx=>6);

  #$box = $c -> Frame() -> pack(-side=>'top', -fill=>'y', -expand=>1);


  ## Background Removal section
  $c = $frame -> Frame(qw/-relief ridge -borderwidth 2 -width 12.5c/, # -height 7.0c/,
		       -highlightcolor=>$config{colors}{background})
    -> pack(qw/-expand 1 -fill both/);
#  disable_mouse_wheel($c);
  $props{bkg} = $c;

  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>3);
  $header{bkg} = $box -> Label(-text=>"  Background removal",
			       -foreground=>$bigtextcolor,
			       -font=>$f_label)
    -> pack(-side=>'left');

  &group_click($header{bkg}, 'bkg');
  $widget{bkg_switch} = $box -> Button(-text=>"Show additional parameters",
				     -font=>$config{fonts}{small},
				     -borderwidth=>1,
				     -command => sub {
				       $props{bkg}->packForget;
				       $props{bkg_secondary} -> pack(qw/-expand 1 -fill both -after/, $props{current});
				     })
    -> pack(-side=>'right', -padx=>12);

  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"E0:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_e0');
  $widget{bkg_e0} = $box -> Entry(-width=>8, -validate=>'all', -font=>$config{fonts}{entry},
				  -validatecommand=>[\&set_variable, 'bkg_e0'])
    -> pack(-side=>'left', -padx=>6);
  $grab{bkg_e0} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_e0'])
    -> pack(-side=>'left');

  $t = $box -> Label(-text=>"",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left', -padx=>10);
  $t = $box -> Label(-text=>"Rbkg:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_rbkg');
  $widget{bkg_rbkg} = $box -> RetEntry(-width=>4,
				       -font=>$config{fonts}{entry},
				       -command=>\&autoreplot,
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_rbkg'])
    -> pack(-side=>'left', -padx=>6);
  $grab{bkg_rbkg} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_rbkg'])
    -> pack(-side=>'left');

  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"k-weight:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_kw');
  $widget{bkg_kw} = $box -> RetEntry(-width=>3,
				     -font=>$config{fonts}{entry},
				     #-disabledforeground=>$config{colors}{disabledforeground},
				     -command=>\&autoreplot,
				     -validate=>'key',
				     -validatecommand=>[\&set_variable, 'bkg_kw'])
    -> pack(-side=>'left', -padx=>6);

  $t = $box -> Label(-text=>"Edge step:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,0);
  $widget{bkg_step} = $box -> NumEntry(-width      => 7,
				       -font       => $config{fonts}{entry},
				       -orient     => 'horizontal',
				       -foreground => $config{colors}{foreground},
				       -increment  => $config{bkg}{step_increment},
				       -browsecmd  => sub{$menus{bkg_fixstep}=1;
							  $groups{$current}->make(bkg_step=>$widget{bkg_step}->cget('-value'),
										  bkg_fixstep=>$menus{bkg_fixstep},
										  update_bkg=>1);
							  project_state(0);
							},
				       -command    => sub{$menus{bkg_fixstep}=1;
							  $groups{$current}->make(bkg_step=>$widget{bkg_step}->cget('-value'),
										  bkg_fixstep=>$menus{bkg_fixstep},
										  update_bkg=>1);
							  project_state(0);
							  autoreplot();
							},
				       #-textvariable=>\$$rhash{$s}{$v}{new},
				       #-validate=>'key',
				       #-validatecommand=>[\&set_variable, 'bkg_step']
				      )
    -> pack(-side=>'left', -padx=>6);
  $widget{bkg_fixstep} = $box -> Checkbutton(-text	  => 'fix step',
					     -onvalue	  => 1,
					     -offvalue	  => 0,
					     -font	  => $f_text,
					     -selectcolor => $config{colors}{single},
					     -variable	  => \$menus{bkg_fixstep},
					     -command	  =>
					     sub{$groups{$current}->
						   make(bkg_step	  => $widget{bkg_step}->cget('-value'),
							bkg_fixstep => $menus{bkg_fixstep},
							update_bkg  => 1);
						 project_state(0);
						 ##$widget{bkg_step} -> configure(-state=>($menus{bkg_fixstep}) ? 'disabled' : 'normal');
					       })
    -> pack(-side=>'left', -padx=>6);



  ##   $t = $c -> createText('5.0c', $y, -anchor=>'w', -text=>"dk: ",
  ## 			-fill=>'black', -font=>$f_text);
  ##   &click_help($t,'bkg_dk');
  ##   $widget{bkg_dk} = $c -> RetEntry(-width=>5, -validate=>'key',
  ##                            -font=>$config{fonts}{entry},
  ## 				-validatecommand=>[\&set_variable, 'bkg_dk']);
  ##   $c -> createWindow('6.0c', $y, -anchor=>'w', -window => $widget{bkg_dk});
  ##   $t = $c -> createText('8.0c', $y, -anchor=>'w', -text=>"window type:",
  ## 			-fill=>'black', -font=>$f_text);
  ##   &click_help($t,'bkg_win');
  ##   $widget{bkg_win} = $c -> Optionmenu(-font=>$config{fonts}{small},
  ##                                         -textvariable => \$menus{bkg_win},);
  ##   foreach my $i ($setup->Windows) {
  ##     $widget{bkg_win} -> command(-label => $i,
  ## 				-command=>sub{$menus{bkg_win}=$i;
  ## 					      project_state(0);
  ## 					      $groups{$current}->make(bkg_win=>$i,
  ## 								      update_bkg=>1)});
  ##   };
  ##   $c -> createWindow('10.9c', $y, -anchor=>'w', -window => $widget{bkg_win});

  # pre edge
  $box = $c -> Frame() -> pack(-side=>'top', -pady=>2, -anchor=>'w');
  $box -> Label(-text=>"     ")
    -> grid(-row=>0, -column=>0, -sticky=>'w', -ipady=>1);
  $t = $box -> Label(-text=>"Pre-edge range:", -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'w');
  &click_help($t,'bkg_pre1','bkg_pre2');
  $widget{bkg_pre1} = $box -> RetEntry(-width=>8,
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -font=>$config{fonts}{entry},
				       -command=>\&autoreplot,
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_pre1'])
    -> grid(-row=>0, -column=>3, -sticky=>'w');
  $grab{bkg_pre1} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_pre1'])
    -> grid(-row=>0, -column=>4, -sticky=>'w', -padx=>2);
  $box -> Label(-text=>"to",
	      -foreground=>'black', -font=>$f_text)
    -> grid(-row=>0, -column=>5, -sticky=>'ew', -ipadx=>5);
  $widget{bkg_pre2} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>\&autoreplot,
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_pre2'])
    -> grid(-row=>0, -column=>6, -sticky=>'ew');
  $grab{bkg_pre2} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_pre2'])
    -> grid(-row=>0, -column=>7, -sticky=>'w', -padx=>2);

				# normalization
  $box -> Label(-text=>"     ")
    -> grid(-row=>1, -column=>0, -sticky=>'ew', -ipady=>1);
  $t = $box -> Label(-text=>"Normalization range:", -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'w');
  &click_help($t,'bkg_nor1','bkg_nor2');
  $widget{bkg_nor1} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>\&autoreplot,
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_nor1'])
    -> grid(-row=>1, -column=>3, -sticky=>'ew');
  $grab{bkg_nor1} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_nor1'])
    -> grid(-row=>1, -column=>4, -sticky=>'w', -padx=>2);
  $box -> Label(-text=>"to",
		-foreground=>'black', -font=>$f_text)
    -> grid(-row=>1, -column=>5, -sticky=>'ew', -ipadx=>5);
  $widget{bkg_nor2} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>\&autoreplot,
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_nor2'])
    -> grid(-row=>1, -column=>6, -sticky=>'ew');
  $grab{bkg_nor2} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_nor2'])
    -> grid(-row=>1, -column=>7, -sticky=>'w', -padx=>2);

				# spline k
  $box -> Label(-text=>"     ")
    -> grid(-row=>2, -column=>0, -sticky=>'ew', -ipady=>1);
  $t = $box -> Label(-text=>"Spline range:", -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> grid(-row=>2, -column=>1, -sticky=>'w');
  &click_help($t,'bkg_spl1','bkg_spl2');
  $t = $box -> Label(-text=>"k: ", -anchor=>'e',
		     -foreground=>'black', -font=>$f_text)
    -> grid(-row=>2, -column=>2, -sticky=>'e');
  &click_help($t,'bkg_spl1','bkg_spl2');
  $widget{bkg_spl1} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>\&autoreplot,
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_spl1'])
    -> grid(-row=>2, -column=>3, -sticky=>'ew');
  $grab{bkg_spl1} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_spl1'])
    -> grid(-row=>2, -column=>4, -sticky=>'w', -padx=>2);
  $box -> Label(-text=>"to",
		-foreground=>'black', -font=>$f_text)
    -> grid(-row=>2, -column=>5, -sticky=>'ew', -ipadx=>5);
  $widget{bkg_spl2} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>\&autoreplot,
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bkg_spl2'])
    -> grid(-row=>2, -column=>6, -sticky=>'ew');
  $grab{bkg_spl2} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_spl2'])
    -> grid(-row=>2, -column=>7, -sticky=>'w', -padx=>2);

				# spline E
  $box -> Label(-text=>"     ")
    -> grid(-row=>3, -column=>0, -sticky=>'ew', -ipady=>1);
  $t = $box -> Label(-text=>"E: ", -anchor=>'e',
		     -foreground=>'black', -font=>$f_text)
    -> grid(-row=>3, -column=>2, -sticky=>'e');
  &click_help($t,'bkg_spl1e','bkg_spl2e');
  $widget{bkg_spl1e} = $box -> RetEntry(-width=>8,
					-font=>$config{fonts}{entry},
					#-disabledforeground=>$config{colors}{disabledforeground},
					-command=>\&autoreplot,
					-validate=>'key',
					-validatecommand=>[\&set_variable, 'bkg_spl1e'])
    -> grid(-row=>3, -column=>3, -sticky=>'w');
  $grab{bkg_spl1e} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_spl1e'])
    -> grid(-row=>3, -column=>4, -sticky=>'w', -padx=>2);
  $box -> Label(-text=>"to",
		-foreground=>'black', -font=>$f_text)
    -> grid(-row=>3, -column=>5, -sticky=>'ew');
  $widget{bkg_spl2e} = $box -> RetEntry(-width=>8,
					#-disabledforeground=>$config{colors}{disabledforeground},
					-validate=>'key',
					-command=>\&autoreplot,
					-font=>$config{fonts}{entry},
					-validatecommand=>[\&set_variable, 'bkg_spl2e'])
    -> grid(-row=>3, -column=>6, -sticky=>'w');
  $grab{bkg_spl2e} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bkg_spl2e'])
    -> grid(-row=>3, -column=>7, -sticky=>'w', -padx=>2);


  ## secondary background parameters
  $c = $frame -> Frame(qw/-relief ridge -borderwidth 2 -width 12.5c/, # -height 7.0c/,
			   -highlightcolor=>$config{colors}{background});
#    -> pack(qw/-expand 1 -fill both/);
#  disable_mouse_wheel($c);
  $props{bkg_secondary} = $c;


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $header{bkg_secondary} = $box -> Label(-text=>"  Background removal",
					 -foreground=>$bigtextcolor,
					 -font=>$f_label)
    -> pack(-side=>'left');
  &group_click($header{bkg_secondary}, 'bkg');
  $widget{bkg_switch2} = $box -> Button(-text=>"Show main parameters",
					-font=>$config{fonts}{small},
					-borderwidth=>1,
					-command => sub{
					  $props{bkg_secondary}->packForget;
					  $props{bkg} -> pack(qw/-expand 1 -fill both -after/, $props{current});
					})
    -> pack(-side=>'right', -padx=>12);



  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $widget{bkg_flatten} = $box -> Checkbutton(-text	  => 'Flatten normalized data',
					     -onvalue	  => 1,
					     -offvalue	  => 0,
					     -font	  => $f_text,
					     -selectcolor => $config{colors}{single},
					     -variable	  => \$menus{bkg_flatten},
					     -command	  =>
					     sub{$groups{$current}->
						   make(bkg_flatten=>$menus{bkg_flatten});
						 autoreplot('e');
						 project_state(0)})

    -> pack(-side=>'left');
  $widget{bkg_flatten} -> bind('<ButtonPress-3>' =>
			       sub{return 0 unless ($current);
				   return 0 unless (scalar keys %groups > 1);
				   my $is_active = ($widget{bkg_flatten}->cget('-state') ne 'disabled');
				   return 0 unless $is_active;
				   my $menu=$top->Menu(-tearoff=>0,
						       -menuitems=>[["command"=>"Set all groups to this value of flatten",
								     -command => sub{&set_params('all', 'bkg_flatten')},
								     -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
								    ],
								    ["command"=>"Set marked groups to this value of flatten",
								     -command => sub{&set_params('marked', 'bkg_flatten')},
								     -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
								    ],
								    "-",
								    ["command"=>"Set this value of flatten to the standard",
								     -command => sub{&set_params('this', 'bkg_flatten')},
								     -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
								    ],
								   ]);
				   $menu -> Popup(-popover=>'cursor', -popanchor=>'w');
				 });
 ##&click_help($t,'bkg_flatten');
  $t = $box -> Label(-text=>"   ",
		     -foreground=>'black',
		     -font=>$f_text)
    -> pack(-side=>'left');

  $menus{bkg_alg} = 'Autobk'; ####!!!!!
  $t = $box -> Label(-text=>"Background:",
		   -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_alg');
  $widget{bkg_alg} = $box -> Optionmenu(-font=>$config{fonts}{small},
					-borderwidth=>1,
					-textvariable => \$menus{bkg_alg},)
    -> pack(-side=>'left', -padx=>6);
  foreach my $i ('Autobk', 'CLnorm') {
    $widget{bkg_alg} -> command(-label => $i,
				-command=>
				sub{$menus{bkg_alg}=$i;
				    if ($groups{$current}->{frozen}) {
				      $menus{bkg_alg}='Autobk';
				      $menus{bkg_alg}='CLnorm' if $groups{$current}->{bkg_cl};
				      return;
				    };
				    ## flatten should be off when CL
				    ## is on
				    if ($menus{bkg_alg} ne 'Autobk') {
				      $groups{$current}->{bkg_flatten_was} = $groups{$current}->{bkg_flatten};
				    };
				    $menus{bkg_flatten} = ($menus{bkg_alg} eq 'Autobk') ? $groups{$current}->{bkg_flatten_was} : 0;
				    $groups{$current} ->
				      make(bkg_cl      => ($menus{bkg_alg} eq 'Autobk') ? 0 : 1,
					   bkg_flatten => ($menus{bkg_alg} eq 'Autobk') ? $groups{$current}->{bkg_flatten_was}  : 0,
					   bkg_z       => $menus{bkg_z},
					   update_bkg  => 1);
		 		    ## disable widgets not needed by
		 		    ## the selected background algorithm
				    #$widget{bkg_z} ->
				    #  configure(-state=>($menus{bkg_alg} eq 'Autobk')
				    #	? 'disabled' : 'normal');
				    ##  dk win
				    foreach (qw(stan rbkg kw spl1 spl2 spl1e spl2e flatten)) {
				      $widget{'bkg_'.$_} ->
					configure(-state=>($menus{bkg_alg} eq 'CLnorm')
						  ? 'disabled' : 'normal');
				    };
				    foreach (qw(rbkg spl1 spl2 spl1e spl2e)) {
				      $grab{'bkg_'.$_} ->
					configure(-state=>($menus{bkg_alg} eq 'CLnorm')
						  ? 'disabled' : 'normal');
				    };
				    ## make a plot
				    project_state(0);
				    #if ($menus{bkg_alg} eq 'CLnorm') {
				    #  if (lc($menus{bkg_z}) eq 'h') {
				    #	&z_popup($current, 'cl');
				    #      } else {
				    #	&z_popup($current, 'cl,update');
				    #  };
				    #};
				    #($menus{bkg_alg} eq 'Autobk') and
				    $groups{$current}->plotE('emz',$dmode,\%plot_features, \@indicator);;
				  }
			       );
  };



  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"Normalization order:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_nnorm1');
  foreach my $i (1,2,3) {
    my $this = "bkg_nnorm".$i;
    $widget{$this} = $box -> Radiobutton(-text        => "$i",
					 -value       => $i,
					 -selectcolor => $config{colors}{single},
					 -font	      => $f_text,
					 -variable    => \$menus{bkg_nnorm},
					 -command     => sub{$groups{$current}->
							       make(bkg_nnorm=>$menus{bkg_nnorm},
								    update_bkg=>1);
							     autoreplot('e');
							     project_state(0)})
      -> pack(-side=>'left', -padx=>3);
  };


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $widget{bkg_fnorm} = $box -> Checkbutton(-text	      => 'Use functional normalization',
					   -onvalue     => 1,
					   -offvalue    => 0,
					   -selectcolor => $config{colors}{single},
					   -font	=> $f_text,
					   -variable    => \$menus{bkg_fnorm},
					   -command     =>
					   sub{$groups{$current}->
						 make(bkg_fnorm=>$menus{bkg_fnorm});
					       autoreplot('e');
					       project_state(0)})
    -> pack(-side=>'left');
  $widget{bkg_fnorm} -> bind('<ButtonPress-3>' =>
			     sub{return 0 unless ($current);
				 return 0 unless (scalar keys %groups > 1);
				 my $is_active = ($widget{bkg_fnorm}->cget('-state') ne 'disabled');
				 return 0 unless $is_active;
				 my $menu=$top->Menu(-tearoff=>0,
						     -menuitems=>[["command"=>"Set all groups to use functional normalization",
								   -command => sub{&set_params('all', 'bkg_fnorm')},
								   -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
								  ],
								  ["command"=>"Set marked groups to use functional normalization",
								   -command => sub{&set_params('marked', 'bkg_fnorm')},
								   -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
								  ],
								  "-",
								  ["command"=>"Set use of functional normalization to the standard",
								   -command => sub{&set_params('this', 'bkg_fnorm')},
								   -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
								  ],
								 ]);
				 $menu -> Popup(-popover=>'cursor', -popanchor=>'w');
			       });


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"Standard:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_stan');
  $widget{bkg_stan} = $box -> BrowseEntry(-variable=>\$menus{bkg_stan_lab},
					  -width=>30,
					  @browseentry_list,
					  -browsecmd => sub {
					    my $text = $_[1];
					    my $this = $1 if ($text =~ /^(\d+):/);
					    Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless defined($this);
					    #$this -= 1;
					    project_state(0);
					    my $x = $menus{keys}->[$this];
					    $groups{$x}->dispatch_bkg($dmode) if
					      $groups{$x}->{update_bkg};
					    $groups{$current}->make(bkg_stan=>$menus{keys}->[$this],
								    bkg_stan_lab=>$groups{$x}->{label},
								    update_bkg=>1);
					    autoreplot('e')
					  })
    -> pack(-side=>'left', -padx=>6);




				# clamps
  $menus{bkg_clamp1} = 'None';
  $menus{bkg_clamp2} = 'Strong';
  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"Spline clamps:  ",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t);
  $t = $box -> Label(-text=>"low:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_clamp1');
  $widget{bkg_clamp1} = $box -> Optionmenu(-font=>$config{fonts}{small},
					   -borderwidth=>1,
					   -textvariable => \$menus{bkg_clamp1},)
    -> pack(-side=>'left', -padx=>6);
  foreach my $i (qw(None Slight Weak Medium Strong Rigid)) {
    $widget{bkg_clamp1} -> command(-label => $i,
				  -command=>sub{$menus{bkg_clamp1}=$i;
						if ($groups{$current}->{frozen}) {
						  $menus{bkg_clamp1}=$groups{$current}->{bkg_clamp1};
						  return;
						};
						project_state(0);
						$groups{$current}->make(bkg_clamp1=>$i,
									update_bkg=>1);
						autoreplot('e') });
  };

  $t = $box -> Label(-text=>"high:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bkg_clamp2');
  $widget{bkg_clamp2} = $box -> Optionmenu(-font=>$config{fonts}{small},
					   -borderwidth=>1,
					   -textvariable => \$menus{bkg_clamp2},)
    -> pack(-side=>'left', -padx=>6);
  foreach my $i (qw(None Slight Weak Medium Strong Rigid)) {
    $widget{bkg_clamp2} -> command(-label => $i,
				  -command=>sub{$menus{bkg_clamp2}=$i;
						if ($groups{$current}->{frozen}) {
						  $menus{bkg_clamp2}=$groups{$current}->{bkg_clamp2};
						  return;
						};
						project_state(0);
						$groups{$current}->make(bkg_clamp2=>$i,
									update_bkg=>1);
						autoreplot('e')});
  };




  ## Forward transform section
  $c = $frame -> Frame(qw/-relief ridge -borderwidth 2 -width 12.5c/, # -height 3.3c/,
			   -highlightcolor=>$config{colors}{background})
    -> pack(qw/-expand 1 -fill both/);
#  disable_mouse_wheel($c);
  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $header{fft} = $box -> Label(-text=>"  Forward Fourier transform",
			       -foreground=>$bigtextcolor,
			       -font=>$f_label)
    -> pack(-side=>'left');
  $props{fft} = $c;
  &group_click($header{fft}, 'fft');

  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"k-range:", -width=>9, -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'fft_kmin','fft_kmax');
  $widget{fft_kmin} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>[\&autoreplot,'r'],
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'fft_kmin'])
    -> pack(-side=>'left', -padx=>6);
  $grab{fft_kmin} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'fft_kmin'])
    -> pack(-side=>'left');
  $box -> Label(-text=>"  to ",
		-foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  $widget{fft_kmax} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>[\&autoreplot,'r'],
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'fft_kmax'])
    -> pack(-side=>'left', -padx=>6);
  $grab{fft_kmax} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'fft_kmax'])
    -> pack(-side=>'left');


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"dk: ", -width=>4, -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'fft_dk');
  $widget{fft_dk} = $box -> RetEntry(-width=>5,
				     -font=>$config{fonts}{entry},
				     #-disabledforeground=>$config{colors}{disabledforeground},
				     -command=>[\&autoreplot,'r'],
				     -validate=>'key',
				     -validatecommand=>[\&set_variable, 'fft_dk'])
    -> pack(-side=>'left', -padx=>6);
  $t = $box -> Label(-text=>"window type:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'fft_win');
  $widget{fft_win} = $box -> Optionmenu(-font=>$config{fonts}{small},
					-borderwidth=>1,
					-textvariable => \$menus{fft_win},)
    -> pack(-side=>'left', -padx=>6);
  foreach my $i ($setup->Windows) {
    $widget{fft_win} -> command(-label => $i,
				-command=>sub{$menus{fft_win}=$i;
					      if ($groups{$current}->{frozen}) {
						$menus{fft_win}=$groups{$current}->{fft_win};
						return;
					      };
					      project_state(0);
					      $groups{$current}->make(fft_win=>$i,
								      update_fft=>1);
					      autoreplot('r')});
  };


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"Phase correction:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'fft_pc');
  $menus{fft_pc} = 'off';
  $widget{fft_pc} =
    $box -> Checkbutton(-selectcolor	  => $config{colors}{single},
			-activebackground => $config{colors}{background},
			-font		  => $f_text,
			-variable	  => \$menus{fft_pc},
			-textvariable	  => \$menus{fft_pc},
			-onvalue	  => 'on',
			-offvalue         => 'off',
			-command	  =>
			sub{$groups{$current}->make(fft_pc=>$menus{fft_pc}, update_fft=>1);
			    if ($menus{fft_pc} eq 'on') {
			      &z_popup($current, 'pc') if (lc($menus{bkg_z}) eq 'h');
			      Echo("Doing central-atom phase-corrected Fourier transforms.");
			    } else {
			      Echo("Doing uncorrected Fourier transforms.");
			    };
			    project_state(0);
			  }
		       )
      -> pack(-side=>'left', -padx=>6);
  $t = $box -> Label(-text=>"arbitrary k-weight:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'fft_arbkw');
  $widget{fft_arbkw} = $box -> RetEntry(-width=>6,
					-font=>$config{fonts}{entry},
					#-disabledforeground=>$config{colors}{disabledforeground},
					-command=>[\&autoreplot, 'r'],
					-validate=>'key',
					-validatecommand=>[\&set_variable, 'fft_arbkw'])
    -> pack(-side=>'left', -padx=>6);


  ## Backward transform section
  $c = $frame -> Frame(qw/-relief ridge -borderwidth 2 -width 12.5c/, # -height 2.4c/,
		       -highlightcolor=>$config{colors}{background})
    -> pack(qw/-expand 1 -fill both/);
#  disable_mouse_wheel($c);
  $props{bft} = $c;
  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $header{bft} = $box -> Label(-text=>"  Backward Fourier transform",
			       -foreground=>$bigtextcolor,
			       -font=>$f_label)
    -> pack(-side=>'left');
  &group_click($header{bft}, 'bft');


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"R-range:", -width=>9, -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bft_rmin','bft_rmax');
  $widget{bft_rmin} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>[\&autoreplot, 'q'],
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bft_rmin'])
    -> pack(-side=>'left', -padx=>6);
  $grab{bft_rmin} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bft_rmin'])
    -> pack(-side=>'left');
  $box -> Label(-text=>"  to ",
		-foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  $widget{bft_rmax} = $box -> RetEntry(-width=>8,
				       -font=>$config{fonts}{entry},
				       #-disabledforeground=>$config{colors}{disabledforeground},
				       -command=>[\&autoreplot, 'q'],
				       -validate=>'key',
				       -validatecommand=>[\&set_variable, 'bft_rmax'])
    -> pack(-side=>'left', -padx=>6);
  $grab{bft_rmax} = $box -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'bft_rmax'])
    -> pack(-side=>'left');


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"dr: ", -width=>4, -anchor=>'w',
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bft_dr');
  $widget{bft_dr} = $box -> RetEntry(-width=>5,
				     -font=>$config{fonts}{entry},
				     #-disabledforeground=>$config{colors}{disabledforeground},
				     -command=>[\&autoreplot, 'q'],
				     -validate=>'key',
				     -validatecommand=>[\&set_variable, 'bft_dr'])
    -> pack(-side=>'left', -padx=>6);
  $t = $box -> Label(-text=>"window type:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'bft_win');
  $widget{bft_win} = $box -> Optionmenu(-font=>$config{fonts}{small},
					-borderwidth=>1,
					-textvariable => \$menus{bft_win},)
    -> pack(-side=>'left', -padx=>6);
  foreach my $i ($setup->Windows) {
    $widget{bft_win} -> command(-label => $i,
				-command=>sub{$menus{bft_win}=$i;
					      if ($groups{$current}->{frozen}) {
						$menus{bft_win}=$groups{$current}->{bft_win};
						return;
					      };
					      project_state(0);
					      $groups{$current}->make(bft_win=>$i,
								      update_bft=>1);
					      autoreplot('q')});
  };


  ## Plot parameters
  $c = $frame -> Frame(qw/-relief ridge -borderwidth 2 -width 12.5c -height 1.4c/,
		       -highlightcolor=>$config{colors}{background})
    -> pack(qw/-expand 1 -fill both/);
#  disable_mouse_wheel($c);
  $props{plot} = $c;


  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $header{plot} = $box -> Label(-text=>"  Plotting parameters",
				-foreground=>$bigtextcolor,
				-font=>$f_label)
    -> pack(-side=>'left');
  &group_click($header{plot}, 'plot');

  $box = $c -> Frame() -> pack(-side=>'top', -fill=>'x', -expand=>1, -pady=>2);
  $box -> Label(-text=>"     ") -> pack(-side=>'left');
  $t = $box -> Label(-text=>"plot multiplier:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'plot_scale');
  $widget{plot_scale} = $box -> RetEntry(-width=>8,
					 -font=>$config{fonts}{entry},
					 #-disabledforeground=>$config{colors}{disabledforeground},
					 -command=>\&autoreplot,
					 -validate=>'key',
					 -validatecommand=>[\&set_variable, 'plot_scale'])
    -> pack(-side=>'left', -padx=>6);

  $t = $box -> Label(-text=>"y-axis offset:",
		     -foreground=>'black', -font=>$f_text)
    -> pack(-side=>'left');
  &click_help($t,'plot_yoffset');
  $widget{plot_yoffset} = $box -> RetEntry(-width=>8,
					   -font=>$config{fonts}{entry},
					   #-disabledforeground=>$config{colors}{disabledforeground},
					   -command=>\&autoreplot,
					   -validate=>'key',
					   -validatecommand=>[\&set_variable, 'plot_yoffset'])
    -> pack(-side=>'left', -padx=>6);

};


## Handle mouse-over functionality for labels in the main window
sub click_help {
  my $t = shift;
  my @keys = @_;


  ## ------ MOUSE OVER
  my @bold   = (-foreground => $config{colors}{foreground},
		-background => $config{colors}{activebackground},
		-font       => $config{fonts}{small},
	        -cursor     => $mouse_over_cursor);
  my @normal = (-foreground => $config{colors}{foreground},
		-background => $config{colors}{background},
		-font       => $config{fonts}{small});

  my @in     = (-fill    => $config{colors}{activebackground},
		-outline => $config{colors}{activebackground},);
  my @out    = (-fill    => $config{colors}{background},
		-outline => $config{colors}{background});
  $t -> bind('<Any-Enter>'=>sub{$t -> configure(@bold  ) });
  $t -> bind('<Any-Leave>'=>sub{$t -> configure(@normal) });


  ## ------ LEFT CLICK
  my $text = $t -> cget('-text');
  $text =~ s/\s+$//;
  my $str = $click_help{$text} || "$text ???";
  $t -> bind('<1>' => sub{Echo("$str")});



  ## a few parameters need additional items in their context menus
  my %extra = (
	       E0 => [[ command => "Set E0 to Ifeffit's default",
		       #-state   => $groups{$current}->{frozen} ? 'disabled' : 'normal',
		       -command => sub{set_edge($current, 'edge');     autoreplot('e');}],
		      [ command => "Set E0 to zero-crossing of 2nd derivative",
		       #-state   => $groups{$current}->{frozen} ? 'disabled' : 'normal',
		       -command => sub{set_edge($current, 'zero');     autoreplot('e');}],
		      [ command => "Set E0 to a set fraction of the edge step",
		       #-state   => $groups{$current}->{frozen} ? 'disabled' : 'normal',
		       -command => sub{set_edge($current, 'fraction'); autoreplot('e');}],
		      [ command => "Set E0 to atomic value",
		       #-state   => $groups{$current}->{frozen} ? 'disabled' : 'normal',
		       -command => sub{set_edge($current, 'atomic');   autoreplot('e');}],
		      [ command => "Set E0 to the peak of the white line",
		       #-state   => &wlbool($current),
		       -command => sub{autoreplot('e') if set_edge_peak($current);}],
		      "-",
		      [checkbutton  =>  'Tie energy and k values to E0   (Ctrl-T)',
		       -onvalue	    => 1,
		       -offvalue    => 0,
		       -selectcolor => $config{colors}{single},
		       -variable    => \$menus{bkg_tie_e0},
		       -command	    => \&tie_untie_e0,
		      ],
		     ],

	       'k-range' =>[[ command => "Set kmax to Ifeffit's suggestion",
			     #-state   => $groups{$current}->{frozen} ? 'disabled' : 'normal',
			     -command => sub{Echonow("Not changing kmax.  This group is frozen."), return if ($groups{$current}->{frozen});
					     $groups{$current}->dispatch_bkg if $groups{$current}->{update_bkg};
					     my @array = Ifeffit::get_array("$current.k");
					     $groups{$current}->MAKE(fft_kmax=>$array[-1]);
					     my $kx = sprintf("%.3f", $groups{$current}->kmax_suggest(\%plot_features));
					     project_state(0);
					     set_properties(1, $current, 0);
					     Echo("Set kmax to Ifeffit's suggested value of $kx");
					   },
			    ],
			   ],


	       Importance => [['command'=>"Set importance of all groups to 1",
			       -command=>sub{
				 foreach my $g (keys %marked) {
				   $groups{$g}->make(importance=>1);
				 }
				 set_properties(0,$current,0);
				 project_state(0);
			       }],
			      ['command'=>"Set importance of marked groups to 1",
			       -command=>sub{
				 foreach my $g (keys %marked) {
				   next unless $marked{$g};
				   $groups{$g}->make(importance=>1);
				 }
				 set_properties(0,$current,0);
				 project_state(0);
			       }]
			     ],

	       'E shift' => [[ command => "Identify reference channel",
			      -command => \&identify_reference,],
			     [ command => "Understanding the E shift",
			      -command => \&explain_eshift,],
			    ],
	      );


  ## ------ RIGHT CLICK
  if ($keys[0]) {
    ## need to treat z and edge specially
    ($keys[0] = 'z')    if ($keys[0] eq 'bkg_z');
    ($keys[0] = 'edge') if ($keys[0] eq 'fft_edge');
    $text =~ s/:$//;		# same text as left click
    ($text eq 'k')    and ($text = 'spline k-range');
    ($text eq 'E')    and ($text = 'spline E-range');
    ($text eq 'low')  and ($text = 'low-end spline clamp');
    ($text eq 'high') and ($text = 'high-end spline clamp');
    my $def_ok = not (($keys[0] =~ /^plot/) or
		      ($keys[0] =~ /^(edge|z)$/) or
		      ($keys[0] =~ /^bkg_(alg|eshift|e0|stan|step)/) or
		      ($text    eq 'E-range'));
    my $is_mee = ($keys[0] =~ m{^mee});
    $t -> bind('<3>' =>
	       sub{return 0 unless ($current);
		   return 0 unless (scalar keys %groups > 1);
		   my $is_active = ($widget{$keys[0]}->cget('-state') eq 'normal');
		   return 0 unless $is_active;
		   my $menu=$t->Menu(-tearoff=>0,
				     -menuitems=>[["command"=>"Set all groups to this value of $text",
						   -command => sub{&set_params('all', @keys)},
						   -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
						  ],
						  ["command"=>"Set marked groups to this value of $text",
						   -command => sub{&set_params('marked', @keys)},
						   -state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
						  ],
						  (($is_mee) ?
						   () :
						   (
						    "-",
						    ["command"=>"Set this value of $text to the standard",
						     -command => sub{&set_params('this', @keys)},
						     -state=>((scalar keys %groups > 2) and (not $groups{$current}->{frozen})) ? 'normal' : 'disabled',
						    ],
						    (($def_ok) ?
						     ("-",
						      ["command"=>"Make this value of $text the session default",
						       -command => sub{session_defaults(@keys)}],
						      "-",
						      ["command"=>"Set $text to its default for this group",
						       -state   => $groups{$current}->{frozen} ? 'disabled' : 'normal',
						       -command => sub{&set_params('def', @keys)},
						      ],
						     ) : ()),
						    ## additional items in the context menu
						    ((exists $extra{$text}) ?
						     ("-",
						      [ command          => "---- $text options ----",
							-foreground       =>'grey20',
							-activeforeground =>'grey20',
							-background       =>$config{colors}{background},
							-activebackground =>$config{colors}{background},
							-font	       =>$config{fonts}{smbold},],
						      @{ $extra{$text} })
						     : ()),
						   )),
						 ]);
		   $menu ->Popup(-popover=>'cursor', -popanchor=>'w');
		 });
  };
};



## this is bound to a keyboard shortcut, so I cannot rely on the
## checkbutton just above to maintain the state correctly
sub tie_untie_e0 {
  my $state = $groups{$current}->{bkg_tie_e0};
  $state = ($state+1) % 2;
  $groups{$current}->make(bkg_tie_e0    => $state,
			  bkg_former_e0 => ($state) ? $groups{$current}->{bkg_e0} : 0);
  $menus{bkg_tie_e0} = $state;
  my $message = ($menus{bkg_tie_e0}) ?
    "Energy and k values tied to e0." :
      "Energy and k values untied from e0.";
  Echo($message);
};

sub group_click {
  my ($t, $which) = @_;


  my @in     = (-background => $config{colors}{activebackground},
	        -cursor     => $mouse_over_cursor, );
  my @out    = (-background => $config{colors}{background});
  $t -> bind('<Any-Enter>'=>sub{$t -> configure(@in ); });
  $t -> bind('<Any-Leave>'=>sub{$t -> configure(@out); });

  my ($str, $desc) = ("", "");
 SWITCH: {
    ($which eq 'project') and do {
      $str = 'The name of the current project file.  Click the "modified" button to save this project.';
      $desc = 'PROJECT';
      last SWITCH;
    };
    ($which eq 'current') and do {
      $str = "These parameters set aspects of the central atom.";
      $desc = 'BACKGROUND';
      last SWITCH;
    };
    ($which eq 'bkg') and do {
      $str = "These parameters determine how the normalization and background spline are found.";
      $desc = 'BACKGROUND';
      last SWITCH;
    };
    ($which eq 'fft') and do {
      $str = "These parameters determine how the forward Fourier transform is performed.";
      $desc = "FORWARD TRANSFORM";
      last SWITCH;
    };
    ($which eq 'bft') and do {
      $str = "These parameters determine how the backward Fourier transform is performed.";
      $desc = "BACKWARD TRANSFORM";
      last SWITCH;
    };
    ($which eq 'plot') and do {
      $str = "These parameters set certain plotting features specific to this group.";
      $desc = "PLOTTING";
      last SWITCH;
    };
  };
  $t -> bind('<1>' => sub{Echo($str)});
  $t -> bind('<3>' =>
	     sub{my $t = shift;
		 return 0 if ($which eq 'current');
		 return 0 unless ($current);
		 return 0 unless (scalar keys %groups > 1);
		 my $is_frozen = $groups{$current}->{frozen};
		 ##my $blue = ($is_frozen) ? $config{colors}{frozen}               : $config{colors}{activehighlightcolor};
		 ##my $cyan = ($is_frozen) ? $config{colors}{frozenrequiresupdate} : $config{colors}{requiresupdate};
		 my $blue = $config{colors}{activehighlightcolor};
		 my $cyan = $config{colors}{requiresupdate};
		 my $is_active = (($t->cget('-foreground') eq $blue) or
				  ($t->cget('-foreground') eq $cyan));
		 return 0 unless $is_active;
		 my @keys = grep {/^$which/ and not /eshift/} (keys %widget);
		 ##print join(" ", @keys), $/;
		 my $menu;
		 if ($which eq 'project') {
		   $menu=$t->Menu(-tearoff=>0,
				  -menuitems=>[['command'=>"Set all groups'  values to the current",
						 -command=>sub{
						   Echo('No data!'), return unless ($current);
						   Echo("Parameters for all groups reset to \`$current\'");
						   my $orig = $current;
						   foreach my $x (keys %marked) {
						     next if ($x eq 'Default Parameters');
						     next if ($x eq $current);
						     next if ($groups{$x}->{frozen});
						     $groups{$x}->set_to_another($groups{$current});
						     set_properties(1, $x, 0);
						   };
						   set_properties(1, $orig, 0);
						   Echo(@done);}],
					       ['command'=>"Set all marked groups'  values to the current",
						 -command=>sub{
						   Echo('No data!'), return unless ($current);
						   Echo("Parameters for all marked groups reset to \`$current\'");
						   my $orig = $current;
						   foreach my $x (keys %marked) {
						     next if ($x eq 'Default Parameters');
						     next if ($x eq $current);
						     next if ($groups{$x}->{frozen});
						     next unless ($marked{$x});
						     $groups{$x}->set_to_another($groups{$current});
						     set_properties(1, $x, 0);
						   };
						   set_properties(1, $orig, 0);
						   Echo(@done);}],
					       ['command'=>"Set current groups'  values to their defaults",
						-state   => $is_frozen ? 'disabled' : 'normal',
						-command=>sub{
						   Echo('No data!'), return unless ($current);
						   my @keys = grep {/^(bft|bkg|fft)/} (keys %widget);
						   set_params('def', @keys);
						   set_properties(1, $current, 0);
						   Echo("Reset all values for this group to their defaults");}],
					      ]);
		 } else {
		   $menu=$t->Menu(-tearoff=>0,
				  -menuitems=>[["command"=>"Set all groups to these $desc parameters",
						-command => sub{&set_params('all', @keys)},
						-state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
					       ],
					       ["command"=>"Set marked groups to these $desc parameters",
						-command => sub{&set_params('marked', @keys)},
						-state=>(scalar keys %groups > 2) ? 'normal' : 'disabled',
					       ],
					       "-",
					       ["command"=>"Set these $desc parameters to the standard",
						-command => sub{&set_params('this', @keys)},
						-state=>((scalar keys %groups > 2) and (not $is_frozen)) ? 'normal' : 'disabled',
					       ],
					       "-",
					       ["command"=>"Set these $desc parameters to their defaults",
						-state   => $is_frozen ? 'disabled' : 'normal',
						-command => sub{&set_params('def', @keys)}],
					       ["command"=>"Make these $desc parameters the session defaults",
						-command => sub{session_defaults(@keys)}],
					       (($which eq 'bkg') ?
					       ("-",
						["command"=>"Document section: background removal",
						 -command =>sub{pod_display("bkg::index.pod")}])
					       : ()),
					      ]);
		 };
		 $menu ->Popup(-popover=>'cursor', -popanchor=>'w');
	       });
};


## This is the function invoked by the right mouse click of a
## parameter label.  It is used to set individual parameters in or
## from other groups.
##   all:    set this parameter in all groups to the current
##           group's value
##   marked: set this parameter in all marked groups
##   this:   set this parameter in this group to the value in the
##           marked group (requires that one and only one group be marked)
sub set_params {
  my $how = shift;
  my @keys = @_;
  ($keys[0] = 'bkg_z')    if ($keys[0] eq 'z');
  ($keys[0] = 'fft_edge') if ($keys[0] eq 'edge');
  my ($e0response, $eshiftresponse) = ("","");
  my $save = $groups{$current}->{bkg_tie_e0}; # temporarily turn off tie_e0
  $groups{$current}->make(bkg_tie_e0=>0);

 SP: {
    ($how eq 'this') and do {
      my ($n, $which) = (0, '');
      foreach my $g (keys %marked) {
	($marked{$g}) and ($which = $g) and ++$n;
      };
      if ($n != 1) {
	$groups{$current}->make(bkg_tie_e0=>$save);
	Error('A standard is defined by marking one and only one group.');
	return;
      };
      foreach my $k (@keys) {
	my $val = $groups{$which}->{$k};
	## take care not to make a group it's own bkg standard
	($k eq 'bkg_stan') and ($val eq $current) and next;
	($k eq 'bkg_alg') or $groups{$current} -> make($k => $val);
	($k = 'bkg_nnorm') if ($k =~ m{bkg_nnorm});
	if ($k eq 'bkg_alg') {
	  $val = $groups{$which}->{bkg_cl};
	  $groups{$current} -> make(bkg_cl=>$val);
	  $val and $groups{$current} -> make(bkg_z=>$groups{$which}->{bkg_z});
	  $menus{bkg_alg} = ($val) ? 'CLnorm' : 'Autobk';
	  if ($val) {
	    $menus{bkg_z} = $groups{$which}->{bkg_z};
	    #$widget{bkg_z} -> configure(-state=>'normal');
	    $widget{bkg_rbkg} -> configure(-state=>'disabled');
	    foreach my $s (qw(bkg_spl1 bkg_spl2 bkg_spl1e bkg_spl2e)) {
	      $widget{$s} -> configure(-state=>'disabled');
	      $grab{$s} -> configure(-state=>'disabled');
	    };
	  } else {
	    #$widget{bkg_z} -> configure(-state=>'disabled');
	    $widget{bkg_rbkg} -> configure(-state=>'normal');
	    foreach my $s (qw(bkg_spl1 bkg_spl2 bkg_spl1e bkg_spl2e)) {
	      $widget{$s} -> configure(-state=>'normal');
	      $grab{$s} -> configure(-state=>'normal');
	    };
	  };
	} elsif ($widget{$k} =~ /Entry/) {
	  $widget{$k} -> configure(-validate=>'none');
	  $widget{$k} -> delete(qw/0 end/);
	  $widget{$k} -> insert(0, $groups{$current}->{$k});
	  $widget{$k} -> configure(-validate=>'key');
	  set_variable($k, $val, 1);
	} elsif ($widget{$k} =~ /Optionmenu/) {
	  $menus{$k} = $groups{$current}->{$k};
	  ($k eq 'bkg_alg') and ($val eq 'CLnorm') and
	    $menus{bkg_z} = $groups{$current}->{bkg_z};
	} elsif ($k eq 'bkg_flatten') {
	  $groups{$current} -> make(bkg_flatten=>$groups{$which}->{bkg_flatten});
	  if ($groups{$current} -> {bkg_flatten}) {
	    $widget{bkg_flatten}->select;
	  } else {
	    $widget{bkg_flatten}->deselect;
	  };
	};			# flag for updates
	($k =~ /bkg/) and $groups{$current}->make(update_bkg=>1);
	($k =~ /fft/) and $groups{$current}->make(update_fft=>1);
	($k =~ /bft/) and $groups{$current}->make(update_bft=>1);
      };
      Echo("Set variable(s) to the standard.");
    }; ## end of "this" block

    ($how eq 'def') and do {
      foreach my $k (@keys) {
	($k = 'bkg_nnorm') if ($k =~ m{bkg_nnorm});
	if ($k eq 'importance') {
	  $groups{$current}->make(importance=>1);
	  set_properties(0,$current,0);
	  $groups{$current}->make(bkg_tie_e0=>$save);
	  return;
	};
	next if (($k =~ /^plot/) or ($k =~ /^(edge|z)$/) or
		 ($k =~ /^bkg_(alg|e0|eshift|fixstep|stan|step)/));
	my ($s,$key) = split(/_/, $k);
	my $val = $config{$s}{$key};
	#print join("|", $k, $s, $key, $val), $/;
	$groups{$current}->make($k=>$val);
	($k =~ /bkg/) and $groups{$current}->make(update_bkg=>1);
	($k =~ /fft/) and $groups{$current}->make(update_fft=>1);
	($k =~ /bft/) and $groups{$current}->make(update_bft=>1);
	## range parameters require special attention
	if ($k =~ /(bkg_(nor[12]|pre[12]|spl([12]|1e|2e))|fft_km(ax|in))/) {
	  my ($pre1, $pre2, $nor1, $nor2, $spl1, $spl2, $kmin, $kmax) =
	    set_range_params($current);
	  ($kmax = 12) if ($kmax <= 0);
	SWITCH: {
	    $groups{$current}->make(bkg_pre1 =>$pre1), last SWITCH if ($k eq 'bkg_pre1');
	    $groups{$current}->make(bkg_pre2 =>$pre2), last SWITCH if ($k eq 'bkg_pre2');
	    $groups{$current}->make(bkg_nor1 =>$nor1), last SWITCH if ($k eq 'bkg_nor1');
	    $groups{$current}->make(bkg_nor2 =>$nor2), last SWITCH if ($k eq 'bkg_nor2');
	    $groups{$current}->make(bkg_spl1 =>$spl1,
				    bkg_spl1e=>$groups{$current}->k2e($spl1)), last SWITCH if ($k eq 'bkg_spl1');
	    $groups{$current}->make(bkg_spl2 =>$spl2,
				    bkg_spl2e=>$groups{$current}->k2e($spl2)), last SWITCH if ($k eq 'bkg_spl2');
	    $groups{$current}->make(fft_kmin =>$kmin), last SWITCH if ($k eq 'fft_kmin');
	    $groups{$current}->make(fft_kmax =>$kmax), last SWITCH if ($k eq 'fft_kmax');
	    $groups{$current}->make(bkg_spl1 =>$spl1,
				    bkg_spl1e=>$groups{$current}->k2e($spl1)), last SWITCH if ($k eq 'bkg_spl1e');
	    $groups{$current}->make(bkg_spl2 =>$spl2,
				    bkg_spl2e=>$groups{$current}->k2e($spl2)), last SWITCH if ($k eq 'bkg_spl2e');
	    $groups{$current}->make(bkg_flatten =>$config{bkg}{flatten}),      last SWITCH if ($k eq 'bkg_flatten');
	  };
	  $groups{$current} -> kmax_suggest(\%plot_features) if ($groups{$current}->{fft_kmax} == 999);
	};
      };
      set_properties(0,$current,0);
      Echo("Set default variable value(s).");
    }; ## end of "def" block

    (($how eq 'all') or ($how eq 'marked')) and do {
      my ($inc_e0, $inc_eshift) = ("", "");
      if ($config{general}{query_constrain}) {
	my $dialog =
	  $top -> Dialog(-bitmap         => 'questhead',
			 -text           => "You are about to constrain parameters across $how groups.  Are you sure you want to do this?",
			 -title          => 'Athena: Constrain parameters...?',
			 -buttons        => [qw/Yes No/],
			 -default_button => 'Yes');
	my $response = $dialog->Show();
	return if ($response eq 'No');
	$e0response = $eshiftresponse = 'Yes';
      } else {
	$inc_e0     = grep(/bkg_e0/,     @keys);
	$inc_eshift = grep(/bkg_eshift/, @keys);
	if ($inc_e0 and $inc_eshift) {
	  my $dialog =
	    $top -> Dialog(-bitmap         => 'questhead',
			   -text           => "You are about to constrain both E0 and the E0 shift for $how groups.  Constraining E0 shifts can be a bad idea if there are groups of different edges and E0 shifts are typically set in the alignment dialog.  Should Athena constrain the E0 values?",
			   -title          => 'Athena: Constrain e0 and the e0 shift...?',
			   -buttons        => [qw/Yes No/],
			   -default_button => 'Yes');
	  $e0response = $dialog->Show();
	  $eshiftresponse = $e0response;
	};
      };
      foreach my $g (keys %marked) {
	next if ($g eq $current);
	next if (($how eq 'marked') and not $marked{$g});
	my $was = $groups{$g}->{bkg_tie_e0}; # temporarily turn off tie_e0
	$groups{$g}->make(bkg_tie_e0=>0);
      K: foreach my $k (@keys) {
	  ($k = 'bkg_nnorm') if ($k =~ m{bkg_nnorm});
	  if (($k eq 'bkg_e0') and not $inc_eshift) {
	    next K if ($e0response eq 'No');
	    unless ($e0response eq 'Yes') {
	      my $dialog =
		$top -> Dialog(-bitmap         => 'questhead',
			       -text           => "You are about to constrain E0 for $how groups.  This is handy if these groups are all of the same edge, but is a poor idea for groups of different edges.  Should Athena constrain the E0 values?",
			       -title          => 'Athena: Constrain e0...?',
			       -buttons        => [qw/Yes No/],
			       -default_button => 'Yes');
	      $e0response = $dialog->Show();
	      next K if ($e0response eq 'No');
	    };
	  } elsif (($k eq 'bkg_eshift') and not $inc_e0) {
	    next K if ($eshiftresponse eq 'No');
	    unless ($eshiftresponse eq 'Yes') {
	      my $dialog =
		$top -> Dialog(-bitmap         => 'questhead',
			       -text           => "You are about to constrain the E0 shift for $how groups.  Setting E0 shifts is normally done via the alignment dialog.  Should Athena constrain the E0 shift values?",
			       -title          => 'Athena: Constrain the e0 shift...?',
			       -buttons        => [qw/Yes No/],
			       -default_button => 'Yes');
	      $eshiftresponse = $dialog->Show();
	      next K if ($eshiftresponse eq 'No');
	    };
	  };
	  my $val = $groups{$current}->{$k};
	  ## take care not to make a group it's own bkg standard
	  ($k eq 'bkg_stan') and ($val eq $g) and next;
	  if ($k eq 'bkg_alg') {
	    $val = $groups{$current}->{bkg_cl};
	    $groups{$g} -> make(bkg_cl=>$val);
	    $val and $groups{$g} -> make(bkg_z=>$groups{$current}->{bkg_z});
	  } elsif ($k eq 'bkg_stan') {
	    $groups{$g} -> make(bkg_stan     => $val,
				#bkg_stan_lab => $groups,
			       );
	  } else {
	    $groups{$g} -> make($k => $val);
	  SWITCH: {
	      $groups{$g} -> make(bkg_spl1e => $groups{$g}->k2e($val)),
		last SWITCH if ($k eq 'bkg_spl1');
	      $groups{$g} -> make(bkg_spl2e => $groups{$g}->k2e($val)),
		last SWITCH if ($k eq 'bkg_spl2');
	      $groups{$g} -> make(bkg_spl1 => $groups{$g}->e2k($val)),
		last SWITCH if ($k eq 'bkg_spl1e');
	      $groups{$g} -> make(bkg_spl2 => $groups{$g}->e2k($val)),
		last SWITCH if ($k eq 'bkg_spl2e');
	    };
	  };			# flag for updates
	  ($k =~ /bkg/) and $groups{$g}->make(update_bkg=>1);
	  ($k =~ /fft/) and $groups{$g}->make(update_fft=>1);
	  ($k =~ /bft/) and $groups{$g}->make(update_bft=>1);
	};
	$groups{$g}->make(bkg_tie_e0=>$was);
      };
      Echo("Set variable(s) for all groups") if ($how eq 'all');
      Echo("Set variable(s) for all marked groups") if ($how eq 'marked');
    };  # end of "all" and "marked"

    (($how eq 'def_all') or ($how eq 'def_marked')) and do {
      Echo("Set this parameter to its default for all or marked groups....");
    };

    $groups{$current}->make(bkg_tie_e0=>$save);
  };
  project_state(0);
};


sub session_defaults {
  Echo("No data!"), return unless $current;
  foreach my $key (@_) {
    $groups{$current} -> SetDefault($key => $groups{$current}->{$key});
  };
};
sub clear_session_defaults {
## set default analysis parameter values
  $setup -> SetDefault(bkg_e0	   => $config{bkg}{e0},
		       bkg_kw	   => $config{bkg}{kw},
		       bkg_rbkg	   => $config{bkg}{rbkg},
		       bkg_pre1	   => $config{bkg}{pre1},
		       bkg_pre2	   => $config{bkg}{pre2},
		       bkg_nor1	   => $config{bkg}{nor1},
		       bkg_nor2	   => $config{bkg}{nor2},
		       bkg_nnorm   => $config{bkg}{nnorm},
		       bkg_spl1	   => $config{bkg}{spl1},
		       bkg_spl2	   => $config{bkg}{spl2},
		       bkg_nclamp  => $config{bkg}{nclamp},
		       bkg_clamp1  => $config{bkg}{clamp1},
		       bkg_clamp2  => $config{bkg}{clamp2},
		       bkg_flatten => $config{bkg}{flatten},
		       #fft_kw	   => $config{fft}{kw},
		       fft_dk	   => $config{fft}{dk},
		       fft_win	   => $config{fft}{win},
		       fft_kmin	   => $config{fft}{kmin},
		       fft_kmax	   => $config{fft}{kmax},
		       fft_pc	   => $config{fft}{pc},
		       bft_dr	   => $config{bft}{dr},
		       bft_win	   => $config{bft}{win},
		       bft_rmin	   => $config{bft}{rmin},
		       bft_rmax	   => $config{bft}{rmax},
		      );
};


## This is the callback used to validate entry boxes.  Mostly it makes
## sure that the entry is a number.  For the spline ranges, it
## recomputes the values in E or k as appropriate.  It also worries
## about relative and absolute energy values.
sub set_variable {
  ##print join(" | ", @_, $/);
  my ($k, $entry, $prop) = (shift, shift, shift);
  ## attempt to change background color on focus.  validate does not
  ## seem to work as advertised.
  #(defined($prop)) or $widget{$k} -> configure(-background=>'pink');
  return 0 if (($groups{$current}->{frozen}) and ($k !~ /^(ind|pf|po|sta|plot_yoffset)/));
  ($entry =~ m{\A\s*\z}) and ($entry = 0);	# error checking ...
  ($entry =~ m{\A\s*-\z}) and return 1;	# error checking ...
  ($entry =~ m{\A\s*-?(\d+\.?\d*|\.\d+)\s*\z}) or return 0;
  (($k =~ m{([bf]ft|spl[12]|rbkg)}) and ($entry < 0)) and return 0;
  (($k =~ m{\Atft_(?:d[kr]|[kr]m(?:ax|in)|npts|r[123])}) and ($entry < 0)) and return 0;
  (($k =~ m{lcf_noise}) and ($entry < 0)) and return 0;

  ## editing bkg_e0 and parameters are tied to the background
  ## need to keep track of previous reasonable value -- consider
  ## an edge energy of 11111.  Changing that to 11110 involves the
  ## sequence 11111 -> 1111 -> 11110.  For the middle step, all the
  ## other values will change by 10000 volts!  To avoid that, the
  ## former_e0 parameter is maintained and used to compute the shift
  ## of all the other parameters
  if (($k eq "bkg_e0") and ($groups{$current}->{bkg_tie_e0})) {
    my $save = $groups{$current}->{bkg_e0};
    my $delta = $entry - $groups{$current}->{bkg_former_e0};
    my $shift = sprintf("%.4f", (abs($delta) > 100) ? 0 : $delta);
    ##print join("\t", $entry, $groups{$current}->{bkg_e0}, $groups{$current}->{bkg_former_e0}, $delta, $shift), $/;
    $groups{$current}->make(bkg_former_e0 => (abs($delta) > 100)
			    ? $groups{$current}->{bkg_former_e0}
			    : $entry);
    foreach my $which (qw(pre1 pre2 nor1 nor2 spl1e spl2e)) {
      my $value = $groups{$current}->{"bkg_$which"}-$shift;
      ($value = 0) if (($value < 0) and ($which =~ m{spl}));
      $groups{$current} -> make("bkg_$which"  => $value);
      $widget{"bkg_$which"} -> configure(-validate=>'none');
      $widget{"bkg_$which"} -> delete(qw/0 end/);
      $widget{"bkg_$which"} -> insert(0, $groups{$current}->{"bkg_$which"});
      $widget{"bkg_$which"} -> configure(-validate=>'key');
    };
    ## now fix up all the k-valued parameters
    $groups{$current}->make(bkg_spl1=>$groups{$current}->e2k($groups{$current}->{bkg_spl1e}),
			    bkg_spl2=>$groups{$current}->e2k($groups{$current}->{bkg_spl2e}),
			   );
    foreach my $which (qw(fft_kmin fft_kmax)) {
      my $e = $groups{$current}->k2e($groups{$current}->{$which})-$shift;
      my $k = $groups{$current}->e2k($e);
      $groups{$current}->make($which=>$k);
    };
    foreach my $which (qw(bkg_spl1 bkg_spl2 fft_kmin fft_kmax)) {
      $widget{$which} -> configure(-validate=>'none');
      $widget{$which} -> delete(qw/0 end/);
      $widget{$which} -> insert(0, $groups{$current}->{$which});
      $widget{$which} -> configure(-validate=>'key');
    };
  };

  ## spline boundaries
  if ($k =~ /bkg_spl/) {
    my $x;
    if ($k eq 'bkg_spl1') {
      my $e = $groups{$current}->k2e($entry);
      $groups{$current}->make(bkg_spl1e=>$e);
      $x = 'bkg_spl1e';
    } elsif ($k eq 'bkg_spl2') {
      my $e = $groups{$current}->k2e($entry);
      $groups{$current}->make(bkg_spl2e=>$e);
      $x = 'bkg_spl2e';
    } elsif ($k eq 'bkg_spl1e') {
      my $k = $groups{$current}->e2k($entry);
      $groups{$current}->make(bkg_spl1=>$k);
      $x = 'bkg_spl1';
    } elsif ($k eq 'bkg_spl2e') {
      my $k = $groups{$current}->e2k($entry);
      $groups{$current}->make(bkg_spl2=>$k);
      $x = 'bkg_spl2';
    };
    $widget{$x} -> configure(-validate=>'none');
    $widget{$x} -> delete(qw/0 end/);
    $widget{$x} -> insert(0, $groups{$current}->{$x});
    $widget{$x} -> configure(-validate=>'key');
  };

  # handle limits of deglitching margins
  if ($k =~ /^deg/) {
    my ($abs_pre1, $abs_pre2, $abs_nor1, $abs_nor2) =
      ($groups{$current}->{bkg_e0} + $groups{$current}->{bkg_pre1},
       $groups{$current}->{bkg_e0} + $groups{$current}->{bkg_pre2},
       $groups{$current}->{bkg_e0} + $groups{$current}->{bkg_nor1},
       $groups{$current}->{bkg_e0} + $groups{$current}->{bkg_nor2});
    my $x;
    if ($k eq 'deg_emin') {
      if (($entry > $groups{$current}->{deg_emax}) and
	  ($entry < $groups{$current}->{bkg_e0}) and
	  ($groups{$current}->{deg_emax} < $groups{$current}->{bkg_e0})) {
	return 0
      } elsif (($entry < $groups{$current}->{bkg_e0}) and
	  ($groups{$current}->{deg_emax} > $abs_pre2)) {
	$groups{$current}->make(deg_emax=>$abs_pre2);
	$x = 'deg_emax';
      } elsif (($entry > $groups{$current}->{bkg_e0}) and
	  ($groups{$current}->{deg_emax} < $entry)) {
	$groups{$current}->make(deg_emax=>$abs_nor2);
	$x = 'deg_emax';
      };
    } elsif ($k eq 'deg_emax'){
      if (($entry < $groups{$current}->{deg_emin}) and
	  ($entry > $groups{$current}->{bkg_e0}) and
	  ($groups{$current}->{deg_emin} > $groups{$current}->{bkg_e0})) {
	return 0
      } elsif (($entry < $groups{$current}->{bkg_e0}) and
	  ($groups{$current}->{deg_emin} > $entry)) {
	$groups{$current}->make(deg_emin=>$abs_pre1);
	$x = 'deg_emin';
      } elsif (($entry > $groups{$current}->{bkg_e0}) and
	  ($groups{$current}->{deg_emin} < $abs_nor1)) {
	$groups{$current}->make(deg_emin=>$abs_nor1);
	$x = 'deg_emin';
      };
    };
    if ($x) {
      my $v = $groups{$current}->{$x};
      $widget{$x} -> configure(-validate=>'none');
      $widget{$x} -> delete(qw/0 end/);
      $widget{$x} -> insert(0, $v);
      $widget{$x} -> configure(-validate=>'key');
    };
  };

  ## linear combination fit parameters
  if ($k =~ /^lcf_fitm(ax|in)/) {
    $groups{$current}->make($k=>$entry);
    $widget{$k} -> configure(-validate=>'none');
    $widget{$k} -> delete(qw/0 end/);
    $widget{$k} -> insert(0, $groups{$current}->{$k});
    $widget{$k} -> configure(-validate=>'key');
    return 1;
  };

  $groups{$current}->make($k=>$entry), return 1 if ($k =~ m{^mee});

  ## return if this is not a front-page variable
  return 1 if ($k =~ /\A(?:al|lcf|tft)/);
  project_state(0), return 1 if ($k =~ /\A(?:conv|ind|pf|po|sa|sta)/);
  return 1 if ($k =~ /\A(?:enc|rebin)/);

  ## set this variable
  $groups{$current}->make($k=>$entry);
  if ($k eq 'bkg_e0') {
    my $k = $groups{$current}->{bkg_spl1};
    $groups{$current} -> make(bkg_spl1e=>$groups{$current}->k2e($k));
    $k = $groups{$current}->{bkg_spl2};
    $groups{$current} -> make(bkg_spl2e=>$groups{$current}->k2e($k));
    foreach my $x (qw/bkg_spl1e bkg_spl2e/) {
      $widget{$x} -> configure(-validate=>'none');
      $widget{$x} -> delete(qw/0 end/);
      $widget{$x} -> insert(0, $groups{$current}->{$x});
      $widget{$x} -> configure(-validate=>'key');
    };
  };

  ## tie together data and reference
  if ($k eq 'bkg_eshift') {
    if ($groups{$current}->{reference} and exists($groups{$groups{$current}->{reference}})) {
      $groups{$groups{$current}->{reference}} -> make(bkg_eshift=>$entry);
    };
  };

 SWITCH: {			# flag what chores need updating
    $groups{$current}->make(update_bkg=>1), last SWITCH if ($k =~ /bkg/);
    $groups{$current}->make(update_fft=>1), last SWITCH if ($k =~ /fft/);
    $groups{$current}->make(update_bft=>1), last SWITCH if ($k =~ /bft/);
  };

  project_state(0);
  return 1;
};

sub check_z {
  my $this = shift;
  return 1 if ($this =~ /$Ifeffit::Files::elem_regex$/i);
  my $dialog =
    $top -> Dialog(-bitmap         => 'error',
		   -text           => "$menus{bkg_z} is not an element symbol",
		   -title          => 'Athena: Invalid element symbol',
		   -buttons        => ['OK'],
		   -default_button => 'OK',
		   -popover        => 'cursor');
  $dialog->raise;
  my $response = $dialog->Show();
  $widget{z} -> focus;
  return 0;
};

sub identify_reference {
  my $message = "This group does not have a reference channel.";
  if (exists($groups{$groups{$current}->{reference}})) {
    my $this = $groups{$current}->{label};
    my $ref  = $groups{$groups{$current}->{reference}}->{label};
    $message = "The reference for \"$this\" is \"$ref\".";
  };
  Echo($message);
};

sub explain_eshift {
  my $text = <<EOH
The energy shift is applied to the energy axis of the input data before any other data processing
happens.  Thus the value for E0 is chosen on the data's energy axis AFTER the energy shift is applied.

Other energy values, such as the pre- and post-edge line parameters and the plotting range
take relative energy values.  Their values are relative to E0, thus computed AFTER the energy
shift is applied.

Data processing operations such as merging and calculation of difference spectra are also
performed AFTER the energy shift is applied.  The energy shift can be changed by hand, but is
normally set using the data alignment dialog.
EOH
    ;
  $text =~ s{\n}{ }g;
  $text =~ s/ /\n\n/g;
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => $text,
		   -title          => 'Athena: Understanding the energy shift',
		   -buttons        => ['OK'],
		   -default_button => 'OK',
		   #-popover        => 'cursor',
		  );
  $dialog->raise;
  my $response = $dialog->Show();
  return 0;
};

## END OF DRAW PROPERTIES SUBSECTION
##########################################################################################
