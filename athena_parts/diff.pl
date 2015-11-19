## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006, 2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  difference spectra

sub difference {
  Echo("No data!"), return unless $current;
  my $space = $_[0];
  #$space = ($space eq 'x') ? 'em' : 'em'.$space;
  my %sp = (e=>'energy', n=>'energy', k=>'k', r=>'R', 'q'=>'q');

  Echo("No data!"), return if ($current eq "Default Parameters");

  ## make the list of groups that can be difference-d in the requested space
  my @allkeys = &sorted_group_list;
  my @keys = ();
  my $header = "";
  my $ysuff;
 SWITCH: {
    ($space eq 'e') and do {
      foreach my $k (@allkeys) {
	($groups{$k}->{is_xmu}) and push @keys, $k;
      };
      $header = "Compute the Difference of mu(E) Spectra";
      $ysuff  = 'xmu';
      last SWITCH;
    };
    ($space eq 'n') and do {
      foreach my $k (@allkeys) {
	(($groups{$k}->{is_xmu}) or ($groups{$k}->{is_nor})) and push @keys, $k;
      };
      $header = "Compute the Difference of Normalized Spectra";
      $ysuff  = $groups{$keys[0]}->{bkg_flatten} ? 'flat' : 'norm';
      last SWITCH;
    };
    ($space eq 'k') and do {
      foreach my $k (@allkeys) {
	(($groups{$k}->{is_xmu}) or ($groups{$k}->{is_nor}) or ($groups{$k}->{is_chi}))
	  and push @keys, $k;
      };
      $header = "Compute the Difference of chi(k)";
      $ysuff  = 'chi';
      last SWITCH;
    };
    ($space eq 'r') and do {
      foreach my $k (@allkeys) {
	($groups{$k}->{is_qsp}) or push @keys, $k;
      };
      $header = "Compute the Difference of chi(R)";
      if    ($plot_features{r_mag}) {$ysuff = "chir_mag"}
      elsif ($plot_features{r_re})  {$ysuff = "chir_re"}
      elsif ($plot_features{r_im})  {$ysuff = "chir_im"}
      elsif ($plot_features{r_pha}) {$ysuff = "chir_pha"};
      last SWITCH;
    };
    1 and do {			# difference in q, any'll do
      foreach my $k (@allkeys) {
	($groups{$k}->{not_data}) or push @keys, $k;
      };
      $header = "Compute the Difference of chi(q)";
      if    ($plot_features{'q_mag'}) {$ysuff = 'chiq_mag'}
      elsif ($plot_features{'q_re'})  {$ysuff = "chiq_re"}
      elsif ($plot_features{'q_im'})  {$ysuff = "chiq_im"}
      elsif ($plot_features{'q_pha'}) {$ysuff = "chiq_pha"};
      last SWITCH;
    };
  };
  Echo("You need two or more groups that can display in $sp{$space} to compute that difference spectrum"),
    return unless ($#keys >= 1);


  my %diff_params = (standard	    => $keys[0],
		     standard_label => "1: ".$groups{$keys[0]}->{label},
		     keys           => \@keys,
		     space	    => $space,
		     xnot           => 0,
		     xsuff          => $sp{$space},
		     ysuff          => $ysuff,
		     xmin           => 0,
		     xmax           => 0,
		     invert         => 0,
		     components     => 0,
		     list           => $list,
		     groups         => \%groups,
		     noplot         => 0,
    ## The options are
    ##    e, n, d            mu, normalized mu, or deriv of mu
    ##    kw, 0, 1, 2, 3, e  chi(k) with k-weight or chi(E) with k-weight
    ##    rm, rp, rr, ri     chi(R), magnitude, phase, real, imaginary
    ##    qm, qp, qr, qi     chi(q), magnitude, phase, real, imaginary
		    );
  if ($space =~ /[en]/) {
    $diff_params{xnot} = $groups{$keys[0]}->{bkg_e0};
    $diff_params{xmin} = $config{diff}{emin};
    $diff_params{xmax} = $config{diff}{emax};
  } elsif ($space =~ /[kq]/) {
    $diff_params{xmin} = $config{diff}{kmin};
    $diff_params{xmax} = $config{diff}{kmax};
  } else {
    $diff_params{xmin} = $config{diff}{rmin};
    $diff_params{xmax} = $config{diff}{rmax};
  };


  if ($diff_params{standard} eq $current) { # make sure $current is sensible given
    set_properties(1, $keys[1], 0);            # that $keys[0] is the standard
    # adjust the view
    my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
    ($here < 0) and ($here = 0);
    my $full = ($list->bbox(@skinny_list))[3] + 5;
    $list -> yview('moveto', $here/$full);
  };

  $fat_showing = 'diff';
  $hash_pointer = \%diff_params;
  map {$_ -> configure(-state=>'disabled')}
    ($data_menu, $merge_menu, $anal_menu, $settings_menu);
  $fat -> packForget;
  my $diff = $container->Frame(@fatgeom, -relief=>'sunken', -borderwidth=>3)
    -> pack(-fill=>'both', -expand=>1);
  #$diff -> packPropagate(0);
  $which_showing = $diff;

  $diff -> Label(-text=>$header,
		 -font=>$config{fonts}{large},
		 -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'top', -fill=>'x', -anchor=>'w');

  ## select the difference standard
  my $frame = $diff -> Frame(-borderwidth=>2, -relief=>'flat')
    -> pack(-side=>'top', -fill=>'x');
  $frame -> Label(-text=>"Standard: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
	    -> grid(-row=>0, -column=>0);


  $widget{diff_menu} = $frame -> BrowseEntry(-variable => \$diff_params{standard_label},
					     @browseentry_list,
					     -browsecmd => sub {
					       my $text = $_[1];
					       my $this = $1 if ($text =~ /^(\d+):/);
					       Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless $this;
					       $this -= 1;
					       Error("Difference group aborted: You selected the same data group twice!"),
						 return if ($diff_params{keys}->[$this] eq $current);
					       $diff_params{standard}=$diff_params{keys}->[$this];
					       ##$diff_params{standard_label} = $groups{$diff_params{standard}}->{label};
					       ($diff_params{xnot} = $groups{$diff_params{standard}}->{bkg_e0})
						 if ($diff_params{space} =~ /[en]/);
					       $groups{$diff_params{standard}} ->
						 plot_difference($groups{$current}, \%diff_params, $dmode, \%plot_features);
					       $last_plot=$space;
					     })
    -> grid(-row=>0, -column=>1);
  my $i = 1;
  foreach my $s (@keys) {
    $widget{diff_menu} -> insert("end", "$i: $groups{$s}->{label}");
    ++$i;
  };


  ## select the other group
  $frame -> Label(-text=>"Other: ",
		  -foreground=>$config{colors}{activehighlightcolor},
		 )
    -> grid(-row=>1, -column=>0);
  $widget{diff_unknown} = $frame -> Label(-text=>$groups{$current}->{label},
					  -foreground=>$config{colors}{button})
    -> grid(-row=>1, -column=>1, -sticky=>'w', -pady=>2, -padx=>2);

  $frame -> Checkbutton(-text	     => 'Invert difference spectra',
			-selectcolor => $config{colors}{single},
			-variable    => \$diff_params{invert},
			-command     => sub{$widget{diff_replot}->invoke},
		       )
    -> grid(-row=>2, -column=>0, -columnspan=>2, -sticky=>'w', -pady=>2, -padx=>2);
  $frame -> Checkbutton(-text	     => 'Plot spectra',
			-selectcolor => $config{colors}{single},
			-variable    => \$diff_params{components},
			-command     => sub{$widget{diff_replot}->invoke},
		       )
    -> grid(-row=>3, -column=>0, -columnspan=>2, -sticky=>'w', -pady=>2, -padx=>2);

  $diff -> Frame(-background=>$config{colors}{darkbackground})
    -> pack(-side=>'bottom', -expand=>1, -fill=>'both');
  $diff -> Button(-text=>'Return to the main window',  @button_list,
		  -background=>$config{colors}{background2},
		  -activebackground=>$config{colors}{activebackground2},
		  -command=>sub{
		    $groups{$diff_params{standard}} ->
		      dispose("erase \@group diff___diff\n", $dmode);
		    &reset_window($diff, "difference spectra", 0);
		  })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>5);

  ## help button
  $diff -> Button(-text=>'Document section: difference spectra', @button_list,
		  -command=>sub{pod_display("analysis::diff.pod")})
    -> pack(-side=>'bottom', -fill=>'x', -pady=>4);

  $frame = $diff -> Frame()
    -> pack(-side=>'bottom', -fill=>'x', -ipadx=>5);
  $widget{diff_savemarked} = $frame ->
    Button(-text=>'Make difference groups from all MARKED groups',  @button_list,
	   -command=>sub{
	     $diff_params{noplot} = 1;
	     $groups{$diff_params{standard}} -> plot_difference($groups{$current}, \%diff_params, $dmode, \%plot_features);
	     &diff_marked($space, \%diff_params);
	     $diff_params{noplot} = 0;
	   })
    -> pack(-side=>'left', -fill=>'x', -expand=>1, -pady=>0, -padx=>0);
  $widget{diff_savemarkedi} = $frame ->
    Checkbutton(-text=>'Integrate?',
		-selectcolor=>$config{colors}{single},
		-variable=>\$diff_params{integrate_marked})
    -> pack(-side=>'right', -pady=>0, -padx=>0);


  $widget{diff_save} = $diff ->
    Button(-text=>'Make difference group',  @button_list,
	   -command=>sub{&make_diff_group($space, $diff_params{standard}, $current, \%diff_params); })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>5, -padx=>0);

  $widget{diff_replot} = $diff ->
    Button(-text=>'Replot',  @button_list,
	   -command=>sub{$groups{$diff_params{standard}} ->
			   plot_difference($groups{$current}, \%diff_params, $dmode, \%plot_features);
		       })
    -> pack(-side=>'bottom', -fill=>'x', -pady=>5, -padx=>0);

  ## integration range
  $frame = $diff -> LabFrame(-label=>'Integrate difference spectra',
			     -labelside=>'acrosstop',
			     -foreground=>$config{colors}{activehighlightcolor},
			    )
    -> pack(-side=>'bottom', -fill=>'x', -pady=>5);
  my $fr = $frame -> Frame()
    -> pack(-side=>'top', -pady=>3);
  $fr -> Label(-text=> "Integration range:", -anchor=>'e',
	       -foreground=>$config{colors}{activehighlightcolor},
	      )
    -> pack(-side=>'left', -pady=>3, -fill=>'x');
  $widget{diff_xmin} = $fr -> Entry(-width=>7, -textvariable=>\$diff_params{xmin},
				    #-validate=>'all',
				    #-validatecommand=>[\&set_peak_variable, 'xmin'],
				   )
    -> pack(-side=>'left', -pady=>3);
  $grab{diff_xmin} = $fr -> Button(@pluck_button, @pluck,
				   -command=>sub{&pluck("diff_xmin");
						 my $e = $widget{diff_xmin}->get();
						 ($e = sprintf("%.3f", $e-$groups{$diff_params{standard}}->{bkg_e0}))
						   if ($diff_params{space} =~ /[en]/);
						 $widget{diff_xmin}->delete(0, 'end');
						 $widget{diff_xmin}->insert(0, $e);
						 if ($diff_params{xmin} > $diff_params{xmax}) {
						   ($diff_params{xmin}, $diff_params{xmax}) =
						     ($diff_params{xmax}, $diff_params{xmin});
						 };
						 $groups{$diff_params{standard}} ->
						   plot_difference($groups{$current}, \%diff_params,
								   $dmode, \%plot_features);
					       })
    -> pack(-side=>'left', -pady=>3);
  $fr -> Label(-text=> "to",
	       -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left', -pady=>6);
  $widget{diff_xmax} = $fr -> Entry(-width=>7, -textvariable=>\$diff_params{xmax},
				    #-validate=>'all',
				    #-validatecommand=>[\&set_peak_variable, 'xmax'],
				   )
    -> pack(-side=>'left', -pady=>3);
  $grab{diff_xmax} = $fr -> Button(@pluck_button, @pluck,
				   -command=>sub{&pluck("diff_xmax");
						 my $e = $widget{diff_xmax}->get();
						 ($e = sprintf("%.3f", $e-$groups{$diff_params{standard}}->{bkg_e0}))
						   if ($diff_params{space} =~ /[en]/);
						 $widget{diff_xmax}->delete(0, 'end');
						 $widget{diff_xmax}->insert(0, $e);
						 if ($diff_params{xmin} > $diff_params{xmax}) {
						   ($diff_params{xmin}, $diff_params{xmax}) =
						     ($diff_params{xmax}, $diff_params{xmin});
						 };
						 $groups{$diff_params{standard}} ->
						   plot_difference($groups{$current}, \%diff_params,
								   $dmode, \%plot_features);
					       })
    -> pack(-side=>'left', -pady=>3);
  my $color = $config{colors}{activehighlightcolor};
  $widget{diff_integrate} = $fr ->
    Button(-text=>'Integrate',  @button_list,
	   -command=>sub{
	     Echonow("Integrating ...");
	     $top -> Busy(-recurse=>1);
	     ($diff_params{xmin},$diff_params{xmax}) = ($diff_params{xmax},$diff_params{xmin})
	       if ($diff_params{xmin} > $diff_params{xmax});
	     $diff_params{integral} =
	       sprintf("%.7f",
		       integrate( \&diff_interpolate,
				  $diff_params{xnot} + $diff_params{xmin},
				  $diff_params{xnot} + $diff_params{xmax},
				  6, 1e-8, \%diff_params ));
	     $widget{diff_integral_label} -> configure(-foreground=>$color);
	     $top -> Unbusy;
	     Echonow("Integrating ... done!");
	   })
      -> pack(-side=>'left', -pady=>3, -padx=>6);
  $fr = $frame -> Frame()
    -> pack(-side=>'bottom', -pady=>3);
  $widget{diff_integral_label} = $fr ->
    Label(-text=> "Intgerated area: ",
	  -foreground=>$config{colors}{disabledforeground})
    -> pack(-side=>'left', -pady=>3, -padx=>12);
  $diff_params{diff_integral_label} = $widget{diff_integral_label};
  $widget{diff_integral} = $fr -> Label(-width=>12,
					-textvariable=>\$diff_params{integral})
    -> pack(-side=>'left', -pady=>3);


  $groups{$diff_params{standard}} ->
    plot_difference($groups{$current}, \%diff_params, $dmode, \%plot_features);
  $last_plot=$space;
  $plotsel -> raise(lc(substr($sp{$space}, 0, 1)));
};


## make a new group object and copy the diff___diff arrays to this new
## group name
sub make_diff_group {
  my ($space, $standard, $other, $rhash) = @_;
  Error("Difference group aborted: You selected the same data group twice!"),
    return if ($standard eq $other);
  ##my $invert = ($$rhash{invert}) ? "-1*" : "";
  Echo ("Saving $standard - $other in $space space");
  ## get a group name
  my $group = join(" ", "Diff", $groups{$standard}->{label}, $groups{$other}->{label});
  my $label;
  ($group, $label) = group_name($group);
  $groups{$group} = Ifeffit::Group -> new(group=>$group, label=>$label);
  my $command = q{};
  ## make objects and copy the arrays from diff___diff to the new group
 SWITCH: {
    ($space eq 'e') and do {
      $groups{$group} -> make(is_xmu=>1, is_chi=>0, is_rsp=>0, is_qsp=>0,
			      is_diff=>1, bkg_flatten=>0,
			      bkg_e0  =>$groups{$standard}->{bkg_e0},
			      bkg_pre1=>$groups{$standard}->{bkg_pre1},
			      bkg_pre2=>$groups{$standard}->{bkg_pre2},
			      bkg_nor1=>$groups{$standard}->{bkg_nor1},
			      bkg_nor2=>$groups{$standard}->{bkg_nor2},
			      bkg_spl1=>$groups{$standard}->{bkg_spl1},
			      bkg_spl2=>$groups{$standard}->{bkg_spl2},
			      fft_kmax=>$groups{$standard}->{bkg_spl2},
			     );
      $groups{$group} -> make(bkg_spl1e=>$groups{$group}->k2e($groups{$group}->{bkg_spl1}));
      $groups{$group} -> make(bkg_spl2e=>$groups{$group}->k2e($groups{$group}->{bkg_spl2}));
      $command  = "set($group.energy = $standard.energy,\n";
      $command .= "    $group.xmu = diff___diff.xmu)\n";
      #$command .= "erase \@group diff___diff\n";
      $groups{$group} -> dispose($command, $dmode);
      last SWITCH;
    };
    ($space eq 'n') and do {
      $groups{$group} -> make(is_xmu=>1, is_chi=>0, is_rsp=>0, is_qsp=>0, is_nor=>1,
			      is_diff=>1, bkg_flatten=>0,
			      bkg_e0  =>$groups{$standard}->{bkg_e0},
			      bkg_pre1=>$groups{$standard}->{bkg_pre1},
			      bkg_pre2=>$groups{$standard}->{bkg_pre2},
			      bkg_nor1=>$groups{$standard}->{bkg_nor1},
			      bkg_nor2=>$groups{$standard}->{bkg_nor2},
			      bkg_spl1=>$groups{$standard}->{bkg_spl1},
			      bkg_spl2=>$groups{$standard}->{bkg_spl2},
			      fft_kmax=>$groups{$standard}->{bkg_spl2},
			     );
      $groups{$group} -> make(bkg_spl1e=>$groups{$group}->k2e($groups{$group}->{bkg_spl1}));
      $groups{$group} -> make(bkg_spl2e=>$groups{$group}->k2e($groups{$group}->{bkg_spl2}));
      $command  = "set($group.energy = $standard.energy,\n";
      my $ysuff = $groups{$standard}->{bkg_flatten} ? 'flat' : 'norm';
      ##my $ysuff = "norm";
      $command .= "    $group.xmu = diff___diff.$ysuff)\n";
      #$command .= "erase \@group diff___diff\n";
      $groups{$group} -> dispose($command, $dmode);
      last SWITCH;
    };
    ($space eq 'k') and do {
      $groups{$group} -> dispose("___x = ceil($standard.k)\n", 1);
      my $maxk = Ifeffit::get_scalar("___x");
      $groups{$group} -> make(is_xmu=>0, is_chi=>1, is_rsp=>0, is_qsp=>0,
			      is_diff=>1,
			      update_bkg=>0, fft_kmax=>sprintf("%.2f", $maxk));
      $command  = "set($group.k = $standard.k,\n";
      $command .= "    $group.chi = diff___diff.chi)\n";
      #$command .= "erase \@group diff___diff\n";
      $groups{$group} -> dispose($command, $dmode);
      last SWITCH;
    };
    ($space eq 'r') and do {
      $groups{$group} -> make(is_xmu=>0, is_chi=>0, is_rsp=>1, is_qsp=>0,
			      is_diff=>1);
      $command  = "set($group.r = $standard.r,\n";
      $command .= "    $group.chir_mag = diff___diff.chir_mag,\n";
      $command .= "    $group.chir_pha = diff___diff.chir_pha,\n";
      $command .= "    $group.chir_re  = diff___diff.chir_re,\n";
      $command .= "    $group.chir_im  = diff___diff.chir_im)\n";
      #$command .= "erase \@group diff___diff\n";
      $groups{$group} -> dispose($command, $dmode);
      last SWITCH;
    };
    ($space eq 'q') and do {
      $groups{$group} -> make(is_xmu=>0, is_chi=>0, is_rsp=>0, is_qsp=>1,
			      is_diff=>1);
      $command  = "set($group.q = $standard.q\n";
      $command .= "    $group.chiq_mag = diff___diff.chiq_mag,\n";
      $command .= "    $group.chiq_pha = diff___diff.chiq_pha,\n";
      $command .= "    $group.chiq_re  = diff___diff.chiq_re,\n";
      $command .= "    $group.chiq_im  = diff___diff.chiq_im)\n";
      #$command .= "erase \@group diff___diff\n";
      $groups{$group} -> dispose($command, $dmode);
      last SWITCH;
    };
  };
  $groups{$group} -> make(bkg_z    => $groups{$standard}->{bkg_z},
			  fft_edge => $groups{$standard}->{fft_edge});
  ## titles and the "file"
  push @{$groups{$group}->{titles}}, "Difference between $groups{$standard}->{label} and $groups{$other}->{label} in $space space";
  if ($$rhash{integral}) {
    push @{$groups{$group}->{titles}},
      sprintf("Integrated area from %s to %s : %s",
	      $$rhash{xmin}, $$rhash{xmax}, $$rhash{integral});
  };
  $groups{$group} -> put_titles();
  $groups{$group} -> make(file => "Difference between $groups{$standard}->{label} and $groups{$other}->{label} in $space space");
  ## and display it
  ++$line_count;
  $groups{$group} -> make(line=>$line_count);
  fill_skinny($list, $group, 1);
  Echo(@done);
  my $memory_ok = $groups{$group} -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
  Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
};



sub diff_interpolate {
  my $e = shift;
  my $rhash = shift;
  my $stan  = $$rhash{standard};
  my $xsuff = $$rhash{xsuff};
  my $ysuff = $$rhash{ysuff};
  $groups{$current} -> dispose("set ___x = splint($stan.$xsuff, diff___diff.$ysuff, $e)", 1);
  return Ifeffit::get_scalar('___x');
};


# adapted from Mastering Algorithms with Perl by Orwant, Hietaniemi,
# and Macdonald Chapter 16, p 632 to pass the diff_params hash to the
# function
#
# integrate() uses the Romberg algorithm to estimate the definite integral
# of the function $func (provided as a code reference) from $lo to $hi.
#
# The subroutine will compute roughly ($steps + 1) * ($steps + 2) / 2
# estimates for the integral, of which the last will be the most accurate.
#
# integrate() returns early if intermediate estimates change by less
# than $epsilon.
#
sub integrate {
    my ($func, $lo, $hi, $steps, $epsilon, $rhash) = @_;
    my ($h) = $hi - $lo;
    my ($i, $j, @r, $sum);
    my @est;

    # Our initial estimate.
    $est[0][0] = ($h / 2) * ( &{$func}( $lo, $rhash ) + &{$func}( $hi, $rhash ) );

    # Compute each row of the Romberg array.
    for ($i = 1; $i <= $steps; $i++) {

        $h /= 2;
        $sum = 0;

        # Compute the first column of the current row.
        for ($j = 1; $j < 2 ** $i; $j += 2) {
            $sum += &{$func}( $lo + $j * $h, $rhash );
        }
        $est[$i][0] = $est[$i-1][0] / 2 + $sum * $h;

        # Compute the rest of the columns in this row.
        for ($j = 1; $j <= $i; $j++) {
            $est[$i][$j] = ($est[$i][$j-1] - $est[$i-1][$j-1])
                / (4**$j - 1) + $est[$i][$j-1];
        }

        # Are we close enough?
        return $est[$i][$i] if $epsilon and
            abs($est[$i][$i] - $est[$i-1][$i-1]) <= $epsilon;
    }
    return $est[$steps][$steps];
}


sub diff_marked {

  my ($space, $rhash) = @_;
  my $stan = $$rhash{standard};
  my @areas;
  my @titles;
  my $j = 0;
  $top -> Busy(-recurse=>1);
  foreach my $g (&sorted_group_list) {
    next unless $marked{$g};
    next if ($g eq $stan);
				## verify this group
    my $ok = 1;
  SWITCH: {
      ($$rhash{space} =~ /[en]/) and do {
	($ok = 0) unless $groups{$g}->{is_xmu};
	last SWITCH;
      };
      ($$rhash{space} eq 'k') and do {
	($ok = 0) unless ($groups{$g}->{is_xmu} or $groups{$g}->{is_chi});
	last SWITCH;
      };
      ($$rhash{space} eq 'r') and do {
	($ok = 0) if $groups{$g}->{is_qsp};
	last SWITCH;
      };
    };
    next unless $ok;

    ++$j;
    set_properties(0, $g, 0);

				## integrate
    if ($$rhash{integrate_marked}) {
      ($$rhash{xmin},$$rhash{xmax}) = ($$rhash{xmax},$$rhash{xmin})
	  if ($$rhash{xmin} > $$rhash{xmax});
      $$rhash{integral} =
	sprintf("%.7f",
		integrate( \&diff_interpolate,
			   $$rhash{xnot} + $$rhash{xmin},
			   $$rhash{xnot} + $$rhash{xmax},
			   6, 1e-8, $rhash ));
      my $color = $config{colors}{activehighlightcolor};
      $widget{diff_integral_label} -> configure(-foreground=>$color);
      push @areas, $$rhash{integral};
      push @titles, "point number $j: " . $groups{$g}->{label};
    };

				## make difference group
    &make_diff_group($space, $$rhash{standard}, $current, $rhash);
  };
  unless ($j) {
    $top -> Unbusy;
    Echo("No valid marked groups!");
    return;
  };

  if ($$rhash{integrate_marked}) {
    ##print join(" ", @areas), $/;
    my @x = ();
    my $i = 0;
    foreach (@areas) { push @x, ++$i };
    my ($group, $label) = group_name("d___iff");
    Ifeffit::put_array("$group.energy", \@x);
    Ifeffit::put_array("$group.det", \@areas);
    $groups{$group} = Ifeffit::Group -> new(group=>$group,
					    label=>"Integrated areas");
    $groups{$group} -> make(is_xmu => 0, is_chi => 0, is_rsp => 0, is_qsp => 0,
			    not_data => 1, bkg_e0 => 1, bkg_eshift => 0);
    push @{$groups{$group}->{titles}}, "Integrated areas from $$rhash{xmin} to $$rhash{xmax}";
    foreach my $t (@titles) { push @{$groups{$group}->{titles}}, $t };
    $groups{$group} -> put_titles();
    $groups{$group} -> make(file => "Integrated areas");
    my @save = ($plot_features{emin}, $plot_features{emax});
    ($plot_features{emin}, $plot_features{emax}) = (0, $i);
    $groups{$group} -> plotE('em',$dmode,\%plot_features, \@indicator);
    ($plot_features{emin}, $plot_features{emax}) = @save;
    ## and display it
    ++$line_count;
    $groups{$group} -> make(line=>$line_count);
    fill_skinny($list, $group, 1);
  };
  $top -> Unbusy;
};

## END OF DIFFERENCE SPECTRA SUBSECTION
##########################################################################################
