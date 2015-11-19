## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This file implements linear combination XANES fitting in Athena

sub lcf {

  ## generally, we do not change modes unless there is data.
  ## exceptions include things like the prefernces and key bindings,
  ## which are data-independent
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");

  ## this is a way of testing the current list of data groups for some
  ## necessary property.  for the demo, this will just be the list of
  ## groups
  my @keys = ('None');
  foreach my $k (&sorted_group_list) {
    ($groups{$k}->{is_xmu} or $groups{$k}->{is_chi}) and push @keys, $k;
  };
  Echo("You need two or more xmu groups to do linear combination fitting"), return unless ($#keys >= 2);

  $values_menubutton -> menu -> entryconfigure(17, -state=>'disabled'); # purge lcf
  $right_values -> menu -> entryconfigure(17, -state=>'disabled'); # purge lcf
  my %lcf_params = (unknown    => $current,
		    fitspace   => $groups{$current}->{lcf_fitspace} || $config{linearcombo}{fitspace},
		    components => $config{linearcombo}{components},
		    difference => 0,
		    fitmin_e   => $groups{$current}->{lcf_fitmin_e} || $config{linearcombo}{fitmin},
		    fitmax_e   => $groups{$current}->{lcf_fitmax_e} || $config{linearcombo}{fitmax},
		    fitmin_k   => $groups{$current}->{lcf_fitmin_k} || $config{linearcombo}{fitmin_k},
		    fitmax_k   => $groups{$current}->{lcf_fitmax_k} || $config{linearcombo}{fitmax_k},
		    enot       => $groups{$current}->{bkg_e0},
		    linear     => $groups{$current}->{lcf_linear} || 0,
		    nonneg     => $groups{$current}->{lcf_nonneg} || 1,
		    100        => $groups{$current}->{lcf_100}    || 1,
		    e0all      => $groups{$current}->{lcf_e0all}  || 0,
		    yint       => 0,
		    slope      => 0,
		    noise      => 0,
		    deflist    => [],
		    toggle     => 0,
		    maxstan    => 4,
		    iterator   => "",
		    sumsqr     => 0,
		    kw         => $plot_features{kw} || 1,
		    #kw         => $groups{$current}->{fft_kw} || 1,
		    keys       => \@keys,
		    );
  if ($lcf_params{fitspace} eq 'k') {
    $lcf_params{fitmin} = $lcf_params{fitmin_k};
    $lcf_params{fitmax} = $lcf_params{fitmax_k};
  } else {
    $lcf_params{fitmin} = $lcf_params{fitmin_e};
    $lcf_params{fitmax} = $lcf_params{fitmax_e};
  };
  ($lcf_params{fitspace} = 'k') if $groups{$current}->{is_chi};

  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = $config{linearcombo}{emin};
  $plot_features{emax} = $config{linearcombo}{emax};
  project_state($ps);		# don't toggle if currently saved

  ## these two global variables must be set before this view is displayed
  $fat_showing = 'lcf';
  $hash_pointer = \%lcf_params;

  ## disable many menus.
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);

  ## this removes the currently displayed view without destroying its
  ## contents
  $fat -> packForget;

  ## define the parent Frame for this analysis chore and pack it in
  ## the correct location
  my $lcf = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$lcf -> packPropagate(0);
  ## global variable identifying which Frame is showing
  $which_showing = $lcf;

  $lcf -> Label(-text=>"Linear combination fitting",
		   -font=>$config{fonts}{large},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  my $frame = $lcf -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Label(-text=>"Unknown: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		  )
    -> pack(-side=>'left');

  $widget{lcf_unknown} = $frame -> Label(-text=>$groups{$current}->{label},
					 -foreground=>$config{colors}{button})
    -> pack(-side=>'left');


  $frame = $lcf -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x',);
  $frame -> Label(-text=>"Fitting range: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		  )
    -> pack(-side=>'left', -anchor=>'n');
  $widget{lcf_fitmin} = $frame -> Entry(-width=>6,
					-validate=>'none',
					-validatecommand=>[\&lcf_set_variable, 'lcf_fitmin'],
					##-textvariable=>\$lcf_params{fitmin},
				       )
    -> pack(-side=>'left', -anchor=>'n');
  $grab{lcf_fitmin} = $frame -> Button(@pluck_button, @pluck,
				       -command=>sub{lcf_pluck(\%lcf_params, 'fitmin');
						     lcf_quickplot(\%lcf_params); })
    -> pack(-side=>'left', -pady=>2, -anchor=>'n');
  $frame -> Label(-text=>' to ',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left', -anchor=>'n');
  $widget{lcf_fitmax} = $frame -> Entry(-width=>6,
					-validate=>'none',
					-validatecommand=>[\&lcf_set_variable, 'lcf_fitmax'],
					##-textvariable=>\$lcf_params{fitmax},
				       )
    -> pack(-side=>'left', -anchor=>'n');
  $grab{lcf_fitmax} = $frame -> Button(@pluck_button, @pluck,
				       -command=>sub{lcf_pluck(\%lcf_params, 'fitmax');
						     lcf_quickplot(\%lcf_params); })
    -> pack(-side=>'left', -pady=>2, -anchor=>'n');
  $widget{lcf_components} = $frame
    -> Checkbutton(-text=>'Plot components?',
		   -selectcolor=>$config{colors}{single},
		   -width=>15,
		   -anchor=>'w',
		   -variable=>\$lcf_params{components})
      -> pack(-side=>'right', -anchor=>'w');

  $frame = $lcf -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Label(-text=>"Fitting space: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		  )
    -> pack(-side=>'left', -anchor=>'n');
  $frame -> Radiobutton(-text=>'norm(E)',
			-selectcolor=>$config{colors}{single},
			-value=>'e',
			-variable=>\$lcf_params{fitspace},
			-command=>sub{
			  $lcf_params{fitmin_e} = $groups{$current}->{lcf_fitmin_e} || $config{linearcombo}{fitmin};
			  $lcf_params{fitmax_e} = $groups{$current}->{lcf_fitmax_e} || $config{linearcombo}{fitmax};
			  $groups{$current}->MAKE(lcf_fitspace => $lcf_params{fitspace},
						  lcf_fitmin   => $lcf_params{fitmin_e},
						  lcf_fitmax   => $lcf_params{fitmax_e});
			  foreach (qw(fitmin fitmax)) {
			    $lcf_params{$_} = $lcf_params{$_."_e"};
			    $widget{"lcf_$_"} -> configure(-validate=>'none');
			    $widget{"lcf_$_"} -> delete(0, 'end');
			    $widget{"lcf_$_"} -> insert('end', $lcf_params{$_});
			    $widget{"lcf_$_"} -> configure(-validate=>'key');
			  };
			  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
			    $widget{"lcf_e0val$i"} -> configure(-state=>'normal');
			    $widget{"lcf_e0$i"} -> configure(-state=>'normal');
			  };
			  $widget{lcf_linear} -> configure(-state=>'normal');
			  $widget{lcf_e0all}  -> configure(-state=>'normal');
			  $widget{lcf_operations} -> entryconfigure(7, -state=>'disabled', -style=>$lcf_params{disabled_style});
			  lcf_reset(\%lcf_params,1);
			  lcf_quickplot_e(\%lcf_params);
			})
    -> pack(-side=>'left', -anchor=>'n');
  $frame -> Radiobutton(-text=>'deriv(E)',
			-selectcolor=>$config{colors}{single},
			-value=>'d',
			-variable=>\$lcf_params{fitspace},
			-command=>sub{
			  $lcf_params{fitmin_e} = $groups{$current}->{lcf_fitmin_e} || $config{linearcombo}{fitmin};
			  $lcf_params{fitmax_e} = $groups{$current}->{lcf_fitmax_e} || $config{linearcombo}{fitmax};
			  $groups{$current}->MAKE(lcf_fitspace => $lcf_params{fitspace},
						  lcf_fitmin   => $lcf_params{fitmin_e},
						  lcf_fitmax   => $lcf_params{fitmax_e});
			  foreach (qw(fitmin fitmax)) {
			    $lcf_params{$_} = $lcf_params{$_."_e"};
			    $widget{"lcf_$_"} -> configure(-validate=>'none');
			    $widget{"lcf_$_"} -> delete(0, 'end');
			    $widget{"lcf_$_"} -> insert('end', $lcf_params{$_});
			    $widget{"lcf_$_"} -> configure(-validate=>'key');
			  };
			  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
			    $widget{"lcf_e0val$i"} -> configure(-state=>'normal');
			    $widget{"lcf_e0$i"} -> configure(-state=>'normal');
			  };
			  $widget{lcf_linear} -> configure(-state=>'disabled');
			  $widget{lcf_e0all}  -> configure(-state=>'normal');
			  $widget{lcf_operations} -> entryconfigure(7, -state=>'disabled', -style=>$lcf_params{disabled_style});
			  lcf_reset(\%lcf_params,1);
			  lcf_quickplot_e(\%lcf_params);
			})
    -> pack(-side=>'left', -anchor=>'n');
  $frame -> Radiobutton(-text=>'chi(k)',
			-selectcolor=>$config{colors}{single},
			-value=>'k',
			-variable=>\$lcf_params{fitspace},
			-command=>sub{
			  $lcf_params{fitmin_k} = $groups{$current}->{lcf_fitmin_k} || $config{linearcombo}{fitmin_k};
			  $lcf_params{fitmax_k} = $groups{$current}->{lcf_fitmax_k} || $config{linearcombo}{fitmax_k};
			  $groups{$current}->MAKE(lcf_fitspace => $lcf_params{fitspace},
						  lcf_fitmin   => $lcf_params{fitmin_k},
						  lcf_fitmax   => $lcf_params{fitmax_k});
			  foreach (qw(fitmin fitmax)) {
			    $lcf_params{$_} = $lcf_params{$_."_k"};
			    $widget{"lcf_$_"} -> configure(-validate=>'none');
			    $widget{"lcf_$_"} -> delete(0, 'end');
			    $widget{"lcf_$_"} -> insert('end', $lcf_params{$_});
			    $widget{"lcf_$_"} -> configure(-validate=>'key');
			  };
			  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
			    $widget{"lcf_e0val$i"} -> configure(-state=>'disabled');
			    $widget{"lcf_e0$i"} -> configure(-state=>'disabled');
			  };
			  $widget{lcf_linear} -> configure(-state=>'disabled');
			  $widget{lcf_e0all}  -> configure(-state=>'disabled');
			  $widget{lcf_operations} -> entryconfigure(7, -state=>'normal', -style=>$lcf_params{normal_style});
			  lcf_reset(\%lcf_params,1);
			  lcf_quickplot_k(\%lcf_params);
			})
    -> pack(-side=>'left', -anchor=>'n');

  $widget{lcf_difference} = $frame
    -> Checkbutton(-text=>'Plot difference?',
		   -selectcolor=>$config{colors}{single},
		   -width=>15,
		   -anchor=>'w',
		   -variable=>\$lcf_params{difference})
      -> pack(-side=>'right', -anchor=>'w');





  ## this is a spacer frame which pushes all the widgets to the top
  ## $lcf -> Frame(-background=>$config{colors}{darkbackground})
  ##   -> pack(-side=>'bottom', -expand=>1, -fill=>'both');

  ## at the bottom of the frame, there are full width buttons for
  ## returning to the main view and for going to the appropriate
  ## document section
  $lcf -> Button(-text=>'Return to the main window',  @button_list,
		    -background=>$config{colors}{background2},
		    -activebackground=>$config{colors}{activebackground2},
		    -command=>sub{$groups{$current}->dispose("unguess\n", $dmode);
				  $values_menubutton -> menu -> entryconfigure(17, -state=>'normal'); # purge lcf
				  $right_values -> menu -> entryconfigure(17, -state=>'normal');
				  #$groups{$current}->dispose("erase \@group l___cf\n");
		                  &reset_window($lcf, "linear combination fitting", \@save);
			       })
    -> pack(-side=>'bottom', -fill=>'x');
  ## help button
  $lcf -> Button(-text=>'Document section: Linear combination fitting',
		 @button_list,
		 -command=>sub{pod_display("analysis::lcf.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);


  my $notebook = $lcf ->NoteBook(-background=>$config{colors}{background},
				 -backpagecolor=>$config{colors}{background},
				 -inactivebackground=>$config{colors}{inactivebackground},
				 #-foreground=>$config{colors}{activehighlightcolor},
				 -font=>$config{fonts}{small},
				)
    -> pack(-side=>'top', -fill =>'both', -expand=>1, -padx=>4, -pady=>4);
  $widget{lcf_notebook} = $notebook;

  my ($buttonframe, $st, $re, $co);
  $st = $notebook -> add('standards',
			 -label=>'Standards spectra',
			 -anchor=>'center',
			 #-raisecmd=>sub{$buttonframe->pack(-in=>$st)}
			);
  $re = $notebook -> add('results',
			 -label=>'Fit results',
			 -anchor=>'center',
			 #-raisecmd=>sub{$buttonframe->pack(-in=>$re)}
			);
  $co = $notebook -> add('combinatorics',
			 -label=>'Combinatorics',
			 -anchor=>'center',
			 -state=>'disabled',
			 #-raisecmd=>sub{$buttonframe->packForget}
			);
  $widget{lcf_notebook} -> pageconfigure('combinatorics', -state=>'normal')
    if (exists $lcf_data{$current});


  my $outerframe = $st -> Frame()
    -> pack(-side=>'bottom', -fill=>'both', -expand=>1, -padx=>2, -pady=>0, -anchor=>'s');

  ## frame with control buttons
  $buttonframe = $outerframe -> LabFrame(-label=>'Operations',
					 -foreground=>$config{colors}{activehighlightcolor},
					 -labelside=>'acrosstop',)
    -> pack(-side=>'right', -fill=>'both', -expand=>1, -padx=>2, -pady=>4, -anchor=>'s');
  $widget{lcf_operations} = $buttonframe ->Scrolled('HList',
						    -scrollbars	      => 'oe',
						    -background	      => $config{colors}{background},
						    -selectmode	      => 'single',
						    -selectbackground => $config{colors}{activebackground},
						    -highlightcolor   => $config{colors}{background},
						    -browsecmd	      => sub{lcf_multiplexer(\%lcf_params)},
						   )
    -> pack(-fill=>'both', -expand=>1);
  $widget{lcf_operations} -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  BindMouseWheel($widget{lcf_operations});
  my $t = $buttonframe->Subwidget("label");
  my @bold   = (-foreground => $config{colors}{marked},);
  my @normal = (-foreground => $config{colors}{activehighlightcolor},);

  $t -> bind("<Any-Enter>", sub {shift->configure(@bold)});
  $t -> bind("<Any-Leave>", sub {shift->configure(@normal)});
  $t -> bind('<ButtonPress-1>' => sub{Echo("Clicking on an entries in the operations list will perform the function described.")});


  $lcf_params{normal_style}   = $widget{lcf_operations} -> ItemStyle('text',
								     -font=>$config{fonts}{small},
								     -anchor=>'w',
								     -foreground=>$config{colors}{foreground});
  $lcf_params{disabled_style} = $widget{lcf_operations} -> ItemStyle('text',
								     -font=>$config{fonts}{small},
								     -anchor=>'w',
								     -foreground=>$config{colors}{disabledforeground});


  $widget{lcf_operations} -> add(1,
				 -itemtype =>'text',
				 -text	   =>'Fit this group',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(2,
				 -itemtype =>'text',
				 -text	   =>'Fit all combinations',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(3,
				 -itemtype =>'text',
				 -text	   =>'Fit marked groups',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(4,
				 -itemtype =>'text',
				 -text	   =>'Write a report',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(5,
				 -itemtype =>'text',
				 -text	   =>'Marked fits report',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(6,
				 -itemtype =>'text',
				 -text	   =>'Plot data + sum',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(7,
				 -itemtype =>'text',
				 -text	   =>'Plot data + sum in R',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(8,
				 -itemtype =>'text',
				 -text	   =>'Make fit group',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(9,
				 -itemtype =>'text',
				 -text	   =>'Make difference group',
				 -state	   => 'disabled',
				 -style	   => $lcf_params{disabled_style},
				);
  $widget{lcf_operations} -> add(10,
				 -itemtype =>'text',
				 -text	   =>'Set params, all groups',
				 -state	   => 'normal',
				 -style	   => $lcf_params{normal_style},
				);
  $widget{lcf_operations} -> add(11,
				 -itemtype =>'text',
				 -text	   =>'Set params, marked groups',
				 -state	   => 'normal',
				 -style	   => $lcf_params{normal_style},
				);
  $widget{lcf_operations} -> add(12,
				 -itemtype =>'text',
				 -text	   =>'Reset',
				 -state	   => 'normal',
				 -style	   => $lcf_params{normal_style},
				);


  $frame = $buttonframe -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -padx=>0);




  ## frame with options
  $frame = $outerframe -> LabFrame(-label=>'Options',
				   -foreground=>$config{colors}{activehighlightcolor},
				   -labelside=>'acrosstop',)
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -padx=>2, -pady=>4, -anchor=>'s');

  $widget{lcf_linear} = $frame -> Checkbutton(-text=>'Add a linear term after e0',
					      -selectcolor=>$config{colors}{single},
					      -variable=>\$lcf_params{linear})
    -> pack(-side=>'top', -padx=>2, -anchor=>'w');
  $widget{lcf_nonneg} = $frame -> Checkbutton(-text=>'Weights between 0 & 1',
					      -selectcolor=>$config{colors}{single},
					      -variable=>\$lcf_params{nonneg})
    -> pack(-side=>'top', -padx=>2, -anchor=>'w');

  $widget{lcf_100} = $frame -> Checkbutton(-text=>'Force weights to sum to 1',
					   -selectcolor=>$config{colors}{single},
					   -variable=>\$lcf_params{100})
    -> pack(-side=>'top', -padx=>2, -anchor=>'w');
  $widget{lcf_e0all} = $frame -> Checkbutton(-text=>'All standards use same e0',
					     -selectcolor=>$config{colors}{single},
					     -variable=>\$lcf_params{e0all},
					     -command=>sub{
					       foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
						 if ($lcf_params{e0all}) {
						   $widget{"lcf_e0$i"} -> select;
						   $widget{"lcf_e0$i"} -> configure(-state=>'disabled');
						 } else {
						   $widget{"lcf_e0$i"} -> configure(-state=>'normal');
						 };
					       };
					     })
    -> pack(-side=>'top', -padx=>2, -anchor=>'w');

  $frame -> Button(-text=>'Use marked groups',
		   @button_list,
		   -borderwidth=>1,
		   -command=>[\&lcf_use_marked, \%lcf_params])
    -> pack(-side=>'top', -fill=>'x', -padx=>2, -anchor=>'w');

  my $ff = $frame -> Frame()
    -> pack(-side=>'top', -padx=>2, -anchor=>'w');
  $ff -> Label(-text=>"Add noise")
    -> pack(-side=>'left', -padx=>2);
  $widget{lcf_noise} = $ff -> Entry(-width           => 7,
				    -textvariable    => \$lcf_params{noise},
				    -validate        => 'none',
				    -validatecommand => [\&set_variable, 'lcf_noise']
				   )
    -> pack(-side=>'left');
  $ff -> Label(-text=>" to data")
    -> pack(-side=>'left', -padx=>2);

  $ff = $frame -> Frame()
    -> pack(-side=>'top', -padx=>2, -anchor=>'w');
  $ff -> Label(-text=>"Use at most")
    -> pack(-side=>'left', -padx=>2);
  $widget{lcf_maxstan} = $ff -> NumEntry(-orient => 'horizontal',
					    -minvalue => 2,
					    -maxvalue => $config{linearcombo}{maxspectra},
					    -textvariable => \$lcf_params{maxstan},
					    -width=>3)
    -> pack(-side=>'left');
  $ff -> Label(-text=>" standards")
    -> pack(-side=>'left', -padx=>2);

  $widget{lcf_maxfit} = $frame -> Label(-font=>$config{fonts}{smbold},
					-foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -padx=>2, -anchor=>'center', -fill=>'x');




  ## frame containing the grid of widgets for selecting the
  ## standards spectra
  $frame = $st -> Scrolled('HList',
			   -scrollbars	=> 'oe',
			   -header	=> 1,
			   -columns	=> 6,
			   -borderwidth	=> 0,
			   -relief	=> 'flat',
			   -highlightcolor => $config{colors}{background},)
    -> pack(-side=>'top', -fill =>'both', -padx=>4, -pady=>4);
  BindMouseWheel($frame);
  #($frame->children)[2] -> configure(-highlightcolor=>$config{colors}{background});
  #foreach (($frame->children)[2]->configure) {no warnings; no strict;  print join(" ", @$_), $/};
  $frame -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));

  my $style = $frame -> ItemStyle('text',
				  -font=>$config{fonts}{small},
				  -anchor=>'w',
				  -foreground=>$config{colors}{activehighlightcolor});
  $frame -> headerCreate(0,
			 -text=>" ",
			 -style=>$style,
			 -headerbackground=>$config{colors}{background},
			 -borderwidth	   => 1,);
  $frame -> headerCreate(1,
			 -text=>"Standards",
			 -style=>$style,
			 -headerbackground=>$config{colors}{background},
			 -borderwidth	   => 1,);
  $frame -> headerCreate(2,
			 -text=>"weight",
			 -style=>$style,
			 -headerbackground=>$config{colors}{background},
			 -borderwidth	   => 1,);
  $frame -> headerCreate(3,
			 -text=>"e0",
			 -style=>$style,
			 -headerbackground=>$config{colors}{background},
			 -borderwidth	   => 1,);
  $frame -> headerCreate(4,
			 -text=>"fit?",
			 -style=>$style,
			 -headerbackground=>$config{colors}{background},
			 -borderwidth	   => 1,);
  $frame -> headerCreate(5,
			 -text=>"req.",
			 -style=>$style,
			 -headerbackground=>$config{colors}{background},
			 -borderwidth	   => 1,);



  $lcf_params{req} = $groups{$current}->{"lcf_req"} || q{};
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    $lcf_params{"standard$i"}     = $groups{$current}->{"lcf_standard$i"}     || 'None';
    $lcf_params{"e0$i"}           = $groups{$current}->{"lcf_e0$i"}           || $config{linearcombo}{fite0};
    $lcf_params{"e0val$i"}        = $groups{$current}->{"lcf_e0val$i"}        || 0;
    $lcf_params{"value$i"}        = $groups{$current}->{"lcf_value$i"}        || 0;


    $frame -> add($i);
    $frame -> itemCreate($i, 0, -itemtype=>'text',   -text=>$i, -style=>$style);
    $widget{"lcf_standard_list$i"} = $frame -> BrowseEntry(-variable => \$lcf_params{"standard_lab$i"},
							   @browseentry_list,
							   -width=>18,
							   -browsecmd => sub {
							     my $text = $_[1];
							     my $this = $1 if ($text =~ /^(\d+):/);
							     Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless ($this or ($this eq '0'));
							     #$this -= 1;
							     $lcf_params{"standard$i"}=$lcf_params{keys}->[$this];
							     $groups{$current} -> MAKE("lcf_standard$i"     => $lcf_params{keys}->[$this],
										       "lcf_standard_lab$i" => $lcf_params{"standard_lab$i"});
							     if ($this == 0) { # select None
							       $lcf_params{"standard$i"}     = "None";
							       $lcf_params{"standard_lab$i"} = "0: None";
							       $lcf_params{"value$i"}	     = 0;
							       $lcf_params{"e0$i"}	     = 0;
							       $lcf_params{"e0val$i"}	     = 0;
							       $lcf_params{"delta_value$i"}  = 0;
							       $lcf_params{"delta_e0val$i"}  = 0;
							       $groups{$current} -> MAKE("lcf_value$i"	     => 0,
											 "lcf_e0$i"	     => 0,
											 "lcf_e0val$i"	     => 0,
											 "lcf_delta_value$i" => 0,
											 "lcf_delta_e0val$i" => 0,
											);
							     };
							     &lcf_initialize(\%lcf_params, 2);
							   });
    $widget{"lcf_standard_list$i"} -> insert("end", "0: None");
    my $j = 1;
    foreach my $s (@keys) {
      next if ($s eq 'None');
      $groups{$s}->MAKE(lcf_menu_label => "$j: $groups{$s}->{label}");
      $widget{"lcf_standard_list$i"} -> insert("end", "$j: $groups{$s}->{label}");
      ++$j;
    };
    ## make sure menu labels are up to date
    my $label = "";
    ($label = $groups{$groups{$current}->{"lcf_standard$i"}}->{lcf_menu_label})
      if (exists $groups{$current}->{"lcf_standard$i"});
    $lcf_params{"standard_lab$i"} = $label || '0: None';




    $frame -> itemCreate($i, 1, -itemtype=>'window', -widget=>$widget{"lcf_standard_list$i"});
    my $en = $frame -> Entry(-width=>6,
 			     -textvariable=>\$lcf_params{"value$i"});
    $frame -> itemCreate($i, 2, -itemtype=>'window', -widget=>$en);
    $widget{"lcf_e0val$i"} = $frame -> Entry(-width=>6,
 					     #-state=>($lcf_params{"e0$i"}) ? 'normal' : 'disabled',
 					     -textvariable=>\$lcf_params{"e0val$i"});
    $frame -> itemCreate($i, 3, -itemtype=>'window', -widget=>$widget{"lcf_e0val$i"});
    $widget{"lcf_e0$i"} = $frame -> Checkbutton(-variable=>\$lcf_params{"e0$i"},
						-selectcolor=>$config{colors}{single},
						#-command=>sub{$widget{"lcf_e0val$i"}->configure(-state=>($lcf_params{"e0$i"})?'normal':'disabled')},
					       );
    $frame -> itemCreate($i, 4, -itemtype=>'window', -widget=>$widget{"lcf_e0$i"});
    $widget{"lcf_req$i"} = $frame -> Radiobutton(-variable=>\$lcf_params{req},
						 -value=>$i,
						 -selectcolor=>$config{colors}{single},
						 #-command=>sub{$widget{"lcf_e0val$i"}->configure(-state=>($lcf_params{"e0$i"})?'normal':'disabled')},
					       );
    $frame -> itemCreate($i, 5, -itemtype=>'window', -widget=>$widget{"lcf_req$i"});
  };






  ## a place to write information after the fit is finished
  $frame = $re -> Frame()
    -> pack(-side=>'top', -fill=>'both', -padx=>4, -expand=>1);

  $widget{lcf_text} = $frame -> Scrolled("ROText", -scrollbars=>'osoe',
					 -wrap=>'none',
					 -height=>1,
					 -width=>40,
					 -font=>$config{fonts}{fixed})
    -> pack(-fill=>'both', -expand=>1);
  disable_mouse3($widget{lcf_text}->Subwidget('rotext'));
  $widget{lcf_text} -> Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
							  ($is_windows) ? () : (-width=>8));
  $widget{lcf_text} -> Subwidget("yscrollbar")->configure(-background=>$config{colors}{background},
							  ($is_windows) ? () : (-width=>8));
  $widget{lcf_text} -> tagConfigure("text", -font=>$config{fonts}{fixedsm});
  my $smbold = $config{fonts}{smbold};
  my $red = $config{colors}{single};
  $widget{lcf_text} -> tagConfigure('error',
				    -lmargin1   => 4,
				    -font	=> $smbold,
				    -foreground	=> $red,
				    -background	=> 'white');

  $frame = $buttonframe -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -padx=>0);





  ## table for selecting a fit from the combinatorial fits
  $widget{lcf_combo_group} = $co -> Label(-foreground=>$config{colors}{activehighlightcolor},
					  -font=>$config{fonts}{smbold})
    -> pack(-side=>'top', -fill=>'x');
  $widget{lcf_select_table} = $co -> Scrolled("HList",
					      -columns    => 3,
					      -header     => 1,
					      -height     => 1,
					      -scrollbars => 'osoe',
					      -background => $config{colors}{background},
					      -selectbackground=> $config{colors}{current},
					     )
    -> pack(-side=>'top', -fill=>'both', -expand=>1);
  BindMouseWheel($widget{lcf_select_table});
  $widget{lcf_select_table} -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $widget{lcf_select_table} -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $widget{lcf_select_table}->bind('<ButtonPress-3>',\&lcf_post_menu);

  my $header_style = $widget{lcf_select_table} -> ItemStyle('text',
							    -font=>$config{fonts}{small},
							    -anchor=>'w',
							    -foreground=>$config{colors}{activehighlightcolor});
  $widget{lcf_select_table} -> headerCreate(0,
					    -text=>"Standards",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);
  $widget{lcf_select_table} -> headerCreate(1,
					    -text=>"R-factor",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);
  $widget{lcf_select_table} -> headerCreate(2,
					    -text=>"Reduced chi-square",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);

  ## table for displaying the results from a selected fit
  my $lf = $co -> LabFrame(-label      => 'Results for the selected fit',
			   -foreground => $config{colors}{activehighlightcolor},
			   -labelside  => 'acrosstop')
    -> pack(-fill=>'both', -expand=>1);

  $widget{lcf_result_table} = $lf -> Scrolled("HList",
					      -columns		=> 4,
					      -header		=> 1,
					      -height           => 4,
					      -scrollbars	=> 'osoe',
					      -background	=> $config{colors}{background},
					      -selectbackground => $config{colors}{background},
					     )
    -> pack(-side=>'top', -fill=>'both', -expand=>1);
  BindMouseWheel($widget{lcf_result_table});
  $widget{lcf_result_table} -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $widget{lcf_result_table} -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background},
		 ($is_windows) ? () : (-width=>8));
  $header_style = $widget{lcf_result_table} -> ItemStyle('text',
							 -font=>$config{fonts}{small},
							 -anchor=>'w',
							 -foreground=>$config{colors}{activehighlightcolor});
  $widget{lcf_result_table} -> headerCreate(0,
					    -text=>"#",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);
  $widget{lcf_result_table} -> headerCreate(1,
					    -text=>"Standard",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);
  $widget{lcf_result_table} -> headerCreate(2,
					    -text=>"Weight",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);
  $widget{lcf_result_table} -> headerCreate(3,
					    -text=>"E0",
					    -style=>$header_style,
					    -headerbackground=>$config{colors}{background},
					    -borderwidth	   => 1,);

  ##   $frame = $co -> Frame() -> pack(-fill=>'both', -side=>'bottom');
  ##   $frame -> Button(-text=>'Make groups of all fits',
  ## 		   @button_list,
  ## 		   -width=>1,
  ## 		   -command=>sub{Echo("Nothin' yet.")})
  ##     -> pack(-side=>'left', -fill=>'x', -expand=>1);
  $lf -> Button(-text=>'Write CSV report for all fits',
		@button_list,
		-width=>1,
		-command=>\&lcf_csv_report)
    -> pack(-side=>'left', -fill=>'x', -expand=>1);


  ## and finally....
  &lcf_initialize(\%lcf_params, 1);
  $top -> Busy;
  $groups{$current}->{lcf_fitspace} ||= 'e';
  $groups{$current}->{lcf_fitmin}   ||= ($groups{$current}->{lcf_fitspace} eq 'k') ? $config{linearcombo}{fitmin_k} : $config{linearcombo}{fitmin};
  $groups{$current}->{lcf_fitmax}   ||= ($groups{$current}->{lcf_fitspace} eq 'k') ? $config{linearcombo}{fitmax_k} : $config{linearcombo}{fitmax};
  ## plot the current group
  if ($lcf_params{fitspace} =~ '[de]') {
    $lcf_params{fitmin} = ($groups{$current}->{lcf_fitspace} =~ '[de]') ? $groups{$current}->{lcf_fitmin} : $config{linearcombo}{fitmin};
    $lcf_params{fitmax} = ($groups{$current}->{lcf_fitspace} =~ '[de]') ? $groups{$current}->{lcf_fitmax} : $config{linearcombo}{fitmax};
    lcf_quickplot_e(\%lcf_params);
  } else {
    $lcf_params{fitmin} = ($groups{$current}->{lcf_fitspace} eq 'k') ? $groups{$current}->{lcf_fitmin} : $config{linearcombo}{fitmin_k};
    $lcf_params{fitmax} = ($groups{$current}->{lcf_fitspace} eq 'k') ? $groups{$current}->{lcf_fitmax} : $config{linearcombo}{fitmax_k};
    lcf_quickplot_k(\%lcf_params);
    $widget{lcf_operations} -> entryconfigure(7, -state=>'normal', -style=>$lcf_params{normal_style});
  };
  if (exists $lcf_data{$current}) {
    my @list = $lcf_data{$current}{results}->[0];
    $lcf_params{rfact}  = $list[1];
    $lcf_params{chisqr} = $list[2];
    $lcf_params{chinu}  = $list[3];
    $lcf_params{nvarys} = $list[4];
    $lcf_params{ndata}  = $list[5];
    lcf_display();
  };
  if (exists $groups{$current}->{lcf_fit} and $groups{$current}->{lcf_fit}) {
    lcf_results(\%lcf_params);
    $widget{lcf_operations} -> entryconfigure(4, -state=>'normal', -style=>$$hash_pointer{normal_style});
  };
  &lcf_initialize(\%lcf_params, 1);

  $widget{lcf_fitmin} -> insert(0, $$hash_pointer{fitmin});
  $widget{lcf_fitmin} -> configure(-validate=>"key");
  $widget{lcf_fitmax} -> insert(0, $$hash_pointer{fitmax});
  $widget{lcf_fitmax} -> configure(-validate=>"key");
  $widget{lcf_noise}  -> configure(-validate=>"key");

  $top -> Unbusy;
  $top -> update;

};

sub lcf_set_variable {
  my ($k, $entry, $prop) = (shift, shift, shift);
  ($entry =~ /^\s*$/) and ($entry = 0);	# error checking ...
  ($entry =~ /^\s*-$/) and return 1;	# error checking ...
  ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
  my $param = substr($k,4);
  $$hash_pointer{$param} = $entry;
  $groups{$current} -> MAKE($k=>$entry);
  if ($param =~ /fitm(ax|in)/) {
    my $kk = ($$hash_pointer{fitspace} eq 'k') ? $param."_k" : $param."_e";
    $$hash_pointer{$kk} = $entry;
    $groups{$current} -> MAKE("lcf_$kk"=>$entry);
  };
  project_state(0);
  return 1;
};

sub lcf_multiplexer {
  my $lcf_params_ref = $_[0];
  my $pick = $widget{lcf_operations} -> selectionGet;
  ($pick = $pick->[0]) if (ref($pick) =~ /ARRAY/); # Tk 800 returns a scalar
                                                   # Tk 804 returns an array ref
 SWITCH: {
    lcf_fit($lcf_params_ref, 1),        last SWITCH if ($pick == 1);
    lcf_combinatorics($lcf_params_ref), last SWITCH if ($pick == 2);
    lcf_marked($lcf_params_ref),        last SWITCH if ($pick == 3);
    lcf_report(),                       last SWITCH if ($pick == 4);
    lcf_save_marked_report(),           last SWITCH if ($pick == 5);
    lcf_plot($lcf_params_ref),          last SWITCH if ($pick == 6);
    lcf_plot_r($lcf_params_ref),        last SWITCH if ($pick == 7);
    lcf_group($lcf_params_ref, 'fit'),  last SWITCH if ($pick == 8);
    lcf_group($lcf_params_ref, 'diff'), last SWITCH if ($pick == 9);
    lcf_constrain("all"),               last SWITCH if ($pick == 10);
    lcf_constrain("marked"),            last SWITCH if ($pick == 11);
    lcf_reset($lcf_params_ref, 0),      last SWITCH if ($pick == 12);
  };
  $widget{lcf_operations} -> selectionClear;
  $widget{lcf_operations} -> anchorClear;
};




sub lcf_quickplot {
  my $rlp = $_[0];
  if ($$rlp{fitspace} eq 'k') {
    $$rlp{fitmin_k} = $$rlp{fitmin};
    $$rlp{fitmax_k} = $$rlp{fitmax};
  } else {
    $$rlp{fitmin_e} = $$rlp{fitmin};
    $$rlp{fitmax_e} = $$rlp{fitmax};
  };
  lcf_quickplot_k($rlp), return if ($$rlp{fitspace} eq 'k');
  lcf_quickplot_e($rlp);
};


sub lcf_quickplot_e {
  my $rlp = $_[0];
  Error("\"$groups{$current}->{label}\" cannot be plotted in energy."), return if ($groups{$current}->{is_chi} or
										   $groups{$current}->{is_rsp} or
										   $groups{$current}->{is_qsp});
  my $how = ($$rlp{fitspace} eq 'e') ? 'emn' : 'emnd';
  $groups{$current}->plotE($how, $dmode, \%plot_features, \@indicator);
  my ($emin, $emax) = ($$rlp{enot}+$$rlp{fitmin}, $$rlp{enot}+$$rlp{fitmax});

  my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
  my $sets = "set(l___cf.x = $current.energy+$groups{$current}->{bkg_eshift},\n";
  if ($$rlp{fitspace} eq 'd') {
    $sets .= "    l___cf.y = deriv($current.norm)/deriv($current.energy)+$groups{$current}->{plot_yoffset})";
  } else {
    $sets .= "    l___cf.y = $current.$suff+$groups{$current}->{plot_yoffset})";
  };
  $groups{$current}->dispose($sets, $dmode);
  my @x = Ifeffit::get_array("l___cf.x");
  my @y = Ifeffit::get_array("l___cf.y");
  my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$current}->{bkg_e0});

  $groups{$current}->plot_vertical_line($emin, $ymin, $ymax, $dmode, "fit range", 0);
  $groups{$current}->plot_vertical_line($emax, $ymin, $ymax, $dmode, "", 0);
  $last_plot='e';
  $plotsel -> raise('e');
};
sub lcf_quickplot_k {
  my $rlp = $_[0];
  Error("\"$groups{$current}->{label}\" cannot be plotted in k."), return if ($groups{$current}->{is_xanes} or
									      $groups{$current}->{is_rsp}   or
									      $groups{$current}->{is_qsp});
  $groups{$current}->plotk('kw', $dmode, \%plot_features, \@indicator);
  my ($kmin, $kmax) = ($$rlp{fitmin}, $$rlp{fitmax});
  ##my ($kw, $group) = ($groups{$current}->{fft_kw}, $groups{$current}->{group});
  my ($kw, $group, $yoff) = ($plot_features{kw}, $groups{$current}->{group}, $groups{$current}->{plot_yoffset});
  my @x = Ifeffit::get_array("$group.k");
  $groups{$current}->dispose("set(l___cf.kw = $group.chi*$group.k^$kw)", $dmode);
  my @y = Ifeffit::get_array("l___cf.kw");
  my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'k', 0);
  $ymin = $ymin*1.05 + $yoff;
  $ymax = $ymax*1.05 + $yoff;
  $groups{$current}->plot_vertical_line($kmin, $ymin, $ymax, $dmode, "fit range", 0);
  $groups{$current}->plot_vertical_line($kmax, $ymin, $ymax, $dmode, "", 0);
  $last_plot='k';
  $plotsel -> raise('k');
};


## need to verify that the current group is not one of the standards
## selected in the standards grid.  also need to count the number of
## standards for the sake of the initial guesses for the weights
sub lcf_initialize {
  my ($rlp, $reset) = @_;
  my $n = 0;
  my $unknown_stan = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    $$rlp{"delta_value$i"} = 0;
    next unless exists($$rlp{"standard$i"});
    ++$n if ($$rlp{"standard$i"} ne 'None');
    ++$unknown_stan if ($$rlp{"standard$i"} eq $current);
  };
  if ($reset == 1) {
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      if (exists $groups{$current}->{"lcf_value$i"}) {
	$$rlp{"value$i"} = $groups{$current}->{"lcf_value$i"};
      } else {
	$$rlp{"value$i"} = ($$rlp{"standard$i"} eq 'None') ? 0 : sprintf("%.3f", 1/$n);
      };
    };
  } elsif ($reset == 2) {
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      $$rlp{"value$i"} = ($$rlp{"standard$i"} eq 'None') ? 0 : sprintf("%.3f", 1/$n);
    };
  };
  my $state = ($unknown_stan) ? 'disabled' : 'normal';
  my $style = ($unknown_stan) ? $$rlp{disabled_style} : $$rlp{normal_style};
  $widget{lcf_operations} -> entryconfigure(1, -state=>$state,     -style=>$style);
  $widget{lcf_operations} -> entryconfigure(3, -state=>$state,     -style=>$style);
  my $nn = ($$rlp{fitspace} eq 'k') ? 1 : 2;
  $widget{lcf_operations} -> entryconfigure(1, -state=>'disabled', -style=>$$rlp{disabled_style}) unless ($n>=$nn);
  $widget{lcf_operations} -> entryconfigure(2, -state=>$state,     -style=>$style);
  $widget{lcf_operations} -> entryconfigure(2, -state=>'disabled', -style=>$$rlp{disabled_style}) unless ($n>=3);
  $widget{lcf_operations} -> entryconfigure(3, -state=>'disabled', -style=>$$rlp{disabled_style}) unless ($n>=$nn);
  $state = (exists $groups{$current}->{lcf_fit} and $groups{$current}->{lcf_fit}) ? 'normal' : 'disabled';
  $style = (exists $groups{$current}->{lcf_fit} and $groups{$current}->{lcf_fit}) ? $$rlp{normal_style} : $$rlp{disabled_style};
  $widget{lcf_operations} -> entryconfigure(4, -state=>$state,     -style=>$style);
  $widget{lcf_operations} -> entryconfigure(5, -state=>'normal',   -style=>$$rlp{normal_style}) if (-e $groups{"Default Parameters"}->find('athena', 'temp_lcf'));
  $state = ($n) ? 'normal' : 'disabled';
  $style = ($n) ? $$rlp{normal_style} : $$rlp{disabled_style};
  $widget{lcf_operations} -> entryconfigure(6, -state=>$state,     -style=>$style);
  $widget{lcf_operations} -> entryconfigure(8, -state=>'disabled', -style=>$$rlp{disabled_style});
  $widget{lcf_operations} -> entryconfigure(9, -state=>'disabled', -style=>$$rlp{disabled_style});

  $widget{lcf_maxstan} -> configure(-state=>($unknown_stan) ? 'disabled' : 'normal');
  $widget{lcf_maxstan} -> configure(-state=>'disabled') unless ($n>=3);
  $widget{lcf_linear}  -> configure(-state=>'normal');
  $widget{lcf_e0all}   -> configure(-state=>'normal');
  if ($$rlp{fitspace} eq 'k') {
    $widget{lcf_linear} -> configure(-state=>'disabled');
    $widget{lcf_e0all}  -> configure(-state=>'disabled');
  } elsif ($$rlp{fitspace} eq 'd') {
    $widget{lcf_linear} -> configure(-state=>'disabled');
  };
};




## this multiplexes between the norm(E) and chi(k) fits
sub lcf_fit {
  my $rlp = $_[0];
  $groups{$current} -> dispose("set &status = 0\n", $dmode);
  ## need to clean up error bars from the last fit.  this should be
  ## innocuous if those scalars do not exist in Ifeffit
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    $groups{$current}->MAKE("lcf_delta_e0val$i"  => 0,
			    "lcf_delta_value$i"  => 0,
			   );
    $groups{$current} -> dispose("erase delta_e$i delta_w$i delta_ww$i", $dmode);
  };
  $groups{$current} -> dispose("erase delta_yint delta_slope", $dmode);
  $$rlp{fit_status} = 0;
  if ($$rlp{fitspace} eq 'k') {
    $$rlp{fitmin_k} = $$rlp{fitmin};
    $$rlp{fitmax_k} = $$rlp{fitmax};
  } else {
    $$rlp{fitmin_e} = $$rlp{fitmin};
    $$rlp{fitmax_e} = $$rlp{fitmax};
  };
  $$rlp{fitting} = 1;
 SWITCH: {
    lcf_fit_k(@_), last SWITCH if ($$rlp{fitspace} eq 'k');
    lcf_fit_e(@_);
  };
  $$rlp{fitting} = 0;
};

sub lcf_marked {
  my $rlp = $_[0];
  my $start = $current;
  #foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
  #  $groups{$current} -> MAKE("lcf_standard$i"     => $$rlp{"standard$i"});
  #  next if ($$rlp{"standard$i"} eq 'None');
  #  $groups{$current} -> MAKE("lcf_standard_lab$i" => $$rlp{"standard_lab$i"},
  #			      "lcf_value$i"        => $$rlp{"value$i"},
  #			      "lcf_e0$i"           => $$rlp{"e0$i"},
  #			      "lcf_e0val$i"        => $$rlp{"e0val$i"},
  #			      );
  #};
  if ($config{linearcombo}{marked_query} eq 'set') {
    lcf_constrain("marked");
  } elsif ($config{linearcombo}{marked_query} eq 'skip') {
    1; ## do nothing
  } else {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "You are about to do linear combination fits on the marked groups.  Would you like to constrain the parameters of all marked groups to those of the current group?",
		     -title          => 'Athena: Constrain parameters for linear combination fit?',
		     -buttons        => ["Constrain", "Do not constrain", "Cancel fits"],
		     -default_button => 'Constrain');
    my $answer = $dialog->Show();
    return if ($answer eq "Cancel fits");
    lcf_constrain("marked") if ($answer eq "Constrain");
  };
  Echo("Fitting all marked groups ...");
  $top -> Busy;
  unlink($groups{"Default Parameters"}->find('athena', 'temp_lcf'))
    if (-e $groups{"Default Parameters"}->find('athena', 'temp_lcf'));
  my $n_fits = 0;
  tie my $timer, 'Time::Stopwatch';
  foreach my $g (&sorted_group_list) {
    next unless $marked{$g};
    my $is_ok = 1;
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      $is_ok = 0 if ($g eq $$rlp{"standard$i"});
    };
    next unless $is_ok;
    ++$n_fits;
    set_properties(0, $g, 0);
    lcf_fit($rlp);
  };
  my $elapsed = $timer;
  undef $timer;
  $elapsed = sprintf("%d fits in %.0f min, %.0f sec", $n_fits, $elapsed/60, $elapsed%60);
  lcf_marked_report();
  set_properties(0, $start,0);
  $widget{lcf_operations} -> entryconfigure(5, -state=>'normal', -style=>$$rlp{normal_style});
  Echo("Fitting all marked groups ... done!  ($elapsed)");
  $top -> Unbusy;
};

sub lcf_fit_e {
  my $rlp = $_[0];
  my $plot = $_[1];
  my $bg = $config{colors}{background};
  $widget{lcf_maxfit} -> configure(-foreground=>'black',
				   -background=>$bg,
				   -text=>"") unless $$rlp{doing_combinatorics};

  my $abort = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$rlp{"standard$i"} eq 'None');
    my $this = $$rlp{"standard$i"};
    ++$abort if $groups{$this}->{is_chi};
  };
  Error("Fit aborted!  One or more of your standards cannot be plotted in energy."), return if $abort;

  my $how = ($$rlp{fitspace} eq 'e') ? 'norm(E)' : 'deriv(E)';
  Echo("Linear combination fitting $groups{$current}->{label} in $how ... ");
  my $is_busy = grep (/Busy/, $top->bindtags);
  $top -> Busy unless $is_busy;
  my $group  = $groups{$current}->{group};
  my $eshift = $groups{$current}->{bkg_eshift};
  $groups{$current}->dispatch_bkg($dmode) if $groups{$current}->{update_bkg};
  my $command = "## performing linear combination fit in $how\nunguess\n";
  $command .= "erase \@group l___cf\n";
  my $define = "def l___cf.mix =";
  push @{ $$rlp{deflist} }, "l___cf.mix";
  $$rlp{filestring} = "linear combination in E of";
  my @weights;
  my @which;

  $groups{$current}->dispose($command, $dmode);
  $command = "";
  ## make the unknown data arrays
  lcf_arrays_e(1);

  ## make sure each standard is up-to-date with respect to
  ## normalization
  $$rlp{nstandards} = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$rlp{"standard$i"} eq 'None');
    ++$$rlp{nstandards};
    push @which, $i;
    my $this = $$rlp{"standard$i"};
    $groups{$this}->dispatch_bkg($dmode) if $groups{$this}->{update_bkg};
    $$rlp{filestring} .= " " . $$rlp{"standard_lab$i"};
  };
  ## the last standard needs to be handled slightly differently
  my $last = pop @which;

  ## interpolate each standard onto the grid of the unknown, guess a
  ## weight and (if requested) an e0 shift.  make sure to use the
  ## flattened spectrum if appropriate
  foreach my $j (@which) {
    my $this = $$rlp{"standard$j"};
    my $esh  = sprintf("%.3f",$groups{$this}->{bkg_eshift});
    my $suff = ($groups{$this}->{bkg_flatten}) ? 'flat' : 'norm';
    ($suff = 'norm') if ($$rlp{fitspace} eq 'd');
    $command .= "# $this is $groups{$this}->{label}\n";
    if ($$rlp{e0all}) {
      if ($j == $which[0]) {
	$command .= "guess e$j = " . $$rlp{"e0val$j"} . "\n";
      } else {
	$command .= "def e$j = e$which[0]\n";
	push @{ $$rlp{deflist} }, "e$j";
      };
    } else {
      if ($$rlp{"e0$j"}) {
	$command .= "guess e$j = " . $$rlp{"e0val$j"} . "\n";
      } else {
	$command .= "set e$j = " .$$rlp{"e0val$j"} . "\n";
      };
    };
    my $function = ($$rlp{fitspace} eq 'd') ? "deriv($this.$suff)/deriv($this.energy)" : "$this.$suff";
    if ($$rlp{nonneg}) {
      $command .= "guess ww$j = " . $$rlp{"value$j"} . "\n";
      $command .= "def w$j = max(0,min(ww$j,1))\n";
      push @{ $$rlp{deflist} }, "w$j";
      $command .= "def l___cf.$j = abs(w$j)*splint($this.energy+e$j+$esh, $function, l___cf.energy)\n";
      push @{ $$rlp{deflist} }, "l___cf.$j";
    } else {
      $command .= "guess w$j = " . $$rlp{"value$j"} . "\n";
      $command .= "def l___cf.$j = w$j*splint($this.energy+e$j+$esh, $function, l___cf.energy)\n";
      push @{ $$rlp{deflist} }, "l___cf.$j";
    };
    $define  .= " l___cf.$j +";
    push @weights, "w$j";
  };

  ## do the same for the last spectrum, except def its weight to be
  ## one minus the sum of all the rest of the weights
  my $this = $$rlp{"standard$last"};
  my $esh  = sprintf("%.3f",$groups{$this}->{bkg_eshift});
  my $suff = ($groups{$this}->{bkg_flatten}) ? 'flat' : 'norm';
  ($suff = 'norm') if ($$rlp{fitspace} eq 'd');
  my @www = ($$rlp{nonneg}) ? map { "abs(".$_.")" } @weights : @weights;
  $command .= "# $this is $groups{$this}->{label}\n";
  if ($$rlp{100}) {
    $command .= "def w$last = max(0, 1 - (" . join("+", @weights) . "))\n";
    push @{ $$rlp{deflist} }, "w$last";
  } else {
    if ($$rlp{nonneg}) {
      $command .= "guess ww$last = " . $$rlp{"value$last"} . "\n";
      $command .= "def w$last = max(0,min(ww$last,1))\n";
      push @{ $$rlp{deflist} }, "w$last";
    } else {
      $command .= "guess w$last = " . $$rlp{"value$last"} . "\n";
    };
  };
  push @weights, "w$last";
  if ($$rlp{e0all}) {
    $command .= "def e$last = e$which[0]\n";
    push @{ $$rlp{deflist} }, "e$last";
  } elsif ($$rlp{"e0$last"}) {
    $command .= "guess e$last = " . $$rlp{"e0val$last"} ."\n";
  } else {
    $$rlp{"e0val$last"} ||= 0;
    $command .= "set e$last = " . $$rlp{"e0val$last"} ."\n";
  };
  my $function = ($$rlp{fitspace} eq 'd') ? "deriv($this.$suff)/deriv($this.energy)" : "$this.$suff";
  $command .= "def l___cf.$last = w$last*splint($this.energy+e$last+$esh, $function, l___cf.energy)\n";
  push @{ $$rlp{deflist} }, "l___cf.$last";
  $define  .= " l___cf.$last";

  ## add a line to the fitting function, if requested.  the line
  ## should only be applied after e0, so use a step function
  if (($$rlp{fitspace} eq 'e') and $$rlp{linear}) {
    $command .= "step l___cf.energy $groups{$current}->{bkg_eshift} $groups{$current}->{bkg_e0} l___cf.theta\n";
    #$command .= "step $group.energy $$rlp{fitmin} $group.theta\n";
    $command .= "guess slope=0\nguess yint=0\n";
    $define .= " + l___cf.theta*(yint + slope*l___cf.energy)";
  };
  $define  .= "\n";
  $command .= $define;

  ## def the residual array and minimize
  my ($emin, $emax) = ($$rlp{enot}+$$rlp{fitmin},
		       $$rlp{enot}+$$rlp{fitmax});
  $command .= "def l___cf.resid = l___cf.mix - l___cf.data\n";
  push @{ $$rlp{deflist} }, "l___cf.resid";
  $command .= "minimize(l___cf.resid, x=l___cf.energy, xmin=$emin, xmax=$emax)\n";
  $groups{$current}->dispose($command, $dmode);
#  if ($$rlp{nonneg}) {
#    foreach my $w (@weights) {
#      $groups{$current}->dispose("set $w = abs($w)\n", $dmode);
#    };
#  };

  ## store the fit results in the object
  $$rlp{fit_status} = lcf_values($rlp);
  $groups{$current}->MAKE(lcf_fit	  => 1,
			  lcf_fitspace	  => $$rlp{fitspace},
			  lcf_fit_status  => $$rlp{fit_status},
			  lcf_linear	  => $$rlp{linear},
			  lcf_nonneg	  => $$rlp{nonneg},
			  lcf_100	  => $$rlp{100},
			  lcf_e0all	  => $$rlp{e0all},
			  lcf_slope	  => $$rlp{slope},
			  lcf_yint	  => $$rlp{yint},
			  lcf_delta_slope => $$rlp{delta_slope},
			  lcf_delta_yint  => $$rlp{delta_yint},
			  lcf_fitmin	  => $$rlp{fitmin},
			  lcf_fitmax	  => $$rlp{fitmax},);
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    $groups{$current}->MAKE("lcf_standard$i"     => $$rlp{"standard$i"});
    next if ($$rlp{"standard$i"} eq 'None');
    $groups{$current}->MAKE("lcf_standard_lab$i" => $$rlp{"standard_lab$i"},
			    "lcf_e0$i"           => $$rlp{"e0$i"},
			    "lcf_e0val$i"        => $$rlp{"e0val$i"},
			    "lcf_delta_e0val$i"  => $$rlp{"delta_e0val$i"},
			    "lcf_value$i"        => $$rlp{"value$i"},
			    "lcf_delta_value$i"  => $$rlp{"delta_value$i"},
			   );
  };
  project_state(0);
  ## write a report to the text box
  lcf_statistics($rlp);
  lcf_results($rlp) if ($plot);

  my $red = $config{colors}{single};

  lcf_undef($rlp);
  ## plot the results
  lcf_plot_e($rlp) if $plot;

  ## and finish up
  $widget{lcf_operations} -> entryconfigure(4, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(8, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(9, -state=>'normal', -style=>$$rlp{normal_style});
  Echo("Linear combination fitting $groups{$current}->{label} in norm(E) ... done!");
  $top -> Unbusy unless $is_busy;
};


sub lcf_fit_k {
  my $rlp = $_[0];
  my $plot = $_[1];
  my $bg = $config{colors}{background};
  $widget{lcf_maxfit} -> configure(-foreground=>'black',
				   -background=>$bg,
				   -text=>"") unless $$rlp{doing_combinatorics};

  my $abort = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$rlp{"standard$i"} eq 'None');
    my $this = $$rlp{"standard$i"};
    ++$abort if $groups{$this}->{is_xanes};
  };
  Error("Fit aborted!  One or more of your standards cannot be plotted in k."), return if $abort;

  Echo("Linear combination fitting $groups{$current}->{label} in chi(k) ... ");
  $top -> Busy;
  my $group = $groups{$current}->{group};
  ##my $kw = $groups{$current}->{fft_kw};
  my $kw = $plot_features{kw};
  $$rlp{kw} = $kw;
  $groups{$current}->dispatch_bkg($dmode) if $groups{$current}->{update_bkg};
  my $command = "## performing linear combination fit in chi(k)\nunguess\n";
  $command .= "erase \@group l___cf\n";
  my $define = "def l___cf.mix =";
  push @{ $$rlp{deflist} }, "l___cf.mix";
  $$rlp{filestring} = "linear combination in k of";
  my @weights;
  my @which;
  $groups{$current}->dispose($command, $dmode);
  $command = "";
  lcf_arrays_k(1);

  ## make sure each standard is up-to-date with respect to
  ## normalization
  $$rlp{nstandards} = 0;
  my $smallest_kmax = 10000;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$rlp{"standard$i"} eq 'None');
    ++$$rlp{nstandards};
    push @which, $i;
    my $this = $$rlp{"standard$i"};
    $groups{$this}->dispatch_bkg($dmode) if $groups{$this}->{update_bkg};
    $$rlp{filestring} .= " " . $$rlp{"standard_lab$i"};

    ## need to make sure that the fitting range is not beyond any of the data
    my @y = Ifeffit::get_array($this . ".k");
    ($smallest_kmax = $y[$#y]) if ($y[$#y] < $smallest_kmax);
  };

  ## the last standard needs to be handled slightly differently
  my $last = ($$rlp{nstandards} > 1) ? pop @which : q{};

  ## guess a weight and (if requested) an e0 shift. add this to the mix
  foreach my $j (@which) {
    my $this = $$rlp{"standard$j"};
    $command .= "# $this is $groups{$this}->{label}\n";
    if ($$rlp{nonneg}) {
      $command .= "guess ww$j = " . $$rlp{"value$j"} . "\n";
      $command .= ($last) ? "def w$j = max(0,min(ww$j,1))\n" : "def w$j = ww$j\n";
    } else {
      $command .= "guess w$j = " . $$rlp{"value$j"} . "\n";
    };
    push @{ $$rlp{deflist} }, "w$j";
    $command .= "def l___cf.$j = w$j*$this.chi*$this.k^$kw\n";
    push @{ $$rlp{deflist} }, "l___cf.$j";
    $define  .= " l___cf.$j +";
    push @weights, "w$j";
  };

  if ($last) {
    ## do the same for the last spectrum, except def its weight to be
    ## one minus the sum of all the rest of the weights
    my $this = $$rlp{"standard$last"};
    my $suff = ($groups{$this}->{bkg_flatten}) ? 'flat' : 'norm';
    my @www = ($$rlp{nonneg}) ? map { "abs(".$_.")" } @weights : @weights;
    $command .= "# $this is $groups{$this}->{label}\n";
    if ($$rlp{100}) {
      $command .= "def w$last = max(0, 1 - (" . join("+", @weights) . "))\n";
    } else {
      $command .= "guess ww$last = " . $$rlp{"value$last"} . "\n";
      $command .= "def w$last = max(0,min(ww$last,1))\n";
    };
    $command .= "def l___cf.$last = w$last*$this.chi*$this.k^$kw\n";
    push @{ $$rlp{deflist} }, "l___cf.$last", "w$last";
    $define  .= " l___cf.$last";
  } else {
    $define =~ s/\+\s*$//;
  };

  $define  .= "\n";
  $command .= $define;

  ## def the residual array and minimize
  my ($kmin, $kmax) = ($$rlp{fitmin}, $$rlp{fitmax});
  ($kmax = $smallest_kmax - 0.01) if ($kmax > $smallest_kmax);
  $$rlp{fitmax} = $kmax;
  ##$command .= "def l___cf.resid = l___cf.mix - $group.chi*$group.k^$kw\n";
  $command .= "def l___cf.resid = l___cf.mix - l___cf.data\n";
  push @{ $$rlp{deflist} }, "l___cf.resid";
  $command .= "minimize(l___cf.resid, x=$group.k, xmin=$kmin, xmax=$kmax)\n";
  $groups{$current}->dispose($command, $dmode);
#  if ($$rlp{nonneg}) {
#    foreach my $w (@weights, "w$last") {
#      $groups{$current}->dispose("set $w = abs($w)\n", $dmode);
#    };
#  };

  ## store the fit results in the object
  $$rlp{fit_status} = lcf_values($rlp);
  $groups{$current}->MAKE(lcf_fit	 => 1,
			  lcf_fitspace	 => 'k',
			  lcf_fit_status => $$rlp{fit_status},
			  lcf_linear	 => $$rlp{linear},
			  lcf_nonneg	 => $$rlp{nonneg},
			  lcf_100	 => $$rlp{100},
			  lcf_e0all	 => $$rlp{e0all},
			  lcf_slope	 => $$rlp{slope},
			  lcf_yint	 => $$rlp{yint},
			  lcf_kw	 => $$rlp{kw},
			  lcf_fitmin	 => $$rlp{fitmin},
			  lcf_fitmax	 => $$rlp{fitmax},);
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    $groups{$current}->MAKE("lcf_standard$i"     => $$rlp{"standard$i"});
    next if ($$rlp{"standard$i"} eq 'None');
    $groups{$current}->MAKE("lcf_standard_lab$i" => $$rlp{"standard_lab$i"},
			    "lcf_value$i"        => $$rlp{"value$i"},
			    "lcf_delta_value$i"  => $$rlp{"delta_value$i"},
			   );
  };
  project_state(0);

  ## write a report to the text box
  lcf_statistics($rlp);
  lcf_results($rlp) if ($plot);
  my $last_error = 0;

  lcf_undef($rlp);
  lcf_plot_k($rlp) if ($plot);

  ## and finish up
  $widget{lcf_operations} -> entryconfigure(4, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(8, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(9, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(7, -state=>'normal', -style=>$$rlp{normal_style});
  Echo("Linear combination fitting $groups{$current}->{label} in chi(k) ... done!");
  $top -> Unbusy;
};


sub lcf_values {
  my $rlp = $_[0];
  my $last_error = 0;
  my $j = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$rlp{"standard$i"} eq 'None');
    ++$j;
    $$rlp{"value$i"} = sprintf("%.3f", Ifeffit::get_scalar("w$i"));
    my $thiserr;
    if ($$rlp{nstandards} == 1) {
      if ($$rlp{nonneg}) {
	$thiserr = Ifeffit::get_scalar("delta_ww".$$rlp{nstandards});
      } else {
	$thiserr = Ifeffit::get_scalar("delta_w".$$rlp{nstandards});
      };
    } elsif ($j eq $$rlp{nstandards}) {
      if ($$rlp{100}) {
	$thiserr = sqrt($last_error);
      } else {
	if ($$rlp{nonneg}) {
	  $thiserr = Ifeffit::get_scalar("delta_ww".$$rlp{nstandards});
	} else {
	  $thiserr = Ifeffit::get_scalar("delta_w".$$rlp{nstandards});
	};
      };
    } else {
      if ($$rlp{nonneg}) {
	$last_error += Ifeffit::get_scalar("delta_ww$i")**2;
	$thiserr = Ifeffit::get_scalar("delta_ww$i");
      } else {
	$last_error += Ifeffit::get_scalar("delta_w$i")**2;
	$thiserr = Ifeffit::get_scalar("delta_w$i");
      };
    };
    $$rlp{"delta_value$i"} = $thiserr;
  };

  unless ($$rlp{fitspace} eq 'k') {
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      next if ($$rlp{"standard$i"} eq 'None');
      $$rlp{"e0val$i"} = sprintf("%.3f", Ifeffit::get_scalar("e$i"));
      $$rlp{"delta_e0val$i"} = sprintf("%.3f", Ifeffit::get_scalar("delta_e$i"));
    };

    if ($$rlp{linear}) {
      $$rlp{slope}       = Ifeffit::get_scalar("slope");
      $$rlp{delta_slope} = Ifeffit::get_scalar("delta_slope");
      $$rlp{yint}        = Ifeffit::get_scalar("yint");
      $$rlp{delta_yint}  = Ifeffit::get_scalar("delta_yint");
    } else {
      $$rlp{slope} = 0;
      $$rlp{delta_slope} = 0;
      $$rlp{yint}  = 0;
      $$rlp{delta_yint}  = 0;
    };
  };


  return Ifeffit::get_scalar('&status');
};


sub lcf_undef {
  my $rlp = $_[0];
  $groups{$current}->dispose("## best not to leave defs lying around...", $dmode);
  foreach (@{ $$rlp{deflist} }) {
    $groups{$current}->dispose("set $_ = $_", $dmode);
  };
  $$rlp{deflist} = ();
};

sub lcf_plot {
  my $rlp = $_[0];
  if ($$rlp{fitspace} eq 'k') {
    $$rlp{fitmin_k} = $$rlp{fitmin};
    $$rlp{fitmax_k} = $$rlp{fitmax};
  } else {
    $$rlp{fitmin_e} = $$rlp{fitmin};
    $$rlp{fitmax_e} = $$rlp{fitmax};
  };
  lcf_plot_k($rlp), return if ($$rlp{fitspace} eq 'k');
  lcf_plot_e($rlp);
};

sub lcf_plot_e {
  my $rlp = $_[0];
  Error("\"$groups{$current}->{label}\" cannot be plotted in energy."),
    return if ($groups{$current}->{is_chi} or
	       $groups{$current}->{is_rsp} or
	       $groups{$current}->{is_qsp});
  my $how = ($$rlp{fitspace} eq 'e') ? 'norm(E)' : 'deriv(E)';
  Echo("Plotting $groups{$current}->{label} + linear combination as $how ... ");
  $top -> Busy;
  my $linear = (($$rlp{slope} != 0) or ($$rlp{yint} != 0));
  my $group = $groups{$current}->{group};
  my $yoff  = $groups{$current}->{plot_yoffset};
  $groups{$current}->dispose("## Plotting linear combination of spectra as $how\n", $dmode);
  #($command .= "step $group.energy $groups{$current}->{bkg_e0} $group.theta\n")
  #  if $linear;

  lcf_arrays_e();

  ## plot 'em up
  $how = ($$rlp{fitspace} eq 'e') ? 'emn' : 'emnd';
  $groups{$current}->plotE($how, $dmode, \%plot_features, \@indicator);
  #$groups{$current}->dispose($command, $dmode);
  my $color = $config{plot}{'c1'};
  my $c = 1;
  if ($$rlp{noise} > 0 ) {
    $groups{$current}->dispose("plot(l___cf.energy, \"l___cf.data+$yoff\", key=\"data+noise\", style=lines, color=$color)\n", $dmode);
    $color = $config{plot}{'c2'};
    ++$c;
  };
  $groups{$current}->dispose("plot(l___cf.energy, \"l___cf.mix+$yoff\", key=\"linear combo.\", style=lines, color=$color)\n", $dmode);
  if ($$rlp{difference}) {
    ++$c;
    my $color = $config{plot}{'c'.$c};
    my $key = 'difference';
    $groups{$current}->dispose("plot(l___cf.energy, \"l___cf.diff+$yoff\", key=\"$key\", style=lines, color=$color)\n", $dmode);
  };

  my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
  $groups{$current}->dispose("set l___cf.x = $current.energy+$groups{$current}->{bkg_eshift}", $dmode);
  if ($$rlp{fitspace} eq 'd') {
    $groups{$current}->dispose("set l___cf.y = deriv($current.norm)/deriv($current.energy)+$groups{$current}->{plot_yoffset}", $dmode);
  } else {
    $groups{$current}->dispose("set l___cf.y = $current.$suff+$groups{$current}->{plot_yoffset}", $dmode);
  };
  my @x = Ifeffit::get_array("l___cf.x");
  my @y = Ifeffit::get_array("l___cf.y");
  my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$current}->{bkg_e0});
  my $offset = 0;
  if ($$rlp{components}) {
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      next if ($$rlp{"standard$i"} eq 'None');
      ++$c;
      my $color = $config{plot}{'c'.$c};
      ($offset   = sprintf("%.4f", abs(($ymin-$yoff)*0.5*$c))) if ($$rlp{fitspace} eq 'd');
      my $key   = $groups{$$rlp{"standard$i"}}->{label};
      $groups{$current}->dispose("plot(l___cf.energy, \"l___cf.$i-$offset+$yoff\", key=\"$key\", style=lines, color=$color)\n", $dmode);
    };
  };

  my ($emin, $emax) = ($$rlp{enot}+$$rlp{fitmin},
		       $$rlp{enot}+$$rlp{fitmax});
  $groups{$current}->plot_vertical_line($emin, $ymin, $ymax, $dmode, "fit range", 0);
  $groups{$current}->plot_vertical_line($emax, $ymin, $ymax, $dmode, "", 0);
  $last_plot='e';
  Echo("Plotting $groups{$current}->{label} + linear combination as norm(E) ... done!");
  $top -> Unbusy;
};


## need to construct l___cf.mix anew...
sub lcf_plot_k {
  Error("\"$groups{$current}->{label}\" cannot be plotted in k."), return if ($groups{$current}->{is_xanes} or
									      $groups{$current}->{is_rsp}   or
									      $groups{$current}->{is_qsp});
  Echo("Plotting $groups{$current}->{label} + linear combination as chi(k) ... ");
  $groups{$current}->dispose("## Plotting linear combination of spectra as chi(k)\n", $dmode);
  my $rlp = $_[0];
  my $group = $groups{$current}->{group};
  my $yoff  = $groups{$current}->{plot_yoffset};
  my ($kmin, $kmax) = ($$rlp{fitmin}, $$rlp{fitmax});
  $groups{$current}->plotk('kw', $dmode, \%plot_features, \@indicator);
  lcf_arrays_k(0);

  my $color = $config{plot}{'c1'};
  my $c = 1;
  if ($$rlp{noise} > 0 ) {
    $groups{$current}->dispose("plot($group.k, \"l___cf.data+$yoff\", key=\"data+noise\", style=lines, color=$color)\n", $dmode);
    $color = $config{plot}{'c2'};
    ++$c;
  };

  $groups{$current}->dispose("plot($group.k, \"l___cf.mix+$yoff\", key=\"linear combo.\", style=lines, color=$color)\n", $dmode);
  my @x = Ifeffit::get_array("$group.k");
  ##$groups{$current}->dispose("set l___cf.y = $group.chi * $group.k**$groups{$current}->{fft_kw}");
  $groups{$current}->dispose("set l___cf.y = $group.chi * $group.k**$plot_features{kw}", $dmode);
  my @y = Ifeffit::get_array("l___cf.y");
  my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'k', 0);
  $ymin = $ymin*1.05 + $yoff;
  $ymax = $ymax*1.05 + $yoff;
  my $offset = 0;
  if ($$rlp{difference}) {
    ++$c;
    my $color = $config{plot}{'c'.$c};
    my $key = 'difference';
    $offset = sprintf("%.4f", abs(($ymin-$yoff)*0.5*$c));
    $groups{$current}->dispose("plot($group.k, \"l___cf.resid-$offset+$yoff\", key=\"$key\", style=lines, color=$color)\n", $dmode);
  };
  if ($$rlp{components}) {
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      next if ($$rlp{"standard$i"} eq 'None');
      ++$c;
      my $color = $config{plot}{'c'.$c};
      my $key = $groups{$$rlp{"standard$i"}}->{label};
      $offset = sprintf("%.4f", abs(($ymin-$yoff)*0.5*$c));
      $groups{$current}->dispose("plot($group.k, \"l___cf.$i-$offset+$yoff\", key=\"$key\", style=lines, color=$color)\n", $dmode);
    };
  };
  $ymin = ($offset) ? $yoff - abs(($ymin-$yoff)*0.6*$c) : $ymin;
  $groups{$current}->plot_vertical_line($kmin, $ymin, $ymax, $dmode, "fit range", 0);
  $groups{$current}->plot_vertical_line($kmax, $ymin, $ymax, $dmode, "", 0);
  $last_plot='k';
  Echo("Plotting $groups{$current}->{label} + linear combination as chi(k) ... done!");
};


sub lcf_plot_r {
  Echo("Plotting $groups{$current}->{label} + linear combination as |chi(R)| ... ");
  $groups{$current}->dispose("## Plotting linear combination of spectra as |chi(R)|\n", $dmode);
  my $rlp = $_[0];
  my $group = $groups{$current}->{group};
  my $yoff  = $groups{$current}->{plot_yoffset};
  my ($kmin, $kmax) = ($$rlp{fitmin}, $$rlp{fitmax});
  $groups{$current}->plotR('rm', $dmode, \%plot_features, \@indicator);
  lcf_arrays_k(0);
  my $command = "(l___cf.mix, ";
  $command   .= "k=$current.k, ",
  $command   .= "kweight=0, ";
  $command   .= "kmin=$groups{$current}->{fft_kmin}, ";
  $command   .= "kmax=$groups{$current}->{fft_kmax}, ";
  $command   .= "dk=$groups{$current}->{fft_dk}, ";
  $command   .= "kwindow=$groups{$current}->{fft_win}, ";
  $command   .= "group=l___cf, ";
  $command   .= "rmax_out=$Ifeffit::Group::rmax_out";
  if (lc($groups{$current}->{fft_pc}) eq 'on') {
    my $str = join(" ", lc($groups{$current}->{bkg_z}), lc($groups{$current}->{fft_edge}));
    ($command .= ", pc_edge=\"$str\", pc_caps=1");
  };
  $command   .= ")\n";
  $command    = wrap("fftf", "     ", $command);
  my $color   = $config{plot}{'c1'};
  $command   .= "plot(l___cf.r, \"l___cf.chir_mag+$yoff\", key=\"linear combo.\", style=lines, color=$color)\n";
  $groups{$current}->dispose($command, $dmode);
};


sub lcf_arrays_e {
  my $just_data = $_[0];
  my $group  = $groups{$current}->{group};
  my $eshift = $groups{$current}->{bkg_eshift};

  my $command .= "## Making arrays for fit in energy to $groups{$current}->{label}\n";

  ## find longest common energy range in the marked groups.
  ## interpolate over this range.  intrpolating just over the range of
  ## the first group might lead to extrapolation in other groups.
  my @ee = Ifeffit::get_array("$group.energy");
  my ($emin, $emax) = ($ee[0]+$eshift, $ee[-1]+$eshift);
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$hash_pointer{"standard$i"} eq 'None');
    my $this = $$hash_pointer{"standard$i"};
    my $esh  = sprintf("%.3f",$groups{$this}->{bkg_eshift});
    @ee = Ifeffit::get_array("$this.energy");
    my ($e1, $e2) = ($ee[0]+$esh, $ee[-1]+$esh);
    ($emin = $e1) if ($e1 > $emin);
    ($emax = $e2) if ($e2 < $emax);
  };

  my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
  ($suff = 'norm') if ($$hash_pointer{fitspace} eq 'd');
  my $function = ($$hash_pointer{fitspace} eq 'd') ? "deriv($group.$suff)/deriv($group.energy)" : "$group.$suff";
  if ($config{linearcombo}{energy} eq 'data') {
    $groups{$current}->dispose("set l___cf.eee = $group.energy+$eshift\n", $dmode);
    my @earray = Ifeffit::get_array("l___cf.eee");
    @earray = grep {($_ > $emin) and ($_ < $emax)} @earray;
    Ifeffit::put_array("l___cf.energy", \@earray);
    $command .= "set l___cf_npts = npts(l___cf.energy)\n";
    if ($$hash_pointer{noise} > 0) {
      $command .= "random(output=l___cf.noise, npts=l___cf_npts, dist=normal, sigma=$$hash_pointer{noise})\n"
	if $$hash_pointer{fitting}; # only regenerate noise for a new fit
      $command .= "set l___cf.data = splint(l___cf.eee, $function, l___cf.energy) + l___cf.noise\n";
    } else {
      $command .= "set l___cf.data = splint(l___cf.eee, $function, l___cf.energy)\n";
    };
  } else {
    my @en = Ifeffit::get_array("$group.energy");
    ##my ($emin, $emax) = ($en[0]+$eshift, $en[-1]+$eshift);
    $command .= "set l___cf.energy = range($emin, $emax, $config{linearcombo}{grid})\n";
    $command .= "set l___cf_npts = npts(l___cf.energy)\n";
    $command .= "set l___cf.eee = $group.energy+$eshift\n";
    if ($$hash_pointer{noise} > 0) {
      $command .= "random(output=l___cf.noise, npts=l___cf_npts, dist=normal, sigma=$$hash_pointer{noise})\n"
	if $$hash_pointer{fitting};
      $command .= "set l___cf.data = splint(l___cf.eee, $function, l___cf.energy) + l___cf.noise\n";
    } else {
      $command .= "set l___cf.data = splint(l___cf.eee, $function, l___cf.energy)\n";
    };
  };

  unless ($just_data) {
    $command .= "set l___cf.mix = zeros(l___cf_npts)\n";
    ## interpolate each standard onto the grid of the unknown, apply the
    ## appropriate weight and e0 shift
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      next if ($$hash_pointer{"standard$i"} eq 'None');
      my $w = $$hash_pointer{"value$i"};
      my $this = $$hash_pointer{"standard$i"};
      my $e = $$hash_pointer{"e0val$i"};
      my $esh  = sprintf("%.3f",$groups{$this}->{bkg_eshift});
      my $suff = ($groups{$this}->{bkg_flatten}) ? 'flat' : 'norm';
      ($suff = 'norm') if ($$hash_pointer{fitspace} eq 'd');
      $groups{$this}->dispatch_bkg($dmode) if $groups{$this}->{update_bkg};
      my $function = ($$hash_pointer{fitspace} eq 'd') ? "deriv($this.$suff)/deriv($this.energy)" : "$this.$suff";
      $command .= "set l___cf.$i = $w*splint($this.energy+$esh+$e, $function, l___cf.energy)\n";
      $command .= "set l___cf.mix = l___cf.mix + l___cf.$i\n";
    };
    ## add on a linear offset, if appropriate
    if ($$hash_pointer{linear}) {
      $command .= "set l___cf.line = l___cf.theta*($$hash_pointer{slope}*($$hash_pointer{yint} + l___cf.energy-$$hash_pointer{enot}))\n";
      $command .= "set l___cf.mix  = l___cf.mix + l___cf.line\n";
    };
    $command .= "set l___cf.diff = l___cf.data - l___cf.mix\n";
  };

  $groups{$current}->dispose($command, $dmode);
};

sub lcf_arrays_k {
  my $just_data = $_[0];
  my $group = $groups{$current}->{group};
  ##my $kw    = $groups{$current}->{fft_kw};
  my $kw    = $plot_features{kw};
  my $command .= "## Making arrays for fit in k to $groups{$current}->{label}\n";
  $command    .= "set l___cf_npts = npts($group.k)\n";
  if ($$hash_pointer{noise} > 0) {
    $command .= "random(output=l___cf.noise, npts=l___cf_npts, dist=normal, sigma=$$hash_pointer{noise})\n";
    my $function = "($group.chi+l___cf.noise)*$group.k^$kw";
    $command .= "set l___cf.data = $function + l___cf.noise\n";
  } else {
    my $function = "$group.chi*$group.k^$kw";
    $command .= "set l___cf.data = $function\n";
  };
  unless ($just_data) {
    $command   .= "set l___cf.mix = zeros(l___cf_npts)\n";
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      next if ($$hash_pointer{"standard$i"} eq 'None');
      my $this  = $$hash_pointer{"standard$i"};
      my $value = $$hash_pointer{'value'.$i};
      my $key = $groups{$$hash_pointer{"standard$i"}}->{label};
      $groups{$this} -> dispatch_bkg($dmode) if ($groups{$this}->{update_bkg});
      ##$command .= "set l___cf.$i = $value*$this.chi*$this.k**$groups{$current}->{fft_kw}\n";
      $command .= "set l___cf.$i = $value*$this.chi*$this.k**$plot_features{kw}\n";
      $command .= "set l___cf.mix = l___cf.mix + l___cf.$i\n";
      #$groups{$current}->dispose($command, $dmode);
    };
    $command .= "set l___cf.diff = l___cf.resid\n";
  };
  $groups{$current}->dispose($command, $dmode);
};

sub lcf_use_marked {
  my $rlp = $_[0];
  my $count = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    $$rlp{"standard$i"}     = 'None';
    $$rlp{"standard_lab$i"} = '0: None';
    $$rlp{"value$i"}        = 0;
    $$rlp{"delta_value$i"}  = 0;
    $$rlp{"e0val$i"}        = 0;
    $$rlp{"delta_e0val$i"}  = 0;
  };
 MG: foreach my $k (&sorted_group_list) {
    next MG unless $marked{$k};
    next if ($k eq $current);
    ## need to make sure that the record type is appropriate for this fit
    next MG if $groups{$k}->{is_rsp};
    next MG if $groups{$k}->{is_qsp};
    next MG if $groups{$k}->{not_data};
    if ($$rlp{fitspace} eq 'k') {
      next MG if $groups{$k}->{is_xanes};
    } else {
      next MG if $groups{$k}->{is_chi};
    };
    ++$count;
    next if ($count > $config{linearcombo}{maxspectra});
    $$rlp{"standard$count"}     = $k;
    $$rlp{"standard_lab$count"} = $groups{$k}->{lcf_menu_label};
    $groups{$current} -> MAKE("lcf_standard$count"     => $k,
			      "lcf_standard_lab$count" => $groups{$k}->{lcf_menu_label});
  };
  lcf_initialize($rlp, 2);
};

sub lcf_results {
  my $rlp = $_[0];
  my $bg = $config{colors}{background};
  $widget{lcf_maxfit} -> configure(-foreground=>'black',
				   -background=>$bg,
				   -text=>"") unless $$rlp{doing_combinatorics};
  ## deal with project files from older versions of Athena's LCF dialog
  map {$groups{$current}->{"lcf_$_"} ||= 0} (qw(sumsqr rfact chisqr chinu nvarys ndata kw));

  my $last_error = 0;
  my $how = "";
 SWITCH: {
    ($how = 'norm(E)'),  last SWITCH if ($groups{$current}->{lcf_fitspace} eq 'e');
    ($how = 'deriv(E)'), last SWITCH if ($groups{$current}->{lcf_fitspace} eq 'd');
    ($how = 'chi(k)'),   last SWITCH if ($groups{$current}->{lcf_fitspace} eq 'k');
  };
  my $report = sprintf("Fitting %s as $how from %.3f to %.3f\n", $groups{$current}->{label}, $groups{$current}->{lcf_fitmin}, $groups{$current}->{lcf_fitmax});
  $report   .= "   fit done use k-weight = $groups{$current}->{lcf_kw}\n" if ($groups{$current}->{lcf_fitspace} eq 'k');
  $report   .= "\n";

  my $variables = ($groups{$current}->{lcf_nvarys} > 1) ? 'variables' : 'variable';
  $report   .= "Fit included $groups{$current}->{lcf_ndata} data points and $groups{$current}->{lcf_nvarys} $variables\n";
  $report   .= sprintf("R-factor = %.6f\nchi-square = %.5f\nreduced chi-square = %.7f\n\n",
		       $groups{$current}->{lcf_rfact},
		       $groups{$current}->{lcf_chisqr},
		       $groups{$current}->{lcf_chinu}
		      );

  if ($groups{$current}->{lcf_sumsqr} == 1) {$report .= "Uh oh! something went wrong with the sum of squares...\n"};

  $report   .= "   group                weight\n";
  $report   .= "=======================================\n";
  my $is_neg = 0;
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next unless (exists $groups{$current}->{"lcf_standard$i"});
    next if ($groups{$current}->{"lcf_standard$i"} eq 'None');
    $groups{$current}->{"lcf_value$i"}       ||= 0;
    $groups{$current}->{"lcf_delta_value$i"} ||= 0;
    $report .= sprintf("  %-20s  %5.3f(%5.3f)\n",
		       $groups{$current}->{"lcf_standard_lab$i"},
		       $groups{$current}->{"lcf_value$i"},
		       $groups{$current}->{"lcf_delta_value$i"},);
    ++$is_neg if ($groups{$current}->{"lcf_value$i"} < 0 );
  };

  unless ($groups{$current}->{lcf_fitspace} eq 'k') {
    $report   .= "\n\n   group                e0 shift\n";
    $report   .= "=======================================\n";
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      next unless (exists $groups{$current}->{"lcf_standard$i"});
      next if ($groups{$current}->{"lcf_standard$i"} eq 'None');
      $groups{$current}->{"lcf_e0val$i"}       ||= 0;
      $groups{$current}->{"lcf_delta_e0val$i"} ||= 0;
      $report .= sprintf("  %-20s %6.3f(%6.3f)\n",
			 $groups{$current}->{"lcf_standard_lab$i"},
			 $groups{$current}->{"lcf_e0val$i"},
			 $groups{$current}->{"lcf_delta_e0val$i"},
			);
    };

    if ($groups{$current}->{lcf_linear}) {
      $report .= sprintf("\n\n with linear term %.3f(%.3f) + %.3g(%.3g) * (E-E0)\n",
			 $groups{$current}->{lcf_yint},
			 $groups{$current}->{lcf_delta_yint},
			 $groups{$current}->{lcf_slope},
			 $groups{$current}->{lcf_delta_slope},)
    };
  };
  $widget{lcf_text} -> delete('1.0', 'end');
  $widget{lcf_text} -> insert('end', $report, 'text');

  ## error handling

  my $red = $config{colors}{single};
  $groups{$current}->{lcf_fit_status} ||= 0;
  if ($groups{$current}->{lcf_fit_status} == 2) {	# error bars not calculated
    $widget{lcf_maxfit} -> configure(-foreground=>$red,
				     -background=>'white',
				     -text=>"Fit returned a warning!") unless $$rlp{doing_combinatorics};
    my $addendum = "
This fit flagged a warning -- probably that error bars
could not be calculated.  That is probably an indication
that one or more of your standards are innapropriate for
this fit.

";
    $widget{lcf_text} -> insert('end', $/);
    $widget{lcf_text} -> insert('end', $addendum, 'error');

  } elsif ($groups{$current}->{lcf_fit_status} > 2) { # something bad!
    $widget{lcf_maxfit} -> configure(-foreground=>$red,
				     -background=>'white',
				     -text=>"Fit returned an error!") unless $$rlp{doing_combinatorics};
    my $addendum = "
This fit flagged a error.  You will need to check the
Ifeffit buffer for details.  One possible cause is that
the standards are inappropriate for this fit and that
the maximum number of iterations in the fit was exceeded.

";
    $widget{lcf_text} -> insert('end', $/);
    $widget{lcf_text} -> insert('end', $addendum, 'error');
  };

  if ($groups{$current}->{lcf_100} and $groups{$current}->{lcf_nonneg} and $is_neg) {
    $widget{lcf_maxfit} -> configure(-foreground=>$red,
				     -background=>'white',
				     -text=>"Poorly constrained fit!") unless $$rlp{doing_combinatorics};
    my $addendum = "
This fit yielded a negative weight.  One or more
of your standards are innapropriate for this fit
and should be removed from the list.

";
    $widget{lcf_text} -> insert('end', $/);
    $widget{lcf_text} -> insert('end', $addendum, 'error');
  };

};

## prompt for a filename and write the report from the text box to
## that file
sub lcf_report {
  my $path = $current_data_dir || Cwd::cwd;
  my $f = $groups{$current}->{label} . ".lcf";
  $f =~ s/ /_/g;
  my $types = [['Linear combination fits', '.lcf'], ['All files', '*']];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$f,
				 -title => "Athena: Write linear combination fitting report");
  Echo("Not writing linear combination fit report"), return unless $file;

  open F, ">".$file;
  foreach (split "\n", $widget{lcf_text}->get('1.0', 'end')) {
    print F "# ", $_, $/;
  };
  print F "# ", "-" x 40, $/;
  my $x = ($$hash_pointer{fitspace} eq 'k') ? "k" : "energy";
  print F "# ", " $x     data      fit    residual";
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$hash_pointer{"standard$i"} eq 'None');
    my $label = $groups{$$hash_pointer{"standard$i"}}->{label};
    $label =~ s/\s+/_/g;
    print F "    ", $label;
  };
  print F $/;

  if ($$hash_pointer{fitspace} eq 'k') {
    lcf_arrays_k(0);
  } else {
    lcf_arrays_e(0);
  };

  my $group = $groups{$current}->{group};
  ## not flat, k-weight
  my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
  ($suff = 'norm') if ($$hash_pointer{fitspace} eq 'd');
  ($suff = 'chi')  if ($$hash_pointer{fitspace} eq 'k');
  my @x = Ifeffit::get_array("$group.$x");
  unless ($$hash_pointer{fitspace} eq 'k') {
    @x = Ifeffit::get_array("l___cf.energy");
  };
  my @data;
  if ($$hash_pointer{fitspace} eq 'd') {
    ##$groups{$current}->dispose("t___oss.y = deriv($group.$suff)/deriv($group.energy)\n", 1);
    $groups{$current}->dispose("t___oss.y = deriv(l___cf.data)/deriv(l___cf.energy)\n", 1);
    @data = Ifeffit::get_array("t___oss.y");
    $groups{$current}->dispose("erase t___oss.y\n", 1);
  } else {
    ##@data = Ifeffit::get_array("$group.$suff");
    @data = Ifeffit::get_array("l___cf.data");
  };
  my @fit   = Ifeffit::get_array("l___cf.mix");
  my @diff  = Ifeffit::get_array("l___cf.diff");
  my @components = ();
  foreach  my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$hash_pointer{"standard$i"} eq 'None');
    my @this = Ifeffit::get_array("l___cf.$i");
    $components[$i] = \@this;
  };
  my $kw = -1 * $$hash_pointer{kw};	# remove the k-weighting from the fit
  foreach my $i (0 .. $#x) {
    if ($$hash_pointer{fitspace} eq 'k') {
      next if ($i==0);
      printf F "  %.3f   %.5f   %.5f   %.5f", $x[$i], $data[$i], $fit[$i]*$x[$i]**$kw, $diff[$i]*$x[$i]**$kw;
      foreach my $j (1 .. $config{linearcombo}{maxspectra}) {
	next if ($$hash_pointer{"standard$j"} eq 'None');
	printf F "   %.5f", $components[$j]->[$i]*$x[$i]**$kw;
      };
      print  F $/;
    } else {
      printf F "  %.3f   %.5f   %.5f   %.5f", $x[$i], $data[$i], $fit[$i], $diff[$i];
      foreach my $j (1 .. $config{linearcombo}{maxspectra}) {
	next if ($$hash_pointer{"standard$j"} eq 'None');
	printf F "   %.5f", $components[$j]->[$i];
      };
      print  F $/;
    };
  };
  close F;
  Echo("Wrote linear combination fit report to \"$file\"");
};

sub lcf_marked_report {
  ## write the header information
  my $how = "";
 SWITCH: {
    ($how = 'norm(E)'),  last SWITCH if ($$hash_pointer{fitspace} eq 'e');
    ($how = 'deriv(E)'), last SWITCH if ($$hash_pointer{fitspace} eq 'd');
    ($how = 'chi(k)'),   last SWITCH if ($$hash_pointer{fitspace} eq 'k');
  };
  my $head = $groups{$current} -> project_header;
  $head   =~ s/,/ /g;
  $head   .= "# Linear combination fits to marked groups as $how$/";
  $head   .= "#    fit done use k-weight = $$hash_pointer{kw}$/" if ($$hash_pointer{fitspace} eq 'k');
  $head   .= "#    noise level: $$hash_pointer{noise}$/";
  $head   .= "#    values between 0 and 1: ";
  $head   .= ($$hash_pointer{nonneg}) ? "yes" : "no";
  $head   .= "$/";
  $head   .= "#    values sum to 1: ";
  $head   .= ($$hash_pointer{100}) ? "yes" : "no";
  $head   .= "$/";
  $head =~ s/^\#/\#,/g;

  open F, ">".$groups{"Default Parameters"} -> find('athena', 'temp_lcf');
  print F $head;

  ## write the column labels for the standards
  print F ",,,,,,,";
  foreach my $i (1..$config{linearcombo}{maxspectra}) {
    next if ($$hash_pointer{"standard$i"} eq 'None');
    print F ",", $$hash_pointer{"standard_lab$i"}, ",,,";
  };
  print F ",linear term,,,";
  print F $/;

  ## write the column labels for the parameters
  print F "Group,R-factor,chi square,chi nu,nvar,ndata,fit min,fit max",
    ",value,+/-,e shift,+/-" x $$hash_pointer{nstandards},
      ",slope,+/-,y-intercept,+/-",
	$/;

  ## loop through the marked groups
  foreach my $g (&sorted_group_list) {
    next unless $marked{$g};
    my $is_ok = 1;
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      $is_ok = 0 if ($g eq $$hash_pointer{"standard$i"});
    };
    next unless $is_ok;
    (my $label = $groups{$g}->{label}) =~ s/,//g;
    print F join(",",
		 $label,
		 $groups{$g}->{lcf_rfact},
		 $groups{$g}->{lcf_chisqr},
		 $groups{$g}->{lcf_chinu},
		 $groups{$g}->{lcf_nvarys},
		 $groups{$g}->{lcf_ndata},
		 $groups{$g}->{lcf_fitmin},
		 $groups{$g}->{lcf_fitmax},
		);
    foreach my $i (1..$config{linearcombo}{maxspectra}) {
      next if ($$hash_pointer{"standard$i"} eq 'None');
      print F join(",", q{},
		   $groups{$g}->{"lcf_value$i"},
		   $groups{$g}->{"lcf_delta_value$i"});
      if ($$hash_pointer{fitspace} eq 'k') {
	print F ",0,0";
      } else {
	print F join(",", q{},
		     $groups{$g}->{"lcf_e0val$i"},
		     $groups{$g}->{"lcf_delta_e0val$i"});
      };
    };
    if ($$hash_pointer{fitspace} eq 'k') {
      print F ",0,0,0,0";
    } else {
      print F join(",", q{},
		   $groups{$g}->{"lcf_slope"},
		   $groups{$g}->{"lcf_delta_slope"},
		   $groups{$g}->{"lcf_yint"},
		   $groups{$g}->{"lcf_delta_yint"},
		  );
    };
    print F $/;
  };
  close F;
};

sub lcf_save_marked_report {
  Error("You have not made a marked groups fit!"), return unless (-e $groups{"Default Parameters"}->find('athena', 'temp_lcf'));
  my $path = $current_data_dir || Cwd::cwd;
  my $f = "lcf_marked.csv";
  my $types = [['Comma separated values', '.csv'], ['All files', '*']];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$f,
				 -title => "Athena: Write marked groups fitting report");
  Echo("Not writing marked groups fit report"), return unless $file;
  copy($groups{"Default Parameters"}->find('athena', 'temp_lcf'), $file);
  Echo("Saved marked fit report as \"$file\"");
};

sub lcf_csv_report {

  my $path = $current_data_dir || Cwd::cwd;
  my $f = $groups{$current}->{label} . "_lcf.csv";
  $f =~ s/ /_/g;
  my $types = [['Comma separated values', '.csv'], ['All files', '*']];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$f,
				 -title => "Athena: Write linear combination fitting report");
  Echo("Not writing linear combination fit report"), return unless $file;

  my @order  = $widget{lcf_result_table}->info('children');
  my @labels = map {$groups{$_}->{label}} @order;
  push(@labels, 'linear term') if ($$hash_pointer{linear});

  my $how = "";
 SWITCH: {
    ($how = 'norm(E)'),  last SWITCH if ($$hash_pointer{fitspace} eq 'e');
    ($how = 'deriv(E)'), last SWITCH if ($$hash_pointer{fitspace} eq 'd');
    ($how = 'chi(k)'),   last SWITCH if ($$hash_pointer{fitspace} eq 'k');
  };
  my $head = $groups{$current} -> project_header;
  $head   =~ s/,/ /g;
  $head   .= sprintf("# Linear combination fits to %s as $how\n", $groups{$current}->{label});
  $head   .= "#    fit done use k-weight = $$hash_pointer{kw}\n" if ($$hash_pointer{fitspace} eq 'k');

  open F, ">".$file;
  print F $head;
  print F "," x 13, join(",,,,", @labels), $/;
  my $n = $#labels+1;
  print F "R-factor,chisqr,chinu,fit_status,Nvar,Ndata,fit_min,fit_max,,y_intercept,delta_y_intercept,slope,delta_slope" .
    ",weight,delta_weight,e0,delta_e0" x $n . $/;

  my @all = $widget{lcf_select_table}->info('children');
  foreach my $i (@all) {
    $widget{lcf_select_table} -> selectionClear;
    $widget{lcf_select_table} -> selectionSet($i);
    my $data = $widget{lcf_select_table}->info('data', $i);
    $data =~ s/^[^\|]*\|//;
    $data =~ s/\|/,/g;
    print F $data, $/;
  };
  close F;
  $widget{lcf_select_table} -> selectionClear;
  $widget{lcf_select_table} -> selectionSet(0);
  $$hash_pointer{toggle} = 1;
  lcf_fill_result(\@order, $hash_pointer, 1, 0);
  Echo("Wrote linear combination fit report to \"$file\"");
};


## make a new data group out of the best fit function.  make this a
## detector group so it can only be plotted in E
sub lcf_group {
  my $rlp = $_[0];
  my $array = $_[1];
  my $group = $groups{$current}->{group};
  my $name = ($array eq "fit") ? "LCF " : "LCF diff ";
  my ($new, $label) = group_name($name . $groups{$current}->{label});
  $groups{$new} = Ifeffit::Group -> new(group=>$new, label=>$label);
  $groups{$new} -> set_to_another($groups{$group});
  if ($$rlp{fitspace} eq 'k') {
    $groups{$new} -> MAKE(is_xmu => 0, is_chi => 1, is_rsp => 0,
			  is_qsp => 0, is_bkg => 0,
			  not_data => 0,
			  file => $$rlp{filestring});
  } else {
    $groups{$new} -> MAKE(is_xmu => 1, is_chi => 0, is_rsp => 0,
			  is_qsp => 0, is_bkg => 0, is_nor => 1,
			  not_data => 0, bkg_flatten => 0,
			  file => $$rlp{filestring});
    $groups{$new} -> MAKE(bkg_e0 => $groups{$group}->{bkg_e0});
  };
  $groups{$new}->{titles} = [];
  my $text = $widget{lcf_text} -> get(qw(1.0 end));
  ## see refresh_titles for explanation
  foreach (split(/\n/, $text)) {
    next if ($_ =~ /^\s*$/);
    my $count = 0;
    foreach my $i (0..length($_)) {
      ++$count if (substr($_, $i, 1) eq '(');
      --$count if ($count and (substr($_, $i, 1) eq ')'));
    };
    $_ .= ')' x $count;
    push @{$groups{$new}->{titles}}, $_;
  };
  $groups{$new} -> put_titles;
  my $which = ($array eq "fit") ? "mix" : "diff";
  if ($$rlp{fitspace} eq 'k') {
    lcf_arrays_k(0);
    my $kw = -1 * $$rlp{kw};	# remove the k-weighting from the fit
    $groups{$new} -> dispose("set $new.k = $group.k", $dmode);
    $groups{$new} -> dispose("set $new.chi = l___cf.$which*$group.k^$kw", $dmode);
  } else {
    my $was = $$rlp{fitspace};
    $$rlp{fitspace} = 'e';
    lcf_arrays_e(0);
    $$rlp{fitspace} = $was;
    ##$groups{$new} -> dispose("set $new.energy = $group.energy + " . $groups{$group}->{bkg_eshift}, $dmode);
    $groups{$new} -> dispose("set $new.energy = l___cf.energy", $dmode);
    $groups{$new} -> dispose("set $new.xmu = l___cf.$which", $dmode);
  };
  ++$line_count;
  fill_skinny($list, $new, 1, 1);
  my $memory_ok = $groups{$new}
    -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo("WARNING: Ifeffit is out of memory!"), return if ($memory_ok == -1);
  Echo("Saved linear combination fit as a new data group");
};

## restore all the widgets except the optionmenus to their original
## state
sub lcf_reset {
  my $rlp = $_[0];
  my $skip_toggles= $_[1];
  my $bg = $config{colors}{background};
  $widget{lcf_maxfit} -> configure(-foreground=>'black',
				   -background=>$bg,
				   -text=>"") unless $$rlp{doing_combinatorics};
  $groups{$current}->dispose("\n## reseting the LCF parameters:\n");
  $widget{lcf_text}   -> delete(qw(1.0 end));
  unless ($skip_toggles) {
    $widget{lcf_nonneg} -> select;
    $widget{lcf_linear} -> deselect;
    $widget{lcf_100}    -> select;
    $widget{lcf_e0all}  -> deselect;
  };
  lcf_initialize($rlp, 2);
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    unless ($skip_toggles) {
      $$rlp{"e0$i"} = $config{linearcombo}{fite0};
      $$rlp{"e0val$i"} = 0;
    };
    $$rlp{"delta_e0val$i"} = 0;
  };
  $$rlp{req}         = q{};
  $$rlp{slope}       = 0;
  $$rlp{delta_slope} = 0;
  $$rlp{yint}        = 0;
  $$rlp{delta_yint}  = 0;
  $groups{$current}->dispose("unguess\n");
  #$groups{$current}->dispose("erase \@group l___cf\n");
};

sub lcf_pluck{
  my $rlp = $_[0];
  my $which = $_[1];
  my $e0 = $groups{$current}->{bkg_e0};
  my $how = ($$rlp{fitspace} eq 'k') ? 'k' : 'e';
  &pluck("lcf_$which", 0, $how);
  my $e = $widget{"lcf_$which"}->get();
  if      (($$rlp{fitspace} =~ /[ed]/) and ($last_plot eq 'e')) {
    $e = $e-$e0;
  } elsif (($$rlp{fitspace} =~ /[ed]/) and ($last_plot eq 'k')) {
    $e = $groups{$current}->k2e($e);
  } elsif (($$rlp{fitspace} eq 'k')    and ($last_plot eq 'e')) {
    $e = $groups{$current}->e2k($e);
  } elsif (($$rlp{fitspace} eq 'k')    and ($last_plot eq 'k')) {
    1;
  };
  $e = sprintf("%.3f", $e);
  $widget{"lcf_$which"}->delete(0, 'end');
  $widget{"lcf_$which"}->insert(0, $e);
  if ($$rlp{fitspace} eq 'k') {
    my $key = join("_", "lcf", $which, "k");
    $groups{$current}->MAKE($key => $e);
  } else {
    my $key = join("_", "lcf", $which, "e");
    $groups{$current}->MAKE($key => $e);
  };
};

## compute an r-factor and generate a couple of lines containing the
## basic fitting statistics
sub lcf_statistics {
  my $rlp = $_[0];
  my $group = $groups{$current}->{group};
  my ($emin, $emax, @x, @y, @z);
  if ($$rlp{fitspace} eq 'e') {
    my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
    ($emin, $emax) = ($$rlp{enot}+$$rlp{fitmin},
		      $$rlp{enot}+$$rlp{fitmax});
    @x = Ifeffit::get_array("l___cf.energy");
    @z = Ifeffit::get_array("l___cf.data");
  } elsif ($$rlp{fitspace} eq 'd') {
    ($emin, $emax) = ($$rlp{enot}+$$rlp{fitmin},
		      $$rlp{enot}+$$rlp{fitmax});
    @x = Ifeffit::get_array("l___cf.energy");
    @z = Ifeffit::get_array("l___cf.data");
  } else {
    ($emin, $emax) = ($$rlp{fitmin},$$rlp{fitmax});
    @x = Ifeffit::get_array("$group.k");
    @z = Ifeffit::get_array("$group.chi");
  };
  @y = Ifeffit::get_array("l___cf.resid");
  my ($sumsqr, $npts, $rfact) = (0, 0, 0);
  foreach my $i (0 .. $#x) {
    next if $x[$i] < $emin;
    next if $x[$i] > $emax;
    last if $i > $#z;
    ++$npts;
    $rfact += $y[$i]**2;
    if ($$rlp{fitspace} =~ /[ed]/) {
      $sumsqr += $z[$i]**2;
    } else {
      $sumsqr += ($z[$i]*$x[$i]**$$rlp{kw})**2;
    };
  };
  $sumsqr ||= 1;
  $rfact /= $sumsqr;
  $$rlp{sumsqr} = $sumsqr;
  $$rlp{rfact}  = $rfact;
  $$rlp{chisqr} = Ifeffit::get_scalar("chi_square");
  $$rlp{chinu}  = Ifeffit::get_scalar("chi_reduced");
  $$rlp{nvarys} = Ifeffit::get_scalar("n_varys");
  $$rlp{ndata}  = $npts;
  ## also save a group data
  $groups{$current}->{lcf_sumsqr} = $sumsqr;
  $groups{$current}->{lcf_rfact}  = $rfact;
  $groups{$current}->{lcf_chisqr} = Ifeffit::get_scalar("chi_square");
  $groups{$current}->{lcf_chinu}  = Ifeffit::get_scalar("chi_reduced");
  $groups{$current}->{lcf_nvarys} = Ifeffit::get_scalar("n_varys");
  $groups{$current}->{lcf_ndata}  = $npts;
};


sub lcf_combinatorics {
  my $rlp = $_[0];
  Echo("Combinatorial fitting ...");
  if ($$rlp{fitspace} eq 'k') {
    $$rlp{fitmin_k} = $$rlp{fitmin};
    $$rlp{fitmax_k} = $$rlp{fitmax};
  } else {
    $$rlp{fitmin_e} = $$rlp{fitmin};
    $$rlp{fitmax_e} = $$rlp{fitmax};
  };
  my @save = ();
  my @standards = ();
  my @order = ();
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    push(@order,     $$rlp{"standard".$i});
    push(@standards, $$rlp{"standard".$i}) unless ($$rlp{"standard".$i} eq 'None');
    $save[$i] = $$rlp{"standard".$i};
    ##$$rlp{"standard".$i} = 'None';
  };
  my @biglist = ();
  my $req_save = $$rlp{req};
  my $required = ($$rlp{req}) ? $$rlp{"standard".$$rlp{req}} : q{};
  foreach my $n (2 .. $#standards+1) {
    last if ($n > $$rlp{maxstan});
    my $combinat = Math::Combinatorics->new(count => $n,
					    data => \@standards,
					   );
    while (my @combo = $combinat->next_combination) {
      my $stringified = join(" ", @combo);
      ##print ">$required< $stringified\n";
      next if ($required and not ($stringified =~ /$required/));
      push @biglist, \@combo;
    };
  };

  if ($#biglist > 50) {
    my ($n, $ns, $ms) = ($#biglist+1, $#standards+1, $$rlp{maxstan});
    my $message = "You have asked that $n fits be performed ($ns possible standards with each fit using up to $ms of them).  That will take some time.  Do you want to continue?";
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => $message,
		     -title          => 'Athena: Start fitting?',
		     -buttons        => ['Continue', 'Abort'],
		     -default_button => 'Continue',);
    my $response = $dialog->Show();
    Echo("Combinatorial fitting ... aborted!"), return if ($response eq 'Abort');
  };
  $top -> Busy;
  my @results;
  $$rlp{iterator} = 0;
  $$rlp{doing_combinatorics} = 1;
  my $orange = $config{colors}{current};
  my $blue = $config{colors}{activehighlightcolor};
  $widget{lcf_maxfit} -> configure(-foreground=>$blue,
				   -background=>$orange);
  my $nbl = $#biglist + 1;
  tie my $timer, 'Time::Stopwatch';
  foreach my $l (@biglist) {
    #map {print("$groups{$_}->{label} ")} @$l;
    #print $/;

    my $i = 1;
    foreach my $s (@order) {
      if (grep(/$s/, @$l)) {
	$$rlp{"standard".$i} = $s;
	$$rlp{"standard_lab$i"} = $groups{$s}->{lcf_menu_label};
      } else {
	$$rlp{"standard".$i} = 'None';
	$$rlp{"standard_lab$i"} = '0: None';
      };
      ++$i;
    };
    lcf_reset($rlp,1);
    $$rlp{req} = $req_save;
    $top -> update;

    ++$$rlp{iterator};
    $widget{lcf_maxfit} -> configure(-text=>"fit $$rlp{iterator} of $nbl");
    ## run this fit
    lcf_fit($rlp, 0);
    $$rlp{fit_status} = Ifeffit::get_scalar('&status');

    ## store the results of this fit
    my @this = ();
    push @this, join(",", @$l), $$rlp{rfact}, $$rlp{chisqr}, $$rlp{chinu}, $$rlp{fit_status}, $$rlp{nvarys},
      $$rlp{ndata}, $$rlp{fitmin}, $$rlp{fitmax}, 0,
	$$rlp{yint}, $$rlp{delta_yint}, $$rlp{slope}, $$rlp{delta_slope};
    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
      push @this, $$rlp{"value".$i}, $$rlp{"delta_value".$i}, $$rlp{"e0val".$i}, $$rlp{"delta_e0val".$i};
    };
    push @results, \@this;
  };
  my $elapsed = $timer;
  undef $timer;
  $elapsed = sprintf("%d fits in %.0f min, %.0f sec", $nbl, $elapsed/60, $elapsed%60);
  $$rlp{doing_combinatorics} = 0;
  $$rlp{fit_status} = 0;
  $$rlp{req} = $req_save;
  $groups{$current} -> dispose("set &status = 0\n", $dmode);

  ## sort by increasing R-factor
  @results = sort {$a->[1] <=> $b->[1]} @results;
  $lcf_data{$current}{order}   = \@order;
  $lcf_data{$current}{results} = \@results;
  my $brown = $config{colors}{background};
  $widget{lcf_maxfit} -> configure(-text=>"", -background=>$brown);

  lcf_display();

  $widget{lcf_combo_group} -> configure(-text=>"Fits to \"$groups{$current}->{label}\" with up to $$rlp{maxstan} standards");
  $top -> Unbusy;
  Echo("Combinatorial fitting ... done!  (Displaying and plotting the best fit.) ($elapsed)");
};


sub lcf_display {

  my @results = @{ $lcf_data{$current}{results} };
  my @order   = @{ $lcf_data{$current}{order}   };
  ## need to translate between the integers in the result table and
  ## the groups used in the fit
  my %names;
  $names{$order[$_]} = $_+1 foreach (0 .. $#order);


  ## empty out both tables
  $widget{lcf_select_table}->delete('all');
  $widget{lcf_result_table}->delete('all');
  my $j = 0;
  my $combo_selected = $j;
  ## fill the select table with all these fits
  foreach (@results) {
    $widget{lcf_select_table}->add($j, -data=>join("|", @$_));
    #my @these = split(/,/, $_->[0]);
    #print join(" ", @these, $_->[1]), $/;
    (my $text = $_->[0]) =~ s/([a-z]{4})/$names{$1}/g;
    $text = join(",", sort {$a <=> $b} ( split(/,/, $text))); # sort the indeces
    $widget{lcf_select_table}->itemCreate($j, 0, -itemtype=>'text',   -text=>$text);
    $widget{lcf_select_table}->itemCreate($j, 1, -itemtype=>'text',   -text=>sprintf("%.7g",$_->[1]));
    $widget{lcf_select_table}->itemCreate($j, 2, -itemtype=>'text',   -text=>sprintf("%.7g",$_->[2]));
    ++$j;
  };
  ## fill the results table
  my $k = 1;
  foreach my $s (@order) {
    next if ($s eq 'None');
    $widget{lcf_result_table}->add($s);
    $widget{lcf_result_table}->itemCreate($s, 0, -itemtype=>'text', -text=>$k);
    $widget{lcf_result_table}->itemCreate($s, 1, -itemtype=>'text', -text=>$groups{$s}->{label});
    my $v = 6+4*$k;
    $widget{lcf_result_table}->itemCreate($s, 2, -itemtype=>'text',
					  -text=>sprintf("%.3f (%.3f)", $results[0]->[$v], $results[0]->[$v+1]));
    $widget{lcf_result_table}->itemCreate($s, 3, -itemtype=>'text',
					  -text=>sprintf("%.3f (%.3f)", $results[0]->[$v+2], $results[0]->[$v+3]));
    ++$k;
  };
  if ($$hash_pointer{linear}) {
    $widget{lcf_result_table}->add('linear');
    $widget{lcf_result_table}->itemCreate('linear', 1, -itemtype=>'text', -text=>'linear term');
    $widget{lcf_result_table}->itemCreate('linear', 2, -itemtype=>'text',
					  -text=>sprintf("%.3f (%.3f)", $$hash_pointer{yint}, $$hash_pointer{delta_yint}));
    $widget{lcf_result_table}->itemCreate('linear', 3, -itemtype=>'text',
					  -text=>sprintf("%.6f (%.6f)", $$hash_pointer{slope}, $$hash_pointer{delta_slope}));
  };

  @order  = $widget{lcf_result_table}->info('children');
  $widget{lcf_select_table} -> configure(-browsecmd=>sub{lcf_fill_result(\@order, $hash_pointer, 1)});
  $widget{lcf_select_table} -> selectionSet(0);
  $widget{lcf_select_table} -> anchorSet(0);
  $$hash_pointer{toggle} = 1;
  lcf_fill_result(\@order, $hash_pointer, 1, 0);
  $widget{lcf_combo_group} -> configure(-text=>"Fits to \"$groups{$current}->{label}\"");
  $widget{lcf_notebook} -> pageconfigure('combinatorics', -state=>'normal');
  $widget{lcf_notebook} -> raise('combinatorics');
};

sub lcf_fill_result {
  #print join(" ", @_), $/;
  my ($rorder, $rlp, $plot, $j) = @_;
  $$rlp{toggle} = not $$rlp{toggle};
  return if $$rlp{toggle};	#  only on the release
  $j = $widget{lcf_select_table} -> selectionGet();
  my $data = $widget{lcf_select_table} -> info('data', $j);
  my @list = split(/\|/, $data);
  my $i = 0;
  ##my %local = ();
  foreach my $s (@$rorder) {
    ++$i;
    if ($s eq 'None') {
      $$rlp{"standard$i"}     = 'None';
      $$rlp{"standard_lab$i"} = '0: None';
      $$rlp{"value$i"}        = 0;
      $$rlp{"delta_value$i"}  = 0;
      $$rlp{"e0val$i"}        = 0;
      $$rlp{"delta_e0val$i"}  = 0;
      next;
    };
    ## fill the other two tabs
    if ($list[0] =~ /$s/) {

      my $ii = 0;
      foreach my $ke (@{$$rlp{keys}}) {
	next if ($ke eq 'None');
	++$ii;
	last if ($ke eq $s);
      };
      $$rlp{"standard$i"}     = $s;
      $$rlp{"standard_lab$i"} = $groups{$s}->{lcf_menu_label};

      my ($v, $w) = (10+4*$i, 11+4*$i);
      $widget{lcf_result_table}->itemConfigure($s, 2,
					       -text=>sprintf("%.3f (%.3f)", $list[$v]||0, $list[$w]||0));
      $$rlp{"value$i"}        = $list[$v];
      $$rlp{"delta_value$i"}  = $list[$w];

      ($v, $w) = (12+4*$i, 13+4*$i);
      $widget{lcf_result_table}->itemConfigure($s, 3,
					       -text=>sprintf("%.3f (%.3f)", $list[$v]||0, $list[$w]||0));
      $$rlp{"e0val$i"}        = $list[$v];
      $$rlp{"delta_e0val$i"}  = $list[$w];

    } else {

      $widget{lcf_result_table}->itemConfigure($s, 2, -text=>" ");
      $widget{lcf_result_table}->itemConfigure($s, 3, -text=>" ");

      $$rlp{"standard$i"}     = 'None';
      $$rlp{"standard_lab$i"} = '0: None';
      $$rlp{"value$i"}        = 0;
      $$rlp{"delta_value$i"}  = 0;
      $$rlp{"e0val$i"}        = 0;
      $$rlp{"delta_e0val$i"}  = 0;
    };
    $groups{$current} -> MAKE("lcf_standard$i"	   => $$rlp{"standard$i"},
			      "lcf_standard_lab$i" => $$rlp{"standard_lab$i"},
			      "lcf_value$i"	   => $$rlp{"value$i"},
			      "lcf_delta_value$i"  => $$rlp{"delta_value$i"},
			      "lcf_e0val$i"	   => $$rlp{"e0val$i"},
			      "lcf_delta_e0val$i"  => $$rlp{"delta_e0val$i"},
			     );
  };
  ## fill up stats and others
  $$rlp{rfact}	    = $list[1];
  $$rlp{chisqr}	    = $list[2];
  $$rlp{chinu}	    = $list[3];
  $$rlp{fit_status} = $list[4];
  $$rlp{nvarys}	    = $list[5];
  $$rlp{ndata}	    = $list[6];
  if ($$rlp{linear}) {
    $widget{lcf_result_table}->itemConfigure('linear', 2,
					     -text=>sprintf("%.3f (%.3f)", $list[10],  $list[11]));
    $widget{lcf_result_table}->itemConfigure('linear', 3,
					     -text=>sprintf("%.6f (%.6f)", $list[12], $list[13]));
  };

  $groups{$current} -> MAKE(lcf_rfact	    => $list[1],
			    lcf_chisqr	    => $list[2],
			    lcf_chinu	    => $list[3],
			    lcf_fit_status  => $list[4],
			    lcf_nvarys	    => $list[5],
			    lcf_ndata	    => $list[6],
			    lcf_fitmin      => $list[7],
			    lcf_fitmax      => $list[8],
			    lcf_yint        => $list[10],
			    lcf_delta_yint  => $list[11],
			    lcf_slope       => $list[12],
			    lcf_delta_slope => $list[13],
			   );


  $top -> update;
  $widget{lcf_operations} -> entryconfigure(1, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(3, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(4, -state=>'normal', -style=>$$rlp{normal_style});
  $widget{lcf_operations} -> entryconfigure(7, -state=>'normal', -style=>$$rlp{normal_style})
    if ($$rlp{fitspace} eq 'k');
  if ($plot) {
    if ($$rlp{fitspace} eq 'k') { lcf_arrays_k(0) } else { lcf_arrays_e() };
    lcf_results($rlp);
    lcf_plot($rlp);
  };
};


sub lcf_post_menu {

  ## figure out where the user clicked
  my $w = shift;
  my $Ev = $w->XEvent;
  delete $w->{'shiftanchor'};
  my $entry = $w->GetNearest($Ev->y, 1);
  return unless (defined($entry) and length($entry));

  ## select and anchor the right-clicked parameter
  #$w->selectionClear;
  $w->anchorSet($entry);
  #$w->selectionSet($entry);

  #my @order  = $widget{lcf_result_table}->info('children');
  #$$hash_pointer{toggle} = 1;
  #lcf_fill_result(\@order, $hash_pointer, 1);


  ## post the message with parameter-appropriate text
  my $which = $w->info('anchor');
  $which    = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  my $id = $widget{lcf_select_table}->itemCget($entry, 0, '-text');
  my ($X, $Y) = ($Ev->X, $Ev->Y);
  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[[ command=>"Write column data file for fit using $id",
		       -command=>sub{$top->Busy;
				     $w->selectionClear;
				     $w->selectionSet($entry);
				     my @order  = $widget{lcf_result_table}->info('children');
				     $$hash_pointer{toggle} = 1;
				     lcf_fill_result(\@order, $hash_pointer, 1);
				     &lcf_save_fit;
				     $top->Unbusy;}
		      ],
		      [ command=>"Make data group for fit using $id",
		       -command=>sub{$top->Busy;
				     $w->selectionClear;
				     $w->selectionSet($entry);
				     my @order  = $widget{lcf_result_table}->info('children');
				     $$hash_pointer{toggle} = 1;
				     lcf_fill_result(\@order, $hash_pointer, 1);
				     &lcf_group($hash_pointer);
				     $top->Unbusy;},
		      ],
		      [ command=>"Write report for fit using $id",
		       -command=>sub{$top->Busy;
				     $w->selectionClear;
				     $w->selectionSet($entry);
				     my @order  = $widget{lcf_result_table}->info('children');
				     $$hash_pointer{toggle} = 1;
				     lcf_fill_result(\@order, $hash_pointer, 1);
				     &lcf_report;
				     $top->Unbusy;}
		      ],
		      "-",
		      [ command=>"Write CSV report for all fits",
		       -command=>\&lcf_csv_report,
		      ],
		     ])
      -> Post($X, $Y);
  $w -> break;
};


sub lcf_save_fit {
  my $path = $current_data_dir || Cwd::cwd;
  my $id = $widget{lcf_select_table} -> itemCget($widget{lcf_select_table}->selectionGet, 0, "-text");
  $id =~ s/,/_/g;
  my $f = $groups{$current}->{label} . ".fit_$id";
  $f =~ s/ /_/g;
  my $types = [['Comma separated values', '.csv'], ['All files', '*']];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$f,
				 -title => "Athena: Write linear combination fitting result");
  Echo("Not writing linear combination fit result file"), return unless $file;

  if ($$hash_pointer{fitspace} eq 'k') { lcf_arrays_k(0) } else { lcf_arrays_e() };

  refresh_titles($groups{$current}); # make sure titles are up-to-date
  $groups{$current}->dispose("\$id_line_1 = \"Athena data file -- Athena version $VERSION\"", $dmode);
  $groups{$current}->dispose("\$id_line_2 = \"Saving LCF fit to $groups{$current}->{label}\"", $dmode);
  my $n = 3;

  my $arrays = "l___cf.mix, l___cf.diff";
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$hash_pointer{"standard$i"} eq 'None');
    my $line = "\$id_line_$n = \"~  $i: " . $$hash_pointer{"standard_lab$i"}  . "\"";
    $groups{$current}->dispose($line, $dmode);
    $arrays .= ", l___cf.$i";
    ++$n;
  };
  $groups{$current}->dispose("\$id_line_$n = \"~\"\n", $dmode);
  my $i = 0;
  foreach my $l (split(/\n/, $groups{$current}->param_summary)) {
    ++$i;
    $groups{$current}->dispose("\$param_line_$i = \"$l\"", $dmode);
  };
  if ($$hash_pointer{fitspace} eq 'k') {
    $groups{$current}->dispose("write_data(file=\"$file\", \$id_line_\*, \$param_line_\*, \$${current}_title_\*, $current.k, l___cf.data, $arrays)\n", $dmode);
  } else {
    my $suff = ($groups{$current}->{bkg_flatten}) ? 'flat' : 'norm';
    ($suff = 'norm') if ($$hash_pointer{fitspace} eq 'd');
    $groups{$current}->dispose("write_data(file=\"$file\", \$id_line_\*, \$param_line_\*, \$${current}_title_\*, $current.energy, $current.$suff, $arrays)\n", $dmode);
  };

};

sub lcf_constrain {
  my $how = $_[0];
  my @keys = qw(lcf_nonneg lcf_100 lcf_linear lcf_noise lcf_fitspace
                lcf_fitmin_k lcf_fitmin_e
                lcf_fitmax_k lcf_fitmax_e
               );
  foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
    next if ($$hash_pointer{"standard$i"} eq 'None');
    push @keys, "lcf_standard$i", "lcf_standard_lab$i", "lcf_value$i", "lcf_e0$i", "lcf_e0val$i";
  };
  set_params($how, @keys);
};


sub lcf_purge {
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  if ($fat_showing eq 'lcf') {
    Error("You may not purge LCF results while the LCF dialog is showing.");
    return;
  };
  foreach my $g (keys %groups) {
    foreach my $k (keys %{$groups{$g}}) {
      #print "$g $k\n";
      next unless ($k =~ /^lcf/);
      delete $groups{$g}->{$k};
    };
  };
  %lcf_data = ();
  project_state(0);
};

## END OF LINEAR COMBINATION FITTING SUBSECTION
##########################################################################################
