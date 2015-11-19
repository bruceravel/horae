## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2006 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  saving and restoring plotting styles


sub plst_save {
  my $name;
  my $label = "Name for this plot style: ";
  my $loop = 1;
  while ($loop) {
    my $ed = get_string($dmode, $label, \$name, \@rename_history);
    $ed -> waitWindow;	# the get_string dialog will be
                        # destroyed once the user hits ok,
                        # then we can move on...
    Echo("Plot style save aborted."), return unless defined($name);
    Echo("Plot style save aborted."), return if ($name =~ /^\s*$/);
    $label = "Name (other than \"default\") for this plot style: ", next if ($name eq 'default');
    if (exists $plot_styles{$name}) {
      my $dialog = $top -> Dialog(-bitmap         => 'questhead',
				  -text           => "A plot style named \"$name\" already exists.",
				  -title          => 'Athena: Question...',
				  -buttons        => ['Overwrite', 'Different name', 'Cancel'],
				  -default_button => 'Overwrite');
      my $response = $dialog->Show();
      Echo("Plot style save aborted."), return if $response eq 'Cancel';
      next if $response eq 'Different name';
    };
    $loop = 0;
    foreach my $k (keys %plot_features) {
      next unless ($k =~ /^[ekqr](_|ma|mi)/);
      $plot_styles{$name}{$k} = $plot_features{$k};
    };
  };
  my $file = $groups{"Default Parameters"} -> find('athena', 'plotstyles');
  tied(%plot_styles) -> WriteConfig($file);
  Echo("Saved plot style \"$name\"");
};

sub plst_post_menu {
  ## figure out where the user clicked
  my $w = shift;
  my $Ev = $w->XEvent;
  delete $w->{'shiftanchor'};
  my ($X, $Y) = ($Ev->X, $Ev->Y);

  my @restore_list;
  my @discard_list;
  foreach my $ps (keys %plot_styles) {
    ##next if ($ps eq "___plst___");
    push @restore_list, [ command => $ps, -command => [\&plst_restore, $ps]];
    next if ($ps eq 'default');
    push @discard_list, [ command => $ps, -command => [\&plst_discard, $ps]];
  };

  $top ->
    Menu(-tearoff=>0,
	 -menuitems=>[
		      [ command   => "Save plot style",
		       -command   => \&plst_save],
		      [ cascade   => "Restore named style",
		       -tearoff   => 0,
		       -menuitems => [@restore_list]],
		      [ cascade   => "Discard named style",
		       -tearoff   => 0,
		       -menuitems => [@discard_list]],
		      [ command   => "About plot styles",
		       -command   => sub{pod_display("ui::styles.pod")}]
		     ])
	-> Post($X, $Y);
  $w -> break;
};

sub plst_restore {
  foreach my $k (keys %plot_features) {
    next unless ($k =~ /^[ekqr](_|ma|mi)/);
    $plot_features{$k} = $plot_styles{$_[0]}{$k};
  };
  #$last_plot='e';
  #$last_plot_params = [$current, 'marked', 'e', $str];
  if ($current eq 'Default Parameters') {
    1; # do nothing, probably there are no records in the project
  } elsif (not exists($last_plot_params->[1])) {
    1; # do nothing, probably there are no records in the project
  } elsif ($last_plot_params->[1] eq 'group') {
    autoreplot($last_plot);
  } else {
  SWITCH: {
      &plot_marked_e, last SWITCH if (lc($last_plot) eq 'e');
      &plot_marked_k, last SWITCH if (lc($last_plot) eq 'k');
      &plot_marked_r, last SWITCH if (lc($last_plot) eq 'r');
      &plot_marked_q, last SWITCH if (lc($last_plot) eq 'q'); 	# ,
    };
  };

  Echo("Restored saved plot style \"$_[0]\"");
};

sub plst_discard {
  my $dialog = $top -> Dialog(-bitmap         => 'questhead',
			      -text           => "Are you sure you want to discard plot style \"$_[0]\"?",
			      -title          => 'Athena: Question...',
			      -buttons        => ['Discard', 'Cancel'],
			      -default_button => 'Discard');
  my $response = $dialog->Show();
  Echo("Not discarding \"$_[0]\""), return if $response eq 'Cancel';
  delete $plot_styles{$_[0]};
  tied(%plot_styles) -> WriteConfig($groups{"Default Parameters"} -> find('athena', 'plotstyles'));
  Echo("Discarded plot style \"$_[0]\"");
};

## END OF PLOT STYLES SUBSECTION
##########################################################################################
