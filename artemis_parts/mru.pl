## -*- cperl -*-
##
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##
##  This implements the most-recently-used (MRU) file functionality


## handle the MRU stack.  Also deal with the global variables that
## keep track of the current working directory and the current project
## file name.
sub push_mru {
  my ($file, $push_file, $type) = @_;
  my ($name, $path, $suffix) = fileparse($file);

  return if ($file eq $autosave_filename);
  ## set some global variables
  $current_data_dir = $path;
#  ($project_name = $file) if (&is_record($file));
  return unless ($push_file);

  my $item = $file . ' [' . $type . ']';
  ## check to see if this file is already in the sack
  my $im = $config{general}{mru_limit};
  my $ifound = 0;
  foreach my $i (1 .. $im-1) {
    ($ifound = $i), last if ($item eq $mru{mru}{$i});
  };

  ## if it is on the stack already, remove it and move all lower ones
  ## up
  if ($ifound) {
    foreach my $i ($ifound+1 .. $im) {
      my $j = $i - 1;
      $mru{mru}{$j} = $mru{mru}{$i};
    };
  };

  ## push each entry down in the stack
  foreach my $i (reverse(1 .. $im-1)) {
    my $j = $i + 1;
    $mru{mru}{$j} = $mru{mru}{$i};
  };
  ## push this file to the top of the stack
  $mru{mru}{1} = $item;

  ## update the mru menu
  &set_recent_menu;

  ## save the mru file
  tied(%mru) -> WriteConfig($mrufile);

  return $name;
};

sub set_recent_menu {
  my $menu = $file_menu -> cget('-menu') -> entrycget('Recent files', '-menu');
  $menu -> delete(0,'end');
  foreach my $i (1 .. $config{general}{mru_limit}) {
    last unless ($mru{mru}{$i});
    my $label = $mru{mru}{$i};
    if ($config{general}{mru_display} eq "name") {
      $label =~ /^([^\[]*)(\[.*\])/;
      my $type = $2;
      (my $file = $1) =~ s/\s+$//;
      $label = basename($file) . " " . $type;
    };
    $menu -> add('command', -label=>$label, @menu_args,
		   -command=>sub{&dispatch_mru($mru{mru}{$i})});
  };
};


sub dispatch_mru {
  return unless $_[0];
  my ($file, $type) = ($_[0], "");
  ($file, $type) = ($1, $2) if ($_[0] =~ /(.+) \[(\w+)\]$/);
  Echo("Could not find \"$file\""), return unless (-e $file);
  Echo("Reading recent file \"$file\"");
  if ($type eq 'atoms') {
    &import_atoms($file);
  } elsif ($type eq 'feff') {
    &read_feff($file);
  } elsif ($type eq 'feffit') {
    &feffit_convert_input($file);
  } elsif ($type eq 'project') {
    &read_data($paths{$current}->data, $file);
  } elsif ($type eq 'athena') {
    &read_athena($file);
  } else {			# data
    my @data = &every_data;
    my $this = $paths{$current}->data;
    if ($#data or $paths{$this}->get('file')) {
      my $message = "Do you wish to read in a new data file (that is, to do multiple data set fitting), or do you wish to change the current data file (that is, to apply this fitting model to a different data set) ?";
      my $dialog =
	$top -> Dialog(-bitmap         => 'questhead',
		       -text           => $message,
		       -title          => 'Athena: Reading data',
		       -buttons        => [qw/Change New Cancel/],
		       -default_button => 'Change',
		       -font           => $config{fonts}{med},
		       -popover        => 'cursor');
      &posted_Dialog;
      my $response = $dialog->Show();
      Echo("Canceling data import"), return if ($response eq 'Cancel');
      Echo("Reading \"$file\"");
      my $change = ($response eq 'Change') ? 1 : 0;
      read_data($change, $file);
    } else {
      read_data(0, $file);
    };
    ##&dispatch_read_data(1, $file);
  };
  ## make sure something is marked for plotting after the fit
  my @all = &all_data;
  foreach (@all) {
      return $type if $paths{$_}->get('plot');
  };
  $widgets{op_plot} -> select;
  $paths{$all[0]}->make(plot=>1);
  return $type;
};


## END OF MRU SUBSECTION
##########################################################################################
