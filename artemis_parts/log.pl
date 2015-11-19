# -*- cperl -*-
##  This file is part of Artemis, copyright (c) 2002-2006 Bruce Ravel
##

###===================================================================
### log file subsystem
###===================================================================


sub log_file_display {
  my $which = $_[0] || 'results';
  $which = 'results' unless (($which eq 'results') or ($which eq 'files'));
  my $is_busy = grep (/Busy/, $top->bindtags);
  $top -> Busy unless $is_busy;

  $notes{$which} -> delete('1.0', 'end');
  my $log = $_[1] || File::Spec->catfile($project_folder, "fits",
					 sprintf("fit%4.4d", $fit{count}), "log");
  ##print join("!", @_), $/;
  ##print join("|", $log, @log_type), $/;
  Echo("Could not read log file \"$log\""), return unless (-e $log);
 SWITCH:{

    ## raw log file
    ($log_type[1] eq 'raw') and do {
      open F, $log;
      while (<F>) {
	$_ =~ s{\r}{} if not $is_windows;
	if ($_ =~ /^!!/) {
	  $notes{$which} -> insert('end', $_, 'warning');
	} elsif ($_ =~ /\.\.$/) {
	  $notes{$which} -> insert('end', $_, 'pathid');
	} else {
	  $notes{$which} -> insert('end', $_);
	};
      }
      $notes{$which} -> yviewMoveto(0);
      close F;
      last SWITCH;
    };

    ## quick view
    ($log_type[1] eq 'quick') and do {
      my $data = Ifeffit::ArtemisLog -> new($log);
      my $was_sum = grep {/Fitting was not performed./} ($data->get('warnings'));
      ## header
      $notes{$which} -> insert('end', "Project title   : " . $data -> get('Project title') . "\n");
      $notes{$which} -> insert('end', "Comment         : " . $data -> get('Comment') . "\n");
      $notes{$which} -> insert('end', "Figure of merit : " . $data -> get('Figure of merit') . "\n");
      ## statistics
      $notes{$which} -> insert('end', $data->stats) unless $was_sum;
      ## guesses
      $notes{$which} -> insert('end', $data->guess);
      ## restraints
      $notes{$which} -> insert('end', $data->restraint);
      ## afters
      $notes{$which} -> insert('end', $data->after);
      undef $data;
      last SWITCH;
    };

    ## columnar view
    ($log_type[1] eq 'column') and do {
      my $data = Ifeffit::ArtemisLog -> new($log);
        #print Data::Dumper->Dump([$data], [qw(*data)]);
        #$top -> Unbusy unless $is_busy;
        #return;
      my $was_sum = grep {/Fitting was not performed./} ($data->get('warnings'));
      $notes{$which} -> insert('end', $data->header);
      $notes{$which} -> insert('end', $data->stats) unless $was_sum;
      $notes{$which} -> insert('end', $data->guess);
      if ($data->list('def')) {
	my $wsp = &which_set_path;
	($wsp)?
	  $notes{$which} -> insert('end', $data->def($paths{$wsp}->descriptor())) :
	    $notes{$which} -> insert('end', $data->def);
      };
      $notes{$which} -> insert('end', $data->restraint) if $data->list('restraint');
      $notes{$which} -> insert('end', $data->set) if $data->list('set');
      $notes{$which} -> insert('end', $data->after) if $data->list('after');
      $notes{$which} -> insert('end', $data->correlations) unless $was_sum;
      ## restraints  data_header  columns
      foreach my $d ($data->list('data')) {
	my $l = 0;
	foreach my $p ($data->get($d, 'paths')) {
	  ($l = length($p)) if (length($p) > $l);
	};
	my $spacer = " " x $l;
	$l+=3;
	my $labels = "    path" . $spacer . "degen     amp      sigma^2    e0        reff     delta_R    R\n";
	$notes{$which} -> insert('end', $data->dataparams($d,0));
	## tables of path param values
	$notes{$which} -> insert('end', $labels);
	$notes{$which} -> insert('end', "  " . "-" x length($labels) . "--\n");
	my $pattern = '  %-' . $l . join(" ", qw(s %9.5f %9.3f %9.5f %9.5f %9.5f %9.5f %9.5f %s));
	foreach my $p ($data->get($d, 'paths')) {
	  $notes{$which} -> insert('end', sprintf($pattern,
						   "\"".$p."\"",
						   $data->get($d, $p, 'degen'),
						   $data->get($d, $p, 's02'),
						   $data->get($d, $p, 'ss2'),
						   $data->get($d, $p, 'e0'),
						   $data->get($d, $p, 'r')-$data->get($d, $p, 'dr'),
						   $data->get($d, $p, 'dr'),
						   $data->get($d, $p, 'r'),
						   "\n"
						  ));
	};
	$notes{$which} -> insert('end', "\n");
	my $write_second_table = 0;
	my $epsilon = 0.000001;
	foreach my $p ($data->get($d, 'paths')) {
	  foreach my $param (qw(ei 3rd 4th dphase)) {
	    ++$write_second_table if (abs($data->get($d, $p, $param)) > $epsilon);
	  };
	};
	if ($write_second_table) {
	  $pattern = '  %-' . $l . join(" ", qw(s %9.5f %9.5f %9.5f %9.5f %s));
	  $labels = "    path" . $spacer . "ei        3rd       4th      dphase\n";
	  $notes{$which} -> insert('end', $labels);
	  $notes{$which} -> insert('end', "  " . "-" x length($labels) . "--\n");
	  foreach my $p ($data->get($d, 'paths')) {
	    $notes{$which} -> insert('end', sprintf($pattern,
						    "\"".$p."\"",
						    $data->get($d, $p, 'ei'),
						    $data->get($d, $p, '3rd'),
						    $data->get($d, $p, '4th'),
						    $data->get($d, $p, 'dphase'),
						    "\n"
						   ));
	  };
	};
	$notes{$which} -> insert('end', "\n");
	$notes{$which} -> insert('end', "\n");
      };
      last SWITCH;
    };
    ## operational view
    ($log_type[1] eq 'operational') and do {
      my $data = Ifeffit::ArtemisLog -> new($log);
      ## header
      $notes{$which} -> insert('end', $data->header);
      my $was_sum = grep {/Fitting was not performed./} ($data->get('warnings'));
      $notes{$which} -> insert('end', $data->stats) unless $was_sum;
      foreach my $d ($data->list('data')) {
	$notes{$which} -> insert('end', $data->dataparams($d,0));
      }
      last SWITCH;
    };
  };
  $top -> Unbusy unless $is_busy;
};

sub set_log_style {
  return ('Raw log file', 'raw')    if ($_[0] eq 'raw');
  return ('Quick view',   'quick')  if ($_[0] eq 'quick');
  return ('Column view',  'column') if ($_[0] eq 'column');
};


## END OF THE LOG SUBSYSTEM

