## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  Athena's interactions with the Ifeffit/PGPLOT plotting system.

sub plot_merge {
  my ($group, $space) = @_;
  my $color = $plot_features{c1};
  my $label = $groups{$group}->{label};
  my $propsp = "color=$color, key=\"$label+std.dev.\", style=lines";
  my $propsm = "color=$color, key=\"$label-std.dev.\", style=lines";
  my $kstr = ($plot_features{k_w} eq 'w') ? 'kw' : 'k'.$plot_features{k_w};
  my $kexp = ($plot_features{k_w} eq 'w') ? $groups{$group}->{fft_arbkw} : $plot_features{k_w};
  my $yoffset = $groups{$group}->{plot_yoffset};
 PLOT: {
    ($space eq 'k') and do {
      if ($config{merge}{plot} eq 'stddev') {
	$groups{$group} -> plotk($kstr,$dmode,\%plot_features, \@indicator);
	my $string = "plot($group.k, \"($group.chi+$group.stddev)*$group.k**$kexp+$yoffset\", $propsp)";
	$groups{$group} -> dispose($string, $dmode);
	$string = "plot($group.k, \"($group.chi-$group.stddev)*$group.k**$kexp+$yoffset\", $propsm)";
	$groups{$group} -> dispose($string, $dmode);
      } else {
	&plot_marked_k;
      };
      $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      last PLOT;
    };
    ($space =~ /[end]/) and do {
      if ($config{merge}{plot} eq 'stddev') {
	my $str = ($space eq 'e') ? 'em' : 'emn';
	$groups{$group} -> plotE($str,$dmode,\%plot_features, \@indicator);
	my $esh = $groups{$group}->{bkg_eshift};
	my $suff = ($space eq 'e') ? 'xmu' : 'norm';
	($suff = "det") if ($space eq 'd');
	($groups{$group}->{is_nor}) and ($suff = 'xmu');
	my $string = "plot($group.energy+$esh, \"$group.$suff+$group.stddev+$yoffset\", $propsp)";
	$groups{$group} -> dispose($string, $dmode);
	$string = "plot($group.energy+$esh, \"$group.$suff-$group.stddev+$yoffset\", $propsm)";
	$groups{$group} -> dispose($string, $dmode);
      } else {
	&plot_marked_e;
      };
      $plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      last PLOT;
    };
    ($space =~ /[rq]/) and do {
      if ($config{merge}{plot} eq 'stddev') {
	Echo("Plotting merge+std.dev. in R and q spaces does not work yet.");
      } elsif ($space eq 'r') {
	&plot_marked_r;
	$plotsel->raise('r') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      } elsif ($space eq 'q') {
	&plot_marked_q;
	$plotsel->raise('q') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      };
      last PLOT;
    };
  };

};


sub plot_i0 {
  my $plot_mu = $_[0];
  $top -> Busy;
  my $with  = ($plot_mu) ? " $groups{$current}->{label} and" : "";
  my $how   = ($plot_mu) ? " (scaled to the size of mu)" : " for $groups{$current}->{label}";
  Echonow("Plotting$with I0$how ...");
  my $plot  = ($plot_mu) ? "plot" : "newplot";
  my $title = ($plot_mu) ? "" : ",xlabel=\"energy (eV)\", ylabel=I0, title=\"I0 of $groups{$current}->{label}\"";
  my ($scale, $color) = ("", $config{plot}{c0});
  my $i0 = $groups{$current}->{i0};
  my $eshift = $groups{$current}->{bkg_eshift};
  if ($plot_mu) {
    $groups{$current}->dispose("## plotting data and I0, scaled to the size of mu(E)\n", $dmode);
    $groups{$current}->plotE('em', $dmode, \%plot_features, \@indicator);
    $color = $config{plot}{c1};
    $groups{$current}->dispose("set ___x = ceil($current.xmu) / ceil($i0)\n", $dmode);
    $scale = sprintf("%.6g*", abs(Ifeffit::get_scalar("___x")));
  };
  my $cmd = "$plot(\"$current.energy+$eshift\", $scale$i0, key=I0, color=$color,\n";
  $cmd   .= " " x length($plot) . " style=lines$title,\n";
  my ($emin, $emax) = ($plot_features{emin}+$groups{$current}->{bkg_e0}, $plot_features{emax}+$groups{$current}->{bkg_e0});
  $cmd   .= " " x length($plot) . " xmin=$emin, xmax=$emax)\n";
  $groups{$current}->dispose($cmd, $dmode);

  if ($indicator[0]) {
    my $eshift = $groups{$current}->{bkg_eshift};
    $groups{$current}->dispose("set(i___ndic.y = $scale$i0, i___ndic.x = $current.energy+$eshift)");
    my @x = Ifeffit::get_array("i___ndic.x");
    my @y = Ifeffit::get_array("i___ndic.y");
    my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$current}->{bkg_e0});
    #print join("|", $not_data, $ymin, $ymax), $/;
    #(($ymin, $ymax) = ($plot_scale*$ymin, $plot_scale*$ymax)) if ($not_data);
    my $diff = $ymax-$ymin;
    $ymin -= $diff/20;
    $ymax += $diff/20;
    foreach my $i (@indicator) {
      last if ($i =~ /^0$/);
      next if ($i =~ /^1$/);
      next if (lc($i->[1]) =~ /[r\s]/);
      my $val = $i->[2];
      ($val = $groups{$current}->k2e($val)+$groups{$current}->{bkg_e0}) if (lc($i->[1]) =~ /[kq]/);
      next if ($val < 0);
      $groups{$current}->plot_vertical_line($val, $ymin, $ymax, $dmode, "", 0, 0, 1)
    };
  };


  $last_plot='e';
  $top -> Unbusy;
  Echonow("Plotting$with I0$how ... done!");
};

sub plot_i0_marked {
  my $plot = "newplot";
  my $i = 0;
  my $title = ",xlabel=\"energy (eV)\", ylabel=I0, title=\"I0 of marked groups\"";
  my ($yn, $yx) = (1e10, -1e10);
  foreach my $k (&sorted_group_list) {
    next unless $marked{$k};
    next unless $groups{$k}->{i0};
    my $eshift = $groups{$k}->{bkg_eshift};
    my $key = $groups{$k}->{label};
    my $color = $config{plot}{"c".$i};
    my ($emin, $emax) = ($plot_features{emin}+$groups{$k}->{bkg_e0}, $plot_features{emax}+$groups{$k}->{bkg_e0});
    my $limits = ($plot eq "newplot") ? ",\n        xmin=$emin, xmax=$emax" : "";
    $groups{$current}->dispose("$plot(\"$k.energy+$eshift\", $groups{$k}->{i0}, key=$key, color=$color, style=lines$title$limits)\n", $dmode);
    $plot = "plot";
    $title = "";
    ++$i;
    ($i = 0) if ($i > 9); # wrap colors

    $groups{$k}->dispose("set(i___ndic.y = $groups{$k}->{i0}, set i___ndic.x = $current.energy+$eshift)");
    my @x = Ifeffit::get_array("i___ndic.x");
    my @y = Ifeffit::get_array("i___ndic.y");
    my ($ymin, $ymax) = Ifeffit::Group->floor_ceil(\@x, \@y, \%plot_features, 'e', $groups{$k}->{bkg_e0});
    ($yn = $ymin) if ($ymin<$yn);
    ($yx = $ymax) if ($ymax>$yx);
  };
  my $diff = $yx-$yn;
  $yn -= $diff/20;
  $yx += $diff/20;
  foreach my $i (@indicator) {
    last if ($i =~ /^0$/);
    next if ($i =~ /^1$/);
    next if (lc($i->[1]) =~ /[r\s]/);
    my $val = $i->[2];
    ($val = $groups{$current}->k2e($val)+$groups{$current}->{bkg_e0}) if (lc($i->[1]) =~ /[kq]/);
    next if ($val < 0);
    $groups{$current}->plot_vertical_line($val, $yn, $yx, $dmode, "", 0, 0, 1)
  };
  $last_plot='e';
};

sub redo_plot {
  Echo ("You have not yet plotted anything"), return unless $last_plot_params;
  my ($curr, $type, $sp, $str) = @$last_plot_params;
 SWITCH: {			# dispatch plot request to the correct method
    $groups{$curr}->plot_marked($str,$dmode,\%groups,\%marked,\%plot_features, $list, \@indicator), last SWITCH
      if ($type eq 'marked');
    $groups{$curr}->plotE($str,$dmode,\%plot_features, \@indicator), last SWITCH if ($sp eq 'e');
    $groups{$curr}->plotk($str,$dmode,\%plot_features, \@indicator), last SWITCH if ($sp eq 'k');
    $groups{$curr}->plotR($str,$dmode,\%plot_features, \@indicator), last SWITCH if ($sp eq 'r');
    $groups{$curr}->plotq($str,$dmode,\%plot_features, \@indicator), last SWITCH if ($sp eq 'q');
  };
};

sub replot {
  Echo('No data'), return unless $current;
  my $mode = $_[0];		# 0=replot, 1=write gif, 2=write ps,
                                # 3=send to printer
  Echo("You have not yet plotted anything."), return 0 unless ($Ifeffit::Group::last_plot);
  my ($title, $suf, $dev);
 SWITCH: {
      ($mode eq 'replot') and do {
	$setup->dispose($Ifeffit::Group::last_plot, 1);
	Echo("Unzoomed.");
	return;
      };
      ($mode =~ /(gif|png|ppm)/) and do {
	($title, $suf, $dev) = ('Athena: '.uc($1).' file name', $1, $mode );
	last SWITCH;
      };
      ($mode =~ /ps/) and do {
	($title, $suf, $dev) = ('Athena: Postscript file name', 'ps', $mode);
	last SWITCH;
      };
      ($mode =~ /latex/) and do {
	($title, $suf, $dev) = ('Athena: LaTeX picture mode file name', 'tex', $mode);
	last SWITCH;
      };
      ($mode eq 'print') and do {
	($title, $suf, $dev) = ('', 'ps', $config{general}{ps_device});
	last SWITCH;
      };
      ($title, $suf, $dev) = ('Athena: Image file name', 'img', $mode);
    };
  my $path = $current_data_dir || Cwd::cwd;
  if ($mode eq 'print') {
    if ($is_windows) {
      Echo("Printing under Windows is not yet supported");
    } else {
      ## this is alarmingly crufty!
      my $tmp = '...athena.tmp';
      $setup->dispose("plot(device=\"$dev\", file=\"$tmp\")\n", 7);
      local $| = 1;
      Echo("Sending image to printer with " .
	   $config{general}{print_spooler});
      open OUT, "| ".$config{general}{print_spooler} or
	die "could not open pipe to ".$config{general}{print_spooler}."\n";
      open IN, $tmp or die "could not open temp file for printing";
      while (<IN>) { print OUT; };
      close IN; close OUT; unlink $tmp;
      Echo("Image spooled.");
    };
    return;
  } else {
    ##local $Tk::FBox::a;
    ##local $Tk::FBox::b;
    my $types = [["$suf image files", $suf],
		 ['All Files', '*'],];
    my $file = $top -> getSaveFile(-defaultextension=>$suf,
				   -filetypes=>$types,
				   ##(not $is_windows) ?
				   ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				   -initialfile=>"athena.$suf",
				   -title => $title);
    if ($file) {
      ## make sure I can write to $file
      open F, ">".$file or do {
	Error("You cannot write to \"$file\"."); return
      };
      close F;
      my ($name, $path, $suffix) = fileparse($file);
      $current_data_dir = $path;
      Echo("saving image to $file");
      $setup->dispose("plot(device=\"$dev\", file=\"$file\")\n", 7);
      #$setup->dispose("plot(device=\"/xserve\", file=\"\")\n", 7);
    };
  };
};


sub autoreplot {
  ## this could be a direct call or it could be a callback from some widget
  my $arg = (ref($_[0]) =~ /Tk/) ? $_[1] : $_[0];
  #print join(" ", @_), $/, "arg=$arg\n";
  ## replot a specific space
  plot_current_e(), return if (lc($arg) eq 'e');
  plot_current_k(), return if (lc($arg) eq 'k');
  plot_current_r(), return if (lc($arg) eq 'r');
  plot_current_q(), return if (lc($arg) eq 'q');
  ## replot the most recent space
  plot_current_e(), return if ($last_plot eq 'e');
  plot_current_k(), return if ($last_plot eq 'k');
  plot_current_r(), return if ($last_plot eq 'r');
  plot_current_q(), return if ($last_plot eq 'q');
};



sub pluck {
  my $widg = $_[0];
  my $parent = $_[1] || $top;
  my $this = $current || "Default Parameters";
  Echo("You have not made a plot yet."), return 0 unless ($last_plot);
  if ($widg =~ /^lr/) {
    1;
  } elsif ($widg =~ /^pp/) {
    1;
  } elsif (($last_plot =~ /[ek]/) and (($widg =~ /^bft/) or ($widg eq 'bkg_rbkg'))) {
    Echonow("You cannot pluck an R value from the last plot.");
    return 0;
  ## } elsif (($last_plot eq 'ke') and ($widg !~ /bkg/)) {
  ##   Echonow("Your last plot was an energy plot.");
  ##   return 0;
  } elsif (($last_plot eq 'k') and ($widg =~ /pre/)) {
    Echonow("You cannot pluck an pre-edge parameter value from a k plot.");
    return 0;
  } elsif (($last_plot eq 'r') and (($widg !~ /^bft/) and ($widg ne 'bkg_rbkg'))) {
    Echonow("Your last plot was an R plot.");
    return 0;
  };
  Echonow("Select a value for $widg from the plot...");
  my ($cursor_x, $cursor_y) = (0,0);
  my $to_grab = $grab{$widg} || $parent;
  $to_grab -> grab();
  $groups{$this}->dispose("cursor(crosshair=true)\n", 1);
  ($cursor_x, $cursor_y) = (Ifeffit::get_scalar("cursor_x"),
			    Ifeffit::get_scalar("cursor_y"));
  $to_grab -> grabRelease();
  my $value;
  if ($widg =~ /^(bkg_(e0|nor[12]|pre[12]|spl(1e|2e)))$/) { # need an E value
    if (($last_plot eq 'e') or ($last_plot eq 'ke')) {
      $value = $cursor_x;
    } else {
      $value = $groups{$this}->k2e($cursor_x);
    };
    ($widg !~ /e0/) and $value -= $groups{$this}->{bkg_e0};
  } elsif ($widg =~ /^(deg|diff|etrun|lcf|peak)/) {
    $value = $cursor_x;
  } elsif ($widg =~ /^(bkg_spl[12]|fft_km(ax|in))$/) {      # need a k value
    if (($last_plot eq 'e') or ($last_plot eq 'ke')) {
      $value = $groups{$this}->e2k($cursor_x);
      ($widg =~ /(nor|pre)/) and $value -= $groups{$this}->{bkg_e0};
    } else {
      $value = $cursor_x;
    };
  } elsif ($widg =~ /^(b(ft_rm(ax|in)|kg_rbkg))$/) {        # need an R value
    $value = $cursor_x;
  } elsif ($widg =~ /^lr/) {        # need an R value
    $value = $cursor_x;
  } elsif ($widg =~ /^pp_(.+)/) {
    $value = sprintf("%.3f", $cursor_x);
    $preprocess{$1} = $value;
    Echonow("Plucked the value of $value for $widg.");
    return 1;
  } else {
    return -1;
  };
  $value = sprintf("%.3f", $value);
  set_variable($widg, $value, 1);
  my $v = $groups{$this}->{$widg};
  $widget{$widg} -> configure(-validate=>'none');
  $widget{$widg} -> delete(qw/0 end/);
  $widget{$widg} -> insert(0, $v);
  $widget{$widg} -> configure(-validate=>'key');
  ##$parent->raise;
  my $how = $_[2] || "e";
  ($how = 'r') if ($widg =~ /^fft/);
  ($how = 'q') if ($widg =~ /^bft/);
  $widget{peak_plot}->invoke if ($widg =~ /^peak/);
  autoreplot($how) unless
      (
       (($widg =~ /^fft/) and not ($config{fft}{pluck_replot}))
       or
       ($widg =~ /^(peak)/)
       or
       ($widg =~ /^(lcf)/)
      );
  Echonow("Plucked the value of $v for $widg.");
  #($widg =~ /^deg/) and $groups{$current} -> plotE('emg',$dmode,\%plot_features, \@indicator);
  return 1;
};


sub zoom {
  if ($fat_showing ne 'teach_ft') {
    Echo('No data'), return unless $current;
    Echo("You have not yet plotted anything."), return unless $last_plot;
  };
  Echonow('Click corners to zoom');
  my $mode = $dmode;
  ($mode & 8) and ($mode -= 8);
  $setup->dispose('zoom(show)', $mode);
  Echo('Zooming done!');
};

sub cursor {
  Echo('No data'), return unless $current;
  Echo("You have not yet plotted anything."), return unless $last_plot;
  my $old = $echo_pause;
  $echo_pause = 0;
  Echonow('Click on a point');
  $echo_pause = $old;
  my $mode = $dmode;
  ($mode & 8) and ($mode -= 8);
  $setup->dispose('cursor(show, crosshair=true)', $mode);
  Echonow(sprintf("You selected  x=%f   y=%f",
		  Ifeffit::get_scalar("cursor_x"),
		  Ifeffit::get_scalar("cursor_y")));
};


## return 1 if all relevant ranges are correct, return 0 and do an
## Echo if there is a problem
sub verify_ranges {
  my ($this, $space, $multi) = @_;
  if ($groups{$this}->{is_xmu} and (not $groups{$this}->{is_nor}) and
      ($groups{$this}->{bkg_pre1} > $groups{$this}->{bkg_pre2})) {
    Echo("ERROR: The minimum value of the pre-edge range exceeds the maximum value.");
    set_properties (1, $this, 0) if ($multi);
    return 0;
  };
  if ($groups{$this}->{is_xmu} and (not $groups{$this}->{is_nor}) and
      ($groups{$this}->{bkg_nor1} > $groups{$this}->{bkg_nor2})) {
    Echo("ERROR: The minimum value of the normalization range exceeds the maximum value.");
    set_properties (1, $this, 0) if ($multi);
    return 0;
  };
  if ($groups{$this}->{is_xmu} and ($groups{$this}->{bkg_spl1} > $groups{$this}->{bkg_spl2})) {
    Echo("ERROR: The minimum value of the spline range exceeds the maximum value.");
    set_properties (1, $this, 0) if ($multi);
    return 0;
  };
  return 1 if $groups{$this}->{is_xanes};
  return 1 if $groups{$this}->{not_data};
  if (($space =~ /[rq]/) and (not $groups{$this}->{is_qsp})) {
    if ($groups{$this}->{fft_kmin} > $groups{$this}->{fft_kmax}) {
      Echo("ERROR: The minimum value of the forward Fourier transform range exceeds the maximum value.");
      set_properties (1, $this, 0) if ($multi);
      return 0;
    };
  };
  return 1 if $groups{$this}->{is_qsp};
  if ($space =~ /q/) {
    if ($groups{$this}->{bft_rmin} > $groups{$this}->{bft_rmax}) {
      Echo("ERROR: The minimum value of the backward Fourier transform range exceeds the maximum value.");
      set_properties (1, $this, 0) if ($multi);
      return 0;
    };
  };
  return 1;
};

sub plot_current_e {
  my $str = "e";
  Echo('No data!'), return unless ($current);
  return unless &verify_ranges($current, 'e');
  $top -> Busy(-recurse=>1,);
  update_hook();
  map {$str .= $plot_features{$_}} (qw/e_mu e_mu0 e_pre e_post e_norm e_der/);
  ($str eq "e")  and ($str = "emz");
  ($str eq "en") and ($str = "emzn");
  ($str eq "ed") and ($str = "emdsss");
  ($str =~ "d")  and ($str .= "s" x $plot_features{smoothderiv});
  &set_key_params;
  $groups{$current}->plotE($str,$dmode,\%plot_features, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'e');
  $last_plot='e';
  $last_plot_params = [$current, 'group', 'e', $str];
  $plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was in Energy");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'normal');
  };
  Error("The edge step is negative!  You probably need to adjust the normalization parameters.")
    if ($groups{$current}->{bkg_step} < 0);
  $top->Unbusy;
};


sub plot_current_k {
  my $str = "k";
  Echo('No data!'), return unless ($current);
  return unless &verify_ranges($current, 'k');
  $top -> Busy(-recurse=>1,);
  update_hook();
  map {$str .= $plot_features{$_}} (qw/k_w k_win/);
  &set_key_params;
  $groups{$current}->plotk($str,$dmode,\%plot_features, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'k');
  $last_plot='k';
  $last_plot_params = [$current, 'group', 'k', $str];
  $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was in k");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'normal');
  };
  Error("The edge step is negative!  You probably need to adjust the normalization parameters.")
    if ($groups{$current}->{bkg_step} < 0);
  $top->Unbusy;
};

sub plot_current_r {
  my $str = "r";
  Echo('No data!'), return unless ($current);
  return unless &verify_ranges($current, 'r');
  $top -> Busy(-recurse=>1,);
  update_hook();
  map {$str .= $plot_features{$_}} (qw/r_mag r_env r_re r_im r_pha r_win/);
  ($str eq "r") and ($str = "rm");
  &set_key_params;
  $groups{$current}->plotR($str,$dmode,\%plot_features, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'r');
  $last_plot='r';
  $last_plot_params = [$current, 'group', 'r', $str];
  $plotsel->raise('r') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was in R");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'normal');
  };
  Error("The edge step is negative!  You probably need to adjust the normalization parameters.")
    if ($groups{$current}->{bkg_step} < 0);
  $top->Unbusy;
};

sub plot_current_q {  # }
  my $str = "q";
  Echo('No data!'), return unless ($current);
  return unless &verify_ranges($current, 'q');
  $top -> Busy(-recurse=>1,);
  update_hook();
  map {$str .= $plot_features{$_}} (qw/q_mag q_env q_re q_im q_pha q_win/);
  ($str eq "q") and ($str = "qi");
  &set_key_params;
  $groups{$current}->plotq($str,$dmode,\%plot_features, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'q');
  $last_plot='q';
  $last_plot_params = [$current, 'group', 'q', $str];
  $plotsel->raise('q') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was in q");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'normal');
  };
  Error("The edge step is negative!  You probably need to adjust the normalization parameters.")
    if ($groups{$current}->{bkg_step} < 0);
  $top->Unbusy;
};


sub keyboard_plot {
  my $who = $top->focusCurrent;
  $multikey = "";
  Echo("Plot Current group: specify plot space (e k r q)");
  $echo -> focus();
  $echo -> grab;
  $echo -> waitVariable(\$multikey);
  $echo -> grabRelease;
  $who -> focus;
  Echo("$multikey is not a plot space!"), return unless (lc($multikey) =~ /^[ekqr]$/);
 SWITCH: {
    &plot_current_e, last SWITCH if (lc($multikey) eq 'e');
    &plot_current_k, last SWITCH if (lc($multikey) eq 'k');
    &plot_current_r, last SWITCH if (lc($multikey) eq 'r');
    &plot_current_q, last SWITCH if (lc($multikey) eq 'q');   # ,
  };
};


sub plot_marked_e {
  my $str = $plot_features{e_marked};
  Echo('No data!'), return unless ($current);
  $top -> Busy(-recurse=>1,);
  update_hook();
  &set_key_params;
  $groups{$current}->plot_marked($str, $dmode, \%groups, \%marked, \%plot_features, $list, \@indicator);
  &refresh_properties;
  $last_plot='e';
  $last_plot_params = [$current, 'marked', 'e', $str];
  $plotsel->raise('e') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was a marked plot");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'disabled');
  };
  my $bad_step = 0;
  foreach my $k (keys %marked) {
    next unless $marked{$k};
    ++$bad_step if ($groups{$k}->{bkg_step} < 0);
  };
  Error("The edge step of one or more groups is negative!  You probably need to adjust the normalization parameters.")
    if $bad_step;
  $top->Unbusy;
};

sub plot_marked_k {
  #my $str = $plot_features{k_w};
  my $str = $plot_features{kw};
  Echo('No data!'), return unless ($current);
  $top -> Busy(-recurse=>1,);
  update_hook();
  &set_key_params;
  $groups{$current}->plot_marked($str, $dmode, \%groups, \%marked, \%plot_features, $list, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'k');
  $last_plot='k';
  $last_plot_params = [$current, 'marked', 'k', $str];
  $plotsel->raise('k') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was a marked plot");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'disabled');
  };
  my $bad_step = 0;
  foreach my $k (keys %marked) {
    next unless $marked{$k};
    ++$bad_step if ($groups{$k}->{bkg_step} < 0);
  };
  Error("The edge step of one or more groups is negative!  You probably need to adjust the normalization parameters.")
    if $bad_step;
  $top->Unbusy;
};

sub plot_marked_r {
  #tie my $timer, 'Time::Stopwatch';
  my $str = $plot_features{r_marked};
  Echo('No data!'), return unless ($current);
  $top -> Busy(-recurse=>1,);
  update_hook();
  &set_key_params;
  $groups{$current}->plot_marked($str, $dmode, \%groups, \%marked, \%plot_features, $list, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'r');
  $last_plot='r';
  $last_plot_params = [$current, 'marked', 'r', $str];
  $plotsel->raise('r') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was a marked plot");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'disabled');
  };
  my $bad_step = 0;
  foreach my $k (keys %marked) {
    next unless $marked{$k};
    ++$bad_step if ($groups{$k}->{bkg_step} < 0);
  };
  Error("The edge step of one or more groups is negative!  You probably need to adjust the normalization parameters.")
    if $bad_step;
  $top->Unbusy;
  #my $elapsed = $timer;
  #undef $timer;
  #$elapsed = sprintf("Deletion took %.0f min, %.0f sec", $elapsed/60, $elapsed%60);
  #Echo($elapsed);
};

sub plot_marked_q {
  my $str = $plot_features{q_marked}; # }
  Echo('No data!'), return unless ($current);
  $top -> Busy(-recurse=>1,);
  update_hook();
  &set_key_params;
  $groups{$current}->plot_marked($str, $dmode, \%groups, \%marked, \%plot_features, $list, \@indicator);
  &refresh_properties;
  ($pointfinder{xvalue}, $pointfinder{yvalue}) = ("", "") unless ($last_plot eq 'q');
  $last_plot='q';
  $last_plot_params = [$current, 'marked', 'q', $str];
  $plotsel->raise('q') unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
  section_indicators();
  $pointfinder{space} -> configure(-text=>"The last plot was a marked plot");
  foreach (qw(x xpluck xfind y ypluck clear)) {
    $pointfinder{$_} -> configure(-state=>'disabled');
  };
  my $bad_step = 0;
  foreach my $k (keys %marked) {
    next unless $marked{$k};
    ++$bad_step if ($groups{$k}->{bkg_step} < 0);
  };
  Error("The edge step of one or more groups is negative!  You probably need to adjust the normalization parameters.")
    if $bad_step;
  $top->Unbusy;
};


sub keyboard_plot_marked {
  my $who = $top->focusCurrent;
  $multikey = "";
  Echo("Plot marked groups: specify plot space (e k r q)");
  $echo -> focus();
  $echo -> grab;
  $echo -> waitVariable(\$multikey);
  $echo -> grabRelease;
  $who -> focus;
  Echo("$multikey is not a plot space!"), return unless (lc($multikey) =~ /^[ekqr]$/);
 SWITCH: {
    &plot_marked_e, last SWITCH if (lc($multikey) eq 'e');
    &plot_marked_k, last SWITCH if (lc($multikey) eq 'k');
    &plot_marked_r, last SWITCH if (lc($multikey) eq 'r');
    &plot_marked_q, last SWITCH if (lc($multikey) eq 'q'); 	# ,
  };
};


sub set_key_params {
  Ifeffit::put_scalar('&plot_key_x',  $config{plot}{'key_x'});
  Ifeffit::put_scalar('&plot_key_y0', $config{plot}{'key_y'});
  Ifeffit::put_scalar('&plot_key_dy', $config{plot}{'key_dy'});
};


sub hide_show_plot_options {
  if ($plot_features{options_showing}) {
    $plotsel->packForget;
    $plot_features{options_showing} = 0;
    $po_left  -> configure(-text=>'^');
    $po_right -> configure(-text=>'^');
  } else {
    $plotsel->pack(-fill => 'x', -side => 'bottom', -anchor=>'s');
    $plot_features{options_showing} = 1;
    $po_left  -> configure(-text=>'v');
    $po_right -> configure(-text=>'v');
  };
};

sub detach_plot {
  #eval {Tk::Wm->release};
  $plot_menu->menu->entryconfigure(12, -state=>'disabled');
  #$top->update;
  #$detached_plot->deiconify;
  #$detached_plot->raise;
  #$b_frame -> pack(-in=>$detached_plot);
  $b_frame->packForget;
  $b_frame->wmRelease;
  $b_frame->raise;
  $b_frame->MainWindow::protocol('WM_DELETE_WINDOW', \&reattach_plot);
  $b_frame->MainWindow::title('Athena: plot buttons');
  $b_frame->MainWindow::iconimage($iconimage);
  $replace = $b_frame ->
    Button(-text=>'Replace',
	   -font=>$config{fonts}{smbold}, @button_list,
	   -command => \&reattach_plot)
      -> pack(-expand=>1, -fill=>'x', -padx=>4, -pady=>4);
  $b_frame->MainWindow::deiconify;
};

sub reattach_plot {
  Echonow("Replacing the plot buttons may take a few seconds...");
  $replace -> packForget;
  $b_frame -> wmCapture;
  $b_frame -> pack(-after=>$po, -anchor=>'n', -fill=>'x');
  $plot_menu->menu->entryconfigure(12, -state=>'normal');
  $top -> update;
  Echonow("Replaced plot buttons!");
};

## END OF PLOTTING SUBSECTION
##########################################################################################
