# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##
## THE PALETTES SUBSECTION

sub display_file {
  my ($type, $fname) = @_;
  Echo("No feff calculation!"), return if (($type eq 'path') and ($n_feff == 0));
 SWITCH: {
    last SWITCH if ($type =~ /^\s*$/);
    $fname = $paths{$current}->get($fname),         last SWITCH if  ($type eq 'feff') ;
    $fname = File::Spec->catfile($paths{$current}->get('path'),
				 $paths{$current}->get('feff')),
				                    last SWITCH if (($type eq 'path') and
								    ($fname eq 'this'));
    $fname = File::Spec->catfile($paths{$current}->get('path'), $fname),
				                    last SWITCH if ($type eq 'path');
    ## dereference the group that a fit or bkg is the same as
    $fname = $paths{$current}->get('file'),
                                                    last SWITCH if (($type eq 'data') and
								    ($fname eq 'this') and
								    $paths{$current}->get('sameas'));
    ## dereference the group that a path or feff refers to
    $fname = $paths{$current}->get('file'),
                                                    last SWITCH if (($type eq 'data') and
								    ($fname eq 'this') and
								    ($current =~ /feff\d+/));
    $fname = $paths{$current}->get('file'),         last SWITCH if (($type eq 'data') and
								    ($fname eq 'this'));
    Echo("Want to display $fname"), return unless ($type eq 'file');
  };
  ## paths file, deal with feff6 vs. feff8!!
  ($fname = substr($fname, 0, -9)."path00.dat") if (($fname =~ /paths\.dat$/) and (not -e $fname));
  Echo("You have not read any data yet"), return unless (defined $fname);
  Echo("The file you asked for could not be found"), return unless (-e $fname);
  Echo("Displaying $fname");
  $current_file = $fname;
  $notes{files} -> delete(qw(1.0 end));

  my $was_mac = $paths{data0} ->
    fix_mac($fname, $stash_dir, lc($config{general}{mac_eol}), $top);
  return, Echo("\"$fname\" had Macintosh EOL characters and was skipped.") if ($was_mac eq "-1");
  if ($was_mac !~ m{^(?:0|-?1)}) {
    Echo("\"$fname\" had Macintosh EOL characters and was fixed.");
    $fname = $was_mac;
  };

  Echo("Could not find \"$fname\""), return unless (-e $fname);
  open F, "$fname" or die "Could not open $fname for viewing.\n";
  while (<F>) {
    $_ =~ s{\r}{}g if not $is_windows;
    $notes{files} -> insert('end', $_);
  };
  close F;
  $notes{files} -> yviewMoveto(0);
  $top      -> update;
  raise_palette('files');
};

sub show_things {
  if ($_[0] eq 'paths') {
    my $error = "";
    $error   .= &verify_parens;
    if ($error) {
      post_message($error, "Error Messages");
      Error("cannot show paths due to errors in parameters and math expressions");
      return;
    };
  };
  $paths{data0}->dispose("show \@$_[0]", $dmode);
  $top -> update();
  raise_palette('ifeffit');
};

sub show_defs {
  my $which = &which_set_path;
  if ($which) {
    $paths{data0}->dispose("\n## Evaluating def parameters using " . $paths{$which}->descriptor(), $dmode);
    $paths{data0}->dispose("set path_index=" . $paths{$which}->get('fit_index'), $dmode);
  };
  my %seen;
  my @defs;
  foreach my $p (@gds) {
    push @defs, $p->name if ($p->type eq 'def');
  };
  $paths{data0}->dispose("show " . join(" ", @defs), $dmode);
  $top -> update();
  raise_palette('ifeffit');
};



## $pal     : key for %notes hash
## $init    : value for -initialfile
## $title   : value for -title
## $t       : anon array of values for $types list
## $prepend : text string to prepend to contents of $notes{$pal}
## $append  : text string to append to contents of $notes{$pal}
sub save_from_palette {
  my ($pal, $init, $title, $t, $prepend, $append) = @_;
  ##local $Tk::FBox::a;
  ##local $Tk::FBox::b;
  my $path = $current_data_dir || cwd;
  ##$path = File::Spec->catfile($project_folder, "log_files") if ($pal  eq 'results');
  ##$path = File::Spec->catfile($project_folder, "log_files") if ($pal  =~ /report/);
  ##$path = File::Spec->catfile($project_folder, "log_files") if ($init =~ /report/);
  my $types = ($t) ? [$t, ['All Files', '*']] : [['All Files', '*'], ['Input Files', '*.inp']];
  ($init =~ s/[\\:\/\*\?\'<>\|]/_/g);# if ($is_windows);
  my $file = $top -> getSaveFile(-filetypes=>$types,
				 ##(not $is_windows) ?
				 ##  (-sortcmd=>sub{$Tk::FBox::a cmp $Tk::FBox::b}) : () ,
				 -initialfile=>$init||$generic_name,
				 -initialdir=>$path,
				 -title => $title);
  return unless ($file);
  my ($name, $pth, $suffix) = fileparse($file);
  #if ($pal eq 'results') {
  #  project_state(0) if sub_directory($pth, $project_folder);
  #} else {
    $current_data_dir = $pth;
  #};
  open F, ">".$file or do {
    Error("You cannot write to \"$file\"."); return
  };
  print F $prepend, $notes{$pal}->get(qw(1.0 end)), $append;
  close F;

  $generic_name = "artemis.stuff";
  Echo("Saved contents of $pal palette to $file");
};




## post a text message to the "messages" palette
## args:  0:text of message  1:id string  2:hide palette
sub post_message {
  $notes{messages} -> delete(qw(1.0 end));
  $notes{messages} -> insert('end', $_[0]||"");
  $notes{messages} -> yviewMoveto(0);
  ##$current_file = $_[1] || "";
  $top -> update;
  raise_palette('messages') unless $_[2];
};


sub raise_palette {
  ##($update->state() eq "normal") ?
  $update->deiconify;
  $update->raise;
  $notebook->raise($_[0]);
};


sub write_results_header {
  my ($fh, $r_fit) = @_;
  foreach ('Project title', 'Comment', 'Prepared by', 'Contact', 'Started', 'Last fit', 'Environment') {
    my $this = $_;
    ($this = "This fit at") if ($this eq 'Last fit');
    print $fh sprintf("%-15s :  ", $this);
    print($fh "\n"), next if (not defined($props{$_}));
    print($fh "\n"), next if ($props{$_} =~ /^\<.*\>$/);
    print($fh "\n"), next if ($props{$_} =~ /^\s*$/);
    print $fh "$props{$_}\n";
  };
  my $string = q{};
  foreach my $d (&all_data) {
    $string .= '"' . $paths{$d}->get('lab') . '", ';
  };
  chop $string; chop $string;
  print $fh sprintf("%-15s :  %s\n", "Data sets", $string);
  print $fh sprintf("%-15s :  %s\n", "Fit label",       $$r_fit{label});
  print $fh sprintf("%-15s :  %s\n", "Figure of merit", $$r_fit{fom});
  print $fh "\n" . "=" x 60 . "\n\n";
};

sub write_results {
  my ($fh, $how, $how_many) = @_;  ## how=1 means fit, how=2 means summation
  ## compile a list of parameters in a sensible order
  my %seen;			# see The Perl Cookbook, 4.6, p. 102,
                                # need to weed out repeated params
  my @all = grep { $_->{name} } @gds;
  my (@params, @defs, @sets, @restraints, @afters);
  foreach my $p (@gds) {
    push @params,     lc($p->name) if ($p->type eq 'guess');
    push @defs,       lc($p->name) if ($p->type eq 'def');
    push @sets,       lc($p->name) if ($p->type eq 'set');
    push @restraints, lc($p->name) if ($p->type eq 'restrain');
    push @afters,     lc($p->name) if ($p->type eq 'after');
  };
  $paths{data0}->dispose("show \@variables", 1);
  my ($lines, $response) = (Ifeffit::get_scalar('&echo_lines'), "");
  my @bkg;
  foreach my $i (1 .. $lines) {
    my $this = (split(" ", Ifeffit::get_echo()))[0];
    push @bkg, $this if ($this =~ /^bkg\d\d_\d\d$/);
  };

  my @things = ('n_idp n_varys chi_square chi_reduced r_factor epsilon_k epsilon_r',
		@params, @defs, @bkg);
  my %things = ("n_idp"       => "Independent points          ",
		"n_varys"     => "Number of variables         ",
		"chi_square"  => "Chi-square                  ",
		"chi_reduced" => "Reduced Chi-square          ",
		"r_factor"    => "R-factor                    ",
		"epsilon_k"   => "Measurement uncertainty (k) ",
		"epsilon_r"   => "Measurement uncertainty (R) ",
		"data_total"  => "Number of data sets         ",
	       );
  if ($how == 1) {
    $paths{data0}->dispose("show n_idp n_varys chi_square chi_reduced r_factor epsilon_k epsilon_r data_total\n", 1);
    ($lines, $response) = (Ifeffit::get_scalar('&echo_lines'), "");
    map {$response .= Ifeffit::get_echo()."\n"} (1 .. $lines);
    foreach my $k (keys %things) {
      $response =~ s/($k)\s+/$things{$k}/eg;
    };
  } else {
    my $this = $paths{$paths{$current}->data}->descriptor();
    $response .= sprintf("%-70s\n", "!! FITTING WAS NOT PERFORMED.");
    $response .= sprintf("%-70s",   "!!   Summation performed for data set \"$this\" using $how_many paths.");
  };
  print $fh $response."\n";

  $response = "";
  if (@Ifeffit::Tools::buffer) {
    print $fh "!!                                                              \n";
    print $fh "!! WARNING.  The following variables had no effect on the fit:  \n";
    map {push @bad_params, $_; printf $fh "!!  >> %-58s\n", $_} @Ifeffit::Tools::buffer;
    print $fh "!!                                                              \n";
    print $fh "!! Uncertainties could not be estimated.                        \n";
    print $fh "!!                                                              \n";
  };
  print $fh "\nGuess parameters +/- uncertainties  (initial guess):\n";
  foreach my $p (@gds) {
    next unless ($p->{type} eq 'guess');
    my $string;
				## this variable had no effect on the fit ...
    if (grep {/$p/} @Ifeffit::Tools::buffer) {
				## ... and was guessed as a math expr.
      if ($p->{mathexp} !~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) {
	$string = sprintf("  %-15s =  %12.7f : no effect on the fit  (guessed as %s)\n",
			  $p->name,
			  $p->bestfit,
			  $p->mathexp);
				## ... and was guessed as a number
      } else {
	$string = sprintf("  %-15s =  %12.7f : no effect on the fit  (%.4g)\n",
			  $p->name,
			  $p->bestfit,
			  $p->mathexp);
      };
				## this variable was guessed as a math expr.
    } elsif ($p->{mathexp} !~ /^\s*-?(\d+\.?\d*|\.\d+)\s*$/) {
      $string = sprintf("  %-15s =  %12.7f   +/-   %12.7f    (guessed as %s)\n",
			$p->name,
			$p->bestfit,
			$p->error,
			$p->mathexp);
    } else {			## this variable was guessed as a number
      $string = sprintf("  %-15s =  %12.7f   +/-   %12.7f    (%.4f)\n",
			$p->name,
			$p->bestfit,
			$p->error,
			$p->mathexp);
    };
    print $fh $string;
  };
  if (@defs) {
    print $fh "\nDef parameters";
    my $which = &which_set_path;
    print $fh " (using \"" . $paths{$which}->descriptor() . "\")"
      if ($which);
    print $fh ":\n";
  };
  foreach (@gds) {
    next unless ($_->{type} eq 'def');
    my $string = sprintf("  %-15s =  %12.7f\n",
			 $_->{name},
			 $_->{bestfit});
    print $fh $string;
  };
  @restraints and print $fh "\nRestraints:\n";
  foreach (@gds) {
    next unless ($_->{type} eq 'restrain');
    my $string = sprintf("  %-15s =  %12.7f  :=  %s \n",
			 $_->name,
			 $_->bestfit,
			 $_->mathexp);
    print $fh $string;
  };
  @sets and print $fh "\nSet parameters:\n";
  foreach (@gds) {
    next unless ($_->{type} eq 'set');
    my $string = sprintf("  %-15s =  %s\n",
			 $_->name,
			 $_->mathexp);
    print $fh $string;
  };
  @afters and print $fh "\nAfter-fit parameters:\n";
  foreach (@gds) {
    next unless ($_->{type} eq 'after');
    my $string = sprintf("  %-15s : %12.7f = %s\n",
			 $_->name,
			 $_->bestfit,
			 $_->mathexp);
    print $fh $string;
  };
  @bkg and print $fh "\nBackground parameters +/- uncertainties:\n";
  foreach (@bkg) {
    my $string = sprintf "  %-15s =  %12.7f   +/-   %12.7f\n", $_,
      Ifeffit::get_scalar($_), Ifeffit::get_scalar("delta_$_");
    print $fh $string;
  };
  my $first = &first_data;
};


sub write_opparams {
  my ($fh, $d) = @_;
  my @lines = ();
  push @lines, sprintf("file: %s", $paths{$d}->get('file'));
  push @lines, "title lines:";
  foreach my $t (split(/\n/, $paths{$d}->get('titles'))) { push @lines, "  ".$t; };
  push @lines, "";
  push @lines, sprintf("k-range             = %.3f - %.3f", $paths{$d}->get('kmin'), $paths{$d}->get('kmax'));
  push @lines, sprintf("dk                  = %.3f", $paths{$d}->get('dk'));
  push @lines, sprintf("k-window            = %s", $paths{$d}->get('kwindow'));
  my @kw = ();
  push @kw, 1 if $paths{$d}->get('k1');
  push @kw, 2 if $paths{$d}->get('k2');
  push @kw, 3 if $paths{$d}->get('k3');
  push @kw, 1 unless @kw;
  push @kw, $paths{$d}->{karb} if $paths{$d}->get('karb');
  push @lines, sprintf("k-weight            = %s", join(",", @kw));
  push @lines, sprintf("R-range             = %.3f - %.3f", $paths{$d}->get('rmin'), $paths{$d}->get('rmax'));
  push @lines, sprintf("dR                  = %.3f", $paths{$d}->get('dr'));
  push @lines, sprintf("R-window            = %s", $paths{$d}->get('rwindow'));
  my $bkg = "none";
  ($bkg = "fitted spline") if ($paths{$d}->get('do_bkg') eq 'yes');
  ($bkg = "previous fit spline") if $paths{$d}->get('use_bkg');
  push @lines, sprintf("fitting space       = %s", $paths{$d}->get('fit_space'));
  push @lines, sprintf("background function = %s", $bkg);
  my $n_bkg_params = 0;
  if ($paths{$d}->get('do_bkg') eq 'yes') {
    $n_bkg_params = ($paths{$d}->get('kmax') - $paths{$d}->get('kmin') + $paths{$d}->get('dk'))
      * $paths{$d}->get('rmin')
	* 2 / PI;
    $n_bkg_params = round($n_bkg_params) + 1;
    push @lines, sprintf("spline parameters   = %d", $n_bkg_params);
  };
  if (lc($paths{$d}->get('pcpath')) eq 'none') {
    push @lines, "phase correction    = none";
  } else {
    push @lines, sprintf("phase correction    = %s", $paths{$paths{$d}->get('pcpath')}->descriptor());
  };
  push @lines, "fit the difference spectrum" if $paths{$d}->get('fit_diff');
  push @lines, "\n";
  ## compute chi-square and R-factor for this data set and for all its k-weightings
  my (@datasum, @diffsum, $ndata) = ((), (), 0);
  if (lc($paths{$d}->get('fit_space')) eq 'k') {
    my @k   = Ifeffit::get_array($paths{$d}->get('group').".k");
    my @chi = Ifeffit::get_array($paths{$d}->get('group').".chi");
    my @fit = Ifeffit::get_array($paths{$d}->get('group')."_fit.chi");
    my $i = 0;
    foreach my $w ($paths{$d}->group_weights) {
      $datasum[$i] = 0;
      $ndata = 0;
      foreach (0 .. $#k) {
	next if ($k[$_] < $paths{$d}->get('kmin'));
	last if ($k[$_] > $paths{$d}->get('kmax'));
	$datasum[$i] += ($chi[$_]*$k[$_]**$w)**2;
	$diffsum[$i] += ($chi[$_]*$k[$_]**$w - $fit[$_]*$k[$_]**$w)**2;
	++$ndata;
      };
      ++$i;
    };
  } elsif (lc($paths{$d}->get('fit_space')) eq 'r') {
    my $i = 0;
    foreach my $w ($paths{$d}->group_weights) {
      ## bring fit up to date in R space for this k-weight
      $paths{$d}->dispose($paths{$d}->write_fft($w, $config{data}{rmax_out}), $dmode);
      $paths{$d.".0"}->dispose($paths{$d.".0"}->write_fft($w, $config{data}{rmax_out}), $dmode);
      my @r    = Ifeffit::get_array($paths{$d}->get('group').".r");
      my @chi  = Ifeffit::get_array($paths{$d}->get('group').".chir_re");
      my @chi2 = Ifeffit::get_array($paths{$d}->get('group').".chir_im");
      my @fit  = Ifeffit::get_array($paths{$d}->get('group')."_fit.chir_re");
      my @fit2 = Ifeffit::get_array($paths{$d}->get('group')."_fit.chir_im");
      my $rmin = $paths{$d}->get('rmin');
      ($rmin = 0) if (lc($paths{$d}->get('do_bkg')) eq 'yes');
      $datasum[$i] = 0;
      $ndata = 0;
      foreach (0 .. $#r) {
	next if ($r[$_] < $rmin);
	last if ($r[$_] > $paths{$d}->get('rmax'));
	$datasum[$i] += $chi[$_]**2 + $chi2[$_]**2;
	$diffsum[$i] += ($chi[$_]-$fit[$_])**2 + ($chi2[$_]-$fit2[$_])**2;
	++$ndata;
      };
      ++$i;
    };
  } elsif (lc($paths{$d}->get('fit_space')) eq 'q') {
    my $i = 0;
    foreach my $w ($paths{$d}->group_weights) {
      ## bring this group up to date in q space for this k-weight
      $paths{$d}->dispose($paths{$d}->write_fft($w, $config{data}{rmax_out}), $dmode);
      $paths{$d}->dispose($paths{$d}->write_bft(), $dmode);
      $paths{$d.".0"}->dispose($paths{$d.".0"}->write_fft($w, $config{data}{rmax_out}), $dmode);
      $paths{$d.".0"}->dispose($paths{$d.".0"}->write_bft(), $dmode);
      my @q    = Ifeffit::get_array($paths{$d}->get('group').".q");
      my @chi  = Ifeffit::get_array($paths{$d}->get('group').".chiq_re");
      my @chi2 = Ifeffit::get_array($paths{$d}->get('group').".chiq_im");
      my @fit  = Ifeffit::get_array($paths{$d}->get('group')."_fit.chiq_re");
      my @fit2 = Ifeffit::get_array($paths{$d}->get('group')."_fit.chiq_im");
      foreach (0 .. $#q) {
	next if ($q[$_] < $paths{$d}->get('kmin'));
	last if ($q[$_] > $paths{$d}->get('kmax'));
	$datasum[$i] += $chi[$_]**2 + $chi2[$_]**2;
	$diffsum[$i] += ($chi[$_]-$fit[$_])**2 + ($chi2[$_]-$fit2[$_])**2;
	++$ndata;
      };
      ++$i;
    };
  };
  if (-e $paths{$d}->get('file')) {
    my $rfactor = 0;
    $rfactor   += $diffsum[$_]/$datasum[$_] foreach (0 .. $#diffsum);
    $rfactor   /= ($#diffsum+1);
    my @noise   = $paths{$d}->chi_noise;
    my $epsilon = (lc($paths{$d}->get('fit_space')) eq 'r') ? $noise[1] : $noise[0];
    my $nidp    = Ifeffit::get_scalar("n_idp");
    #print join(" ", $rfactor, @noise, $epsilon, $nidp, $ndata, $/);
    my $chisqr  = 0;
    $chisqr    += ($nidp*$diffsum[$_]) / ($ndata*$epsilon**2) foreach (0 .. $#diffsum);
    #push @lines, "These are not yet computed quite right in all situations...";
    #push @lines, sprintf("Chi-square for this data set = %.5f", $chisqr);
    push @lines, sprintf("R-factor for this data set   = %.5f", $rfactor);
    if ($#diffsum) {
      my $i = 0;
      foreach my $w ($paths{$d}->group_weights) {
	push @lines, sprintf("R-factor with k-weight=$w for this data set = %.5f", $diffsum[$i]/$datasum[$i]);
	++$i;
      };
    };
  };

  foreach my $l (@lines) {
    print $fh "  $l\n";
  };


};


## in the case of a log file for a summation, only write out those
## paths included in the sum
sub write_paths {
  my ($fh, $d, $how, $how_many, $rhash) = @_;
  my @included =  @{$paths{$d}->get('included')};
  my @inc_mapping = @{$paths{$d}->get('inc_mapping')};

  my $warnings = "";
  my %pathtext;
  my %pp = (reff=>0, dr=>0);
  my $pp_re = "(3rd|4th|d(egen|phase|r)|e[0i]|n.s02|r(|eff)|s(02|s2))";
  foreach my $i (@included) {
    next if (($how == 2) and
	     ($how_many =~ /sel/) and
	     (not exists($$rhash{$inc_mapping[$i]})) );
    $pp{index} = $i;
    $pp{descriptor} = $paths{$inc_mapping[$i]}->descriptor();
    $paths{data0} -> dispose("show \@path $i", 1);
    my ($lines, $response) = (Ifeffit::get_scalar('&echo_lines')||0, "");
    my ($this, $text) = ("","");
    if ($lines) {
      foreach my $l (1 .. $lines) {
	$response = Ifeffit::get_echo()."\n";
	next unless $response;
	next if ($response =~ /\*\*\* correl:/);
	if ($response =~ /^PATH/) {
	  my $p = $inc_mapping[$i];
	  $text .= "\n  ^^^" . $paths{$p}->descriptor();
	  $text .= "\n";
	  ##$text .= ($paths{$p}->get('group')) ? " (ifeffit group = ".$paths{$p}->get('group').")\n" : "\n";
	} elsif ($response =~ /^\s*feff/){
	  $this = (split(/\s+=\s+/, $response))[1];
	PPMATCH1: {
	    ($pp{$1} = $5), last PPMATCH1 # OK value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH1 # bad value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\*+/);
	    ($pp{$1} = $5), last PPMATCH1 # OK value, end of line
	      if ($response =~ /,\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH1 # bad value, end of line
	      if ($response =~ /,\s*$pp_re\s+=\*+/);
	  };
	  $text .= "    ".$response;
	} else {
	PPMATCH3: {
	    ($pp{$1} = $5), last PPMATCH3 # OK value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH3 # bad value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\*+/);
	  };
	  $text .= $response;
	};
      };
    };
    $pathtext{$i} = [$this,$text];
    $warnings .= &check_path(\%pp);
    store_ppvalues($inc_mapping[$i], \%pp);
  };

  foreach my $t (@included) {
    next if (($how == 2) and
	     ($how_many =~ /sel/) and
	     (not exists($$rhash{$inc_mapping[$t]})) );
    foreach my $l (split(/\n/, $pathtext{$t}[1])) {
      if ($l =~ /^\s*\^\^\^/i) {
	$l =~ s/^\s*\^\^\^//;
	print $fh "  ";
	print $fh $l." ..\n";
      } elsif ($l =~ /^\s*feff/) {
	print $fh $l."\n";
      } elsif ($l =~ /s02\s*=/) {
	$l =~ s/n\*s/s/;
	$l =~ s/=/  =/ if $paths{data0}->vstr == 1.02005;
	print $fh "    ".$l."\n";
      } else {
	print $fh "    ".$l."\n";
      };
    };
  };
  return $warnings;
}

sub write_paths_pre_1_2_5 {
  my ($fh, $d, $how, $how_many, $rhash) = @_;
  my @included =  @{$paths{$d}->get('included')};
  my @inc_mapping = @{$paths{$d}->get('inc_mapping')};

  my $warnings = "";
  my %pathtext;
  my %pp = (reff=>0, dr=>0);
  my $pp_re = "(3rd|4th|d(egen|phase|r)|e[0i]|reff|s(02|s2))";
  foreach my $i (@included) {
    next if (($how == 2) and
	     ($how_many =~ /sel/) and
	     (not exists($$rhash{$inc_mapping[$i]})) );
    $pp{index} = $i;
    $pp{descriptor} = $paths{$inc_mapping[$i]}->descriptor();
    $paths{data0} -> dispose("show \@path $i", 1);
    my ($lines, $response) = (Ifeffit::get_scalar('&echo_lines')||0, "");
    my ($this, $text) = ("","");
    if ($lines) {
      foreach my $l (1 .. $lines) {
	$response = Ifeffit::get_echo()."\n";
	next unless $response;
	next if ($response =~ /\*\*\* correl:/);
	if ($response =~ /^PATH/) {
	  my $p = $inc_mapping[$i];
	  $text .= "\n  " . $paths{$p}->descriptor();
	  $text .= "\n";
	  ##$text .= ($paths{$p}->{group}) ? " (ifeffit group = ".$paths{$p}->get('group').")\n" : "\n";
	} elsif ($response =~ /^\s*feff/){
	  $this = (split(/\s+=\s+/, $response))[1];
	  $response =~ s/=/  =/g;
	PPMATCH1: {
	    ($pp{$1} = $4), last PPMATCH1 # OK value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH1 # bad value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\*+/);
	    ($pp{$1} = $4), last PPMATCH1 # OK value, end of line
	      if ($response =~ /,\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH1 # bad value, end of line
	      if ($response =~ /,\s*$pp_re\s+=\*+/);
	  };
	  $text .= "    ".$response;
	} else {
	  $response =~ s/=/  =/g; # align = signs with reff+dr line
	  $text .= "    ".$response;
	PPMATCH3: {
	    ($pp{$1} = $4), last PPMATCH3 # OK value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH3 # bad value, beginning of line
	      if ($response =~ /^\s*$pp_re\s+=\*+/);
	  };
	PPMATCH4: {
	    ($pp{$1} = $4), last PPMATCH4 # OK value, end of line
	      if ($response =~ /,\s*$pp_re\s+=\s+(-?\d+\.\d+)/);
	    ($pp{$1} = "tilt"), last PPMATCH4 # bad value, end of line
	      if ($response =~ /,\s*$pp_re\s+=\*+/);
	  };
	  ## I know that reff is reported before dr...
	  if ($response =~ /^\s*dr\s+=\s+/) { # report net R
	    $text .= sprintf("    reff+dr =   %9.6f\n", $pp{reff}+$pp{dr});
	  };
	};
      };
    };
    $pathtext{$i} = [$this,$text];
    $warnings .= &check_path(\%pp);
  };

  foreach my $t (@included) {
    next if (($how == 2) and
	     ($how_many =~ /sel/) and
	     (not exists($$rhash{$inc_mapping[$t]})) );
    foreach my $l (split(/\n/, $pathtext{$t}[1])) {
      if ($l =~ /^FEFF/) {
	print $fh $l."\n", 'pathid';
      } else {
	print $fh $l."\n";
      };
    };
  };
  return $warnings;
};


sub check_path {
  my $pp = $_[0];
  my ($epsi, $warnings) = (0.0001, "");
  ## check for bad values
  my %names = ('n*s02'=>'n*S02', ss2=>'sigma^2', dr=>'delta_R', e0=>'e0', ei=>'ei',
	       dphase=>'dphase', '3rd'=>'3rd cumulant', '4th'=>'4th cumulant');
  foreach my $k (qw(n*s02 ss2 dr e0 ei dphase 3rd 4th)) {
    next unless exists $$pp{$k};
    if ($$pp{$k} eq 'tilt') {
      $warnings .= "The $names{$k} of \"$$pp{descriptor}\" (path $$pp{index}) is not a number.\n\n";
      $$pp{$k} = $epsi;
    };
  };
 SWITCH: {
    my $s02 = ($paths{data0}->vstr == 1.02005) ? 'n*s02' : 's02';
    ($config{warnings}{s02_neg} and
     ($$pp{$s02} < 0)) and do {
       $warnings .= "The S02 of \"$$pp{descriptor}\" (path $$pp{index}) is negative.\n\n";
       last SWITCH;
     };
    ($config{warnings}{s02_max} and
     ($$pp{$s02} > $config{warnings}{s02_max})) and do {
       $warnings .= "The S02 of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
       last SWITCH;
     };

    ($config{warnings}{ss2_neg} and
     ($$pp{ss2} < 0)) and do {
      $warnings .= "The sigma^2 of \"$$pp{descriptor}\" (path $$pp{index}) is negative.\n\n";
      last SWITCH;
    };
    ($config{warnings}{ss2_max} and
     ($$pp{ss2} > $config{warnings}{ss2_max})) and do {
      $warnings .= "The sigma^2 of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
      last SWITCH;
    };
    ($config{warnings}{dr_max} and
     (abs($$pp{dr}) > $config{warnings}{dr_max})) and do {
      $warnings .= "The delta_R of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
      last SWITCH;
    };
    ($config{warnings}{e0_max} and
     (abs($$pp{e0}) > $config{warnings}{e0_max})) and do {
      $warnings .= "The e0 of \"$$pp{descriptor}\" (path $$pp{index}) is greater than $config{warnings}{e0_max} eV.\n\n";
      last SWITCH;
    };
    ($config{warnings}{ei_max} and
     (abs($$pp{ei}) > $config{warnings}{ei_max})) and do {
      $warnings .= "The ei of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
      last SWITCH;
    };
    ($config{warnings}{dphase_max} and
     (abs($$pp{dphase}) > $config{warnings}{dphase_max})) and do {
      $warnings .= "The dphase of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
      last SWITCH;
    };
    ($config{warnings}{'3rd_max'} and
     (abs($$pp{'3rd'}) > $config{warnings}{'3rd_max'})) and do {
      $warnings .= "The 3rd cumulant of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
      last SWITCH;
    };
    ($config{warnings}{'4th_max'} and
     (abs($$pp{'4th'}) > $config{warnings}{'4th_max'})) and do {
      $warnings .= "The 4th cumulant of \"$$pp{descriptor}\" (path $$pp{index}) is suspiciously large.\n\n";
      last SWITCH;
    };
  };
  return $warnings;
};


sub store_ppvalues {
  my ($this, $rpp) = @_;
  my %names = ('n*s02'=>'s02', ss2=>'sigma^2', dr=>'delr', e0=>'e0', ei=>'ei',
	       dphase=>'dphase', '3rd'=>'3rd', '4th'=>'4th');
  foreach my $key (keys %$rpp) {
    next unless exists($names{$key});
    my $p = $names{$key};
    #print join("|", $key, $$rpp{$key}), $/;
    $paths{$this} -> make("value_$p" => $$rpp{$key});
  };
};


sub show_correlations {
  my $fh = $_[0];
  my @order;
  foreach (@gds) {
    push @order, $_->name if ($_->type eq 'guess');
  };
  my $nd = 0;
  my %bkg_map;
  foreach my $d (keys %paths) {	# get all bkg params from all data sets
    next unless (ref($paths{$d}) =~ /Ifeffit/);
    next unless ($paths{$d}->type eq 'data');
    $nd = $paths{$d}->get('data_index');
    if ($paths{$d}->get('do_bkg') eq 'yes') {
      my $i = 1;
      my $bkg = sprintf("bkg%2.2d_%2.2d", $nd, $i);
      while (Ifeffit::get_scalar($bkg)) {
	push @order, $bkg;
	++$i;
	$bkg = sprintf("bkg%2.2d_%2.2d", $nd, $i);
      };
    };
    my $this = sprintf("bkg%2.2d_XX", $nd);
    $bkg_map{$this} = $paths{$d}->descriptor();
  };
  my @correls;
  my $cormin = $paths{&first_data}->{cormin};
  $paths{data0} -> dispose("\n## get correlations\n", $dmode);
  $paths{data0} -> dispose('correl(x=@all, y=@all, save, min=0)', $dmode);

  foreach my $i (0 .. $#order) {
    INNER: foreach my $j ($i .. $#order) {
	next INNER if ($i == $j);
	## default is to skip correlations between background parameters
	## belonging to the same data set
	next INNER if ((lc($config{data}{bkg_corr}) eq 'no') and
		       ($order[$i] =~ /bkg(\d\d)_\d\d/) and
		       ($order[$j] =~ /bkg$1_\d\d/));
	my $cor = join("_", "correl", $order[$j], $order[$i]);
	my $val = Ifeffit::get_scalar($cor);
	next INNER unless (abs($val) > $cormin);
	push @correls, [$order[$i], $order[$j], $val];
      };
    };
  $paths{data0} -> dispose("\n", $dmode);
  @correls = sort { abs(@$b[2]) <=> abs(@$a[2]) } @correls;
  print $fh "\n\nCorrelations between variables:\n";
  foreach (@correls) {
    my $str = sprintf("  %10s and %-10s --> %7.4f\n", @$_);
    print $fh $str;
  };
  print $fh "All other correlations are below $cormin\n\n";
  my $did_bkg = grep {$paths{$_}->get('do_bkg') eq 'yes'} (&all_data);
  return unless $did_bkg;
  foreach my $k (sort (keys %bkg_map)) {
    print $fh sprintf("Background parameters \"%s\" belong to data set %s\n",
		      $k, $bkg_map{$k});
  };
};

##  END OF THE PALETTES SUBSECTION

