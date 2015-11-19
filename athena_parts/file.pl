## -*- cperl -*-
##
##  This file is part of Athena, copyright (c) 2001-2008 Bruce Ravel
##
##  This section of the code contains subroutines associated with
##  reading in data and project files

## file reading wrapper...
##   ## read from the command line?  from the web?
##   ## unless (($_[0] and -e $_[0]) or ($_[0] and $_[0] =~ /^http:/)) {
sub read_file {
  my $get_many = $_[0] || 0;
  my $read_arg = $_[1] || 0;
  ($get_many =~ /HASH/) and ($get_many=0);
  $preprocess{ok} = 0;
  my $save_groupreplot = $config{general}{groupreplot};
  $config{general}{groupreplot} = 'none';
  my @data;
  if ($read_arg) {
    push @data, $read_arg;
  } elsif (($Tk::VERSION < 804) and ($get_many)) {
    @data = &get_file_list;
  } elsif ($Tk::VERSION < 804) {
    $data[0] = &get_single_file;
  } else {
    @data = &get_single_file;
  };
  return unless ((@data) and ($data[0]) and ($data[0] !~ /^\s*$/));
  $top -> Busy(-recurse=>1,);
  my ($raw, $cancel) = (undef, 0);
  #$prior_args = [];
  my ($first, $count) = ("", 1);
  my $errmsg;
  my $project_no_prompt = 0;
 DATA: foreach my $thisfile (@data) {
    next unless (($thisfile) and ($thisfile !~ /^\s*$/));
    unless (-r $thisfile) {
      if (-e $thisfile) {
	$errmsg = "Could not read \"$thisfile\" (check permissions)";
	$top -> Dialog(-bitmap  => 'error',
		       -text    => $errmsg,
		       -title   => 'Athena: Error reading file',
		       -buttons => ['OK'],
		       -default_button => "OK" )
	  -> Show();
	Error($errmsg);
      } else {
	$errmsg = "Could not read \"$thisfile\" (file does not exist)";
	$top -> Dialog(-bitmap  => 'error',
		       -text    => $errmsg,
		       -title   => 'Athena: Error reading file',
		       -buttons => ['OK'],
		       -default_button => "OK" )
	  -> Show();
	Error($errmsg);
      };
      $cancel = 1;
      next DATA
    };

    Archive::Zip::setErrorHandler( \&is_zip_error_handler );
    my $zip = Archive::Zip->new();
    ##print $zip->read($thisfile), $/;
    my $is_zipstyle = ($zip->read($thisfile) == AZ_OK) ? 1 : 0;
    my $is_artemis = ($is_zipstyle) ? $zip->membersMatching(/HORAE/) : 0;
    ##print "$thisfile|$is_zipstyle|$is_artemis\n";
    undef $zip;
    Archive::Zip::setErrorHandler( undef );
    if ($is_artemis) {
      $errmsg = "Oops!  $thisfile seems to be an Artemis project file.";
      $top -> Dialog(-bitmap  => 'error',
		     -text    => $errmsg,
		     -title   => 'Athena: Error reading file',
		     -buttons => ['OK'],
		     -default_button => "OK" )
	-> Show();
      Error($errmsg);
      $cancel = 1;
      next DATA;
    };
    if ($is_zipstyle) {
      $errmsg = "$thisfile is not a valid data file.";
      $top -> Dialog(-bitmap  => 'error',
		     -text    => $errmsg,
		     -title   => 'Athena: Error reading file',
		     -buttons => ['OK'],
		     -default_button => "OK" )
	-> Show();
      Error($errmsg);
      $cancel = 1;
      next DATA;
    };


    # does this one have mac line-endings?
#     my $was_mac = $groups{"Default Parameters"} ->
#       fix_mac($thisfile, $stash_dir, lc($config{general}{mac_eol}), $top);
#     Echo("\"$thisfile\" had Macintosh EOL characters and was skipped."), next DATA if ($was_mac eq '-1');
#     Echo("\"$thisfile\" had Macintosh EOL characters and was fixed.") if ($was_mac eq '1');
    my $is_record = (Ifeffit::Files->is_record($thisfile));
    my ($is_mac, $tempfile) = (0, q{});
    if (not $is_record) {
      local( $/, *FH ) ;
      open( FH, $thisfile ) or die "sudden flaming death\n";
      my $snarf = <FH>;
      close(FH);
      if (($snarf !~ m{SSRL\s+\-?\s+EXAFS Data Collector}) and ($snarf =~ m{\r(?!\n)})) { # this matches Mac EOL but not Windows
	Echo("Correcting Mac line termination for $thisfile");
	$tempfile =  File::Spec->catfile($stash_dir, "unmacify_".basename($thisfile));
	$snarf =~ s{\r(?!\n)}{\n}g;
	open TF, ">",$tempfile;
	print TF $snarf;
	close TF;
	$is_mac = 1;
      };
    };
    my $thisfile_notmac = ($is_mac) ? $tempfile : $thisfile;

    my @foo = %marked;
    my $empty = $#foo;
    my $safe_message_issued = 0;
    my %stash;
    my %map;
    if ($is_record) {
      my $fname = $thisfile_notmac;
      my %group_map = ();
      my ($imported, $total) = (0,0);
      my $frame = examine_project($fname, \%group_map, \$cancel, \$project_no_prompt);
      ($frame == 0) or $frame -> waitWindow();
      last DATA if ($cancel);
      my $nrecords = 0;
      $reading_project = 1;
      ##open R, $fname or die "Could not open $thisfile_notmac as a record or project\n";
      my $gz = gzopen($fname, "rb") or die "could not open $fname as an Athena project\n";
      my $line;
      use vars qw($old_group @args @x @y @journal @stddev @i0 %foo);
      while ($gz->gzreadline($line) > 0) {
	next if ($line =~ /^\s*\#/);
	next if ($line =~ /^\s*$/);
	next if ($line =~ /^\s*1/);
	#if ($is_windows) {
	if ($always_false) {

	  ## eval each line directly -- NOT SAFE!!
	  Echo("Reading project file with direct evaluations") unless $safe_message_issued;
	  $safe_message_issued = 1;
	WINDOWS: {
	    ($line =~ /^\@journal/) and do {
	      eval $line;
	      foreach (@journal) {
		$notes{journal} -> insert('end', $line."\n", "text");
	      };
	      last WINDOWS;
	    };
	    ($line =~ /^\%plot_features/) and do {

	      (my $this = $line) =~ s/^\%plot_features/\%foo/;
	      eval $this;
	      foreach my $k (keys %foo) {
		next unless ($k =~ /[ekqr]((_\w+)|(m(ax|in)))/);
		$plot_features{$k} = $foo{$k};
	      };
	      ($plot_features{e_marked} = 'n') if ($plot_features{e_marked} eq 'd');
	      last WINDOWS;
	    };
	    ($line =~ /^\@indicator/) and do {
	      (my $this = $line) =~ s/^\@indicator\s+=\s+//;
	      my @indic = eval $this;
	      foreach (1 .. $#indic) {
		$indicator[$_]->[1] = $indic[$_]->[1];
		$indicator[$_]->[2] = $indic[$_]->[2];
	      };
	      #print Data::Dumper->Dump([\@indicator], [qw/indicator/]);
	      last WINDOWS;
	    };
	    ($line =~ /^\%lcf_data/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    ($line =~ /^\$old_group/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    ($line =~ /^\@args/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    ($line =~ /^\@x/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    ($line =~ /^\@y/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    ($line =~ /^\@stddev/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    ($line =~ /^\@i0/) and do {
	      eval $line;
	      last WINDOWS;
	    };
	    (($line =~ /^\[record\]/) or ($line =~ /^\&read_record/)) and do {
	      my $memory_ok = $groups{"Default Parameters"}
		-> memory_check($top, \&Echo, \%groups, $max_heap, 0, 1);
	      Echo ("Out of memory in Ifeffit"), last DATA if ($memory_ok == -1);
	      my $gp = &read_record(0, $fname, $old_group, \@args, \@x, \@y, \@stddev, \@i0);
	      $map{$old_group} = $gp;
	      $first ||= $gp;
	      ++$nrecords;
	      $old_group = ""; @args = (); @x = ();  @y = (); @journal = (); @stddev = (); @i0 = (); %foo = ();
	      last WINDOWS;
	    };
	    1;
	  };

	} else {

	  ## read each line in a Safe compartment
	  Echo("Reading project file in a safe compartment") unless $safe_message_issued;
	  $safe_message_issued = 1;
	  my $cpt = new Safe;
	NOT_WINDOWS: {
	    ($line =~ /^\@journal/) and do {
	      @ {$cpt->varglob('journal')} = $cpt->reval($line);
	      @journal = @ {$cpt->varglob('journal')};
	      foreach (@journal) {
		$notes{journal} -> insert('end', $_."\n", "text");
	      };
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\%plot_features/) and do {
	      $line =~ s{^\%}{\@};
	      @ {$cpt->varglob('plot_features')} = $cpt->reval($line);
	      my @list = @ {$cpt->varglob('plot_features')};
	      while (@list) {	# only set the things in the plot
		my ($k, $v) = (shift @list, shift @list); # options area
		next unless ($k =~ /[ekqr]((_\w+)|(m(ax|in))|w)/);
		$plot_features{$k} = $v;
	      };
	      ($plot_features{e_marked} = 'n') if ($plot_features{e_marked} eq 'd');
	      delete $plot_features{project};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\@indicator/) and do {
	      @ {$cpt->varglob('indicator')} = $cpt->reval($line);
	      my @indic = @ {$cpt->varglob('indicator')};
	      foreach (1 .. $#indic) {
		$indicator[$_]->[1] = $indic[$_]->[1];
		$indicator[$_]->[2] = $indic[$_]->[2];
	      };
	      #print Data::Dumper->Dump([\@indicator], [qw/indicator/]);
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\%lcf_data/) and do {
	      my $this = $line;
	      my $regex = join("|", (keys %map));
	      #print $regex;
	      $this =~ s/\b($regex)\b/$map{$1}/g;
	      % {$cpt->varglob('lcf_data')} = $cpt->reval($this);
	      %lcf_data = % {$cpt->varglob('lcf_data')};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\$old_group/) and do {
	      $ {$cpt->varglob('old_group')} = $cpt->reval($line);
	      $old_group = $ {$cpt->varglob('old_group')};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\@args/) and do {
	      @ {$cpt->varglob('args')} = $cpt->reval($line);
	      @args = @ {$cpt->varglob('args')};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\@x/) and do {
	      @ {$cpt->varglob('x')} = $cpt->reval($line);
	      @x = @ {$cpt->varglob('x')};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\@y/) and do {
	      @ {$cpt->varglob('y')} = $cpt->reval($line);
	      @y = @ {$cpt->varglob('y')};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\@stddev/) and do {
	      @ {$cpt->varglob('stddev')} = $cpt->reval($line);
	      @stddev = @ {$cpt->varglob('stddev')};
	      last NOT_WINDOWS;
	    };
	    ($line =~ /^\@i0/) and do {
	      @ {$cpt->varglob('i0')} = $cpt->reval($line);
	      @i0 = @ {$cpt->varglob('i0')};
	      last NOT_WINDOWS;
	    };
	    (($line =~ /^\[record\]/) or ($line =~ /^\&read_record/)) and do {
	      ++$total;
	      last NOT_WINDOWS if not $group_map{$old_group}; # from examine_project
	      ++$imported;
	      my $memory_ok = $groups{"Default Parameters"}
		-> memory_check($top, \&Echo, \%groups, $max_heap, 0, 1);
	      Echo ("Out of memory in Ifeffit"), last DATA if ($memory_ok == -1);
	      my $gp = read_record(0, $fname, $old_group, \@args, \@x, \@y, \@stddev, \@i0);
	      $map{$old_group} = $gp;
	      $first ||= $gp;
	      ++$nrecords;
	      $old_group = ""; @args = (); @x = ();  @y = (); @journal = (); @stddev = (); @i0 = (); %foo = ();
	      last NOT_WINDOWS;
	    };
	    1;
	  };
	};
      };
      $reading_project = 0;
      $gz->gzclose();
      ##close R;
      unless ($nrecords) {
	$top->Unbusy;
	Echo("The project file \"$fname\" contained no records.");
	return;
      };
      my $complete = ($total == $imported);
      &push_mru($thisfile, 1, 1, $complete);
      project_state(1) if ($empty == -1);


      &set_properties(1, $first||$current, 0);
    SWITCH: {
	($groups{$first}->{is_xmu}) and do {
	  &plot_current_e;
	  last SWITCH;
	};
	($groups{$first}->{is_chi}) and do {
	  my $str = sprintf('k%1d', $plot_features{kw}); #$groups{$first}->{fft_kw});
	  &plot_current_k;
	  last SWITCH;
	};
      };

##       foreach my $g (keys %groups) {
## 	next if ($g eq "Default Parameters");
## 	print $groups{$g}->{group}, " ", $groups{$g}->{old_group}, "\n";
##       };

      ## restore purple mark buttons and fix up background standards,
      ## reference channels, and lcf standards
      foreach my $k (keys %groups) {
	next if ($k eq "Default Parameters");
	## mu_str
	if (exists($groups{$k}->{mu_str}) and $groups{$k}->{is_proj}) {
	  my $mustr = $groups{$k}->{mu_str};
	  my $old   = $groups{$k}->{old_group};
	  $mustr =~ s/\b$old\b/$k/g;
	  $groups{$k}->MAKE(mu_str=>$mustr);
	};
	## mark buttons
	if (exists($groups{$k}->{project_marked}) and
	    $groups{$k}->{project_marked}) {
	  $marked{$k} = 1;
	  $groups{$k}->{checkbutton} -> select;
	};
	## background standards
	unless ((exists $groups{$k}->{bkg_stan}) and
		($groups{$k}->{bkg_stan} eq 'None')) {
	STAN: foreach my $kk (keys %groups) {
	    next if ($kk eq "Default Parameters");
	    ##print join(" ", $k, $groups{$k}->{bkg_stan}, $kk, $groups{$kk}->{old_group}), $/;
	    if ((exists $groups{$k}->{bkg_stan})   and
		(exists $groups{$kk}->{old_group}) and
		($groups{$k}->{bkg_stan} eq $groups{$kk}->{old_group})) {
	      $groups{$k}->MAKE(bkg_stan=>$kk);
	      last STAN;
	    };
	  };
	};
	## reference channels
	if ($groups{$k}->{reference}) {
	  my $found = 0;
	INNER: foreach my $o (keys %groups) {
	    next if ($o eq "Default Parameters");
	    next if ($o eq $k);
	    next unless exists $groups{$o}->{old_group};
	    if ((exists $groups{$k}->{reference}) and
		(exists $groups{$o}->{old_group}) and
		($groups{$k}->{reference} eq $groups{$o}->{old_group})) {
	      $groups{$k}->MAKE(reference=>$o);
	      $found = 1;
	      last INNER;
	    };
	  };
	  $groups{$k}->MAKE(reference=>0) if
	    ((not $found) and ## in case of partial project import
	     (not exists($groups{$groups{$k}->{reference}}))); # already in project
	};
	## linear combination fitting standards
	if ($groups{$k}->{lcf_fit}) {
	  my @keys = ();
	  foreach my $kk (&sorted_group_list) {
	    ($groups{$kk}->{is_xmu} or $groups{$kk}->{is_chi}) and push @keys, $kk;
	  };

	LCF: foreach my $o (keys %groups) {
	    next if ($o eq "Default Parameters");
	    next if ($o eq $k);

	    foreach my $i (1 .. $config{linearcombo}{maxspectra}) {
	      next unless (exists $groups{$k}->{"lcf_standard$i"});
	      next if ($groups{$k}->{"lcf_standard$i"} eq 'None');
	      next unless (exists $groups{$o}->{old_group});
	      if ($groups{$k}->{"lcf_standard$i"}  eq $groups{$o}->{old_group}) {
 		my $ii = 0;
 		foreach my $ke (@keys) { # find the index of this standard
 		  ++$ii;
 		  last if ($ke eq $o);
 		};
		$groups{$k}->MAKE("lcf_standard$i"     => $o,
				  "lcf_standard_lab$i" => $ii . ": " . $groups{$o}->{label});
	      };
	      if ((exists $groups{$k}->{"lcf_standard$i"}) and
		  (not exists $groups{$o}->{old_group})) {
		$groups{$k}->MAKE("lcf_standard$i"     => 'None',
				  "lcf_standard_lab$i" => '0: None',
				  "lcf_e0$i"           => 0,
				  "lcf_e0val$i"        => 0,
				  "lcf_value$i"        => 0,
				 );
	      };
	      ##print "$i  ", $groups{$k}->{label}, " ", $groups{$k}->{"lcf_standard_lab$i"}, $/;
	    };
	  };
	};
      };
      foreach my $o (keys %stash) {
	foreach my $k (%groups) {
	  next unless (exists $groups{$k}->{old_group});
	  next unless ($groups{$k}->{old_group} eq $o);
	  $lcf_data{$k} = $stash{$o};
	};
# 	my @order = map { $map{$_} } @{ $stash{$o}{order} };
# 	$stash{$o}{order} = \@order;
# 	my @results = @ {$stash{$o}{results}};
# 	my @fixed;
# 	foreach my $r (@results) {
# 	  my $r->[0]
# 	};
      };
    } else {
      #my $foo = $thisfile_notmac;
      ($raw, $prior_string) = read_raw($thisfile_notmac, $thisfile, $prior_string, $prior_args, \$cancel, \$count);
      ($raw == 0) or $raw -> waitWindow();
      last DATA if ($cancel);
      ++$count;
      $top->update;
    };
  };
  ## unset extra import features
  #$rebin{do_rebin}	= 0;
  $preprocess{standard}	||= 'None';
  #$preprocess{mark_do}	= 0;
  #$preprocess{trun_do}	= 0;
  #$preprocess{deg_do}	= 0;

  $preprocess{raised} ||= "reference";
  $rebin{titles}	= [];
  $preprocess{titles}	= [];

  section_indicators();

  $top->Unbusy, return if $cancel;
  $current and &set_properties(1, $first||$current,0);
  $config{general}{groupreplot} = $save_groupreplot;
  # finally adjust the view
  if (exists($groups{$current}->{text})) {
    my $here = ($list->bbox($groups{$current}->{text}))[1] - 5  || 0;
    ($here < 0) and ($here = 0);
    my $full = ($list->bbox(@skinny_list))[3] + 5;
    $list -> yview('moveto', $here/$full);
  };
  $top->Unbusy;
};


## fetch a list of files using FileSelect
sub get_file_list {
  ## read from the command line?  from the web?
  ## unless (($_[0] and -e $_[0]) or ($_[0] and $_[0] =~ /^http:/)) {
  require Cwd;
  my $path = $current_data_dir || Cwd::cwd;
  my $FSel  = $top->FileSelect(-title => 'Athena: open MANY data files',
			       -width => 40,
			       -directory=>$path);
  $FSel -> configure(-selectmode=>'extended');
  my @data = $FSel->Show;
  return sort @data;
};

## fetch a single file using getOpenFile
sub get_single_file {
  ## read from the command line?  from the web?
  ## unless (($_[0] and -e $_[0]) or ($_[0] and $_[0] =~ /^http:/)) {
  require Cwd;
  #local $Tk::FBox::a;
  #local $Tk::FBox::b;
  my $path = $current_data_dir || Cwd::cwd;
  my $types = [['All Files',            '*'],
	       ['data files',          ['.dat', '.xmu']],
	       ['chi(k) files',         '.chi'],
	       ['Athena project files', '.prj'],
	      ];
  if ($Tk::VERSION > 804) {
    my $file = $top -> getOpenFile(-filetypes=>$types,
				   #(not $is_windows) ?
				   #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				   -multiple => 1,
				   -title => "Athena: Open one or more data files");
    $file ||= [];
    return sort @$file;
  } else {
    my $file = $top -> getOpenFile(-filetypes=>$types,
				   #(not $is_windows) ?
				   #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				   -initialdir=>$path,
				   -title => "Athena: Open a SINGLE data file");
    $file ||= q{};
    return $file;
  };
};


sub read_demo {
  require Cwd;
  #local $Tk::FBox::a;
  #local $Tk::FBox::b;
  my $path = $groups{"Default Parameters"} -> find('athena', 'demos');
  my $types = [['Athena project files', '.prj'],
	       ['All Files',            '*'],
	      ];
  my $file = scalar $top -> getOpenFile(-filetypes=>$types,
					#(not $is_windows) ?
					#  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
					-initialdir=>$path,
					-multiple => 0,
					-title => "Athena: Open a demo project");
  if ($file) {
    read_file(0,$file);
    raise_palette('journal');
  };
};

## read a file as raw data.  This means to prompt for column selection.
sub read_raw {

  my $red = $config{colors}{single};

  my ($data, $orig, $prior_string, $prior_args, $r_cancel, $rcount) = @_;
  my $count = $$rcount;
				## look at first file in list to see
				## if this is a record or raw dat
  my $memory_ok = $groups{"Default Parameters"}
    -> memory_check($top, \&Echo, \%groups, $max_heap, 0, 1);
  Echo ("Out of memory in Ifeffit"), return (-1, $prior_string) if ($memory_ok == -1);

  ## bad things happen if the data file name is longer than 128
  ## characters.  when this happens, transfer the file to the stash
  ## directory so ifeffit can read it from there.  if the filename is
  ## not too long, then $stash and $data will be the same
  my $stash = $data;
  my $is_binary = 0;

 PLUGINS: foreach my $p (sort {$a cmp $b} @plugins) {
    next PLUGINS unless $plugin_params{$p}{_enabled};
    if (eval "Ifeffit::Plugins::Filetype::Athena::$p->is('$data')") {
      Echo("$data seems to be a $p data file.");
      $stash = eval "Ifeffit::Plugins::Filetype::Athena::$p->fix('$data', '$stash_dir', \$top, \$plugin_params{$p});";
      if (not $stash) {
	$$r_cancel = 1;
	set_status(0);
	Echo("$data could not be read as a $p data file.");
	return (0, $prior_string);
      };
      my $file = $groups{"Default Parameters"} -> find('athena', 'plugins');
      tied( %plugin_params )->WriteConfig($file);
      eval "\$is_binary = \$Ifeffit::Plugins::Filetype::Athena::${p}::is_binary";
      last PLUGINS;
    };
  };
  if ($stash =~ /\#/) {
    my ($nme, $pth, $suffix) = fileparse($stash);
    $nme =~ s/\#//g;
    my $new = File::Spec->catfile($stash_dir, $nme);
    ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
    copy($stash, $new);
    $stash = $new;
  };
  if (length($stash) > 127) {
    my ($nme, $pth, $suffix) = fileparse($stash);
    my $new = File::Spec->catfile($stash_dir, $nme);
    ($new = File::Spec->catfile($stash_dir, "toss")) if (length($new) > 127);
    copy($stash, $new);
    $stash = $new;
  };

  my %label_map = (e=>'mu(E)', n=>'norm(E)', k=>'chi(k)', d=>'detector',
		   x=>'xmu.dat', c=>'chi.dat', a=>'xanes(E)');
  my ($name, $pth, $suffix) = fileparse($data, qw(\. \.dat \.chi \.xmu));
  my $databox;
  #my $group = $name;
  my $group = $name.$suffix;
  my $label;
  ($group, $label) = group_name($group);
  ##$groups{$current} -> dispose("read_data(file=\"$data\", group=$group)\n", $dmode);
  my $is_xmudat = Ifeffit::Files->is_xmudat($stash, $top);
  my $is_pixel  = ($config{pixel}{do_pixel_check}) ?
    Ifeffit::Files->is_pixel($stash) : 0;
  my $is_xanes = 0;
  ($is_xanes = Ifeffit::Files->is_xanes($stash, 100)) if $config{xanes}{cutoff};
  if ($stash ne $data) {
    $groups{"Default Parameters"} -> dispose("## actual file: $data\n");
    $groups{"Default Parameters"} -> dispose("## transfered to stash file: $stash\n");
  };
  $groups{"Default Parameters"} -> dispose("\n## Reading a data file in the column selection dialog\n");
  if ($is_xmudat) {
    $groups{"Default Parameters"} -> dispose("read_data(file=\"$stash\", group=$group, type=xmu.dat, no_sort)\n", $dmode);
  } else {
    $groups{"Default Parameters"} -> dispose("read_data(file=\"$stash\", group=$group, no_sort)\n", $dmode);
  };
  unless (Ifeffit::Files->is_datafile) {
    $top -> Dialog(-bitmap  => 'error',
		   -text    => "\`$data\' could not be read by ifeffit as a data file",
		   -title   => 'Athena: Error reading file',
		   -buttons => ['OK'],
		   -default_button => "OK" )
      -> Show();
    ## delete title lines from ifeffit for $group
    $$r_cancel = 0;
    set_status(0);
    return (0, $prior_string);
  };
  my $str = &column_string;
  my $suff = (split(" ", $str))[0];
  $groups{"Default Parameters"} -> dispose("set ___n = npts($group.$suff)", $dmode);
  my $nn = Ifeffit::get_scalar("___n");
  if ($nn <= $config{general}{minpts}) {
    $top -> Dialog(-bitmap  => 'error',
		   -text    => "\`$data\' has fewer than " .
		   $config{general}{minpts} . " data points.",
		   -title   => 'Athena: Error reading file',
		   -buttons => ['OK'],
		   -default_button => "OK" )
      -> Show();
    ## delete title lines from ifeffit for $group
    $$r_cancel = 0;
    set_status(0);
    --$count;
    return (0, $prior_string);
  };

  &push_mru($orig, 1);

  ## the heuristic for deciding if the interpretation of the columns
  ## has changed is the value of ifeffit's column_label variable.  I
  ## presume that if this is unchanged between successive files, then
  ## I can interpret the columns identically.  This is a decent
  ## heuristic for data with labeled columns, but can be trouble for
  ## unlabeled columns.  In that case, the arrays are called $group.1,
  ## $group.2, etc.
  my $col_string = &column_string;
    ## this is trouble -- need to know difference between one file and many files
  if (($count > 1) and ($col_string eq $prior_string)) {
    construct_xmu(0, $group, $label, $data, $stash, $prior_args);
    return (0, $col_string);
  };
  ## If the column lables are different, then go ahead and set up the
  ## column selection palette...
  my @cols = split(" ", $col_string);
  my $raw = $top->Toplevel(-class=>'horae');
  $raw -> geometry($1) if $colsel_geometry =~ /([-+]\d+[-+]\d+)/;
  $raw -> title('Athena: data columns');
  $raw -> protocol(WM_DELETE_WINDOW => sub{$colsel_geometry = $raw->geometry; $$r_cancel = 1; $raw->destroy; return (-1, $prior_string)});
  $raw -> packPropagate(1);
  $raw -> bind('<Control-q>' => sub{$colsel_geometry = $raw->geometry; $$r_cancel = 1; $raw->destroy; return (-1, $prior_string)});
  $raw -> bind('<Control-d>' => sub{$colsel_geometry = $raw->geometry; $$r_cancel = 1; $raw->destroy; return (-1, $prior_string)});
  my ($fnlabel, $enlabel, $unlabel);
  my $grey= '#9c9583';
  my $active_color = $config{colors}{activehighlightcolor};
  ##my $preproc_state = (scalar(keys %groups) == 1) ? 'disabled' : 'normal';
  my $preproc_state = 'normal';
  my $preproc_number = scalar(keys %groups);
  #($preproc_state = 'disabled') if ($current eq "Default Parameters");
  my ($energy, %numerator, %denominator, $mustr, $enstr, %widg, %reference);
  my ($j, $do_ln, $invert, $multi, $xmustring, $space, $space_label, $evkev, $sort, $sorted) =
    (1, 0, 0, 0, "1", 'e', "mu(E)", 'ev', 1, "");
  %reference  = (numerator=>0, denominator=>0, ln=>1, same=>1);
				## build a grid of radio and check
				## buttons for selecting columns from
				## which to construct mu(E)
  my $left  = $raw -> Frame() -> pack(-side=>'left',  -anchor=>'n');
  my $right = $raw -> Frame() -> pack(-side=>'right', -anchor=>'n', -expand=>1, -fill=>'both');
  ($widg{left}, $widg{right}, $widg{raw}) = ($left, $right, $raw);

  my $fr = $left -> Scrolled('Pane', -relief=>'groove', -borderwidth=>2,
			     -gridded=>'xy',
			     -scrollbars=>'os', -sticky => 'we',)
    -> pack(-expand=>1, -fill=>'x');
  $fr->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
  $fr -> Label(-text=>' ', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $fr -> Label(-text=>'Energy', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $fr -> Label(-text=>'Numerator', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $fr -> Label(-text=>'Denominator', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  my @toss;
  ## regexes that attempt to recognize common labels for the i0, it, and if
  ## channels
  my %re = (i0 => $config{general}{i0_regex},
	    it => $config{general}{transmission_regex},
	    if => $config{general}{fluorescence_regex},  );
  if ($config{general}{match_as} eq 'glob') {
    $re{i0} = glob_to_regex($config{general}{i0_regex});
    $re{it} = glob_to_regex($config{general}{transmission_regex});
    $re{if} = glob_to_regex($config{general}{fluorescence_regex});
  };
  my %parts = (0=>0, t=>0, f=>0);
  ##   $Data::Dumper::Indent = 2;
  ##   print Data::Dumper->Dump([$prior_args],[qw(*prior_args)]);
  ##   $Data::Dumper::Indent = 0;
  my $match = 0;
  foreach (@cols) {
    my $this = $group.".".$_;
    ($numerator{$this}, $denominator{$this}) = (0,0);

    if ($$prior_args{old}) { 	# check to see if column labels are
                                # the same as the previous group
      my $old = $$prior_args{old};
      $old = (split(/\./, $old))[0];
				## the keys of the hashes are of the form
				## group.col rather than just col
      (my $that = $this) =~ s/$group/$old/;
      ($energy = $this) if ($that eq $$prior_args{old});
      $numerator{$this}   = $$prior_args{numerator}->{$that} || 0;
      $denominator{$this} = $$prior_args{denominator}->{$that} || 0;
      $match += $numerator{$this} + $denominator{$this};

      ($reference{numerator}   = $this) if ($$prior_args{ref}->{numerator}   eq $that);
      ($reference{denominator} = $this) if ($$prior_args{ref}->{denominator} eq $that);

    };

    $fr -> Label(-text=>$_)
      -> grid(-row=>0, -column=>$j);
    my $jj = $j;  # need a counter that is scoped HERE
    $fr -> Radiobutton(-variable=>\$energy, -value=>$this, -selectcolor=>$red,
		       -command =>
		       sub{
			 $$prior_args{old}	    = $energy;
			 $$prior_args{numerator}    = \%numerator;
			 $$prior_args{denominator}  = \%denominator;
			 $$prior_args{do_ln}	    = $do_ln;
			 $$prior_args{invert}	    = $invert;
			 $$prior_args{space}	    = $space;
			 $$prior_args{evkev}	    = $evkev;
			 $$prior_args{is_xmudat}    = $is_xmudat;
			 $$prior_args{sort}	    = $sort;
			 $$prior_args{multi}	    = $multi;
			 $$prior_args{ref}	    = \%reference;
			 ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
			 $sort=$jj;
		       })
      -> grid(-row=>1, -column=>$j,);
    $fr -> Checkbutton(-variable=>\$numerator{$this}, -selectcolor=>$red, -command=>
		       sub{
			 $$prior_args{old}	    = $energy;
			 $$prior_args{numerator}    = \%numerator;
			 $$prior_args{denominator}  = \%denominator;
			 $$prior_args{do_ln}	    = $do_ln;
			 $$prior_args{invert}	    = $invert;
			 $$prior_args{space}	    = $space;
			 $$prior_args{evkev}	    = $evkev;
			 $$prior_args{is_xmudat}    = $is_xmudat;
			 $$prior_args{sort}	    = $sort;
			 $$prior_args{multi}	    = $multi;
			 $$prior_args{ref}	    = \%reference;
			 ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
			 my $sum = 0;
			 foreach my $v (values %numerator) {$sum += $v};
			 $widg{multi} -> configure(-state=>($sum > 1)?'normal':'disabled');
		       })
      -> grid(-row=>2, -column=>$j,);
    $fr -> Checkbutton(-variable=>\$denominator{$this}, -selectcolor=>$red, -command=>
		       sub{
			 $$prior_args{old}	    = $energy;
			 $$prior_args{numerator}    = \%numerator;
			 $$prior_args{denominator}  = \%denominator;
			 $$prior_args{do_ln}	    = $do_ln;
			 $$prior_args{invert}	    = $invert;
			 $$prior_args{space}	    = $space;
			 $$prior_args{evkev}	    = $evkev;
			 $$prior_args{is_xmudat}    = $is_xmudat;
			 $$prior_args{sort}	    = $sort;
			 $$prior_args{multi}	    = $multi;
			 $$prior_args{ref}	    = \%reference;
			 ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)
		       })
      -> grid(-row=>3, -column=>$j,);
    ++$j;
  };

  ## $match>0 means that the columns used in the last imported file match this
  ## file.  If there is no match, then need to rely upon the regexes for
  ## i0, it, if
  #if ($match) {
  if ($col_string eq $prior_string) {
    $do_ln	   = $$prior_args{do_ln}  || 0;
    $invert	   = $$prior_args{invert} || 0;
    $space	   = $$prior_args{space}  || 'e';
    $space_label   = $label_map{$space};
    $evkev	   = $$prior_args{evkev}  || 'ev';
    $sort	   = $$prior_args{sort}   || 1;
    $multi	   = $$prior_args{multi}  || 0;
    %reference     = (numerator   => $reference{numerator}   || $$prior_args{ref}{numerator}   || 0,
		      denominator => $reference{denominator} || $$prior_args{ref}{denominator} || 0,
		      ln          => $$prior_args{ref}->{ln},
		      same        => $$prior_args{ref}->{same},
		     );
    $sorted      = $$prior_args{sorted} || "";
    ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
  } else {

    ## reset all the preprocessing stuff if this one is different
    $rebin{do_rebin}	  = 0;
    $preprocess{standard} = 'None';
    $preprocess{mark_do}  = 0;
    $preprocess{trun_do}  = 0;
    $preprocess{deg_do}	  = 0;
    $preprocess{raised}	  = 'reference';

    %reference  = (numerator=>0, denominator=>0, ln=>1, same=>1);
    $$prior_args{evkev}  = 'ev';
    foreach (@cols) {
      my $this = $group.".".$_;
      (/^(e|en|energy)/i) and ($energy = $this);
      (/^[Kk]$/)   and ($energy = $this);
      (/$re{i0}/i) and ($parts{0} = $this);
      if (/$re{it}/i) {$parts{t} = $this}
      elsif (/$re{if}/i) {$parts{f} = $this};
    };
    $energy ||= $group.".".$cols[0]; # set it if not already set

    if ($parts{t}) {
      $denominator{$parts{t}} = 1;
      ($parts{0}) and ($numerator{$parts{0}} = 1);
      $do_ln = 1;
      ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
    } elsif ($parts{f}) {
      $numerator{$parts{f}} = 1;
      ($parts{0}) and ($denominator{$parts{0}} = 1);
      $do_ln = 0;
      ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
    }
  };

  $energy ||= $group.".".$cols[0]; # set it if not already set
  if ($#cols == 1) {		# mu(E) or chi(k) data
    $$prior_args{evkev}  = 'ev';
    $numerator{$group.".".$cols[1]} = 1;
    ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
  } elsif (($#cols == 3) and ($cols[1] eq 'chi')) { # probably a chi.dat file
    $numerator{$group.".".$cols[1]} = 1;
    ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
  } elsif ($is_xmudat) {
    $$prior_args{evkev}  = 'ev';
    $numerator{"$group.mu"} = 1;
    $energy = $group.".".$cols[0];
    ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy);
  };
				## try to guess if this is chi(k) data.
  if (($#cols == 3) and ($cols[1] eq 'chi')) {
    ($space, $space_label, $evkev) = ('c', 'chi.dat', 'ev');
  } elsif (($cols[0] eq 'k') or ($cols[1] =~ /chi/)) {
    ($space, $space_label, $evkev) = ('k', 'chi(K)', 'ev');
  } elsif ($is_xmudat) {
    ($space, $space_label, $evkev) = ('x', 'xmu.dat', 'ev');
  } elsif ($is_pixel) {
    ($space, $space_label, $evkev) = ('e', 'mu(E)', 'pixel');
    (($space, $space_label) = ('a','xanes(E)')) if $is_xanes;
  } else {
    (($space, $space_label) = ('a','xanes(E)')) if $is_xanes;
    my @cols = split(" ", $col_string);
    my @en = Ifeffit::get_array("$group.$cols[0]");
    ($#en > 0) || (@en = Ifeffit::get_array($group.'.1'));
    $evkev = ($en[0] < 100) ? 'kev' : 'ev';
  };
  $space       ||= 'm';		# fall back
  $space_label   = $label_map{$space};
  $evkev       ||= 'ev';

  ## Formulas
  $fr = $left -> Frame(-relief=>'flat', -borderwidth=>0,)
    -> pack(-expand=>1, -fill=>'x');
  ## take the natural log?
  $fr -> Checkbutton(-text=>"Natural log",
		     -variable=>\$do_ln,
		     -selectcolor=>$red,
		     -onvalue=>1,
		     -command=>
		     sub{
		       $$prior_args{old}	 = $energy;
		       $$prior_args{numerator}   = \%numerator;
		       $$prior_args{denominator} = \%denominator;
		       $$prior_args{do_ln}	 = $do_ln;
		       $$prior_args{invert}	 = $invert;
		       $$prior_args{space}	 = $space;
		       $$prior_args{evkev}	 = $evkev;
		       $$prior_args{is_xmudat}   = $is_xmudat;
		       $$prior_args{sort}	 = $sort;
		       $$prior_args{multi}	 = $multi;
		       $$prior_args{ref}	 = \%reference;
		       ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)
		     })
    -> pack(-side=>'left', -anchor=>'w');
  $widg{multi} = $fr -> Checkbutton(-text=>"Save each channel as a group",
				    -variable=>\$multi, -selectcolor=>$red,
				    -onvalue=>1, -offvalue=>0,
				    -state=>'disabled')
    -> pack(-side=>'right', -anchor=>'w');
  $fr = $left -> Frame(-relief=>'flat', -borderwidth=>0,)
    -> pack(-pady=>2, -expand=>1, -fill=>'x');
  $fr -> Checkbutton(-text=>"Negate",
		     -variable=>\$invert,
		     -selectcolor=>$red,
		     -onvalue=>1,
		     -command=>
		     sub{
		       $$prior_args{old}	 = $energy;
		       $$prior_args{numerator}   = \%numerator;
		       $$prior_args{denominator} = \%denominator;
		       $$prior_args{do_ln}	 = $do_ln;
		       $$prior_args{invert}	 = $invert;
		       $$prior_args{space}	 = $space;
		       $$prior_args{evkev}	 = $evkev;
		       $$prior_args{is_xmudat}   = $is_xmudat;
		       $$prior_args{sort}	 = $sort;
		       $$prior_args{multi}	 = $multi;
		       $$prior_args{ref}	 = \%reference;
		       ($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)
		     })
    -> pack(-side=>'left', -anchor=>'w');
  $fr -> Button(-text=>"Replot",
		-borderwidth=>1,
		-command=>sub{make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)},
	       )
    -> pack(-side=>'right', -anchor=>'w');

  $fr = $left -> Frame(-relief=>'flat', -borderwidth=>0,)
    -> pack(-pady=>2, -expand=>1, -fill=>'x');
  $enlabel = $fr -> Label(-text=>"Energy:",
			  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left', -padx=>2);
  $enstr = $fr -> Label(-textvariable=>\$energy, -justify=>'left')
    -> pack(-side=>'left', -padx=>2, -expand=>1, -fill=>'x', -anchor=>'w');

  $fr = $left -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-pady=>2, -expand=>1, -fill=>'x');
  $fnlabel = $fr -> Label(-text=>($is_xmudat) ? "theory:" : "mu(E):",
			  -foreground=>$config{colors}{activehighlightcolor},
			  -width=>6)
    -> pack(-side=>'left', -padx=>2);
  $mustr = $fr -> Scrolled("Entry", -text=>\$xmustring, -justify=>'left', -width=>35,
			   (($Tk::VERSION >= 804) ? (-disabledforeground=>$config{colors}{foreground}) : ()),
			   -state=>'disabled')
    -> pack(-side=>'left', -padx=>2, -expand=>1, -fill=>'x');
  $mustr->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background},
					     ($is_windows) ? () : (-width=>8));

  $fr = $left -> Frame(-relief=>'flat', -borderwidth=>2, -height=>2)
    -> pack(-pady=>2, -expand=>1, -fill=>'x');


  my $frm = $left -> Frame(-relief=>'flat', -borderwidth=>2)
    -> pack(-pady=>2, -expand=>1, -fill=>'x');
  ##  -> grid(-row=>5, -column=>0, -sticky=>'ew', -columnspan=>$#cols+2);
  ## choose the data type (mu || norm || chi || xmu.dat || chi.dat || detector)
  my $f1 = $frm -> Frame() -> pack(-side=>'top', -expand=>1, -fill=>'x');
  #my $f2 = $frm -> Frame() -> pack(-side=>'bottom', -expand=>1, -fill=>'x');
  $f1 -> Label(-text=>'Data type: ', -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  my $om = $f1 -> Optionmenu(-font=>$config{fonts}{small},
			     -borderwidth=>1,
			     -textvariable=>\$space_label, -width=>7)
    -> pack(-side=>'left');
  $om ->command(-label=>'mu(E)',
		-command=>sub{$space='e'; $space_label='mu(E)';
			      $widg{evkev}->configure(-state=>'normal');
			      #$widg{pre}->configure(-state=>$preproc_state);
			      $enlabel -> configure(-text=>'Energy:');
			      $fnlabel -> configure(-text=>'mu(E):');
			      $unlabel -> configure(-foreground=>$active_color); });
  $om ->command(-label=>'norm(E)',
		-command=>sub{$space='n'; $space_label='norm(E)';
			      $widg{evkev}->configure(-state=>'normal');
			      #$widg{pre}->configure(-state=>$preproc_state);
			      $enlabel -> configure(-text=>'Energy:');
			      $fnlabel -> configure(-text=>'norm(E):');
			      $unlabel -> configure(-foreground=>$active_color); });
  $om ->command(-label=>'xanes(E)',
		-command=>sub{$space='a'; $space_label='xanes(E)';
			      $widg{evkev}->configure(-state=>'normal');
			      #$widg{pre}->configure(-state=>$preproc_state);
			      $enlabel -> configure(-text=>'Energy:');
			      $fnlabel -> configure(-text=>'mu(E):');
			      $unlabel -> configure(-foreground=>$active_color); });
  $om ->command(-label=>'chi(k)',
		-command=>sub{$space='k'; $space_label='chi(k)';
			      $widg{evkev}->configure(-state=>'disabled');
			      #$widg{pre}->configure(-state=>'disabled');
			      $enlabel -> configure(-text=>'wavenumber:');
			      $fnlabel -> configure(-text=>'chi(k):');
			      $unlabel -> configure(-foreground=>$grey); });
  $om ->command(-label=>'detector',
		-command=>sub{$space='d'; $space_label='detector';
			      $widg{evkev}->configure(-state=>'normal');
			      #$widg{pre}->configure(-state=>$preproc_state);
			      $enlabel -> configure(-text=>'Energy:');
			      $fnlabel -> configure(-text=>'det(E):');
			      $unlabel -> configure(-foreground=>$active_color);});
  $om ->command(-label=>'xmu.dat',
		-command=>sub{$space='x'; $space_label='xmu.dat';
			      $widg{evkev}->configure(-state=>'normal');
			      #$widg{pre}->configure(-state=>'disabled');
			      $enlabel -> configure(-text=>'Energy:');
			      $fnlabel -> configure(-text=>'theory:');
			      $unlabel -> configure(-foreground=>$active_color); });
  $om ->command(-label=>'chi.dat',
		-command=>sub{$space='c'; $space_label='chi.dat';
			      $widg{evkev}->configure(-state=>'disabled');
			      #$widg{pre}->configure(-state=>'disabled');
			      $enlabel -> configure(-text=>'wavenumber:');
			      $fnlabel -> configure(-text=>'theory:');
			      $unlabel -> configure(-foreground=>$grey); });

  $f1 -> Frame(-width=>10)
    -> pack(-side=>'left');
  $unlabel = $f1 -> Label(-text=>'Energy units: ',
			  -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');
  $widg{evkev} = $f1 -> Optionmenu(-font=>$config{fonts}{small},
				   -borderwidth=>1,
				   -textvariable=>\$evkev, -width=>6)
    -> pack(-side=>'left');
  $widg{evkev} -> command(-label  =>'eV',
			  -command=>sub{$evkev = 'ev';
					#$widg{extras} -> raise(($preproc_number>1) ? 'preprocessing' : 'reference');
					$$prior_args{old}	     = $energy;
					$$prior_args{numerator}   = \%numerator;
					$$prior_args{denominator} = \%denominator;
					$$prior_args{do_ln}	     = $do_ln;
					$$prior_args{invert}	     = $invert;
					$$prior_args{space}	     = $space;
					$$prior_args{evkev}	     = $evkev;
					$$prior_args{is_xmudat}   = $is_xmudat;
					$$prior_args{sort}	     = $sort;
					$$prior_args{multi}	     = $multi;
					$$prior_args{ref}	     = \%reference;
					($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)
				      });
  $widg{evkev} -> command(-label  =>'keV',
			  -command=>sub{$evkev = 'kev';
					#$widg{extras} -> raise(($preproc_number>1) ? 'preprocessing' : 'reference');
					$$prior_args{old}	     = $energy;
					$$prior_args{numerator}   = \%numerator;
					$$prior_args{denominator} = \%denominator;
					$$prior_args{do_ln}	     = $do_ln;
					$$prior_args{invert}	     = $invert;
					$$prior_args{space}	     = $space;
					$$prior_args{evkev}	     = $evkev;
					$$prior_args{is_xmudat}   = $is_xmudat;
					$$prior_args{sort}	     = $sort;
					$$prior_args{multi}	     = $multi;
					$$prior_args{ref}	     = \%reference;
					($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)
				      });
  $widg{evkev} -> command(-label  =>'pixel',
			  -command=>sub{$evkev = 'pixel';
					#$widg{extras} -> raise(($preproc_number>1) ? 'preprocessing' : 'reference');
					$$prior_args{old}	     = $energy;
					$$prior_args{numerator}   = \%numerator;
					$$prior_args{denominator} = \%denominator;
					$$prior_args{do_ln}	     = $do_ln;
					$$prior_args{invert}	     = $invert;
					$$prior_args{space}	     = $space;
					$$prior_args{evkev}	     = $evkev;
					$$prior_args{is_xmudat}   = $is_xmudat;
					$$prior_args{sort}	     = $sort;
					$$prior_args{multi}	     = $multi;
					$$prior_args{ref}	     = \%reference;
					($xmustring, @toss) = make_xmu_string(\%numerator, \%denominator, $do_ln, $invert, $energy)
				      },
			  -state=>($config{pixel}{do_pixel_check}) ? 'normal' : 'disabled');
  if ($space =~ /[ck]/) {
    $widg{evkev}->configure(-state=>'disabled');
    $enlabel -> configure(-text=>'wavenumber:');
    $unlabel -> configure(-foreground=>$grey);
  };
 FN: {
    $fnlabel -> configure(-text=>'mu(E):'),   last FN if ($space eq 'e');
    $fnlabel -> configure(-text=>'norm(E):'), last FN if ($space eq 'n');
    $fnlabel -> configure(-text=>'mu(E):'),   last FN if ($space eq 'a');
    $fnlabel -> configure(-text=>'chi(k):'),  last FN if ($space eq 'k');
    $fnlabel -> configure(-text=>'det(E):'),  last FN if ($space eq 'd');
    $fnlabel -> configure(-text=>'theory:'),  last FN if ($space eq 'x');
    $fnlabel -> configure(-text=>'theory:'),  last FN if ($space eq 'c');
  };




  $preprocess{raised} ||= "reference";
  $widg{extras} = $left -> NoteBook(-background=>$config{colors}{background},
				    -backpagecolor=>$config{colors}{background},
				    -inactivebackground=>$config{colors}{inactivebackground},
				    -font=>$config{fonts}{small},
				   )
     -> pack(-pady=>2, -expand=>1, -fill=>'x');
  $widg{pre_card} = $widg{extras} ->
    add("preprocessing", -label=>'Preprocess', -anchor=>'center',
	-state=>$preproc_state);
  set_preprocessing(\%widg)
    -> pack(-expand=>1, -fill=>'x');
  $widg{bin_card} = $widg{extras} ->
    add("bin",           -label=>'Bin'     ,     -anchor=>'center',
	-state=>($$prior_args{space} eq 'k') ? 'disabled' : 'normal');
  set_bin(\%widg)
    -> pack(-anchor=>'n', -fill=>'x');
  $widg{ref_card} = $widg{extras} ->
    add("reference",     -label=>'Reference',     -anchor=>'center',);
  set_reference($widg{ref_card}, $group, \@cols, \%widg, \%reference, \$energy)
    -> pack(-anchor=>'n', -fill=>'x');
  ## $widg{fav_card} = $widg{extras}
  ##   -> add("favorites",     -label=>'Favorites',   -anchor=>'center',);
  ## set_favorites(\%widg)
  ##   -> pack(-anchor=>'n', -fill=>'x');
  $widg{extras} -> raise($preprocess{raised});

  $$prior_args{extra_shown} = 1; # 0;
##   $widg{extra_button} = $left -> Button(-text=>'Show extra features', @button_list,
## 					-command=>
## 					sub{
## 					  my ($h,$w) = ($left->height(), $raw->width());
## 					  $reference{preproc_state} = $preproc_state;
## 					  $widg{extra_button} -> packForget;
## 					  $top -> update; # needed so $raw resizes correctly
## 					  $widg{extras} -> pack(-pady=>2, -expand=>1, -fill=>'x');
## 					  $right->pack(-expand=>1, -fill=>'both',
## 						       -side=>'right', -anchor=>'n');
## 					  $databox->pack(-expand=>1, -fill=>'both',
## 							 -padx=>4, -pady=>2);
## 					  $widg{extras} -> raise(($preproc_number>1 eq 'normal') ? 'preprocessing' : 'reference');
## 					  $$prior_args{extra_shown} = 1;
## 					})
##     -> pack(-expand=>1, -fill=>'x', -pady=>0);


  ## help button
  #$left -> Button(-text=>'Document section: importing data', @button_list,
  #		  -command=>sub{pod_display("import::index.pod")})
  #  -> pack(-side=>'bottom', -fill=>'x', -pady=>2);

  $fr = $left -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-pady=>2, -expand=>1, -fill=>'x', -side=>'bottom');
  $widg{ok}= $fr -> Button(-text=>'OK', @button_list,
			   -command=>
			   sub {
			     $widg{ok} -> configure(-state=>'disabled');
			     if (($rebin{do_rebin}) and ($rebin{abs} =~ /^\s*$/)) {
			       my $dialog =
				 $raw -> Dialog(-bitmap         => 'error',
						-text           => "You did not specify an absorber.  The on-the-fly rebinning algorithm needs to know the absorber species.",
						-title          => 'Athena: Problem with rebinning parameters',
						-buttons        => ['Go back', 'Import without rebinning'],
						-default_button => 'Go back',
						-popover        => 'cursor');
			       $dialog->raise;
			       my $response = $dialog->Show();
			       if ($response eq 'Go back') {
				 $widg{ok} -> configure(-state=>'normal');
				 $raw->raise;
				 $widg{extras} -> raise("bin");
				 $widget{rebin_abs} -> focus;
				 return (-1, $prior_string);
			       };
			     };
			     if (($rebin{do_rebin}) and (lc($rebin{abs}) !~ /^$Ifeffit::Files::elem_regex$/)) {
			       my $dialog =
				 $raw -> Dialog(-bitmap         => 'error',
						-text           => "Your absorber, $rebin{abs}, is not a valid element symbol.  The on-the-fly rebinning cannot continue.",
						-title          => 'Athena: Problem with rebinning parameters',
						-buttons        => ['Go back', 'Import without rebinning'],
						-default_button => 'Go back',
						-popover        => 'cursor');
			       my $response = $dialog->Show();
			       if ($response eq 'Go back') {
				 $widg{ok} -> configure(-state=>'normal');
				 $raw->raise;
				 $widget{rebin_abs} -> focus;
				 return (-1, $prior_string);
			       };
			     };
			     $preprocess{raised} = $widg{extras}->raised();
			     $colsel_geometry = $raw->geometry;
			     $$prior_args{old}	       = $energy;
			     $$prior_args{numerator}   = \%numerator;
			     $$prior_args{denominator} = \%denominator;
			     $$prior_args{do_ln}       = $do_ln;
			     $$prior_args{invert}      = $invert;
			     $$prior_args{space}       = $space;
			     $$prior_args{evkev}       = $evkev;
			     $$prior_args{is_xmudat}   = $is_xmudat;
			     $$prior_args{sort}	       = $sort;
			     $$prior_args{multi}       = $multi;
			     my $ret = &construct_xmu($raw, $group, $label,
						      $data, $stash, $prior_args
						     );
			     $$prior_args{ref}	       = \%reference;
			     if ($ret < 0) {$$r_cancel = 1; $raw->destroy;
					    return (-1, $col_string)};
			     $widg{ok} -> configure(-state=>'normal') if ($ret == 0);
			   })
    -> pack(-expand=>1, -fill=>'x', -pady=>2, -side=>'left');
  $fr -> Button(-text=>'Cancel', @button_list,
		-command=>sub{$colsel_geometry = $raw->geometry;
			      $$r_cancel = 1; $raw->destroy; return (-1, $prior_string)})
    -> pack(-expand=>1, -fill=>'x', -pady=>2, -side=>'right');


  ## setup the display of the data file text
  my $h = $left->height();
  $databox = $right -> Scrolled(qw/ROText -relief sunken -borderwidth 2
				-wrap none -scrollbars se -width 50/,
				-font=>$config{fonts}{fixed})
    -> pack(-expand=>1, -fill=>'both', -padx=>4, -pady=>2);
  $databox -> tagConfigure("text", -font=>$config{fonts}{fixedsm});
  $widg{databox} = $databox;
  BindMouseWheel($databox);
  $databox->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
  $databox->Subwidget("yscrollbar")->configure(-background=>$config{colors}{background});
  my $to_display = ($is_binary) ? $stash : $data;
  open F, $to_display or die "Could not open $to_display\n";
  while (<F>) {
    s/\r//;
    $databox -> insert('end', $_, 'text');
  };
  close F;
  ## display the multi-element button properly
  my $sum;
  foreach my $v (values %numerator) {$sum += $v};
  $widg{multi} -> configure(-state=>($sum > 1)?'normal':'disabled');


  ## show the reference dialog if the reference channels are set, which only
  ## happens if this is similar to the prior data and the prior had reference
  ## channels
  ## print Data::Dumper->Dump([\%reference], [qw(*reference)]);
  if ($reference{numerator} or $reference{denominator}) {
    $reference{preproc_state} = $preproc_state;
    ##$widg{extra_button} -> packForget;
    $top -> update; # needed so $raw resizes correctly
    $widg{extras} -> pack(-pady=>2, -expand=>1, -fill=>'x');
    $right->pack(-expand=>1, -fill=>'both', -side=>'right', -anchor=>'n');
    $databox->pack(-expand=>1, -fill=>'both', -padx=>4, -pady=>2);
    #$widg{extras} -> raise('reference');
    $$prior_args{extra_shown} = 1;
  };

  $widg{ok} -> focus;
  ##$raw -> raise;
  $raw -> grab;
  ##$top -> update;
  ##$update -> grabRelease;
  $$prior_args{old}	     = $energy;
  $$prior_args{numerator}    = \%numerator;
  $$prior_args{denominator}  = \%denominator;
  $$prior_args{do_ln}	     = $do_ln;
  $$prior_args{invert}	     = $invert;
  $$prior_args{space}	     = $space;
  $$prior_args{evkev}	     = $evkev;
  $$prior_args{is_xmudat}    = $is_xmudat;
  $$prior_args{sort}	     = $sort;
  $$prior_args{multi}	     = $multi;
  $$prior_args{ref}	     = \%reference;
  return ($raw, $col_string);
};


sub column_string {
  my $col_string = q{};
  my $i = 1;
  my $this = Ifeffit::get_string('$column_label'.$i);
  while ($this !~ m{^\s*$}) {
    $col_string .= $this . ' ';
    ++$i;
    $this = Ifeffit::get_string('$column_label'.$i)
  };
  # $col_string =~ s{^nergy}{energy}i;
  return $col_string;
};

## this suppresses a nattering message that warns, in cryptic fashion,
## when you attempt to read a non-zip file as a zip file.  since that
## is the only way to test for zippiness of a file using Archive::Zip,
## simply suppressing the message seems appropriate.
sub is_zip_error_handler { 1; };



## $w takes the column selection Toplevel or 0 if this is a repeated file
sub construct_xmu {
  my ($w, $group, $label, $file, $stash, $prior_args) = @_;
    #$en, $rn, $rd, $ln, $inv, $space, $evkev, $is_xmudat, $sort, $multi, $reference, $sorted) = @_;
  #print join(" ", $group, $file, $en, $rn, $rd, $ln, $space, $evkev,
  #	     $is_xmudat, $sort, $multi), $/;

  my $en	 = $$prior_args{old};	       # 0
  my $rn	 = $$prior_args{numerator};    # 1
  my $rd	 = $$prior_args{denominator};  # 2
  my $ln	 = $$prior_args{do_ln};	       # 3
  my $inv	 = $$prior_args{invert};       # 4
  my $space	 = $$prior_args{space};	       # 5
  my $evkev	 = $$prior_args{evkev};	       # 6
  my $is_xmudat	 = $$prior_args{is_xmudat};    # 7
  my $sort	 = $$prior_args{sort};	       # 8
  my $multi	 = $$prior_args{multi};	       # 9
  my $reference	 = $$prior_args{ref};	       # 10
  my $sorted	 = $$prior_args{sorted};       # 11

  #print join(" ", %$reference), $/;
  unless (($group) and ($en) and ($rd) and ($rn)) {
    ($w == 0) or $w -> destroy();	# get rid of column palette
    Echo("Group undefined!"),            return 0 unless $group;
    Echo("Energy array undefined!"),     return 0 unless $en;
    Echo("Numerator hash undefined!"),   return 0 unless $rn;
    Echo("Denominator hash undefined!"), return 0 unless $rd;
  };
  ## must take care when reading multiple files that the arguments
  ## from the previous run have the current group name substituted
  ## in. The following regex is unnecessary (but not incorrect) when
  ## reading a single data file, but is essential when reading a set
  ## of data files
  ##
  ## The regex is anything that is not an alphanumeric, an underscore,
  ## or a question mark then followed by a dot, but the dot is matched
  ## by a non-consuming look-ahead, so it does not get substituted
  ##
  ## Matt sez (mail 17 Jan. 2003) "the first character for scalars and
  ## group prefix must be 'a-z_&', and 'a-z0-9_&' for group suffixes,
  ## and that subsequent characters can be any of 'a-z0-9_&:?@~' ".  I
  ## am actually only using _ and ? as nonalphanumerics
  $en =~ s/[A-Za-z0-9_?]+(?=\.)/$group/g;
  $space = lc($space);
  $evkev = lc($evkev);
  ($evkev =~ /(kev|pixel)/) or ($evkev = 'ev');
  ($is_xmudat)     and ($space = 'e');  # n for normalizaed
  ($space eq 'c')  and ($space = 'k');
  ($space eq 'k')  and ($evkev = '');
  #$prior_args = [$en, $rn, $rd, $ln, $inv, $space, $evkev, $is_xmudat, $sort, $multi, $reference, $sorted];
  ($w == 0) or $w -> grabRelease; # column palette gives up grab
  ($label .= "_pixel") if ($evkev eq 'pixel');


  my ($str, $num, $den, $i0) =  make_xmu_string($rn, $rd, $ln, $inv, 0);
  if (($str eq "1") or ($str eq "ln(abs(1))")) {
    my $message = "You have not selected any data columns!";
    my $dialog =
      $w -> Dialog(-bitmap         => 'questhead',
		   -text           => $message,
		   -title          => 'Athena: oops!',
		   -buttons        => [qw/OK/],
		   -default_button => 'OK');
    my $response = $dialog->Show();
    #$w -> raise();
    $top -> update;
    return 0;
  };

  unless ($num) {
    #($w == 0) or $w -> destroy();	# get rid of column palette
    Echo("Data string was not selected.") and return 0;
  };
  ## clean up the strings to use  the current group's group name
  $str =~ s/[A-Za-z0-9_?]+(?=\.)/$group/g; # same regex as above
  $num =~ s/[A-Za-z0-9_?]+(?=\.)/$group/g;
  $den =~ s/[A-Za-z0-9_?]+(?=\.)/$group/g;
  $i0  =~ s/[A-Za-z0-9_?]+(?=\.)/$group/g;
  my $was_backwards = 0;	            # Ifeffit::Files->backwards_data($group, $en);
  my ($isnt_monotonic, @points)  = Ifeffit::Files->monotonic_data($group, $en, $evkev); # (0, ());
  if ($isnt_monotonic) {
    my $xaxis = "energy";
    ($space eq 'k') and ($xaxis = "wavenumber");
    my $response = "";
#     if ($sorted) {
#       $response = $sorted;
#     } else {
#       my $message = "This file:\n\n  $file\n\n";
#       $message   .= "contains data that are not monotonically increasing in $xaxis.\n";
#       if ($#points) {
# 	$message   .= "(check data points " . join(", ", @points) . ")";
#       } else {
# 	$message   .= "(check data point $points[0])";
#       };
#       $message   .= "\n\n\nAthena cannot import data in this state.";
#       $message   .= " You may sort these data by $xaxis,";
#       $message   .= " discarding repeated points,";
#       $message   .= " or you may simply cancel the import of these data.";
#       my $dialog =
# 	$top -> Dialog(-bitmap         => 'warning',
# 		       -text           => $message,
# 		       -title          => 'Athena: Non-monotonic data file',
# 		       -buttons        => ['Sort data', 'Cancel'],
# 		       -default_button => 'Sort data');
#       ($w == 0) or $w -> lower; # the dialog sometimes is hard to see on the screen!
#       $response = $dialog->Show(-popover    => 'cursor'  );
#     };
    $response = "Sort data";
    if ($response eq 'Cancel') { # discard non-monotonic data
      #($w == 0) or $w -> destroy();	# get rid of column palette
      $setup -> dispose("erase \@group $group");
      Echo("Canceling import of \"$file\"");
      return -1;
    } else {			# fix non-monotonic data
      $$prior_args{sorted} = $response;
      Echo("Sorting data for $label");

      ## This block is a complicated bit.  The idea is to store all
      ## the data in a list of lists.  In this way, I can sort all the
      ## data in one swoop by sorting off the energy part of the list
      ## of lists.  After sorting, I check the data for repeated
      ## points and remove them.  Finally, I reload the data into
      ## ifeffit and carry on like normal data

      ## This gets a list of column labels
      my @cols = split(" ", &column_string);
      my @lol;
      ## energy value is zeroth in each anon list
      my @array = get_array("$en");
      map {push @{$lol[$_]}, $array[$_]} (0 .. $#array);
      foreach my $c (@cols) {
	## load other cols (including energy col) into anon. lists
	my @array = get_array("$group.$c");
	map {push @{$lol[$_]}, $array[$_]} (0 .. $#array);
      };
      ## sort the anon. lists by energy (i.e. zeroth element)
      @lol = sort {$a->[0] <=> $b->[0]} @lol;

      ## now fish thru lol looking for repeated energy points
      my $ii = 0;
      while ($ii < $#lol) {
	($lol[$ii+1]->[0] > $lol[$ii]->[0]) ? ++$ii : splice(@lol, $ii+1, 1);
      };

      ## now feed columns back to ifeffit
      foreach my $c (0 .. $#cols) {
	my @array;
	map {push @array, $_->[$c+1]} @lol;
	$setup->dispose("erase $group.$cols[$c]", $dmode);
	Ifeffit::put_array("$group.$cols[$c]", \@array);
      };
      $setup->dispose("## Athena reloaded arrays after sorting non-monotonic data\n", $dmode);
    };
  };
  ## for multi-element data fed to separate groups -- loop over
  ## channels.  For all other data, this is a "loop" over a list 1
  ## item long
  my @channel_list = ($num);
  if ($multi) {
    (my $channels = $num) =~ s/[()]//g;
    @channel_list = split(/\s*\+\s*/, $channels);
  };
  foreach my $c (@channel_list) {
    my $this_str = $str;
    my $grp = $group;
    if ($multi) {
      my $suff = (split(/\./, $c))[1];
      ($grp, $label) = group_name(basename($file) . "_" . $suff);
      ($this_str, my $num, my $den, my $i0) =  make_xmu_string({$c => 1}, $rd, $ln, $inv, 0);
    }

    ++$line_count;
    $i0 =~ s/[\(\)]//g;
    $groups{$grp} = Ifeffit::Group -> new(group=>$grp, label=>$label,
					  is_rsp=>0, is_qsp=>0, line=>$line_count,
					  is_rec=>0, file=>$file, en_str=>$en, mu_str=>$this_str,
					  is_raw=>1, numerator=>$c, denominator=>$den,
					  i0=>$i0);

    $groups{$grp} -> dispose("\n## Importing a new file\n");
    if ($sort_available) {
      if ($isnt_monotonic and (not $is_xmudat)) {
	$groups{$grp} ->
	  dispose("## uncomment the following line in a macro to have ifeffit sort the data\n", $dmode);
	$groups{$grp} ->
	  dispose("## read_data(file=\"$stash\", group=$grp, sort=$sort)\n", $dmode);
      };
    };

    if ($space =~ /[enx]/) {
      $groups{$grp} -> make(is_xmu=>1, is_chi=>0, is_xmudat=>$is_xmudat);
      ($space =~ /[nx]/) and ($groups{$grp} -> make(is_nor=>1));
      if ($evkev eq 'ev') {
	$groups{$grp} -> dispose("set $grp.energy = $en\n", $dmode);
      } elsif ($evkev eq 'pixel') {
	$groups{$grp} -> make(is_pixel=>1);
	$groups{$grp} -> dispose("set $grp.energy = $en\n", $dmode);
      } else {			# keV
	$groups{$grp} -> dispose("set $grp.energy = 1000*$en\n", $dmode);
      };
      $rebin{do_rebin} and perform_rebinning($grp);
      if (length($this_str) < 251) {
	$groups{$grp} -> dispose("set $grp.xmu = $this_str\n", $dmode);
      } else {
	&long_string($grp, "$grp.xmu", $this_str);
      };
    } elsif ($space =~ /[ck]/) {
      $groups{$grp} -> make(is_xmu=>0, is_chi=>1);
      $groups{$grp} -> dispose("set $grp.k = $en\n", $dmode);
      $groups{$grp} -> dispose("set $grp.chi = $this_str\n", $dmode);
      if (($space eq 'k') and (not Ifeffit::Files->uniform_k_grid($grp))) {
	$setup->dispose("## this seems to be chi(k) data in need of fixing...\nfix_chik($grp)",
			$dmode);
      };
    } elsif ($space eq 'd') {
      $groups{$grp} -> make(not_data=>1, is_xmu=>0, is_chi=>0, is_rsp=>0, is_qsp=>0);
      if ($evkev eq 'ev') {
	$groups{$grp} -> dispose("set $grp.energy = $en\n", $dmode);
      } elsif ($evkev eq 'pixel') {
	$groups{$grp} -> make(is_pixel=>1);
	$groups{$grp} -> dispose("set $grp.energy = $en\n", $dmode);
      } else {
	$groups{$grp} -> dispose("set $grp.energy = 1000*$en\n", $dmode);
      };
      $rebin{do_rebin} and perform_rebinning($grp);
      if (length($this_str) < 251) {
	$groups{$grp} -> dispose("set $grp.det = $this_str\n", $dmode);
      } else {
	&long_string($grp, "$grp.det", $this_str);
      };
    } elsif ($space eq 'a') {
      $groups{$grp} -> make(not_data=>0, is_xmu=>1, is_xanes=>1,
			    is_chi=>0, is_rsp=>0, is_qsp=>0, bkg_nnorm=>2);
      if ($evkev eq 'ev') {
	$groups{$grp} -> dispose("set $grp.energy = $en\n", $dmode);
      } elsif ($evkev eq 'pixel') {
	$groups{$grp} -> make(is_pixel=>1);
	$groups{$grp} -> dispose("set $grp.energy = $en\n", $dmode);
      } else {
	$groups{$grp} -> dispose("set $grp.energy = 1000*$en\n", $dmode);
      };
      $rebin{do_rebin} and perform_rebinning($grp);
      if (length($this_str) < 251) {
	$groups{$grp} -> dispose("set $grp.xmu = $this_str\n", $dmode);
      } else {
	&long_string($grp, "$grp.xmu", $this_str);
      };
    };

    set_defaults($grp, $space, $is_xmudat);
    $preprocess{ok}  and perform_preprocessing($grp);

    fill_skinny($list, $grp, 1);
    if ($$reference{numerator} or $$reference{denominator}) {
      Echo("Importing reference channel for $label ...");
      my ($ref, $ref_label) = group_name("   Ref " . $label);
      $groups{$grp} -> make(reference=>$ref);
      ++$line_count;
      $$reference{numerator}   ||= 1;
      $$reference{denominator} ||= 1;
      $this_str = join("/", $$reference{numerator}, $$reference{denominator});
      ($this_str = "ln(abs($this_str))") if $$reference{ln};
      $this_str =~ s/[A-Za-z0-9_?]+(?=\.)/$grp/g; # same regex as above
      $groups{$ref} = Ifeffit::Group -> new(group	=> $ref,
					    label	=> $ref_label,
					    is_xmu	=> 1,
					    is_chi	=> 0,
					    is_nor	=> 0,
					    is_rsp	=> 0,
					    is_qsp	=> 0,
					    is_rec	=> 0,
					    is_raw	=> 1,
					    en_str	=> $en,
					    mu_str	=> $this_str,
					    numerator	=> $$reference{numerator},
					    denominator	=> $$reference{denominator},
					    reference	=> $grp,
					    is_ref      => 1,
					    bkg_eshift	=> $groups{$grp}->{bkg_eshift});
      $groups{$ref} -> make(bkg_eshift=>0) unless ($groups{$ref}->{bkg_eshift} =~ /-?(\d+\.?\d*|\.\d+)/);
      $groups{$ref} -> make(line => $line_count,
			    file => "reference channel for " . $groups{$grp}->{label});
      $groups{$ref} -> set_to_another($groups{$grp});

      if ($$reference{same}) {
	$groups{$grp} -> make(refsame=>1);
	$groups{$ref} -> make(bkg_z=>$groups{$grp}->{bkg_z},
			      fft_edge=>$groups{$grp}->{fft_edge},
			      refsame=>1,
			     );
      };
      $groups{$ref} -> dispose("set $ref.energy = $grp.energy\n", $dmode);
      $groups{$ref} -> dispose("set $ref.xmu = $this_str\n", $dmode);
      $groups{$ref} -> dispose("pre_edge($ref.energy, $ref.xmu)\n", $dmode);
      $groups{$ref} -> make(bkg_e0   => Ifeffit::get_scalar("e0"),
			    is_xanes => $groups{$grp}->{is_xanes});
      if (not $$reference{same}) {
	$groups{$grp} -> make(refsame=>0);
	my ($z, $edge) = find_edge($groups{$ref}->{bkg_e0});
	$groups{$ref} -> make(bkg_z=>$z,
			      fft_edge=>$edge,
			      refsame=>0,
			     );
      };
      fill_skinny($list, $ref, 1);
      Echo("Importing reference channel for $label ... done!");
    };
    clean_unused_columns($grp, $en, $num, $den);

    my $stan = $preprocess{standard};
    if ($preprocess{al_do} and ($stan !~ /None/) and exists($groups{$stan})) {
      my $eshift;
      if ($groups{$stan}->{reference} and $groups{$grp}->{reference}) {
	$groups{$grp} -> dispose("## Aligning $groups{$grp}->{label} using reference", $dmode);
	Echo("Aligning $groups{$grp}->{label} using reference");
	$eshift = auto_align($groups{$stan}->{reference}, $groups{$grp}->{reference}, 'd');
      } else {
	$groups{$grp} -> dispose("## Aligning $groups{$grp}->{label} using data", $dmode);
	Echo("Aligning $groups{$grp}->{label} using data", 0);
	$eshift = auto_align($stan, $grp, 'd');
      };
      $groups{$grp} -> dispose("## need to re-get e0 after doing the preprocessing auto-alignment...\npre_edge(\"$grp.energy+$eshift\", $grp.xmu)\n", $dmode);
      $groups{$grp} -> make(bkg_e0 => Ifeffit::get_scalar("e0")) unless $preprocess{par_do};
      $groups{$grp} -> make(bkg_eshift => $eshift);
      my $ref = $groups{$grp}->{reference};
      if ($ref) {
	$groups{$ref} -> make(bkg_eshift => $eshift);
	$groups{$ref} -> dispose("pre_edge($ref.energy, $ref.xmu)\n", $dmode);
	$groups{$ref} -> make(bkg_e0   => Ifeffit::get_scalar("e0"));
      };
      push @{$preprocess{titles}}, "^^    alignment to $groups{$stan}->{label}";
    };

    ## marking proprocessing
    Echo("Marking $groups{$grp}->{label}", 0);
    ($marked{$grp} = 1) if $preprocess{mark_do};

    ## capture title lines from the data file and from the extra import features
    $groups{$grp} -> get_titles;
    foreach (@{$rebin{titles}}) {
      push @{$groups{$grp}->{titles}}, $_;
    };
    foreach (@{$preprocess{titles}}) {
      push @{$groups{$grp}->{titles}}, $_;
    };
    push @{$groups{$grp}->{titles}}, "^^ Imported with reference channel"
      if ($$reference{numerator} or $$reference{denominator});

    my @titles = ();
    foreach (@{$groups{$grp}->{titles}}) {
      next if ($_ =~ /^\s*$/);
      my $count = 0;
      foreach my $i (0..length($_)) {
	++$count if (substr($_, $i, 1) eq '(');
	--$count if ($count and (substr($_, $i, 1) eq ')'));
      };
      ## close all unmatched parens by appending close_parens to the string
      $_ .= ')' x $count;
      ## ! % and # in title lines seem to be a problem on Windows
      $_ =~ s/[!\%\#]//g;
      push @titles, $_;
    };
    $groups{$grp} -> make(titles=>\@titles);
    $groups{$grp} -> put_titles;

    ## and show some eye candy...
    set_properties(1, $grp,0);
    unless ($w == 0) {
      &set_key_params;
    SWITCH: {
	$groups{$grp} -> plotE('em',  $dmode,\%plot_features, \@indicator), last SWITCH if ($is_xmudat);
	$groups{$grp} -> plotE('em',  $dmode,\%plot_features, \@indicator), last SWITCH if ($space eq 'd');
	$groups{$grp} -> plotE('em',  $dmode,\%plot_features, \@indicator), last SWITCH if ($space eq 'a');
	$groups{$grp} -> plotE('emz', $dmode,\%plot_features, \@indicator), last SWITCH if ($space eq 'e');
	$groups{$grp} -> plotE('emzn',$dmode,\%plot_features, \@indicator), last SWITCH if ($space eq 'n');
	$groups{$grp} -> plotk('k1',  $dmode,\%plot_features, \@indicator), last SWITCH if ($space eq 'k');
      };
      $last_plot = $space;
      ($last_plot = 'e') if (($space eq 'a') or ($space eq 'n'));
      $plotsel->raise($last_plot) unless ($plotsel->raised() =~ /(Stack|Ind|PF)/);
      my $pl_str = 'emz';
      if ($space =~ /k/) {
	$pointfinder{space} -> configure(-text=>"The last plot was in k");
      } else {
	$pointfinder{space} -> configure(-text=>"The last plot was in Energy");
      };
      foreach (qw(x xpluck xfind y ypluck clear)) {
	$pointfinder{$_} -> configure(-state=>'normal');
      };
      ($space eq 'k') and ($pl_str = 'k1');
      ($space eq 'n') and ($pl_str = 'emzn');
      ($is_xmudat)    and ($pl_str = 'em');
      $last_plot_params = [$grp, 'group', $space, $pl_str];
      ## this seems to be necessary...
      ($is_xmudat)    and $groups{$grp}->make(update_bkg=>1);
    }; # end of plotting SWITCH
    unless ($config{fft}{kmax}){
      $groups{$grp} -> dispose("___x = ceil($groups{$grp}->{group}.k)\n", 1);
      $groups{$grp} -> make(fft_kmax=>Ifeffit::get_scalar("___x"));
      $groups{$grp} -> kmax_suggest(\%plot_features);
    };

  }; # end of loop over data channels
  ($w == 0) or $w -> destroy();	# get rid of column palette

  $was_backwards and
    Echo("Notice: Athena had to reverse the data in this file as it was in descending order");
  return 1;
};

## construct the string that tells ifeffit how to make mu(E) out of
## columns of data
sub make_xmu_string {
  my ($rn, $rd, $ln, $inv, $en) = @_;
  my $num = "(";                               # build the numerator string:
  map {$$rn{$_} and ($num .= $_ . " + ")} (sort keys %$rn);
  $num = substr($num, 0, -3) . ")";
  ($num eq ')') and ($num = "1");
  my $str = $num;
  my $den = "(";			       # build the denominator string:
  map {$$rd{$_} and ($den .= $_ . " + ")} (sort keys %$rd);
  $den = substr($den, 0, -3) . ")";
  ($den eq ')') and ($den = "");
  ($den) and $str .= " / " . $den;
  ($ln) and ($str = "ln(abs(" . $str . "))");  # transmission data
  ($inv) and ($str = "-1*" . $str);	       # invert

  ## autoplot as columns are selected
  if ($en and $config{general}{autoplot}) {
    &set_key_params;
    my $command = "\n## Autoplot in the file selection dialog:\n";
    $command   .= "set t___oss.y = $str\n";
    $command   .= "newplot(x=$en, y=t___oss.y, ";
    $command   .= "color=$config{plot}{c0}, title=\"current column selection\", xlabel=x, ylabel=y)\n";
    $command   .= "erase \@group t___oss\n";
    $groups{"Default Parameters"}->dispose($command, $dmode);
  };
  my $i0 = ($ln) ? $num : $den;
  ($i0 = "") unless $den;

  ## return full string, numerator part, denominator part
  return ($str, $num, $den, $i0);
};


## deal with a very long string as the expression for setting a vector
## assume it is of the form (a + b + c + ...) / i0
sub long_string {
  my ($g, $xmu, $string) = @_;
  my ($num, $den) = split(/\s*\/\s*/, $string);
  $num =~ s/[()]//g;
  my @channels = split(/\s*\+\s*/, $num);
  $groups{$g} -> dispose("set ___npts = npts($g.energy)", $dmode);
  $groups{$g} -> dispose("set $xmu = zeros(___npts)", $dmode);
  foreach my $ch (@channels) {
    $groups{$g} -> dispose("set $xmu = $xmu + $ch/$den", $dmode);
  };
};

sub clean_unused_columns {
  my ($group, $en, $num, $den) = @_;
  my @col_string = split(" ", &column_string);
  my @words = split(/[() \t+]+/, $num);
  push @words, split(/[() \t+]+/, $den);
  if ($groups{$group}->{reference}) {
    my $str = $groups{$groups{$group}->{reference}}->{numerator};
    push @words, split(/[() \t+]+/, $str);
    $str = $groups{$groups{$group}->{reference}}->{denominator};
    push @words, split(/[() \t+]+/, $str);
  };
  my @used = ((split(/\./,$en))[1]); # put energy suffix in the list
  foreach my $w (@words) {	     # of used columns
    next if ($w =~ /^\s*$/);
    push @used, (split(/\./, $w))[1]; # put suffixes used in numerator
  };				      # and denominator in list
  ## see Perl Cookbook recipe 4.7 p. 104
  my %seen;          # lookup table
  my @csonly;        # only in @col_string
  @seen{@used} = (); # perl-y magic!
  foreach my $i (@col_string) {
    push(@csonly, $i) unless exists $seen{$i};
  };
  ## print "col_string: ", join(" ", @col_string), $/;
  ## print "used: ", join(" ", @used), $/;
  ## print "unused: ", join(" ", @csonly), $/;
  foreach my $suff (@csonly) {	# erase the unused columns
    $groups{$group} -> dispose("erase $group.$suff", $dmode);
  };
};


## open a Toplevel with a palette for setting preprocessing
## parameters, including parameters for deglitching, truncating,
## interpolating, and aligning data sets as they are read in.  A
## standard, i.e. a record already read in, must be chosen for all
## these actions.
sub set_preprocessing {
  my $widg = $_[0];
  my $ppp = $$widg{pre_card};
  my $parent = $ppp -> Frame(-borderwidth=>0, -relief=>'flat');
  my $how_many = scalar(keys %groups);

  ## set some variables
  my $red = $config{colors}{single};
  my $blue= $config{colors}{activehighlightcolor};
  my $grey= '#9c9583';
  #my $pre = $top->Toplevel(-class=>'horae');
  #$pre -> title('Athena: preprocess data');
  my (%widgets, %labels, %grab);

  $parent -> Label(-text=>'Preprocessing parameters',
		   -font=>$config{fonts}{bold},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-pady=>3);
  ## choose a standard
  my $frame = $parent -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');

  my $exists = 0;
  foreach my $k (&sorted_group_list) { $exists = 1, last if ($k eq $preprocess{standard}); };
  $exists or (($preprocess{standard},$preprocess{standard_lab})  = ('None','0: None'));
  $preprocess{ok} = ($preprocess{standard} eq 'None') ? 0 : 1;
  my $initial_state = ($preprocess{standard} eq 'None') ? 'disabled' : 'normal';
  $frame -> Label(-text=>'Standard', -foreground=>$config{colors}{activehighlightcolor})
    -> pack(-side=>'left');

  $preprocess{keys} = ['None', &sorted_group_list];
  $widgets{standard} = $frame -> BrowseEntry(-variable => \$preprocess{standard_lab},
					     @browseentry_list,
					     -browsecmd => sub {
					       my $text = $_[1];
					       my $this = $1 if ($text =~ /^(\d+):/);
					       #Echo("Failed to match in browsecmd.  Yikes!  Complain to Bruce."), return unless $this;
					       #$this -= 1;
					       $preprocess{standard} = $preprocess{keys}->[$this];
					       #if ($this == 0) { # choose None
					       if ($preprocess{standard} eq 'None') { # choose None
						 foreach (keys %widgets) {
						   $preprocess{ok} = 0;
						   next if ($_ eq 'standard');
						   next if ($_ =~ /^int/);
						   #next if ($_ eq 'deg_check');
						   #next if ($_ eq 'trun_check');
						   next if ($_ =~ /^(deg|mark|trun)/);
						   $widgets{$_}->configure(-state=>'disabled');
						   ($_ =~ /check$/) or
						     ($widgets{$_}->configure(-foreground=>$grey));
						 };
						 foreach (keys %labels) {
						   next if ($_ =~ /^(deg|mark|trun)/);
						   $labels{$_}->configure(-foreground=>$grey);
						 };
						 foreach (keys %grab) {
						   next if ($_ =~ /^(deg|trun)/);
						   $grab{$_}->configure(-state=>'disabled');
						 };
						 foreach (qw(deg_do trun_do int_do al_do par_do)) {
						   $preprocess{$_} = 0;
						 };
					       } else {	# choose a group
						 my $x = $preprocess{standard};
						 $preprocess{ok} = 1;
						 $widgets{mark_check}-> configure(-state=>'normal');
						 $widgets{deg_check} -> configure(-state=>'normal');
						 $widgets{trun_check}-> configure(-state=>'normal');
						 #$widgets{int_check}-> configure(-state=>'normal');
						 $widgets{al_check}  -> configure(-state=>'normal');
						 $widgets{par_check} -> configure(-state=>'normal');
						 $groups{$x}->dispose("___x = ceil($x.energy)\n", 1);
						 my $minE = $groups{$x}->{bkg_nor1}+$groups{$x}->{bkg_e0};
						 my $maxE = Ifeffit::get_scalar("___x");
						 my $toler = sprintf("%.4f", $groups{$x}->{bkg_step} * $config{deglitch}{margin});
						 $preprocess{deg_emin} = $groups{$x}->{deg_emin} || $minE;
						 $preprocess{deg_emax} = $groups{$x}->{deg_emax} || $maxE+$config{deglitch}{emax};
						 $preprocess{deg_tol}  = ($groups{$x}->{deg_tol} > 0) ? $groups{$x}->{deg_tol} : $toler;
						 $preprocess{trun_e}   = $maxE;
						 $preprocess{al_emin}  = -50;
						 $preprocess{al_emax}  = 150;
						 $groups{$x} -> make(deg_emin=>$minE, deg_emax=>$maxE, deg_tol=>$toler);
						 &set_key_params;
						 $groups{$x} -> plotE('emtg',$dmode);
						 $groups{$x} -> dispose("___x = floor($x.xmu)\n", 1);
						 $preprocess{ymin} = 0.95 * Ifeffit::get_scalar("___x");
						 $groups{$x} -> dispose("___x = ceil($x.xmu)\n", 1);
						 $preprocess{ymax} = 1.05 * Ifeffit::get_scalar("___x");
						 $groups{$x} -> plot_vertical_line($preprocess{trun_e}, $preprocess{ymin},
										   $preprocess{ymax}, $dmode, "truncate",
										   $groups{$x}->{plot_yoffset});
						 if ($preprocess{trun_do}) {
						   $widgets{"pp_trun_".$_} -> configure(-state=>'normal') foreach (qw(e beforeafter));
						   $grab{pp_trun_e}->configure(-state=>'normal');
						   $labels{trun_e}->configure(-foreground=>$blue);
						   $widgets{pp_trun_e}->configure(-foreground=>'black');
						 };
						 if ($preprocess{deg_do}) {
						   foreach (qw(deg_emin deg_emax deg_tol)) {
						     $labels{$_}->configure(-foreground=>$blue);
						     $widgets{$_}->configure(-state=>'normal',
									     -foreground=>'black');
						     $grab{'pp_'.$_}->configure(-state=>'normal');
						   };
						 };
					       };
					     })
    -> pack(-side=>'right', -expand=>1, -fill=>'x', -padx=>1);
  my $i = 1;
  $widgets{standard} -> insert("end", "0: None");
  foreach my $s (&sorted_group_list) {
    $widgets{standard} -> insert("end", "$i: $groups{$s}->{label}");
    ++$i;
  };

##   $widgets{standard} = $frame -> Optionmenu(-textvariable => \$preprocess{standard_lab},
## 					    -borderwidth=>1, )
##     -> pack(-side=>'right', -expand=>1, -fill=>'x', -padx=>1);
##   $widgets{standard} -> command(-label => 'None',
## 				-command=>sub{$preprocess{standard}='None';
## 					      $preprocess{standard_lab}='0: None';
## 					      foreach (keys %widgets) {
## 						$preprocess{ok} = 0;
## 						next if ($_ eq 'standard');
## 						next if ($_ =~ /^int/);
## 						#next if ($_ eq 'deg_check');
## 						#next if ($_ eq 'trun_check');
## 						next if ($_ =~ /^(deg|trun)/);
## 						$widgets{$_}->configure(-state=>'disabled');
## 						($_ =~ /check$/) or
## 						  ($widgets{$_}->configure(-foreground=>$grey)); };
## 					      foreach (keys %labels) {
## 						next if ($_ =~ /^(deg|trun)/);
## 						$labels{$_}->configure(-foreground=>$grey); };
## 					      foreach (keys %grab) {
## 						next if ($_ =~ /^(deg|trun)/);
## 						$grab{$_}->configure(-state=>'disabled'); };
## 					      foreach (qw(deg_do trun_do int_do al_do par_do)){
## 						$preprocess{$_} = 0; };
## 					    });
##   foreach my $x (&sorted_group_list) {
##     $widgets{standard} ->
##       command(-label => $groups{$x}->{label},
## 	      -command=>
## 	      sub{		# set preprocess parameters based on this group
## 		$preprocess{standard}=$x;
## 		$preprocess{standard_lab}=$groups{$x}->{label};
## 		$preprocess{ok} = 1;
## 		$widgets{deg_check}->configure(-state=>'normal');
## 		$widgets{trun_check}->configure(-state=>'normal');
## 		#$widgets{int_check}->configure(-state=>'normal');
## 		$widgets{al_check}->configure(-state=>'normal');
## 		$widgets{par_check}->configure(-state=>'normal');
## 		$groups{$x}->dispose("___x = ceil($x.energy)\n", 1);
## 		my $minE = $groups{$x}->{bkg_nor1}+$groups{$x}->{bkg_e0};
## 		my $maxE = Ifeffit::get_scalar("___x");
## 		my $toler = sprintf("%.4f", $groups{$x}->{bkg_step} * $config{deglitch}{margin});
## 		$preprocess{deg_emin} = $groups{$x}->{deg_emin} || $minE;
## 		$preprocess{deg_emax} = $groups{$x}->{deg_emax} || $maxE+$config{deglitch}{emax};
## 		$preprocess{deg_tol}  = ($groups{$x}->{deg_tol} > 0) ? $groups{$x}->{deg_tol} : $toler;
## 		$preprocess{trun_e}   = $maxE;
## 		$preprocess{al_emin}  = -50;
## 		$preprocess{al_emax}  = 150;
## 		$groups{$x} -> make(deg_emin=>$minE, deg_emax=>$maxE, deg_tol=>$toler);
## 		&set_key_params;
## 		$groups{$x} -> plotE('emtg',$dmode);
## 		$groups{$x} -> dispose("___x = floor($x.xmu)\n", 1);
## 		$preprocess{ymin} = 0.95 * Ifeffit::get_scalar("___x");
## 		$groups{$x} -> dispose("___x = ceil($x.xmu)\n", 1);
## 		$preprocess{ymax} = 1.05 * Ifeffit::get_scalar("___x");
## 		$groups{$x} -> plot_vertical_line($preprocess{trun_e}, $preprocess{ymin},
## 						  $preprocess{ymax}, $dmode, "truncate",
## 						  $groups{$x}->{plot_yoffset});
## 		if ($preprocess{trun_do}) {
## 		  $widgets{"pp_trun_".$_} -> configure(-state=>'normal') foreach (qw(e beforeafter));
## 		  $grab{pp_trun_e}->configure(-state=>'normal');
## 		  $labels{trun_e}->configure(-foreground=>$blue);
## 		  $widgets{pp_trun_e}->configure(-foreground=>'black');
## 		};
## 		if ($preprocess{deg_do}) {
## 		  foreach (qw(deg_emin deg_emax deg_tol)) {
## 		    $labels{$_}->configure(-foreground=>$blue);
## 		    $widgets{$_}->configure(-state=>'normal',
## 					    -foreground=>'black');
## 		    $grab{'pp_'.$_}->configure(-state=>'normal');
## 		  };
## 		};
## 	      });
##   };

  ## mark? =====================================================
  my $outer = $parent -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{mark_check} = $frame -> Checkbutton(-text=>"Mark each data set when imported",
					       -foreground=>$config{colors}{activehighlightcolor},
					       -variable=>\$preprocess{mark_do},
					       -selectcolor=>$red,
					     )
    -> pack(-pady=>2, -side=>'left');


  ## truncate? =================================================
  #=$preprocess{trun_do} = 0;
  #=$preprocess{trun_e}  = 0;
  $outer = $parent -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{trun_check} = $frame -> Checkbutton(-text=>"Truncate each data set",
					       -foreground=>$config{colors}{activehighlightcolor},
					       -variable=>\$preprocess{trun_do},
					       -selectcolor=>$red,
					       -command=>sub{
						 $preprocess{ok} = 1;
						 my $stst = ($config{general}{autoplot}) ? 'normal' : 'disabled';
						 my ($color, $text, $state, $button) = $preprocess{trun_do} ?
						   ($blue, 'black', 'normal', $stst) :
						     ($grey, $grey, 'disabled', 'disabled');
						 $labels{trun_e}->configure(-foreground=>$color);
						 $widgets{pp_trun_e}->configure(-state=>$state,
										-foreground=>$text);
						 $grab{pp_trun_e}->configure(-state=>$button);
						 $widgets{pp_trun_beforeafter}->configure(-state=>$state);
					       })
    -> pack(-pady=>2, -side=>'left');
  # truncate emax
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $grab{pp_trun_e} = $frame -> Button(@pluck_button, @pluck,
				      -command=>sub{$last_plot ||= 'e';
						    pluck('pp_trun_e');
						    my $x = $preprocess{standard};
						    return unless exists $groups{$x};
						    $groups{$x} -> plotE('emtg',$dmode);
						    $groups{$x} -> plot_vertical_line($preprocess{trun_e}, $preprocess{ymin},
										      $preprocess{ymax}, $dmode, "truncate",
										      $groups{$x}->{plot_yoffset});
						  },)
    -> pack(-side=>'right');
  $widgets{pp_trun_e} = $frame->Entry(-width	    => 8,
				      -textvariable => \$preprocess{trun_e},
				      -foreground => $grey,)
    -> pack(-side=>'right');
  $widgets{pp_trun_beforeafter} = $frame -> Optionmenu(-variable=>\$preprocess{trun_beforeafter},
						       -textvariable=>\$preprocess{trun_beforeafter},
						       -borderwidth=>1,
						       -options=>['before', 'after'],)
    -> pack(-side=>'right');
  $labels{trun_e} = $frame -> Label(-text=>'Truncate ')
    -> pack(-side=>'right');

  ## deglitch? ===================================================
  #=$preprocess{deg_do}   = 0;
  #=$preprocess{deg_emin} = 0;
  #=$preprocess{deg_emax} = 0;
  #=$preprocess{deg_tol}  = 0;
  $outer = $parent -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{deg_check} = $frame -> Checkbutton(-text=>"Deglitch each data set",
					      -foreground=>$config{colors}{activehighlightcolor},
					      -variable=>\$preprocess{deg_do},
					      -selectcolor=>$red,
					      -command=>sub{
						$preprocess{ok} = 1;
						my $stst = ($config{general}{autoplot}) ? 'normal' : 'disabled';
						my ($color, $text, $state, $button) = $preprocess{deg_do} ?
						  ($blue, 'black', 'normal', $stst) :
						    ($grey, $grey, 'disabled', 'disabled');
						foreach (qw(deg_emin deg_emax deg_tol)) {
						  $labels{$_}->configure(-foreground=>$color);
						  $widgets{$_}->configure(-state=>$state,
									  -foreground=>$text);
						  next if ($_ eq 'deg_tol');
						  $grab{'pp_'.$_}->configure(-state=>$button);
						};
					      })
    -> pack(-pady=>2, -side=>'left', -anchor=>'w');
  # deglitch emin
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $grab{pp_deg_emin} = $frame -> Button(@pluck_button, @pluck,
					-command=>sub{$last_plot ||= 'e';
						      pluck('pp_deg_emin');
						      my $x = $preprocess{standard};
						      return unless $x;
						      $groups{$x} -> make(deg_emin=>$preprocess{deg_emin});
						      $groups{$x} -> plotE('emtg',$dmode);
						      $groups{$x} -> plot_vertical_line($preprocess{trun_e}, $preprocess{ymin},
											$preprocess{ymax}, $dmode, "truncate",
											$groups{$x}->{plot_yoffset});
					},)
    -> pack(-side=>'right');
  $widgets{deg_emin} = $frame->Entry(-width=>8, -textvariable=>\$preprocess{deg_emin},
				     -foreground=>$grey)
    -> pack(-side=>'right');
  $labels{deg_emin} = $frame -> Label(-text=>'Emin')
    -> pack(-side=>'right');
  # deglitch emax
  #$frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
  #  -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $frame -> Frame(-width=>5)
    -> pack(-side=>'right');
  $grab{pp_deg_emax} = $frame -> Button(@pluck_button, @pluck,
					-command=>sub{pluck('pp_deg_emax');
						      my $x = $preprocess{standard};
						      return unless $x;
						      $groups{$x} -> make(deg_emin=>$preprocess{deg_emax});
						      $groups{$x} -> plotE('emtg',$dmode);
						      $groups{$x} -> plot_vertical_line($preprocess{trun_e}, $preprocess{ymin},
											$preprocess{ymax}, $dmode, "truncate",
											$groups{$x}->{plot_yoffset});
					},)
    -> pack(-side=>'right');
  $widgets{deg_emax} = $frame->Entry(-width=>8, -textvariable=>\$preprocess{deg_emax},
				     -foreground=>$grey)
    -> pack(-side=>'right');
  $labels{deg_emax} = $frame -> Label(-text=>'Emax')
    -> pack(-side=>'right');
  # deglitch tolerance
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{deg_tol} = $frame->Entry(-width=>8, -textvariable=>\$preprocess{deg_tol},
				    -foreground=>$grey)
    -> pack(-side=>'right');
  $labels{deg_tol} = $frame -> Label(-text=>'Tolerance')
    -> pack(-side=>'right');

  ## interpolate? =================================================
  #=$preprocess{int_do} = 0;
  ##   $outer = $parent -> Frame(-relief=>'groove', -borderwidth=>2)
  ##     -> pack(-side=>'top', -expand=>1, -fill=>'x');
  ##   $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
  ##     -> pack(-side=>'top', -expand=>1, -fill=>'x');
  ##   $widgets{int_check} = $frame -> Checkbutton(-text=>"Interpolate to the standard",
  ## 					      -foreground=>$config{colors}{activehighlightcolor},
  ## 					      -variable=>\$preprocess{int_do},
  ## 					      -selectcolor=>$red,
  ## 					      -command=>sub{
  ## 						my $state = ($preprocess{int_do}) ?
  ## 						  'normal' : 'disabled';
  ## 						##$widgets{al_check} -> configure(-state=>$state);
  ## 					      })
  ##     -> pack(-pady=>2, -side=>'left');

  ## align? =================================================
  #=$preprocess{al_do} = 0;
  $outer = $parent -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{al_check} = $frame -> Checkbutton(-text=>"Align to the standard",
					     -foreground=>$config{colors}{activehighlightcolor},
					     -variable=>\$preprocess{al_do},
					     -selectcolor=>$red,)
					     #-command=>sub{
					       #my ($color, $text, $state) = $preprocess{al_do} ?
					       # ($blue, 'black', 'normal') :
					       #   ($grey, $grey, 'disabled');
					       #foreach (qw(al_emin al_emax)) {
					       # $labels{$_}->configure(-foreground=>$color);
					       # $widgets{$_}->configure(-state=>$state,
					       #			 -foreground=>$color);
					       # $grab{'pp_'.$_}->configure(-state=>$state);
					       #};
					     #})
    -> pack(-pady=>2, -side=>'left');
  # alignment emin
  #$frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
  #  -> pack(-side=>'top', -expand=>1, -fill=>'x');
  #$grab{pp_al_emin} = $frame -> Button(@pluck_button, @pluck,
  #				       -command=>sub{Echo("Preprocessing pluck not yet working")},)
  #  -> pack(-side=>'right');
  #$widgets{al_emin} = $frame->Entry(-width=>8, -textvariable=>\$preprocess{al_emin},
  #				    -foreground=>$grey)
  #  -> pack(-side=>'right');
  #$labels{al_emin} = $frame -> Label(-text=>'Emin')
  #  -> pack(-side=>'right');
  # alignment emax
  #$frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
  #  -> pack(-side=>'top', -expand=>1, -fill=>'x');
  #$grab{pp_al_emax} = $frame -> Button(@pluck_button, @pluck,
  #				       -command=>sub{Echo("Preprocessing pluck not yet working")},)
  #  -> pack(-side=>'right');
  #$widgets{al_emax} = $frame->Entry(-width=>8, -textvariable=>\$preprocess{al_emax},
  #				    -foreground=>$grey)
  #  -> pack(-side=>'right');
  #$labels{al_emax} = $frame -> Label(-text=>'Emax')
  #  -> pack(-side=>'right');

  ## params? ===================================================
  #=$preprocess{par_do} = 0;
  $outer = $parent -> Frame(-relief=>'groove', -borderwidth=>2)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $frame = $outer -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-side=>'top', -expand=>1, -fill=>'x');
  $widgets{par_check} = $frame -> Checkbutton(-text=>"Set parameters to the standard",
					      -foreground=>$config{colors}{activehighlightcolor},
					      -variable=>\$preprocess{par_do},
					      -selectcolor=>$red,
					     )
    -> pack(-pady=>2, -side=>'left');


  ## buttons ===================================================
  $frame = $parent -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-expand=>1, -fill=>'x');
  $frame -> Button(-text=>'Replot standard', -width=>5, @button_list,
		   -command=>sub{
		     my $x = $preprocess{standard};
		     $groups{$x} -> make(deg_emin=>$preprocess{deg_emin},
					 deg_emax=>$preprocess{deg_emax},
					 deg_tol =>$preprocess{deg_tol});
		     &set_key_params;
		     $groups{$x} -> plotE('emtg',$dmode);
		     $groups{$x} -> plot_vertical_line($preprocess{trun_e}, $preprocess{ymin},
						       $preprocess{ymax}, $dmode, "truncate",
						       $groups{$x}->{plot_yoffset});
		   })
    -> pack(-expand=>1, -fill=>'x', -padx=>1, -pady=>2, -side=>'left');
  ##$frame -> Button(-text=>'Dismiss extras', -width=>5, @button_list,
  ##		   -command => sub{remove_extras($widg)} )
  ##  -> pack(-expand=>1, -fill=>'x', -padx=>1, -pady=>2, -side=>'right');

  ## initial setup
  my $notnone = $config{colors}{activehighlightcolor};
  foreach (qw(deg_emin deg_emax deg_tol)) {
    my $active = (($preprocess{standard} ne 'None') and $preprocess{deg_do});
    $labels{$_}->configure(-foreground=> $active ? '#9c9583' : $notnone);
  };
  foreach (qw(trun_e)) {
    my $active = (($preprocess{standard} ne 'None') and $preprocess{trun_do});
    $labels{$_}->configure(-foreground=> $active ? '#9c9583' : $notnone);
  };
  foreach (keys %widgets) {
    next if ($_ eq 'standard'); # or ($_ =~ /(deg|trun)_check/));
    $widgets{$_}->configure(-state=>$initial_state);
  };
  foreach (keys %grab) {
    $grab{$_}->configure(-state=>$initial_state);
  };
  $widgets{standard} -> configure(-state=>'disabled') if $how_many == 1;
  map { $widgets{$_} -> configure(-state=>'normal') } (qw(mark_check trun_check deg_check));
  #$pre -> grab;
  return $parent;
};


sub perform_preprocessing {
  if ($preprocess{standard} eq 'None') {
    return 0 unless ($preprocess{trun_do} or $preprocess{deg_do});
  };
  my $group = $_[0];
  my $stan = $preprocess{standard};
  my $eshift = 0;
  $preprocess{titles} = ["^^ Preprocessing chores performed:"];
  Echo("Performing preprocessing chores on $groups{$group}->{label} ... ");
  if ($preprocess{trun_do}) {
    Echo("Truncating $groups{$group}->{label}", 0);
    $groups{$group}->make(etruncate=>$preprocess{trun_e});
    push @{$preprocess{titles}}, "^^    truncation at $preprocess{trun_e}";
    truncate_data($group, 1, $preprocess{trun_beforeafter}, 'mu(E)');
  };
  if ($preprocess{deg_do}) {
    Echo("Deglitching $groups{$group}->{label}", 0);
    $groups{$group}->make(deg_emin=>$preprocess{deg_emin},
			  deg_emax=>$preprocess{deg_emax},
			  deg_tol =>$preprocess{deg_tol});
    $groups{$group}->dispatch_bkg($dmode);
    my $cmd = sprintf("set %s.postline = %g+%g*%s.energy+%g*%s.energy**2\n",
		      $group, $groups{$group}->{bkg_nc0}, $groups{$group}->{bkg_nc1},
		      $group, $groups{$group}->{bkg_nc2}, $group);
    $groups{$group}->dispose($cmd, $dmode);
    remove_glitches($group, 1);	# remove em, but don't plot yet
    push @{$preprocess{titles}}, "^^    deglitching with margins $preprocess{deg_emin}, $preprocess{deg_emax}, and $preprocess{deg_tol}";
  };
  if ($preprocess{int_do}) {
    Echo("Interpolating $groups{$group}->{label}", 0);
    $groups{$stan} -> interpolate($groups{$group}, 'e', $dmode);
    push @{$preprocess{titles}}, "^^    interpolation onto grid of $groups{$stan}->{label}";
  };

  ## need to do alignment a bit later in case we want to align using
  ## the reference channels

  if ($preprocess{par_do}) {
    Echo("Setting parameters for $groups{$group}->{label}", 0);
    $groups{$group} -> set_to_another($groups{$stan});
    push @{$preprocess{titles}}, "^^    constraint of parameters to $groups{$stan}->{label}";
  };
  Echo("Finished with preprocessing!", 0);
};


sub perform_rebinning {
  return 0 unless $rebin{do_rebin};
  #Error("You forgot to specify an absorber for rebinning."),
  return 0 if ($rebin{abs} =~ /^\s*$/);
  #Error("\"$rebin{abs}\" is not a valid element symbol."),
  return 0 unless (lc($rebin{abs}) =~ /^$Ifeffit::Files::elem_regex$/);
  ## make sure these are all defined
  $rebin{emin}  ||= $config{rebin}{emin};
  $rebin{emax}  ||= $config{rebin}{emax};
  $rebin{pre}   ||= $config{rebin}{pre};
  $rebin{xanes} ||= $config{rebin}{xanes};
  $rebin{exafs} ||= $config{rebin}{exafs};
  ## these must be positive or bad stuff will happen
  $rebin{pre}   = abs($rebin{pre});
  $rebin{xanes} = abs($rebin{xanes});
  $rebin{exafs} = abs($rebin{exafs});
  ## check if emin, emax out of order
  (($rebin{emin}, $rebin{emax}) = ($rebin{emax}, $rebin{emin})) if
    ($rebin{emin} > $rebin{emax});

  my $group = $_[0];

  my @e = Ifeffit::get_array("$group.energy");
  my ($efirst, $elast) = ($e[0], $e[$#e]);
  my ($ek, $el1, $el2, $el3) = (Xray::Absorption->get_energy($rebin{abs}, 'K'),
				Xray::Absorption->get_energy($rebin{abs}, 'L1'),
				Xray::Absorption->get_energy($rebin{abs}, 'L2'),
				Xray::Absorption->get_energy($rebin{abs}, 'L3'));
  my ($e0, $edge);
 SWITCH: {
    (($e0, $edge) = ($ek,  'K')),  last SWITCH if (($ek  > $efirst) and ($ek  < $elast));
    (($e0, $edge) = ($el3, 'L3')), last SWITCH if (($el3 > $efirst) and ($el3 < $elast));
    (($e0, $edge) = ($el2, 'L2')), last SWITCH if (($el2 > $efirst) and ($el2 < $elast));
    (($e0, $edge) = ($el1, 'L1')), last SWITCH if (($el1 > $efirst) and ($el1 < $elast));
    Error("These data cannot be of absorber $rebin{abs}!  No edge of that element lies within the energy range."), return;
  };
  Echo("Rebinning data $groups{$group}->{label} ($rebin{abs} $edge-edge) ...");
  $groups{$group}->dispose("## Rebinning group $group:", $dmode);
  my @bingrid;
  my $ee = $efirst;
  while ($ee < $rebin{emin}+$e0) {
    push @bingrid, $ee;
    $ee += $rebin{pre};
  };
  $ee = $rebin{emin}+$e0;
  while ($ee < $rebin{emax}+$e0) {
    push @bingrid, $ee;
    $ee += $rebin{xanes};
  };
  $ee = $rebin{emax}+$e0;
  my $kk = $groups{$group}->e2k($rebin{emax});
  while ($ee < $elast) {
    push @bingrid, $ee;
    $kk += $rebin{exafs};
    $ee = $e0 + $groups{$group}->k2e($kk);
  };
  push @bingrid, $elast;
  Ifeffit::put_array("$group.xxx", \@bingrid);
  foreach my $y (split(" ", &column_string)) {
    next if ($y eq 'energy');
    ## also do not want to rebin, say, $g.1 if "1" is the energy column
    $groups{$group}->dispose("set $group.rebin = rebin($group.energy, $group.$y, $group.xxx)", $dmode);
    $groups{$group}->dispose("set $group.$y = $group.rebin", $dmode);
  };
  $groups{$group}->dispose("set $group.energy = $group.xxx", $dmode);
  $groups{$group}->dispose("erase $group.xxx $group.rebin", $dmode);
  #$groups{$group}->dispose("erase $group.rebin", $dmode);
  $rebin{titles} =
    ["^^ Rebinned data onto grid [$rebin{emin}:$rebin{emax}] with steps ($rebin{pre},$rebin{xanes},$rebin{exafs})"];

  Echo("Rebinning data $groups{$group}->{label} ($rebin{abs} $edge-edge) ... done!");
};

sub set_reference {
  my $parent	= $_[0] -> Frame(-borderwidth=>0, -relief=>'flat');
  my $group	= $_[1];
  my $cols	= $_[2];
  my $widg	= $_[3];
  my $reference	= $_[4];
  my $energy    = $_[5];

  ## set some variables
  my $red = $config{colors}{single};
  my $blue= $config{colors}{activehighlightcolor};
  my $grey= '#9c9583';

  $parent -> Label(-text=>'Reference channel',
		   -font=>$config{fonts}{bold},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack();
  $parent -> Label(-text=>'The reference uses the same energy array as the data.',
		   -relief=>'groove',
		  )
    -> pack(-ipadx=>2, -ipady=>2);
  my $fr = $parent -> Scrolled('Pane', -relief=>'flat', -borderwidth=>2,
			       -gridded=>'xy',
			       -scrollbars=>'os', -sticky => 'ew',)
    -> pack(-expand=>1, -fill=>'x');
  $fr->Subwidget("xscrollbar")->configure(-background=>$config{colors}{background});
  $fr -> Label(-text=>' ', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $fr -> Label(-text=>'Numerator', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $fr -> Label(-text=>'Denominator', -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  my $j = 1;
  foreach (@$cols) {
    my $this = $group.".".$_;
    #my $this = $_;

    $fr -> Label(-text=>$_)
      -> grid(-row=>0, -column=>$j);
    my $jj = $j;  # need a counter that is scoped HERE
    $fr -> Radiobutton(-variable=>\$$reference{numerator},
		       -value=>$this,
		       -text=>"",
		       -selectcolor=>$red,
		      )
      -> grid(-row=>1, -column=>$j,);
    $fr -> Radiobutton(-variable=>\$$reference{denominator},
		       -value=>$this,
		       -text=>"",
		       -selectcolor=>$red,
		       )
      -> grid(-row=>2, -column=>$j,);
    ++$j;
  };

  $fr = $parent -> Frame()
    -> pack();
  $fr -> Checkbutton(-text=>"Natural log", -variable=>\$$reference{ln}, -selectcolor=>$red,)
    -> pack(-side=>'left', -fill=>'x', -anchor=>'w');
  $fr -> Checkbutton(-text=>"Same element", -variable=>\$$reference{same}, -selectcolor=>$red,)
    -> pack(-side=>'left', -fill=>'x', -anchor=>'w', -padx=>2);
  $fr -> Button(-text=>"Plot reference",
		-borderwidth=>1,
		-command=>sub{
		  Echo("Not enough information to plot reference"), return unless
		    ($$reference{numerator} or $$reference{denominator});
		  my $str = "$$reference{numerator}/$$reference{denominator}";
		  $str = "ln(abs( $str ))" if $$reference{ln};
		  my $en = $$energy;
		  my $command = "\n## Plot reference in the file selection dialog:\n";
		  $command   .= "set t___oss.y = $str\n";
		  $command   .= "newplot(x=$en, y=t___oss.y, ";
		  $command   .= "color=$config{plot}{c0}, title=\"current reference selection\", xlabel=x, ylabel=y)\n";
		  $command   .= "erase \@group t___oss\n";
		  $groups{"Default Parameters"}->dispose($command, $dmode);
		},
	       )
    -> pack(-side=>'left', -fill=>'x', -anchor=>'w', -padx=>2);
  $fr = $parent -> Frame()
    -> pack(-side=>'bottom', -anchor=>'w', -pady=>4);
  $fr -> Button(-text=>'Clear reference channels', @button_list,
		-command=>sub{$$reference{numerator}   = 0;
			      $$reference{denominator} = 0;
			      $$reference{ln}          = 1;
			      $$reference{same}        = 1;
			    })
    -> pack(-side=>'left', -fill=>'x', -padx=>8, -anchor=>'e');
  ##$fr -> Button(-text=>'Dismiss extras', @button_list,
  ##		-command=>sub{remove_extras($widg)})
  ##  -> pack(-side=>'left', -fill=>'x', -padx=>8, -anchor=>'e');
  return $parent;
};


sub set_bin {
  my $widg = $_[0];
  my $ppp = $$widg{bin_card};
  my $parent = $ppp -> Frame(-borderwidth=>0, -relief=>'flat');

  $parent -> Label(-text=>'Data rebinning',
		   -font=>$config{fonts}{bold},
		   -foreground=>$config{colors}{activehighlightcolor})
    -> pack();
  $parent -> Checkbutton(-text=>"Perform rebinning",
			 -variable=>\$rebin{do_rebin})
    -> pack(-pady=>4);

  my $frame = $parent -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-expand=>1, -fill=>'x');
  $frame -> Label(-text=>'Absorber:',
		  -foreground=>$config{colors}{activehighlightcolor},)
    -> grid(-row=>0, -column=>0, -sticky=>'e');
  $widget{rebin_abs} = $frame -> Entry(-width=>5, -textvariable=>\$rebin{abs})
    -> grid(-row=>0, -column=>1, -sticky=>'w', -padx=>2);

  $frame -> Label(-text=>'Edge region from:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin{emin},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>1, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>' to ',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>2);
  $frame -> Entry(-width=>5, -textvariable=>\$rebin{emax},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>1, -column=>3, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'eV',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>1, -column=>4);

  $frame -> Label(-text=>'Pre edge grid:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin{pre},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>2, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'eV',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>2, -column=>2, -sticky=>'w',);

  $frame -> Label(-text=>'XANES grid:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin{xanes},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>3, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'eV',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>3, -column=>2, -sticky=>'w',);

  $frame -> Label(-text=>'EXAFS grid:',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>4, -column=>0, -sticky=>'e');
  $frame -> Entry(-width=>5, -textvariable=>\$rebin{exafs},
		  -validate=>'key',
		  -validatecommand=>[\&set_variable, 'rebin'])
    -> grid(-row=>4, -column=>1, -sticky=>'w', -padx=>2);
  $frame -> Label(-text=>'invAng',
		  -foreground=>$config{colors}{activehighlightcolor})
    -> grid(-row=>4, -column=>2, -sticky=>'w',);

  $frame = $parent -> Frame(-relief=>'flat', -borderwidth=>0)
    -> pack(-expand=>1, -fill=>'x', -pady=>4);
  ##$frame -> Button(-text=>'Dismiss extras', -width=>5, @button_list,
  ##		   -command => sub{remove_extras($widg)} )
  ##  -> pack(-expand=>1, -fill=>'x', -padx=>1, -pady=>2, -side=>'right');

  return $parent;
};

## sub set_favorites {
##   my $widg = $_[0];
##   my $ppp = $$widg{fav_card};
##   my $parent = $ppp -> Frame(-borderwidth=>0, -relief=>'flat');
##
##   $parent -> Label(-text=>'Favorite file types',
## 		   -font=>$config{fonts}{bold},
## 		   -foreground=>$config{colors}{activehighlightcolor})
##     -> pack();
##
##   my $text = $parent -> ROText(-wrap=>'word', -width=>1, -height=>10, -relief=>'flat')
##     -> pack(-expand=>1, -fill=>'both');
##   $text -> insert('end', "This space will contain an as-yet unimplemented, user-definable list of file types.  Selecting one will serve as a short cut to setting the column checkboxes for the numerator and denominator, allowing you to quickly specify common column selections.");
##
##   my $frame = $parent -> Frame(-relief=>'flat', -borderwidth=>0)
##     -> pack(-expand=>1, -fill=>'x');
##   $frame -> Button(-text=>'Dismiss extras', -width=>5, @button_list,
## 		   -command => sub{remove_extras($widg)} )
##     -> pack(-expand=>1, -fill=>'x', -padx=>1, -pady=>2, -side=>'right');
##
##   return $parent;
## };


sub remove_extras {
  my $widg = $_[0];
  $$widg{extras} -> packForget;
  $top -> update; # needed so $raw resizes correctly
  $$widg{extra_button} -> pack(-expand=>1, -fill=>'x', -pady=>0);
  $$widg{right}->pack(-expand=>1, -fill=>'both',
		      -side=>'right', -anchor=>'n');
  $$widg{databox}->pack(-expand=>1, -fill=>'both',
			-padx=>4, -pady=>2);
  $$prior_args{extra_shown} = 0;
  ## removing this frame says that the user does not want to do any of these
  ## chores, so turn them all off
  $preprocess{ok}=0;
}






## save data in the selected space (a misnomer, since mu(E) can also
## be saved by this subroutine
sub save_chi {
  Echo('No data!'), return unless ($current);
  my ($space, $in_loop, $dir) = @_;
  $space = lc($space);
  Echo("You cannot save chi for the Default Parameters"), return 0
    if ($current eq "Default Parameters");
  $top -> Busy;
  my $this = $in_loop || $current;
  my ($suffix, $text) = ('chi', 'chi(k)');
 SWITCH: {
    (($suffix, $text) = ('chi1', 'k*chi(k)')),         last SWITCH if ($space eq 'k1');
    (($suffix, $text) = ('chi2', 'k^2*chi(k)')),       last SWITCH if ($space eq 'k2');
    (($suffix, $text) = ('chi3', 'k^3*chi(k)')),       last SWITCH if ($space eq 'k3');
    (($suffix, $text) = ('chie', 'chi(E)')),           last SWITCH if ($space eq 'ke');
    (($suffix, $text) = ('xmu',  'mu(E)')),            last SWITCH if ($space eq 'e');
    (($suffix, $text) = ('nor',  'normalized mu(E)')), last SWITCH if ($space eq 'n');
    (($suffix, $text) = ('der',  'derivative mu(E)')), last SWITCH if ($space eq 'd');
    (($suffix, $text) = ('bkg',  'bkg(E)')),           last SWITCH if ($space eq 'b');
    (($suffix, $text) = ('rsp',  'chi(R)')),           last SWITCH if ($space eq 'r');
    (($suffix, $text) = ('qsp',  'chi(q)')),           last SWITCH if ($space eq 'q');
  };
  Echo("Saving $text data ...", 0);
  #local $Tk::FBox::a;
  #local $Tk::FBox::b;
  my $path = $current_data_dir || Cwd::cwd;
  my $types = [["EXAFS $text data", ".".$suffix],
	       ['All + hidden', '*']];
  ##(my $initial = join(".", $this, $suffix)) =~ s/\?/_/g;
  my $initial = join(".", $groups{$this}->{label}, $suffix);
  # spaces are common in filenames on Mac and Win, but not on un*x
  ($initial =~ s/\s+/_/g) unless ($is_windows or $is_darwin);
  ($initial =~ s/[\\:\/\*\?\'<>\|]/_/g);# if ($is_windows);
  my $file = q{};
  if ($in_loop) {
    $file = File::Spec->catfile($dir, $initial);
  } else {
    $file = $top -> getSaveFile(-defaultextension=>$suffix,
				-filetypes=>$types,
				#(not $is_windows) ?
				#  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$path,
				-initialfile=>$initial,
				-title => "Athena: Save $text data");
  };
  if ($file) {
    ## make sure I can write to $file
    open F, ">".$file or do {
      $top -> Unbusy;
      Error("You cannot write to \"$file\".");
      return
    };
    close F;
    my ($name, $pth, $suffix) = fileparse($file);
    $current_data_dir = $pth;
    ##&push_mru($file);
    my $stdev = "";
    if ($groups{$this}->{is_merge} eq $space) {
      $stdev = ", $this.stddev"
    };
    refresh_titles($groups{$this}); # make sure titles are up-to-date
    $groups{$this}->dispose("\$id_line = \"Athena data file -- Athena version $VERSION\"");
    #$groups{$this}->dispose("\$id2_line = \"Saving $groups{$this}->{label} (group=$groups{$this}->{group}) as $text\"");
    $groups{$this}->dispose("\$id2_line = \"Saving $groups{$this}->{label} as $text\"");
    my $i = 0;
    foreach my $l (split(/\n/, $groups{$this}->param_summary)) {
      ++$i;
      $groups{$this}->dispose("\$param_line_$i = \"$l\"");
    };

  SWITCH: {			# what about mu(E), mu0(E), pre(E),
                                # post(E), window(?)
      (($space eq 'e') and ($groups{$this}->{not_data})) and do {
	my $esh = $groups{$this}->{bkg_eshift};
	$groups{$this}->dispose("set $this.ee = $this.energy+$esh", $dmode);
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.ee, $this.det)\n", $dmode);
	$groups{$this}->dispose("erase $this.ee", $dmode);
	last SWITCH;
      };
      ($space eq 'e') and do {
	$groups{$this}->dispatch_bkg($dmode);
	my $suff = ($groups{$this}->{bkg_cl}) ? "f2" : "bkg";
	my $esh = $groups{$this}->{bkg_eshift};
	my $i0 = ($groups{$this}->{i0}) ? ", $this.i0" : "";
	$groups{$this}->dispose("set $this.ee = $this.energy+$esh", $dmode);
	$groups{$this}->dispose("set $this.der = deriv($this.xmu)/deriv($this.energy)", $dmode);
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.ee, $this.xmu, $this.$suff, $this.der $stdev$i0, $this.preline, $this.postline)\n", $dmode);
	$groups{$this}->dispose("erase $this.ee $this.der", $dmode);
	last SWITCH;
      };
      ($space eq 'n') and do {
	##($groups{$this}->{update_bkg}) and
	$groups{$this}->dispatch_bkg($dmode);
	my $suff = "f2norm";
	my $esh = $groups{$this}->{bkg_eshift};
	my $i0 = ($groups{$this}->{i0}) ? ", $this.i0" : "";
	unless ($groups{$this}->{bkg_cl}) {
	  $groups{$this}->dispose("$this.bkg_norm=($this.bkg-$this.preline)/$groups{$this}->{bkg_step}", $dmode);
	  $suff = "bkg_norm";
	};
	$groups{$this}->dispose("set $this.der_norm = deriv($this.norm)/deriv($this.energy)", $dmode);
	$groups{$this}->dispose("set $this.ee = $this.energy+$esh", $dmode);
	if ($groups{$this}->{bkg_flatten}) {
	  my $label = "energy norm";
	  $label   .= " bkg_norm" if (not $groups{$this}->{is_xanes});
	  $label   .= " der_norm";
	  $label   .= " stddev"   if $groups{$this}->{is_merge};
	  $label   .= " i0"       if $groups{$this}->{i0};
	  my $fbkg = ($groups{$this}->{is_xanes}) ? "" : ", $this.fbkg";
	  $groups{$this}->dispose("write_data(file=\"$file\", label=\"$label\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.ee, $this.flat $fbkg, $this.der_norm $stdev $i0)\n", $dmode);
	} else {
	  my $fbkg = ($groups{$this}->{is_xanes}) ? "" : ", $this.$suff";
	  $groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.ee, $this.norm $fbkg, $this.der_norm $stdev $i0)\n", $dmode);
	};
	$groups{$this}->dispose("erase $this.ee", $dmode);
	($groups{$this}->{bkg_cl}) or
	  $groups{$this}->dispose("erase $this.bkg_norm $this.der_norm", $dmode);
	last SWITCH;
      };
      ($space eq 'd') and do {
	my $esh = $groups{$this}->{bkg_eshift};
	$groups{$this}->dispatch_bkg($dmode);
	$groups{$this}->dispose("set $this.ee = $this.energy+$esh", $dmode);
	$groups{$this}->dispose("set $this.deriv = deriv($this.xmu)/deriv($this.energy)", $dmode);
	my $i0 = ($groups{$this}->{i0}) ? ", $this.i0" : "";
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.ee, $this.deriv $i0)\n", $dmode);
	$groups{$this}->dispose("erase $this.ee $this.deriv", $dmode);
	last SWITCH;
      };
      ($space eq 'b') and do {
	my $suff = ($groups{$this}->{bkg_cl}) ? "f2norm" : "bkg";
	my $esh = $groups{$this}->{bkg_eshift};
	($groups{$this}->{update_bkg}) and $groups{$this}->dispatch_bkg($dmode);
	$groups{$this}->dispose("set $this.ee = $this.energy+$esh", $dmode);
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.ee, $this.$suff)\n", $dmode);
	$groups{$this}->dispose("erase $this.ee", $dmode);
	last SWITCH;
      };
      ($space eq 'k') and do {
	($groups{$this}->{update_bkg}) and $groups{$this}->dispatch_bkg($dmode);
	($groups{$this}->{update_fft}) and $groups{$this}->do_fft($dmode, \%plot_features);
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.k, $this.chi $stdev, $this.win)\n", $dmode);
	last SWITCH;
      };
      ($space =~ /k(\d)/) and do { # k-weighted chi(k) output (note stddev not to scale)
	my $kw = $1;
	($groups{$this}->{update_bkg}) and $groups{$this}->dispatch_bkg($dmode);
	($groups{$this}->{update_fft}) and $groups{$this}->do_fft($dmode, \%plot_features);
	$groups{$this}->dispose("set $this.chik = $this.chi * $this.k**$kw", $dmode);
	ifeffit("set ___x = ceil($this.chik)"); # scale window to plot
	my $scale = 1.05 * Ifeffit::get_scalar("___x");
	$groups{$this}->dispose("set $this.winout = $scale*$this.win");
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.k, $this.chik $stdev, $this.winout)\n", $dmode);
	$groups{$this}->dispose("erase $this.chik $this.winout", $dmode);
	last SWITCH;
      };
      ($space eq 'r') and do {
	($groups{$this}->{update_bkg}) and $groups{$this}->dispatch_bkg($dmode);
	($groups{$this}->{update_fft}) and $groups{$this}->do_fft($dmode, \%plot_features);
	($groups{$this}->{update_bft}) and $groups{$this}->do_bft($dmode);
	ifeffit("set ___x = ceil($this.chir_mag)"); # scale window to plot
	my $scale = 1.05 * Ifeffit::get_scalar("___x");
	$groups{$this}->dispose("set $this.winout = $scale*$this.rwin");
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*,\n           $this.r, $this.chir_re, $this.chir_im, $this.chir_mag, $this.chir_pha, $this.winout)\n", $dmode);
	$groups{$this}->dispose("erase $this.winout", $dmode);
	last SWITCH;
      };
      ($space eq 'ke') and do {
	($groups{$this}->{update_bkg}) and $groups{$this}->dispatch_bkg($dmode);
	my $e0      = $groups{$this}->{bkg_e0};
	my $command = "$this.eee = $this.k^2/etok+$e0$/\n";
	$command   .= "write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.eee, $this.chi)\n";
	$groups{$this}->dispose($command, $dmode);
	last SWITCH;
      };
      ($space eq 'q') and do {
	($groups{$this}->{update_bkg}) and $groups{$this}->dispatch_bkg($dmode);
	($groups{$this}->{update_fft}) and $groups{$this}->do_fft($dmode, \%plot_features);
	($groups{$this}->{update_bft}) and $groups{$this}->do_bft($dmode);
	$groups{$this}->dispose("write_data(file=\"$file\", \$id_line, \$id2_line, \$param_line_\*, \$${this}_title_\*, $this.q, $this.chiq_re, $this.chiq_im, $this.chiq_mag, $this.chiq_pha)\n", $dmode);
	last SWITCH;
      };
    };
    Echo("Saving $text data to $file ... done", 0);
    my $memory_ok = $groups{$this}->memory_check($top, \&Echo, \%groups, $max_heap, 0, 0);
    Echo ("WARNING: Ifeffit is out of memory!") if ($memory_ok == -1);
  } else {
    Echo("Saving $text data ... canceled", 0);
  };
  $top -> Unbusy;
  return $text;
};


sub save_marked {
  my $m = 0;
  map {$m += $_} values %marked;
  Error("Saving file aborted.  There are no marked groups."), return 1 unless ($m);
  my $maxcol = Ifeffit::get_scalar('&max_output_cols') || 16;
  --$maxcol;
  Error("You cannot save more than $maxcol groups to a single file."), return if ($m>$maxcol);
  my $sp = $_[0];
  ##local $Tk::FBox::a;
  ##local $Tk::FBox::b;

  my ($x, $y, $mess) = ('','','');
 SWITCH: {
      ($x, $y, $mess) = ('energy','xmu', "mu(E)"),                       last SWITCH if ($sp eq 'e');
      ($x, $y, $mess) = ('energy','norm', "normalized mu(E)"),           last SWITCH if ($sp eq 'n');
      ($x, $y, $mess) = ('energy','deriv', "derivative mu(E)"),          last SWITCH if ($sp eq 'd');
      ($x, $y, $mess) = ('energy','nderiv', "derivative norm(E)"),       last SWITCH if ($sp eq 'nd');
      ($x, $y, $mess) = ('k','chi', "chi(k)"),                           last SWITCH if ($sp eq 'k');
      ($x, $y, $mess) = ('k','chi1', "k*chi(k)"),                        last SWITCH if ($sp eq 'k1');
      ($x, $y, $mess) = ('k','chi2', "k^2*chi(k)"),                      last SWITCH if ($sp eq 'k2');
      ($x, $y, $mess) = ('k','chi3', "k^3*chi(k)"),                      last SWITCH if ($sp eq 'k3');
      ($x, $y, $mess) = ('energy','chi', "chi(E)"),                      last SWITCH if ($sp eq 'ke');
      ($x, $y, $mess) = ('r','chir_mag', "the magnitude of chi(R)"),     last SWITCH if ($sp eq 'rm');
      ($x, $y, $mess) = ('r','chir_re', "the real part of chi(R)"),      last SWITCH if ($sp eq 'rr');
      ($x, $y, $mess) = ('r','chir_im', "the imaginary part of chi(R)"), last SWITCH if ($sp eq 'ri');
      ($x, $y, $mess) = ('q','chiq_mag', "the magnitude of chi(q)"),     last SWITCH if ($sp eq 'qm');
      ($x, $y, $mess) = ('q','chiq_re', "the real part of chi(q)"),      last SWITCH if ($sp eq 'qr');
      ($x, $y, $mess) = ('q','chiq_im', "the imaginary part of chi(q)"), last SWITCH if ($sp eq 'qi');
    };
  my $types = [['All Files', '*'],[$x, '.'.$y]];
  my $path = $current_data_dir || Cwd::cwd;
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>"marked.".$y,
				 -title => "Athena: Save marked groups as $mess");
  return unless $file;
  ## make sure I can write to $file
  open F, ">".$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  close F;
  my ($name, $pth, $suffix) = fileparse($file);
  $current_data_dir = $pth;
  #&push_mru($file);
  Echo("Saving $mess for each marked group ...");
  $top -> Busy;

  $groups{$current} -> dispose("\n## saving marked groups as columns in a file", $dmode);
  my @list = (&sorted_group_list);
  ## determine first marked group so we can use its energy array
  my $first;
  foreach (@list) {
    ($first = $_), last if $marked{$_};
  };
  my ($label, $alt_label) = ($x, $x);
  my $command = "file=\"$file\", \$marked_title_\*, ";
  $groups{$current}->dispose("\$marked_title_1 = \"Athena multicolumn data file -- Athena version $VERSION\"");
  my $erase = "erase \$marked_title_1\n";
  $groups{$current}->dispose("\$marked_title_2 = \"This file contains $mess from:\"");
  $erase .= "erase \$marked_title_2\n";
  if ($x eq "energy") {
    $groups{$first}->dispose("set $first.ee = $first.energy+$groups{$first}->{bkg_eshift}", $dmode);
    $command .= "$first.ee";
    $erase   .= "erase $first.ee\n";
  } else {
    $command .= "$first.$x";
  };
  my $ncol = 0;
  my $stan;
  foreach my $g  (@list) {
    next unless $marked{$g};
    next if (($x ne 'energy') and  ($groups{$g}->{not_data}));
    next if (($x eq 'energy') and (($groups{$g}->{is_chi}) or ($groups{$g}->{is_rsp}) or
				   ($groups{$g}->{is_qsp})));
    next if (($x eq 'k')      and (($groups{$g}->{is_rsp}) or ($groups{$g}->{is_qsp})));
    next if (($x eq 'r')      and  ($groups{$g}->{is_qsp}));
    ## bring up to date if needed
    $groups{$g}->dispatch_bkg($dmode)            if $groups{$g}->{update_bkg};
    $groups{$g}->do_fft($dmode, \%plot_features) if (($x =~ /^[qr]$/) and $groups{$g}->{update_fft});
    $groups{$g}->do_bft($dmode)                  if (($x eq 'q')      and $groups{$g}->{update_bft});
    ## column label
    (my $this_lab = $groups{$g}->{label}) =~ s/[^A-Za-z0-9_&:?@~]+/_/g;
    $label .= "  $this_lab";
    ## interpolate if energy and not the first column
    my $yy = $y;
    ($ncol) or ($stan = $g);
    if (($ncol) and ($y eq 'deriv')) {
      my ($e0stan, $e0g) = ($groups{$stan}->{bkg_eshift},$groups{$g}->{bkg_eshift});
      $yy = sprintf "deriv_%s", $ncol+1;
      $groups{$g}->dispose("set $g.$yy = deriv($g.xmu)/deriv($g.energy)", $dmode);
      $groups{$g}->dispose("set $g.$yy = qinterp($g.energy+$e0g, $g.$yy, $stan.energy+$e0stan)",
			   $dmode);
      $erase .= "erase $g.$yy\n";
    } elsif ($y eq 'nderiv') {
      my ($e0stan, $e0g) = ($groups{$stan}->{bkg_eshift},$groups{$g}->{bkg_eshift});
      $yy = sprintf "nderiv_%s", $ncol+1;
      $groups{$g}->dispose("set $g.$yy = deriv($g.norm)/deriv($g.energy)", $dmode);
      $groups{$g}->dispose("set $g.$yy = qinterp($g.energy+$e0g, $g.$yy, $stan.energy+$e0stan)",
			   $dmode);
      $erase .= "erase $g.$yy\n";
    } elsif (($ncol) and ($x eq 'energy')) {
      my ($e0stan, $e0g) = ($groups{$stan}->{bkg_eshift},$groups{$g}->{bkg_eshift});
      $yy = sprintf "%s_%s", $y, $ncol+1;
      if (($y eq 'norm') and $groups{$g}->{bkg_flatten}) {
	$groups{$g}->dispose("set $g.$yy = qinterp($g.energy+$e0g, $g.flat, $stan.energy+$e0stan)",
			     $dmode);
      } else {
	$groups{$g}->dispose("set $g.$yy = qinterp($g.energy+$e0g, $g.$y, $stan.energy+$e0stan)",
			     $dmode);
      };
      $erase .= "erase $g.yy\n";
    } elsif ($y =~ /chi(\d)/) {
      $yy = sprintf "%s_%s", $y, $ncol+1;
      my $kw = $1;
      $groups{$g}->dispose("set $g.$yy = $g.chi * $g.k**$kw", $dmode);
      $erase .= "erase $g.$yy\n";
    } else {
      $yy = sprintf "%s_%s", $y, $ncol+1;
      if ($y eq 'deriv') {
	$groups{$g}->dispose("set $g.$yy = deriv($g.xmu)/deriv($g.energy)", $dmode);
      } elsif (($y eq 'norm') and ($groups{$g}->{bkg_flatten})) {
	$groups{$g}->dispose("set $g.$yy = $g.flat", $dmode);
      } else {
	$groups{$g}->dispose("set $g.$yy = $g.$y", $dmode);
      };
      $erase .= "erase $g.$yy\n";
    };
    $command .= ", $g.$yy";
    ++$ncol;
    $alt_label .= " $ncol";
    my $nmess = $ncol+1;
    my $ntit = $ncol+2;
    $groups{$g}->dispose("\$marked_title_$ntit = \"$groups{$g}->{label} (column $nmess)\"");
    $erase .= "erase \$marked_title_$ntit\n"
  };
  $Text::Wrap::huge = 'overflow';
  ## extremely long column label strings can lead to weirdness as the ifeffit
  ## string gets written past the end.  if it's too long, use he alt_label,
  ## which is boring and non-descriptive, but safe
  if (length($label) < 255) {
    $command .= ", label=\"$label\"";
  } else {
    $command .= ", label=\"$alt_label\"";
  };
  $command  = wrap("write_data(", "           ", $command.")");
  ##$command .= ",\n           label=\"$label\")";
  $groups{$current} -> dispose($command, $dmode);
  $groups{$current} -> dispose($erase,   $dmode); # clean up the mess
  $top -> Unbusy;
  Echo("Saving $mess for each marked group ... done!");
};

sub save_each {
  my ($sp) = @_;
  my $m = 0;
  map {$m += $_} values %marked;
  Error("Saving files aborted.  There are no marked groups."), return 1 unless ($m);

  my $d = $top->DialogBox(-title   => "Artemis: Save each marked group to a directory",
			  -buttons => ["Select", "Cancel"],
			  ##-popover => 'cursor'
			 );

  my $curr_dir = $current_data_dir;
  my $label = $d -> add('Label', -textvariable=>\$curr_dir)
    -> pack(-fill => "x", -expand => 1);
  my $fr = $d -> add('Frame') -> pack(-fill => "both", -expand => 1);
  ## ----> need a create new directory button <----
  my $dt = $fr->Scrolled('DirTree',
			 -scrollbars	   => 'osoe',
			 -width		   => 55,
			 -height	   => 20,
			 -selectmode	   => 'browse',
			 -exportselection  => 1,
			 -directory	   => $current_data_dir,
			 -browsecmd	   => sub { $curr_dir = shift },

			 # With this version of -command a double-click will
			 # select the directory
			 ##-command	   => sub { $ok = 1 },

			 # With this version of -command a double-click will
			 # open a directory. Selection is only possible with
			 # the Ok button.
			 #-command	   => sub { $d->opencmd($_[0]) },
			)
    ->pack(-fill => "both", -expand => 1);
  my $this = $d -> Show();
  Echo("Not saving each marked file"), return if ($this eq 'Cancel');

  my $text = q{};
  my @list = (&sorted_group_list);
  foreach my $g (@list) {
    next if not $marked{$g};
    Echonow("Saving $groups{$g}->{label} in \"$curr_dir\" ...");
    $text = save_chi($sp, $g, $curr_dir);
  };
  Echo("Saved $text data to \"$curr_dir\" ...");
};


sub set_defaults {
  my ($group, $space, $is_xmudat) = @_;
 SWITCH:{
    ($space =~ /[aenx]/) and do {
      ## set e0, kmax, Emax values
      if ($is_xmudat) {		# for an xmu.dat file use computed e0
	my @x = Ifeffit::get_array("$group.energy");
	my $omega = $x[0];
	@x = Ifeffit::get_array("$group.e_wrt0");
	$omega -= $x[0];
	$omega += $is_xmudat;
	##print "omega = $omega\n";
	$groups{$group} -> make(bkg_e0=>$omega, bkg_spl1=>0, update_bkg=>1,
				bkg_flatten=>1, bkg_fixstep=>1, bkg_step=>1.0);
      } else {			# else look for max first deriv
	$groups{$group} ->
	  dispose("## need to get e0 to set defaults...\npre_edge(\"$group.energy+$groups{$group}->{bkg_eshift}\", $group.xmu)\n", $dmode);
	my $e0 = Ifeffit::get_scalar("e0");
	unless ($e0) {		# deal with situation where pre_edge
	  $groups{$group} ->	# fails to return an e0 value
	    dispose("## failed to find e0 with the pre_edge command, take max of derivative",
		    $dmode);
	  my $sets = "set($group.derv = deriv($group.xmu)/deriv($group.energy),\n";
	  $sets   .= "    i___i = ceil($group.derv),\n";
	  $sets   .= "    i___i = nofx($group.derv, i___i))\n";
	  $groups{$group} -> dispose($sets, $dmode);
	  $e0 = Ifeffit::get_scalar("i___i");
	  if ($e0 < 5) {
	    $e0 = 15;
	    $groups{$group} -> dispose("## max of derivative was very close to the beginning of the data, e0 set to 15th data point", $dmode);
	  };
	  my @array = Ifeffit::get_array("$group.energy");
	  $e0 = $array[$e0-1];
	  $groups{$group} -> dispose("erase i___i $group.derv", $dmode);
	};
	$groups{$group} -> make(bkg_e0=>$e0);
      };

      ## set defaults of the various range parameters
      my ($pre1, $pre2, $nor1, $nor2, $spl1, $spl2, $kmin, $kmax) =
	set_range_params($group);
      $groups{$group} -> make(
			      bkg_pre1	 => $pre1,
			      bkg_pre2	 => $pre2,
			      bkg_nor1	 => $nor1,
			      bkg_nor2	 => $nor2,
			      bkg_spl1	 => $spl1,
			      bkg_spl2	 => $spl2,
			      bkg_spl1e	 => $groups{$group}->k2e($spl1),
			      bkg_spl2e	 => $groups{$group}->k2e($spl2),
			      fft_kmin	 => $kmin,
			      fft_kmax	 => $kmax,
			      update_bkg => 1,
			     );
      if ($groups{$group}->{is_xmudat}) {
	$groups{$group}->make(bkg_nor2=>$groups{$group}->{bkg_spl2e});
      };
      if ($groups{$group}->{fft_kmax} == 999) {
	if ($groups{$group}->{is_xanes}) {
	  $groups{$group}->make(fft_kmax=>$groups{$group}->e2k($config{xanes}{cutoff}));
	} else {
	  $groups{$group} -> kmax_suggest(\%plot_features);
## 	  if ($groups{$group}->{fft_kmax} < EPSI) {
## 	    $groups{$group} -> dispose("set ___x = ceil($group.k)\n", 1);
## 	    $groups{$group} -> make(fft_kmax=>Ifeffit::get_scalar("___x"));
## 	  };
	};
      };
      last SWITCH;
    };
    ($space eq 'd') and do {
      my @en = Ifeffit::get_array("$group.energy");
      $groups{$group} -> make(bkg_e0=>$en[0]-$plot_features{emin});
      last SWITCH;
    };
    ($space eq 'k') and do {
      $groups{$group}->dispose("___x = ceil($group.k)\n", 1);
      my $maxk = Ifeffit::get_scalar("___x");
      ## need to set fft_kmax correctly
      $groups{$group} -> make(fft_kmax=>$maxk, update_bkg=>0, fft_pc=>'off');
      last SWITCH;
    };
  };
};


sub set_range_params {
  my $group = $_[0];
  ## PRE1
  my @en = Ifeffit::get_array("$group.energy");
  my $firstE  = ($en[1] - $groups{$group}->{bkg_e0});
  my $secondE = ($en[2] - $groups{$group}->{bkg_e0});
  #my $pre1 = $groups{$group}->{bkg_pre1};
  my $pre1 = $groups{$group}->Default('bkg_pre1') || $config{bkg}{pre1};
  ($pre1 *= 1000) if (($pre1 > -1) and ($pre1 < 1));
 PRE1: {
    ($pre1 = $firstE+$pre1), last PRE1 if ($pre1 > 0);
    ($pre1 = $secondE),      last PRE1 if ($pre1 == 0);
    ($pre1 = $secondE),      last PRE1 if ($pre1 < $secondE);
  };

  ## PRE2
  #my $pre2 = $groups{$group}->{bkg_pre2};
  my $pre2 = $groups{$group}->Default('bkg_pre2') || $config{bkg}{pre2};
  ($pre2 *= 1000) if (($pre2 > -1) and ($pre2 < 1));
 PRE2: {
    ($pre2 = $firstE+$pre2), last PRE2 if ($pre2 > 0);
    ($pre2 = $secondE/2),    last PRE2 if ($pre2 < $secondE);
  };
  (($pre1,$pre2) = ($pre2,$pre1)) if ($pre1 > $pre2);
  #($pre2 = ($pre1>30) ? $pre1+30 : $pre1/2) if ($pre1 < $pre2);

  ## NOR1
  my $lastE  = ($en[$#en] - $groups{$group}->{bkg_e0});
  #my $nor1 = $groups{$group}->{bkg_nor1};
  my $nor1 = $groups{$group}->Default('bkg_nor1') || $config{bkg}{nor1};
  ($nor1 *= 1000) if (($nor1 > 0) and ($nor1 < 5));
 NOR1: {
    if ($groups{$group}->{is_xanes}) {
      $nor1 = $config{xanes}{nor1};
      ($nor1 += $lastE) if ($nor1 < 0);
      last NOR1;
    };
    ($nor1 = $lastE/5),     last NOR1 if ($nor1 > $lastE);
    ($nor1 = $lastE+$nor1), last NOR1 if ($nor1 < 0);
  };

  ## NOR2
  my $nor2 = $groups{$group}->Default('bkg_nor2') || $groups{$group}->{bkg_nor2};
  ($nor2 *= 1000) if (($nor2 > -5) and ($nor2 < 5));
 NOR2: {
    if ($groups{$group}->{is_xanes}) {
      $nor2 = $config{xanes}{nor2};
      if    ($nor2 < 0)      { $nor2 += $lastE }
      elsif ($nor2 == 0)     { $nor2  = $lastE }
      elsif ($nor2 > $lastE) { $nor2  = $lastE };
      last NOR2;
    };
    ($nor2 = $lastE),       last NOR2 if ($nor2 > $lastE);
    ($nor2 = $lastE),       last NOR2 if ($nor2 == 0);
    ($nor2 = $lastE+$nor2), last NOR2 if ($nor2 < 0);
  };
  ($nor1 > $nor2) and (($nor1, $nor2) = ($nor2, $nor1));

  ## SPL1
  my $lastk  = $groups{$group}->e2k($lastE);
  my $spl1 = $groups{$group}->Default('bkg_spl1') || $groups{$group}->{bkg_spl1};
 SPL1: {
    ($spl1 = 0.5),          last SPL1 if ($groups{$group}->{is_xanes});
    ($spl1 = 0.5),          last SPL1 if ($spl1 > $lastk);
    ($spl1 = $lastk+$spl1), last SPL1 if ($spl1 < 0);
  };

  ## SPL2
  my $spl2 = $groups{$group}->Default('bkg_spl2') || $groups{$group}->{bkg_spl2};
 SPL2: {
    ($spl2 = $lastk),       last SPL2 if ($groups{$group}->{is_xanes});
    ($spl2 = $lastk),       last SPL2 if ($spl2 > $lastk);
    ($spl2 = $lastk),       last SPL2 if ($spl2 == 0);
    ($spl2 = $lastk+$spl2), last SPL2 if ($spl2 < 0);
  };
  ($spl1 > $spl2) and (($spl1, $spl2) = ($spl1, $lastk));

  ## FFT_KMIN
  my $kmin = $groups{$group}->Default('fft_kmin') || $groups{$group}->{fft_kmin};
 KMIN: {
    ($kmin = 2),            last KMIN if ($groups{$group}->{is_xanes});
    ($kmin = 2),            last KMIN if ($kmin > $lastk);
    ($kmin = $lastk+$kmin), last KMIN if ($kmin < 0);
  };

  ## FFT_KMAX
  my $kmax = $groups{$group}->Default('fft_kmax') || $groups{$group}->{fft_kmax};
 KMAX: {
    ($kmax = $lastk),       last KMAX if ($groups{$group}->{is_xanes});
    ($kmax = 999),          last KMAX if (not $kmax);
    ($kmax = $lastk),       last KMAX if ($kmax > $lastk);
    ($kmax = $lastk+$kmax), last KMAX if ($kmax < 0);
  };
  #($kmax = $lastk) if ($kmax < EPSI);
  ($kmin > $kmax) and (($kmin, $kmax) = ($kmax, $kmin));
  ##print "in set_range: $group $kmax\n";

  ($pre2 = $pre1+5)  if ($pre2 < $pre1);
  ($nor2 = $nor1+50) if ($nor2 < $nor1);
  ($spl2 = $spl1+50) if ($spl2 < $spl1);
  ($kmax = $kmin+5)  if ($kmax < $kmin);
  return ($pre1, $pre2, $nor1, $nor2, $spl1, $spl2, $kmin, $kmax);
};



## first arg is 1 when this is called from the Help menu, 0 otherwise
## second arg is 1 if called after reading a file, 0 otherwise
sub memory_check {
  my ($just_checking, $reading_file) = @_;
  Echo ("Cannot check memory with this version of Ifeffit"), return 0 if ($max_heap == -1);
  my $free = Ifeffit::get_scalar("\&heap_free");
  my $used = $max_heap - $free;
  my $ngr  = keys %groups;
  --$ngr;
  Echo("You have not used any memory yet."), return 0 unless $ngr;
  my $per  = ($ngr) ? $used / $ngr : 0;
  my $more = ($ngr) ? int($free / $per) : 0;
  $per =  int($per/1024);
  $free = int($free/1024);
  $used = int($used/1024);
  my $net = int($max_heap / 1024);
  my $report = "\n\nNumber of groups: $ngr
Memory used per group: $per kB
Memory space used: $used kB
Memory space free: $free kB
Total memory space: $net kB
Approximate number of groups available: $more
";
  if ($just_checking) {
    my $message = "Ifeffit's current memory usage:$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'info',
		     -text           => $message,
		     -title          => 'Athena: memory check',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return 0;
  } elsif ($more < 2) {
    my $message = "Ifeffit is nearly out of memory space!!!
Athena will not read more data until you
delete some groups.\n\n$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'error',
		     -text           => $message,
		     -title          => 'Athena: Out of memory space',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return -1;
  } elsif (($more < 5) and $reading_file) {
    my $message = "You are running out of Ifeffit memory space!!!
Reading this data group is probably ok, but you
need to delete some groups before reading
more data.\n\n$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => $message,
		     -title          => 'Athena: memory space running low',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return 1;
  } elsif (($more < 10) and (not $reading_file)) {
    my $message = "You are running out of Ifeffit memory space!!!
You should probably delete some groups to
free up space before continuing with any
operation.\n\n$report";
    my $dialog =
      $top -> Dialog(-bitmap         => 'warning',
		     -text           => $message,
		     -title          => 'Athena: memory space running low',
		     -buttons        => ['OK'],
		     -default_button => 'OK');
    my $response = $dialog->Show();
    return 1;
  };
  return 1;
};


sub fetch_url {
  my $remote = "";
  my $label  = "URL of the remote file: ";
  my $dialog = get_string($dmode, $label, \$remote, \@web_buffer);
  $dialog -> waitWindow;	# the get_string dialog will be
                                # destroyed once the user hits ok,
                                # then we can move on...
  Echo("Aborting web fetch of data."), return unless ($remote);
  Echo("Fetching $remote ...");
  $top -> Busy;
  my @parts = split(/\//, $remote);
  (-d $webdir) or mkpath($webdir);
  my $local = File::Spec->catfile($webdir, $parts[$#parts]);
  my $response = getstore($remote, $local);
  $top -> Unbusy;
  Echo("$remote: HTTP status $response -- " . status_message($response));
  return unless (-e $local);
  push @web_buffer, $remote;
  &read_file(0, $local);
};

sub purge_web_cache {
  return unless -d $webdir;
  opendir C, $webdir;
  map { my $f = File::Spec->catfile($webdir, $_); -f $f and unlink $f}
    (grep !/^\.{1,2}$/, readdir C);
  closedir C;
  Echo("Purged web cache: $webdir");
};


## this wacko sub is to satisfy the Aussie contingent.  The output
## file is something that can be read in by Xfit.  The idea is for
## someone to use Athena for data processing and Xfit for data
## analysis.  Whatever.
sub write_xfit_file {
  Error("Only mu(E) data can be saved as an xfit file."), return unless
    ($groups{$current}->{is_xmu});

  #local $Tk::FBox::a;
  #local $Tk::FBox::b;
  my $path = $current_data_dir || Cwd::cwd;
  my $types = [["Xfit data", ".xfit"], ['All', '*']];
  my $initial = join(".", $groups{$current}->{label}, "xfit");
  # spaces are common in filenames on Mac and Win, but not on un*x
  ($initial =~ s/\s+/_/g) unless ($is_windows or $is_darwin);
  ($initial =~ s/[\\:\/\*\?\'<>\|]/_/g);# if ($is_windows);
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 #(not $is_windows) ?
				 #  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialdir=>$path,
				 -initialfile=>$initial,
				 -title => "Athena: Save Xfit data");
  Echo("Saving Xfit data ... canceled", 0), return unless ($file);

  my ($com,$sep) = ("", ",");	 # xfit-able
  #my ($com,$sep) = ("#", "  "); # readable by gnuplot
  #Error("Cannot write to $file"), return unless (-w $file);
  open F, ">".$file;
  ## write boilerplate headers
  printf F ("%sAVERAGE
%s  ABSORBER   %s
%s  EDGE       %s
%s  E0         %.2f eV
%s
",
	    $com,
	    $com, ucfirst(Chemistry::Elements::get_name($groups{$current}->{bkg_z})),
	    $com, $groups{$current}->{fft_edge},
	    $com, $groups{$current}->{bkg_e0},
	    $com
	   );
  printf F ("%sSPLINE
%s  ABSORBER   %s
%s  EDGE       %s
%s  E0         %.2f eV
%s  WEIGHT     K**%.1f
%s  WINDOW     %.2f-%.2f (0.20) angstrom**-1
%s  BACKGROUND
%s  SPLINE
%s  CORRECTION OFF
%s
",
	    $com,
	    $com, ucfirst(Chemistry::Elements::get_name($groups{$current}->{bkg_z})),
	    $com, $groups{$current}->{fft_edge},
	    $com, $groups{$current}->{bkg_e0},
	    $com, $groups{$current}->{bkg_kw},
	    $com, $groups{$current}->{bkg_spl1},
	    $groups{$current}->{bkg_spl2},
	    $com, $com, $com, $com);
  print F $com . "DATA
$com  EV ENERGY
$com  EV X-ray energy in eV
$com  RAW ABSORBANCE
$com  RAW Sample absorbance
$com  FOIL Foil absorbance
$com  BACKGROUND PREEDGE
$com  BACKGROUND Background absorbance
$com  NORMAL Normalised absorbance
$com  SPLINE Polynomial spline
$com  K K-SCALE
$com  K Photoelectron momentum
$com  XAFS EXAFS
$com  XAFS X-ray absorption fine structure
$com
$com EV RAW BACKGROUND NORMAL SPLINE K XAFS
";
  ## columns: energy, mu, pre-edge, norm, normbkg, k, chik
  ## k is converted from E, negative values set to 0
  ## comma separated
  my $gp = $groups{$current}->{group};
  my @e = Ifeffit::get_array("$gp.energy");
  my @x = Ifeffit::get_array("$gp.xmu");
  my @b = Ifeffit::get_array("$gp.bkg");
  my @n = Ifeffit::get_array("$gp.norm");
  my $e0 = $groups{$current}->{bkg_e0};
  foreach my $i (0 .. $#e) {
    my $pre = $groups{$current}->{bkg_int} +
      $groups{$current}->{bkg_slope}*($e[$i] + $groups{$current}->{bkg_eshift});
    my $normbkg = ($b[$i] - $pre)/$groups{$current}->{bkg_step};
    my $k = ($e[$i] < $e0) ? "0" : sprintf("%.5f",sqrt(ETOK * ($e[$i]-$e0)));
    my $chik = $n[$i] - $normbkg;
    printf F " %.5f%s%.11f%s%.11f%s%.11f%s%.11f%s%s%s%.11f\n",
      $e[$i], $sep, $x[$i], $sep, $pre, $sep, $n[$i], $sep,
	$normbkg, $sep, $k, $sep, $chik;
  };

  close F;
  Echo("Wrote $groups{$current}->{label} to an Xfit file.");
};




## END OF DATA INPUT SUBSECTION
##########################################################################################
