# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##
## THE FITTING SUBSECTION



sub generate_script {
  my $first = &first_data;
  my $how = $_[0];		# 0=write to file buffer
				# 1=dispose fit + plot
				# 2=dispose ff2chi + plot
  my $how_many = $_[1] || 'all';
  Echo("You have not opened a data file yet."), return unless (($how == 2) or $paths{$first}->get('file'));
 ECHO: {
    Echo("Writing script ..."), last ECHO if ($how == 0);
    Echo("Writing script and fitting ..."), last ECHO if ($how == 1);
    Echo("Writing script and summing for data set \"" . $paths{$paths{$current}->data}->descriptor . " ..."), last ECHO if ($how == 2);
  };

  ## this cannot proceed unless merge parameters have been resolved
  my ($nmerge, $first_merge) = &count_merge;
  if ($nmerge) {
    display_page("gsd");
    gds2_display($first_merge);
    # message to echo area
    Error("You must resolve all merged parameters before " .
	  ("writing a script.", "running a fit.", "making a summation.")[$how] );
    return;
  };

  ## empty out the space where the list of ill posed variables will go
  @Ifeffit::Tools::buffer = ();

  ## deal with the situation of hitting the big green button while
  ## editing a parameter
  gds2_update_mathexp($widgets{gds2list}, \%gds_selected) if ($current_canvas eq 'gsd');

  ## --- Save autosave file
  &save_project(0,1);

  my ($wbg, $wfn, $wbt) = ($config{colors}{warning_bg},
			   $config{fonts}{smbold},
			   $config{colors}{warning_fg});
  my ($bg, $fn, $bt) = ($config{colors}{background},
			$config{fonts}{small},
			$config{colors}{button});

  ## --- need a list of the selected paths for writing the log file in
  ##     the case of a summation of selected paths
  my %selection;
  if ($how == 2) {
    map {$selection{$_} = 1} ($list->selectionGet);
  };

  my $warnings = "";
  ## make sure that the data and feffNNNN files actually exist as indicated
  my @ok = ();
  my $missing_feff = 0;
  my $missing = "Error finding data and/or FEFF files:\n\nArtemis could not find the following files:\n";

  ## --- check to see that all the files needed for the fit can be found
  foreach my $p (keys %paths) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next if ($p =~ /^\s*$/);
    next if ($p eq 'journal');
    next if (($paths{$p}->type eq 'gsd') or ($paths{$p}->type eq 'feff') or
	     ($paths{$p}->type eq 'fit') or ($paths{$p}->type eq 'bkg')  or
	     ($paths{$p}->type eq 'res'));
    next if (($paths{$p}->type eq 'data') and (not $paths{$p}->get('file')));
    my $file;
    my $data = $paths{$p}->data;
    ## --- data file, if included in the fit
    if ($paths{$p}->type eq 'data') {
      next unless $paths{$p}->included;
      $file = $paths{$p}->get('file');
      unless (-e $file) {
	push @ok, $paths{$p}->get('lab');
	$missing .= "  Data:\t$file\n";
      };
    };
    ## --- paths, if included in the fit
    if ($paths{$p}->type eq 'path') {
      next unless $paths{$data}->included;
      next unless $paths{$p}->included;
      $file = File::Spec->catfile($paths{$p}->get('path'),
				  $paths{$p}->get('feff'));
      unless (-e $file) {
	++$missing_feff;
	$missing .= "  Path \`" . $paths{$p}->descriptor() . "\':\t$file\n";
      };
    };
  };
  $missing_feff && push @ok, "one or more feffNNN.dat files";
  my $message = join(" and ", @ok);
  ## --- post a message identifying the missing files, then bail
  if ($message) {
    Error("Artemis could not find $message.");
    post_message($missing, 'Error messages');
    return 0
  };


  ## --- check that every data set has at least one path associated
  ##     with it, post message explaining problem if problem found
  my $datafeff = "";
  foreach my $d (&all_data) {
    ($datafeff .= "The data set \"" . $paths{$d}->descriptor() . "\" has no included feff paths\n\tassociated with it.\n\n")
      unless data_paths($d);
  };
  if ($datafeff) {
    $datafeff .= "\nArtemis cannot continue.\n\tYou must either add some paths to the indicated data\n\tset(s) or exclude those data set(s) from the fit.\n";
    Error("There are severe errors in the fitting model!");
    post_message($datafeff, 'Error messages');
    return 0;
  };

  ## --- trying to do an ff2chi on a data file not included in the fit
  my $ff2chi_data;
  ($ff2chi_data = $paths{$current}->data) if ($how == 2);
  Error("You cannot do ff2chi on " . $paths{$ff2chi_data}->get('lab') . " because it is excluded from fitting."),
    return if (($how==2) and (not $paths{$ff2chi_data}->included));

  my $is_busy = grep (/Busy/, $top->bindtags);
  $is_busy or $top -> Busy();


  ## --- make sure that there are included paths in the fit
  my @paths = grep {exists($paths{$_}->{type}) and
		      ($paths{$_}->type eq 'path')} &path_list;
  my $selected_paths = 0;
  foreach (@paths) {
    $selected_paths ||= $paths{$_}->included;
  };
  unless ($selected_paths) {
    Echo ("You have not included any paths for fitting.");
    $top->Unbusy;
    return;
  };

  ## --- just about ready to start fitting
  my $string .= "\n" . "#" x 40 .
    "\n# Starting a new fit\n" .
      "\n# Guess, def, and set parameters:\n";
  $string .= "unguess\n";
  ##&read_gds2(0);			# update gsd object

  ## --- do some error checking on the parameters...
  my $is_err = 0;
  my $error  = ($how==1) ? &check_idp : "";
  my ($this_err, $must_stop) = ("", 0);
  ++$is_err if $error;
				## data parameters
  ($error) and ($error .= "\n\n");
  $this_err  = &verify_data_parameters;
  $error    .= $this_err;
  #($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## number of paths
  ($error) and ($error .= "\n\n");
  $this_err  = &verify_number_of_paths;
  $error    .= $this_err;
  ($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## number of variables
  ($error) and ($error .= "\n\n");
  $this_err  = &verify_number_of_variables;
  $error    .= $this_err;
  ($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## rmin < Rbkg
  ($error) and ($error .= "\n\n");
  $this_err  = &verify_rmin_rbkg;
  $error    .= $this_err;
  ($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## binary operators
  ($error =~ /^\s$/m) or ($error .= "\n\n");
  $this_err  = &verify_operators;
  $error    .= $this_err;
  ($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## matching parens
  ($error =~ /^\s$/m) or ($error .= "\n\n");
  $this_err  = &verify_parens;
  $error    .= $this_err;
  ($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## parameters named like program variables
  ($error =~ /^\s$/m) or ($error .= "\n\n");
  $this_err  = &verify_ifeffit_program_variables;
  $error    .= $this_err;
  ($must_stop = 1) if $this_err;
  ++$is_err if $this_err;
				## parameters defined and used
  ($error =~ /^\s$/m) or ($error .= "\n\n");
  my $unused_defs = 0;
  ($this_err, $unused_defs) = &verify_parameters;
  $error    .= $this_err;
  ++$is_err if $this_err;

  if ($how != 2) {
				## R-range compared to Reff values
    ($error =~ /^\s$/m) or ($error .= "\n\n");
    $this_err  = &verify_reffs;
    $error    .= $this_err;
    ++$is_err if $this_err;
  };

  ## --- clear out the Messages tab
  $notes{messages} -> delete(qw(1.0 end));
  ##$current_file = "";
  $top -> update;

  ## --- post a message if trouble was found among the parameters
  if ($must_stop) {
    post_message($error, "Error Messages");
    Error("Fit aborted due to unrecoverable errors in your project.  See Messages buffer (control-4)");
    $top->Unbusy;
    $update->raise;
    return;
  } elsif ($is_err) {
    post_message($error, "Error Messages");
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => "There are errors in your math expressions.  Do you want to abort this fit or carry on regardless?",
		     -title          => 'Artemis: Errors...',
		     -buttons        => [qw/Continue Abort/],
		     -default_button => 'Abort',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    $top->update;
    ## offer to convert any unused def parameters into either skip or
    ## after parameters, then issue the right message for aborted or
    ## continued fits
    if (@$unused_defs) {
      my $string = '("'.join('", "', @$unused_defs).'")';
      my $dia =
	$top -> Dialog(-bitmap         => 'questhead',
		       -text           => "Would you like to change the unused def parameters $string into skip or after parameters?",
		       -title          => 'Artemis: Def parameters...',
		       -buttons        => ["Change to skip", "Change to after", "Do nothing"],
		       -default_button => 'Change to skip',
		       -font           => $config{fonts}{med},
		       -popover        => 'cursor'
		      );
      &posted_Dialog;
      my $resp = $dia->Show();
      unless ($resp eq "Do nothing") {
	my $changeto = (split(" ", $resp))[2];
	gds2_def_to_other($changeto, $unused_defs);
	if ($response eq 'Abort') {
	  Error("Fit aborted and all unused def parameters were converted to $changeto parameters.");
	  $top->Unbusy;
	  return;
	} else {
	  Echo("All unused def parameters were converted to $changeto parameters.");
	};
      };
    };
    if ($response eq 'Abort') {
      Error("Fit aborted due to errors in parameters and math expressions.");
      $top->Unbusy;
      $update->raise;
      return;
    };
  } else {
    post_message if ($notes{messages} -> get(qw(1.0 end)) =~ /^\s*Errors/);
    $update->raise;
  };


  ## --- make this fit folder, get fit meta data
  my $project_fit_dir;
  ##my ($fit_label, $fit_comment, $fit_fom) = ("", "", 0);
  if ($how) {
    Echo("Making fit folder ...");
    my %save = (label => $fit{label}, comment    => $fit{comment},
		count => $fit{count}, count_full => $fit{count_full},
		fom   => $fit{fom});
    my $prev_label = "";
    if (-e File::Spec->catfile($project_folder, "fits",
			       sprintf("fit%4.4d", $fit{count}), 'label')) {
      open PL, File::Spec->catfile($project_folder, "fits",
				   sprintf("fit%4.4d", $fit{count}), 'label');
      $prev_label = <PL>;
      close PL;
    };
    ($prev_label =~ s/\bsum\b/fit/) if ($how == 1);
    ($prev_label =~ s/\bfit\b/sum/) if ($how == 2);

    ## get the most recent fit number, then set $fit{count} according
    ## to the value of $fit{new}
    opendir F, File::Spec->catfile($project_folder, "fits");
    my @fits = sort( grep {/fit\d+/ and -d  File::Spec->catfile($project_folder, "fits", $_)} readdir(F) );
    closedir F;
    my $prev = (@fits) ? sprintf("%d", substr($fits[$#fits],3)) : 0;
    $fit{count} = ($fit{new}) ? $prev+1 : $prev;
    ++$fit{count_full};
    $fit{label}     = $prev_label;
    $fit{label}   ||= ($how == 1) ? "fit $fit{count}"  : "sum $fit{count}";
    $fit{label}    =~ s/\b$prev\b/$fit{count}/g;
    $fit{comment}   = $props{Comment};
    ($fit{comment} =~ s/\bSummation\b/Fit/) if ($how == 1);
    ($fit{comment} =~ s/\bFit\b/Sum/) if ($how == 2);
    $fit{comment} ||= ($how == 1) ? "Fit #$fit{count}" : "Summation #$fit{count}";
    #$fit{comment}  =~ s/\b$prev\b/$fit{count}/g;
    $fit{fom} = $fit{count};
    $project_fit_dir = File::Spec->catfile($project_folder, "fits",
					   sprintf("fit%4.4d", $fit{count}));
    if ($config{general}{fit_query}) {
      Echo("Getting fit information ...");
      my $chore = ($how == 1) ? "Run fit" : "Make sum";
      my $title = ($how == 1) ? "fit" : "summation";
      my $db = $top -> DialogBox(-title=>"Artemis: Information about this $title",
				 -buttons=>[$chore, 'Cancel'],
				 -default_button=>$chore);
      my $fr = $db->Frame(-borderwidth=>2, -relief=>'flat')->pack(-pady=>5);
      $title = ($how == 1) ? "run a fit" : "make a summation";
      $fr -> Label(-text=>"You are about to $title.  Artemis needs some",
		   -font=>$config{fonts}{large},
		   -foreground=>$config{colors}{activehighlightcolor})
	-> pack(-side=>'top');
      $fr -> Label(-text=>"information to help you organize your project.",
		   -font=>$config{fonts}{large},
		   -foreground=>$config{colors}{activehighlightcolor})
	-> pack(-side=>'top');

      my @button = (-foreground=>$config{colors}{activehighlightcolor},
		    -font=>$config{fonts}{med},
		    -activeforeground=>$config{colors}{mbutton},
		    -relief=>'flat', -borderwidth=>0,);
      $fr = $db->Frame(-borderwidth=>2, -relief=>'groove')->pack;
      $fr -> Button(-text=>"Label: ", @button,
		    -command=>[\&Echo, 'The label that will be used in the Paths list'])
	-> grid(-column=>0, -row=>0, -sticky=>'w', -pady=>2);
      $fr -> Entry(-width=>20, -textvariable=>\$fit{label})
	-> grid(-column=>1, -row=>0, -sticky=>'w', -pady=>2);
      $fr -> Button(-text=>"Comment: ", @button,
		    -command=>[\&Echo, 'A brief description of this fit.  This will the Comment on the Project Properties page.'])
	-> grid(-column=>0, -row=>1, -sticky=>'w', -pady=>2);
      $fr -> Entry(-width=>60, -textvariable=>\$fit{comment})
	-> grid(-column=>1, -row=>1, -sticky=>'w', -pady=>2);
      $fr -> Button(-text=>"Figure of merit: ", @button,
		    -command=>[\&Echo, 'A number associated with this fit (for instance, the temperature in a temperature series)'])
	-> grid(-column=>0, -row=>2, -sticky=>'w', -pady=>2);
      $fr -> Entry(-width=>6, -textvariable=>\$fit{fom})
	-> grid(-column=>1, -row=>2, -sticky=>'w', -pady=>2);
      my $rfr = $fr -> Frame
	-> grid(-column=>0, -row=>3, -columnspan=>2, -sticky=>'w', -padx=>8, -pady=>2);
      $rfr -> Radiobutton(-text=>"Make a new fit entry",
			  -variable=>\$fit{new},
			  -value=>1,
			  -selectcolor=>$config{colors}{check},
			  -foreground=>$config{colors}{activehighlightcolor},
			  -activeforeground=>$config{colors}{activehighlightcolor},
			  -state=>($fit{count_full}>1) ? 'normal' : 'disabled',
			  -command=>sub{&fit_toggle_new(\$project_fit_dir, $how)})
	-> pack(-side=>'left');
      $rfr -> Radiobutton(-text=>"Reuse previous fit entry",
			  -variable=>\$fit{new},
			  -value=>0,
			  -selectcolor=>$config{colors}{check},
			  -foreground=>$config{colors}{activehighlightcolor},
			  -activeforeground=>$config{colors}{activehighlightcolor},
			  -state=>($fit{count_full}>1) ? 'normal' : 'disabled',
			  -command=>sub{&fit_toggle_new(\$project_fit_dir, $how)})
	-> pack(-side=>'left');
      $fr -> Button(-text=>"Document: fit information dialog", @button2_list,
		    -command=>sub{pod_display("artemis_fitinfo.pod")})
	-> grid(-column=>0, -row=>4, -columnspan=>2, -sticky=>'ew', -pady=>2, -padx=>2);
      my $answer = $db -> Show;
      if ($answer eq 'Cancel') {
	## restore the fit hash upon canceling
	foreach my $k (qw(label comment count count_full fom)) {
	  $fit{$k} = $save{$k};
	};
	Echo("Fit aborted!");
	$top -> Unbusy;
	return;
      };
    };
    $fit{label} =~ s/\'/\"/g;	# care with quotes
    $fit{label} =~ s/\s+$//;	# trim railing spaces
    $props{Comment} = $fit{comment};
    mkpath $project_fit_dir unless (-d $project_fit_dir);
  };


  ## --- and carry on if there are no obvious problems
  set_status(0);
  Echo("Generating ifeffit commands ...");

  ## --- define all the GDS parameters
  my @sets = ();
  foreach (@gds) {
    push @sets, $_ if ($_->type eq 'set');
  };
  if ($config{general}{sort_set}) {
    foreach (sort byuse @sets) { $string .= $_ -> write_gsd(0) };
  } else {
    foreach (@sets) { $string .= $_ -> write_gsd(0) };
  };
  $string .= $/;
  if ($how == 2) {
    ## use bestfit values for the summation
    foreach (@gds) { $string .= $_ -> write_gsd(1) if ($_->type eq 'guess');    };
  } else {
    ## otherwise use the mathexp values
    foreach (@gds) { $string .= $_ -> write_gsd(0) if ($_->type eq 'guess');    };
  };
  $string .= $/;
  foreach (@gds) { $string .= $_ -> write_gsd(0) if ($_->type eq 'def');      };
  $string .= $/;
  foreach (@gds) { $string .= $_ -> write_gsd(0) if ($_->type eq 'restrain'); };

  ## --- now read in all the data
  $string .= "\n\n# Read data:\n";
  foreach my $d (&all_data) {
    next if (($how==2) and ($ff2chi_data ne $d));
    last if (($how==2) and (not -e $paths{$d}->get('file')));
    my $this =  $paths{$d}->get('lab');
    $paths{$d} -> make(included=>[], inc_mapping=>[]);
    ## read_data
    if ($paths{$d}->{is_rec}) {
      $string .= "# The data was for $this was imported from an Athena record file:\n";
      $string .= "#   " . $paths{$d}->get('file') . "\n";
    } else {
      $string .= "## read data for $this:\n";
      $string .= "read_data(file=\"" . $paths{$d}->get('file') . "\",\n";
      $string .= "          type=chi, group=" . $paths{$d}->get('group') . ")\n";
    };
  };

  ## --- write all the paths
  $string .= "\n\n# Paths:\n";
  my $i = 0;
  my @included;
  my @inc_mapping = ();
  foreach my $p (@paths) {
    next unless (($how_many eq 'all selected') or ($paths{$p}->included));  # skip paths deselected for fit
    next if (($how_many eq 'all selected') and (not $list->selectionIncludes($p)));
    ++$i;
    my $ind    = $paths{$p} -> index;
    ##my $parent = $paths{$p}->get('parent');
    my $data   = $paths{$p}->data;
    my $pathto = $paths{$p}->get('path');
    push @{$paths{$data}->{included}}, $ind;
    $paths{$data}->{inc_mapping}->[$ind] = $p;
    $string   .= $paths{$p} -> write_path($ind, $pathto, $config{paths}{extpp}, $stash_dir);
  };

  ## --- get the list of restraints
  my $restraints = "";
  foreach my $p (@gds) {
    next unless ($p->{type} eq "restrain");
    $restraints .= "restraint=" . $p->name . ", ";
  }

  ## --- generate a feffit() of ff2chi() command for each data set
  my $npaths = $i;
  my $nsets = $paths{data0} -> count_data_sets();
  my $iset = 1;
  ($string .= "\n\n# Do the fit!\n") if ($how==1);
  foreach my $d (&all_data) {
    my $this =  $paths{$d}->get('lab');
    if ($how == 2) { ## --- only do ff2chi for the current data
      next unless ($ff2chi_data eq $d);
      $string .= "\n\n# Run ff2chi!\n";
      ## --- an ff2chi can be on all paths or on the selected paths
      if ($how_many =~ /sel/) { # selected and included
	my @sel = ();
	foreach my $p ($list->selectionGet) {
	  next unless (ref($paths{$p}) =~ /Ifeffit/);
	  next unless ($paths{$p}->type eq 'path');
	  next unless ($paths{$p}->data eq $d);
	  next unless ($paths{$p}->included);
	  push @sel, $paths{$p}->get('fit_index');
	};
	unless (@sel) {
	  Echo("There are no selected paths for data set \"$this\".");
	  --$fit{count};
	  $top -> Unbusy;
	  return;
	};
	$string .= $paths{$d} -> write_ff2chi( &normalize_paths(\@sel) );
      } else {

	my @sel = ();
	foreach my $p (keys(%paths)) {
	  next unless (ref($paths{$p}) =~ /Ifeffit/);
	  next unless ($paths{$p}->type eq 'path');
	  next unless ($paths{$p}->data eq $d);
	  next unless ($paths{$p}->included);
	  push @sel, $paths{$p}->get('fit_index');
	};
	unless (@sel) {
	  Echo("There are no included paths for data set \"$this\".");
	  --$fit{count};
	  $top -> Unbusy;
	  return;
	};
	$string .= $paths{$d} ->
	  write_ff2chi( &normalize_paths(\@sel) );
      };
      $string .= "\n\n# Plot data and simulation in fitting space\n";
    } else {
      $string .= "\n## fitting $this ...\n" ;
      $string .= "## === data set \#$iset of $nsets\n";
      ## --- need to keep track of which data set this in in this fit
      ##     so that background parameters can be found later on
      $paths{$d} -> make(data_index=>$iset);
      my $res_list = ($iset == $nsets) ? $restraints : "";
      $string .= $paths{$d} ->
	write_feffit( &normalize_paths($paths{$d}->{included}), $iset, $nsets, $res_list);
      ++$iset;
      $string .= "\n";
    }
  }

  ## --- establish ifeffit's current path for def parameter evaluation
  my $which = &which_set_path;
  if ($which) {
    $string .= "## set default path for def parameter evaluation\n";
    $string .= "set path_index = " . $paths{$which}->get('fit_index');
  };

  ## --- prep the bkg data
  if ($how!=2) {
    foreach my $d (&all_data) {
      my $this =  $paths{$d}->get('lab');
      my $g    = $paths{$d}->get('group');
      $string .= "\n\n## Background data for $this ...\n";
      if ($paths{$d}->get('do_bkg') eq 'yes') {
	$string .= "set(" . $g . "_bkg.k   = $g.k)\n";
	$string .= "set(" . $g . "_bkg.chi = " . $g . "_fit.kbkg)\n";
	##$string .= "## the following line is a crude hack to sidestep a bug Bruce cannot figure out\n";
	##$string .= "     set foo.x = " . $g . "_bkg.chi\n";
	##$paths{$g.".2"}->make(do_r=>1);
	$plot_features{bkg} = "b";
      } else {
	$plot_features{bkg} = 0;
      };
    };
  };

  ## --- make residual data (need to zero values outside fit range)
  foreach my $d (&all_data) {
    next if (($how==2) and ($ff2chi_data ne $d));
    last if (($how==2) and (not -e $paths{$d}->get('file')));
    my $this =  $paths{$d}->get('lab');
    my $g    = $paths{$d}->get('group');
    $string .= "\n## Residual data for $this ...\n";
    $string .= sprintf("set(%s_res.k = %s.k)\n", $g, $g);
    $string .= sprintf("set(%s_res.chi = %s.chi - %s_fit.chi)\n", $g, $g, $g);
  };

  ## --- make sure do_k flag is set throughout the project
  foreach (keys %paths) {
    next unless (ref($paths{$_}) =~ /Ifeffit/);
    next unless ($paths{$_}->type);
    next if (/$no_plot_regex$/o);
    next if (/^\s*$/);
    $paths{$_}->make(do_k=>1);
  };

  ### somewhere in the following block data0.0 etc get unhidden see
  ###   earlier versions for examples of list entries being made on
  ###   the fly

  ## --- show Fit, Background, and Residual list entries
  foreach my $d (&all_data) {
    next if (($how==2) and ($ff2chi_data ne $d));
    if ($how) {
      $paths{$d.'.0'} ||=  Ifeffit::Path -> new(id=>$d.".0", type=>'fit', group=>$d.'_fit',
						sameas=>$d, lab=>'Fit',
						parent=>0, family=>\%paths);
      $list -> show('entry', $paths{$d}->get('id').".0");
      $paths{$d}->make(with_fit=>1);
    };
  };
    ##     if ($how == 1) {
    ##       $list -> show('entry', $paths{$d}->get('id').".1");
    ##       $paths{$d}->make(with_res=>1);
    ##     };
    ##     if (($how == 1) and ($paths{$d}->get('do_bkg') eq 'yes')) {
    ##       $list -> show('entry', $paths{$d}->get('id').".2");
    ##       $paths{$d}->make(with_bkg=>1);
    ##     };
  ##};


  ## --- select and anchor the plotted data set
  my $to_plot;
  foreach (&all_data) {
    ($to_plot = $_), last if $paths{$_}->get('plot');
  };
  unless ($to_plot) {
    $to_plot = &first_data;
    $paths{$to_plot}->make(plot=>1);
  };
  ($to_plot = $ff2chi_data) if ($how == 2);
  if ($how) {
    $list -> see($list->info('prev', $paths{$to_plot}->get('id')));
    $list -> anchorSet($to_plot);
  };
##   foreach (&all_data) {
##     $paths{$_}->make(plot=>0);
##   };
##   $paths{$to_plot}->make(plot=>1);
  ## what does this next block do??  is it a remnant of the ancient
  ## difference spectrum scheme??
##   unless (($how==2) and (not -e $paths{$to_plot}->get('file'))) {
##     $list -> selectionClear;
##     $list -> anchorSet($to_plot.'.0') if ($how_many =~ /sel/);
##     if ($paths{$to_plot}->{fit_diff}) {
##       $list -> selectionSet($to_plot.'.3');
##       $list -> anchorSet($to_plot.'.3');
##     } else {
##       $list -> selectionSet($to_plot);
##       $list -> anchorSet($to_plot);
##     };
##     $list -> see($paths{$to_plot}->get('id').'.0') if $how;
##     display_properties if $how;
##   };


  ## -- plot the data and fit of the chosen (or first) data set
  my $plot_string = "\n\n# Plot data and fit in fitting space\n";
  $list -> selectionClear;
  if ($how==1) {		# fitting
    $list -> selectionSet($paths{$to_plot}->get('id').'.0');
    foreach my $d (&all_data) {
      $list -> entryconfigure($paths{$d}->get('id').".0",
			      -text=>"Fit");
                              ##-text=>"Fit [$fit{count_full}]");
      $paths{$d}->make(count_full=>$fit{count_full});
      if ($paths{$d}->get('plot')) {
	$list -> selectionSet($paths{$d}->get('id'));
	$list -> selectionSet($paths{$d}->get('id').".0");
      };
    };
  } elsif ($how==2) {		# ff2chi-ing
    $list -> selectionSet($paths{$ff2chi_data}->get('id').'.0');
    $list -> entryconfigure($paths{$ff2chi_data}->get('id').".0",
			    -text=>"Sum");
			    ##-text=>"Sum [$fit{count_full}]");
    foreach my $d (&all_data) {
      $paths{$d}->make(count_full=>$fit{count_full});
    };
  };
  unless ($how == 0) {
    foreach my $p (keys %paths) {
      next unless (exists($paths{$p}) and $paths{$p});
      next unless ($paths{$p}->type eq 'path');
      $list -> selectionSet($paths{$p}->get('id')) if $paths{$p}->get('plotpath');
    };
  };

  unless (($how==2) and (not -e $paths{$to_plot}->get('file'))) {
    $plot_string .= "read_data(file=\"" . $paths{$to_plot}->get('file') . "\",\n" .
                    "          type=chi, group=". $paths{$to_plot}->get('group') . ")\n";
  };

  $plot_string .= plot($paths{$to_plot}->get('fit_space'), 1, 1);
  ($how) or ($plot_string .= "echo \"...and you need to FT and plot the fit as well...\"\n");

  ## --- ready to dispose this fitting script
  Echo("Generating ifefit commands ... done!");
  if ($how == 0) {
    post_message($string.$plot_string, 'Ifeffit script');
    $update->raise;
  } else {
    Running(($how == 2) ?
	 "Making the sum of paths (this could take a few minutes, please be patient) ..." :
	 "Running fit (this could take a few minutes, please be patient) ...");
    @bad_params = ();
    $paths{data0} -> dispose($string, $dmode);
    $parameters_changed = 0 if $how; # flag parameters as not changed

    $props{'Last fit'} = $paths{data0} -> date_of_file;

    foreach (keys %paths) {	# flag all for updating
      next unless (ref($paths{$_}) =~ /Ifeffit/);
      next unless $paths{$_}->type;
      next if (/$no_plot_regex$/);
      $paths{$_}->make(do_k=>1);
    };

    ## --- set state of various File menu options based on how the fit was done
    ##$file_menu->menu->entryconfigure($save_index+1, -state=>'normal'); # fit
##     if ($paths{$paths{$current}->data}->get('with_bkg')) {
##       $data_menu->menu->entryconfigure(2, -state=>'normal');# bkgsub
##       #$file_menu->menu->entryconfigure($save_index+2, -state=>'normal');# bkg
##     };
##     if (-e $paths{$paths{$current}->data}->get('file')) { # don't enable in case of data-less ff2chi
##       ##$file_menu->menu->entryconfigure($save_index+3, -state=>'normal'); # resid
##       $fit_menu->menu->entryconfigure(4, -state=>'normal'); # running R-factor
##     };
  };

  ### --- put best fit & error values in the parameter objects
  if ($how) {
    $paths{data0} -> dispose( "\n## Evaluate after-fit parameters ...\n", $dmode);
    foreach my $p (@gds) {
      if ($p->{type} eq 'guess') {
	$p->make(bestfit  => sprintf("%.6f", Ifeffit::get_scalar($p->name)),
		 error    => 0);
	if ($how == 1) {
	  $p->make(error    => sprintf("%.6f", Ifeffit::get_scalar("delta_".$p->name)));
	  $p->make(note     => sprintf("%s = %s +/- %s", $p->name, $p->bestfit, $p->error))
	    if $p->autonote;
	};
      } elsif ($p->{type} eq 'def') {
	$p->make(bestfit  => sprintf("%.6f", Ifeffit::get_scalar($p->name)));
	if ($how == 1) {
	  $p->make(note   => sprintf("%s = %s", $p->name, $p->bestfit)) if $p->autonote;
	};
      } elsif ($p->{type} eq 'restrain') {
	$p->make(bestfit  => sprintf("%.6f", Ifeffit::get_scalar($p->name)));
	if ($how == 1) {
	  $p->make(note   => sprintf("%s = %s", $p->name, $p->bestfit)) if $p->autonote;
	};
      } elsif ($p->{type} eq 'after') {
	## evaluate the after, then store its value
	my $after_string = sprintf("%s = %s\n", $p->name, $p->mathexp);
	$paths{data0} -> dispose($after_string, $dmode);
	$p->make(bestfit  => sprintf("%.6f", Ifeffit::get_scalar($p->name)));
	if ($how == 1) {
	  $p->make(note   => sprintf("%s = %s", $p->name, $p->bestfit)) if $p->autonote;
	};
      };
    };
    $paths{data0} -> dispose( "\n\n", $dmode);
    repopulate_gds2();
  };

  ## --- post fitting chores
  if ($how) {

    Running("Writing log file ...");
    $widgets{results_save} -> configure(-state=>'normal');
    $notes{results} -> configure(-state=>'normal');
    $notes{results} -> delete(qw(1.0 end));
    my $fh;
    ## --- save the log file to this fit folder
    open $fh, ">".File::Spec->catfile($project_fit_dir, "log");
    #my @a;
    #@a=localtime; print "$a[1]:$a[0] calling results_header\n";
    &write_results_header($fh, \%fit);
    #@a=localtime; print "$a[1]:$a[0] calling results\n";
    &write_results($fh, $how, $how_many);
    #@a=localtime; print "$a[1]:$a[0] calling show_correlations\n";
    &show_correlations($fh) if ($how == 1);
    foreach my $d (&all_data) {
      next if (($how == 2) and ($d ne $paths{$current}->data));
      my $lab = $paths{$d}->get('lab');
      print $fh join("", "\n\n\n", "=" x 5,
		     " Data set >>$lab<< ", "=" x 40, "\n\n");
      #@a=localtime; print "$a[1]:$a[0] calling write_opparams\n";
      &write_opparams($fh, $d);
      print $fh join("", "\n\n  ", "=" x 5,
		     " Paths used to fit $lab\n");
      #@a=localtime; print "$a[1]:$a[0] calling write_paths\n";
      if ($paths{data0} -> vstr >= 1.02005) {
	$warnings .= &write_paths($fh, $d, $how, $how_many, \%selection);
      } else {
	$warnings .= &write_paths_pre_1_2_5($fh, $d, $how, $how_many, \%selection);
      };
    };
    close $fh;
    #@a=localtime; print "$a[1]:$a[0] calling log_file_display\n";
    log_file_display();
    $widgets{results_choose} -> configure(-state=>'normal');
    $notes{results} -> yviewMoveto(0);
    raise_palette('results');
    $update->raise;

    ## --- save the fits to this fit folder
    Running("Saving fit information ...");
    my $ll = ($how ==1) ? "fit" : "sum";
    my $id = "";
    foreach my $d (&all_data) {
      ## remember whether the most recent was a fit or a sum, this is
      ## needed for labeling the DPL when deleting fits
      $fit{recent} = ($how == 1) ? 'fit' : 'sum';
      next if (($how == 2) and ($d ne $paths{$current}->data));
      my $fname = $d . ".fit";
      my $bname = $d . ".bkg";
      my $rname = $d . ".res";
      ##my $id = join(".", $d, '0', $fit{count});
      if ($fit{new}) {
	$id = $d.".0.".$fit{count};
	$list->add($id);
	$fit{label} ||= join(" ", $ll, $fit{count});
	$paths{$id} = Ifeffit::Path -> new(id       => $id,
					   type     => 'fit',
					   group    => $d.'_fit_'.$fit{count},
					   sameas   => $d,
					   lab      => $fit{label},
					   value    => $fit{fom},
					   folder   => sprintf("fit%4.4d", $fit{count}),
					   filename => $fname,
					   parent   => $d.".0",
					   family   => \%paths,
					  );
      } else {
	my $i = $fit{count}; #-1;
	$id = "$d.0.$i";
	$paths{$id} -> make(lab		 => $fit{label},
			    value	 => $fit{fom},
			    imported	 => 0,
			    imported_bkg => 0,
			    imported_res => 0,
			   );
      };
      ## store whether the most recent call to this subroutine was for
      ## a fit or a sum.  this is needed so that DPL label can be set
      ## correctly when importing a project file.
      my $fsfile = File::Spec->catfile($project_fit_dir, "$d.fs");
      open FS, ">".$fsfile;
      print FS $fit{recent};
      close FS;

      ## store FT and fit parameters in this fit object
      my $ftfile = File::Spec->catfile($project_fit_dir, "$d.FT");
      open FT, ">".$ftfile;
      foreach my $k (qw(kmin kmax dk kwindow rmin rmax dr rwindow)) {
	my $val = $paths{$d}->get($k);
	$paths{$id} -> make($k => $val);
	print FT $k, "=", $val, $/;
      };
      close FT;
      $paths{$d.".0"} -> make(plot=>$d.'_fit_'.$fit{count},
			      thisfit=>$id);
      $list -> entryconfigure($id, -style=>$list_styles{$paths{$id}->pathstate("enabled")},
			      -text=>$paths{$id}->get('lab'));
      my $group = $paths{$d.".0"}->get('group');
      $fname = File::Spec->catfile($project_fit_dir, $fname);
      ## store the fit, bkg, and res filenames for quick reference
      ## when plottings
      $paths{$id} -> make(fitfile=>$fname);
      $paths{$id} -> make(bkgfile=>File::Spec->catfile($project_fit_dir, $bname))
	if ($paths{$d}->get('do_bkg') eq 'yes');;
      $paths{$id} -> make(resfile=>File::Spec->catfile($project_fit_dir, $rname));
      $paths{$d} -> dispose("write_data(file=$fname,\n           label=\"k chi\", $group.k, $group.chi)");
      ## --- save the bkg and residual data to the fit folder
      if ($paths{$d}->get('do_bkg') eq 'yes') {
	$fname = File::Spec->catfile($project_fit_dir, $d.".bkg");
	$paths{$d} -> dispose("write_data(file=$fname,\n           label=\"k chi\", ${d}_bkg.k, ${d}_bkg.chi)");
      };
      $fname = File::Spec->catfile($project_fit_dir, $d.".res");
      $paths{$d} -> dispose("write_data(file=$fname,\n           label=\"k chi\", ${d}_res.k, ${d}_res.chi)");
      ## --- save the header to the fit folder
      foreach my $d (&all_data) {
	next if (($how == 2) and ($d ne $paths{$current}->data));
	my $header = "";
	foreach ('Project title', 'Comment', 'Prepared by', 'Contact', 'Started', 'Last fit', 'Environment') {
	  my $this = $_;
	  ($this = "This fit at") if ($this eq 'Last fit');
	  $header .= sprintf("# %-15s :  ", $this);
	  $header .= "\n", next if (not defined($props{$_}));
	  $header .= "\n", next if ($props{$_} =~ /^\<.*\>$/);
	  $header .= "\n", next if ($props{$_} =~ /^\s*$/);
	  $header .= "$props{$_}\n";
	};
	$header .= sprintf("# %-15s :  %s\n", "Figure of merit", $fit{fom});
	foreach my $l (split(/\n/, $paths{$d}->param_summary($plot_features{kweight}))) {
	  $header .= "# ".$l.$/;
	};
	open H, ">".File::Spec->catfile($project_fit_dir, "header.$d");
	print H $header;
	close H;
      };
    };

    ## --- save the description to this fit folder
    &save_description;
    my $description = File::Spec->catfile($project_folder, 'descriptions', 'artemis');
    copy($description, File::Spec->catfile($project_fit_dir, "description"));
    ##@-fp-@ save_fingerprint(File::Spec->catfile($project_fit_dir, "description"));

    ## --- touch the label file
    open L, ">".File::Spec->catfile($project_fit_dir, "label");
    print L $fit{label};
    close L;

    ## --- plot the fit
    Running("Plotting fit results ...");
    $list -> selectionClear;
    if ($how==1) {		# fitting
      foreach my $d (&all_data) {
	next unless ($paths{$d}->get('plot'));
	$list -> selectionSet($paths{$d}->get('id'));
	$list -> selectionSet($paths{$d}->get('id').".0");
      };
      #$list -> selectionSet($paths{$to_plot}->get('id'));
      #$list -> selectionSet($paths{$to_plot}->get('id').'.0');
    } elsif ($how==2) {		# ff2chi-ing
      $list -> selectionSet($paths{$ff2chi_data}->get('id'));
      $list -> selectionSet($paths{$ff2chi_data}->get('id').'.0');
    };
    unless ($how == 0) {
      foreach my $p (keys %paths) {
	next unless ($paths{$p}->type eq 'path');
	$list -> selectionSet($paths{$p}->get('id')) if $paths{$p}->get('plotpath');
      };
    };
    $plot_string = "\n\n# Plot data and fit in fitting space\n";
    unless (($how==2) and (not -e $paths{$to_plot}->get('file'))) {
      $plot_string .= "read_data(file=\"" . $paths{$to_plot}->get('file') . "\",\n" .
	              "          type=chi, group=". $paths{$to_plot}->get('group') . ")\n";
    };
    $plot_string .= plot($paths{$to_plot}->get('fit_space'), 1, 1);
    $paths{data0} -> dispose($plot_string, $dmode);

  };

  ## --- if there were some bad guess parameters ...
  if (@bad_params) {
    my $all = join("\n\t", @bad_params);
    my $these = ($#bad_params) ? 'these' : 'this';
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => "The guess parameters:\n\t$all\ncould not be determined by the fit.\n\nShould Artemis change $these from guess to set?",
		     -title          => 'Artemis: Bad guess parameters...',
		     -buttons        => [qw/Yes No/],
		     -default_button => 'No',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    if ($response eq 'Yes') {
      foreach my $b (@bad_params) {
	G: foreach my $g (@gds) {
	    if (lc($b) eq lc($g->name)) {
	      $g->make(type=>"set");
	      last G;
	    };
	  };
	};
      repopulate_gds2();
      Echo("The ill-defined guess parameters were changed to set.  You might want to re-run the fit now.")
    };
  };

  ## --- almost done...
  $is_busy or $top->Unbusy;
  display_properties if $how;
  if ($warnings) {
    open W, ">".File::Spec->catfile($project_fit_dir, 'warnings');
    print W $warnings;
    close W;
    Error("Artemis found possible problems with the fit.  Check the \"Messages\" tab (Control-4) for details.");
    post_message($warnings, 'Fit warnings', 1);
    raise_palette('results');
    $update->raise;
  } elsif ($echo -> cget('-text') =~ /trap/) {
    1;
  } elsif ($echo -> cget('-text') =~ /ill-defined/) {
    1;
  } else {
    Echo(($how == 2) ?
	 "Making the sum of paths ... done!" :
	 "Running fit ... done!");
  };
  $log_params{force} = 1 if ($how_many =~ /sel/);
  project_state(0) if $how;
};



# swiped from the old Ifeffit::IO:
#   change (3,1,14,5,15,2,13,7,8,6,12) to "1-3,5-8,12-15"
sub normalize_paths {
  my @tmplist;                  # expand 'X-Y'
  map { push @tmplist, ($_ =~ /(\d+)-(\d+)/) ? $1 .. $2 : $_ } @{$_[0]};
  my @list   = grep /\d+/, @tmplist; # weed out non-integers
  @list      = sort {$a<=>$b} @list; # sort 'em
  my $this   = shift(@list);
  my $string = $this;
  my ($prev, $concat) = ('', '');
  while (@list) {
    $prev   = $this;
    $this      = shift(@list);
    if ($this == $prev+1) {
      $concat  = "-";
    } else {
      $concat  = ",";
      $string .= join("", "-", $prev, $concat, $this);
    };
    $prev = $this;
  };
  ($concat eq "-") and $string .= $concat . $this;
  return $string;
};


## this sorts the set parameter objects in an order such that the sets that
## depend on other sets are declared after the ones they depend upon.  The
## logic is this: $a is greater than $b if $a's math expression uses $b's name
## or else sort alphabetically by math expression (which puts the
## number-valued sets first)
sub byuse {
  ($a->mathexp =~ /\b$b->{name}\b/i) <=> ($b->mathexp =~ /\b$a->{name}\b/i)
    ||
  (lc($a->mathexp) cmp lc($b->mathexp))
};


sub fix_residuals {
  my $d = $_[0];
  my $g = $paths{$d}->get('group');
  if (lc($paths{$d}->get('fit_space')) eq 'k') {
    my @xarray = Ifeffit::get_array($g."_res.k");
    my @yarray = Ifeffit::get_array($g."_res.chi");
    my ($min, $max) = (0, $#xarray);
    foreach my $i (0 .. $#xarray) {
      next if (($xarray[$i] > $paths{$d}->get('rmin')) and
	       ($xarray[$i] < $paths{$d}->get('rmax')));
      $yarray[$i] = 0;
      ## ($min = $i-1), last if ($xarray[$i] > $paths{$d}->get('kmin'));
    };
    ## foreach my $i (reverse (0 .. $#xarray)) {
    ##  ($max = $i+1), last if  ($xarray[$i] < $paths{$d}->get('kmax'));
    ## };
    ## @xarray = splice(@xarray, $min, $max-$min+1);
    ## @yarray = splice(@yarray, $min, $max-$min+1);
    Ifeffit::put_array($g."_res.k",   \@xarray);
    Ifeffit::put_array($g."_res.chi", \@yarray);
  } elsif (lc($paths{$d}->get('fit_space')) eq 'r') {
    my @xarray = Ifeffit::get_array($g."_res.r");
    my @yarray = Ifeffit::get_array($g."_res.chir_re");
    my @zarray = Ifeffit::get_array($g."_res.chir_im");
    my ($min, $max) = (0, $#xarray);
    foreach my $i (0 .. $#xarray) {
      next if (($xarray[$i] > $paths{$d}->get('rmin')) and
	       ($xarray[$i] < $paths{$d}->get('rmax')));
      $yarray[$i]=EPSILON, $zarray[$i]=0;
      ## ($min = $i-1), last if ($xarray[$i] > $paths{$d}->get('rmin'));
    };
    ## foreach my $i (reverse (0 .. $#xarray)) {
    ##   ($max = $i+1), last if ($xarray[$i] < $paths{$d}->get('rmax'));
    ## };
    ## @xarray = splice(@xarray, $min, $max-$min+1);
    ## @yarray = splice(@yarray, $min, $max-$min+1);
    ## @zarray = splice(@zarray, $min, $max-$min+1);
    Ifeffit::put_array($g."_res.r",       \@xarray);
    Ifeffit::put_array($g."_res.chir_re", \@yarray);
    Ifeffit::put_array($g."_res.chir_im", \@zarray);
  } elsif (lc($paths{$d}->get('fit_space')) eq 'q') {
    my @xarray = Ifeffit::get_array($g."_res.q");
    my @yarray = Ifeffit::get_array($g."_res.chiq_re");
    my @zarray = Ifeffit::get_array($g."_res.chiq_im");
    my ($min, $max) = (0, $#xarray);
    foreach my $i (0 .. $#xarray) {
      next if (($xarray[$i] > $paths{$d}->get('rmin')) and
	       ($xarray[$i] < $paths{$d}->get('rmax')));
      $yarray[$i]=EPSILON, $zarray[$i]=0;
      ## ($min = $i-1), last if ($xarray[$i] > $paths{$d}->get('kmin'));
    };
    ## foreach my $i (reverse (0 .. $#xarray)) {
    ##   ($max = $i+1), last if  ($xarray[$i] < $paths{$d}->get('kmax'));
    ## };
    ## @xarray = splice(@xarray, $min, $max-$min+1);
    ## @zarray = splice(@zarray, $min, $max-$min+1);
    Ifeffit::put_array($g."_res.q",       \@xarray);
    Ifeffit::put_array($g."_res.chiq_re", \@yarray);
    Ifeffit::put_array($g."_res.chiq_im", \@zarray);
  };
};


sub erase_all_variables { &unguess };

sub unguess {
  return "unguess\n";
};

sub fit_toggle_new {
  my ($rpfd, $how) = @_;
  my $prev_label = "";
  if (-e File::Spec->catfile($project_folder, "fits",
			     sprintf("fit%4.4d", $fit{count}), 'label')) {
    open PL, File::Spec->catfile($project_folder, "fits",
				 sprintf("fit%4.4d", $fit{count}), 'label');
    $prev_label = <PL>;
    close PL;
  };
  ($prev_label =~ s/\bsum\b/fit/) if ($how == 1);
  ($prev_label =~ s/\bfit\b/sum/) if ($how == 2);

  ## get the previous fit count number and set $fit{count} according
  ## to how it is being toggled.
  opendir F, File::Spec->catfile($project_folder, "fits");
  my @fits = sort( grep {/fit\d+/ and -d  File::Spec->catfile($project_folder, "fits", $_)} readdir(F) );
  closedir F;
  my $prev = sprintf("%d", substr($fits[$#fits],3));
  if ($fit{new}) {
    $fit{count} = $prev+1;
  } else {
    $fit{count} = $prev;
  };
  ## only fix the label and comment if the user is sticking with the
  ## defaults, don't change them is they appear to be user chosen
  if ($fit{label} =~ /^(fit|sum)\s+\d+$/) {
    $fit{label}     = $prev_label;
    $fit{label}   ||= ($how == 1) ? "fit $fit{count}"  : "sum $fit{count}";
    $fit{label}    =~ s/\b$prev\b/$fit{count}/g;
  };
##   if ($fit{comment} =~ /^(Fit|Sum)\s+\#\d+$/) {
##     $fit{comment}   = $props{Comment};
##     ($fit{comment} =~ s/\bSummation\b/Fit/) if ($how == 1);
##     ($fit{comment} =~ s/\bFit\b/Sum/) if ($how == 2);
##     $fit{comment} ||= ($how == 1) ? "Fit #$fit{count}" : "Summation #$fit{count}";
##     $fit{comment}  =~ s/\b$prev\b/$fit{count}/g;
##   };
  $fit{fom} = $fit{count};
  $$rpfd = File::Spec->catfile($project_folder, "fits",
			       sprintf("fit%4.4d", $fit{count}));
};

##  END OF THE FITTING SUBSECTION

