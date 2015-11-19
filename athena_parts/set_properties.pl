## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006, 2008 Bruce Ravel
##
##  This section of the code contains the subroutine for setting
##  properties for display of a newly selected group

sub set_properties {
  my $how = shift;
  my $item = shift;
  my $saving = shift;
  my @normal   = (-fill   =>$config{colors}{background},
		  -outline=>$config{colors}{background});
  my @selected = (-fill   =>$config{colors}{current},
		  -outline=>$config{colors}{current});

  ## fixed step may not be up to date if the fixstep button was
  ## pressed, then the step size was edited
  $groups{$current} -> make(bkg_step => $widget{bkg_step}->cget('-value')) if $groups{$current}->{bkg_fixstep};

  #return if (($fat_showing eq 'normal') and ($item eq $current));

  ## a regex to match %grab buttons *not* on the main page
  my $grabskip = join("|", qw(deg lr peak etrun sta));
  my ($blue, $cyan, $grey, $black, $h_font) = ($config{colors}{activehighlightcolor},
					       $config{colors}{requiresupdate},
					       $config{colors}{disabledforeground},
					       $config{colors}{foreground},
					       $config{fonts}{bold});
  my $textcolor = $config{colors}{foreground};

  ## place a mark in the skinny window indicating which group is current
  my ($check, $widg, $rect, $prev);
  if ($current) {
    $rect = $groups{$current}->{rect};
    $list -> itemconfigure($rect, @normal);
    update_hook($current);
  };
  $prev = $current;
  $current = $item;
  if ($groups{$current}->{frozen}) {
    #($blue, $cyan) = ($config{colors}{frozen}, $config{colors}{frozenrequiresupdate});
    #$textcolor = $config{colors}{frozen};
    $h_font = $config{fonts}{boldit};
    @selected = (-fill   =>$config{colors}{frozencurrent},
		 -outline=>$config{colors}{frozencurrent});
  };
  $rect = $groups{$current}->{rect};
  $list -> itemconfigure($rect, @selected);
  ## restore normal text size/color to this label
  $list -> itemconfigure($groups{$current}->{text},
			 -fill => $textcolor,
			 -font => ($groups{$current}->{frozen}) ? $config{fonts}{medit} : $config{fonts}{med});

  ($how == 1) or Echonow("displaying parameters for group \"$groups{$item}->{label}\"");

  ## only want to do a Busy if something else isn't already doing so
  ## because we do not want to release the grab at the end of this
  ## routine should something else need to continue the grab after
  ## this is finished
  my $is_busy = grep (/Busy/, $top->bindtags);
  #print join(" ", "before", $top->bindtags), $/;
  $top -> Busy unless $is_busy;
  #print join(" ", "after", $top->bindtags), $/;

  ## these two widgets should be uneditable but selectable

  $widget{current} -> configure(qw/-state normal/);
  $widget{current} -> delete(qw/0 end/);
  if ($use_default) {
    $widget{current} -> insert(0, $groups{$item}->{label});
  } else {
    if ($item eq "Default Parameters") {
      $widget{current} -> insert(0, "<no files loaded>");
      project_state(1);
    } else {
      $widget{current} -> insert(0, $groups{$item}->{label});
    };
  };
  $widget{current} -> configure(qw/-state disabled/);

  $widget{group} -> configure(qw/-state normal/);
  $widget{group} -> delete(qw/0 end/);
  if ($use_default) {
    $widget{group} -> insert(0, $groups{$item}->{label});
  } else {
    $widget{group} -> insert(0, ($item eq "Default Parameters") ? "" :
			       $groups{$item}->{group});
  };
  $widget{group} -> configure(qw/-state disabled/);


  $widget{file} -> configure(qw/-state normal/);
  $widget{file} -> delete(qw/0 end/);
  $widget{file} -> insert(0, $groups{$item}->{file});
  $widget{file} -> xview('end');
  $widget{file} -> configure(qw/-state disabled/);

  $widget{z} -> configure(-state=>($item eq "Default Parameters") ?
			  'disabled' : 'normal');
  $widget{edge} -> configure(-state=>($item eq "Default Parameters") ?
			  'disabled' : 'normal');

  #$widget{bkg_eshift} -> configure(-text=>$groups{$current}->{bkg_eshift});
  #$widget{bkg_step}   -> configure(-text=>sprintf "%.2f", $groups{$current}->{bkg_step});

  $header{project} -> configure(-foreground=>$blue, -font=>$h_font);
  $header{current} -> configure(-foreground=>$blue, -font=>$h_font,
				-text=>$groups{$current}->{frozen} ? "  Frozen group" : "  Current group");
  $header{plot}    -> configure(-foreground=>$blue, -font=>$h_font);
  if ($item eq "Default Parameters") {
    map {$header{$_} -> configure(-foreground=>$blue, -font=>$h_font)} qw(bkg fft bft);
  };

  ## enable/disable red plotting buttons
  map {$b_red{$_} -> configure(-state=>'normal')} (keys %b_red);
  ## enable/disable "save as" menu options
  ## -1=chi rec, +1=mu, +2=norm, +3=chi(k), +4=chi(R), +5=chi(q)
  my $sep = ($Tk::VERSION > 804) ? 7 : 8;
  map {$file_menu -> menu -> entryconfigure($_, -state=>'normal')} ($sep+1 .. $sep+5);
  $data_menu -> menu -> entryconfigure(9, -state=>'disabled'); # Self Absorption
  ##$freeze_menu -> menu -> entryconfigure(1, -label=>$groups{$item}->{frozen} ? 'Unfreeze this group': 'Freeze this group');
  ## also enable/disable headers according to data type
 SWITCH:{
    ($groups{$item}->{is_xanes}) and do {
      $header{bkg} -> configure(-foreground=>($groups{$item}->{update_bkg}) ? $cyan : $blue, -font=>$h_font);
      $header{bkg_secondary} -> configure(-foreground=>($groups{$item}->{update_bkg}) ? $cyan : $blue, -font=>$h_font);
      $header{fft} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bft} -> configure(-foreground=>$grey, -font=>$h_font);
      map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'disabled')} (keys %grab);
      map {$grab{"bkg_$_"} -> configure(-state=>'normal')} (qw(pre1 pre2 nor1 nor2 e0));
      map {$b_red{$_} -> configure(-state=>'disabled')} (qw(k R q kq));
      map {$file_menu -> menu -> entryconfigure($_, -state=>'disabled')} ($sep+3 .. $sep+4);
      $data_menu -> menu -> entryconfigure(9, -state=>'normal'); # Self Absorption
      last SWITCH;
    };
    ($groups{$item}->{is_xmu}) and do {
      $header{bkg} -> configure(-foreground=>($groups{$item}->{update_bkg}) ? $cyan : $blue, -font=>$h_font);
      $header{bkg_secondary} -> configure(-foreground=>($groups{$item}->{update_bkg}) ? $cyan : $blue, -font=>$h_font);
      $header{fft} -> configure(-foreground=>($groups{$item}->{update_fft}) ? $cyan : $blue, -font=>$h_font);
      $header{bft} -> configure(-foreground=>($groups{$item}->{update_bft}) ? $cyan : $blue, -font=>$h_font);
      map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'normal')} (keys %grab);
      $data_menu -> menu -> entryconfigure(9, -state=>'normal'); # Self Absorption
      last SWITCH;
    };
    ($groups{$item}->{is_chi}) and do {
      $header{bkg} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bkg_secondary} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{fft} -> configure(-foreground=>($groups{$item}->{update_fft}) ? $cyan : $blue, -font=>$h_font);
      $header{bft} -> configure(-foreground=>($groups{$item}->{update_bft}) ? $cyan : $blue, -font=>$h_font);
      map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'disabled')} (keys %grab);
      map {$grab{$_} -> configure(-state=>'normal')} (qw/fft_kmin fft_kmax bft_rmin bft_rmax/);
      map {$b_red{$_} -> configure(-state=>'disabled')} (qw(E));
      map {$file_menu -> menu -> entryconfigure($_, -state=>'disabled')} ($sep+1 .. $sep+2);
      $data_menu -> menu -> entryconfigure(9, -state=>'normal'); # Self Absorption
      last SWITCH;
    };
    ($groups{$item}->{is_rsp}) and do {
      $header{bkg} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bkg_secondary} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{fft} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bft} -> configure(-foreground=>($groups{$item}->{update_bft}) ? $cyan : $blue, -font=>$h_font);
      map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'disabled')} (keys %grab);
      map {$grab{$_} -> configure(-state=>'normal')} (qw/bft_rmin bft_rmax/);
      map {$b_red{$_} -> configure(-state=>'disabled')} (qw(E k kq));
      map {$file_menu -> menu -> entryconfigure($_, -state=>'disabled')} ($sep+1 .. $sep+3);
      last SWITCH;
    };
    ($groups{$item}->{is_qsp}) and do {
      $header{bkg} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bkg_secondary} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{fft} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bft} -> configure(-foreground=>$grey, -font=>$h_font);
      map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'disabled')} (keys %grab);
      map {$b_red{$_} -> configure(-state=>'disabled')} (qw(E k R kq));
      map {$file_menu -> menu -> entryconfigure($_, -state=>'disabled')} ($sep+1 .. $sep+4);
      last SWITCH;
    };
    ($groups{$item}->{not_data}) and do {
      $header{bkg} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bkg_secondary} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{fft} -> configure(-foreground=>$grey, -font=>$h_font);
      $header{bft} -> configure(-foreground=>$grey, -font=>$h_font);
      map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'disabled')} (keys %grab);
      map {$b_red{$_} -> configure(-state=>'disabled')} (qw(k R q kq));
      map {$file_menu -> menu -> entryconfigure($_, -state=>'disabled')} ($sep+2 .. $sep+5);
      last SWITCH;
    };
  };
  if (not $groups{$item}->{is_xmu}) {
    $widget{"bkg_$_"} -> configure(-state=>'disabled')
      foreach (qw(alg fixstep flatten fnorm nnorm1 nnorm2 nnorm3));
  } else {
    $widget{"bkg_$_"} -> configure(-state=>'normal')
      foreach (qw(fixstep flatten fnorm nnorm1 nnorm2 nnorm3));
    $widget{bkg_step} -> configure(-foreground => $config{colors}{foreground});
  };
  $widget{fft_pc} -> configure(-state=>'normal');



  foreach my $x ($groups{$item} -> Keys) {
    next if (($x eq "file") or ($x eq "line"));
    next if ($x eq "fft_edge");
    next if (($x eq "bkg_z") or ($x eq "fft_edge"));
    next if ($x eq "bkg_nclamp");
    next if ($x eq "bkg_fitted_step");
    next if ($x eq "bkg_stan_lab");

    ## treat BrowsEntry widgets specially
    my $normal = (ref($widget{$x}) =~ m{BrowseEntry}) ? 'readonly' : 'normal';

    if ($x eq "bkg_cl") {
      if ($groups{$item}->{is_diff}) {
	$widget{bkg_alg} -> configure(-state=>'disabled');
	#$widget{z}   -> configure(-state=>'disabled');
      } elsif ($groups{$item}->{is_xmu}) {
	$widget{bkg_alg} -> configure(-state=>$normal);
	$menus{bkg_alg} = ($groups{$item}->{bkg_cl}) ? 'CLnorm' : 'Autobk';
	#$widget{z} ->
	#  configure(-state => ($menus{bkg_alg} eq 'CLnorm') ? $normal : 'disabled');
      } else {
	$widget{bkg_alg} -> configure(-state=>'disabled');
      };
#     } elsif ($x eq "bkg_z") {
#       $widget{z} -> configure(-validate=>'none');
#       $menus{bkg_z} = $groups{$item}->{bkg_z};
#       $widget{z} -> configure(-validate=>'focusout');
    } else {
      #($x eq 'bkg_step') and print "bkg_step\n";
      $widget{$x} -> configure(-state=>$normal);
      if ($widget{$x} =~ /Entry/) {
	$widget{$x} -> configure(-validate=>'none');
	$widget{$x} -> delete(qw/0 end/);
	$widget{$x} -> insert(0, $groups{$item}->{$x});
	$widget{$x} -> configure(-validate=>'key');
      } elsif ($widget{$x} =~ /Optionmenu/) {
	$menus{$x} = $groups{$item}->{$x};
      } elsif ($widget{$x} =~ /Check/) {
	$menus{$x} = $groups{$item}->{$x};
      };
    };
    next unless (Exists($widget{$x}));
    $widget{$x} -> configure(-state=>$normal), next if ($x =~ /^plot/);
    ## disable widgets in the fields according to data type
  SWITCH: {
      ($groups{$item}->{is_xanes}) and do {
	if (($x =~ /^bkg/) or ($x eq "importance")) {
	  $widget{$x} -> configure(-state=>$normal);
	  $widget{$x} -> configure(-foreground=>$black);
	} else {
	  $widget{$x} -> configure(-state=>'disable');
	  $widget{$x} -> configure(-foreground=>$grey);
	};
	$widget{$x} -> configure(-state=>'disable')
	  if ($x =~ /(clamp[12]|kw|rbkg|spl[12]e?|stan)/);
	last SWITCH;
      };
      ($groups{$item}->{is_xmu}) and do {
	$widget{$x} -> configure(-state=>$normal);
	if ($groups{$item}->{bkg_cl}) {
	  if ($x =~ /^bkg_spl/) {
	    $widget{$x} -> configure(-state=>'disabled');
	    $grab{$x} -> configure(-state=>'disabled');
	  };
	};
	$widget{$x} -> configure(-foreground=>$black) unless (ref($widget{$x}) =~ /NumEntry/);
	if ($groups{$item}->{is_nor}) {
	  if ($x =~ /bkg_(pre[12]|nor[12])/) {
	    $widget{$x} -> configure(-state=>'disabled', -foreground=>$grey);
	    $grab{$x} -> configure(-state=>'disabled');
	  };
	  #if ($x =~ /bkg_f(ixstep|latten)/) {
	  if ($x =~ /bkg_fixstep/) {
	    $widget{$x} -> configure(-state=>'disabled', -foreground=>$grey);
	  };
	};
	last SWITCH;
      };
      ($groups{$item}->{is_chi}) and do {
	if ($x =~ /^bkg/) {
	  $widget{$x} -> configure(-state=>'disabled');
	  $widget{$x} -> configure(-foreground=>$grey);
	} else {
	  $widget{$x} -> configure(-state=>$normal);
	  $widget{$x} -> configure(-foreground=>$black);
	};
	last SWITCH;
      };
      ($groups{$item}->{is_rsp}) and do {
	if ($x =~ /^(bkg|fft)/) {
	  $widget{$x} -> configure(-state=>'disabled');
	  $widget{$x} -> configure(-foreground=>$grey);
	} else {
	  $widget{$x} -> configure(-state=>$normal);
	  $widget{$x} -> configure(-foreground=>$black);
	};
	last SWITCH;
      };
      ($groups{$item}->{is_qsp}) and do {
	$widget{$x} -> configure(-state=>'disabled');
	$widget{$x} -> configure(-foreground=>$grey);
	last SWITCH;
      };
      ($groups{$item}->{not_data}) and do {
	$widget{$x} -> configure(-state=>'disabled');
	$widget{$x} -> configure(-foreground=>$grey);
	last SWITCH;
      };
    };
  };

  if ($groups{$item}->{frozen}) {
    $widget{"bkg_$_"} -> configure(-state=>'disabled')
      foreach (qw(fixstep flatten fnorm nnorm1 nnorm2 nnorm3 step stan));
    $widget{fft_pc} -> configure(-state=>'disabled');
    map {($_ =~ /^($grabskip)/) or $grab{$_} -> configure(-state=>'disabled')} (keys %grab);
  };
  map {$values_menubutton -> menu -> entryconfigure($_, -state=>$groups{$item}->{frozen} ? 'disabled' : 'normal')}
    (3, 10);


  ## set various buttons
  foreach (qw(fixstep flatten fnorm nnorm tie_e0)) {
    $menus{"bkg_$_"} = $groups{$item}->{"bkg_$_"};
  };
  ## disable these until it's all working
  $widget{"bkg_fnorm"} -> configure(-state=>'disabled');


  ## mark eshift if this is a reference or a group with a reference
  my ($red, $bold, $normal) = ($config{colors}{button}, $config{fonts}{entrybold}, $config{fonts}{entry});
  if ($groups{$item}->{reference}) {
    $widget{bkg_eshift} -> configure(-foreground => $red,
				     -font       => $bold,)
  } else {
    $widget{bkg_eshift} -> configure(-foreground => $black,
				     -font       => $normal,)
  };

  ## set up the Standard optionmenu -- the list may have changed recently...
  ## (commented out stuff is from Optionmenu, tidy up when stable)
  if (($groups{$item}->{bkg_stan} ne 'None')
      and (exists $groups{$groups{$item}->{bkg_stan}})) {
    ##    $menus{bkg_stan} = $groups{$groups{$item}->{bkg_stan}}->{label};
    $groups{$groups{$item}->{bkg_stan}}->dispatch_bkg($dmode) if
      $groups{$groups{$item}->{bkg_stan}}->{update_bkg};
  } else {
    $menus{bkg_stan} = 'None';
    $menus{bkg_stan_lab} = '0: None';
    $groups{$item}->make(bkg_stan=>'None',
			 bkg_stan_lab=>'0: None');
  };

  $widget{bkg_stan} -> delete(0, 'end');
  $widget{bkg_stan} -> insert("end", "0: None");
  my @list = ('None');
  my $i = 1;
  foreach my $x (&sorted_group_list) {
    next if ($x eq $current);
    next unless (($groups{$x}->{is_xmu}) or ($groups{$x}->{is_chi}));
    push @list, $x;
    $widget{bkg_stan} -> insert("end", "$i: $groups{$x}->{label}");
    my $label = $groups{$groups{$item}->{bkg_stan}}->{label};
    if ($groups{$item}->{bkg_stan} eq $x) {
      $menus{bkg_stan_lab} = "$i: $label";
      $groups{$item} -> make(bkg_stan_lab => "$i: $label");
    };
    ++$i;
  };
  $menus{keys} = [@list];

  ## is this group a merge?
  $plot_menu -> menu -> entryconfigure(5, -state=>($groups{$item}->{is_merge}) ? 'normal' : 'disabled');
  $plot_menu -> menu -> entryconfigure(6, -state=>($groups{$item}->{i0}) ? 'normal' : 'disabled');
  $plot_menu -> menu -> entryconfigure(7, -state=>($groups{$item}->{i0}) ? 'normal' : 'disabled');
  ## can chi(E) be plotted?
  my $ok = ($groups{$item}->{is_xmu} or $groups{$item}->{is_nor} or
    $groups{$item}->{is_chi});
  #$plot_menu -> menu -> entryconfigure(9, -state=> $ok ? 'normal' : 'disabled');
  #$plot_menu -> menu -> entryconfigure(10, -state=> 'normal');
  ## is this an xmu group?  If so enable thingies to make detector
  ## groups and background group
  $ok = ($groups{$item}->{is_xmu} and $groups{$item}->{denominator}
	and (not $groups{$item}->{is_proj}));
  my $ind = 5; #($group_menubutton -> children())[0] -> index('detector');
  $group_menubutton -> menu ->
    entryconfigure($ind, -state=> $ok ? 'normal' : 'disabled');
  $group_menubutton -> menu ->
    entryconfigure($ind+1, -state=> $groups{$item}->{is_xmu} ? 'normal' : 'disabled');

  my $is_energy = not ($groups{$item}->{is_chi} or $groups{$item}->{is_rsp} or $groups{$item}->{is_qsp});
  $group_menubutton -> menu ->
    entryconfigure(8, -state=> $is_energy ? 'normal' : 'disabled');

  ## phase correction parameters (a checkbutton and two menus)
  $menus{bkg_z}     =  $groups{$item}->{bkg_z};
  $menus{fft_pc}    =  $groups{$item}->{fft_pc};
  $menus{fft_edge}  =  $groups{$item}->{fft_edge};
  #$widget{z}    -> configure(-state=>($menus{fft_pc} eq 'on') ? 'normal' : 'disabled');
  #$widget{edge} -> configure(-state=>($menus{fft_pc} eq 'on') ? 'normal' : 'disabled');

  ## deal with various parameters if something other than the normal
  ## display is present
 FAT: {
    ($saving) and do {
      1;			# do nothing more
      last FAT;
    };

    ($fat_showing eq 'peakfit') and do {
      $widget{peak_group} -> configure(-text=>$groups{$item}->{label});
      $widget{peak_save}  -> configure(-state=>'disabled');
      $widget{peak_log}   -> configure(-state=>'disabled');
      ## need to worry about non-xmu groups being selected
      unless ($groups{$item}->{is_xmu}) {
	if ($groups{$item}->{not_data}) {
	  $groups{$item}->plotE('em', $dmode, \%plot_features, \@indicator);
	} else {
	  Error("$groups{$item}->{label} cannot be plotted in energy.");
	};
	last FAT
      };
      my $r_peaks = $$hash_pointer{peaks};
      $groups{$item}->{update_bkg} and $groups{$item}->dispatch_bkg($dmode);
      $groups{$item}->{peak} and peak_fill_variables($item, $hash_pointer, $r_peaks);
      $groups{$item}->plotE('emn', $dmode, \%plot_features, \@indicator);
      my ($emin, $emax) = ($$hash_pointer{enot}+$$hash_pointer{emin},
			   $$hash_pointer{enot}+$$hash_pointer{emax});
      $groups{$item}->plot_vertical_line($emin, 0, $$hash_pointer{ymax},
					 $dmode, "fit range", $groups{$item}->{plot_yoffset});
      $groups{$item}->plot_vertical_line($emax, 0, $$hash_pointer{ymax},
					 $dmode, "", $groups{$item}->{plot_yoffset});
      $last_plot='e';
      last FAT;
    };

    ($fat_showing eq 'lograt') and do {
      $widget{lr_unknown} -> configure(-text=>$groups{$item}->{label});
      ## it is possible that the groups list has changed of late, so update
      ## the lists of standards
      my @keys = ();
      foreach my $k (&sorted_group_list) {
	($groups{$k}->{is_xmu} or $groups{$k}->{is_chi}) and push @keys, $k;
      };
      $widget{lr_menu} -> delete(0, 'end');
      my $i = 1;
      foreach my $s (@keys) {
	$widget{lr_menu} -> insert("end", "$i: $groups{$s}->{label}");
	++$i;
      };


      ## need to worry about non-xmu/chi groups being selected
      &reset_lr_data($hash_pointer, $$hash_pointer{standard}, $current)
	if ($groups{$current}->{is_xmu} or $groups{$current}->{is_chi});
      last FAT;
    };

    ($fat_showing eq 'calibrate') and do {
      $widget{cal_group} -> configure(-text=>$groups{$item}->{label});
      ## need to worry about non-xmu groups being selected
      $groups{$current} -> dispose("set $current.deriv = deriv($current.xmu)/deriv($current.energy)\n", $dmode);
      ($groups{$current}->{bkg_z}, $groups{$current}->{fft_edge})
	= find_edge($groups{$current}->{bkg_e0});
      $$hash_pointer{cal_to} = Xray::Absorption->get_energy($groups{$current}->{bkg_z},
							    $groups{$current}->{fft_edge});
      $$hash_pointer{e0} = $groups{$current}->{bkg_e0};
      ## plot this group
      $plot_features{suppress_markers} = 1;
      $groups{$current}->plotE($$hash_pointer{str}, $dmode, \%plot_features, \@indicator);
      $plot_features{suppress_markers} = 0;
      &cal_marker($current, $$hash_pointer{e0}, $$hash_pointer{str});
      last FAT;
    };

    ($fat_showing eq 'align') and do {
      ## need check for non-xmu data and for (standard->{ref} eq current)
      $widget{align_unknown} -> configure(-text=>$groups{$item}->{label});
      ##$widget{align_other_label} -> configure(-text=>"Shift \"$groups{$current}->{label}\" by ");
      $widget{align_other_label} -> configure(-text=>"Shift by ");
      $widget{align_result} -> delete(qw(0 end));
      $widget{align_result} -> insert('end', $groups{$current}->{bkg_eshift});
      $$hash_pointer{shift} = $groups{$current}->{bkg_eshift};
      $$hash_pointer{prior_shift} = $groups{$current}->{bkg_eshift};

      ## it is possible that the groups list has changed of late, so update
      ## the lists of standards
      my @keys = ();
      foreach my $k (&sorted_group_list) {
	$groups{$k}->{is_xmu} and push @keys, $k;
      };
      $widget{align_menu} -> delete(0, 'end');
      my $i = 1;
      foreach my $s (@keys) {
	$widget{align_menu} -> insert("end", "$i: $groups{$s}->{label}");
	++$i;
      };

      &do_eshift($hash_pointer, $current);
      last FAT;
    };

    ($fat_showing eq 'pixel') and do {
      $widget{pixel_unknown} -> configure(-text=>$groups{$item}->{label});
      if ($groups{$item}->{is_pixel}) {
	map {$widget{"pixel_".$_}->configure(-state=>'normal')}
	  (qw(refine replot make offset constrain linear linear_button quad));
      } else {
	map {$widget{"pixel_".$_}->configure(-state=>'disabled')}
	  (qw(refine replot make offset constrain linear linear_button quad));
      };
      ## $widget{pixel_make} -> configure(-state=>'disabled');
      &pixel_setup($hash_pointer) if $groups{$item}->{is_pixel};
      last FAT;
    };

    ($fat_showing eq 'truncate') and do {
      $widget{trun_group} -> configure(-text=>$groups{$item}->{label});
      $groups{$item} -> make(etruncate=>$widget{etruncate}->get());
      ## need to worry about non-xmu groups being selected
      $groups{$item} -> plotE('em',$dmode,\%plot_features, \@indicator);
      $last_plot = 'e';
      my $e = $groups{$item}->{etruncate};
      $groups{$item} -> dispose("set(___f = floor($item.xmu), ___c = ceil($item.xmu))\n", 1);
      my $ymin = Ifeffit::get_scalar("___f");
      my $ymax = Ifeffit::get_scalar("___c");
      $groups{$item} -> plot_vertical_line($e, $ymin, $ymax, $dmode,
					       "truncate", $groups{$item}->{plot_yoffset});
      last FAT;
    };

    ($fat_showing eq 'rebin') and do {
      $widget{rb_group} -> configure(-text=>$groups{$item}->{label});
      $$hash_pointer{abs}  = $groups{$item}->{bkg_z};
      $$hash_pointer{edge} = $groups{$item}->{bkg_e0};
      $widget{rb_plot}->configure(-state=>($groups{$item}->{is_xmu}) ? 'normal' : 'disabled');
      $widget{rb_save}->configure(-state=>'disabled');
      $groups{$item} -> plotE('em',$dmode,\%plot_features, \@indicator);
      last FAT;
    };

    ($fat_showing eq 'smooth') and do {
      $widget{sm_group} -> configure(-text=>$groups{$item}->{label});
      $groups{$item}->dispose("erase $item.smoothed", $dmode);
      $widget{sm_save}->configure(-state=>'disabled');
      $groups{$item} -> plotE('em',$dmode,\%plot_features, \@indicator);
      last FAT;
    };

    ($fat_showing eq 'convolve') and do {
      $$hash_pointer{current} = $groups{$current}->{label};
      $widget{conv_group}->configure(-state=>'disabled');
      $groups{$item}->plotE('emn', $dmode, \%plot_features, \@indicator);
      last FAT;
    };

    ($fat_showing eq 'diff') and do {
      $widget{diff_unknown} -> configure(-text=>$groups{$item}->{label});
      ## need to worry about selected group not being plottable in the
      ## difference space
      Error("Difference plot aborted: You cannot select the same data group twice!"),
	return if ($$hash_pointer{standard} eq $current);
      $$hash_pointer{integral} = "";
      my $dfg = $config{colors}{disabledforeground};
      $$hash_pointer{diff_integral_label} -> configure(-foreground=>$dfg);
      my $state = 'normal';
      my @keys = ();
      my @allkeys = (&sorted_group_list);
    SWITCH: {
	($groups{$item}->{is_diff}) and do {
	  $state = 'disabled';
	  last SWITCH;
	};
	($$hash_pointer{space} =~ /[en]/) and do {
	  ($state = 'disabled') unless $groups{$item}->{is_xmu};
	  foreach my $k (@allkeys) {
	    ($groups{$k}->{is_xmu}) and push @keys, $k;
	  };
	  last SWITCH;
	};
	($$hash_pointer{space} eq 'k') and do {
	  ($state = 'disabled') unless ($groups{$item}->{is_xmu} or $groups{$item}->{is_chi});
	  foreach my $k (@allkeys) {
	    ($groups{$k}->{is_xmu} or $groups{$k}->{is_chi}) and push @keys, $k;
	  };
	  last SWITCH;
	};
	($$hash_pointer{space} eq 'r') and do {
	  foreach my $k (@allkeys) {
	    ($groups{$k}->{is_qsp}) or push @keys, $k;
	  };
	  ($state = 'disabled') if $groups{$item}->{is_qsp};
	  last SWITCH;
	};
	($$hash_pointer{space} eq 'q') and do {
	  foreach my $k (@allkeys) {
	    ($groups{$k}->{not_data}) or push @keys, $k;
	  };
	  last SWITCH;
	};
      };
      map { $widget{'diff_'.$_} -> configure(-state=>$state) }
	(qw(savemarkedi savemarked save replot xmin xmax));
      map { $grab{'diff_'.$_} -> configure(-state=>$state) }
	(qw(xmin xmax));

      ## it is possible that the groups list has changed of late, so update
      ## the lists of standards
      $widget{diff_menu} -> delete(0, 'end');
      my $i = 1;
      foreach my $s (@keys) {
	$widget{diff_menu} -> insert("end", "$i: $groups{$s}->{label}");
	++$i;
      };

      if ($state eq 'normal') {
	my $ok = $groups{$$hash_pointer{standard}} ->
	  plot_difference($groups{$current}, $hash_pointer, $dmode, \%plot_features);
	$last_plot=$$hash_pointer{space} if $ok;
      };
      last FAT;
    };

    ($fat_showing eq 'deglitch') and do {
      $widget{deg_group} -> configure(-text=>$groups{$item}->{label});
      ## worry about non-xmu groups
      $$hash_pointer{standard} = $current;
      set_deglitch_params($hash_pointer);
      if ($$hash_pointer{space} eq 'emg') {
	$groups{$current} -> plotE('emg',$dmode,\%plot_features, \@indicator);
      } else {
	&plot_chie($current);
      };
      $last_plot = 'e';
      last FAT;
    };

    ($fat_showing eq 'lcf') and do {
      $widget{lcf_unknown} -> configure(-text=>$groups{$item}->{label});
      $widget{lcf_operations} -> entryconfigure(4, -state=>'disabled', -style=>$$hash_pointer{disabled_style});
      $widget{lcf_operations} -> entryconfigure(8, -state=>'disabled', -style=>$$hash_pointer{disabled_style});
      if ($groups{$item}->{is_chi} and ($$hash_pointer{fitspace} ne 'k')) {
	$groups{$item}->MAKE("lcf_fitspace" => 'k');
      };
      if ($groups{$item}->{is_xanes} and ($$hash_pointer{fitspace} eq 'k')) {
	$groups{$item}->MAKE("lcf_fitspace" => 'e');
      };

      ## need to initialize these for a group that doesn't have them
      $groups{$item}->{lcf_fitspace} ||= $config{linearcombo}{fitspace};
      $groups{$item}->{lcf_fitmin_k} ||= $config{linearcombo}{fitmin_k};
      $groups{$item}->{lcf_fitmax_k} ||= $config{linearcombo}{fitmax_k};
      $groups{$item}->{lcf_fitmin_e} ||= $config{linearcombo}{fitmin};
      $groups{$item}->{lcf_fitmax_e} ||= $config{linearcombo}{fitmax};
      if ($groups{$item}->{lcf_fitspace} eq 'k') {
	$groups{$item}->{lcf_fitmin} = $groups{$item}->{lcf_fitmin_k};
	$groups{$item}->{lcf_fitmax} = $groups{$item}->{lcf_fitmax_k};
      } else {
	$groups{$item}->{lcf_fitmin} = $groups{$item}->{lcf_fitmin_e};
	$groups{$item}->{lcf_fitmax} = $groups{$item}->{lcf_fitmax_e};
      };
      ## make sure these display correctly and are correctly stored in the
      ## parameters hash
      foreach (qw(fitmin fitmax)) {
	my $key = "lcf_" . $_;
	$widget{$key} -> configure(-validate=>"none");
	$widget{$key} -> delete(0, 'end');
	$widget{$key} -> insert(0, $groups{$item}->{$key});
	$widget{$key} -> configure(-validate=>"key");
	$$hash_pointer{$_} = $groups{$item}->{$key};
      };

      unless ($groups{$item}->{is_xmu}) {
	$widget{lcf_fit} -> configure(-state=>'disabled');
	last FAT;
      };
      $$hash_pointer{fitspace} = $groups{$item}->{"lcf_fitspace"} || $$hash_pointer{fitspace};
      $$hash_pointer{linear}   = $groups{$item}->{"lcf_linear"}   || $$hash_pointer{linear};
      $$hash_pointer{nonneg}   = $groups{$item}->{"lcf_nonneg"}   || $$hash_pointer{nonneg};
      $$hash_pointer{100}      = $groups{$item}->{"lcf_100"}      || $$hash_pointer{100};
      $$hash_pointer{e0all}    = $groups{$item}->{"lcf_e0all"}    || $$hash_pointer{e0all};

      ## it is possible that the groups list has changed of late, so update
      ## the lists of standards
      my @keys = ('None');
      foreach my $k (&sorted_group_list) {
	($groups{$k}->{is_xmu} or $groups{$k}->{is_chi}) and push @keys, $k;
      };
      $$hash_pointer{keys} = \@keys;
      ## when switching groups, use the standards associated with the
      ## group, if available, else use the standards already in the
      ## table
      if (exists $groups{$item}->{lcf_fit} and $groups{$item}->{lcf_fit}) {
	my $any_set = 0;
	foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
	  ++$any_set if (exists($groups{$item}->{"lcf_standard$i"}) and ($groups{$item}->{"lcf_standard$i"} ne 'None'));
	};
	foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
	  my $test = (exists($groups{$item}->{"lcf_standard$i"}) and ($groups{$item}->{"lcf_standard$i"} ne 'None'));
	  $$hash_pointer{"standard$i"} = ($any_set) ? $groups{$item}->{"lcf_standard$i"}  : $$hash_pointer{"standard$i"};
	  $$hash_pointer{"standard$i"} = "None" unless defined $$hash_pointer{"standard$i"};
	  $$hash_pointer{"e0$i"}       = ($any_set) ? $groups{$item}->{"lcf_e0$i"}	  : $$hash_pointer{"e0$i"};
	  $$hash_pointer{"e0val$i"}    = ($any_set) ? $groups{$item}->{"lcf_e0val$i"}     : $$hash_pointer{"e0val$i"};
	  $$hash_pointer{"value$i"}    = ($any_set) ? $groups{$item}->{"lcf_value$i"}     : $$hash_pointer{"value$i"};

	  $widget{"lcf_standard_list$i"} -> delete(0, "end");
	  $widget{"lcf_standard_list$i"} -> insert("end", "0: None");
	  my $j = 1;
	  foreach my $s (@keys) {
	    next if ($s eq 'None');
	    $groups{$s}->MAKE(lcf_menu_label => "$j: $groups{$s}->{label}");
	    $widget{"lcf_standard_list$i"} -> insert("end", "$j: $groups{$s}->{label}");
	    ++$j;
	  };
	  if (not exists $groups{$item}->{"lcf_standard$i"}) {
	    $$hash_pointer{"standard_lab$i"} = "0: None";
	  } elsif ($groups{$item}->{"lcf_standard$i"} eq 'None') {
	    $$hash_pointer{"standard_lab$i"} = "0: None";
	  } else {
	    $$hash_pointer{"standard_lab$i"} = ($any_set) ? $groups{$groups{$item}->{"lcf_standard$i"}}->{lcf_menu_label} : $$hash_pointer{"standard_lab$i"};
	  };
	  ## make sure menu labels are up to date
	  #my $label = "";
	  #($label = $groups{$groups{$current}->{"lcf_standard$i"}}->{lcf_menu_label})
	  #  if (exists $groups{$current}->{"lcf_standard$i"});
	  #$$hash_pointer{"standard_lab$i"} = $label || $$hash_pointer{"standard_lab$i"};
	};
	lcf_results($hash_pointer);
	$widget{lcf_operations} -> entryconfigure(4, -state=>'normal', -style=>$$hash_pointer{normal_style});

      } else {
	$widget{lcf_text} -> delete('1.0', 'end');
      };

      $$hash_pointer{fitmin} = $groups{$item}->{lcf_fitmin};
      $$hash_pointer{fitmax} = $groups{$item}->{lcf_fitmax};
      if ($$hash_pointer{fitspace} eq 'k') {
	$widget{lcf_operations} -> entryconfigure(7, -state=>'normal', -style=>$$hash_pointer{normal_style});
	lcf_quickplot_k($hash_pointer);
      } else {
	$widget{lcf_operations} -> entryconfigure(7, -state=>'disabled', -style=>$$hash_pointer{disabled_style});
	lcf_quickplot_e($hash_pointer);
      };
      my $how = ($groups{$item}->{lcf_fit}) ? 0 : 2;
      lcf_initialize($hash_pointer, $how);
      $widget{lcf_notebook} -> raise('standards') unless ($widget{lcf_notebook}->raised eq 'results');
      ##       if (exists $lcf_data{$item}) {
      ## 	$widget{lcf_notebook} -> pageconfigure('combinatorics', -state=>'normal');
      ## 	lcf_display();
      ##       } else {
      ## 	## empty out both combinatorics tables
      ## 	$widget{lcf_select_table}->delete('all');
      ## 	$widget{lcf_result_table}->delete('all');
      ## 	$widget{lcf_notebook} -> raise('standards');
      ## 	$widget{lcf_notebook} -> pageconfigure('combinatorics', -state=>'disabled');
      ##       };
      last FAT;
    };

    ($fat_showing eq 'sa') and do {
      $widget{safluo_group} -> configure(-text=>$groups{$item}->{label});
      $widget{safluo_elem}  -> configure(-text=>$groups{$item}->{bkg_z});
      $widget{safluo_edge}  -> configure(-text=>$groups{$item}->{fft_edge});
      my $is_xmu = $groups{$item}->{is_xmu};
      $widget{safluo_plot} -> configure(-state=>($is_xmu) ? 'normal' : 'disabled');
      $widget{safluo_make} -> configure(-state=>'disabled');
      $widget{safluo_fluo} -> configure(-state=>'normal');
      unless ($is_xmu) {	# deal with chi(k) record
	($$hash_pointer{algorithm} = "booth") if ($$hash_pointer{algorithm} eq 'fluo');
	$widget{safluo_fluo} -> configure(-state=>'disabled');
      };
      foreach my $k (qw(formula angle_in angle_out thickness)) {
	$$hash_pointer{$k} = $groups{$item}->{"sa_$k"} if ((exists $groups{$item}->{"sa_$k"}) and
							   ($groups{$item}->{"sa_$k"} !~ /^\s*$/));
      };
      if ($$hash_pointer{algorithm} eq 'fluo') {
	$groups{$item}->plotE('emn', $dmode, \%plot_features, \@indicator) if $is_xmu;
	$last_plot = 'e';
	$plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      } elsif ($$hash_pointer{algorithm} =~ /atoms|booth|troger/) {
	my $str = 'k'.$plot_features{k_w};
	$groups{$current} -> plotk($str, $dmode, \%plot_features, \@indicator);
	$last_plot='k';
	$plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      };
      last FAT;
    };

    ($fat_showing eq 'mee') and do {
      my $is_xmu = $groups{$item}->{is_xmu};
      map {$widget{"mee_$_"} -> configure(-state=>($is_xmu) ? 'normal' : 'disabled')}
	qw(store make e k r q);
      my $key = join("_", lc($groups{$item}->{bkg_z}), lc($groups{$item}->{fft_edge}));
      $$hash_pointer{shift} = $groups{$item}->{mee_en} || $mee_energies{energies}{$key} || 100;
      $$hash_pointer{width} = $groups{$item}->{mee_wi} || 10;
      $$hash_pointer{amp}   = $groups{$item}->{mee_am} || 0.01;
      $$hash_pointer{key}   = $key;
      $widget{mee_data} -> configure(-text=>$groups{$item}->{label});
      last FAT;
    };

    ## this section is the demo section, add a new section for a new
    ## analysis chore as appropriate
    ($fat_showing eq 'demo') and do {
      ## update the "unknown" with this label, if needed
      $widget{foobar_unknown} -> configure(-text=>$groups{$item}->{label});
      ## you may wish to fret about the standard and unknown being the
      ## same group and do something sensible

      ## set any other foobar_params as needed using
      ## $$hash_pointer{whatever} = "whatever";

      ## do you need to make a plot?  it is best to use a plotting
      ## method and don't forget to set the $last_plot global variable
      ## so the pluck buttons work correctly
      last FAT;
    };

    ($fat_showing eq 'series') and do {
      my $this = $$hash_pointer{param};
      $$hash_pointer{group} = $current;
      $$hash_pointer{label}   = $groups{$current}->{label};
      $$hash_pointer{current} = sprintf("%.3f", $groups{$current}->{$this});
      $$hash_pointer{begin}   = sprintf("%.3f", $groups{$current}->{$this});
      last FAT;
    };

    ($fat_showing eq 'teach_ft') and do {
      last FAT;
    };

    ## this is what is done if the normal view is showing.
    do {
      last FAT         if ($config{general}{groupreplot} eq 'none');
      plot_current_e() if ($config{general}{groupreplot} eq 'e');
      plot_current_k() if ($config{general}{groupreplot} eq 'k');
      plot_current_r() if ($config{general}{groupreplot} eq 'r');
      plot_current_q() if ($config{general}{groupreplot} eq 'q'); #  ()
      last FAT;
    };

  };  # end of non-normal display switch


  ## and finally, put titles in the title display
  if ($prev and defined $groups{$prev}) {
    refresh_titles($groups{$prev}) unless (($prev eq 'Default Parameters') or
					   ($current eq 'Default Parameters'));
  };
  $notes{titles} -> configure(-state=>'normal');
  $notes{titles} -> delete(qw/1.0 end/);
  unless ($item eq "Default Parameters") {
    $groups{$item} -> get_titles;
    foreach (@{$groups{$item}->{titles}}) {
      $notes{titles} -> insert('end', $_."\n", "text");
    };
  };

  sanity_check($item) if ((not $reading_project) and (not $saving) and ($fat_showing eq 'normal'));

  $top -> Unbusy unless $is_busy;
  return unless ($fat_showing eq 'normal');
  ($how == 1) or Echonow("displaying parameters for group \"$groups{$item}->{label}\" ... done.");
};

sub sanity_check {
  my $item = shift;
  my $problems = $groups{$item}->sanity;
  if ($problems) {
    Error("Athena has found suspicious values for one or more parameters.  Please check the indicated value.");
    my $d = $top->DialogBox(-title   => "Athena: Suspicious parameter values!",
			    -buttons => ["OK"],
			    -popover => 'cursor');
    my $r = $d -> add('ROText',
		      -font=>$config{fonts}{fixed},
		     )
      -> pack();
    $r -> tagConfigure("text", -font=>$config{fonts}{fixedsm});
    $r -> insert('1.0', $problems, 'text');
    $r -> insert('1.0', "The following problems were found for group \"$groups{$item}->{label}\"\n\n", 'text');
    $r -> insert('end', "\nYou should fix these values before continuing analysis of these data.\n", 'text');
    $d -> Show;
    #print $problems;
    return 1;
  };
  return 0;
};


## END OF SET PROPERTIES SUBSECTION
##########################################################################################
