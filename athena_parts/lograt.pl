
## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  log-ratio/phase-difference analysis


## missing features in the log-ratio interface:
##  -- widget for window functions


## pop-up a palette for performing log-ratio/phase-difference analysis
## between two scans
sub log_ratio {
  Echo("No data!"), return unless $current;
  my $color = $plot_features{c1};
  my %widg;
  my @cumul = (0, 0, 0, 0, 0);
  my @delta = (0, 0, 0, 0, 0);

  Echo("No data!"), return if ($current eq "Default Parameters");

  my @keys = ();
  foreach my $k (&sorted_group_list) {
    (($groups{$k}->{is_xmu}) or ($groups{$k}->{is_chi})) and push @keys, $k;
  };
  Echo("You need two or more xmu or chi groups to do log-ratio/phase-difference analysis"),
    return unless ($#keys >= 1);

  $widg{standard} = $keys[0];
  $widg{keys} = \@keys;
  my $standard_label = "1:".$groups{$widg{standard}}->{label};
  if ($widg{standard} eq $current) {	# make sure $current is sensible given
    set_properties(1, $keys[1], 0);     # that $keys[0] is the standard
    # adjust the view
    my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
    ($here < 0) and ($here = 0);
    my $full = ($list->bbox(@skinny_list))[3] + 5;
    $list -> yview('moveto', $here/$full);
  };
  $fat_showing = 'lograt';
  $hash_pointer = \%widg;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $lr = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$lr -> packPropagate(0);
  $which_showing = $lr;

  ## select the standard
  my $frame = $lr -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x');

  $frame -> Label(-text=>"Log-Ratio/Phase-Difference Analysis",
		  -font=>$config{fonts}{large},
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -columnspan=>2);

  $frame -> Label(-text=>"Standard: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>1, -column=>0, -sticky=>'e', -pady=>2);

  $widget{lr_menu} = $frame -> BrowseEntry(-variable => \$standard_label,
					   @browseentry_list,
					   -browsecmd => sub {
					     my $text = $_[1];
					     my $this = $1 if ($text =~ /^(\d+):/);
					     Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless $this;
					     $this -= 1;
					     $widg{standard}=$widg{keys}->[$this];
					     #$standard_lab="$groups{$s}->{label} ($s)";
					     &reset_lr_data(\%widg, $widg{standard}, $current);
					     @cumul = (1, 0, 0, 0, 0);
					   })
    -> grid(-row=>1, -column=>1, -sticky=>'w', -pady=>2);
  my $i = 1;
  foreach my $s (@keys) {
    $widget{lr_menu} -> insert("end", "$i: $groups{$s}->{label}");
    ++$i;
  };


  ## select the unknown group
  $frame -> Label(-text=>"Unknown: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>2, -column=>0, -sticky=>'e', -pady=>2);
  $widget{lr_unknown} = $frame -> Label(-text=>$groups{$current}->{label},
					-foreground=>$config{colors}{button})
    -> grid(-row=>2, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);

  $lr -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');
  $lr -> Button(-text=>'Return to the main window',  @button_list,
		-background=>$config{colors}{background2},
		-activebackground=>$config{colors}{activebackground2},
		-command=>sub{$groups{$current}->dispose("clean_lograt", $dmode);
			      &reset_window($lr, "log-ratio analysis", 0);
			      set_properties(1, $current, 0);
			    })
    -> pack(-side=>'bottom', -fill=>'x');

  ## help button
  $lr -> Button(-text=>'Document section: log ratio/phase difference analysis', @button_list,
		-command=>sub{pod_display("analysis::lr.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  ## frame with fit params
  $frame = $lr -> LabFrame(-label      => 'Fourier transform and fitting parameters',
			   -foreground => $config{colors}{activehighlightcolor},
			   -labelside  => 'acrosstop')
    -> pack(-fill=>'x', -padx=>3);

  $frame -> Label(-text=>"k-range of FT:  ",
		 )
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widget{lr_kmin} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				     -validate=>'key',
				     -validatecommand=>[\&set_lr_variable, 'lr_kmin']
				    )
    -> grid(-row=>0, -column=>1);
  $grab{lr_kmin} = $frame -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'lr_kmin'])
    -> grid(-row=>0, -column=>2);
  $frame -> Label(-text=>" :   ")
    -> grid(-row=>0, -column=>3);
  $widget{lr_kmax} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				     -validate=>'key',
				     -validatecommand=>[\&set_lr_variable, 'lr_kmax']
				    )
    -> grid(-row=>0, -column=>4);
  $grab{lr_kmax} = $frame -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'lr_kmax'])
    -> grid(-row=>0, -column=>5);

  $frame -> Label(-text=>"k-weight:  ",
		 )
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $widget{lr_kw} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				   -validate=>'key',
				   -validatecommand=>[\&set_lr_variable, 'lr_kw']
				  )
    -> grid(-row=>1, -column=>1);
  $frame -> Label(-text=>"dk:  ",
		 )
    -> grid(-row=>1, -column=>3, -sticky=>'e');
  $widget{lr_dk} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				   -validate=>'key',
				   -validatecommand=>[\&set_lr_variable, 'lr_dk']
				  )
    -> grid(-row=>1, -column=>4);

  $frame -> Label(-text=>"R-range of BFT:  ",
		 )
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $widget{lr_rmin} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				     -validate=>'key',
				     -validatecommand=>[\&set_lr_variable, 'lr_rmin']
				    )
    -> grid(-row=>2, -column=>1);
  $grab{lr_rmin} = $frame -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'lr_rmin'])
    -> grid(-row=>2, -column=>2);
  $frame -> Label(-text=>" :   ")
    -> grid(-row=>2, -column=>3,);
  $widget{lr_rmax} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				     -validate=>'key',
				     -validatecommand=>[\&set_lr_variable, 'lr_rmax']
				    )
    -> grid(-row=>2, -column=>4);
  $grab{lr_rmax} = $frame -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'lr_rmax'])
    -> grid(-row=>2, -column=>5);

  $frame -> Label(-text=>"2pi jump:  ",
		 )
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $widget{lr_npi} = $frame -> NumEntry(-width=>4, -orient=>'horizontal',
				       -foreground=>$config{colors}{foreground})
    -> grid(-row=>3, -column=>1, -sticky=>'w');
  $frame -> Label(-text=>"dr:  ",
		 )
    -> grid(-row=>3, -column=>3, -sticky=>'e');
  $widget{lr_dr} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				   -validate=>'key',
				   -validatecommand=>[\&set_lr_variable, 'lr_dr']
				  )
    -> grid(-row=>3, -column=>4, -sticky=>'w');

  $frame -> Label(-text=>"k-range of fit:  ",
		 )
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $widget{lr_fmin} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				     -validate=>'key',
				     -validatecommand=>[\&set_lr_variable, 'lr_fmin']
				    )
    -> grid(-row=>4, -column=>1);
  $grab{lr_fmin} = $frame -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'lr_fmin'])
    -> grid(-row=>4, -column=>2);
  $frame -> Label(-text=>" :   ")
    -> grid(-row=>4, -column=>3,);
  $widget{lr_fmax} = $frame -> Entry(-width=>8, -font=>$config{fonts}{entry},
				     -validate=>'key',
				     -validatecommand=>[\&set_lr_variable, 'lr_fmax']
				    )
    -> grid(-row=>4, -column=>4);
  $grab{lr_fmax} = $frame -> Button(@pluck_button, @pluck, -command=>[\&pluck, 'lr_fmax'])
    -> grid(-row=>4, -column=>5);

  ##   $frame -> Label(-text=>"window function:")
  ##     -> grid(-row=>5, -column=>0, -sticky=>'e');
  ##   $widget{lr_win} = $frame -> Optionmenu(-font=>$config{fonts}{small},
  ## 					 -textvariable => \$menus{fft_win},)
  ##     -> grid(-row=>5, -column=>1, -columnspan=>4, -sticky=>'w');
  ##   foreach my $i ($setup->Windows) {
  ##     $widget{lr_win} -> command(-label => $i,
  ## 			       -command=>sub{$menus{fft_win}=$i;
  ## 					     project_state(0);
  ## 					     $groups{$current}->make(fft_win=>$i,
  ## 								     update_fft=>1)});
  ##   };

  ## frame with fit button
  $frame = $lr -> Frame(-borderwidth=>0, -relief=>'flat')
    -> pack(-fill=>'x', -padx=>3, -pady=>2, -ipadx=>2, -ipady=>2);

  $widget{lr_fit} =
  $frame -> Button(-text=>'Fit',  @button_list,
		   -command=>sub{my $ok = &do_lr_fit($widg{standard}, $current);
				 return unless $ok;
				 ## post cumulant values;
				 @cumul[0..2] =
				   map {sprintf("%.5f", Ifeffit::get_scalar("___c" . $_))}
				     (0 .. 2);
				 @cumul[3..4] =
				   map {sprintf("%.8f", Ifeffit::get_scalar("___c" . $_))}
				     (3 .. 4);
				 @delta[0..2] =
				   map {sprintf("%.5f", Ifeffit::get_scalar("delta____c" . $_))}
				     (0 .. 2);
				 @delta[3..4] =
				   map {sprintf("%.8f", Ifeffit::get_scalar("delta____c" . $_))}
				     (3 .. 4);
				 $widg{l0} ->
				   configure(-text=>sprintf("%.5f +/- %.5f",
							    exp($cumul[0]),
							    $delta[0]*exp($cumul[0])));
				 map {$widg{"l".$_} ->
					configure(-text=>"$cumul[$_] +/- $delta[$_]")} (1..4);
				 map {$widget{'lr_'.$_}->configure(-state=>'normal')} (qw(lr pd save log));
			       })
    -> pack(-expand=>1, -fill=>'x');


  ## frame with plot buttons
  $frame = $lr -> LabFrame(-label      => 'Plot standard and unknown in',
			   -foreground => $config{colors}{activehighlightcolor},
			   -labelside  => 'acrosstop')
    -> pack(-side=>'bottom', -fill=>'x', -padx=>3, -pady=>2, -ipadx=>2, -ipady=>2);

  $widget{lr_plotk} =
  $frame -> Button(-text=>'k',  @button_list,
		   -command=>sub{
		     $groups{$widg{standard}}->plot_marked($plot_features{k_w}, $dmode, \%groups,
							   {$widg{standard}=>1, $current=>1},
							   \%plot_features, $list, \@indicator);
		     $last_plot='k';
		     $last_plot_params = [$current, 'marked', 'k', $plot_features{k_w}];
		     $groups{$widg{standard}}->plot_window(0, 'k', $dmode, $config{plot}{c2}, \%plot_features);
		     map { $grab{$_} -> configure(-state=>'normal') }
		       (qw(lr_kmin lr_kmax lr_fmin lr_fmax));
		     map { $grab{$_} -> configure(-state=>'disabled') }
		       (qw(lr_rmin lr_rmax));
		     })
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $widget{lr_plotr} =
  $frame -> Button(-text=>'R',  @button_list,
		   -command=>sub{
		     $groups{$widg{standard}}->plot_marked($plot_features{r_marked}, $dmode, \%groups,
							   {$widg{standard}=>1, $current=>1},
							   \%plot_features, $list, \@indicator);
		     $last_plot='r';
		     $last_plot_params = [$current, 'marked', 'r', $plot_features{r_marked}];
		     $groups{$widg{standard}}->plot_window(0, 'r', $dmode, $config{plot}{c2}, \%plot_features);
		     map { $grab{$_} -> configure(-state=>'disabled') }
		       (qw(lr_kmin lr_kmax lr_fmin lr_fmax));
		     map { $grab{$_} -> configure(-state=>'normal') }
		       (qw(lr_rmin lr_rmax));
		   })
    -> pack(-side=>'left', -expand=>1, -fill=>'x');
  $widget{lr_plotq} =
  $frame -> Button(-text=>'q',  @button_list,
		   -command=>sub{
		     $groups{$widg{standard}}->plot_marked($plot_features{q_marked}, $dmode, \%groups,
							   {$widg{standard}=>1, $current=>1},
							   \%plot_features, $list, \@indicator);
		     $last_plot='q';
		     $last_plot_params = [$current, 'marked', 'q', $plot_features{q_marked}];
		     $groups{$widg{standard}}->plot_window(0, 'q', $dmode, $config{plot}{c2}, \%plot_features);
		     map { $grab{$_} -> configure(-state=>'normal') }
		       (qw(lr_kmin lr_kmax lr_fmin lr_fmax));
		     map { $grab{$_} -> configure(-state=>'disabled') }
		       (qw(lr_rmin lr_rmax));
		   })
    -> pack(-side=>'left', -expand=>1, -fill=>'x');


  ## frame with plot buttons for results
  $frame = $lr -> Frame(-borderwidth=>0, -relief=>'flat')
    -> pack(-side=>'bottom', -fill=>'x', -padx=>3, -pady=>2);

  $widget{lr_save} = $frame -> Button(-text=>'Save ratio data & fit',  @button_list,
				      -command=>sub{&save_lr_fit($widg{standard}, \@cumul, \@delta)},
				      -width=>1,
				      -state=>'disabled')
    -> pack(-expand=>1, -fill=>'x', -side=>'left');
  $widget{lr_log} = $frame -> Button(-text=>'Write log file',  @button_list,
				     -command=>sub{
				       my $types = [['Log-ratio fit logs', '.lr_log'], ['All Files', '*']];
				       my $path = $current_data_dir || Cwd::cwd;
				       my $initial = $groups{$current}->{label} . ".lr_log";
				       ($initial =~ s/[\\:\/\*\?\'<>\|]/_/g); # if ($is_windows);
				       my $file = $top ->
					 getSaveFile(-filetypes=>$types,
						     #(not $is_windows) ?
						     #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
						     -initialdir=>$path,
						     -initialfile=>$initial,
						     -title => "Athena: Save log-ratio log file");
				       return unless $file;
				       my ($name, $pth, $suffix) = fileparse($file);
				       $current_data_dir = $pth;
				       open LOG, ">".$file or do {
					 Error("You cannot write a log to \"$file\"."); return
				       };
				       print LOG &lr_log($widg{standard}, \@cumul, \@delta);
				       close LOG;
				     },
				     -width=>1,
				     -state=>'disabled')
    -> pack(-expand=>1, -fill=>'x', -side=>'left');


  ## frame with plot buttons for results
  $frame = $lr -> Frame(-borderwidth=>0, -relief=>'flat')
    -> pack(-side=>'bottom', -fill=>'x', -padx=>3, -pady=>2);

  $widget{lr_lr} = $frame -> Button(-text=>'Plot log-ratio + fit',  @button_list,
				    -command=>sub{
				      my ($qmin, $qmax) =
					($widget{lr_fmin}->get(), $widget{lr_fmax}->get()+1);
				      $groups{$widg{standard}} ->
					dispose("plot_lograt $widg{standard} \"$groups{$widg{standard}}->{label}\" \"$groups{$current}->{label}\" $qmax", $dmode);
				      $last_plot='q';
				      map { $grab{$_} -> configure(-state=>'normal') }
					(qw(lr_kmin lr_kmax lr_fmin lr_fmax));
				      map { $grab{$_} -> configure(-state=>'disabled') }
					(qw(lr_rmin lr_rmax));
				    },
				    -width=>1,
				    -state=>'disabled')
    -> pack(-expand=>1, -fill=>'x', -side=>'left');
  $widget{lr_pd} = $frame -> Button(-text=>'Plot phase-difference + fit',  @button_list,
				    -command=>sub{
				      my ($qmin, $qmax) =
					($widget{lr_fmin}->get(), $widget{lr_fmax}->get()+1);
				      $groups{$widg{standard}} ->
					dispose("plot_phdiff $widg{standard} \"$groups{$widg{standard}}->{label}\" \"$groups{$current}->{label}\" $qmax", $dmode);
				      $last_plot='q';
				      map { $grab{$_} -> configure(-state=>'normal') }
					(qw(lr_kmin lr_kmax lr_fmin lr_fmax));
				      map { $grab{$_} -> configure(-state=>'disabled') }
					(qw(lr_rmin lr_rmax));
				    },
				    -width=>1,
				    -state=>'disabled')
    -> pack(-expand=>1, -fill=>'x', -side=>'left');

  ## frame with results
  $frame = $lr -> LabFrame(-label      => 'Fit Results',
			   -foreground => $config{colors}{activehighlightcolor},
			   -labelside  => 'acrosstop')
    -> pack(-fill=>'x', -padx=>3);
  $frame -> Label(-text=>"Zeroth: ", -foreground=>$config{colors}{highlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widg{l0} = $frame -> Label(-text=>exp($cumul[0]),)
    -> grid(-row=>0, -column=>1, -sticky=>'w');
  $frame -> Label(-text=>"First: ", -foreground=>$config{colors}{highlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $widg{l1} = $frame -> Label(-text=>$cumul[1],)
    -> grid(-row=>1, -column=>1, -sticky=>'w');
  $frame -> Label(-text=>"Second: ", -foreground=>$config{colors}{highlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $widg{l2} = $frame -> Label(-text=>$cumul[2],)
    -> grid(-row=>2, -column=>1, -sticky=>'w');
  $frame -> Label(-text=>"     ", -foreground=>$config{colors}{highlightcolor})
    -> grid(-row=>1, -column=>2, -sticky=>'e');
  $frame -> Label(-text=>"Third: ", -foreground=>$config{colors}{highlightcolor})
    -> grid(-row=>1, -column=>3, -sticky=>'e');
  $widg{l3} = $frame -> Label(-text=>$cumul[3],)
    -> grid(-row=>1, -column=>4, -sticky=>'w');
  $frame -> Label(-text=>"Fourth: ", -foreground=>$config{colors}{highlightcolor})
    -> grid(-row=>2, -column=>3, -sticky=>'e');
  $widg{l4} = $frame -> Label(-text=>$cumul[4],)
    -> grid(-row=>2, -column=>4, -sticky=>'w');

  ## set initial data
  &reset_lr_data(\%widg, $widg{standard}, $current);
  foreach my $widg (qw(lr_fmin lr_fmax)) {
    $widget{$widg} -> configure(-validate=>'none');
    $widget{$widg} -> delete(qw/0 end/);
    $widget{$widg} -> insert(0, ($widg =~ /n$/) ? 3 : 12);
    $widget{$widg} -> configure(-validate=>'key');
  };

  Echo("Reminder: Data should be aligned BEFORE doing log-ratio analysis.");
  $plotsel -> raise('k');
  $top -> update;
};


sub set_lr_variable {
  my ($k, $entry, $prop) = (shift, shift, shift);
  ($entry =~ /^\s*$/) and ($entry = 0);	# error checking ...
  ($entry =~ /^\s*-$/) and return 1;	# error checking ...
  ($entry =~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) or return 0;
  return 1;
};

sub do_lr_fit {
  my ($standard, $other) = @_;

  ## some error checking
  Error("Log-ratio fit aborted: You selected the same data group as standard and unknown."),
    return 0 if ($standard eq $other);
  Error("Log-ratio fit aborted: " . $groups{$other}->{label} . " is not an xmu or chi group."),
    return 0 unless (($groups{$other}->{is_xmu}) or ($groups{$other}->{is_chi}));

  Echo("Doing log-ratio/phase-difference fit ...");
  $top -> Busy;
  ## set standard and unknown FT param values
  foreach my $k (qw(kmin kmax kw dk rmin rmax dr)){
    my $widg = "lr_$k";
    my $key = ($k =~ /r/) ? "bft_$k" : "fft_$k";
    $groups{$standard}->make($key => $widget{$widg}->get());
    $groups{$other}->make($key => $widget{$widg}->get());
  };
  ## bring both up to date in q-space
  $groups{$standard}->do_fft($dmode, \%plot_features);
  $groups{$standard}->do_bft($dmode);
  $groups{$other}->do_fft($dmode, \%plot_features);
  $groups{$other}->do_bft($dmode);
  ## call LR/PD fit macro
  my ($qmin, $qmax, $npi) = ($widget{lr_fmin}->get(), $widget{lr_fmax}->get(),
			     $widget{lr_npi}->get(), );
  $groups{$standard}-> dispose("do_lograt $standard $other $qmin $qmax $npi", $dmode);
  ## plot phase diff
  $qmax += 1;
  $groups{$standard} ->
    dispose("plot_lograt $standard \"$groups{$standard}->{label}\" \"$groups{$current}->{label}\" $qmax", $dmode);
  $last_plot='q';
  $top -> Unbusy;
  Echo("Doing log-ratio/phase-difference fit ... done!");
  1;
};

sub save_lr_fit {
  my ($standard, $r_c, $r_d) = @_;
  my $types = [['Log ratio fits', '.lr'], ['All Files', '*'],];
  my $path = $current_data_dir || Cwd::cwd;
  my $initial = $groups{$current}->{label} . ".lr";
  ($initial =~ s/[\\:\/\*\?\'<>\|]/_/g);# if ($is_windows);
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$initial,
				 -title => "Athena: Save log-ratio fit");
  return unless $file;
  ## make sure I can write to $file
  open F, ">".$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  close F;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  my $titles = &lr_log($standard, $r_c, $r_d);
  my $i = 0;
  foreach my $t (split(/\n/, $titles)) {
    next if ($t =~ /^\s*$/);
    ++$i;
    Ifeffit::put_string("\$l___r_title_$i", $t);
  };
  my $command = "write_data(file=\"$file\", ";
  $command   .= "           \$l___r_title_*, $standard.q, ___c.ratio, ___c.even, ___c.diff, ___c.odd)";
  $groups{$standard} -> dispose($command, $dmode);
  foreach (1 .. $i) {
    $groups{$standard} -> dispose("erase \$l___r_title_$_", $dmode);
  };
};

sub lr_log {
  my ($standard, $r_c, $r_d) = @_;
  my $string = "Log-ratio/phase-difference between " . $groups{$current}->{label} .
    " (the unknown)\n";
  $string .= "and " . $groups{$standard}->{label} . " (the standard)\n\n";
  $string .= sprintf("Zeroth cumulant = %.5f +/- %.5f\n",  exp($$r_c[0]), $$r_d[0]*exp($$r_c[0]));
  $string .= "First cumulant  = $$r_c[1] +/- $$r_d[1]\n";
  $string .= "Second cumulant = $$r_c[2] +/- $$r_d[2]\n";
  $string .= "Third cumulant  = $$r_c[3] +/- $$r_d[3]\n";
  $string .= "Fourth cumulant = $$r_c[4] +/- $$r_d[4]\n\n";
  $string .= sprintf("Forward FT parameters: [%.2f:%.2f], dk=%.2f, kw=%s\n",
		     $widget{lr_kmin}->get,
		     $widget{lr_kmax}->get,
		     $widget{lr_dk}->get,
		     $widget{lr_kw}->get, );
  $string .= sprintf("Backward FT parameters: [%.2f:%.2f]  dr=%.2f\n",
		     $widget{lr_rmin}->get,
		     $widget{lr_rmax}->get,
		     $widget{lr_dr}->get,);
  $string .= sprintf("Fitting range in q: [%.2f:%.2f]\n",
		     $widget{lr_fmin}->get,
		     $widget{lr_fmax}->get,);
  return $string;
};

sub reset_lr_data {
  my ($r_widg, $standard, $other) = @_;
  ## reset plot buttons
  map {$widget{'lr_'.$_}->configure(-state=>'disabled')} (qw(lr pd save log));
  ## plot new data
  $groups{$standard}->plot_marked($plot_features{k_w}, $dmode, \%groups,
				  {$standard=>1, $other=>1}, \%plot_features, $list, \@indicator);
  $last_plot='k';
  $last_plot_params = [$current, 'marked', 'k', $plot_features{k_w}];
  $groups{$standard}->plot_window(0, 'k', $dmode, $config{plot}{c2}, \%plot_features);
  ## enable/disable pluck buttons for k
  map { $grab{$_} -> configure(-state=>'normal') }
    (qw(lr_kmin lr_kmax lr_fmin lr_fmax));
  map { $grab{$_} -> configure(-state=>'disabled') }
    (qw(lr_rmin lr_rmax));
  ## reset FT params
  foreach my $k (qw(kmin kmax kw dk rmin rmax dr)){
    my $widg = "lr_$k";
    my $key = ($k =~ /r/) ? "bft_$k" : "fft_$k";
    $widget{$widg} -> configure(-validate=>'none');
    $widget{$widg} -> delete(qw/0 end/);
    $widget{$widg} -> insert(0, $groups{$standard}->{$key});
    $widget{$widg} -> configure(-validate=>'key');
  };
  ## $widget{lr_win} ->
  ## reset cumulants
  my @cumul = (1, 0, 0, 0, 0);
  map {$$r_widg{"l".$_}->configure(-text=>$cumul[$_])} (0 .. 4);
};



## END OF LOG-RATIO/PHASE_DIFFERENCE SUBSECTION
##########################################################################################
