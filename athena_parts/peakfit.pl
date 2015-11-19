## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2009 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  near edge peak fitting.


sub peak_fit {
  Echo("No data!"), return unless $current;
  Echo("No data!"), return if ($current eq "Default Parameters");
  my $ps = $project_saved;
  my @save = ($plot_features{emin}, $plot_features{emax});
  $plot_features{emin} = $config{peakfit}{emin};
  $plot_features{emax} = $config{peakfit}{emax};
  project_state($ps);		# don't toggle if currently saved
  my $npeaks = $config{peakfit}{maxpeaks};
  my @peaks = ();
  my @param_list = ("amp", "width");

  $fat_showing = 'peakfit';
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $peak = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$peak -> packPropagate(0);
  $which_showing = $peak;

  my %peak_params = (function	     => 'atan', function_choice => 'atan',
		     fit_e	     => 0,
		     fit_a	     => 1,
		     fit_w	     => 1,
		     emin	     => $config{peakfit}{fitmin},
		     emax	     => $config{peakfit}{fitmax},
		     enot	     => $groups{$current}->{bkg_e0},
		     amp	     => 1, width => 1,
		     plot_components => $config{peakfit}{components},
		     plot_difference => $config{peakfit}{difference},
		     mark_centroids  => $config{peakfit}{centroids},
		     toplevel	     => $peak,
		     deltas	     => []);
  #my %function_map = (arctangent=>'atan', None=>'None', 'error function'=>'erf',
  #		      Gaussian=>'gauss', Lorentzian=>'loren', none=>'none',
  #		      'pseudo-Voight'=>'pvoight');
  $hash_pointer = \%peak_params;
  my $peak_results;

  $peak -> Label(-text=>"Peak fitting with lineshapes",
		  -font=>$config{fonts}{large},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');
  my $params_frame = $peak -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -ipadx=>5);
  my $frame = $params_frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -ipadx=>5);
  $frame -> Label(-text=>'Group: ',
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> pack(-side=>'left');
  $widget{peak_group} = $frame -> Label(-text=>$groups{$current}->{label},
					-foreground=>$config{colors}{button},
					#-width=>15, -justify=>'left'
				       )
    -> pack(-side=>'left', -padx=>3, -anchor=>'w');


  ## pack the next few in reverse order so they go flush up against
  ## the right hand side
  $grab{peak_emax} = $frame -> Button(@pluck_button, @pluck,
				      -command=>sub{&pluck("peak_emax");
						    my $e = $widget{peak_emax}->get();
						    $e = sprintf("%.3f", $e-$peak_params{enot});
						    $widget{peak_emax}->delete(0, 'end');
						    $widget{peak_emax}->insert(0, $e);
						  })
    -> pack(-side=>'right', -pady=>3);
  $widget{peak_emax} = $frame -> Entry(-width=>5, -textvariable=>\$peak_params{emax},
				     -validate=>'all',
				     -validatecommand=>[\&peak_set_variable, 'emax'],
				    )
    -> pack(-side=>'right', -pady=>3);
  $frame -> Label(-text=> "to",
		  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'right', -pady=>6);
  $grab{peak_emin} = $frame -> Button(@pluck_button, @pluck,
				      -command=>sub{&pluck("peak_emin");
						    my $e = $widget{peak_emin}->get();
						    $e = sprintf("%.3f", $e-$peak_params{enot});
						    $widget{peak_emin}->delete(0, 'end');
						    $widget{peak_emin}->insert(0, $e);
						  })
    -> pack(-side=>'right', -pady=>3);
  $widget{peak_emin} = $frame -> Entry(-width=>5, -textvariable=>\$peak_params{emin},
				     -validate=>'all',
				     -validatecommand=>[\&peak_set_variable, 'emin'],
				    )
    -> pack(-side=>'right', -pady=>3);
  $frame -> Label(-text=> "Fitting range:",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> pack(-side=>'right', -pady=>3, -fill=>'x');



  $frame = $params_frame -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x', -ipadx=>5);

  $widget{peak_components} = $frame ->
    Checkbutton(-text=>'Plot components', -selectcolor=>$config{colors}{single},
		-variable=>\$peak_params{plot_components})
      -> pack(-side=>'left', -padx=>5);#, -expand=>1, -anchor=>'w');
  $widget{peak_difference} = $frame ->
    Checkbutton(-text=>'Plot difference', -selectcolor=>$config{colors}{single},
		-variable=>\$peak_params{plot_difference})
      -> pack(-side=>'left', -padx=>5);#, -expand=>1, -anchor=>'center');
  $widget{peak_show} = $frame ->
    Checkbutton(-text=>'Mark centroids', -selectcolor=>$config{colors}{single},
		-command=>sub{$peak_params{mark_centroids} and
				peak_mark_centroids($current,\%peak_params,\@peaks);},
		-variable=>\$peak_params{mark_centroids})
      -> pack(-side=>'left', -padx=>5);


  $peak -> Button(-text=>'Return to the main window',  @button_list,
		  -background=>$config{colors}{background2},
		  -activebackground=>$config{colors}{activebackground2},
		  -command=>sub{
		    $groups{$current}->dispose("erase \@group p___eak", $dmode);
		    $groups{$current}->dispose("erase p___eak_enot p___eak_amp p___eak_width",
					       $dmode);
		    foreach my $ipk (0 .. $#peaks) {
		      my $i = $ipk+1;
		      $groups{$current}->dispose("erase p___eak_e$i p___eak_a$i p___eak_w$i",
						 $dmode);
		    };
		    &reset_window($peak, "peak fitting", \@save);
		  })
    -> pack(-side=>'bottom', -fill=>'x', -padx=>5, -pady=>5);

  ## help button
  $peak -> Button(-text=>'Document section: peak fitting', @button_list,
		   -command=>sub{pod_display("analysis::peak.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  ## frame with buttons in
  my $nb = $peak -> NoteBook(-backpagecolor=>$config{colors}{background},
			     -inactivebackground=>$config{colors}{inactivebackground},)
    -> pack(-side=>'top', -expand=>1, -fill=>'y');

  ## step function
  #my $lab = $frame -> Frame(-borderwidth=>2, -relief=>'flat')
  #  -> pack(-side=>'top', -expand=>1, -fill=>'both');

  my %nc;
  $nc{params} = $nb -> add('params', -label=>'Parameters', -anchor=>'center',);

  ## there should be a Pane here
  my $pane = $nc{params} -> Scrolled('Pane', -relief=>'groove', -borderwidth=>2,
				     -scrollbars=>'oe')
    -> pack(-expand=>1, -fill=>'y');
  $pane->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});

  my $hlist = $pane -> HList(-columns=>10, -header=>1, -width=>65, -height=>18,
			     -selectborderwidth=>0, -selectbackground=>
			     $config{colors}{activebackground} )
    -> pack(-expand=>1, -fill=>'y', -anchor=>'n');
  my $style = $hlist ->
    ItemStyle('text', -foreground=>$config{colors}{activehighlightcolor},
	      -font=>$config{fonts}{smbold},
	      -anchor=>'center');
  my $ih = 0;
  foreach my $t ('Function', 'Centroid', '', 'Fit', ' ',
		 'Amp.', 'Fit', ' ', 'Width', 'Fit') {
    $hlist->headerCreate($ih++, -headerbackground=>$config{colors}{background},
			 -itemtype=>'text', -style=>$style,
			 -text=>=>$t);
  };
  $hlist->add(1);

  $widget{peak_function} = $hlist -> Optionmenu(-textvariable => \$peak_params{function_choice},
						-borderwidth=>1, -width=>5);
  foreach my $f ('none', 'atan', 'erf', 'CL') {
    $widget{peak_function}
      -> command(-label => $f, -state=>($f =~ /CL/) ? 'disabled' : 'normal',
		 -command=>sub{
		   $peak_params{function_choice} = $f;
		 SWITCH: {
		     $peak_params{function} = 'none', last SWITCH if ($f eq 'none');
		     $peak_params{function} = 'atan', last SWITCH if ($f eq 'atan');
		     $peak_params{function} = 'erf',  last SWITCH if ($f eq 'erf');
		     $peak_params{function} = 'CL',   last SWITCH if ($f eq 'CL');
		   };
		   foreach my $p (@param_list) {
		     $peak_params{$p} = $widget{"peak_$p"}->get();
		   };
		   #&peak_do_fit($current, \%peak_params, $peak_results, @peaks);
		 });
  };
  $hlist->itemCreate(1, 0, -itemtype=>'window', -widget=>$widget{peak_function});
  $widget{peak_enot} = $hlist -> Entry(-width=>8, -textvariable=>\$peak_params{enot},
				     -validate=>'all',
				     -validatecommand=>[\&peak_set_variable, 'enot'],
				    );
  $hlist->itemCreate(1, 1, -itemtype=>'window', -widget=>$widget{peak_enot});
  my $inner =  $hlist -> Frame();
  $hlist->itemCreate(1, 2, -itemtype=>'window', -widget=>$inner);
  $grab{peak_enot} = $inner -> Button(@pluck_button, @pluck,
				      -command=>sub{&pluck("peak_enot");}) -> pack();
  $widget{peak_fit_e} = $hlist -> Checkbutton(-text=>"",
					      -selectcolor=>$config{colors}{single},
					      -variable=>\$peak_params{fit_e});
  $hlist->itemCreate(1, 3, -itemtype=>'window', -widget=>$widget{peak_fit_e});
  ##$hlist->itemCreate(1, 2, -itemtype=>'window', -widget=>$grab{peak_enot});
  $widget{peak_amp} = $hlist -> Entry(-width=>6, -textvariable=>\$peak_params{amp},
				      -validate=>'all',
				      -validatecommand=>[\&peak_set_variable, 'amp'],
				     );
  $hlist->itemCreate(1, 5, -itemtype=>'window', -widget=>$widget{peak_amp});
  $widget{peak_fit_a} = $hlist -> Checkbutton(-text=>"",
					      -selectcolor=>$config{colors}{single},
					      -variable=>\$peak_params{fit_a});
  $hlist->itemCreate(1, 6, -itemtype=>'window', -widget=>$widget{peak_fit_a});
  $widget{peak_width} = $hlist -> Entry(-width=>6, -textvariable=>\$peak_params{width},
				      -validate=>'all',
				      -validatecommand=>[\&peak_set_variable, 'width'],
				     );
  $hlist->itemCreate(1, 8, -itemtype=>'window', -widget=>$widget{peak_width});
  $widget{peak_fit_w} = $hlist -> Checkbutton(-text=>"",
					      -selectcolor=>$config{colors}{single},
					      -variable=>\$peak_params{fit_w});
  $hlist->itemCreate(1, 9, -itemtype=>'window', -widget=>$widget{peak_fit_w});


  #my $normalbg=$top->ItemStyle('window', -background=>$config{colors}{background});
  #my $alternatebg=$top->ItemStyle('window', -background=>$config{colors}{background2});
  foreach my $i (1 .. $npeaks) {
    $hlist->add($i+1);

    $peak_params{"e$i"} = "";
    $peak_params{"a$i"} = $config{peakfit}{peakamp};
    $peak_params{"w$i"} = $config{peakfit}{peakwidth};
    $peak_params{"f$i"} = "none";
    $peak_params{"function$i"} = "none";
    $peak_params{"fit_e$i"} = 0;
    $peak_params{"fit_a$i"} = 1;
    $peak_params{"fit_w$i"} = 1;
    $peaks[$i] = 0;
    #my $bg  = ($i % 2) ? $config{colors}{background2} : $config{colors}{background};
    #my $abg = ($i % 2) ? $config{colors}{activebackground2} :
    my $bg  = $config{colors}{background};
    my $abg = $config{colors}{activebackground};
    #my $style = ($i % 2) ? $alternatebg : $normalbg;
    push @param_list, "e$i", "a$i", "w$i";
    $widget{"peak_function$i"} = $hlist ->
      Optionmenu(-textvariable => \$peak_params{"function$i"}, -width=>5,
		 -borderwidth=>1, -background=>$bg, -activebackground=>$abg);
    foreach my $f (qw(none gauss loren pvoight atan erf CL)) {
      $widget{"peak_function$i"} ->
	command(-label => $f, -state=>($f =~ /(pvoight|CL)/) ? 'disabled' : 'normal',
		-command=>sub{
		  $peak_params{"function$i"} = $f;
		  $peaks[$i] = ($f eq 'none') ? 0 : 1;
		SWITCH: {
		    $peak_params{"f$i"} = 'none',    last SWITCH if ($f eq 'none');
		    $peak_params{"f$i"} = 'gauss',   last SWITCH if ($f eq 'gauss');
		    $peak_params{"f$i"} = 'loren',   last SWITCH if ($f eq 'loren');
		    $peak_params{"f$i"} = 'pvoight', last SWITCH if ($f eq 'pvoight');
		    $peak_params{"f$i"} = 'atan',    last SWITCH if ($f eq 'atan');
		    $peak_params{"f$i"} = 'erf',     last SWITCH if ($f eq 'erf');
		    $peak_params{"f$i"} = 'CL',      last SWITCH if ($f eq 'CL');
		  };
		  foreach my $p (qw(e a w)) {
		    $peak_params{$p.$i} = $widget{"peak_$p$i"}->get();
		  };
		  #&peak_do_fit($current, \%peak_params, $peak_results, @peaks);
		});
    };
    $hlist->itemCreate($i+1, 0, -itemtype=>'window', -widget=>$widget{"peak_function$i"});
    $widget{"peak_e$i"} = $hlist -> Entry(-width=>8, -textvariable=>\$peak_params{"e$i"},
					 -background=>$bg, -validate=>'all',
					 -validatecommand=>[\&peak_set_variable, "e$i"],
					);
    $hlist->itemCreate($i+1, 1, -itemtype=>'window',
		       -widget=>$widget{"peak_e$i"});
    my $inner =  $hlist -> Frame();
    $hlist->itemCreate($i+1, 2, -itemtype=>'window', -widget=>$inner);
    $grab{"peak_e$i"} = $inner -> Button(@pluck_button, @pluck,
					 -background=>$bg , -activebackground=>$abg,
					 -command=>sub{&pluck("peak_e$i")}) -> pack();
    #$hlist->itemCreate($i+1, 2, -itemtype=>'window', -widget=>$grab{"peak_e$i"});
    $widget{"peak_fit_e$i"} = $hlist -> Checkbutton(-text=>"",
						    -background=>$bg,
						    -activebackground=>$abg,
						    -selectcolor=>$config{colors}{single},
						    -variable=>\$peak_params{"fit_e$i"});
    $hlist->itemCreate($i+1, 3, -itemtype=>'window', -widget=>$widget{"peak_fit_e$i"});
    $widget{"peak_a$i"} = $hlist -> Entry(-width=>6, -textvariable=>\$peak_params{"a$i"},
					  -background=>$bg, -validate=>'all',
					  -validatecommand=>[\&peak_set_variable, "a$i"],
				       );
    $hlist->itemCreate($i+1, 5, -itemtype=>'window', -widget=>$widget{"peak_a$i"});
    $widget{"peak_fit_a$i"} = $hlist -> Checkbutton(-text=>"",
						    -background=>$bg,
						    -activebackground=>$abg,
						    -selectcolor=>$config{colors}{single},
						    -variable=>\$peak_params{"fit_a$i"});
    $hlist->itemCreate($i+1, 6, -itemtype=>'window', -widget=>$widget{"peak_fit_a$i"});
    $widget{"peak_w$i"} = $hlist -> Entry(-width=>6, -textvariable=>\$peak_params{"w$i"},
					  -background=>$bg, -validate=>'all',
					  -validatecommand=>[\&peak_set_variable, "w$i"],
					 );
    $hlist->itemCreate($i+1, 8, -itemtype=>'window', -widget=>$widget{"peak_w$i"});
    $widget{"peak_fit_w$i"} = $hlist -> Checkbutton(-text=>"",
						    -background=>$bg,
						    -activebackground=>$abg,
						    -selectcolor=>$config{colors}{single},
						    -variable=>\$peak_params{"fit_w$i"});
    $hlist->itemCreate($i+1, 9, -itemtype=>'window', -widget=>$widget{"peak_fit_w$i"});

  };

  $frame = $peak -> Frame()
    -> pack(-side=>'bottom', -fill=>'x');
  $widget{peak_save} = $frame ->
    Button(-text=>'Save fit as a data group',  @button_list,
	   -width=>1,
	   -state=>'disabled',
	   -command=>sub{
	     my $group = $groups{$current}->{group};
	     my $name  = $groups{$current}->{label};
	     my ($new, $label) = group_name("Peak $name");
	     $groups{$new} = Ifeffit::Group -> new(group=>$new, label=>$label);
	     ##$groups{$new} -> set_to_another($groups{$group});
	     $groups{$new} -> make(is_xmu => 0, is_chi => 0, is_rsp => 0,
				   is_qsp => 0, is_bkg => 0,
				   not_data => 1);
	     $groups{$new} -> make(bkg_e0 => $groups{$group}->{bkg_e0});
	     $groups{$new}->{titles} = [];
	     my $text = $peak_results -> get(qw(1.0 end));
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
	     my $sets = "set($new.energy = $group.energy + " . $groups{$group}->{bkg_eshift} . ",\n";
	     $sets   .= "    $new.det = p___eak.fun)";
	     $groups{$new}->dispose($sets, $dmode);
	     ++$line_count;
	     fill_skinny($list, $new, 1);
	     my $memory_ok = $groups{$new}
	       -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
	     Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
	   }
	  )
      -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $widget{peak_log} = $frame ->
    Button(-text=>'Write a log file',  @button_list,
	   -width=>1,
	   -state=>'disabled',
	   -command=>sub{&peak_log($current, $peak_results, \%peak_params, @peaks)}, )
      -> pack(-side=>'right', -expand=>1, -fill=>'x');


  $frame = $peak -> Frame()
    -> pack(-side=>'bottom', -fill=>'x');
  $widget{peak_reset} =
  $frame -> Button(-text=>'Reset amplitudes and widths',  @button_list,
		   -width=>1,
		   -command=>sub{
		     $widget{"peak_amp"}   -> delete(qw(0 end));
		     $widget{"peak_amp"}   -> insert(0, 1.0);
		     $widget{"peak_width"} -> delete(qw(0 end));
		     $widget{"peak_width"} -> insert(0, 1.0);
		     foreach my $i (1 .. $#peaks) {
		       $widget{"peak_a$i"} -> delete(qw(0 end));
		       $widget{"peak_a$i"} -> insert(0, $config{peakfit}{peakamp});
		       $widget{"peak_w$i"} -> delete(qw(0 end));
		       $widget{"peak_w$i"} -> insert(0, $config{peakfit}{peakwidth});
		     };
		   })
    -> pack(-side=>'right', -expand=>1, -fill=>'x');
  $widget{peak_plot} =
  $frame -> Button(-text=>'Plot lineshapes',  @button_list,
		   -width=>1,
		   -command=>sub{
		     Error("This is not mu(E) data."), return unless $groups{$current}->{is_xmu};
		     my $fun = $ {$widget{peak_function}->cget("-textvariable")};
		     $peak_params{function} = $fun;
		     foreach my $p (qw(enot amp width)) {
		       $peak_params{$p} = $widget{"peak_$p"}->get();
		     };
		     foreach my $i (1 .. $#peaks) {
		       my $fun = $ {$widget{"peak_function$i"}->cget("-textvariable")};
		       $peaks[$i] = (lc($fun) eq 'none') ? 0 : 1;
		       $peak_params{"f$i"} = $fun;
		       foreach my $p (qw(e a w)) {
			 $peak_params{$p.$i} = $widget{"peak_$p$i"}->get();
		       };
		     };
		     &peak_do_fit($current, 0, \%peak_params, $peak_results, @peaks);
		     $widget{peak_save} -> configure(-state=>'normal');
		     $widget{peak_log}  -> configure(-state=>'normal');
		   })
    -> pack(-side=>'left', -expand=>1, -fill=>'x');

  $peak -> Button(-text=>'Fit lineshapes',  @button_list,
		   -command=>sub{
		     Error("This is not mu(E) data."), return unless $groups{$current}->{is_xmu};
		     my $fun = $ {$widget{peak_function}->cget("-textvariable")};
		     $peak_params{function} = $fun;
		     foreach my $p (qw(enot amp width)) {
		       $peak_params{$p} = $widget{"peak_$p"}->get();
		     };
		     foreach my $i (1 .. $#peaks) {
		       my $fun = $ {$widget{"peak_function$i"}->cget("-textvariable")};
		       $peaks[$i] = (lc($fun) eq 'none') ? 0 : 1;
		       $peak_params{"f$i"} = $fun;
		       foreach my $p (qw(e a w)) {
			 $peak_params{$p.$i} = $widget{"peak_$p$i"}->get();
		       };
		     };
		     &peak_do_fit($current, 1, \%peak_params, $peak_results, @peaks);
		     $widget{peak_save} -> configure(-state=>'normal');
		     $widget{peak_log}  -> configure(-state=>'normal');
		   })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);




  ## text box containing the results + buttons for log file and data group
  $nc{results} = $nb -> add('results', -label=>'Results', -anchor=>'center',);
  $peak_results = $nc{results} -> Scrolled('ROText', qw(-relief sunken -borderwidth 2
							-wrap none -scrollbars se
							-width 5 -height 5),
					   -font=>$config{fonts}{fixed})
    -> pack(qw/-expand yes -fill both -side top/);
  disable_mouse3($peak_results->Subwidget('rotext'));
  $peak_results -> Subwidget("yscrollbar")
    -> configure(-background=>$config{colors}{background});
  $peak_results -> Subwidget("xscrollbar")
    -> configure(-background=>$config{colors}{background});
  $peak_results -> tagConfigure("text", -font=>$config{fonts}{fixedsm});


  $groups{$current}->{update_bkg} and $groups{$current}->dispatch_bkg($dmode);
  $groups{$current}->{peak} and peak_fill_variables($current, \%peak_params, \@peaks);
  &peak_do_fit($current, 1, \%peak_params, $peak_results, @peaks);
  #$peak -> grab;
  $plotsel -> raise('e');
  $top -> update;

};


sub peak_do_fit {
  my ($standard, $do_fit, $r_params, $peak_results, @peaks) = @_;

  Error("Peak fit aborted: " . $groups{$standard}->{label} . " is not an xmu group."),
    return unless ($groups{$standard}->{is_xmu});

  Echo("Fitting near edge peak structure for \`$groups{$standard}->{label}\' ... ");
  $top -> Busy(-recurse=>1,);
  my $emin += $$r_params{emin} + $$r_params{enot};
  my $emax += $$r_params{emax} + $$r_params{enot};
  my $offset = "";
 SWITCH: {
    $offset = "/pi + 0.5", last SWITCH if ($$r_params{function} eq 'atan');
    $offset = " + 1",      last SWITCH if ($$r_params{function} eq 'erf');
  };
  my @deltas = ();
  my @deflist = ();
  my $command = "## starting peak fit for " . $groups{$standard}->{label} . "\n";
  $command   .= "unguess\nerase \@group p___eak\n";
  $command   .= "set $standard.eshift = $standard.energy + " .
    $groups{$standard}->{bkg_eshift} . "\n";
  $groups{$standard} ->dispose("## clean up parameters from previous fit...", $dmode) if $$r_params{deltas};
  foreach my $d (@{$$r_params{deltas}}) {
    $groups{$standard} ->dispose("erase $d delta_$d\n", $dmode);
  };
  my $function = "p___eak.fun  = 0";
  ## $ymax is used for the vertical lines marking the fit range
  my $suff = ($groups{$standard}->{bkg_flatten}) ? 'flat' : 'norm';
  $groups{$standard} ->
    dispose("set ___x = splint($standard.energy+$groups{$standard}->{bkg_eshift}, $standard.$suff, $$r_params{enot})", 1);
  my $ymax = 2.5*Ifeffit::get_scalar("___x");
  $$r_params{ymax} = $ymax;

  ## save peak fitting parameters in data group
  $groups{$standard} -> MAKE(peak=>1,
			     peak_enot=>$$r_params{enot},
			     peak_amp=>$$r_params{amp},
			     peak_width=>$$r_params{width},
			     peak_function=>$$r_params{function},
			     peak_function_choice=>$$r_params{function_choice},
			     peak_fit_e=>$$r_params{fit_e},
			     peak_fit_a=>$$r_params{fit_a},
			     peak_fit_w=>$$r_params{fit_w},
			    );
  unless ($$r_params{function} eq 'none') {
    my ($fite, $fita, $fitw);
    #($fita, $toss, $fitw, $toss) = split(" ", $$r_params{fit_choice});
    $fite = ($$r_params{fit_e}) ? "guess" : "set  ";
    $fita = ($$r_params{fit_a}) ? "guess" : "set  ";
    $fitw = ($$r_params{fit_w}) ? "guess" : "set  ";
    $command .= "$fite p___eak_e = $$r_params{enot}\n";
    $command .= "$fita p___eak_amp = $$r_params{amp}\n";
    $command .= "$fitw p___eak_width = $$r_params{width}\n";
    $command .= "def p___eak.step = p___eak_amp * ($$r_params{function}(($standard.eshift - p___eak_e)/p___eak_width)$offset)\n";
    $function = "def p___eak.fun  = p___eak.step";
    push @deltas, qw(p___eak_e p___eak_amp p___eak_width);
    push @deflist, "p___eak.step", "p___eak.fun";
  };
  ## build the peak arrays, taking care not to leave any unused
  ## variables lying around
  foreach my $ipk (0 .. $#peaks) {
    my $i = $ipk+1;
    my $this = $$r_params{"f$i"};
    next unless ($peaks[$i] and ($$r_params{"e$i"}));
    my ($fite, $fita, $fitw, $toss);
    #($fita, $toss, $fitw, $toss) = split(" ", $$r_params{"fit$i"});
    $fite = ($$r_params{"fit_e$i"}) ? "guess" : "set  ";
    $fita = ($$r_params{"fit_a$i"}) ? "guess" : "set  ";
    $fitw = ($$r_params{"fit_w$i"}) ? "guess" : "set  ";
    $command .= "$fite p___eak_e$i = " . $$r_params{"e$i"} . "\n";
    $command .= "$fita p___eak_a$i = " . $$r_params{"a$i"} . "\n";
    $command .= "$fitw p___eak_w$i = " . $$r_params{"w$i"} . "\n";
    push @deltas, "p___eak_e$i",  "p___eak_a$i",  "p___eak_w$i";
    if ($this =~ /(gauss|loren|pvoight)/) { # peak function
      $command .= "def p___eak.peak$i = p___eak_a$i * $this($standard.eshift, p___eak_e$i, p___eak_w$i)\n";
    } else {			# extra step function
      my $ff = $$r_params{"f$i"};
      my $offset = "";
    SWITCH: {
	$offset = "/pi + 0.5", last SWITCH if ($ff eq 'atan');
	$offset = " + 1",      last SWITCH if ($ff eq 'erf');
      };
      $command .= "def p___eak.peak$i = p___eak_a$i * ($ff(($standard.eshift - p___eak_e$i)/p___eak_w$i)$offset)\n";
    };
    ## add this peak to the fitting function
    $function .= " + p___eak.peak$i";
    push @deflist, "p___eak.peak$i";
    ## save peak parameters to the data group
    $groups{$standard} -> MAKE("peak_e$i"=>$$r_params{"e$i"}, "peak_a$i"=>$$r_params{"a$i"},
			       "peak_w$i"=>$$r_params{"w$i"}, "peak_f$i"=>$$r_params{"f$i"},
			       "peak_function$i"=>$$r_params{"function$i"},
			       "peak_fit$i"=>$$r_params{"fit$i"},
			      );
  };

  ## make the residual array and then minimize
  $command .= $function . "\n";
  if ($do_fit) {
    $command .= "def p___eak.resid = $standard.$suff - p___eak.fun\n";
    $command .= "minimize(p___eak.resid, x=$standard.eshift, xmin=$emin, xmax=$emax)\n";
    push @deflist, "p___eak.resid";
  };
  $groups{$standard} -> dispose($command, $dmode);
  $$r_params{deltas} = \@deltas;
  $groups{$standard} -> dispose("## don't want to leave defs lying around...\n", $dmode);
  foreach my $f (@deflist) {
    $groups{$standard} -> dispose("set($f = $f)\n", $dmode);
  };

  ## store the results of the fit
  foreach my $p (qw(amp width)) {
    $widget{"peak_$p"} -> delete(qw(0 end));
    $$r_params{$p} = sprintf("%.3f", Ifeffit::get_scalar("p___eak_$p"));
    $widget{"peak_$p"} -> insert(0, $$r_params{$p});
  };
  foreach my $ipk (0 .. $#peaks) {
    my $i = $ipk+1;
    next unless ($peaks[$i] and ($$r_params{"e$i"}));
    foreach my $p (qw(e a w)) {
      $widget{"peak_$p$i"} -> delete(qw(0 end));
      $$r_params{"$p$i"} = sprintf("%.3f", Ifeffit::get_scalar("p___eak_$p$i"));
      $widget{"peak_$p$i"} -> insert(0, $$r_params{"$p$i"});
    };
  };
  ## plot the result
  $groups{$standard}->plotE('emn', $dmode, \%plot_features, \@indicator);
  my $fitcolor  = $config{plot}{c1};
  $groups{$standard}->dispose("plot($standard.eshift, p___eak.fun, key=fit, color=$fitcolor, style=lines)", $dmode);
  my $ic = 2;
  if ($$r_params{plot_components}) {
    unless ($widget{peak_function} eq 'None') {
      my $color = $config{plot}{c2};
      $groups{$standard}->dispose("plot($standard.eshift, p___eak.step, key=\"step\", style=lines, color=$color)", $dmode);
    };
    foreach my $ipk (0 .. $#peaks) {
      my $i  = $ipk+1;
      next unless ($peaks[$i] and ($$r_params{"e$i"}));
      ++$ic;
      my $color = $config{plot}{'c'.$ic};
      $groups{$standard}->dispose("plot($standard.eshift, p___eak.peak$i, key=\"peak $i\", style=lines, color=$color)", $dmode);
    };
  };
  if ($$r_params{plot_difference}) {
    ++$ic;
    my @e = Ifeffit::get_array("$standard.eshift");
    my @x = Ifeffit::get_array('p___eak.resid');
    my ($emin, $emax) = ($$r_params{enot}+$$r_params{emin},$$r_params{enot}+$$r_params{emax});
    foreach my $i (0 .. $#e) {
      ($x[$i] = 0) if (($e[$i] < $emin) or ($e[$i] > $emax));
    };
    Ifeffit::put_array('p___eak.diff', \@x);
    my $color = $config{plot}{'c'.$ic};
    $groups{$standard}->dispose("plot($standard.eshift, p___eak.diff, key=\"difference\", style=lines, color=$color)", $dmode);
  };
  $groups{$standard}->plot_vertical_line($emin, 0, $ymax, $dmode, "fit range",
					 $groups{$standard}->{plot_yoffset});
  $groups{$standard}->plot_vertical_line($emax, 0, $ymax, $dmode, "",
					 $groups{$standard}->{plot_yoffset});
  $$r_params{mark_centroids} and peak_mark_centroids($standard,$r_params,\@peaks);
  $last_plot='e';
  peak_fill_results($standard, $r_params, $peak_results, @peaks) if ($do_fit);
  $$r_params{peaks} = \@peaks;
  $top->Unbusy;
  Echo("Fitting near edge peak structure for \`$groups{$standard}->{label}\' ... done!");
};


sub peak_fill_results {
  my ($standard, $r_params, $peak_results, @peaks) = @_;
  $peak_results -> delete(qw(1.0 end));
  $peak_results -> insert('end', "Results of near edge peak fit to \"$groups{$standard}->{label}\"\n\n", 'text');
  $peak_results -> insert('end', "Fitting range = \[$$r_params{emin}:$$r_params{emax}\] (relative to centroid of step function)\n\n", 'text');

  my $suff = ($groups{$standard}->{bkg_flatten}) ? 'flat' : 'norm';
  my @e = Ifeffit::get_array("$standard.eshift");
  my @r = Ifeffit::get_array('p___eak.resid');
  my @x = Ifeffit::get_array("$standard.$suff");
  my ($emin, $emax) = ($$r_params{enot}+$$r_params{emin},$$r_params{enot}+$$r_params{emax});
  my ($rfactor, $sumsqr, $npts) = (0, 0, 0);
  foreach my $i (0 .. $#e) {
    if (($e[$i] > $emin) and ($e[$i] < $emax)) {
      ++$npts;
      $rfactor += $r[$i]**2;
      $sumsqr  += $x[$i]**2;
    };
  };
  my $chisqr = Ifeffit::get_scalar("chi_square");
  my $chinu  = Ifeffit::get_scalar("chi_reduced");
  my $nvarys = Ifeffit::get_scalar("n_varys");
  $peak_results -> insert('end', "Fit included $npts data points and $nvarys variables\n");
  $peak_results -> insert('end', sprintf("R-factor = %.5f, chi-square = %.5f, reduced chi-square = %.7f\n\n",
					 $rfactor/$sumsqr, $chisqr, $chinu), 'text');

  if ($$r_params{function} eq 'none') {
    $peak_results -> insert('end', "No step function was used\n", 'text');
    $peak_results -> insert('end', " function       centroid             amplitude        width\n", 'text');
  } else {
    $peak_results -> insert('end', " function       centroid             amplitude        width\n", 'text');
    $peak_results -> insert('end',
			    sprintf(" %-14s %8.2f(%8.2f) %6.3f(%6.3f) %6.3f(%6.3f)\n",
				    $$r_params{function_choice},
				    $$r_params{enot},  Ifeffit::get_scalar("delta_p___eak_e"),
				    $$r_params{amp},   Ifeffit::get_scalar("delta_p___eak_amp"),
				    $$r_params{width}, Ifeffit::get_scalar("delta_p___eak_width")),
			    'text');
  };
  foreach  my $ipk (0 .. $#peaks) {
    my $i = $ipk+1;
    next unless ($peaks[$i] and ($$r_params{"e$i"}));
    $peak_results -> insert('end',
			    sprintf(" %-14s %8.2f(%8.2f) %6.3f(%6.3f) %6.3f(%6.3f)\n",
				    $$r_params{"function$i"},
				    $$r_params{"e$i"}, Ifeffit::get_scalar("delta_p___eak_e$i"),
				    $$r_params{"a$i"}, Ifeffit::get_scalar("delta_p___eak_a$i"),
				    $$r_params{"w$i"}, Ifeffit::get_scalar("delta_p___eak_w$i")),
			    'text');
  };
  $peak_results -> insert('end', "\n\nThe Gaussians and Lorentzians are unit normalized,\nso the amplitudes are the areas.", 'text');
};


sub peak_fill_variables {
  my ($standard, $r_params, $r_peaks) = @_;
  $$r_params{enot}	  = $groups{$standard}->{peak_enot};
  $$r_params{amp}	  = $groups{$standard}->{peak_amp};
  $$r_params{width}	  = $groups{$standard}->{peak_width};
  $$r_params{function}	  = $groups{$standard}->{peak_function};
  $$r_params{function_choice} = $groups{$standard}->{peak_function_choice};
  $$r_params{fit_e}       = $groups{$standard}->{peak_fit_e}||0;
  $$r_params{fit_a}       = $groups{$standard}->{peak_fit_a}||1;
  $$r_params{fit_w}       = $groups{$standard}->{peak_fit_w}||1;

  ## yipes!  this counts the size of the dereferenced array
  foreach my $ipk (0 .. $#{@$r_peaks}) {
    my $i = $ipk+1;
    next unless ($groups{$standard}->{"peak_e$i"});
    $$r_params{"e$i"}	     = $groups{$standard}->{"peak_e$i"};
    $$r_params{"a$i"}	     = $groups{$standard}->{"peak_a$i"} || 0.3;
    $$r_params{"w$i"}	     = $groups{$standard}->{"peak_w$i"} || 1.0;
    $$r_params{"f$i"}	     = $groups{$standard}->{"peak_f$i"} || 'none';
    $$r_params{"function$i"} = $groups{$standard}->{"peak_function$i"} || 'none';
    $$r_params{"fit_e$i"}    = $groups{$standard}->{"peak_fit_e$i"};
    $$r_params{"fit_a$i"}    = $groups{$standard}->{"peak_fit_a$i"};
    $$r_params{"fit_w$i"}    = $groups{$standard}->{"peak_fit_w$i"};
    ($$r_params{"e$i"} and ($$r_params{"function$i"} ne 'none')) and ($$r_peaks[$i] = 1);
  };
};

sub peak_set_variable {
  my ($k, $entry, $prop) = (shift, shift, shift);
  ($entry =~ /^\s*$/) and ($entry = 0);	# error checking ...
  ($entry =~ /^\s*-$/) and return 1;	# error checking ...
  ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
};


sub peak_log {
  my ($standard, $peak_results, $r_params, @peaks) = @_;
  my $path = $current_data_dir || Cwd::cwd;
  my $types = [['Log files', '.log'], ['All files', '*']];
  my $initial = $groups{$standard}->{label}."_peak.log";
  ($initial =~ s/[\\:\/\*\?\'<>\|]/_/g);# if ($is_windows);
  my $file = $top ->
    getSaveFile(-filetypes=>$types,
		#(not $is_windows) ?
		#  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
		-initialdir=>$path,
		-initialfile=>$initial,
		-title => "Athena: Save peak fit log file");
  return unless $file;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  #&push_mru($file, 0);
  Echo("Saving log file from peak fit to \"$standard\" ...");

  my $command = q{};
  my $i = 0;
  foreach my $line (split(/\n/, $peak_results->get(qw(1.0 end)))) {
    ++$i;
    if ($line) {
      $command .= "set \$peak_title_$i = \"$line\"\n";
    } else {
      $command .= "set \$peak_title_$i = \".   \"\n";
    };
    if ($line =~ /^Results/) {
      ++$i;
      $command .= "set \$peak_title_$i = \"Titles from $groups{$standard}->{label}\"\n";
      foreach (@{$groups{$standard}->{titles}}) {
	++$i;
	$command .= "set \$peak_title_$i = \"  .  $_\"\n";
      };
    } elsif ($line =~ /^\s*function/) {
      ++$i;
      $command .= "set \$peak_title_$i = \"" . "=" x 60 . "\"\n";
    };
  };


  ++$i;
  $command .= "set \$peak_title_$i = \"Formulas:\"\n";
  ++$i;
  $command .= "set \$peak_title_$i = \"-  arctangent:       A*[atan((e-E0)/W)/pi + 0.5]\"\n";
  ++$i;
  $command .= "set \$peak_title_$i = \"-  error function:   A*[erf((e-E0)/W) + 1]\"\n";
  ++$i;
  $command .= "set \$peak_title_$i = \"-  Gaussian:         [A/(W*sqrt(2pi))] * exp[-(e-E0)^2/(2W^2)]\"\n";
  ++$i;
  $command .= "set \$peak_title_$i = \"-  Lorentzian:       (AW/2pi) / [(e-E0)^2 + (W/2)^2]\"\n";

  $command .= sprintf("set %s.ee = %s.energy + %f\n", $standard, $standard, $groups{$standard}->{bkg_eshift});

  my $peakstring = q{};
  my $ic = 0;
  foreach my $ipk (0 .. $#peaks) {
    my $i  = $ipk+1;
    next unless ($peaks[$i] and ($$r_params{"e$i"}));
    ++$ic;
    $peakstring .= ", p___eak.peak$ic";
  };
  $command .= "write_data(file=\"$file\", \$peak_title_\*, $standard.ee, $standard.xmu, p___eak.fun, p___eak.step$peakstring, p___eak.resid)\n";

  $groups{$standard}->dispose($command, $dmode);

  my $postcmd = q{};
  foreach my $j (1 .. $i) {
    $postcmd .= "erase \$peak_title_$j\n";
  };
  $groups{$standard}->dispose($postcmd, $dmode);

  Echo("Saving log file from peak fit to \"$groups{$standard}->{label}\" ... done!");
}


sub peak_mark_centroids {
  my ($standard, $r_params, $r_peaks) = @_;
  $$r_params{toplevel} -> Busy(-recurse=>1);
  my @list;
  push @list, $$r_params{enot} unless ($$r_params{function_choice} eq 'none');
  foreach my $ipk (0 .. $#{@$r_peaks}) {
    my $i = $ipk+1;
    push @list, $$r_params{"e$i"} if $$r_params{"e$i"};
  };

  my $string = "$config{plot}{marker}, $config{plot}{markercolor}, $groups{$standard}->{plot_yoffset}";
  my $command = "";
  foreach my $e (@list) {
    $command .= "pmarker \"$standard.energy+$groups{$standard}->{bkg_eshift}\", " .
      "p___eak.fun, $e, $string\n";
  };
  $groups{$standard} -> dispose($command, $dmode);
  $$r_params{toplevel} -> Unbusy
};




## END OF PEAK FITTING SUBSECTION
##########################################################################################
