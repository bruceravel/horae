# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2008 Bruce Ravel
##



###===================================================================
### project file (zip-based) subsystem
###===================================================================


sub initialize_project {
  my $do_search = $_[0];
  ## need to make name unique in case of multiple instances of Artemis.
  ## the project_folder global variable should suffice to disambiguate
  ## the multiple instances.
  my $instance = 0;
  my $project_dir = File::Spec->catfile($stash_dir, "artemis.project.$instance", "");
  unless (same_directory($project_folder, $project_dir)) {
    while (-d $project_dir) {
      ++$instance;
      $project_dir = File::Spec->catfile($stash_dir, "artemis.project.$instance", "");
    };
    if (($instance > 3) and ($do_search)) {
      my $dialog =
	$top -> Dialog(-bitmap         => 'questhead',
		       -text           => "There seem to be a large number of abandoned project folders.  Project folders can be abandoned when Artemis exits abnormally.\n\nArtemis can clean these up at this time.\n\nYou should NOT clean these up if you have other active instances of Artemis running.",
		       -title          => 'Artemis: Question...',
		       -buttons        => ['Clean up',
					   "Don't clean up"],
		       -default_button => 'Cancel',
		       -font           => $config{fonts}{med},
		       -popover        => 'cursor');
      &posted_Dialog;
      $top -> deiconify;
      $top -> raise;
      my $response = $dialog->Show;
      if ($response eq 'Clean up') {
	Echo("Cleaning up adndoned project folders");
        opendir S, $stash_dir;
	map { rmtree(File::Spec->catfile($stash_dir, $_)) } (grep(/artemis\.project/, readdir S));
	closedir S;
	$project_dir = File::Spec->catfile($stash_dir, "artemis.project.0", "");
      };
      Echo("");
    };
    mkpath $project_dir unless (-d $project_dir);
    $project_folder = $project_dir;
  };
  ## one trailing slash of the correct variety...
  if ($is_windows) {
    ($project_folder .= "\\") unless ($project_folder =~ /\\$/);
  } else {
    ($project_folder .= "/") unless ($project_folder =~ /\/$/);
  };
  $props{'Project location'} = $project_dir;
  ## touch the marker file
  unless (-f File::Spec->catfile($project_dir, "HORAE")) {
    open A, ">".File::Spec->catfile($project_dir, "HORAE");
    #print A " \n";
    close A;
  };
  ## copy the readme file
  my $readme_file = $paths{data0} -> find('artemis', 'readme');
  copy($readme_file, File::Spec->catfile($project_dir, "README")) if (-e $readme_file);
  if ($is_windows) {
    require Win32::File;
    Win32::File::SetAttributes(File::Spec->catfile($project_dir, "README"), 0);
  };
  ## make the descriptions directory
  my $project_descr_dir = File::Spec->catfile($project_folder, "descriptions");
  mkpath $project_descr_dir unless (-d $project_descr_dir);
  ## make the data directory
  my $project_data_dir = File::Spec->catfile($project_folder, "chi_data");
  mkpath $project_data_dir unless (-d $project_data_dir);
  ## make the log files directory
  my $project_log_dir = File::Spec->catfile($project_folder, "log_files");
  mkpath $project_log_dir unless (-d $project_log_dir);
  ## make the tmp directory
  my $project_tmp_dir = File::Spec->catfile($project_folder, "tmp");
  mkpath $project_tmp_dir unless (-d $project_tmp_dir);
  ## make the fits directory
  my $project_fit_dir = File::Spec->catfile($project_folder, "fits");
  mkpath $project_fit_dir unless (-d $project_fit_dir);
  ## determine the autosave filename
  $autosave_filename = File::Spec->catfile($stash_dir, "artemis.autosave");
};

sub clean_old_trap_files {
  opendir S, $stash_dir;
  my @list = grep {/ARTEMIS/} readdir S;
  closedir S;
  map {unlink File::Spec->catfile($stash_dir, $_)} @list;
};


## make a project feff folder
sub initialize_feff {
  my $id = $_[0];
  my $project_feff_dir = File::Spec->catfile($project_folder, $id);
  mkpath $project_feff_dir unless (-d $project_feff_dir);
  return $project_feff_dir;
};


sub unpack_zip {
  Echo("Opening project zipfile $_[0] ...");
  ## check to see if it seems as though a project has started
  ##   system "ls -R /home/bruce/.horae/stash/";
  ##   opendir P, $project_folder;
  ##   my @dirs = grep {$_ !~ /^\./ and -d $_} (readdir P);
  ##   closedir P;
  ##   my $i = 0;
  ##   find( sub{ ++$i if -f; print $_, $/ }, @dirs );
  ##   print $i, $/;
  if (($paths{data0}->get('file') and (-e $paths{data0}->get('file'))) or
      (&all_feff)) {
    my $dialog =
      $top -> Dialog(-bitmap         => 'questhead',
		     -text           => "You have already started a project.  Do you want to discard the current project and replace it with this one?  Or do you want to cancel the import of this project?  (Merging projects is not currently supported.)",
		     -title          => 'Artemis: Question...',
		     -buttons        => ['Replace', 'Cancel'],
		     -default_button => 'Cancel',
		     -font           => $config{fonts}{med},
		     -popover        => 'cursor');
    &posted_Dialog;
    Echo("Aborting project file"), return 1 if ($dialog->Show() eq 'Cancel');
    Echo("");
    &delete_project;
  };

  my ($zip, $name);
  #if (ref $_[0] =~ /Archive/) {
  #  $zip = $_[0];
  #} else {
    $zip = Archive::Zip->new();
    Echo('Error reading project file $_[0]'), return 1 unless ($zip->read($_[0]) == AZ_OK);
    $name = &push_mru($_[0], 1, "project") || $_[0];
  #};
  $zip->extractTree("", $project_folder);
  undef $zip;
  Echo("Opening project zipfile $name ... done!");
  return 0;
};


sub zip_project {
  my $proj = $_[0];
  my $zip = Archive::Zip->new();
  $zip->addTree( $project_folder, "" );
  die 'error writing zip-style project' unless $zip->writeToFileNamed( $proj ) == AZ_OK;
  undef $zip;
};

sub convert_project_to_zip {

  my $stash = $_[0];
  Echo("Converting old-style project file to the zip format ... ");

  &initialize_project(0);
  ## copy the old-style project file to the description file in the
  ## stash directory
  copy($stash, File::Spec->catfile($project_folder, "descriptions", 'artemis'));


  open PROJ, $stash or die "could not open $stash as a project file\n";

  $top -> Busy();
  my $cpt = new Safe;
  #use vars qw($old_path @args @strings @journal @plot_features);
  my $from_version = 0;
  while (<PROJ>) {
    next unless (/^\@args/);
    @ {$cpt->varglob('args')} = $cpt->reval($_);
    ## this is a little fast 'n' loose, but the args array is stored in
    ## a form that can be read directly into a hash, so ...
    my %args = @ {$cpt->varglob('args')};
    ## copy the data files into the data folder
    if ($args{type} eq 'data') {
      unless ($args{file} =~ /^\s*$/) {
	unless (-f $args{file}) {
	  my $dialog =
	    $top -> Dialog(-bitmap         => 'questhead',
			   -text           => "The file $args{file} does not seem to exist.  Artemis will now prompt you for the real location of this file.",
			   -title          => 'Artemis: Problem finding a data file ...',
			   -buttons        => ['OK', 'Cancel'],
			   -default_button => 'OK',
			   -font           => $config{fonts}{med},
			   -popover        => 'cursor');
	  &posted_Dialog;
	  my $response = $dialog->Show();
	  if ($response eq 'Cancel') {
	    rmtree($project_folder);
	    $project_folder = "";
	    $top -> Unbusy();
	    Echo("Project aborted.");
	    return 0;
	  };
	  Echo("");
	  my $path = $current_data_dir || cwd;
	  my $types = [['chi(k) data',      '*.chi'],
		       ['All files',        '*'],];
	  my $file ||= $top -> getOpenFile(-filetypes=>$types,
					   ##(not $is_windows) ?
					   ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
					   -initialdir=>$path,
					   -title => "Artemis: Open a data file");
	  unless ($file) {
	    rmtree($project_folder);
	    $project_folder = "";
	    $top -> Unbusy();
	    Echo("Project aborted.");
	    return 0;
	  };
	  push_mru($file);
	  $args{file} = $file;
	};
	copy($args{file}, File::Spec->catfile($project_folder, "chi_data"));
      };
    ## copy the feff calculations into feff folders
    } elsif ($args{type} eq 'feff') {
      my $project_feff_dir = File::Spec->catfile($project_folder, $args{id});
      mkpath $project_feff_dir unless (-d $project_feff_dir);
      unless ((-d $args{path}) and (-f $args{'feff.inp'})) {
	my $dialog =
	  $top -> Dialog(-bitmap         => 'questhead',
			 -text           => "The Feff calculation which used $args{'feff.inp'} does not seem to exist.  Artemis will now prompt you for the correct directory.",
			 -title          => 'Artemis: Problem finding a data file ...',
			 -buttons        => ['OK', 'Cancel'],
			 -default_button => 'OK',
			 -font           => $config{fonts}{med},
			 -popover        => 'cursor');
	&posted_Dialog;
	my $response = $dialog->Show();
	if ($response eq 'Cancel') {
	  rmtree($project_folder);
	  $project_folder = "";
	  $top -> Unbusy();
	  Echo("Project aborted.");
	  return 0;
	};
	Echo("");
	my $dir = q{};
	if ($Tk::VERSION < 804) {
	  $top -> Dialog(-bitmap  => 'error',
			 -text    => "Selecting folders requires perl/Tk 804.  You are using perl/Tk $Tk::VERSION.  Drat!",
			 -title   => 'Artemis: Unable to change folders',
			 -buttons => ['OK'],
			 -font           => $config{fonts}{med},
			 -default_button => "OK", )
	    -> Show();
	  #$dir = $top -> DirSelect(-width=>40, -dir=>$current_data_dir,
		#		   -title=> "Artemis: Select a directory",
		#		   -text => "Select the correct path to your FEFF calculation",
		#		  ) -> Show;
	} else {
	  $dir = $top -> chooseDirectory(-initialdir => $current_data_dir,
					 -title	=> "Artemis: Select a directory",
				    #-mustexist	=> 1,
				   );
	};
	unless ($dir) {
	  rmtree($project_folder);
	  $project_folder = "";
	  $top -> Unbusy();
	  Echo("Project aborted.");
	  return 0;
	};
	$current_data_dir = $dir;
	$args{path} = $dir;
      };
      opendir FFF, $args{path};
      my @list = grep { -f File::Spec->catfile($args{path},$_) } readdir FFF;
      closedir FFF;
      map { copy(File::Spec->catfile($args{path},$_), $project_feff_dir) } @list;
    };
  };
  close PROJ;

  ## backup the old-style project file for safe keeping
  rename($stash, $stash.".oldstyle");
  ## save the project as a zip file
  my $zip = Archive::Zip->new();
  $zip->addTree( $project_folder, "" );
  die 'write error' unless $zip->writeToFileNamed( $stash ) == AZ_OK;
  undef $zip;
  ## clean up the stash folder.  this is perhaps a bit silly since it
  ## will soon be opened up again, but doing it this was will not
  ## require special code.
  rmtree($project_folder);
  $project_folder = "";
  &initialize_project(0);
  $top -> Unbusy();
  Echo("Converting old-style project file to the zip format ... done!");
  return 1;

};





## END OF THE PROJECT FILE (ZIP-BASED) SUBSYSTEM

