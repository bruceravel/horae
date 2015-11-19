# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006, 2008 Bruce Ravel
##



###===================================================================
### project description subsystem
###===================================================================

## arg 1: flag for querying user for a file name
## arg 2: autosave flag
sub save_project {
  my ($query, $auto) = @_;
  ##local $Tk::FBox::a;
  ##local $Tk::FBox::b;

  ## --- respond to an autosave event
  ##     autosave disabled
  return if ($auto and (lc($config{general}{autosave_policy}) eq 'none'));
  ##     realsave rather than autosave
  ($auto = 0) if ($auto and (lc($config{general}{autosave_policy}) eq 'realsave'));

  my $file;
  if ($auto) {
    $file = $autosave_filename;
    Echo("Performing autosave ...");
  } elsif ($query or (not $project_name)) {
    my $path = $current_data_dir || cwd;
    my ($init, $suffix) = ('artemis.apj', '');
    ($init, $path, $suffix) = fileparse($project_name) if $project_name;
    my $types = [['Artemis projects', '.apj'],
		 ['All Files', '*'],];
    $file = $top -> getSaveFile(-filetypes=>$types,
				##(not $is_windows) ?
				##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-initialfile=>$init,
				-title => "Artemis: Save project");
    return unless ($file);
    my $name = &push_mru($file, 1, "project");
    #my ($name, $pth, $suff) = fileparse($file);
    #$current_data_dir = $pth;
    $project_name = $file;	# reset deault project name
    Echo("Saving project ...");
  } else {
    $file = $project_name;
    Echo("Saving project ...");
  };

  my $dir = dirname($file);
  if (-e $dir and -w $dir) {
    Error("Cannot write to \"$file\".  Check the permissions of that file or directory."), return if (-e $file and not -w $file);
  };

  $top -> Busy;

  if (($paths{$current}->type eq 'feff') and ($paths{$current}->{mode} > 1)) {
    ## save the feff.inp file
    my $feff_file = File::Spec->catfile($project_folder, $paths{$current}->get('id'), "feff.inp");
    Echo("Saving feff.inp file");
    $widgets{feff_inptext} -> Save($feff_file);
  };

  read_titles if ($current_canvas eq 'op');

  my $description = &save_description;
  ##@-fp-@ save_fingerprint($description);

  ## save the journal
  open J, ">".File::Spec->catfile($project_folder, "descriptions", "journal.artemis");
  print J $notes{journal}->get(qw(1.0 end));
  close J;

  ## zip up project folder
  &zip_project($file);
  $top -> Unbusy;
  if ($auto) {
    Echo("Performing autosave ... done!");
  } else {
    unlink $autosave_filename, Echo("Removed stale autosave file.")
      if (-e $autosave_filename);
    Echo("Saved project to $file.");
  };
  project_state(1) unless $auto;
};

sub save_description {
  $Data::Dumper::Indent = 0;

  my $description = File::Spec->catfile($project_folder, 'descriptions', 'artemis');

  ## keep one level of backup
  ##rename($description, $description.".bak") if (-f $description);

  open PROJ, ">".$description or do {
    Error("You cannot write the artemis description file."); return
  };
  print PROJ "# Artemis project file -- Artemis version $Ifeffit::Path::VERSION\n";
  print PROJ $paths{data0} -> project_header($project_folder);

  ### loop over all data and save parameters and titles
  ##my @data = ('gsd', &every_data);
  my @data = (&every_data);
  foreach my $p (@data) {
    my @titles;
    if ($paths{$p}->type eq 'data') {
      foreach my $t (split(/\n/, $paths{$p}->get('titles'))) {
	push @titles, $t;
      };
    };
    my @args;
    foreach my $k (keys %{$paths{$p}}) {
      next if ($k eq 'titles');
      next if ($k eq 'inc_mapping');
      next if ($k eq 'included');
      next if ($k eq 'from_project');
      next if ($k eq 'autoparams');
      next if ($k eq 'family');
      next if ($k =~ 'do_[krq]');
      ## these next two prevent saving difference spectrum information
      ## to the project
      next if ($k =~ 'diff_(list|mapping|paths)');
      next if ($k =~ '(fit|made)_diff');
      push @args, $k, $paths{$p}->get($k);
    };
    print PROJ
      Data::Dumper->Dump([$p], [qw/old_path/]),    $/,
      Data::Dumper->Dump([\@args],   [qw/*args/]), $/;
    ($p =~ /^data\d+$/) and print PROJ Data::Dumper->Dump([\@titles], [qw/*strings/]), $/;
    print PROJ "[record]", $/, $/;
  };

  ##my @allkeys = (keys %paths);
  my @allkeys = &path_list;
  ## save the feff's and paths
  foreach my $path (&all_feff) {
    # my $path = "data" . $nd . ".feff" . $nf;
    next unless (exists $paths{$path});
    my @args;
    foreach my $k (keys %{$paths{$path}}) { # save the feff parent
      next if ($k eq 'titles');
      next if ($k eq 'intrp');
      next if ($k eq 'from_project');
      next if ($k eq 'family');
      push @args, $k, $paths{$path}->get($k);
    };
    print PROJ
      Data::Dumper->Dump([$path], [qw/old_path/]), $/,
      Data::Dumper->Dump([\@args], [qw/*args/]),   $/,
      "[record]", $/, $/;
    #my @paths = grep {/feff$nf\.\d+/} @allkeys;
    my @paths = grep {/$path\.\d+/} @allkeys;
    # and save all the path children of this parent
    foreach my $p (@paths) {
      my @args;
      foreach my $k (keys %{$paths{$p}}) {
	next if ($k eq 'titles');
	next if ($k eq 'header');
	next if ($k eq 'group');
	next if ($k eq 'fit_index');
	next if ($k eq 'from_project');
	next if ($k eq 'family');
	push @args, $k, $paths{$p}->get($k);
      };
      my @header;		# save headers separately
      foreach my $h (split(/\n/, $paths{$p}->get('header'))) {
	push @header, $h;
      };
      print PROJ
	Data::Dumper->Dump([$p],       [qw/old_path/]), $/,
	Data::Dumper->Dump([\@args],   [qw/*args/]),    $/,
	Data::Dumper->Dump([\@header], [qw/*strings/]),  $/,
	"[record]", $/, $/;
    };
  };

  ## save the parameter list
  foreach my $p (@gds) {
    printf PROJ ("\@parameter = ('%s','%s','%s','%s',%d);\n",
		 $p->name, $p->type, $p->mathexp, $p->note, $p->autonote);
  };
  print PROJ "\n";

  ## save the plotting options
  print PROJ Data::Dumper->Dump([\%plot_features], [qw/*plot_features/]), $/, $/;

  ## save the extra plotting features
  my @this;
  @this[0..5] = @extra[0..5];
  $this[5] = "";
  foreach (7 .. $#extra) {
    $this[$_]->[0] = $extra[$_]->[1];
    $this[$_]->[1] = $extra[$_]->[2];
  };
  print PROJ Data::Dumper->Dump([\@this], [qw/*extra/]), $/, $/;

  ##   my @journal;
  ##   foreach my $j (split(/\n/, $notes{journal}->get(qw(1.0 end)))) {
  ##     push @journal, $j;
  ##   };
  ##   print PROJ Data::Dumper->Dump([\@journal], [qw/*journal/]), $/, $/;

  ## save the properties
  print PROJ Data::Dumper->Dump([\%props], [qw/*props/]), $/, $/;

  print PROJ "\n1;\n# Local Variables:\n# truncate-lines: t\n# End:\n";
  close PROJ;
  $Data::Dumper::Indent = 2;
  return $description;

};

sub save_fingerprint {
  my $description = $_[0];
  local( $/, *P );
  open( P, $description ) or die "could not open $description for fingerprinting\n";
  my $fingerprint = md5_hex(<P>);
  close P;
  my $folder = dirname($description);
  open F, ">".File::Spec->catfile($folder, '...fp');
  print F $fingerprint;
  close F;
};

sub compare_fingerprint {
  my ($fp_file, $description) = @_;
  open( F, $fp_file ) or die "could not open $description for fp_file\n";
  my $prior = <F>;
  close F;
  open( D, $description ) or die "could not open $description for fingerprinting\n";
  my $this = md5_hex(<D>);
  close D;
  ##print "  $prior  $this\n";
  return ($prior eq $this);
};


## check to see if arg is a zip-style project
sub is_project {
  return 0;
};


## check the first line of a file to verify that it is a record
## (i.e. old-style project)
sub is_old_project {
  my $file = $_[0];
  open F, $file or die "could not open $file as an Artemis project\n";
  my $first = <F>;
  close F;
  return ($first =~ /Artemis project file/) ? 1 : 0;
};

sub is_athena_record {
  my $file = $_[0];
  open F, $file or die "could not open $file as an Athena record\n";
  my $first = <F>;
  close F;
  if ($first =~ /Athena project file/) {
    return -1;
  } elsif ($first =~ /Athena record file/) {
    return 1;
  } else {
    return 0;
  };
};




sub date_of_file {
  my $month = (qw/January February March April May June July
	          August September October November December/)[(localtime)[4]];
  my $year = 1900 + (localtime)[5];
  return sprintf "This file created at %2.2u:%2.2u:%2.2u on %s %s, %s",
    reverse((localtime)[0..2]), (localtime)[3], $month, $year;
  # ^^^ this gives hour:min:sec
};


sub open_project {
  my $file = $_[0];
  #my ($name, $pth, $suffix) = fileparse($file);
  #$current_data_dir = $pth;
  ## activate op widgets
  map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'normal')} (keys %widgets);
  map {$grab{$_}->configure(-state=>'normal')} (keys %grab);

  my $is_busy = grep (/Busy/, $top->bindtags);
  $top -> Busy unless $is_busy;
  my $from_version;
  if ($is_windows) {
    Echo("Reading project file with direct evaluations");
    $from_version = read_record_on_windows($file);
  } else {
    Echo("Reading project file in a safe compartment");
    $from_version = read_record($file)
  };
  ## set $n_feff to one larger than the largest index used in this
  ## project
  my $nn = 0;
  opendir P, $project_folder;
  foreach (readdir P) {
    next unless (/data\d+\.feff(\d)/);
    ($nn = $1) if ($1 > $nn);
  };
  closedir P;
  ++$nn;
  $n_feff = $nn;

  ## read journal into the journal space
  do {
    local $/ = undef;
    open J, File::Spec->catfile($project_folder, "descriptions", "journal.artemis");
    $notes{journal}->insert('1.0', <J>);
    close J;
  };

  ## insert sets and guesses
  repopulate_gds2();

  ## try to clean up the problem of null entries
  foreach my $p (keys %paths) {
    next if (ref($paths{$p}) =~ /Ifeffit/);
    delete $paths{$p};
    Echo("Null path $p discarded.");
  };
  foreach my $d (keys %paths) {
    next if ($paths{$d}->type =~ /(feff|gsd|path)/);
    #next unless ($paths{$d}->type =~ /(bkg|data|diff|fit|res)/);
    $paths{$d} -> make(do_k=>1);
  };
  foreach my $p (keys %paths) {	 # flag paths for updating
    next unless ($paths{$p}->type eq 'path');
    $paths{$p} -> make(do_k=>1);
  };

  unless ($from_version =~ /DR/) {
    # fix up order of paths for projects from before 0.5.002
    if (($from_version < 0.5002) or ($from_version > 2000)) {
      Echo("Fixing project file from before version 0.5.002");
      my @allkeys = (keys %paths);
      my @feffs = grep {/feff\d+$/} @allkeys;
      foreach my $f (@feffs) {
	my $n = substr($f, 4);
	my @paths = grep {/feff$n\.\d+/} @allkeys;
	@paths = sort {$paths{$a}->get('lab') cmp $paths{$b}->get('lab')} @paths;
	my @cache;
	foreach my $p (@paths) {	# remember the mapping between the old and new objects
	  push @cache, $paths{$p};
	};
	foreach my $p (@paths) {	# delete 'em all from the list
	  $list -> delete('entry', $p);
	};
	foreach my $p (@paths) {	# replace 'em all in the list and map old to new
	  my $kid = $list ->
	    addchild($f, -text=>$paths{$p}->get('lab'),
		     -style=>$list_styles{$paths{$p}->pathstate});
	  $paths{$kid} = shift @cache;
	  $paths{$kid} -> make(id=>$kid);
	};
	foreach my $p (@paths) {	# get rid of the old objects
	  delete $paths{$p};
	};
      };
      Echo("Fixing project file from before version 0.5.002 ... done!");
    };
  };

  $fefftabs -> raise("Interpretation");

  ## --- look for situation of a fits/fits0001 folder that is not a
  ##     real project fit folder from 0.7.010
  my $is_old_fits = 1;
  $is_old_fits = 0 if ($from_version =~ /DR/);
  $is_old_fits = 0 if ($from_version =~ /^0.8/);
  if ($is_old_fits and (-d File::Spec->catfile($project_folder, "fits", "fit0001"))) {
    Echo("Cleaning up fit directory from an old version of Artemis that does not support fit history.");
    rmtree(File::Spec->catfile($project_folder, "fits", "fit0001"), 0, 0);
  };

  ## --- is this project old enough not to have a tmp/ folder?
  mkdir File::Spec->catfile($project_folder, "tmp") unless (-d File::Spec->catfile($project_folder, "tmp"));

  ## --- is this project old enough not to have a readme file?
  my $readme_file = $paths{data0} -> find('artemis', 'readme');
  copy($readme_file, File::Spec->catfile($project_folder, "README"))
    if ((-e $readme_file) and (! -e File::Spec->catfile($project_folder, "README")));

  ## --- look for old fits in the fits folder
  opendir F, File::Spec->catfile($project_folder, "fits");
  my @fits = sort( grep {/fit\d+/ and -d  File::Spec->catfile($project_folder, "fits", $_)} readdir(F) );
  closedir F;

  ## restore label to the fit branch according to whether the last
  ## operation involving this data set was a fit or a sum
  if (@fits) {
    foreach my $d (&all_data) {
      my $fsfile = File::Spec->catfile($project_folder, "fits", $fits[$#fits], "$d.fs");
      my $lastfit = 'fit';
      if (-e $fsfile) {
	open FS, $fsfile;
	$lastfit = <FS>;
	$lastfit =~ s/\s$//;	# remove the carriage return if it's there
	close FS;
      };
      $list -> entryconfigure($d.".0", -text=>($lastfit =~ /fit/) ? "Fit" : "Sum");
    };
  };

  foreach my $f (@fits) {
    open L, File::Spec->catfile($project_folder, "fits", $f, 'label');
    my $label = <L>;
    $label =~ s/\s$//;	# remove the carriage return if it's there
    close L;
    $fit{count} = sprintf("%d", substr($f,3));
    $fit{count_full} ||= $fit{count};
    my $log = Ifeffit::ArtemisLog -> new(File::Spec->catfile($project_folder, "fits", $f, 'log'));

    foreach my $d (&all_data) {
      ##$list -> entryconfigure($d.".0", -text=>"Fit [$fit{count_full}]");
      my $fname = $d . ".fit";
      ## handle situation of this data not having this fit
      next unless (-e File::Spec->catfile($project_folder, "fits", $f, $fname));
      $paths{$d.'.0'} ||=  Ifeffit::Path -> new(id     => $d.".0",
						type   => 'fit',
						group  => $d.'_fit',
						sameas => $d,
						lab    => 'Fit',
						parent => 0,
						family => \%paths);
      $list -> show('entry', $d.".0");
      ##my $id = $list->addchild($d.".0");
      $list->add($d.".0.".$fit{count});
      my $id = $d.".0.".$fit{count};
      $paths{$id} = Ifeffit::Path -> new(id	  => $id,
					 type     => 'fit',
					 group    => $d.'_fit_'.$fit{count},
					 sameas   => $d,
					 lab	  => $label,
					 value    => $log->get('Figure of merit') || 0,
					 folder   => $f,
					 filename => $fname,
					 parent   => $d.".0",
					 family   => \%paths);
      $paths{$d.".0"} -> make(thisfit=>$id);
      $list -> entryconfigure($id, -style=>$list_styles{enabled}, -text=>$label);
      $paths{$id} -> make(fitfile=>File::Spec->catfile($project_folder, "fits", $f, $fname));
      my $bname = File::Spec->catfile($project_folder, "fits", $f, $d.".bkg");
      $paths{$id} -> make(bkgfile=>(-e $bname) ? $bname : "");
      $paths{$id} -> make(resfile=>File::Spec->catfile($project_folder, "fits", $f, $d.".res"));
      ## restore FT and fit parameters
      my $ftfile = File::Spec->catfile($project_folder, "fits", $f, $d.".FT");
      if (-e $ftfile) {
	open FT, $ftfile;
	foreach (<FT>) {
	  chomp;
	  my ($k, $v) = split(/=/, $_);
	  $v =~ s/\s//g;	# remove the carriage return if it's there
	  $paths{$id} -> make($k=>$v);
	};
	close FT;
      } else { # this is a project from before the FT file existed, so
               # use the corresponding data's parameters
	foreach my $k (qw(kmin kmax dk kwindow rmin rmax dr rwindow)) {
	  $paths{$id} -> make($k => $paths{$d}->get($k));
	};
      };
    };
    undef $log;
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

  ## display data
  my $first = &first_data;
  $widgets{op_titles} -> delete('1.0', 'end');
  $widgets{op_titles} -> insert('end', $paths{$first}->get('titles'));
  display_page($first);
  $file_menu->menu->entryconfigure($save_index, -state=>'normal'); # data
  $file_menu -> menu -> entryconfigure($save_index+6, -state=>'normal');
  $file_menu -> menu -> entryconfigure($save_index+4, -state=>($Tk::VERSION > 804) ? 'normal' : 'disabled'); # all paths
  (-e $paths{$first}->get('file')) and plot('r', 0);
  $top -> Unbusy unless $is_busy;
  Echo("Read project description \`$file\'.");
  project_state(1);
};




sub read_path {
  my ($r_old_path, $r_args, $r_strings) = @_;
  my $group;
  ## ...................................................................
  ## need to clean up old_path string for projects from before 0.5.009
  ## we can be confident that a project from that era is a single data
  ## set project.  all that should be necessary is appending "data0"
  ## to the old_path string.
  ($$r_old_path = 'data0.' . $$r_old_path) if ($$r_old_path =~ /^feff/);
  ## ...................................................................

  if ($$r_old_path eq 'gsd') {	# --- GSD ---
    $paths{gsd} = Ifeffit::Path -> new(id	    => 'gsd',
				       type	    => 'gsd',
				       from_project => 1,
				       family       => \%paths);
    while (@$r_args) {
      my ($k, $v) = (shift @$r_args, shift @$r_args);
      next if ($k =~ /^(id|type)$/);
      $paths{gsd} -> make($k=>$v);
    };
    foreach my $p (@{$paths{gsd}->{order}}) {
      push @gds, Ifeffit::Parameter->new(name	  => $p,
					 type	  => $paths{gsd}->{$p}->{choice},
					 mathexp  => $paths{gsd}->{$p}->{value},
					 bestfit  => '',
					 error	  => '',
					 modified => 0,
					 note	  => "$p: ");
    };
  } elsif ($$r_old_path =~ /^data\d+$/) { # --- DATA ---
    my $this = $$r_old_path;  ##'data' . $n_data++;
    $paths{$this} = Ifeffit::Path -> new(id	 => $this,
					 group	 => $this,
					 type	 => 'data',
					 sameas	 => 0,
					 from_project => 1,
					 family	 => \%paths);
    $paths{$this.".0"}  = Ifeffit::Path -> new(id	    => $this.".0",
					       type	    => 'fit',
					       from_project => 1,
					       group	    => $this."_fit",
					       sameas       => $this, lab=>'Fit',
					       parent       => 0,
					       family       => \%paths);
    my $saw_include = 0;	# deal with project files pre-0.6.000
    while (@$r_args) {
      my ($k, $v) = (shift @$r_args, shift @$r_args);
      next if ($k =~ /^(id|type|group|sameas|chib)$/); # chib is an old,
                                                       # discarded atribute
      ($saw_include = 1) if ($k eq 'include');
      if ($k eq 'kweight') {	# treat kweight specially for backwards
      SWITCH: {			# compatability for before 0.5.009
	  $paths{$this} -> make(k1=>1), last SWITCH if ($v eq 1);
	  $paths{$this} -> make(k2=>1), last SWITCH if ($v eq 2);
	  $paths{$this} -> make(k3=>1), last SWITCH if ($v eq 3);
	  $paths{$this} -> make(karb_use=>1, karb=>$v);
	};
      } else {
	$paths{$this} -> make($k=>$v);
      };
    };
    $paths{$this} -> make(pcpath=>'None') unless exists $paths{$paths{$this}->get('pcpath')};
    $paths{$this} -> make(include=>1)     unless $saw_include;
    $paths{$this} -> make(lab=>"Data")    unless $paths{$this}->get('lab');

    unless ($this eq 'data0') {
      my $style = ($paths{$this}->get('include')) ? $list_styles{enabled} : $list_styles{disabled};
      $list -> add($this, -text=>$paths{$this}->get('lab'), -style=>$style);

      $list -> add($this.".0", -text=>'Fit', -style=>$style,);
      $list -> setmode($this.'.0', 'close');
      $list -> hide('entry', $this.".0");
    };
    $list -> entryconfigure($paths{$this}->get('id'), -text=>$paths{$this}->get('lab'));
    $list -> setmode($paths{$this}->get('id'), 'close');
    $paths{$this}->make(use_bkg=>0);
    $temp{op_include} = 1;
    $temp{op_plot}    = $paths{$this}->get('plot') || 0;
    ++$n_data;
    my $group = $paths{$this}->get('group');

    if ($paths{$this}->get('file')) {
      ## fixy up path information to accommodate zip-style projects
      my $fl = $paths{$this}->get('file');
      $fl =~ s/\\+/\//g; # convert \ to /
      $paths{$this}->make(file=>$fl);
      my $thisfile = basename($paths{$this}->get('file'));
      $paths{$this} -> make(file=>File::Spec->catfile($project_folder, "chi_data", $thisfile));

      my $file = $paths{$this}->get('file');
      if (-e $file) {
	if (&is_athena_record($file) == 1) {
	  Echo("Reading $file as an Athena record");
	  if ($is_windows) {
	    read_athena_record_on_windows($file, 1, 0);
	  } else {
	    read_athena_record($file, 1, 0);
	  };
	} else {
	  $paths{$this} -> dispose("read_data(file=\"$file\", type=chi, group=$group)\n", 1);
	};
      };
    };
    # solve a problem lingering from early-version project files, this
    # problem will only exist in a single data set project file
    if (lc($paths{data0}->get('pcedge')) =~ /([a-z]{1,2}) (k|l(1|2|3|i{1,3}))/) {
      $paths{data0} -> make(pcelem=>ucfirst($1), pcedge=>ucfirst($2));
    };
    my $titles = "";
    my @all_titles = @$r_strings;
    #($#all_titles = 25) if ($#all_titles > 25);
    map {$titles .= $_."\n"} (@all_titles);
    $paths{$this} -> make(titles=>$titles);
    $fit{count_full} = $paths{$this}->get('count_full');
  } elsif ($$r_old_path =~ /^(data\d+)\.(bkg|diff|fit|res)/) {
    1; ## why is there one of these in the project??
  } elsif ($$r_old_path =~ /feff(\d+)$/) { # --- FEFF CALC ---
    my $this = $$r_old_path;
    ($n_feff < $1) and ($n_feff = $1+1); # bump up feff counter
    $paths{$this} = Ifeffit::Path -> new(id	 => $this,
					 type	 => 'feff',
					 group	 => $this,
					 from_project => 1,
					 family	 => \%paths,);
    while (@$r_args) {
      my ($k, $v) = (shift @$r_args, shift @$r_args);
      next if ($k =~ /^(id|type|group)$/);
      ## the next line addresses a change in the atoms portion of the
      ## feff calc data structure that happened when the atoms page
      ## was redesigned in DR004
      next if ($k =~ /atoms_(elem|tag|occ|x|y|z)/);
      $paths{$this} -> make($k=>$v);
    };
    ## fixy up path information to accommodate zip-style projects
    if ($paths{$this}->get('linkto')) {
      my $l = $paths{$this}->get('linkto');
      $paths{$this} -> make(path=>$paths{$l}->get('path'));
    } else {
      $paths{$this} -> make(path=>File::Spec->catfile($project_folder, $paths{$this}->get('id'), ""));
    };
    my $mode = 0;
    if (-e $paths{$this}->get('atoms.inp')) {
      $mode   += 1;
      &import_atoms($paths{$this}->get('atoms.inp'), 1, $this);
    };
    $paths{$this}->verify_feffinp;
    $mode   += 2 if (-e $paths{$this}->get('feff.inp'));
    $paths{$this} -> make(lab=>'FEFF'.$n_feff) unless ($paths{$this}->get('lab'));
    $paths{$this} -> make(include=>1)          unless (exists $paths{$this}->{include});
    my $parent = $paths{$this}->data;
    my $style = ($paths{$parent}->get('include')) ? $list_styles{noplot} : $list_styles{noplotdis};
    $list -> add($paths{$this}->get('id'), -text=>$paths{$this}->get('lab'), -style=>$style);
    my $intrp_ok = &do_intrp($this);
    $mode   += 4 if $intrp_ok;
    $paths{$this} -> make(mode=>$mode);
    $list -> setmode($paths{$this}->get('id'), 'close');
    ## does this project predate autoparams??
    unless ($paths{$this}->get('autoparams')) {
      my @autoparams;
      $#autoparams = 6;
      (@autoparams = autoparams_define($this, $n_feff, 0, 1)) if $config{autoparams}{do_autoparams};
      $paths{$this} -> make(autoparams=>[@autoparams]);
    };
    $n_feff = $1+1;
    ## feff parents do not have strings
  } elsif ($$r_old_path =~ /((data\d+)\.feff\d+)\.(\d+)/) { # --- PATH ----
    my $this = $$r_old_path;
    my $kid = $list -> addchild($1);
    $paths{$kid} = Ifeffit::Path -> new(id	     => $kid,
					type	     => 'path',
					parent	     => $1,
					data	     => $2,
					from_project => 1,
					intrpline    => "",
					zcwif	     => 0,
					family	     => \%paths);
    while (@$r_args) {
      my ($k, $v) = (shift @$r_args, shift @$r_args);
      next if ($k =~ /^(id|type|group|parent|data)$/);
      $paths{$kid} -> make($k=>$v);
    };
    my $data   = $paths{$kid}->data;
    ($paths{$kid}->make(deg => int $paths{$kid}->get('deg'))) if
      ($paths{$kid}->get('deg') == int $paths{$kid}->get('deg'));
    my $fi = substr($paths{$kid}->get('file'),4,4);
    $paths{$kid} -> make(feff_index=>sprintf('%d', $fi));
    my $save_deg = $paths{$kid}->get('deg');
    my $header = "";
    map {$header .= $_."\n"} (@$r_strings);
    my $file = File::Spec->catfile($paths{$kid}->get('path'), $paths{$kid}->get('feff'));
    ## take care that the file actually exists...
    unless (-e $file) {
      delete $paths{$kid};
      $list -> delete('entry', $kid);
      return;
    };
    $paths{$kid} -> make(header=>nnnn_header($kid, $file),
			 deg=>$save_deg);
    ## plotpath was introduced at DR006
    $paths{$kid} -> make(plotpath=>0) unless $paths{$kid}->get('plotpath');
    $paths{$kid} -> make(is_ss  => 1) if ($paths{$kid}->get("nleg") == 2);
    $paths{$kid} -> make(intrpline => $paths{$kid}->intrpline);
    $paths{$kid}->make(is_col => 1) if ($paths{$kid}->get("intrpline") =~ /\d :/);
    my $style = $list_styles{$paths{$kid}->pathstate};
    $style = ($paths{$paths{$kid}->data}->get('include')) ? $style : $list_styles{disabled};
    $list -> entryconfigure($kid,
 			    -style=> $style,
			    -text => $paths{$kid}->get('lab')
			   );

  };

};




sub delete_project {
  my $restore = $_[0];
  Echo("Closing project ... ");
  my $is_busy = grep (/Busy/, $top->bindtags);
  $top -> Busy unless $is_busy;

  $widgets{athena_return} -> invoke() if ($current_canvas eq 'athena');

  ## get rid of all $artemis_titleN strings
  ifeffit("show \@strings\n");
  my ($lines, @response) = (Ifeffit::get_scalar('&echo_lines')||0, ());
  if ($lines) {
    map {push @response, Ifeffit::get_echo()} (1 .. $lines);
  };
  foreach (@response) {
    $paths{data0} -> dispose("erase $1") if (/^\s*(\$artemis_title\d+)/);
  };

  foreach my $d (&every_data) {
    $paths{$d}->delete_titles;
    unless ($paths{$d}->get('include')) {
      $paths{$d}->make(include=>1);
      &toggle_data($d);
    };
  };
  my $first = first_data;
  $list -> entryconfigure($first, -text=>'Data');
  $list -> setmode($first, 'none');
  $current = $first;
  display_page($first);
  $top->update;
  clear_gds2();
  ## erase data from ifeffit's memory
  foreach my $k (keys %paths) {
    next if ($k eq 'gsd');
    next unless (ref($paths{$k}) =~ /Ifeffit/);
    ## erase fits from tree
    $list -> delete('offsprings', $k) if ($k =~ /^data\d+\.0$/);
    delete_feff($k,1,2) if ($paths{$k}->type eq 'feff');
  };
  $paths{data0} -> dispose("erase \@paths all", $dmode);
  $paths{data0} -> dispose("erase \@arrays", $dmode);
  $paths{data0} -> drop_all;
  $#gds = -1;
  $gds_selected{type}    = "";
  $gds_selected{name}    = "";
  $gds_selected{mathexp} = "";
  $gds_selected{which}   = 0;

  ## reset the extra plotting features
  $extra[0] = 0;
  $extra[1] = 0;
  $extra[2] = 0;
  $extra[3] = 0;
  $extra[4] = 0;
  $extra[5] = "";
  $widgets{plot_extra} -> raise('main');

  foreach my $d (&all_data) {
    foreach ($list->infoChildren($d)) {
      if (/data\d$/) {	# clear out data
	1;
      } elsif (/feff\d+$/) {	# clear out feff calc
	1; #$list->delete('entry',$_);
      } elsif (/data(\d+)\.\d+/) {	# clear out fit head diff, bkg, res
	$list->delete('entry',$_) unless ($1 == 0);
      };
    };
    clear_op($d);
  };
  $widgets{show_chi} -> invoke();
  map {$widgets{$_} -> configure(-state=>'disabled')} (qw(show_chi show_mu));
  ##--bkg-- clear_athena;
  ##--bkg-- $widgets{data_notebook} -> raise('chi');
  ##--bkg-- $widgets{data_notebook} -> pageconfigure('bkg', -state=>'disabled');
  $list -> hide('entry', "data0.0");

  ## undefine the paths hash, then reset globals
  undef %paths;
  ($n_feff, $n_data) = (0, 0);
  map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'disabled')} (keys %widgets);
  $paths{data0} = Ifeffit::Path -> new(id      => 'data0',
				       group   => 'data0',
				       type    => 'data',
				       sameas  => 0,
				       lab     => 'Data',
				       kwindow => $config{data}{kwindow},
				       rwindow => $config{data}{rwindow},
				       family  => \%paths);
  $paths{gsd}   = Ifeffit::Path -> new(id=>'gsd', type=>'gsd', family=>\%paths);
  $list->focus();
  project_state(1);
  $project_name  = "";
  ## disable the save cascades
  map { $file_menu->menu->entryconfigure($_, -state=>'disabled') }
    ($save_index .. $save_index+4, $save_index+6);
  $data_menu->menu->entryconfigure(2, -state=>'disabled');
  $fit_menu ->menu->entryconfigure(4, -state=>'disabled');
  $widgets{op_include} -> configure(-text=>"Include data in the fit?");
  $widgets{op_plot}    -> configure(-text=>"Plot data after the fit?");
  map {$widgets{$_}  -> deselect()} qw(op_do_bkg op_include op_plot); # op_use_bkg
  map {($_ =~ /^op/) and $widgets{$_}->configure(-state=>'disabled')} (keys %widgets);
  map {$grab{$_}->configure(-state=>'disabled')} (keys %grab);
  ## then clear out the journal ...
  $notes{journal}->delete(qw(1.0 end));
  $widgets{atoms_titles}->delete(qw(1.0 end));
  ## ... and reset the poperties
  $props{'Project title'} = "<insert a title for your project here>";
  $props{'Comment'} = "";
  $props{'Prepared by'} = "<insert your name and/or the name of your computer here>";
  ##$props{'Prepared by'} = ($is_windows) ? "<insert your name and/or the name of your computer here>" :
  ##  join("\@", $ENV{USER}, $ENV{HOST});
  $props{Contact} = "<insert your email address and/or phone number here>";
  $props{Environment} = (split(/\n/, $paths{data0} -> project_header))[1];
  $props{Environment} =~ s/\# /Artemis $VERSION /;
  $props{'Last fit'} = q{};
  $props{'Information content'} = q{};
  $props{'Project location'} = q{};
  $props{Started} = $paths{data0} -> date_of_file;
  ## clean up the GDS page
  &gds2_clear_highlights;
  ## delete autosave file
  unlink $autosave_filename if (-e $autosave_filename);
  Echo("Removed stale autosave file.");

  if ($restore) {
    Echo("Closing project ... done!");
    return;
  };

  # finally, delete the stash directory
  rmtree($project_folder);
  ## $0 does icky, utf8-y things on windows due to the backslashes
  if ($is_windows) {
    $current_data_dir = $ENV{IFEFFIT_DIR};
  } else {
    ($current_data_dir = dirname($0)) if sub_directory($current_data_dir, $project_folder);
  };
  $project_folder = "";
  ## then reset some global variables...
  &set_temp;
  %fit = (index=>1, count=>0, count_full=>0, new=>1, label=>"", comment=>"", fom=>0);
  ## %log_params  ???
  ## and reinitialize the project
  &initialize_project(0);
  my $chdir_to = $current_data_dir || dirname($0) || $ENV{IFEFFIT_DIR};
  $chdir_to = Cwd::abs_path($chdir_to);
  chdir $chdir_to;
  Echo("Closing project ... done!");
  $top -> Unbusy unless $is_busy;
};


sub compactify_project {
  Echo("Compacting project ...");
  $top->Busy;
  foreach my $p (keys %paths) {
    next unless ($paths{$p}->type eq 'feff');
    feff_compactify($p);
  };
  $top->Unbusy;
  Echo("Compacting project ... done!");
  project_state(0);
  &display_properties if ($paths{$current}->type eq 'feff');
  my $message = "All unused files from all Feff calculations have been deleted.  This makes your project file much smaller.\n\nTo recover files that were deleted, simply rerun the Feff calculation and, when it finishes, choose the option to import no paths.";
  &posted_Dialog;
  my $dialog =
    $top -> Dialog(-bitmap         => 'info',
		   -text           => $message,
		   -title          => 'Artemis: Compacting project...',
		   -buttons        => [qw/OK/],
		   -font           => $config{fonts}{med},
		   -default_button => 'OK')
      -> Show();
  Echo(q{});
};


## END OF THE PROJECT FILE SUBSYSTEM

