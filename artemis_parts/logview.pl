# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##

###===================================================================
### log viewer subsystem
###===================================================================

sub logviewer {

  #Echo("You can only look at the log viewer when the data, feff, path or gsd views are showing"),
  #  return unless ($current_canvas =~ /(feff|gsd|path|op)/);
  %log_params = (param	     => 'Statistical parameters',
		 absorber    => '',
		 scatterer   => '',
		 is_einstein => 0,
		 average     => 0,
		 force	     => 0,
		 zero        => 0,
		 prefer      => $config{logview}{prefer});

  my $logview = $_[0] -> Frame(-relief=>'flat',
			       #@window_size,
			       -borderwidth=>0,
			       -highlightcolor=>$config{colors}{background});

  my $fr = $logview -> Frame(-background  => $config{colors}{background2},
			  -borderwidth => 2,
			  -relief      => 'groove',
			 )
    -> pack(-padx=>0, -pady=>0, -fill=>'x');
  $fr -> Label(-text=>"Examine log files", @title2, -background  => $config{colors}{background2},)
    -> pack(-side=>'left', -anchor=>'w', -padx=>6);
##   $widgets{log_latest} = $fr -> Label(-text=>'',
## 				      -font=>$config{fonts}{bold},
## 				      -foreground=>$config{colors}{foreground},
## 				      -background  => $config{colors}{background2})
##     -> pack(-side=>'right', -anchor=>'w', -padx=>6);
  $widgets{log_current} = $fr -> Label(-text=>'',
				       -font=>$config{fonts}{bold},
				       -foreground=>$config{colors}{foreground},
				       -background  => $config{colors}{background2},)
    -> pack(-side=>'right', -anchor=>'w', -padx=>6);
   $fr -> Label(-text=>'Current fit:',
		-font=>$config{fonts}{bold},
		-foreground=>$config{colors}{button},
		-background  => $config{colors}{background2},)
    -> pack(-side=>'right', -anchor=>'w', -padx=>0);
  $fr -> Label(-text=>'Displaying:',
	       -font=>$config{fonts}{bold},
	       -foreground=>$config{colors}{button});
  ##  -> pack(-side=>'right', -anchor=>'w', -padx=>0);

  my $lfr = $logview -> LabFrame(-label=>'Fits', -labelside=>'acrosstop',
				 -width=>14)
    -> pack(-side=>'left', -fill=>'y');

  $widgets{loglistbox} = $lfr -> Scrolled('HList',
					  -scrollbars	    => 'osoe',
					  -background	    => 'white',
					  -selectmode	    => 'extended',
					  -selectbackground => $config{colors}{selected},
					  -cursor           => $mouse_over_cursor,
					  -command	    =>
					  sub{
					    #&display_file('', $widgets{loglistbox}->infoData($widgets{loglistbox}->infoSelection))
					    logview_show($config{log}{style});
					  },
			     )
    -> pack(-side=>'top', -expand=>1, -fill=>'both');
  $widgets{loglistbox}->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
  $widgets{loglistbox}->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
  $widgets{loglistbox}->bind('<ButtonPress-3>',\&logview_post_menu);
  BindMouseWheel($widgets{loglistbox});

  $widgets{log_select} = $lfr -> Button(-text=>'Select all',
					@button2_list,)
    -> pack(-side=>'top', -fill=>'x');
  $lfr -> Button(-text=>'Clear selection',
		 @button2_list,
		 -command=>sub{$widgets{loglistbox}->selectionClear();
			       $widgets{loglistbox}->anchorClear();})
    -> pack(-side=>'top', -fill=>'x');


  my $right = $logview -> Frame()
    -> pack(-side=>'right', -fill=>'both', -expand=>1);

  $lfr = $right -> LabFrame(-label=>'Choose a parameter', -labelside=>'acrosstop',)
    -> pack(-side=>'top', -fill=>'x');
  $widgets{log_param_list} = $lfr -> BrowseEntry(-font=>$config{fonts}{med},
						 (($is_windows) ? () :
						  (-disabledforeground => $config{colors}{foreground},
						   -state => 'readonly')),
						 -width=>25,
						 -variable=>\$log_params{param},
						 -browsecmd=>\&logview_write_report,
						)
    -> pack(-padx=>1, -pady=>1, -fill=>'x');
  $lfr -> Button(-text=>'Get parameters from Guess, Def, Set list',
		 @button2_list,
		 -command=>sub{&logview_param_list('gds')})
    -> pack(-padx=>1, -pady=>1, -fill=>'x');

  $widgets{log_write} = $right ->
    Button(-text=>'Parameter report',  @button2_list,
	   -command=>\&logview_write_report )
    -> pack(-side=>'top', -fill=>'x', -pady=>2, -padx=>3);

  $lfr = $right -> LabFrame(-label=>'Calculations', -labelside=>'acrosstop',)
    -> pack(-side=>'top', -fill=>'x', -pady=>3);
  $widgets{log_av} =
    $lfr -> Checkbutton(-text=>'Compute the average value',
			-selectcolor=>$config{colors}{check},
			-foreground=>$config{colors}{activehighlightcolor},
			-activeforeground=>$config{colors}{activehighlightcolor},
			-variable=>\$log_params{average},
			-onvalue=>1, -offvalue=>0, -anchor=>'w',
			-command=>sub{
			  if ($log_params{einstein}) {
			    $widgets{log_ei} -> deselect;
			    $widgets{log_al} -> configure(-foreground => ($log_params{einstein}) ?
							  $config{colors}{activehighlightcolor} :
							  $config{colors}{disabledforeground});
			    $widgets{log_sl} -> configure(-foreground => ($log_params{einstein}) ?
							  $config{colors}{activehighlightcolor} :
							  $config{colors}{disabledforeground});
			    $widgets{log_ae} -> configure(-state => ($log_params{einstein}) ?
							  'normal' : 'disabled');
			    $widgets{log_se} -> configure(-state => ($log_params{einstein}) ?
							  'normal' : 'disabled');
			  };
			})
    -> pack(-padx=>1, -pady=>1, -fill=>'x');
  $widgets{log_ei} =
    $lfr -> Checkbutton(-text=>'Fit Einstein temp. to sigma^2 values',
			-selectcolor=>$config{colors}{check},
			-foreground=>$config{colors}{activehighlightcolor},
			-activeforeground=>$config{colors}{activehighlightcolor},
			-variable=>\$log_params{einstein},
			-onvalue=>1, -offvalue=>0, -anchor=>'w',
			-command=>sub{
			  $widgets{log_av} -> deselect if $log_params{average};
			  $widgets{log_al} -> configure(-foreground => ($log_params{einstein}) ?
							$config{colors}{activehighlightcolor} :
							$config{colors}{disabledforeground});
			  $widgets{log_sl} -> configure(-foreground => ($log_params{einstein}) ?
							$config{colors}{activehighlightcolor} :
							$config{colors}{disabledforeground});
			  $widgets{log_ae} -> configure(-state => ($log_params{einstein}) ?
							'normal' : 'disabled');
			  $widgets{log_se} -> configure(-state => ($log_params{einstein}) ?
							'normal' : 'disabled');
			})
      -> pack(-padx=>1, -pady=>1, -fill=>'x');
  $fr = $lfr -> Frame()
    -> pack(-padx=>1, -pady=>1, -fill=>'x');
  $widgets{log_al} = $fr -> Label(-text=>'Absorber: ', -foreground=>$config{colors}{disabledforeground})
    -> pack(-side=>'left', -expand=>1);
  $widgets{log_ae} = $fr -> Entry(-width=>3, -textvariable=>\$log_params{absorber}, -state=>'disabled')
    -> pack(-side=>'left', -expand=>1);
  $widgets{log_sl} = $fr -> Label(-text=>'Scatterer: ', -foreground=>$config{colors}{disabledforeground})
    -> pack(-side=>'left', -expand=>1);
  $widgets{log_se} = $fr -> Entry(-width=>3, -textvariable=>\$log_params{scatterer}, -state=>'disabled')
    -> pack(-side=>'left', -expand=>1);

  $lfr -> Frame(-borderwidth=>2, -relief=>'sunken', -height=>2)
    -> pack(-side=>'top', -pady=>4, -padx=>8, -fill=>'x');

  $widgets{log_rfactor} = $lfr -> Radiobutton(-text	        => "Prefer R-factor",
					      -variable	        => \$log_params{prefer},
					      -value	        => 'rfactor',
					      -selectcolor      => $config{colors}{check},
					      -foreground       => $config{colors}{activehighlightcolor},
					      -activeforeground => $config{colors}{activehighlightcolor},
					      -state            => 'disabled',
					      -command          => sub{$log_params{param} = 'Statistical parameters';
								       &logview_write_report;
								       &logview_plot},
					     )
    -> pack(-side=>'top', -expand=>1, -anchor=>'w');
  $widgets{log_chinu} = $lfr -> Radiobutton(-text	      => "Prefer reduced chi-square",
					    -variable	      => \$log_params{prefer},
					    -value	      => 'chinu',
					    -selectcolor      => $config{colors}{check},
					    -foreground       => $config{colors}{activehighlightcolor},
					    -activeforeground => $config{colors}{activehighlightcolor},
					    -state            => 'disabled',
					    -command          => sub{$log_params{param} = 'Statistical parameters';
								     &logview_write_report;
								     &logview_plot},
					   )
    -> pack(-side=>'top', -expand=>1, -anchor=>'w');

  $lfr -> Frame(-borderwidth=>2, -relief=>'sunken', -height=>2)
    -> pack(-side=>'top', -pady=>4, -padx=>8, -fill=>'x');

  $widgets{log_zero} = $lfr -> Checkbutton(-text	     => "Show y=0 in plot",
					   -variable	     => \$log_params{zero},
					   -onvalue          =>1,
					   -offvalue         =>0,
					   -anchor           =>'w',
					   -selectcolor      => $config{colors}{check},
					   -foreground       => $config{colors}{activehighlightcolor},
					   -activeforeground => $config{colors}{activehighlightcolor},
					   -command          => sub{&logview_write_report;
								    &logview_plot},
					   )
    -> pack(-side=>'top', -expand=>1, -anchor=>'w');

  ##$widgets{log_plot}  = $right ->
  ##  Button(-text=>'Plot report',  @button2_list, -state=>'disabled',
  ##	   -command=>\&logview_plot )
  ##    -> pack(-side=>'top', -fill=>'x', -pady=>2);
  ##$fr = $right -> Frame()
  ##  -> pack(-side=>'top', -fill=>'x', -pady=>2);

  $widgets{log_summaries} = $right ->
    Button(-text=>'Quick summaries of selected fits', @button2_list,
	   -command=>\&logview_quick_summary )
    -> pack(-side=>'top', -fill=>'x', -pady=>12, -padx=>3);



  $widgets{help_logview} =
    $right -> Button(-text=>'Document: Log viewer',  @button2_list,
		     -command=>sub{pod_display("artemis_logview.pod")} )
      -> pack(-side=>'bottom', -fill=>'x', -pady=>2);


  return $logview;
};



sub populate_logview {
  ## --- fill the HList with fit labels
  opendir F, File::Spec->catfile($project_folder, "fits");
  my @fits = sort( grep {/fit\d+/ and -d  File::Spec->catfile($project_folder, "fits", $_)} readdir(F) );
  closedir F;
  $widgets{loglistbox} -> delete('all');
  my @which;
  my $count = 0;
  foreach my $f (@fits) {
    local $| = 1;
    next unless -e File::Spec->catfile($project_folder, "fits", $f, 'label');
    open LL, File::Spec->catfile($project_folder, "fits", $f, 'label');
    my $label = <LL>;
    close LL;
    push(@which, $count) if ($f eq $fits[0]);
    push(@which, $count) if ($f eq $fits[-1]);
    my $add = 1;
    foreach my $p (keys %paths) {
      next unless ($paths{$p}->type eq 'fit');
      next unless  $paths{$p}->get('parent');
      next unless ($paths{$p}->get('folder') eq $f);
      $add = 0 if  $list -> info('hidden',$p);
      $add = 1 if ($list->getmode($paths{$p}->get('parent')) eq 'open');
      last;
    };
    ## don't add if this one is hidden
    if ($add) {
      $widgets{loglistbox}
	-> add($count,
	       -itemtype => 'text',
	       -text     => $label,
	       -data     => File::Spec->catfile($project_folder, "fits", $f, "log"));
      ++$count;
    };
  };
  ## --- set the callback on the "select all" button
  $widgets{log_select} -> configure(-command=>sub{$widgets{loglistbox}->selectionSet(@which)});
  ## --- fill the list of parameters
  logview_param_list('gds');
  ## --- disable write button if there are no unhidden fits
  $widgets{log_write}     -> configure(-state=>($count) ? 'normal' : 'disabled');
  $widgets{log_summaries} -> configure(-state=>($count) ? 'normal' : 'disabled');
  ## --- disable the plot button
  ##$widgets{log_plot}  -> configure(-state=>'disabled');
  $log_params{force} = 0;
};



sub logview_post_menu {

  ## figure out where the user clicked
  my $w = shift;
  my $Ev = $w->XEvent;
  delete $w->{'shiftanchor'};
  my $entry = $w->GetNearest($Ev->y, 1);
  return unless (defined($entry) and length($entry));

  ## select and anchor the right-clicked parameter
  $w->selectionClear;
  $w->anchorSet($entry);
  $w->selectionSet($entry);

  ## need to know how many fits there are...
  opendir F, File::Spec->catfile($project_folder, "fits");
  my @fits = sort( grep {/fit\d+/ and -d  File::Spec->catfile($project_folder, "fits", $_)} readdir(F) );
  closedir F;

  ## post the message with parameter-appropriate text
  my $which = $w->selectionGet();
  $which    = (ref($which) eq 'ARRAY') ? $$which[0] : $which;
  my $label = $widgets{loglistbox}->entrycget($entry, '-text');
  my ($X, $Y) = ($Ev->X, $Ev->Y);
  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[[ command=>"Show raw log file for \"$label\"",
		       -command=>[\&logview_show, 'raw']
		      ],
		      [ command=>"Show column view of log file for \"$label\"",
		       -command=>[\&logview_show, 'column']
		      ],
		      [ command=>"Show quick view of log file for \"$label\"",
		       -command=>[\&logview_show, 'quick']
		      ],
		      [ command=>"Show operational view of log file for \"$label\"",
		       -command=>[\&logview_show, 'operational']
		      ],
		      "-",
		      [ command=>"Get parameter list from \"$label\"",
		       -command=>sub{logview_param_list('file', $widgets{loglistbox}->infoData($widgets{loglistbox}->infoSelection))}
		      ],
		      "-",
		      [ command=>"Restore the \"$label\" fit model",
		       -command=>sub{logview_restore_model($which)},
		       -state=>($#fits) ? 'normal' : 'disabled']
		     ])
      -> Post($X, $Y);
  $w -> break;


};

sub logview_show {
  my @save = @log_type;
 SW: {
    @log_type = ('Raw log file', 'raw'),               last SW if ($_[0] eq 'raw');
    @log_type = ('Column file',  'column'),            last SW if ($_[0] eq 'column');
    @log_type = ('Quick view',   'quick'),             last SW if ($_[0] eq 'quick');
    @log_type = ('Operational view',   'operational'), last SW if ($_[0] eq 'operational');
    @log_type = ('Raw log file', 'raw');
  };
  $current_file = $widgets{loglistbox}->infoData($widgets{loglistbox}->infoSelection);
  log_file_display('files', $current_file);
  Echo("Showed $log_type[0] for $current_file");
  @log_type = @save;
  raise_palette('files');
};


sub logview_param_list {
  my ($how, $file) = @_;
  my @vars;
  if ($how eq 'gds') {
    ## names of all non-skip parameters
    @vars = map  { $_->name } (grep {$_->type !~ /s(e|ki)p/} @gds);
  } else {
    return unless (-e $file);
    my $data = Ifeffit::ArtemisLog -> new($file);
    push @vars, sort($data -> list('guess')), sort($data -> list('def')),
      sort($data -> list('set'));
  };
  unshift @vars, "Statistical parameters"; #, "Data parameters";
  #'Chi-square', 'Reduced Chi-square', 'R-factor';
  $widgets{log_param_list} -> delete(0,'end');
  my $seen = 0;
  foreach my $v (@vars) {
    $widgets{log_param_list} -> insert('end', $v);
    $seen = 1 if (lc($log_params{param}) eq lc($v));
  };
  ($log_params{param} = 'Statistical parameters') unless $seen;
  Echo("Loaded parameter list from GDS page"), return if ($how eq 'gds');
  Echo("Loaded parameter list from the log file for ".$widgets{loglistbox}->selectionGet);
};


sub logview_write_report {
  my $listbox = $widgets{loglistbox};
  #my $rhash   = $_[1];
  $log_params{is_einstein} = 0;
  my @list;
  my @logs;
  $widgets{log_select}->invoke unless ($listbox->selectionGet);
  foreach my $l ($listbox->selectionGet) {
    push @list, $l;
    push @logs, Ifeffit::ArtemisLog->new($listbox->infoData($l));
  };
  Error("You have not selected any log files"), return unless @list;
  ## set param name so that Ifeffit::ArtemisLog will recognize it
  my $param   = $log_params{param};
  #($param = 'chisqr') if ($param eq 'Chi-square');
  #($param = 'chinu')  if ($param eq 'Reduced Chi-square');
  #($param = 'rfact')  if ($param eq 'R-factor');
  (($log_params{average}, $log_params{einstein}) = (0,0)) if ($param eq 'Statistical parameters');
  (($log_params{average}, $log_params{einstein}) = (0,0)) if ($param eq 'Data parameters');
  ## compute average and standard deviation of best fits values, if requested
  my ($sum, $sdv) = (0, 0);
  if (($log_params{average}) and ($#logs>=1)) {
    map { $sum += ($_ -> get($param))[0] } @logs;
    $sum /= ($#logs+1);
    map { $sdv += ( ($_ -> get($param))[0] - $sum )**2 } @logs;
    $sdv /= $#logs;
  };
  ## do einstein fit if requested
  my ($thetae, $dth, $offset, $doff) = (0,0,0,0);
  if ($log_params{einstein}) {
    ($thetae, $dth, $offset, $doff) =
      &logview_do_einstein(\@logs, $param);# pass the data
  };
  ## write report
  my $message = "# $props{'Project title'}\n";
  $message   .= "# report on \"$log_params{param}\"\n";
  ($message  .= sprintf("# the average value of $log_params{param} is %.5f +/- %.5f\n", $sum, sqrt($sdv)))
    if ($log_params{average} and ($#logs>=1));
  ## deal with the einstein fit
  $log_params{absorber}  ||= " ";
  $log_params{scatterer} ||= " ";
 EINS: {
    ($log_params{einstein} and ($thetae>0)) and do {
      $message  .= sprintf("# these data fit an Einstein temperature of %8.3f +/- %.3f\n", $thetae, $dth);
      $message  .= sprintf("# with an offset of %.6f +/- %.6f\n", $offset, $doff);
      $log_params{is_einstein} = 1;
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-1)) and do {
      $message  .= "# The Einstein fit could not be done because\n# Xray::Absorption is not installed\n";
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-2)) and do {
      $message  .= "# The Einstein fit could not be done because\n# \`$log_params{absorber}\' is not an element symbol\n";
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-3)) and do {
      $message  .= "# The Einstein fit could not be done because\n# \`$log_params{scatterer}\' is not an element symbol\n";
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-4)) and do {
      $message  .= "# The Einstein fit could not be done because\n# there are fewer than three data points\n";
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-5)) and do {
      $message  .= "# The Einstein fit could not be done because\n# the data arrays were of unequal length\n";
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-6)) and do {
      $message  .= "# The Einstein fit could not be done because\n# the temperature array does not seem to contain temperature data\n";
      last EINS;
    };
    ($log_params{einstein} and ($thetae==-7)) and do {
      $message  .= "# The Einstein fit could not be done because\n# the sigma^2 array does not seem to contain sigma^2 data\n";
      last EINS;
    };
  };

  $message   .= "# -----------------------------------------------------------------\n";

  if ($param eq 'Statistical parameters') {
    $message   .= "#  fit            FoM    R-factor   Reduced_chi-square  Chi-square   nvar   nidp\n";
    foreach my $i (0..$#list) {
      $message .= sprintf("  %-15s  %-6s  %6.4f  %11.3f        %11.3f    %3d    %3d\n",
			  "'".$listbox->itemCget($list[$i], 0, '-text')."'",
			  $logs[$i]->get('Figure of merit'),
			  $logs[$i]->get('rfact'),
			  $logs[$i]->get('chinu'),
			  $logs[$i]->get('chisqr'),
			  $logs[$i]->get('nvar'),
			  $logs[$i]->get('nidp'),
			 );
    };
##   } elsif ($param eq 'Data parameters') {
##     my $n_set = 0;
##     foreach my $d ($data->list('data')) {
##       ++$n_set;
##       $message   .= "\n\n Data set $n_set\n\n";
##       $message   .= "#  fit            kw   k-range    dk   R-range  dR\n";
##       foreach my $i (0..$#list) {
## 	$message .= sprintf("  %-15s  %-7s [%6.4f:%6.4f]  %4.2  [%6.4f:%6.4f]  %4.2\n",
## 			    "'".$listbox->itemCget($list[$i], 0, '-text')."'",
## 			    $logs[$i]->get($d, 'kw'),
## 			    $logs[$i]->get($d, 'kmin'),
## 			    $logs[$i]->get($d, 'kmax'),
## 			    $logs[$i]->get($d, 'dk'),
## 			    $logs[$i]->get($d, 'rmin'),
## 			    $logs[$i]->get($d, 'rmax'),
## 			    $logs[$i]->get($d, 'dr'),
## 			   );
##       };
##     };
  } else {
    $message   .= "#  fit            FoM            $log_params{param}";
    $message   .= (grep {/^$param$/} $logs[0]->list('guess')) ? "               +/-             initial\n" : "\n";
    foreach my $i (0..$#list) {
      my ($first, $pat) = ($list[$i], '%-20s');
      ## need to report error bars for guess values
      my $val = (grep {/^$param$/} $logs[$i]->list('guess')) ? '%15.7f  %15.7f      %s' : '%15.7f';
      my @ll = $logs[$i]->get($param);
      #($ll[0] = (split(/=/, $ll[0]))[0]) if (grep {/^$param$/} $logs[$i]->list('after'));
      next if (($ll[0] == -999) or ($ll[0] == -998)); # skip if unused in the fit

      ## here, one could try to evaluate a math expression if a param
      ## is guessed as a mathexp.  in stead, I'll just print the mathexp.
      $message .= sprintf("  %-15s  %-6s  $val\n",
			  "'".$listbox->itemCget($list[$i], 0, '-text')."'",
			  $logs[$i]->get('Figure of merit'), @ll);

      ## need to take care about a param guessed as another param (note
      ## this will plotz for deeply nested guessing-as-param
      #($ll[2] = ($logs[$i]->get($ll[2]))[2]) unless (not exists($ll[2]) or ($ll[2] =~ /-?\d*\.\d+/));
    };
  };
  &post_message($message, "report");
  if ($#logs) {
    ##$widgets{log_plot}    -> configure(-state=>'normal');
    $widgets{log_rfactor} -> configure(-state=>'disabled');
    $widgets{log_chinu}   -> configure(-state=>'disabled');
    if ($log_params{param} =~ /Statistical/) {
      $widgets{log_rfactor} -> configure(-state=>'normal');
      $widgets{log_chinu}   -> configure(-state=>'normal');
    };
  };
  my $plot_return = &logview_plot unless ($log_params{param} eq 'Data parameters');
  $top -> update();
  Echo("Wrote and plotted report on \"$log_params{param}\"") unless $plot_return;
};

## return (theta, d_theta, offset, d_offset)
## error codes, theta=
##   -1   Xray::Absorption not installed
##   -2   Absorber symbol is not an element
##   -3   Scatterer symbol is not an element
##   -4   Not enough data points
##   -5   Arrays of unequal length (probably unable to harvest temperatures)
##   -6   temperature array does not appear to be valid data
##   -7   sigma^2 array does not appear to be valid data
sub logview_do_einstein {
  my $rlogs = $_[0];
  my $param = $_[1];
  #return (-1,0,0,0) unless $absorption_exists;
  $log_params{absorber}  =~ s/\s+//g;
  return (-2,0,0,0) unless Xray::Absorption->in_resource($log_params{absorber});
  $log_params{scatterer} =~ s/\s+//g;
  return (-3,0,0,0) unless Xray::Absorption->in_resource($log_params{scatterer});
  my $abs = Xray::Absorption->get_atomic_weight($log_params{absorber});
  my $sca = Xray::Absorption->get_atomic_weight($log_params{scatterer});
  my (@t, @ss, @err);
  foreach my $l (@$rlogs) {
    push @t,    $l -> get('Figure of merit');
    push @ss,  ($l -> get($param))[0];
    push @err, ($l -> get($param))[1] || 0;
  };
  return (-4,0,0,0) unless ($#t >= 2);
  return (-5,0,0,0) unless (($#t == $#ss) and ($#t == $#err));
  my ($t_bad, $ss_bad) = (0,0);
  map { ++$t_bad  if (($_ < 0) or ($_ > $config{logview}{eins_temp_max})) } @t;
  return (-6,0,0,0) if $t_bad;
  map { ++$ss_bad if ($_ > $config{logview}{eins_sigma_max}) } @ss;
  return (-7,0,0,0) if $ss_bad;
  Ifeffit::put_array('eins.1', \@t);
  Ifeffit::put_array('eins.2', \@ss);
  Ifeffit::put_array('eins.3', \@err);
  ##$paths{gsd} -> dispose("show \@group eins", $dmode);
  $paths{gsd} -> dispose("eins $abs $sca", $dmode);
  my ($th, $dth, $off, $doff) =  (Ifeffit::get_scalar('eins_theta'),
				  Ifeffit::get_scalar('delta_eins_theta'),
				  Ifeffit::get_scalar('eins_offset'),
				  Ifeffit::get_scalar('delta_eins_offset') );
  $paths{gsd} -> dispose("unguess", $dmode);
  return ($th, $dth, $off, $doff);
};



sub logview_plot {
  Echo("Cannot plot data parameters"), return if ($log_params{param} eq 'Data parameters');
  my $param   = $log_params{param};
  if ($log_params{is_einstein}) {
    $paths{gsd} -> dispose("set ___min = floor(eins.2)",1);
    my $ym = Ifeffit::get_scalar("___min");
    $ym = ($ym < 0) ? 1.1*$ym : 0;
    my $message = "eins.1, eins.2, dy=eins.3, ymin=$ym, xmin=0, title=\"Einstein fit\", ";
    $message   .= "xlabel=\"temperature (K)\", ylabel=\"\\gs\\u2\\d (\\A\\u-2\\d)\", ";
    $message   .= "key=data, style=points16, color=$config{plot}{c0}";
    $message   .= ", ymin=0" if $log_params{zero};
    $message    = wrap("newplot(", "        ", $message) . ")\n";
    $message   .= "plot(eins.xx, eins.yy, style=lines, key=fit, color=$config{plot}{c1})";
    $paths{gsd} -> dispose($message, $dmode);
  } else {
    ## set param name so that Ifeffit::ArtemisLog will recognize it
    ##     my $param   = $log_params{param};
    ##     ($param = 'chisqr') if ($param eq 'Chi-square');
    ##     ($param = 'chinu')  if ($param eq 'Reduced Chi-square');
    ##     ($param = 'rfact')  if ($param eq 'R-factor');
    my (@x, @val, @err, @fth);
    foreach my $l (split(/\n/, $notes{messages} -> get(qw(1.0 end)))) {
      next if ($l =~ /^\s*\#/);
      next if ($l =~ /^\s*$/);
      $l = substr($l, index($l, "'")+1);
      $l = substr($l, index($l, "'")+1);
      my @line = split(" ", $l);
      push @x,   $line[0];
      push @val, $line[1];
      push @err, $line[2] || 0;
      push @fth, $line[3] || 0;
    };
    Error("Plot aborted.  You only selected one fit."), return 1 unless $#x;
    if ($log_params{param} =~ /Statistical/) {
      Ifeffit::put_array("l___og.1", \@x);
      if ($log_params{prefer} eq 'rfactor') {
	$param = "R-factor";
	Ifeffit::put_array("l___og.2", \@val);
      } elsif ($log_params{prefer} eq 'chinu') {
	$param = "reduced chi-square";
	Ifeffit::put_array("l___og.2", \@err);
      } else {
	$param = "chi-square";
	Ifeffit::put_array("l___og.2", \@fth);
      };
      my $message = "l___og.1, l___og.2, title=\"Report on $param\", ";
      $message   .= "xlabel=\"Figure of merit\", ylabel=\"$param\", ";
      $message   .= "key=$param, style=points3, markersize=4, color=$config{plot}{c0}";
      $message   .= ", ymin=0" if $log_params{zero};
      $message    = wrap("newplot(", "        ", $message) . ")\n";
      $paths{gsd} -> dispose($message, $dmode);
    } else {
      Ifeffit::put_array("l___og.1", \@x);
      Ifeffit::put_array("l___og.2", \@val);
      Ifeffit::put_array("l___og.3", \@err);
      my $message = "l___og.1, l___og.2, dy=l___og.3, title=\"Report on $param\", ";
      $message   .= "xlabel=\"Figure of merit\", ylabel=\"$param\", ";
      $message   .= "key=$param, style=points16, color=$config{plot}{c0}";
      $message   .= ", ymin=0" if $log_params{zero};
      $message    = wrap("newplot(", "        ", $message) . ")\n";
      $paths{gsd} -> dispose($message, $dmode);
    };
    #$paths{gsd} -> dispose("plot(style=line)\n", $dmode);
  };
  Echo("Plotted $param");
  return 0;
};


sub logview_quick_summary {
  $widgets{log_select}->invoke unless ($widgets{loglistbox}->selectionGet);
  $notes{messages} -> delete(qw(1.0 end));
  foreach my $l ($widgets{loglistbox}->selectionGet) {
    my $data = Ifeffit::ArtemisLog->new($widgets{loglistbox}->infoData($l));
    my $was_sum = grep {/Fitting was not performed./} ($data->get('warnings'));
    ## header
    $notes{messages} -> insert('end', "Project title   : " . $data -> get('Project title') . "\n");
    $notes{messages} -> insert('end', "Comment         : " . $data -> get('Comment') . "\n");
    $notes{messages} -> insert('end', "Figure of merit : " . $data -> get('Figure of merit') . "\n");
    ## statistics
    $notes{messages} -> insert('end', $data->stats) unless $was_sum;
    ## guesses
    $notes{messages} -> insert('end', $data->guess);
    ## restraints
    $notes{messages} -> insert('end', $data->restraint);
    ## separator
    $notes{messages} -> insert('end', $/ . "=*=" x 20 . $/ x 2);
    undef $data;
  };
  $notes{messages} -> yviewMoveto(0);
  $top -> update;
  raise_palette('messages') unless $_[2];
};


## show the latest fit if this is the head of a branch
sub logview_show_fom {
  my $data = $paths{$current}->data;
  my $which = (($paths{$current}->type eq 'fit') and $paths{$current}->get('parent')) ?
    $current :
      $paths{$data.".0"}->get('thisfit');
  Echo("The figure of merit for \"" . $paths{$which}->descriptor .
       "\" is " . $paths{$which}->get('value'))
}

sub logview_change_fom {
  logview_change_fit_property("fom");
};
sub logview_change_comment {
  logview_change_fit_property("comment");
};
sub logview_change_fit_property {

  ## before doing this, shift anchor from head of fit branch to latest
  my $data = $paths{$current}->data;
  my $which = (($paths{$current}->type eq 'fit') and $paths{$current}->get('parent')) ?
    $current :
      $paths{$data.".0"}->get('thisfit');
  $list->anchorSet($which);
  &display_properties;
  $top -> update;

  ## set some variables based on what's being changed
  my ($long, $lclong, $old) = (q{}, q{}, q{});
 SW: {
    ($_[0] eq 'fom') and do {
      $long = "Figure of merit";
      $lclong = lc($long);
      $old = $paths{$current}->get('value');
      last SW;
    };
    ($_[0] eq 'comment') and do {
      $long = "Comment";
      $lclong = lc($long);
      last SW;
    };
  };

  my $new = $old;
  my $label = "$long for \"" . $paths{$current}->short_descriptor . "\": ";
  my $dialog = get_string($dmode, $label, \$new);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Not changing the $lclong for \"".$paths{$current}->short_descriptor."\""),
    return if ($new eq $old);
  my @parts = split(/\./, $current);
  foreach my $d (&every_data) {
    my $key = "$d.0.$parts[2]";
    next unless $list->info('exists', $key);
    $paths{$key}->make(value=>$new);
  };

  ## need to make the change permanent by altering the log file
  my $folder = $paths{$current}->get('folder');
  my $log = File::Spec->catfile($project_folder, 'fits', $folder, 'log');
  do {
    local $/ = undef;
    local $| = 1;
    open L, $log;
    my $contents = <L>;
    close L;
    $contents =~ s/($long\s*:).*\n/$1  $new\n/;
    open L, ">".$log;
    print L $contents;
    close L;
  };

  project_state(0);
  Echo("Changed $lclong for \"" .
       $paths{$current}->descriptor .
       "\" to \'$new\'");
};

## show the latest fit if this is the head of a branch
sub logview_show_comment {
  my $data = $paths{$current}->data;
  my $which = (($paths{$current}->type eq 'fit') and $paths{$current}->get('parent')) ?
    $current :
      $paths{$data.".0"}->get('thisfit');

  my $log = $_[1] || File::Spec->catfile($project_folder,
					 "fits",
					 $paths{$which}->get('folder'),
					 "log"
					);
  my $logfile = Ifeffit::ArtemisLog -> new($log);

  Echo("Comment for \""
       . $paths{$which}->descriptor
       . "\" :   "
       . $logfile->get('Comment')
      )
}


### some subs for managing the fit branches in the Data and Paths List

sub rename_fit {

  ## before doing this, shift anchor from head of fit branch to latest
  if (($paths{$current}->type eq 'fit') and
      (not $paths{$current}->get('parent')) and
      ($paths{$current}->get('thisfit'))) { # this keeps it from
				            # plotzing when writing a
                                            # script without actually
                                            # running
    display_page($paths{$current}->get('thisfit'));
  };
  $top -> update;

  my $old = $paths{$current}->get('lab');
  my $new = $old;
  my $label = "Rename \"" . $paths{$current}->short_descriptor . "\" to: ";
  my $dialog = get_string($dmode, $label, \$new, \@rename_buffer);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Not changing the name of \"".$paths{$current}->short_descriptor."\""),
    return if ($new eq $old);
  $new =~ s{[\"\']}{}g;
  project_state(0);
  push @rename_buffer, $new;
  my @parts = split(/\./, $current);
  foreach my $d (&every_data) {
    my $key = "$d.0.$parts[2]";
    next unless $list->info('exists', $key);
    $paths{$key}->make(lab=>$new);
    $list -> itemConfigure($key, 0, -text=>$new);
  };
  Echo("Renamed for \'$old\' to \'$new\'");
  ## --- touch the label file
  my $file = File::Spec->catfile($project_folder, "fits", $paths{$current}->get('folder'), "label");
  open L, ">".$file;
  print L $new;
  close L;
  populate_logview if ($current_canvas eq 'logview');
};


sub hide_fit {

  ## before doing this, shift anchor from head of fit branch to latest
  if (($paths{$current}->type eq 'fit') and
      (not $paths{$current}->get('parent')) and
      ($paths{$current}->get('thisfit'))) { # this keeps it from
				            # plotzing when writing a
                                            # script without actually
                                            # running
    &display_page($paths{$current}->get('thisfit'));
  };
  $top -> update;

  ## need to hide this fit in other data sets as well.
  my @parts = split(/\./, $current);
  Echo("Hiding ".$paths{$current}->get('lab'));
  foreach my $d (&every_data) {
    my $key = "$d.0.$parts[2]";
    next unless $list->info('exists', $key);
    $list -> selectionClear($key);
    $list -> hide('entry', $key);
    $list -> itemConfigure($d.".0", 0, -style=>$list_styles{hidden});
  };
  &keyboard_up;
  &populate_logview;
};

sub hide_selected_fits {
  my $anchor = $list->info('anchor') || 'data0';
  foreach my $p ($list->info('selection')) {
    next unless (($paths{$p}->type eq 'fit') and $paths{$p}->get('parent'));
    my @parts = split(/\./, $p);
    foreach my $d (&every_data) {
      my $key = "$d.0.$parts[2]";
      next unless $list->info('exists', $key);
      $list -> selectionClear($key);
      $list -> hide('entry', $key);
      $list -> itemConfigure($d.".0", 0, -style=>$list_styles{hidden});
    };
  };
  if (($paths{$anchor}->type eq 'fit') and $paths{$anchor}->get('parent')) {
    my $pa = $paths{$anchor}->get('parent');
    &display_page($pa);
  };
  Echo("Hid selected fits.");
};

sub show_fits {
  foreach my $p (keys %paths) {
    next unless (($paths{$p}->type eq 'fit') and $paths{$p}->get('parent'));
    next unless ($list->info('hidden', $p));
    $list -> show('entry', $p);
    $list -> itemConfigure($paths{$p}->get('parent'), 0, -style=>$list_styles{enabled});
  };
  my $anchor = $list->info('anchor') || 'data0';
  &populate_logview if ($paths{$anchor}->type eq 'fit');
  Echo("Showing all fits.");
};


sub discard_fit {
  my $solo = $_[0];
  my $which = $_[0] || $current;

  unless ($solo) {
    ## before doing this, shift anchor from head of fit branch to latest
    if (($paths{$which}->type eq 'fit') and
	(not $paths{$which}->get('parent')) and
	($paths{$which}->get('thisfit'))) { # this keeps it from
				            # plotzing when writing a
                                            # script without actually
                                            # running
      &display_page($paths{$which}->get('thisfit'));
    };
    $top -> update;
    $which = $current;
  };

  ## this could have already been deleted if this is called as part of
  ## delete selected or delete all
  return unless exists $paths{$which};
  ##Echo($paths{$which}->descriptor . " is not a fit."),
  return unless (($paths{$which}->type eq 'fit') and $paths{$which}->get('parent'));

  ## need to get some info while the object still exists ...
  my $this_count = (split(/\./, $which))[2];
  my $folder = File::Spec->catfile($project_folder,
				   "fits",
				   $paths{$which}->get('folder'));
  my $above = $list->info('prev', $which);
  my $was = $paths{$which}->descriptor;

  foreach my $d (&every_data) {
    my $this = $d . ".0." . $this_count;
    ## repoint thisfit in the head fit object if it pointed at this one
    next unless exists $paths{$this};
    my $parent = $paths{$this}->parent;
    if ($paths{$parent}->get('thisfit') eq $this) {
      my $prev = $list->info('prev', $this);
      if (($paths{$prev}->type eq 'fit') and $paths{$prev}->get('parent')) {
	$paths{$parent}->make(thisfit=>$prev);
      } else {
	$paths{$parent}->make(thisfit=>0);
      };
    };

    ## erase these data from Ifeffit
    my $group = $paths{$this}->get('group');
    $paths{$this}->dispose("erase \@group $group\n", $dmode);

    ## undef the object
    delete $paths{$this};

    ## remove the DPL entry
    $list->delete('entry', $this);
  };

  ## delete the fit folder
  rmtree($folder,0,0) if -d $folder;

  ## reset fit_count if it was the latest
  if ($fit{count} == $this_count+1) {
    --$fit{count};
    foreach my $d (&every_data) {
      ## what about Sum?
      if (not exists $fit{recent}) {
	$list -> entryconfigure($d.".0", -text=>"Fit");
      } elsif ($fit{recent} eq 'fit') {
	$list -> entryconfigure($d.".0", -text=>"Fit");
      } else {
	$list -> entryconfigure($d.".0", -text=>"Sum");
      };
      ##$list -> entryconfigure($d.".0", -text=>"Fit [$fit{count}]");
    };
  };

  return if $solo;
  ## and finally, redisplay the newly anchored list entry
  &display_page($above);
  project_state(0);
  Echo("Discarded \"$was\".");
};


sub discard_selected_fits {
  my $data = $paths{$current}->data;
  foreach my $f ($list->info('selection')) {
    next unless (($paths{$f}->type eq 'fit') and $paths{$f}->get('parent'));
    discard_fit($f);
  };
  &display_page($data);
  project_state(0);
  Echo("Discarded selected fits.");
};

sub discard_all_fits {
  my $data = $paths{$current}->data;
  my @list = sort(keys %paths);
  foreach my $f (@list) {
    next unless exists $paths{$f};
    next unless (($paths{$f}->type eq 'fit') and $paths{$f}->get('parent'));
    discard_fit($f);
  };
  foreach my $d (&every_data) {
    ## what about Sum?
    $list -> entryconfigure($d.".0", -text=>"Fit");
  };
  #$fit{new} = 1;
  #$fit{count} = 0;
  #$fit{count_full} = 0;
  %fit = (index=>1, count=>0, count_full=>0, new=>1, label=>"", comment=>"", fom=>0);
  &display_page($data);
  project_state(0);
  Echo("Discarded all fits.");
};


sub save_fit {
  my ($suff, $space) = @_;
  my $kind = "Fit";
  ($kind = "Residual")   if ($suff eq 'res');
  ($kind = "Background") if ($suff eq 'bkg');
  my $sp = $space;
  ($sp = "R") if ($sp =~ /[rR]/);

  my $data    = $paths{$current}->data;
  ## use the latest fit unless this is a fit and not the head of the
  ## fit branch
  my $to_save = (($paths{$current}->type eq 'fit') and $paths{$current}->get('parent')) ?
    $current :
      $paths{$data.".0"}->get('thisfit');
  my $init    = $paths{$to_save}->descriptor;
  $init =~ s/[.:@&\/\\ ]+/_/g;

  ## take care that file to save exists...
  my $data_file = File::Spec->catfile($project_folder, "fits",
				      $paths{$to_save}->get('folder'),
				      join(".",$data,$suff));
  Error("There is no $kind file for \"".$paths{$data}->descriptor."\""), return
    unless (-e $data_file);

  ## get the file name to save to
  my $save_file = $top -> getSaveFile(-filetypes=>[["$kind files", ".$suff"],
						   ['All Files',   '*'],],
				      ##(not $is_windows) ?
				      ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				      -initialfile=>$init."_$space.".$suff,
				      -initialdir=> $current_data_dir || cwd,
				      -title => "Artemis: Save $kind");
  return unless ($save_file);

  Echo("Saving $kind in $sp for \"" . $paths{$to_save}->descriptor . "\" ...");
  my $first = "# $kind in $sp for \"" . $paths{$to_save}->descriptor . "\"\n";
  my $to  = File::Spec->catfile($project_folder, "tmp", "outfile");
  my $header_file = File::Spec->catfile($project_folder, "fits", $paths{$to_save}->get('folder'), "header.".$data);
  if (lc($space) eq 'k') {
    open O, ">".$to;
    print O $first;
    do {			# cat the header and the data
      local $| = 1;
      local $/ = undef;
      if (-e $header_file) {
	open H, $header_file;
	print O <H>;
	close H;
      };
      open D, $data_file;
      print O <D>;
      close D;
    };
    close O;
  } elsif ($space =~ /[qr]/i) {
    my $group = $paths{$to_save}->get('group');
    $group =~ s/fit/$suff/;
    my $command = "";
    ## read in this file
    my $infile = $paths{$to_save}->get('fitfile');
    $infile = substr($infile, 0, -3) . $suff;
    $command .= "read_data(file=\"$infile\",\n           type=chi, group=$group)\n";
    ## FT this array
    my $string = "($group.chi, k=$group.k, ";
    foreach (qw(kmin kmax dk kwindow)) {
      $string   .= "$_=" . $paths{$data}->get($_) . ", ";
    };
    $string .= "kweight=" . $plot_features{kweight} . ", ";
    $string .= "rmax_out=" . $plot_features{rmax_out} . ", ";
    if ($paths{$data}->get('pcpath') ne "None") {
      my $pcp  = $paths{$paths{$data}->get('pcpath')}->('fit_index');
      $string .= "pc_feff_path=$pcp, ";
    };
    $string =~ s/, $/\)\n/;
    $string = wrap("fftf", "     ", $string);
    $command .= $string;
    ## do bft for 1 space
    if (lc($space) eq 'q') {
      my $string = "(real=$group.chir_re, imag=$group.chir_im, ";
      foreach (qw(rmin rmax dr rwindow)) {
	$string   .= "$_=" . $paths{$data}->get($_) . ", ";
      };
      $string =~ s/, $/\)\n/;
      $string = wrap("fftr", "     ", $string);
      $command .= $string;
      ## write it to the tmp/ space
      $command .= "\nwrite_data(file=$to,\n           label=\"q chiq_re chiq_im chiq_mag chiq_pha\",\n           $group.q, $group.chiq_re, $group.chiq_im, $group.chiq_mag, $group.chiq_pha)\n";
    } else {
      ## write it to the tmp/ space
      $command .= "\nwrite_data(file=$to,\n           label=\"r chir_re chir_im chir_mag chir_pha\",\n           $group.r, $group.chir_re, $group.chir_im, $group.chir_mag, $group.chir_pha)\n";
    }
    $paths{$to_save}->dispose($command, $dmode);
    do {			# cat the header and the data
      local $| = 1;
      local $/ = undef;
      open D, $to;
      my $d = <D>;
      close D;
      open O, ">".$to;
      print O $first;
      if (-e $header_file) {
	open H, $header_file;
	print O <H>;
	close H;
      };
      print O $d
    };
    close O;
  };
  move($to, $save_file);
  #unlink $to if (-e $to);

  ## finally, reset current_data_dir
  my ($name, $pth, $suffix) = fileparse($save_file);
  $current_data_dir = $pth;
  Echo("Saved $save_file");
};


sub logview_restore_model {
  ## the argument is either the entry number from the list on the log
  ## viewer page (when called from the log viewer) or the id of the
  ## currently anchored path (when called from the menubar)
  my $which = (defined $_[0]) ? $_[0] : $paths{$current};

  my $this;			  # this will be used to set the thisfit
  if (ref($which) =~ /Ifeffit/) { # property of the fit heads
    $this = $which->get('id');
  } else {
    foreach (keys %paths) {
      next unless ($paths{$_}->type eq 'fit');
      next unless  $paths{$_}->get('parent');
      my $lv = dirname($widgets{loglistbox} -> info('data', $which));
      my $ft = File::Spec->catfile($project_folder, 'fits', $paths{$_}->get('folder'));
      next unless same_directory($lv, $ft);
      $this = $_;
    };
  };
  my $from = (ref($which) =~ /Ifeffit/) ?
    File::Spec->catfile($project_folder, 'fits', $which->get('folder'), 'description') :
	File::Spec->catfile(dirname($widgets{loglistbox} -> info('data', $which)), 'description');
  my $to   = File::Spec->catfile($project_folder, 'descriptions', 'artemis');

  my $label = (ref($which) =~ /Ifeffit/) ?
    $which->get('lab') :
      $widgets{loglistbox} -> entrycget($which, '-text');

  ## need to compare from and to, bail if the requested model is the current
  Error("\"$label\" is the current fitting model.  Restore aborted."), return
    if compare($from,$to) == 0;

  $top -> Busy;
  Echo("Restoring fitting model from \"$label\" ...");

  ##@-fp-@   my $bnfr = basename($from);
  ##@-fp-@   my $fp_exists = (-e File::Spec->catfile($bnfr, "...fp"));
  ##@-fp-@   if ($fp_exists) {
  ##@-fp-@     my $is_ok = compare_fingerprint(File::Spec->catfile($bnfr, "...fp"),
  ##@-fp-@ 				    File::Spec->catfile($bnfr, "artemis"));
  ##@-fp-@     unless ($is_ok) {
  ##@-fp-@       my $dialog =
  ##@-fp-@ 	$top -> Dialog(-bitmap         => 'warning',
  ##@-fp-@ 		       -text           => "The fingerprint of the description file for the selected model has changed.  This could indicate that this project file has been tampered with.  It may be unsafe to continue reading this project file.",
  ##@-fp-@ 		       -title          => 'Artemis: Possibly tainted project file...',
  ##@-fp-@ 		       -buttons        => [qw/Continue Abort/],
  ##@-fp-@ 		       -default_button => 'Abort',
  ##@-fp-@ 		       -popover        => 'cursor');
  ##@-fp-@       &posted_Dialog;
  ##@-fp-@       my $response = $dialog->Show();
  ##@-fp-@       if ($response eq 'Abort') {
  ##@-fp-@ 	Echo("Restoring fitting model from \"$label\" ... aborted!");
  ##@-fp-@ 	$top -> Unbusy;
  ##@-fp-@ 	return;
  ##@-fp-@       };
  ##@-fp-@     };
  ##@-fp-@   };

  ## copy this fit's description to the description folder
  Error("Uh oh!  Something went wrong backing up the old description file."),
    return unless copy($to, File::Spec->catfile($project_folder, 'descriptions', 'artemis.bak'));
  Error("Uh oh!  Something went wrong copying the description file for \"$label\"."),
    return unless copy($from, $to);

  ## save the journal
  open J, ">".File::Spec->catfile($project_folder, "descriptions", "journal.artemis");
  print J $notes{journal}->get(qw(1.0 end));
  close J;

  ## discard this fit
  my $save_project_name = $project_name;
  delete_project(1);
  $project_name  = $save_project_name;

  ## read in the description now in the description folder
  open_project($to);
  foreach (keys %paths) {
    next unless ($paths{$_}->type eq 'fit');
    next if $paths{$_}->get('parent');
    $paths{$_} -> make(thisfit=>$this);
  };
  $widgets{log_current} -> configure(-text=>$paths{$this}->get('lab'));
  project_state(0);

  $top -> Unbusy;
  Echo("Restoring fitting model from \"$label\" ... done!");
};

sub display_warnings {
  my $thisfit = $paths{$current}->get('parent')
    ? $current
      : $paths{$current}->get('thisfit');
  my $warnings_file = File::Spec->catfile($project_folder, "fits", $paths{$thisfit}->get('folder'), 'warnings');
  Error("There is no warnings file for this fit"), return
    unless (-e $warnings_file);
  display_file('file', $warnings_file)
};
