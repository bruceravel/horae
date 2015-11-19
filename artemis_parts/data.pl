# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##

###===================================================================
### dealing with data
###===================================================================


## return the name of the data at the top of the paths list
sub first_data {
  foreach my $d (sort &all_data) {
    return $d if ($paths{$d}->get('include'));
  };
  return 'data0';
};

sub next_data {
  my $next = -1;
  foreach my $d (keys %paths) {
    next unless (ref($paths{$d}) =~ /Ifeffit/);
    next unless ($paths{$d}->type eq 'data');
    my $this = $1 if ($d =~ /^data(\d+)$/);
    ($next = $this) if ($this > $next);
  };
  return ($paths{'data'.$next}->{file}) ? $next+1 : $next;
};


## return a list of all data sets included in the fit
sub all_data {
  return (sort (grep {$paths{$_}->get('include')} (grep /^data(\d+)$/, (keys %paths) )));
};

## return a list of every data in %paths regardless of whether it is
## included in the fit
sub every_data {
  return (sort (grep /^data(\d+)$/, (keys %paths) ));
};

## return a list of all feff calculations associated with the
## specified data set
sub data_feff {
  my $this = shift;
  my @list = ();
  foreach my $p (&path_list) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless $paths{$p}->type;
    next unless ($paths{$p}->type eq 'feff');
    next unless ($paths{$p}->data eq $this);
    push(@list, $p);
  };
  return @list;
};

## return a list of all included paths associated with the specified
## data set
sub data_paths {
  my $this = shift;
  my @list = ();
  foreach my $p (&path_list) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless ($paths{$p}->type eq 'path');
    next unless ($paths{$p}->data eq $this);
    next unless $paths{$p}->get('include');
    push(@list, $p);
  };
  return @list;
};

sub rename_data {
  Error("There is no data."), return unless $n_data;
  my $this = $current;
  $this = $paths{$current}->data;
  ##($this = $paths{$current}->{data}) if (exists $paths{$current}->{data});
  ##($this = &first_data) if ($current eq 'gsd');
  my $oldname = $paths{$this}->get('lab');
  my $newname = $oldname;
  my $label = "New name for data \"$oldname\": ";
  my $dialog = get_string($dmode, $label, \$newname, \@rename_buffer);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Not renaming ". $paths{$this}->get('lab')), return if ($oldname eq $newname);
  $newname =~ s{[\"\']}{}g;
  my $exists = 0;
  foreach my $d (&every_data) {
    $exists = 1, last if ($newname eq $paths{$d}->get('lab'));
  };
  Error("There is already a data set named \"$newname\"!"), return if $exists;
  project_state(0);
  push @rename_buffer, $newname;
  $paths{$this} -> make(lab=>$newname);
  $list -> itemConfigure($this, 0, -text=>$newname);
};


sub toggle_data {
  my $data = $_[0];
  my $style = ($paths{$data}->get('include')) ? $list_styles{enabled} : $list_styles{disabled};
  $list -> entryconfigure($data, -style => $style);
  foreach my $p (keys %paths) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    next unless $paths{$p}->type;
  SWITCH: {
      ($paths{$p}->type =~ /(bkg|data|fit|res)/) and do {
	last SWITCH unless ($paths{$p}->get('sameas') eq $data);
	last SWITCH unless $list->infoExists($paths{$p}->get('id'));
	my $style = ($paths{$data}->get('include')) ? $list_styles{enabled} : $list_styles{disabled};
	$list -> entryconfigure($paths{$p}->get('id'), -style => $style);
	last SWITCH;
      };
      ($paths{$p}->type eq 'feff') and do {
	last SWITCH unless ($paths{$p}->data eq $data);
	my $style = ($paths{$data}->get('include')) ? $list_styles{noplot} : $list_styles{noplotdis};
	$list -> entryconfigure($paths{$p}->get('id'), -style => $style);
	last SWITCH;
      };
      ($paths{$p}->type eq 'path') and do {
	last SWITCH unless ($paths{$p}->data eq $data);
	my $style = $list_styles{$paths{$data}->pathstate("enabled")};
	$style = $list_styles{$paths{$data}->pathstate("disabled")} if (not $paths{$data}->get('include'));
	$style = $list_styles{$paths{$data}->pathstate("disabled")} if ($paths{$data}->get('include') and
								       not $paths{$p}->get('include'));
	$list -> entryconfigure($paths{$p}->get('id'), -style => $style);
	last SWITCH;
      };
    };
  };
  if ($paths{$current}->type =~ /(bkg|data|diff|fit|res)/) {
    my @all = &every_data;
    $widgets{op_do_bkg} -> configure(-state=>($#all) ? 'disabled' : 'normal' );
    ##$widgets{op_use_bkg} -> configure(-state=>($#all) ? 'disabled' : 'normal' );
  };
  project_state(0);
};


sub make_difference_spectrum {
  my $this = $paths{$current}->data;
  unless (-e $paths{$this}->get('file')) {
    Error("You have not yet imported this data file.");
    return;
  };
  unless ($list->info(exists=>$paths{$this}->get('id').'.0')) {
    Error("You have not yet done a fit.  You cannot yet make a difference spectrum.");
    return;
  };

  my @paths = grep {(ref($paths{$_}) =~ /Ifeffit/) and
		      ($paths{$_}->type eq 'path')} $list->info('selection');
  Error("You did not select any paths.  The difference spectrum is computed from the set of highlighted paths."),
    return unless @paths;
  $top -> Busy;
  my $not_from_this = 0;
  foreach (@paths) {
    ++$not_from_this if ($paths{$_}->data ne $this);
  };
  if ($not_from_this) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "You have selected paths not associated with the current data set.  Do you want to continue making the difference spectrum?",
		     -title          => 'Athena: Question...',
		     -buttons        => [qw/Yes No/],
		     -default_button => 'No',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    my $response = $dialog->Show();
    if ($response eq 'No') {
      Echo("Difference spectrum aborted");
      $top -> Unbusy;
      return;
    };
  };

  my $explanation = "Difference between " . $paths{$this}->descriptor() .
    " and these paths:\n";
  my $string = "## Making difference spectrum from data ";
  $string   .= $paths{$this}->descriptor() . $/;
  $paths{$this} -> make(diff_paths=>[], diff_list=>[], diff_mapping=>[]);
  foreach my $p (sort {(split(/\./,$a))[0] cmp (split(/\./,$b))[0]
			 or
		       (split(/\./,$a))[1] cmp (split(/\./,$b))[1]
			 or
		       (split(/\./,$a))[2] <=> (split(/\./,$b))[2]
		     } @paths) { # make sure they are in order
    next unless ($paths{$p}->get('include'));  # skip paths deselected for fit
    my $ind    = $paths{$p}->index;
    my $data   = $paths{$p}->data;
    my $pathto = $paths{$p}->get('path');
    ## need to keep track of which paths went into this diff spectrum
    ## so they can be deselected for a fit to the diff spectrum
    push @{$paths{$data}->{diff_paths}}, $p;
    push @{$paths{$data}->{diff_list}}, $ind;
    $paths{$data}->{diff_mapping}->[$ind] = $p;
    $string   .= $paths{$p} -> write_path($ind, $pathto, $config{paths}{extpp}, $stash_dir);
    $explanation .= ".\t" . $paths{$p}->descriptor() . $/;
  };

  ## do an ff2chi on the selected paths
  my $group = $paths{$this}->get('group');
  $string .= $paths{$this} ->
    write_ff2chi( &normalize_paths($paths{$this}->{diff_list}), $group."_sum" );

  ## make the difference spectrum
  $string .= "set ${group}_diff.k   = $group.k\n";
  if ((lc($paths{$this}->get('do_bkg')) eq 'yes') or $paths{$this}->get('use_bkg')) {
    $string .= "set ${group}_diff.chi = $group.chi - ${group}_sum.chi - ${group}_bkg.chi\n";
  } else {
    $string .= "set ${group}_diff.chi = $group.chi - ${group}_sum.chi\n";
  };

  ## get the filename to save this diff spectrum to
  my $types = [['chi Files', '*.chi'],
	       ['All Files', '*'],];
  my $path = File::Spec->catfile($project_folder, "chi_data", "");
  my $fname = basename($paths{$this}->get('file'));
  my @list = split(/\./, $fname);
  $fname = $list[0] . "_diff." . $list[1];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$fname,
				 -title => "Artemis: Save difference spectrum");
  $top -> Unbusy, return unless $file;
  ## fetch the titles for this data
  my $titles = $widgets{op_titles}->get(qw(1.0 end));
  my $n = 1;
  foreach my $e (split(/\n/, $explanation)) {
    $string .= "\$artemis_title$n = \"$e\"\n";
    ++$n;
  };
  foreach my $t (split(/\n/,$titles)) {
    next if ($t =~ /^\s*$/);
    $string .= "\$artemis_title$n = \"$t\"\n";
    ++$n;
  };
  $string .= "\$artemis_title$n = \"artemis: " . $paths{$this}->get('lab') . " as background subtracted chi(k)\"\n";
  ## write and erase the difference data
  $string .= "write_data(file=$file,\n" .
    wrap("           ", "           ", "\$artemis_title*, ${group}_diff.k, ${group}_diff.chi)");
  $string .= "\n";
  $string .= "erase \@group ${group}_diff\n";
  $paths{$this} -> dispose($string, $dmode);

  ## offer to reload the bkg sub data
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Would you like to replace the current data set with the difference spectrum?",
		   -title          => 'Athena: Replace data?',
		   -buttons        => [qw/Yes No/],
		   -default_button => 'Yes',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  if ($dialog->Show() eq 'Yes') {
    $paths{$this}->make(do_bkg=>'no');
    &read_data($paths{$current}->data, $file, 1);
    ## need to uninclude the paths that went into the diff spectrum
    foreach my $p (@paths) {
      &select_paths('toggle', $p, 1)
    };
  };
  $top -> Unbusy;
  Echo("Saved difference spectrum to $file");
};




sub delete_data {
  my $data = $paths{$current}->data;
  my $label = $paths{$data}->get('lab');

  Error("You cannot discard the first data set.  Try changing the data via the \"Open data file\" in the Data menu."),
    return if ($data eq 'data0');
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Are you sure you want to discard \"$label\" and all it's paths?",
		   -title          => 'Artemis: Verifying...',
		   -buttons        => [qw/Discard Cancel/],
		   -default_button => 'Discard',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  my $response = $dialog->Show();
  Echo("Not discarding \"$label\""), return unless ($response eq 'Discard');
  Echo("Discarding \"$label\" and all its paths ... ");

  ## discard titles for this data group
  $paths{$data}->delete_titles;

  my $first = &first_data;
  ($first = 'data0') if ($first eq $data);
  $paths{$first}->make(include=>1), &toggle_data($first) unless $paths{$first}->included;
  display_page($first);

  $list -> delete('offsprings', $data);
  $list -> delete('entry',      $data);
  my (@delete_em, @rmtree);
  foreach my $k (keys %paths) {
    #print $k, $/;
    #next unless exists($paths{$k});
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless $paths{$k}->type;
    ##     push(@delete_em, $k) if ($k eq $data);
    ##     push(@rmtree, $k) if (($paths{$k}->type eq 'feff') and ($k =~ /^$data/));
    push(@delete_em, $k) if ($paths{$k}->data eq $data);
    ##     if (exists $paths{$k}->{data}) {
    ##       push(@delete_em, $k) if ($paths{$k}->data eq $data);
    ##     };
    ##     if (exists $paths{$k}->{sameas}) {
    ##       push(@delete_em, $k) if ($paths{$k}->{sameas} eq $data);
    ##     };
  };
  map { delete $paths{$_} } @delete_em;
  map { rmtree(File::Spec->catfile($project_folder, $_)) } @rmtree;

  ## deactivate these two checkbuttons if we now have only one active
  ## data set
  my $n = 0; map {++$n} (&all_data);
  if ($n == 1) {
    $widgets{op_include} -> configure(-state=>'disabled');
    $widgets{op_plot}    -> configure(-state=>'disabled');
  };

  ## is at least one data set included in the fit?
  my $ok = 0;
  foreach my $d (&all_data) {
    $ok++ if $paths{$d}->get('include');
  };
  ## if not, turn on data0
  unless ($ok) {
    $paths{data0}->make(include=>1);
    toggle_data('data0');
    #foreach my $p (keys %paths) {
    #  next unless ($paths{$p}->get('parent') eq 'data0');
    #  next unless ($paths{$p}->type eq 'feff');
    #  $paths{$p}->make(include=>1);
    #};
  };

  Echo("Discarding \"$label\" and all its paths ... done!");
};

sub nidp {
  Error("You have not opened a data file yet."), return unless $paths{&first_data}->get('file');
  my ($nidp, $ndat) = (0, 0);
  foreach my $k (keys %paths) {
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    next unless ($paths{$k}->type eq 'data');
    next unless ($paths{$k}->{include});
    my $deltak = $paths{$k}->get('kmax') - $paths{$k}->get('kmin');
    my $deltar = $paths{$k}->get('rmax') - $paths{$k}->get('rmin');
    $nidp     += int( 2 * $deltak * $deltar / PI );
    ++$ndat;
  };
  ($nidp = 0) if ($nidp < 0);
  my $nvar = 0;
  foreach (@gds) {
    ++$nvar if ($_->type eq 'guess');
  };
  my $message = "$nidp independent points data points (Nyquist): ($ndat data set";
  $message .= ($ndat > 1) ? "s)" : ")";
  $message .= "  ($nvar variable";
  $message .= ($nvar > 1) ? "s)" : ")";
  $props{'Information content'} = $message;
  Echo($message);
};


sub fetch_epsilon_k {
  Error("You have not opened a data file yet."), return unless $paths{&first_data}->get('file');
  my $this  = $paths{$current}->data;
  my $lab   = $paths{$this}->descriptor;
  my @noise = $paths{$this}->chi_noise;
  Echo(sprintf("The noise in k for \"$lab\" is %.7f and in R is %.7f", @noise));
};


## this currently only works on the most recent fit -- need to
## generalize to all fits...
sub running_r_factor {
  Error("You have not opened a data file yet."), return unless $paths{&first_data}->get('file');
  my $space = $_[0];

  ## presumably, the current is a fit and not the head of the branch
  my $this  = $paths{$current}->data;

  my (@x, @y, $max_y);


  ## before doing this, shift anchor from head of fit branch to latest
  my $data = $paths{$current}->data;
  my $which = (($paths{$current}->type eq 'fit') and $paths{$current}->get('parent')) ?
    $current :
      $paths{$data.".0"}->get('thisfit');
  display_page($which);
  $top -> update;

  ## plot the data and fit for this data set
  my $group = $paths{$this}->get('group');
  $list -> selectionSet($this);
  &plot($space, 0);

  ## compute the running r-factor in the appropriate space
  my ($datasum, $diffsum, $ndata) = (0, 0, 0);
  if (lc($space) eq 'k') {
    my $kw  = $plot_features{kweight};
    my @k   = Ifeffit::get_array($group.".k");
    my @chi = Ifeffit::get_array($group.".chi");
    unless ($paths{$current}->get('imported')) {
      ## read this fit into its group if it has not already been imported
      my $command = "read_data(file=\"" .
	$paths{$current}->get('fitfile') .
	  "\",\n" .
	    "          type=chi, group=". $paths{$current}->get('group') . ")\n";
      $paths{$current}->dispose($command, $dmode);
      $paths{$current}->make(imported=>1);
    };
    my @fit = Ifeffit::get_array($paths{$current}->get('group').".chi");
    foreach (0 .. $#k) {
      if ($k[$_] < $paths{$this}->get('kmin')) {
	push @x, 0;
	push @y, 0;
	next;
      };
      last if ($k[$_] > $paths{$this}->get('kmax'));
      ##$datasum += $chi[$_]**2;
      $diffsum += ($chi[$_]*$k[$_]**$kw - $fit[$_]*$k[$_]**$kw)**2;
      push @x,  $k[$_];
      push @y, $diffsum;
      ##++$ndata;
    };
    $paths{$this} -> dispose("___x = ceil($group.chi*$group.k^$kw)", 1);
    $max_y = Ifeffit::get_scalar("___x");
  } elsif (lc($space) eq 'r') {
    my @r    = Ifeffit::get_array($group.".r");
    my @chi  = Ifeffit::get_array($group.".chir_re");
    my @chi2 = Ifeffit::get_array($group.".chir_im");
    unless ($paths{$current}->get('imported')) {
      ## read this fit into its group if it has not already been imported
      my $command = "read_data(file=\"" .
	$paths{$current}->get('fitfile') .
	  "\",\n" .
	    "          type=chi, group=". $paths{$current}->get('group') . ")\n";
      $paths{$current}->dispose($command, $dmode);
      $paths{$current}->make(imported=>1);
    };
    $paths{$current}->dispose($paths{$current}->write_fft(0,$config{data}{rmax_out}), $dmode);
    my @fit  = Ifeffit::get_array($paths{$current}->get('group').".chir_re");
    my @fit2 = Ifeffit::get_array($paths{$current}->get('group').".chir_im");
    my $rmin = $paths{$this}->get('rmin');
    ($rmin = 0) if (lc($paths{$this}->get('do_bkg')) eq 'yes');
    foreach (0 .. $#r) {
      if ($r[$_] < $rmin) {
	push @x, 0;
	push @y, 0;
	next;
      };
      last if ($r[$_] > $paths{$this}->get('rmax'));
      ##$datasum += $chi[$_]**2 + $chi2[$_]**2;
      $diffsum += ($chi[$_]-$fit[$_])**2 + ($chi2[$_]-$fit2[$_])**2;
      push @x, $r[$_];
      push @y, $diffsum;
      ##++$ndata;
    };
    $paths{$this} -> dispose("set ___x = ceil($group.chir_mag)", 1);
    $max_y = Ifeffit::get_scalar("___x");
  } elsif (lc($space) eq 'q') {
    my @q    = Ifeffit::get_array($group.".q");
    my @chi  = Ifeffit::get_array($group.".chiq_re");
    my @chi2 = Ifeffit::get_array($group.".chiq_im");
    unless ($paths{$current}->get('imported')) {
      ## read this fit into its group if it has not already been imported
      my $command = "read_data(file=\"" .
	$paths{$current}->get('fitfile') .
	  "\",\n" .
	    "          type=chi, group=". $paths{$current}->get('group') . ")\n";
      $paths{$current}->dispose($command, $dmode);
      $paths{$current}->make(imported=>1);
    };
    $paths{$current}->dispose($paths{$current}->write_fft(0,$config{data}{rmax_out}), $dmode);
    $paths{$current}->dispose($paths{$current}->write_bft, $dmode);
    my @fit  = Ifeffit::get_array($paths{$current}->get('group').".chiq_re");
    my @fit2 = Ifeffit::get_array($paths{$current}->get('group').".chiq_im");
    foreach (0 .. $#q) {
      if ($q[$_] < $paths{$this}->get('kmin')) {
	push @q, 0;
	push @y, 0;
	next;
      };
      last if ($q[$_] > $paths{$this}->get('kmax'));
      ##$datasum += $chi[$_]**2 + $chi2[$_]**2;
      $diffsum += ($chi[$_]-$fit[$_])**2 + ($chi2[$_]-$fit2[$_])**2;
      push @x, $q[$_];
      push @y, $diffsum;
      ##++$ndata;
    };
    $paths{$this} -> dispose("___x = ceil($group.chiq_mag)", 1);
    $max_y = Ifeffit::get_scalar("___x");
  };

  ## normalize the running r-factor to the data
  my $scale = $max_y / $y[$#y];
  foreach my $i (0 .. $#y) {
    $y[$i] *= $scale;
  };

  ## load the arrays into ifeffit
  Ifeffit::put_array('r___unning.x', \@x);
  Ifeffit::put_array('r___unning.y', \@y);

  my $color = ($plot_features{win}) ? 'c3' : 'c2';
  ## plot the running r-factor over the data+fit
  my $message = "r___unning.x, r___unning.y, key=\"running R-factor\", ";
  $message   .= "color=$config{plot}{$color}, style=lines, ";
  $message   .= "title=\"Running R-factor, " . $paths{$this}->get('lab') . ", and fit\")";
  $message    = wrap("plot(", "     ", $message);
  $paths{$this}->dispose($message, $dmode);

};


sub verify_data_parameters {
  my $message = "";
  foreach my $d (&all_data) {

    $message .= $paths{$d}->get('lab') . ": kmin is greater than kmax\n"
      if ($paths{$d}->get('kmin') > $paths{$d}->get('kmax'));

    $message .= $paths{$d}->get('lab') . ": kmax is zero\n"
      if ($paths{$d}->get('kmax') < EPSILON);

    $message .= $paths{$d}->get('lab') . ": rmin is greater than rmax\n"
      if ($paths{$d}->get('rmin') > $paths{$d}->get('rmax'));

    $message .= $paths{$d}->get('lab') . ": rmax is zero\n"
      if ($paths{$d}->get('rmax') < EPSILON);

  };
  return $message;
};

sub verify_reffs {
  my $message = "";
  foreach my $d (&all_data) {
    my $this_rmax = $paths{$d}->get('rmax');
    my $this_ok = 1;
    foreach my $p (&path_list) {
      next unless (ref($paths{$p}) =~ /Ifeffit/);
      next unless ($paths{$p}->type eq 'path');
      next unless ($paths{$p}->get('data') eq $d);
      next unless ($paths{$p}->get('include'));
      if ( $paths{$p}->get('reff') > $this_rmax*$config{warnings}{reff_margin} ) {
	$message .= "\t" . $paths{$p}->descriptor . "\n";
	$this_ok = 0;
      };
    };
    unless ($this_ok) {
      $message  = "Artemis found one or more paths that are far outside the fitting range:\n" . $message;
      $message .= "Check the R-range of data set \"" . $paths{$d}->descriptor . "\"\n\n";
    };
  };
  return $message;
};

sub verify_rmin_rbkg {
  my $message = "";
  foreach my $d (&all_data) {
    my $this_rmin = $paths{$d}->get('rmin');
    my $this_rbkg = $paths{$d}->get('bkg_rbkg');
    next unless $this_rbkg;
    if ($this_rmin < $this_rbkg) {
      $message .= "\nThe value of rmin for \"" . $paths{$d}->descriptor . "\" is smaller than the value of\n";
      $message .= "Rbkg used during background removal in Athena.\n";
      $message .= "     rmin = $this_rmin        Rbkg = $this_rbkg\n";
    };
  };
  if ($message) {
    $message .= "\nLetting rmin be smaller than Rbkg is dangerous in that it masks important\n";
    $message .= "correlations between the data and the background.\n\n";
  };
  return $message;
};

##  END OF THE DATA SUBSECTION

