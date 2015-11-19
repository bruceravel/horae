# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##

###===================================================================
### file I/O
###===================================================================

sub open_file {
  ##local $Tk::FBox::a;
  ##local $Tk::FBox::b;
  my $path = $current_data_dir || cwd;
  ##print ">>> --$from_project--    --$current_data_dir--   --$path--\n";
  my @atoms_ext = ($STAR_Parser_exists) ? ('*.inp', '*.cif') : ('*.inp');
  my $types = [['All Artemis file types', ['*.prj', '*.chi', '*.apj', @atoms_ext]],
	       ['Athena projects',         '*.prj'],
	       ['chi(k) data',             '*.chi'],
	       ['Artemis projects',        '*.apj'],
	       ['Atoms/Feff input files', [@atoms_ext]],
	       ['All files',        '*'],];
  my $file = $top -> getOpenFile(-filetypes=>$types,
				 ##(not $is_windows) ?
				 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -title => "Artemis: Open a file");
  return unless ($file);
  Error("$file does not exist!"), return unless (-e $file);
  track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
 SWITCH: {
    import_atoms($file), last SWITCH if ($STAR_Parser_exists and Ifeffit::Files->is_cif($file));
    import_atoms($file), last SWITCH if (Ifeffit::Files->is_atoms($file));
    read_feff($file),    last SWITCH if (Ifeffit::Files->is_feff($file));
    read_athena($file),  last SWITCH if (Ifeffit::Files->is_athena($file));
    read_data(0, $file), last SWITCH if (Ifeffit::Files->is_artemis($file));
    do {
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
	Echo("Not reading data"), my $response = $dialog->Show();
	return if ($response eq 'Cancel');
	my $change = ($response eq 'Change') ? $this : 0;
	($change) ? Echo("Changing data") : Echo("Importing new data");
	read_data($change, $file);
      } else {
	read_data(0, $file);
      };
    };
  };
  ## make sure something is to be plotted after the fit
  my @all = &all_data;
  foreach (@all) {
    return if $paths{$_}->get('plot');
  };
  $paths{$all[0]}->make(plot=>1);
};

## This dispatcher handles all the possibilities for different avenues
## of reading in files and decided whether it should be a new data set
## in an MDS fit or if it should be a change of data in the current
## data set.
sub dispatch_read_data {
  my ($change, $file, $from_project) = @_;
  ##&read_data(@_), return unless ($config{general}{read_data_query});

  track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
  my @data = &every_data;
  my $this_data = $paths{$current}->data;
  &read_data, return unless ($#data or $paths{$this_data}->get('file'));

  ## test to see if this is a zip-style project
  if ($file) {
    Archive::Zip::setErrorHandler( \&is_zip_error_handler );
    my $zip = Archive::Zip->new();
    my $is_zipstyle = ($zip->read($file) == AZ_OK);
    undef $zip;
    Archive::Zip::setErrorHandler( undef );
    &read_data($paths{$current}->data, $file), return if $is_zipstyle;
  };

  ##if (($change) and ($change ne "1") and ($change !~ /Tk::Tree/) and (not $from_project)) {
  if ($#data or $paths{$this_data}->get('file')) {
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
    Echo("Not reading data"), return if ($response eq 'Cancel');
    if ($response eq 'Change') {
      Echo("Changing data");
      ## this is needed to handle an mru file
      if ($file) {
	&read_data($paths{$current}->data, $file);
      } elsif ($from_project) {
	&read_data($paths{$current}->data, $file, 1);
      } else {
	&renew_data;
      };
    } else {
      Echo("Importing new data.");
      &read_data(@_);
    };
  } else {
    &renew_data;
  };
};

sub renew_data {
  #track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
  &read_data($paths{$current}->data);
};

## this suppresses a nattering message that warns, in cryptic fashion,
## when you attempt to read a non-zip file as a zip file.  since that
## is the only way to test for zippiness of a file using Archive::Zip,
## simply suppressing the message seems appropriate.
sub is_zip_error_handler { 1; };

sub read_data {
  my $change = $_[0];
  my $file   = $_[1];
  my $from_project = $_[2] || 0;
  my $force_chi = $_[3] || 0;
  ((defined $change) and ($change =~ /data\d+/)) or ($change = 0);
  ##local $Tk::FBox::a;
  ##local $Tk::FBox::b;
  my $path = $current_data_dir || cwd;
  $path = File::Spec->catfile($project_folder, "chi_data", "") if $from_project;
  ##print ">>> --$from_project--    --$current_data_dir--   --$path--\n";
  my $types = [['Athena projects, chi(k) data, or Artemis projects', ['*.prj', '*.chi', '*.apj']],
	       ['Athena projects',  '*.prj'],
	       ['chi(k) data',      '*.chi'],
	       ['Artemis projects', '*.apj'],
	       ['All files',        '*'],];
  if ($from_project) {
    @$types[0,1,2] = @$types[2,0,1];
  } elsif ($change) {
    @$types[0,1] = @$types[1,0];
  };
  $file ||= $top -> getOpenFile(-filetypes=>$types,
				##(not $is_windows) ?
				##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-title => "Artemis: Open a data file");
  return unless ($file);
  Error("$file does not exist!"), return unless (-e $file);

  track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
  ## test to see if this is a zip-style project
  Archive::Zip::setErrorHandler( \&is_zip_error_handler );
  my $zip = Archive::Zip->new();
  my $is_zipstyle = ($zip->read($file) == AZ_OK);
  undef $zip;
  Archive::Zip::setErrorHandler( undef );
  ##Archive::Zip::setErrorHandler( \&Carp::carp );

  my $stash = $file;

  unless ($is_zipstyle) {
    track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
    my $was_mac = $paths{gsd} ->
      fix_mac($file, $stash_dir, lc($config{general}{mac_eol}), $top);
    track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;
    return, Echo("\"$file\" had Macintosh EOL characters and was skipped.") if ($was_mac eq "-1");
    if ($was_mac) {
      Echo("\"$file\" had Macintosh EOL characters and was fixed.");
      $stash = $was_mac;
    };
  };

  ## bad things happen if the data file name is longer than 128
  ## characters.  when this happens, transfer the file to the stash
  ## directory so ifeffit can read it from there.  if the filename is
  ## not too long, then $stash and $file will be the same
  ##   if (length($stash) > 127) {
  ##     my ($nme, $pth, $suffix) = fileparse($stash);
  ##     my $new = File::Spec->catfile($stash_dir, $nme);
  ##     ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  ##     copy($stash, $new);
  ##     $stash = $new;
  ##   };

  ## this is a zip-style project
  if ($is_zipstyle) {
    #$project_folder =
##     my $made_by = determine_version_from_project($file);
    $top -> Busy;
    my $is_error = unpack_zip($file); ## pass reference to zip object??
    $top->Unbusy, return 0 if $is_error;
    $project_name = $file;
    ##@-fp-@     my $fp_exists = (-e File::Spec->catfile($project_folder, "descriptions", "...fp"));
    ##@-fp-@     if ($fp_exists) {
    ##@-fp-@       my $is_ok = compare_fingerprint(File::Spec->catfile($project_folder, "descriptions", "...fp"),
    ##@-fp-@ 				      File::Spec->catfile($project_folder, "descriptions", "artemis"));
    ##@-fp-@       unless ($is_ok) {
    ##@-fp-@ 	my $dialog =
    ##@-fp-@ 	  $top -> Dialog(-bitmap         => 'warning',
    ##@-fp-@ 			 -text           => "The fingerprint of the description file has changed.  This could indicate that this project file has been tampered with.  It may be unsafe to continue reading this project file.",
    ##@-fp-@ 			 -title          => 'Artemis: Possibly tainted project file...',
    ##@-fp-@ 			 -buttons        => [qw/Continue Abort/],
    ##@-fp-@ 			 -default_button => 'Abort',
    ##@-fp-@		     -popover        => 'cursor');
    ##@-fp-@ 	&posted_Dialog;
    ##@-fp-@ 	my $response = $dialog->Show();
    ##@-fp-@ 	if ($response eq 'Abort') {
    ##@-fp-@ 	  delete_project(0);
    ##@-fp-@ 	  return;
    ##@-fp-@ 	};
    ##@-fp-@       };
    ##@-fp-@     };
    open_project(File::Spec->catfile($project_folder, "descriptions", "artemis"));
    set_fit_button('fit');
    $top->Unbusy;
    return;
  ## test to see if this is an old-style project
  } elsif (is_old_project($stash)) {
    $project_name = $stash;
    my $retval = convert_project_to_zip($stash);
    return 0 unless $retval;
    #$project_folder =
    my $is_error = unpack_zip($stash);
    return 0 if $is_error;
    open_project(File::Spec->catfile($project_folder, "descriptions", "artemis"));
    set_fit_button('fit');
    return;
  };

  ## or if it is a record from athena
  if (Ifeffit::Files->is_record($stash)) {
    Echo("Reading $file as an Athena project");
    read_athena($stash);
    return;
  };

  ## make sure this is interpretable as data
  $paths{data0} -> dispose("read_data(file=\"$file\", group=t___oss, no_sort)\n", $dmode);
  unless (Ifeffit::Files->is_datafile) {
    &posted_Dialog;
    $top -> Dialog(-bitmap  => 'error',
		   -text    => "\`$file\' could not be read by ifeffit as a data file",
		   -title   => 'Artemis: Error reading file',
		   -buttons => ['OK'],
		   -default_button => "OK",
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor' )
      -> Show();
    Echo("Failed to read \"$file\" as data");
    $paths{data0} -> dispose("erase \@group t___oss", $dmode);
    set_status(0);
    $top->Unbusy, return 0;
  };
  my $suff = (split(" ", Ifeffit::get_string('$column_label')))[0];
  $paths{data0} -> dispose("set ___n = npts(t___oss.$suff)", $dmode);
  my $nn = Ifeffit::get_scalar("___n");
  unless ($nn > 10) {
    &posted_Dialog;
    $top -> Dialog(-bitmap  => 'error',
		   -text    => "\`$file\' has fewer than 10 data points.",
		   -title   => 'Artemis: Error reading file',
		   -buttons => ['OK'],
		   -default_button => "OK",
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor' )
      -> Show();
    Echo("Failed to read \"$file\" as data");
    $paths{data0} -> dispose("erase \@group t___oss", $dmode);
    set_status(0);
    $top->Unbusy, return 0;
  };
  $paths{data0} -> dispose("erase \@group t___oss", $dmode);
  set_status(0);

  ## if we have multicolumn data, then we need to have the user choose
  ## the correct column, this column will be written to a data file in
  ## the chi_data directory of the project space

  ## -1=tagged by Athena 0=two column  else &n_arrays_read from Ifeffit
  my $is_multicolumn = (Ifeffit::Files->is_multicolumn($file) and (not $force_chi));
  my $bail = 0;
  if ($is_multicolumn) {
    Echo("$file is a multicolumn data file");
    my $cols = $top -> Toplevel(-title=>"Artemis: multicolumn file ($file)",
				-class=>'horae');
    $cols -> protocol(WM_DELETE_WINDOW => sub{$bail = 1;
					      $cols->grabRelease;
					      $cols->destroy;});
    $cols -> bind('<Control-q>' => sub{$bail = 1;
				       $cols->grabRelease;
				       $cols->destroy;});
    $cols -> iconimage($iconimage);
    $cols -> grab;
    my $left = $cols -> Frame()
      -> pack(-side=>'left',  -fill=>'y', -expand=>1);
    my $right = $cols -> Frame()
      -> pack(-side=>'right', -fill=>'both', -expand=>1);

    my $databox = $right -> Scrolled('ROText', -scrollbars=>'se', -width=>50,
				     -relief=>'sunken', -borderwidth=>2,
				     -wrap=>'none')
      -> pack(-fill=>'both', -expand=>1);
    BindMouseWheel($databox);
    $databox->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
    $databox->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
    do {
      local $/ = undef;
      open F, $file;
      $databox->insert('1.0', <F>);
      close F;
    };

    $left -> Label(-text=>"Select a chi(k) column",
		   @title2)
      -> pack(-side=>'top', -pady=>5);

    $paths{gsd} -> dispose("read_data(file=$file, group=t___oss)\n", 1);
    my @cols = split(" ", Ifeffit::get_string('$column_label'));
    my ($wn, $chi) = (@cols[0..1]);
    my $i = 0;
    my $top = $left -> Frame(-relief=>'groove', -borderwidth=>2)
      -> pack(-side=>'top', -anchor=>'n', -padx=>4, -pady=>4, -pady=>2);
    $top -> Label(-text=>'wavenumber', -foreground=>$config{colors}{activehighlightcolor})
      -> grid(-column=>1, -row=>0, -padx=>4, -pady=>2);
    $top -> Label(-text=>'chi(k)', -foreground=>$config{colors}{activehighlightcolor})
      -> grid(-column=>2, -row=>0, -pady=>2);
    foreach my $c (@cols) {
      ++$i;
      my $j = $i;
      $top -> Label(-text=>$c, -foreground=>$config{colors}{activehighlightcolor})
	-> grid(-column=>0, -row=>$i, -sticky=>'e', -pady=>2);
      $top -> Radiobutton(-text=>"", -value=>$c, -variable=>\$wn,
			  -command=>sub{($chi = ($j==5) ? $cols[0] : $cols[$j]) if ($wn eq $chi);
					my $command = "newplot(x=t___oss.$wn, y=t___oss.$chi, ";
					$command   .= "title=\"current column selection\", xlabel=x, ylabel=y)\n";
					$paths{gsd}->dispose($command, $dmode);
				      })
	-> grid(-column=>1, -row=>$i, -pady=>2);
      $top -> Radiobutton(-text=>"", -value=>$c, -variable=>\$chi,
			  -command=>sub{($chi = ($j==5) ? $cols[0] : $cols[$j]) if ($wn eq $chi);
					my $command = "newplot(x=t___oss.$wn, y=t___oss.$chi, ";
					$command   .= "title=\"current column selection\", xlabel=x, ylabel=y)\n";
					$paths{gsd}->dispose($command, $dmode);
				      })
	-> grid(-column=>2, -row=>$i, -pady=>2);
    };

    my $bottom = $left -> Frame()
      -> pack(-side=>'bottom', -fill=>'x', -expand=>1);
    my $ok = $left -> Button(-text=>'OK', @button2_list,
			     -command=>sub{$cols->grabRelease;
					   $cols->destroy})
      -> pack(-side=>'left', -fill=>'x', -expand=>1);
    $left -> Button(-text=>'Cancel', @button2_list,
		    -command=>sub{$bail=1;
				  $cols->grabRelease;
				  $cols->destroy})
      -> pack(-side=>'right', -fill=>'x', -expand=>1);
    my $command = "newplot(x=t___oss.$wn, y=t___oss.$chi, ";
    $command   .= "title=\"current column selection\", xlabel=x, ylabel=y)\n";
    $paths{gsd}->dispose($command, $dmode);
    $ok -> focus;
    $cols -> waitWindow;

    unless ($bail) {
      ## transfer this column to its own data file in the project data folder
      my $fname = File::Spec->catfile($project_folder, "chi_data", "$chi.chi");
      my ($count, $chi_orig) = (1, $chi);
      while (-e $fname) {
	$chi = $chi_orig . "_$count";
	++$count;
	$fname = File::Spec->catfile($project_folder, "chi_data", "$chi.chi");
      };
      $paths{gsd} -> dispose("set \$t___oss_title_01 = \"Artemis extracted data file -- Artemis version $VERSION\"\n", $dmode);
      $paths{gsd} -> dispose("write_data(file=$fname, \$t___oss_title_*, label=\"k chi\", t___oss.$wn, t___oss.$chi_orig)", $dmode);
      $paths{gsd} -> dispose("erase \@group t___oss\n", 1);
      &push_mru($file, 1, "data") unless $from_project;
      $stash = $fname;
      my $new = File::Spec->catfile($project_folder, "chi_data", basename($file));
      copy($file, $new) unless ($file eq $new);
      $from_project = 1;
    };
  };
  Echo("Aborting read of multicolumn data file $file."), return if $bail;

  ## nope... this is a data file.  import this data file into the project

  my $name = ($from_project) ? basename($file) : &push_mru($file, 1, "data");
  $name = basename($stash) if $is_multicolumn;
  #my ($name, $pth, $suffix) = fileparse($file);
  #$current_data_dir = $pth;

  ## make a place to put the data
  my $project_data_dir = File::Spec->catfile($project_folder, "chi_data");
  my $nme = basename($stash);
  my $bn  = basename($stash, qw(.chi));
  my $new = File::Spec->catfile($project_data_dir, $nme);
  ##($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
  my $count = 1;
  unless ($stash eq $new) {
    while (-e $new) {		# care not to overwrite files
      $new = File::Spec->catfile($project_data_dir, $bn."_$count.chi");
      ++$count;
    };
  };
  copy($stash, $new) unless ($stash eq $new);
  $stash = $new;

  my $label = unique_label($name);

  map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'normal')} (keys %widgets);
  map {$grab{$_}->configure(-state=>'normal')} (keys %grab);
  my $next = &next_data;
  my $group = $change || 'data' . $next;
  if ($change) {
    ## read the new data into ifeffit's memory
    my $command = "## Renewing data file:\n";
    #if ($stash ne $file) {
    #  $command .= "## actual file: $file\n";
    #  $command .= "## transfered to stash file: $stash\n";
    #};
    $command   .= "read_data(file=\"$stash\", type=chi, group=ch___eck)\n\n";
    $paths{$group} -> dispose($command, $dmode);
    Error("$file doesn't appear to be a data file"), return unless (&is_datafile);
    $command = "erase \@group ch___eck\n";
    $command   .= "read_data(file=\"$stash\", type=chi, group=$group)\n\n";
    ## delete the old title lines from Ifeffit's memory
    my ($i, $titles) = (1, "");
    my $string = join("", "\$", $group, "_title_", sprintf("%2.2d",$i));
    my $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    while ($str !~ /^\s*$/) {
      $string = join("", "\$", $group, "_title_", sprintf("%2.2d",$i));
      $paths{$group} -> dispose("$string = \"\"", $dmode);
      ++$i;
      $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    };
    $paths{$group} -> dispose($command, $dmode);
    ## put the new item in the path list
    #$name = (split(/\./, $name))[0];
    $paths{$group} -> make(file=>$stash, original_file=>$file,
			   lab=>$label, is_rec=>0,
			   with_bkg=>0, with_fit=>0, with_res=>0);
    ##$list -> hide('entry', $paths{$group}->get('id').".0");
    ##$list -> hide('entry', $paths{$group}->get('id').".1");
    ##$list -> hide('entry', $paths{$group}->get('id').".2");

    $list -> entryconfigure($paths{$group}->get('id'), -text=>$label);
    if (not &uniform_k_grid($group)) {
      #$paths{$group} -> make(fix_chi => 1);
      $paths{$group} -> dispose("## this seems to be chi(k) data in need of fixing...\nfix_chik($group)",
				$dmode);
      my $command = "\$artemis_title1 = \"Artemis output file, path -- Artemis version $VERSION\"\n";
      $command   .= "\$artemis_title2 = \"Data interpolated onto even grid \"\n";
      $command   .= "write_data(file=$stash,\n";
      $command   .= wrap("           ", "           ", "\$artemis_title*, \$${group}_title_*, $group.k, $group.chi)");
      $paths{$group} -> dispose($command, $dmode);
    };

    ## load up the new titles
    $i = 1;
    $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    while ($str !~ /^\s*$/) {
      $titles .= $str."\n";
      ++$i;
      $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    };
    $paths{$group} -> make(titles=>$titles);
    ## and display the new titles
    $widgets{op_titles} -> delete(qw(1.0 end));
    $widgets{op_titles} -> insert('end', $titles);
  } else {
    $paths{gsd} -> dispose("## Reading data file: \n", $dmode);
    #if ($stash ne $file) {
    #  $paths{gsd} -> dispose("## actual file: $file\n", $dmode);
    #  $paths{gsd} -> dispose("## transfered to stash file: $stash\n", $dmode);
    #};
    $paths{gsd} -> dispose("read_data(file=\"$stash\", type=chi, group=$group)\n\n", $dmode);
    Error("$file doesn't appear to be a data file"), return unless (&is_datafile);
    my $fit   = $group . '.0';
    #$name = (split(/\./, $name))[0];

    ## handle the list entry for this data set
    if ($next > 0) {
      $paths{$group} = Ifeffit::Path -> new(id		  => $group,
					    group	  => $group,
					    type	  => 'data',
					    sameas	  => 0,
					    file	  => $stash,
					    lab		  => $label,
					    original_file => $file,
					    family	  => \%paths);
      $list -> add($group, -text=>$label, -style=>$list_styles{enabled});
      $list -> setmode($group, 'none');

      $list -> add($group.".0", -text=>'Fit', -style=>$list_styles{enabled},);
      $list -> setmode($group.'.0', 'none');
      $list -> hide('entry', $group.".0");
    } else {			# this is the first data set
      $list -> entryconfigure($paths{$group}->get('id'), -text=>$label);
    };

    ## and set all the default values
    $paths{$group} -> make(group=>$group, file=>$stash, lab=>$label,
			   original_file=>$file,
			   fit_space => $config{data}{fit_space},
			   do_bkg    => ($config{data}{fit_bkg}) ? 'yes' : 'no',
			   kmin      => $config{data}{kmin},
			   kmax      => $config{data}{kmax},
			   dk        => $config{data}{dk},
			   k1        => ($config{data}{kweight} == 1),
			   k2        => ($config{data}{kweight} == 2),
			   k3        => ($config{data}{kweight} == 3),
			   rmin      => $config{data}{rmin},
			   rmax      => $config{data}{rmax},
			   dr        => $config{data}{dr},
			   kwindow   => $config{data}{kwindow},
			   rwindow   => $config{data}{rwindow},
			   cormin    => $config{data}{cormin},
			  );

    # interpret the range parameters
    if ($paths{$group}->get('kmax') == 0) {
      $paths{$group}->make(kmax=>15);
      my ($epsk, $epsr, $suggest) = $paths{$group}->chi_noise;
      $suggest ||= 15;
      $paths{$group}->make(kmax=>$suggest);
    };
    $paths{$group} -> fix_values();

    ## the or-eq is necessary for the situation where an ff2chi was
    ## done before the data was read in
    $paths{$fit}   ||=  Ifeffit::Path -> new(id     => $group.".0",
					     type   => 'fit',
					     group  => $group."_fit",
					     sameas => $group,
					     lab    => 'Fit',
					     parent => 0,
					     family => \%paths);
    if (not &uniform_k_grid($group)) {
      #$paths{$group} -> make(fix_chi => 1);
      $paths{$group} -> dispose("## this seems to be chi(k) data in need of fixing...\nfix_chik($group)",
				$dmode);
      my $command = "\$artemis_title1 = \"Artemis output file, path -- Artemis version $VERSION\"\n";
      $command   .= "\$artemis_title2 = \"Data interpolated onto even grid \"\n";
      $command   .= "write_data(file=$stash,\n";
      $command   .= wrap("           ", "           ", "\$artemis_title*, \$${group}_title_*, $group.k, $group.chi)");
      $paths{$group} -> dispose($command, $dmode);
    };
    ## other possible: eps_r toler do_real do_ph do_mag
    my ($i, $titles) = (1, "");
    my $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    while ($str !~ /^\s*$/) {
      $titles .= $str."\n";
      ++$i;
      $str = Ifeffit::get_string(join("", "\$", $group, "_title_", sprintf("%2.2d",$i)));
    };
    $paths{$group} -> make(titles=>$titles);
    $widgets{op_titles} -> insert('end', $paths{$group}->get('titles')) if
      (($group eq 'data0') and ($widgets{op_titles}->get(qw(1.0 end)) =~ /^\s*$/));

  };
  $props{'Project title'} = "Fitting ".$paths{$group}->descriptor
    if $props{'Project title'} =~ /^(\<|$)/;
  &set_fit_button('fit');

  ## save an autosave file...
  &save_project(0,1);

  ++$n_data;
  display_page($group);
  $file_menu->menu->entryconfigure($save_index, -state=>'normal'); # enable save data
  $file_menu->menu->entryconfigure($save_index+6, -state=>'normal');
  plot('r', 0);
  if ($is_multicolumn) {
    Echo("Read column $name from $file");
  } else {
    Echo("Read data from $file");
  };
  $top -> update();
  project_state(0);
  return $group;
};


## this should be called immediately after a disposal of
## "read_data". It checks the $column_label ifeffit global variable,
## which ifeffit sets to "--undefined--" when it is thinks that it was
## given a file that was not actually data.
sub is_datafile {
  my $col_string = Ifeffit::get_string('$column_label');
  return (not ($col_string =~ /^--undefined--$/));
};

sub determine_version_from_project {
  my $zipfile = $_[0];
  Archive::Zip::setErrorHandler( \&is_zip_error_handler );
  my $zip = Archive::Zip->new();
  die 'error reading project file $zipfile' unless $zip->read($zipfile) == AZ_OK;
  my $tmp = $paths{data0} -> find('artemis', 'tmp');
  $zip -> extractMember("descriptions/artemis", $tmp);
  open T, $tmp;
  my $line = <T>;
  chomp $line;
  close T;
  unlink $tmp;
  my $vnum = $1 if ($line =~ /version (.+)$/);
  undef $zip;
  Archive::Zip::setErrorHandler( undef );
  ($vnum = "DR" . $1) if ($vnum =~ /Development Branch Release (\d+)/);
  Echo("This project is from Artemis version $vnum");
  return $vnum;
};


## check to see that input chi(k) data is on a rigorously uniform
## k-grid. also check that the first point is either 0 or 0.05.
## return 0 if this data fails either test.
sub uniform_k_grid {
  my ($group) = @_;
  my @x = Ifeffit::get_array("$group.k");
  return 0 unless ((abs($x[0]) < EPSILON) or ($x[0]-0.05 < EPSILON));
  my $ok = 1;
  my $prev = sprintf "%.3f", $x[1] - $x[0];
  foreach (2 .. $#x) {
    my $this = sprintf "%.3f", $x[$_] - $x[$_-1];
    $ok = (
	   ($this eq $prev)
	   and
	   (abs($this-0.05) < EPSILON)
	  )
      ? 1 : 0;
    $prev = $this;
    return 0 if not $ok;
  };
  return $ok;
};


sub read_feff {
  my $file = ($_[0] =~ /^\^\^/) ? "" : $_[0];
  my $nopaths = $_[1];
  unless ($file) {
    ##local $Tk::FBox::a;
    ##local $Tk::FBox::b;
    my $path = $current_data_dir || cwd;
    if (($_[0] =~ /^\^\^/) and ($paths{$current}->get('type') =~ /(feff|path)/)) {
      $path = $paths{$current}->get('path');
    };
    ## apparently some windows apps will save a text file with a
    ## Capitalized File Name...
    my $types;
    if ($_[0]) {			# add a path
      $types = [['feffNNNN.dat and input files', [ 'feff*.dat', '*.inp', '*.INP', '*.Inp']],
		['FEFF input files', ['feff.inp', 'FEFF.INP', 'Feff.Inp', 'Feff.inp']],
		['feffNNNN.dat files', ['feff*.dat', 'FEFF*.DAT', 'Feff*.Dat', 'Feff*.dat']],
		['input files', ['*.inp', '*.INP', '*.Inp']],
		['All Files', '*'],];
    } else {			# read feff
      $types = [['FEFF input files', ['feff.inp', 'FEFF.INP', 'Feff.Inp', 'Feff.inp']],
		#['feffNNNN.dat files', ['feff*.dat', 'FEFF*.DAT', 'Feff*.Dat', 'Feff*.dat']],
		['input files', ['*.inp', '*.INP', '*.Inp']],
		#['feffNNNN.dat and input files', [ 'feff*.dat', 'FEFF.INP', 'Feff.Inp', 'Feff.inp', '*.inp', '*.INP', '*.Inp']],
		['All Files', '*'],];
    };
    $file = $top -> getOpenFile(-filetypes=>$types,
				##(not $is_windows) ?
				##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-title => "Artemis: Import a Feff calculation");
    return unless ($file);
  };
  Echo("Could not find \"$file\""), return unless (-e $file);
  my ($name, $feff_path, $suffix) = fileparse($file);
  $current_data_dir = $feff_path;
  track({file=>$file, mode=>"reading from", command=>sub{my $size = -s $file; print "size : $size\n"}}) if $debug_file_path;

  my $data = $paths{$current}->data;
  ## assign an id to this feff calc
  my $id = $data . '.feff' . $n_feff;

  ## import this feff calc into the project by copying all files
  ## &initialize_project(0);
  my $project_feff_dir = &initialize_feff($id);
  ## copy all these feff files to the project feff folder
  opendir F, $feff_path;
  my @list = grep { (-f File::Spec->catfile($feff_path,$_)) and
		    (lc($_) =~ /\.(bin|dat|inp|log|run)$/) } readdir F;
  closedir F;
  map { copy(File::Spec->catfile($feff_path,$_), $project_feff_dir) } @list;

  ## make sure that the feff.inp file is "feff.inp"
  copy($file, File::Spec->catfile($project_feff_dir, 'feff.inp'));

  my $exists = '';
  my @nnnnlist;
  ## windows has an intensely stoopid setting where file extensions
  ## are not displayed in the file selection widget.  in that case it
  ## is difficult to distinguish between feff.inp and feff.bin (a
  ## feff8 file option).  this next line does something reasonable
  ## when feff.bin is selected.
  $name =~ s/\.bin$/\.inp/;

  if (lc($name) =~ /inp$/) {
    ## artemis wants the feff input file to be called feff.inp,
    ## regardless of what filename the user clicked on
    copy($file, File::Spec->catfile($project_feff_dir, 'feff.inp'));
    ## don't push to the MRU if this feff.inp comes from the tmp directory
    my $tmpdir = File::Spec->catfile($project_folder, "tmp");
    my $thisdir = dirname($file);
    push_mru($file, 1, 'feff') unless same_directory($tmpdir, $thisdir);
  } else {
    ## this is a feffNNNN.dat file, not a feff.inp file, figure out
    ## which feff calc it's a part of
    push @nnnnlist, $name;
    foreach my $k (keys %paths) {
      next unless (ref($paths{$k}) =~ /Ifeffit/);
      next unless ($paths{$k}->type eq 'feff');
      next unless same_directory($paths{$k}->{path}, $feff_path);
      $exists = $k;
      $id = $paths{$k}->get('id');
      last;
    };
  };

  unless ($exists) {
    ## instantiate a new object
    $paths{$id} = Ifeffit::Path -> new(id     => $id,
				       type   => 'feff',
				       path   => $project_feff_dir,
				       data   => $data,
				       lab    => 'FEFF'.$n_feff,
				       mode   => 2,
				       family => \%paths,
				       atoms_atoms => []);
    my @autoparams;
    $#autoparams = 6;
    (@autoparams = autoparams_define($id, $n_feff, 0, 0)) if $config{autoparams}{do_autoparams};
    $paths{$id} -> make(autoparams=>[@autoparams]);

    if (lc($name) =~ /inp$/) {

      opendir D, $project_feff_dir or die "cannot read directory $project_feff_dir\n";
      @nnnnlist = sort grep /feff\d{4}\.dat/i, readdir D;
      closedir D;
      if (@nnnnlist) {
	my $response;
	if ($nopaths) {
	  $response = "No paths";
	} else {
	  my $dialog =
	    $top -> Dialog(-bitmap         => 'questhead',
			   -text           => "How many feff paths do you want to import right now.",
			   -title          => 'Artemis: Question...',
			   -buttons        => ['No paths',
					       'Just the first',
					       "The first $config{paths}{firstn}",
					       'All paths'],
			   -default_button => 'All paths',
			   -font           => $config{fonts}{med},
			   -popover        => 'cursor');
	  &posted_Dialog;
	  $response = $dialog->Show();
	};
	$paths{$id} -> make("feff.inp" => File::Spec->catfile($project_feff_dir, $name));
	## fetch list of feffNNNN.dat files
	Echo("Importing " . lc($response));
	($#nnnnlist = -1) if ($response eq 'No paths');
	($#nnnnlist = 0)  if ($response eq 'Just the first');
	($#nnnnlist = $config{paths}{firstn}-1) if (($response =~ /^The first/) and
						    ($#nnnnlist > $config{paths}{firstn}-1));
      } else {
	## this is the situation of importing a feff.inp that has not
	## been run to produce the feffNNNN.dat files
	$exists = 1;
	## setting this variable flags the incrementing of $n_feff 7
	## lines below and precludes a few other actions later in this
	## sub
      };
    };
    $list -> add($id, -text=>'FEFF'.$n_feff, -style=>$list_styles{noplot});
    $list -> setmode($id, 'close');
    $list -> setmode($paths{$data}->get('id'), 'close')
      if ($list -> getmode($paths{$data}->get('id')) eq 'none');
    ++$n_feff if $exists;
  };

  ## do intrp
  unless ($exists) {
    my $intrp_ok = &do_intrp($id);
    $paths{$id} -> make(mode=>$paths{$id}->get('mode')+4);
  };


  $list->selectionClear;
  if ($exists and ($exists =~ /^1$/)) {
    display_page($id);
  } elsif ($exists) {
    display_page($exists);
  } else {
    display_page($id);
  };
  $exists or ++$n_feff;
  $file_menu -> menu -> entryconfigure($save_index+6, -state=>'normal');
  $file_menu -> menu -> entryconfigure($save_index+4, -state=>($Tk::VERSION > 804) ? 'normal' : 'disabled'); # all paths

  my $i = 0;
  foreach my $f (sort {lc($a) cmp lc($b)} (@nnnnlist)) {
    #my $kid = $list -> addchild($id);
    (!$i) or ($i % 10) or Echo("Reading the ${i}th feffNNNN.dat file");
    #fetch_nnnn($project_feff_dir, $f, join('.', $id, $i), $f);
    my $kid = fetch_nnnn($id, $project_feff_dir, $f);
    $exists = $kid if $exists;
    $list -> entryconfigure($kid,
			    -style => $list_styles{$paths{$kid}->pathstate("enabled")},
			    -text  => $paths{$kid}->get('lab'));
    ++$i;
  };


  ## set display and increment feff counter
  &set_fit_button('fit');

  ## save an autosave file...
  &save_project(0,1);

  project_state(0);
  return $id;
};


sub save_all_paths {
  my $space = $_[0];
  my $suff;
 SW: {
    $suff = '.chi', last SW if (lc($space) eq 'k');
    $suff = '.rsp', last SW if (lc($space) eq 'r');
    $suff = '.qsp', last SW if (lc($space) eq 'q');
  };
  my $dir = $top -> chooseDirectory(-initialdir	=> $current_data_dir,
				    -title	=> "Artemis: Select a directory",
				    #-mustexist	=> 1,
				   );
  Error("Saving all paths -- aborted.  You did not select a directory."), return 0 unless $dir;
  $current_data_dir = $dir;
  Echo("Saving all included paths to files ...");
  $top -> Busy;
  ## refresh the variables and title glob  before writing out the paths
  my $command = "\n## saving all included paths to files\n";
  ##$command .= &erase_all_variables;
  ##&read_gds2(1);		# update gsd object
  if ($parameters_changed) {
    map { $command .= $_ -> write_gsd } (@gds);
    $parameters_changed = 0;
  };
  my $titles = $widgets{op_titles}->get(qw(1.0 end));
  my $n = 3;
  foreach my $t (split(/\n/,$titles)) {
    next if ($t =~ /^\s*$/);
    $command .= "\$artemis_title$n = \"$t\"\n";
    ++$n;
  };
  $paths{$current} -> dispose($command, $dmode);

  my $this_data = $paths{$current}->data;
  my $kw = $plot_features{kweight};
  ($kw = $paths{$this_data}->default_k_weight) if ($kw eq 'kw');

  foreach my $k (&path_list) {
    next unless ($k =~ /feff\d+\.(\d+)/);
    next unless $paths{$k}->get('include');

    my $command = "";
    my $group = Ifeffit::Path::pathgroup($k, \%paths);

    my $ii = $paths{$k}->index;
    ## my $parent = $paths{$k}->get('parent');
    my $pathto = $paths{$k}->get('path');
    $command .= $paths{$k} -> write_path($ii, $pathto, $config{paths}{extpp}, $stash_dir);
    $command .= "ff2chi($ii, group=$group)\n";

    $command .= "\$artemis_title1 = \"Artemis output file, path -- Artemis version $VERSION\"\n";
    $command .= "\$artemis_title2 = \"Path data from " . $paths{$k}->descriptor() . "\"\n";
    $command .= "\$artemis_title$n = \"artemis: $group in $space space\"\n";

    my $data = $paths{$k}->data;
    my $name = $paths{$k}->descriptor();
    $name =~ s/[.:@&\/\\ ]/_/g;
    my $file = File::Spec->catfile($current_data_dir, $name.$suff);
  SWITCH: {
      (lc($space) eq 'k') and do {
	$command .= "write_data(file=$file,\n" .
	  wrap("           ", "           ", "\$artemis_title*, $group.k, $group.chi)");
	last SWITCH;
      };
      (lc($space) eq 'r') and do {
	#($paths{$k}->get('do_r')) and
	$command .= $paths{$k} -> write_fft($kw, $config{data}{rmax_out});
	$command .= "write_data(file=$file,\n" .
	  wrap("           ", "           ",
	       "\$artemis_title*, $group.r, $group.chir_re, " .
	       "$group.chir_im, $group.chir_mag, $group.chir_pha)");
	last SWITCH;
      };
      (lc($space) eq 'q') and do {
	#($paths{$k}->get('do_r')) and
	#($paths{$k}->get('do_q')) and
	$command .= $paths{$k} -> write_fft($kw, $config{data}{rmax_out});
	$command .= $paths{$k} -> write_bft();
	$command .= "write_data(file=$file,\n" .
	  wrap("           ", "           ",
	       "\$artemis_title*, $group.q, $group.chiq_re, " .
	       "$group.chiq_im, $group.chiq_mag, $group.chiq_pha)");
	last SWITCH;
      };
    }; # end of SWITCH
    $paths{$k} -> dispose($command, $dmode);
  }; # end of loop over paths
  $top -> Unbusy;
  Echo("Saved all paths in $space space to $current_data_dir");
};

## check to see if fit and bkg exist...
sub save_data {
  my ($which, $space, $dont_ask) = @_;
  Echo("Want to save $which in $space space");
  my $command = "";
  ## get the correct group name
  my ($group, $lab);
  my $save = $current;
  if (($which eq 'path') and ($current_canvas ne 'path')) {
    Error("A path is not currently displayed.");
    return;
  };
  if ($which eq 'path') {	# prep a path for writing
    ## what about multiple feff calcs and indeces
    $group = Ifeffit::Path::pathgroup($current, \%paths);
    if ($current =~ /feff\d\.(\d+)/) {
      my $ii = $paths{$current}->index;
      my $pathto = $paths{$current}->get('path');
      ##$command .= &erase_all_variables;
      ##&read_gds2(1);			# update gsd object
      if ($parameters_changed) {
	map { $command .= $_ -> write_gsd } (@gds);
	$parameters_changed = 0;
      };
      $command .= $paths{$current} -> write_path($ii, $pathto, $config{paths}{extpp}, $stash_dir);
      $command .= "ff2chi($ii, group=$group)\n";
    };
  } else {			# prep data/fit/background for writing
    ## need to determine the data that corresponds to this feff|path|fit|bkg|res|diff
    $group = $paths{$current}->data;
    $lab   = $paths{$group}->get('lab');
    $lab   = (split(/\./, $lab))[0];
    $save  = $group;
    ($which eq 'fit')  and (($group, $lab, $save) =
			    ($group."_fit",  $lab."_fit",  $group.".0"));
    ##     ($which eq 'bkg')  and (($group, $lab, $save) =
    ## 			    ($group."_bkg",  $lab."_bkg",  $group.".2"));
    ##     ($which eq 'res')  and (($group, $lab, $save) =
    ## 			    ($group."_res",  $lab."_res",  $group.".1"));
  };

  ## get the output filename
  my $file;
  my $path = $current_data_dir || cwd;
  my ($desc, $suff);
 SW: {
    ($desc, $suff) = ('chi(k) files', '.chi'), last SW if (lc($space) eq 'k');
    ($desc, $suff) = ('chi(R) files', '.rsp'), last SW if (lc($space) eq 'r');
    ($desc, $suff) = ('chi(q) files', '.qsp'), last SW if (lc($space) eq 'q');
  };
  my $types = [[$desc, $suff], ['All Files', '*'],];
  my $init;
  if ($paths{$current}->type eq 'path'){
    my $name = $paths{$current}->descriptor();
    $name =~ s/[.:@&\/\\ ]/_/g;
    $init = $name.$suff;
  } else {
    $init = $group.$suff;
    ($init = $lab.$suff) if $lab;
  };
  ($init =~ s/[\\:\/\*\?\'<>\|]/_/g);# if ($is_windows);
  $file = $top -> getSaveFile(-filetypes=>$types,
			      ##(not $is_windows) ?
			      ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
			      -initialfile=>$init,
			      -initialdir=>$path,
			      -title => "Artemis: Save data");
  return unless ($file);
  ## make sure I can write to $file
  open F, ">".$file or do {
    Error("You cannot write to \"$file\".  Check the permissions of that file."); return
  };
  close F;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  ## make the titles glob
  my $titles = $widgets{op_titles}->get(qw(1.0 end));
  $command .= "\$artemis_title1 = \"Artemis output file, data -- Artemis version $VERSION\"\n";
  my $n = 2;
  if ($which eq 'path') {
    $command .= "\$artemis_title$n = \"Path data from " . $paths{$current}->get('lab') . "\"\n";
    ++$n;
  };
  foreach my $l (split(/\n/, $paths{$current}->param_summary($plot_features{kweight}))) {
    $command .= "\$artemis_title$n = \"$l\"\n";
    ++$n;
  };

  foreach my $t (split(/\n/,$titles)) {
    next if ($t =~ /^\s*$/);
    $command .= "\$artemis_title$n = \"$t\"\n";
    ++$n;
  };
  $command .= "\$artemis_title$n = \"artemis: <".$paths{$save}->descriptor."> in $space space\"\n";


  ## build the write_data command
  my $kw = $plot_features{kweight};
  ($kw = $paths{$save}->default_k_weight) if ($kw eq 'kw');
 SWITCH: {
    (lc($space) eq 'k') and do {
      my $suff = "chi";
      ($paths{$save}->get('do_r')) and  do {
	my $data = $paths{$current}->data;
	my $kw = ($plot_features{kweight} eq 'kw') ? $paths{$data}->default_k_weight() : $plot_features{kweight};
	my $this = "$group.chi, k=$group.k, kweight=$kw, kmin=" . $paths{$data}->get('kmin') .
	    ", kmax=" . $paths{$data}->get('kmax') .
	      ", dk=" . $paths{$data}->get('dk') .
		", rmax_out=" . $config{data}{rmax_out} .
		  ", kwindow=" . $paths{$data}->get('kwindow') . ")";
	$command .= wrap('fftf(', '     ', $this) . "\n";
	$paths{$save} -> make(do_r=>0);
      };
      $command .= "write_data(file=$file,\n" .
	wrap("           ", "           ", "\$artemis_title*, $group.k, $group.$suff, $group.win)");
      last SWITCH;
    };
    (lc($space) eq 'r') and do {
      #($paths{$current}->get('do_r')) and (
      $command .= $paths{$save} -> write_fft($kw, $config{data}{rmax_out});
      $command .= $paths{$save} -> write_bft();
      $paths{$save} -> dispose("___x = ceil($group.chir_mag)", 1); # scale window to plot
      my $scale = $plot_features{window_multiplier} * Ifeffit::get_scalar("___x");
      $command .= "set $group.winout = $scale * $group.rwin\n";
      $command .= "write_data(file=$file,\n" .
	wrap("           ", "           ",
	     "\$artemis_title*, $group.r, $group.chir_re, " .
	     "$group.chir_im, $group.chir_mag, $group.chir_pha, $group.winout)");
      last SWITCH;
    };
    (lc($space) eq 'q') and do {
      $command .= $paths{$save} -> write_fft($kw, $config{data}{rmax_out});
      $command .= $paths{$save} -> write_bft();
      $command .= "write_data(file=$file,\n" .
	wrap("           ", "           ",
	     "\$artemis_title*, $group.q, $group.chiq_re, " .
	     "$group.chiq_im, $group.chiq_mag, $group.chiq_pha)");
      last SWITCH;
    };
  };
  $paths{$current} -> dispose($command, $dmode);
  Echo("Saved $which in $space space to $file");
};


sub save_selected {
  my $m = 0;
  foreach my $p ($list->info('selection')) {
    #my $pp = $p;
    #($pp = $1 . "_" . ("fit", "res", "bkg")[$2]) if ($p =~ /(data\d)\.(\d)/);
    next if ($paths{$p}->type =~ /(feff|gsd)/);
    ++$m
  };
  Error("Saving file aborted.  No plottable items are selected."), return 1 unless ($m);
  Error("You cannot save more than $limits{output_columns} groups to a single file.  Sorry."), return if ($m>$limits{output_columns});
  my $sp = $_[0];

  $top->Busy;

  my ($x, $y, $mess) = ('','','');
 SWITCH: {
    ($x, $y, $mess)=('k','chi', "chi(k)"),                           last SWITCH if ($sp eq 'k');
    ($x, $y, $mess)=('k','chi', "k weighted chi(k)"),                last SWITCH if ($sp eq 'k1');
    ($x, $y, $mess)=('k','chi', "k^2 weighted chi(k)"),              last SWITCH if ($sp eq 'k2');
    ($x, $y, $mess)=('k','chi', "k^3 weighted chi(k)"),              last SWITCH if ($sp eq 'k3');
    ($x, $y, $mess)=('r','chir_mag', "the magnitude of chi(R)"),     last SWITCH if ($sp eq 'rm');
    ($x, $y, $mess)=('r','chir_re', "the real part of chi(R)"),      last SWITCH if ($sp eq 'rr');
    ($x, $y, $mess)=('r','chir_im', "the imaginary part of chi(R)"), last SWITCH if ($sp eq 'ri');
    ($x, $y, $mess)=('q','chiq_mag', "the magnitude of chi(q)"),     last SWITCH if ($sp eq 'qm');
    ($x, $y, $mess)=('q','chiq_re', "the real part of chi(q)"),      last SWITCH if ($sp eq 'qr');
    ($x, $y, $mess)=('q','chiq_im', "the imaginary part of chi(q)"), last SWITCH if ($sp eq 'qi');
  };
  my $types = [['All Files', '*'],['Data Files', '*.dat']];
  my $path = $current_data_dir || Cwd::cwd;
  my $yy = $y;
  ($yy = "chi".$1) if ($sp =~ /k(\d)/);
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>"selected.".$yy,
				 -title => "Artemis: Save selected data");
  $top->Unbusy, return unless $file;
  ## make sure I can write to $file
  open F, ">".$file or do { Error("You cannot write to \"$file\".  Check the permissions of that file.");
			    $top -> Unbusy;
			    return };
  close F;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  Echo("Saving $mess for the selected data ...");

  $paths{$current} -> dispose("\n## saving selected data as columns in a file", $dmode);
  my @list = $list->info('selection');
  my $command = "file=$file, \$selected_title_\*, " . $paths{$list[0]}->get('group') . ".$x";
  my $precmd  = "";
  if ($parameters_changed) {
    map { $precmd .= $_ -> write_gsd(1) } (@gds);
    $parameters_changed = 0;
  };
  $paths{$current}->dispose("\$selected_title_1 = \"Artemis output file, selected -- Artemis version $VERSION\"", $dmode);
  $paths{$current}->dispose("\$selected_title_2 = \"This file contains $mess from:\"", $dmode);
  my $erase = "erase \$selected_title_1\nerase \$selected_title_2\n";
  my $ncol = 0;
  my $stan;
  my $kw = $plot_features{kweight};
  my $this_data = $paths{$current}->data;
  ($kw = $paths{$this_data}->default_k_weight) if ($kw eq 'kw');
  my @column_labels = ($x);
  foreach my $g (@list) {
    ##($g = $1 . "_" . ("fit", "res", "bkg")[$2]) if $g =~ /(data\d)\.(\d)/;
    next if ($paths{$g}->type =~ /(feff|gsd)/);
    my $group;
    my $this_label = $paths{$g}->descriptor();
    push @column_labels, $this_label; # use DPL labels as column labels
    if ($paths{$g}->type eq 'path') {
      my $ind    = $paths{$g} -> index;
      my $pathto = $paths{$g}->get('path');
      $precmd .= $paths{$g} -> write_path($ind, $pathto, $config{paths}{extpp}, $stash_dir);
      $group = Ifeffit::Path::pathgroup($g, \%paths);
      next unless $group;
      $precmd .= "ff2chi($ind, group=$group)\n";
    } elsif (($paths{$g}->{type} eq 'fit') and $paths{$g}->{parent}) {
      ## this is a fit, but not the parent of the fit branch
      unless ($paths{$g}->get('imported')) {
	## read this fit into its group if it has not already been imported
	$precmd .= "read_data(file=\"" .
	  $paths{$g}->get('fitfile') .
	    "\",\n" .
	      "          type=chi, group=". $paths{$g}->get('group') . ")\n";
	$paths{$g}->make(imported=>1);
      };
##       ## bkg plot has been requested
##       if (($do_bkg) and (-e $paths{$g}->get('bkgfile'))) {
## 	unless ($paths{$g}->get('imported_bkg')) {
## 	  (my $gr = $paths{$g}->get('group')) =~ s/fit/bkg/;
## 	  ## read this fit into its group if it has not already been imported
## 	  $precmd .= "read_data(file=\"" .
## 	    $paths{$g}->get('bkgfile') .
## 	      "\",\n          type=chi, group=$gr)\n";
## 	  $paths{$g}->make(imported_bkg=>1);
## 	};
##       };
##       ## residual plot has been requested
##       if ($do_res) {
## 	unless ($paths{$g}->get('imported_res')) {
## 	  (my $gr = $paths{$g}->get('group')) =~ s/fit/res/;
## 	  ## read this fit into its group if it has not already been imported
## 	  $precmd .= "read_data(file=\"" .
## 	    $paths{$g}->get('resfile') .
## 	      "\",\n          type=chi, group=$gr)\n";
## 	  $paths{$g}->make(imported_res=>1);
## 	};
##       };
    };


    if ($sp =~ /^r/) {
      $precmd .= $paths{$g} -> write_fft($kw, $config{data}{rmax_out});
    } elsif ($sp =~ /^q/) {
      $precmd .= $paths{$g} -> write_fft($kw, $config{data}{rmax_out});
      $precmd .= $paths{$g} -> write_bft();
    };
    my $grp = ($paths{$g}->type eq 'path') ? $group : $paths{$g}->get('group');
    if ($sp =~ /k(\d)/) {
      $precmd  .= "$grp.chi$1 = $grp.$x^$1 * $grp.$y\n";
      $command .= ", $grp.chi$1";
      $erase   .= "erase $grp.chi$1\n";
    } else {
      $command .= ", $grp.$y";
    };
    ++$ncol;
    my $ntit = $ncol+2;
    $paths{$g}->dispose("\$selected_title_$ntit = \"".$paths{$g}->descriptor()." (column " . eval("$ncol+1") . ")\"", $dmode);
    $erase .= "erase \$selected_title_$ntit\n"
  };
  $Text::Wrap::huge = 'overflow';
  ## remove blanks from column labels
  @column_labels = map { $_ =~ s/\s+/_/g; $_ } @column_labels;
  my $label = join(" ", @column_labels);
  $command = wrap("write_data(", "           ", $command);
  $command .= ",\n           label=\"$label\")";
  $paths{$current} -> dispose($precmd,  $dmode);
  $paths{$current} -> dispose($command, $dmode);
  $paths{$current} -> dispose($erase,   $dmode); # clean up the mess
  Echo("Saved $mess for the selected data to \`$file\'");
  $top->Unbusy;
};


sub save_full_data {
  my $data = $paths{$current}->data;
  my ($space, $part);
 SWITCH: {
    ($space, $part) = ('k', 'chi'),      last SWITCH if ($_[0] eq 'k');
    ($space, $part) = ('r', 'chir_mag'), last SWITCH if ($_[0] eq 'r_mag');
    ($space, $part) = ('r', 'chir_re'),  last SWITCH if ($_[0] eq 'r_re');
    ($space, $part) = ('r', 'chir_im'),  last SWITCH if ($_[0] eq 'r_im');
    ($space, $part) = ('q', 'chiq_mag'), last SWITCH if ($_[0] eq 'q_mag');
    ($space, $part) = ('q', 'chiq_re'),  last SWITCH if ($_[0] eq 'q_re');
    ($space, $part) = ('q', 'chiq_im'),  last SWITCH if ($_[0] eq 'q_im');
  };

  my $lab = $paths{$data}->descriptor;
  my $label = "$space ";
  my $kw = $plot_features{kweight};
  ($kw = $paths{$data}->default_k_weight) if ($kw eq 'kw');
  my $which = (($paths{$current}->type eq 'fit') and $paths{$current}->get('parent')) ?
    $current :
      $paths{$data.".0"}->get('thisfit');

  my $types = [['All Files', '*'],['Data Files', '*.dat']];
  my $path = $current_data_dir || Cwd::cwd;
  (my $init = $paths{$which}->descriptor) =~ s/[.:@&\/\\ ]+/_/g;
  $init .= "_full.$part";
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$init,
				 -title => "Artemis: Save full data and fit");
  ## make sure I can write to $file
  open F, ">".$file or do { Error("You cannot write to \"$file\".  Check the permissions of that file.");
			    $top -> Unbusy;
			    return };
  close F;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  Echo("Saving full data and fit for ". $paths{$which}->descriptor . " ...");
  $top->Busy;

  my ($command, $precmd)  = ("", "");
  my $n = 3;
  $paths{$data}->dispose("\$full_title_1 = \"Artemis output file, full data -- Artemis version $VERSION\"", $dmode);
  $paths{$data}->dispose("\$full_title_2 = \"This file contains the full data from from $lab\"", $dmode);
  my $erase = "erase \$full_title_1\nerase \$full_title_2\n";
  my $header_file = $paths{$which}->get('fitfile');
  $header_file =~ s/(data\d+)\.fit$/header.$1/;
  open H, $header_file;
  foreach (<H>) {
    chomp;
    my $l = substr($_, 2);
    $precmd .= "\$full_title_$n = \"$l\"\n";
    $erase .= "erase \$full_title_$n\n";
    ++$n;
  };
  close H;

##   foreach my $l (split(/\n/, $paths{$data}->param_summary($kw))) {
##     $precmd .= "\$full_title_$n = \"$l\"\n";
##     ++$n;
##     $erase .= "erase \$full_title_1\n";
##   };
  (my $nospaces = $lab) =~ s/[.:@&\/\\ ]+/_/g;
  $label .= "$nospaces ";
  ##   foreach my $t (split(/\n/,$titles)) {
  ##     next if ($t =~ /^\s*$/);
  ##     $command .= "\$artemis_title$n = \"$t\"\n";
  ##     ++$n;
  ##   };

  ## take care to do the FTs uising the parameters of the fit and not
  ## of the data!  this is easiest done by doing write_fft and
  ## write_bft on the chosen fit and substituting in the correct
  ## ifeffit group name

  my $group = $paths{$which}->get('group');
  my $data_group = $paths{$data}->get('group');
  my $fft_command = $paths{$which} -> write_fft($kw, $config{data}{rmax_out});
  my $bft_command = $paths{$which} -> write_bft();

  ## --- data
  $command .= "\$full_title_\*, " . $paths{$data}->get('group') . ".$space, " .
    $paths{$data}->get('group') . ".$part, ";
  if ($space =~ /^k/) {
    (my $this_fft = $fft_command) =~ s/$group/$data_group/g;
    $precmd .= $this_fft;
    ##$precmd .= $paths{$data} -> write_fft($kw, $config{data}{rmax_out});
  } elsif ($space =~ /^[rq]/) {
    (my $this_fft = $fft_command) =~ s/$group/$data_group/g;
    $precmd .= $this_fft;
    (my $this_bft = $bft_command) =~ s/$group/$data_group/g;
    $precmd .= $this_bft;
    ##$precmd .= $paths{$data} -> write_bft();
  };

  ## --- fit
  unless ($paths{$which}->get('imported')) {
    $precmd .= "read_data(file=\"" .
      $paths{$which}->get('fitfile') . "\",\n" . "          type=chi, group=$group)\n";
    $paths{$which}->make(imported=>1);
  };
  if ($space =~ /^r/) {
    $precmd .= $fft_command;
  } elsif ($space =~ /^q/) {
    $precmd .= $fft_command;
    $precmd .= $bft_command;
  };
  $command .=  "$group.$part, ";
  $label .= "fit ";

  ## --- background
  if (-e $paths{$which}->get('bkgfile')) {
    (my $gr = $paths{$which}->get('group')) =~ s/fit/bkg/;
    unless ($paths{$which}->get('imported_bkg')) {
      ## read this fit into its group if it has not already been imported
      $precmd .= "read_data(file=\"" .
	$paths{$which}->get('bkgfile') .
	  "\",\n          type=chi, group=$gr)\n";
      $paths{$which}->make(imported_bkg=>1);
    };
    if ($space =~ /^r/) {
      (my $this_fft = $fft_command) =~ s/$group/$gr/g;
      $precmd .= $this_fft;
    } elsif ($space =~ /^q/) {
      (my $this_fft = $fft_command) =~ s/$group/$gr/g;
      $precmd .= $this_fft;
      (my $this_bft = $bft_command) =~ s/$group/$gr/g;
      $precmd .= $this_bft;
    };
    $command .=  "$gr.$part, ";
    $label .= "background ";
  };

  ## --- residual
  (my $gr = $paths{$which}->get('group')) =~ s/fit/res/;
  unless ($paths{$which}->get('imported_res')) {
    ## read this fit into its group if it has not already been imported
    $precmd .= "read_data(file=\"" .
      $paths{$which}->get('resfile') .
	"\",\n          type=chi, group=$gr)\n";
    $paths{$which}->make(imported_res=>1);
  };
  if ($space =~ /^r/) {
    (my $this_fft = $fft_command) =~ s/$group/$gr/g;
    $precmd .= $this_fft;
  } elsif ($space =~ /^q/) {
    (my $this_fft = $fft_command) =~ s/$group/$gr/g;
    $precmd .= $this_fft;
    (my $this_bft = $bft_command) =~ s/$group/$gr/g;
    $precmd .= $this_bft;
  };
  $command .=  "$gr.$part, ";
  $label .= "residual ";

  ## --- window
  $group = $paths{$data}->get('group');
  if ($space =~ /^r/) {
    $paths{$data} -> dispose("___x = ceil($group.chir_mag)", 1); # scale window to plot
    my $scale = $plot_features{window_multiplier} * Ifeffit::get_scalar("___x");
    $precmd .= "set $group.winout = $scale * $group.rwin\n";
  } else {
    $paths{$data} -> dispose("___x = ceil($group.chi)", 1); # scale window to plot
    my $scale = $plot_features{window_multiplier} * Ifeffit::get_scalar("___x");
    $precmd .= "set $group.winout = $scale * $group.win\n";
  };
  $command .=  "$group.winout, ";
  $label .= "window";


  $command = "write_data(file=$file,\n" . wrap("           ", "           ", $command);
  $command .= "\n           label=\"$label\")";
  $paths{$which} -> dispose($precmd,  $dmode);
  $paths{$which} -> dispose($command, $dmode);
  $paths{$which} -> dispose($erase,   $dmode); # clean up the mess
  Echo("Saving full data and fit for ". $paths{$which}->descriptor . " ... done!");
  $top->Unbusy;

};

sub save_bkgsub_data {
  my $data  = $paths{$current}->data;
  my $label = $paths{$current}->get("lab");
  my $types = [['chi Files', '*.chi'],
	       ['All Files', '*'],];
  my $path = File::Spec->catfile($project_folder, "chi_data", "");
  my $fname = basename($paths{$data}->get('file'));
  my @list = split(/\./, $fname);
  $fname = $list[0] . "_bkgsub." . $list[1];
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$fname,
				 -title => "Artemis: Save background subtracted data");
  return unless $file;

  my $group = $paths{$data}->get('group');
  my $command = "\$artemis_title1 = \"Artemis output file, bkgsub -- Artemis version $VERSION\"\n";
  my $titles = $widgets{op_titles}->get(qw(1.0 end));
  my $n = 2;
  foreach my $t (split(/\n/,$titles)) {
    next if ($t =~ /^\s*$/);
    $command .= "\$artemis_title$n = \"$t\"\n";
    ++$n;
  };
  $command .= "\$artemis_title$n = \"artemis: " . $paths{$data}->get('lab') . " as background subtracted chi(k)\"\n";

  ## make and write bkgsub data
  if ($config{data}{bkgsub_window}) {
    $command .= "## note: weighting spline by window in background subtraction!!\n";
    $command .= "set $group.chib = $group.chi - (${group}_bkg.chi*$group.win)\n";
  } else {
    $command .= "set $group.chib = $group.chi - ${group}_bkg.chi\n";
  };
  $command .= "write_data(file=$file,\n" .
    wrap("           ", "           ", "\$artemis_title*, $group.k, $group.chib)");

  $paths{$data} -> dispose($command, $dmode);
  project_state(0);

  ## offer to reload the bkg sub data
  my $dialog =
    $top -> Dialog(-bitmap         => 'questhead',
		   -text           => "Would you like to replace the current data set with the background subtracted data?",
		   -title          => 'Athena: Replace data?',
		   -buttons        => [qw/Yes No/],
		   -default_button => 'Yes',
		   -font           => $config{fonts}{med},
		   -popover        => 'cursor');
  &posted_Dialog;
  if ($dialog->Show() eq 'Yes') {
    ##my $cdd_save = $current_data_dir;
    &read_data($paths{$current}->data, $file, 1);
    $paths{$current} -> make(lab=>"bkgsub " . $label);
    $list -> entryconfigure($paths{$current}->get('id'), -text=>$paths{$current}->get("lab"));

    ##$current_data_dir = $cdd_save;
    $paths{$data} -> make(do_bkg=>'no');
    $temp{op_do_bkg} = 'no';
    $plot_features{bkg} = 0;
  };
  Echo("Saved background subtracted data to $file");

};

sub bulk_data {
  ## get a list of files from some directory to transfer
  my $path = $current_data_dir || Cwd::cwd;
  my $FSel  = $top->FileSelect(-title => 'Artemis: transfer MANY data files to the project data folder',
			       -width => 40,
			       -directory=>$path);
  $FSel -> configure(-selectmode=>'extended');
  my @data = $FSel->Show;
  Echo("Data transfer was aborted."), return unless (defined $data[0] and -f $data[0]);
  ## transfer 'em
  foreach my $d (@data) {
    my $new = File::Spec->catfile($project_folder, "chi_data", basename($d));
    my $bn  = basename($d, qw(.chi));
    my $count = 1;
    while (-e $new) {		# care not to overwrite files
      $new = File::Spec->catfile($project_folder, "chi_data", $bn."_$count.chi");
      ++$count;
    };
    copy($d, $new) unless ($d eq $new);
  };
  project_state(0);
  ## offer to read one of these newly transfered data files
  &dispatch_read_data($paths{$current}->data, "", 1);
};


sub unique_label {
  my $in = $_[0];
  my $i = 1;
  my $name = $in;
  my $there = 0;
  map {($in eq $paths{$_}->get('lab')) and $there = 1} (&every_data);
  while ($there) {
    $there = 0;
    ++$i;
    $name = join(" ", $in, $i);
    map {($name eq $paths{$_}->get('lab')) and $there = 1} (&every_data);
  };
  return $name;
};


##  END OF THE FILE I/O SUBSECTION

