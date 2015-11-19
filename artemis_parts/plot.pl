# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##

###===================================================================
### plotting subsystem
###===================================================================

sub plot {
  my $data = $paths{$current}->data;
  #unless ($list -> info('exists', $paths{$data}->{id}.".0")) {
  Echo("You're last plot was an Energy plot."), return "" if (lc($_[0]) eq 'e');
  Echo("You have not opened a data file or a feff calculation yet."), return ""
    unless ($n_data or $n_feff);
  #};
  ## need a foreach loop for multiple data sets
  my ($data_requested, $data_there) = (0, 1);
  foreach my $d ($list->info('selection')) {
    next unless (ref($paths{$d}) =~ /Ifeffit/);
    next unless ($paths{$d}->type =~ /(bkg|data|diff|fit|res)/);
    ++$data_requested;
    if ($paths{$d}->type eq 'data') {
      $data_there &&= ((-e $paths{$d}->get('file')) or ($paths{$d}->get('file') eq ""));
    } else {
      my $this = $paths{$d}->data;
      $data_there &&= ((-e $paths{$this}->get('file')) or ($paths{$this}->get('file') eq ""));
    };
  };
  ## if ($data_requested and $n_data and (not $data_there)) {
  ##     Echo("You have not yet loaded data or your data file does not exist.  Try \"Change data file\" in the Data menu.");
  ##     return "";
  ##   };
  ## this is flawed (do a foreach loop)
  my $feff_requested = grep(/(feff\d+)\.\d+/, $list->info('selection'));
  my $feffinp_exist  = 0;
  foreach ($list->info('selection')) {
    next unless (ref($paths{$_}) =~ /Ifeffit/);
    next unless ($paths{$_}->type eq 'path');
    $feffinp_exist ||= (-e $paths{$_}->get("feff.inp"));
  };
  if ($feff_requested and $n_feff and not $feffinp_exist) {
    Echo("Your feff calculation does not exist.  Perhaps you chould change the path.");
    return "";
  };
  if (not $feff_requested and not $data_requested) {
    #Echo("You have not selected any form of data or any paths for plotting.");
    #return "";
    my $first = &first_data;
    $list->selectionClear;
    $list->selectionSet($first);
    $list->selectionSet($list->info('next', $first));
  };
  my $space = lc($_[0]);
  Echo("Plotting in $space space ... ") unless $_[1];
  my $after_fit = $_[2];
  $top -> Busy();
  my $command = '';

  my $param_err .= &verify_data_parameters;
  if ($param_err) {
    $param_err = "There were errors among the data parameters:\n\n" . $param_err;
    post_message($param_err, "Error Messages");
    Error("plot aborted due to errors in data parameters");
    $top->Unbusy;
    return;
  };

  ## need variables for paths
  if ($feff_requested) {
    my $error = "";
    $error   .= &verify_parens;
    if ($error) {
      post_message($error, "Error Messages");
      Error("plot aborted due to errors in math expressions");
      $top->Unbusy;
      return;
    };
    ##$command .= &erase_all_variables;
    ##&read_gsd(1);			# update gsd object
    if ($parameters_changed) {
      map { $command .= $_ -> write_gsd } (@gds);
      $parameters_changed = 0;
    };
  };

  ## before plotting, adjust the selection so that if the head of a
  ## fit branch is requested for plotting, it is deselected and the
  ## latest fit is selected instead
  foreach my $p ($list->info('selection')) {
    next unless ($paths{$p}->type eq 'fit');
    next if $paths{$p}->get('parent');
    next unless $paths{$p}->get('thisfit'); # this keeps it from
                                            # plotzing when writing a
                                            # script without actually
                                            # running
    $list->selectionClear($p);
    $list->selectionSet($paths{$p}->get('thisfit'));
  };
  $top -> update;

 SWITCH: {
    ($space eq 'k') and do {
      $command .= $paths{$data} -> plot_k($list, \%plot_features, \@extra, $stash_dir);
      $last_plot = 'k';
      last SWITCH;
    };
    ($space eq 'r') and do {
      $command .= $paths{$data} -> plot_R($list, \%plot_features, \@extra, $stash_dir);
      $last_plot = 'r';
      last SWITCH;
    };
    ($space eq 'q') and do {
      $command .= $paths{$data} -> plot_q($list, \%plot_features, \@extra, $stash_dir);
      $last_plot = 'q';
      last SWITCH;
    };
    $command .= $paths{$data} -> plot_R($list, \%plot_features, \@extra, $stash_dir);
    $last_plot = 'r';
  };
  return $command if $_[1];

  #$notebook -> raise('ifeffit');
  $paths{gsd} -> dispose($command, $dmode);
  $paths{gsd} -> dispose($extra[6], $dmode) if $extra[5]; # indicators
  $extra[6] = "";
  #$config{general}{plot_tab} and $plotsel -> raise($space);

  $top->Unbusy;
  $command and Echo(@done);

};


sub replot {
  my $mode = $_[0];		# replot, print, or device_type
  Echo("You have not yet plotted anything."), return 0 unless ($last_plot);
  my ($title, $suf, $dev);
 SWITCH: {
      ($mode eq 'replot') and do {
	$paths{gsd}->dispose($Ifeffit::Path::last_plot_command, 1);
	Echo("Unzoomed.");
	return;
      };
      ($mode =~ /(gif|png)/) and do {
	($title, $suf, $dev) = ('Artemis: '.uc($1).' file name', $1, $mode );
	last SWITCH;
      };
      ($mode =~ /ps/) and do {
	($title, $suf, $dev) = ('Artemis: Postscript file name', 'ps', $mode);
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
      my $tmp = '...artemis.tmp';
      $paths{gsd}->dispose("plot(device=\"$dev\", file=\"$tmp\")\n", 7);
      local $| = 1;
      my $to = $config{general}{print_spooler};
      Echo("Sending image to printer via the  \"$to\" command");
      open OUT, "| $to" or
	die "could not open pipe to $to\n";
      open IN, $tmp or die "could not open temp file for printing";
      while (<IN>) { print OUT; };
      close IN; close OUT; unlink $tmp;
    };
    return;
  } else {
    ##local $Tk::FBox::a;
    ##local $Tk::FBox::b;
    my $types = [["$suf image files", $suf],
		 ['All Files', '*'],];
    my $file = $top -> getSaveFile(-defaultextension=>$suf,
				   -filetypes=>$types,
				   #(not $is_windows) ?
				   #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				   -initialfile=>"artemis.$suf",
				   -title => $title);
    if ($file) {
      ## make sure I can write to $file
      open F, ">".$file or do { Error("You cannot write to \"$file\"."); return };
      close F;
      my ($name, $pth, $suffix) = fileparse($file);
      $current_data_dir = $pth;
      Echo("saving image to $file");
      $paths{gsd}->dispose("plot(device=\"$dev\", file=\"$file\")\n", 7);
    };
  };
};


sub zoom {
  Echo('No data'), return unless $current;
  Echo("You have not yet plotted anything."),
    return unless $last_plot;
  Echo('Click corners to zoom');
  $paths{gsd}->dispose('zoom', 1);
  Echo('Zooming done!');
};

sub cursor {
  Echo('No data'), return unless $current;
  Echo("You have not yet plotted anything."),
    return unless $last_plot;
  Echo('Click on a point');
  $paths{gsd}->dispose('cursor(crosshair=true)', 1);
  Echo(sprintf("You selected  x=%f   y=%f",
	       Ifeffit::get_scalar("cursor_x"),
	       Ifeffit::get_scalar("cursor_y")));
};



sub keyboard_plot {
  my $who = $top->focusCurrent;
  $multikey = "";
  Echo("Plot Current group: specify plot space (k r q)");
  $echo -> focus();
  $echo -> grab;
  $echo -> waitVariable(\$multikey);
  $echo -> grabRelease;
  $who -> focus;
  Echo("$multikey is not a plot space!"), return unless (lc($multikey) =~ /^[kqr]$/);
 SWITCH: {
    &plot('k', 0), last SWITCH if (lc($multikey) eq 'k');
    &plot('r', 0), last SWITCH if (lc($multikey) eq 'r');
    &plot('q', 0), last SWITCH if (lc($multikey) eq 'q');
  };
};


sub select_all {
  foreach my $p (keys %paths) {
    next unless (ref($paths{$p}) =~ /Ifeffit/);
    my $pp = $p;
    ## ($pp = $1 . "_" . ("fit", "res", "bkg")[$2]) if $p =~ /(data\d)\.(\d)/;
    next if ($paths{$pp}->type eq 'feff');
    next if ($paths{$pp}->type eq 'gsd');
    next unless ($list->infoExists($paths{$p}->get('id')));
    next if (($paths{$pp}->type eq 'path') and not ($paths{$pp}->get('include')));
    $list -> selectionSet($paths{$p}->get('id'));
  };
};


sub deselect_all {
  $list -> selectionClear;
  $list -> selectionSet($current);
  $list -> anchorSet($current);
};

## END OF THE PLOTTING SUBSYSTEM

