# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2007 Bruce Ravel
##
## convert a feffit input file (and its include files) into an artemis
## project


sub feffit_convert_input {
  my ($file) = @_;

  my @feffit = ();
  $feffit[0] = {titles=>[], opparams=>{}, path=>[], feffcalcs=>[]};
  my @gds    = ();


  my $pth = $current_data_dir || cwd;
  my $types = [['Feffit input file', '*.inp'],
	       ['All files',         '*'],];
  $file ||= $top -> getOpenFile(-filetypes=>$types,
				##(not $is_windows) ?
				##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				-initialdir=>$pth,
				-title => "Artemis: Open a feffit input file");
  return unless ($file);
  Error("$file does not exist!"), return unless (-e $file);
  my ($name,$path,$suffix) = fileparse($file);

  open *I, $file or die "could not open $file for reading";
  feffit_parse_file(\@feffit, \@gds, $path, *I);
  close *I;
  feffit_finish(\@feffit, \@gds, $path, $file);

  &push_mru($file, 1, "feffit");
  1;
};



sub feffit_parse_file {
  my ($r_feffit, $r_gds, $path, $file) = @_;
  while (<$file>) {
    next if m{^\s*$};		# blank lines
    next if m{^\s*[#!*%]};	# comment lines
    chomp;
    feffit_parse_line($r_feffit, $r_gds, $path, $_);
  };
  return 1;
};


sub feffit_parse_line {
  my ($r_feffit, $r_gds, $path, $line) = @_;

  ## feffit keywords
  my @ignore = qw(format rspout kspout qspout allout bkgfile output);
  my @opparams = qw(bkg data kmin kmax rmin rmax dk dr kw nodegen);
  my $allre = join("|", @ignore, @opparams);
  my $igre  = join("|", @ignore);
  my $opre  = join("|", @opparams);
  my @pathparams = qw(path id e0 s02 sigma2 delr ei third fourth);
  my $ppre = join("|", @pathparams);

  $line =~ s{^\s+}{};		# trim leading blanks
  $line =~ s{\#.*$}{};		# trim trailing comments
  $line =~ s{\s+$}{};		# trim trailing blanks
  $line =~ s{nodegen}{nodegen=1};
  #$line = lc($line);
  my $dataset = $#{$r_feffit};
 LINE: {
    ($line =~ m{\Anext}i) and do {
      ++$dataset;
      $r_feffit->[$dataset] = {titles=>[], opparams=>{}, path=>[], feffcalcs=>[]};
      last LINE;
    };

    ($line =~ m{\Atitle}i) and do {
      $line =~ s{\Atitle\s*[ \t=,]\s*}{}i;
      ## $line now contains the title line, push it onto titles list
      push @{ $r_feffit->[$dataset]->{titles} }, $line;
      last LINE;
    };

    ($line =~ m{\A(?:guess|local|set)}i) and do {
      ## $line now contains the gds line, push it onto gds list
      push @$r_gds, $line;
      last LINE;
    };

    ($line =~ m{^end}i) and do {
      feffit_finish($r_feffit, $r_gds, $path);
      last LINE;
    };

    ($line =~ m{^include}i) and do {
      $line =~ s{\Ainclude\s*[ \t=,]\s*}{}i;
      ## $line now contains the include file, call feffit_parse_file
      my $newfile = File::Spec->catfile($path,$line);
      open *INC, $newfile or die "could not read from $newfile\n";
      feffit_parse_file($r_feffit, $r_gds, $path, *INC);
      close *INC;
      last LINE;
    };

    ($line =~ m{^($ppre)\s*[ \t=,]\s*(\d+)\s*[ \t=,]\s*(.*)}i) and do {
      ## push this path parameter onto its list
      feffit_parse_pathparam($r_feffit, $line);
      last LINE;
    };

    ($line =~ m{^(?:$allre)\s*[ \t=,]\s*}i) and do {
      feffit_parse_opparam($r_feffit, $line, $path);
      last LINE;
    };
  };
};


sub feffit_parse_pathparam {
  my ($r_feffit, $line) = @_;
  $line =~ s{[#!%].*$}{};	# remove end of line comments
  my @pathparams = qw(path id e0 s02 sigma2 delr ei third fourth);
  my $ppre = join("|", @pathparams);
  $line =~ m{^($ppre)\s*[ \t=,]\s*(\d+)\s*[ \t=,]\s*(.*)}i;
  my ($pp, $index, $me) = ($1, $2, $3);
  my $dataset = $#{$r_feffit};
  $r_feffit->[$dataset]->{path}->[$index]->{$pp} = $me;
};

sub feffit_parse_opparam {
  my ($r_feffit, $line, $path) = @_;
  $line =~ s{[#!%].*$}{};	# remove end of line comments
  my @ignore = qw(format rspout kspout qspout allout bkgfile output);
  my @opparams = qw(bkg data kmin kmax rmin rmax dk dr kw);
  my $allre = join("|", @ignore, @opparams);
  my $igre  = join("|", @ignore);
  my $opre  = join("|", @opparams);
  my %words = split(/\s*[ \t=,]\s*/, $line);
  my $dataset = $#{$r_feffit};
  foreach my $key (keys %words) {
    next if (lc($key) =~ m{\A$igre\z}); # ignore some opparams
    ## store the good opparams for this data set
    if (lc($key) eq 'data') {
      my $datafile = File::Spec->catfile($path, $words{$key});
      $r_feffit->[$dataset]->{opparams}->{data} = $datafile;
    } elsif (lc($key) eq 'bkg') {
      if ($r_feffit->[$dataset]->{opparams}->{bkg} =~ m{^[1yt]}) {
	$r_feffit->[$dataset]->{opparams}->{bkg} = 'yes';
      } else {
	$r_feffit->[$dataset]->{opparams}->{bkg} = 'no';
      };
    } else {
      $r_feffit->[$dataset]->{opparams}->{$key} = $words{$key};
    };
  };
};


sub feffit_finish {
  my ($r_feffit, $r_gds, $path, $inpfile) = @_;
  feffit_cull_mkw($r_feffit);
  feffit_find_feffcalcs($r_feffit);

  my %fix = feffit_load_gds($r_gds);
  feffit_load_data($r_feffit, $path);
  feffit_fix_gds(%fix);

  $notes{messages} -> delete(qw(1.0 end));
  use Data::Dumper;
  $notes{messages} -> insert('end', Data::Dumper->Dump([$r_feffit], [qw(*feffit)]));
  $notes{messages} -> insert('end', "\n");
  $notes{messages} -> insert('end', Data::Dumper->Dump([$r_gds], [qw(*gds)]));
  display_file('file', $inpfile) if $inpfile;
  $top -> update;
  raise_palette('messages');
  display_page('data0');
  plot('r', 0);
  Echo("Imported feffit input file");
};


sub feffit_cull_mkw {
  my ($r_feffit) = @_;
  my $first_data = $r_feffit->[0]->{opparams}->{data};
  foreach my $i (1 .. $#{$r_feffit}) {
    my $this_data = $r_feffit->[$i]->{opparams}->{data};
    next if ($this_data ne $first_data);
    my $first_kw = $r_feffit->[0]->{opparams}->{kw};
    $first_kw .= ',' . $r_feffit->[$i]->{opparams}->{kw};
    $r_feffit->[0]->{opparams}->{kw} = $first_kw;
    $r_feffit->[$i] = undef;
  };

};

sub feffit_find_feffcalcs {
  my ($r_feffit) = @_;
  foreach my $set (@$r_feffit) {
    next if not defined($set);
    my %seen;
    my @dirlist;
    my $list = $set->{path};
    my $count = -1;
    foreach my $p (@$list) {
      next if not defined($p);
      my $nnnn = $p->{path};
      next if not defined($nnnn); # take care with path 0
      my $pth = dirname($nnnn);
      $seen{$pth} or push @dirlist, $pth;
      ++$seen{$pth};
    };
    foreach my $feff (@dirlist) {
      push @{$set->{feffcalcs}}, $feff;
    };
  };
};


sub feffit_load_gds {
  my ($r_gds) = @_;
  my %fix = ();
  my $count = 0;
  foreach my $text (@$r_gds) {
    $text =~ s{[#!%].*$}{};	# remove end of line comments
    $text =~ s{\s+$}{};		# trim trailing blanks
    my (@words) = split(/\s*[ \t=,]\s*/, $text);
    my $type = shift @words;
    my $name = shift @words;
    my $me   = join("", @words);
    ## make it a def if it's a math expression and a set if its a number
    if (($type eq 'set') and ($me !~ m{\A[+-]?(?:\d+\.?\d*|\.\d+)\z})) {
      $type = 'def';
    };
    ($type = 'skip') if ($type eq 'local'); # punt for now
    ++$count;
    jump_to_variable(lc($name), $type, 1, $me);
    my $regex = join("|", qw(e0 ei s02 sigma2 third fourth dr dr1 dr2 dk dk1 dk2 etok pi));
    if (lc($name) =~ m{\A($regex)\z}) {
      $fix{lc($name)} = $count;
    };
  };
  return %fix;
  gds2_display(1);
};

sub feffit_fix_gds {
  my %fix = @_;
  my %replacement = ( e0     => 'enot',
		      ei     => 'eimag',
		      s02    => 's_02',
		      sigma2 => 'sigsqr',
		      third  => 'cumul3',
		      fourth => 'cumul4',
		      dr     => 'd_r',
		      dr1    => 'dr_1',
		      dr2    => 'dr_2',
		      dk     => 'd_k',
		      dk1    => 'dk_1',
		      dk2    => 'dk_2',
		      etok   => 'e2k',
		      pi     => 'pie',
		    );
  foreach my $k (keys %fix) {
    gds2_search_replace($fix{$k}, $replacement{$k});
  };
  gds2_display(1);
};


sub feffit_load_data {
  my ($r_feffit, $path) = @_;
  foreach my $set (@$r_feffit) {
    next if not defined($set);
    my $fname = $set->{opparams}->{data};

    ## import the data
    my $group = read_data(0, $fname, 0, 1);

    ## import the operational parameter values and titles
    foreach my $k (qw(kmin kmax rmin rmax dk)) {
      $paths{$group}->make($k=>$set->{opparams}->{$k}) if $k;
    };
    $paths{$group}->make(k1=>1) if ($set->{opparams}->{kw} =~ m{1});
    $paths{$group}->make(k2=>1) if ($set->{opparams}->{kw} =~ m{2});
    $paths{$group}->make(k3=>1) if ($set->{opparams}->{kw} =~ m{3});
    $paths{$group}->make(kwindow=>'Hanning');
    $paths{$group}->make(rwindow=>'Hanning');

    $widgets{op_titles} -> insert('1.0', "\n") if (@{ $set->{titles} });
    foreach my $text (reverse @{ $set->{titles} }) {
      $widgets{op_titles} -> insert('1.0', $text."\n");
    };

    ## import the feff calculations
    my %pathto;
    my $save = $config{autoparams}{do_autoparams};
    $config{autoparams}{do_autoparams} = 0;
    foreach my $dir (@{ $set->{feffcalcs} }) {
      my $feffinp = File::Spec->catfile($path, $dir, "feff.inp");
      my $id = read_feff($feffinp, 1);
      $pathto{$dir} = $id;
    };

    ## import the feff paths and set their path parameters
    my $default = {id=>q{}, s02=>1, e0=>0, delr=>0, sigma2=>0, third=>0, fourth=>0};
    my $pathzero = $set->{path}->[0];
    if (not defined($pathzero)) {
      $pathzero = {id=>q{}, s02=>1, e0=>0, delr=>0, sigma2=>0, third=>0, fourth=>0};
    };
    foreach my $p (@{ $set->{path} }) {
      next if not defined($p);

      my $pth = $p->{path};
      next if not defined($pth); # take care with path 0
      $pth    = dirname($pth);
      my $id  = $pathto{$pth};
      $pth    = $paths{$id}->{path};

      my $nnnn = File::Spec->catfile($pth, basename($p->{path}));
      next if (not -e $nnnn);	# shelly's mkfit will make entries for paths that fail the crits2
      my $key = add_a_path($nnnn, 1, 0);

      $paths{$key}->make('label'   => $p->{id}         || $pathzero->{id}         || $default->{id}    );
      $paths{$key}->make('s02'     => lc($p->{s02})    || lc($pathzero->{s02})    || $default->{s02}   );
      $paths{$key}->make('e0'      => lc($p->{e0})     || lc($pathzero->{e0})     || $default->{e0}    );
      $paths{$key}->make('delr'    => lc($p->{delr})   || lc($pathzero->{delr})   || $default->{delr}  );
      $paths{$key}->make('sigma^2' => lc($p->{sigma2}) || lc($pathzero->{sigma2}) || $default->{sigma2});
      $paths{$key}->make('ei'      => lc($p->{ei})     || lc($pathzero->{ei})     || $default->{ei}    );
      $paths{$key}->make('3rd'     => lc($p->{third})  || lc($pathzero->{third})  || $default->{third} );
      $paths{$key}->make('4th'     => lc($p->{fourth}) || lc($pathzero->{fourth}) || $default->{fourth});

    };

    # respect the nodegen flag
    if ($set->{opparams}->{nodegen}) {
      foreach my $dir (@{ $set->{feffcalcs} }) {
	display_page($pathto{$dir});
	set_degeneracy(1);
      };
    };

    $config{autoparams}{do_autoparams} = $save;

    display_page($group);
  };
};

##  END OF THE SECTION ON FEFFIT CONVERSION

