## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  the informational palettes


## $group_title_##
sub update_titles {
  my $group = $_[0];

};

sub raise_palette {
  ($update->state() eq "normal") ? $update->raise : $update->deiconify && $update->raise;
  $notebook->raise($_[0]);
};


sub setup_data {
  #my $this = $_[0] || $groups{$current}->{file};
  my $this = $groups{$current}->{file};
  Echo('No data!'), return unless ($this);
  Echo("The Default Parameters have no associated data"), return if ($this eq "Default Parameters");
  Echo("The current group has no associated file"), return unless (-e $this);
  if (Ifeffit::Files->is_record($this)) {
    Error("This data is from a project file and may not be edited via the data palette.");
    $notes{data} -> insert('end', 'This data is from a project file and may not be edited this way.', "text");
    $update->deiconify;
    $notebook->raise('data');
    $top->update;
    return;
  };
  $update->deiconify;
  $notebook->raise('data');
  $current_file = $this;
  #my $file = $_[0] || $groups{$current}->{file};
  my $file = $groups{$current}->{file};
  open F, $file or die "Could not open $file\n";
  $notes{data} -> configure(-state=>'normal');
  $notes{data} -> delete(qw/1.0 end/);
  while (<F>) {
    s/\r//;
    $notes{data} -> insert('end', $_, "text");
  };
  ## this was a stab at putting the view at the beginning of the
  ## data. it cause Athena to crash in certain situations.  that
  ## doesn't seem like a good idea...

#  if ($_[0]) {
##     my $comm = Ifeffit::get_string('$commentchar');
##     my $lab  = (split(" ",Ifeffit::get_string('$column_label')))[0];
##     my $regex = "^[ \\t$comm]*$lab";
##     ##print $regex, $/;
##     my $index = $notes{data} -> search('-regexp', $regex, '1.0', 'end');
##     $index = $notes{data} -> index($index);
##     my @parts = split(/\./, $index);
##     $index = $parts[0] - 2;
##     $index .= ".$parts[1]";
##     $notes{data} -> yview($index);
##     $top -> update;
#  };
  close F;
};


## what about records and chi data?
sub save_and_reload {
  Echo("Cannot save and reload, \"$groups{$current}->{label}\" is frozen."), return if ($groups{$current}->{frozen});
  Echo("Save and reload does not yet work for records"), return if $groups{$current}->{is_rec};
  my $how = $_[0];
  my $n = 3;
  my $tmp = "." x $n . "athena.tmp"; # this will eventually find an
  while (-f $tmp) {		     # unused temporary file name
    ++$n;
    $tmp = "." x $n . "athena.tmp";
  };
  my $file = $tmp;
  if ($how) {
    #local $Tk::FBox::a;
    #local $Tk::FBox::b;
    my $path = $current_data_dir || Cwd::cwd;
    my $f = basename($groups{$current}->{file});
    my $types = [['All Files', '*'], ['Data Files', '.dat']];
    $file = $top -> getSaveFile(-filetypes=>$types,
				#(not $is_windows) ?
				#  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-initialfile=>$f,
				-title => "Athena: Save edited data");
    return unless ($file and (-e $file));
    &push_mru($file, 1);
  };
  open D, '>'.$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  print D $notes{data} -> get(qw/1.0 end/);
  close D;
  my ($e, $x) = ($groups{$current}->{en_str}, $groups{$current}->{mu_str});
  $groups{$current} -> dispose("read_data(file=\"$file\", group=$current)\n", $dmode);
 SWITCH: {
    $groups{$current}->{is_xmu} and do {
      $groups{$current} -> dispose("set($current.energy = $e, $current.xmu = $x)\n", $dmode);
      $groups{$current} -> make(update_bkg=>1);
      $groups{$current} -> plotE('emz',$dmode,\%plot_features, \@indicator);
      $last_plot = 'e';
      $last_plot_params = [$current, 'group', 'e', 'emz'];
      last SWITCH;
    };
    $groups{$current}->{is_chi} and do {
      $groups{$current} -> dispose("set($current.k = $e, $current.chi = $x)\n", $dmode);
      $groups{$current} -> make(update_chi=>1);
      $groups{$current} -> plotk('kw',$dmode,\%plot_features, \@indicator);
      $last_plot = 'k';
      $last_plot_params = [$current, 'group', 'k', 'kw'];
      last SWITCH;
    };
    ## rsp? qsp?
  };
  if ($how) {
    $groups{$current} -> make(file=>$file);
  } else {
    unlink $file;
  };
};

## END OF PALETTES SUBSECTION
##########################################################################################
