## -*- cperl -*-
## ===========================================================================
##  This is the find energies portion of hephaestus

sub find {
  $periodic_table -> packForget() if $current =~ /$uses_periodic_regex/;
  switch({page=>"find", text=>'Ordered List of Absorption Energies'});
};


sub setup_find {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  $data{find_min}      = 100;
  $data{find_energy}   ||= 9000;
  $data{find_harmonic} ||= 1;

  ## snarf (quietly!) the list of energies from the list used for the
  ## next_energy function in Xray::Absoprtion::Elam
  my $hash;
  do {
    no warnings;
    $hash = $$Xray::Absorption::Elam::r_elam{energy_list};
  };
  my @find_list = ();
  foreach my $key (keys %$hash) {
    next unless exists $$hash{$key}->[2];
    push @find_list, $$hash{$key};
  };
  ## and sort by increasing energy
  @find_list = sort {$a->[2] <=> $b->[2]} @find_list;
  $data{find_list} = \@find_list;

  ## a list of all edges and energies
  my $lf = $frame -> LabFrame(-label=>"All edges ($data{find_min} eV - 135 keV)",
			      -labelside=>'acrosstop',@label_args)
    -> pack(-fill=>'both', -side=>'left', -padx=>10, -pady=>1);
  my $lb = $lf -> Scrolled("Listbox", -scrollbars=>'e',
			   -selectmode=>'single',
			   -font =>$config{fonts}{fixed})
    -> pack(-fill=>'both', -expand=>1, -side=>'left');
  BindMouseWheel($lb);
  $data{find_lb} = $lb;
  foreach (@find_list) {
    next if ($_->[2] < $data{find_min});
    $lb -> insert('end', sprintf("%-2s %-2s....%8.1f ", ucfirst($_->[0]), ucfirst($_->[1]), $_->[2]));
  };

  ## the interactive part
  $lf = $frame -> LabFrame(-label=>'Target energy',
			   -labelside=>'acrosstop', @label_args)
    -> pack(-fill=>'x', -expand=>1, -side=>'right', -pady=>1, -padx=>10);
  my $fr = $lf -> Frame() -> pack(-side=>'top', -pady=>3, -anchor=>'c');
  my $entry = $fr -> Entry(-width=>8, -textvariable=>\$data{find_energy},
			   -font=>$config{fonts}{fixed},
			   -validate=>'key', -validatecommand=>\&set_variable)
    -> pack(-side=>'left', -pady=>4);
  $fr -> Label(-text=>'eV', @label_args)
    -> pack(-side=>'right');
  $fr = $lf -> Frame() -> pack(-side=>'top', -pady=>3, -anchor=>'c');
  $fr -> Label(-text=>'Harmonic: ', @label_args)
    -> pack(-side=>'left');
  $fr -> Radiobutton(-text=>"Fundamental", -variable=>\$data{find_harmonic},
		     -font=>$config{fonts}{smbold},
		     -value=>1, -command => \&find_energy)
    -> pack(-side=>'left');
  $fr -> Radiobutton(-text=>"2nd", -variable=>\$data{find_harmonic},
		     -font=>$config{fonts}{smbold},
		     -value=>2, -command => \&find_energy)
    -> pack(-side=>'left');
  $fr -> Radiobutton(-text=>"3rd", -variable=>\$data{find_harmonic},
		     -font=>$config{fonts}{smbold},
		     -value=>3, -command => \&find_energy)
    -> pack(-side=>'left');
  ##   $fr -> Radiobutton(-text=>"4th", -variable=>\$data{find_harmonic},
  ## 		     -value=>4, -command => \&find_energy)
  ##     -> pack(-side=>'left');
  ##   $fr -> Radiobutton(-text=>"5th", -variable=>\$data{find_harmonic},
  ## 		     -value=>5, -command => \&find_energy)
  ##     -> pack(-side=>'left');
  my $button = $lf -> Button(-width=>8, -text=>"Find it!", @button_args,
			     -command => \&find_energy)
    -> pack(-side=>'bottom', -pady=>3, -fill=>'x', -expand=>1);
  $entry -> bind("<KeyPress-Return>"=>sub{$button->invoke});

  ## initialize
  &find_energy;
  return $frame;
};

sub find_energy {
  ## deal with the harmonic setting
  my $energy = $data{find_energy} * $data{find_harmonic};
  ## deal with energies below the low energy cutoff
  if ($energy <= $data{find_min}) {
    $data{find_lb} -> see(0);
    $data{find_lb} -> selectionClear(0, 'end');
    $data{find_lb} -> selectionSet(0);
    return;
  };
  ## find the energy just above the specified energy
  my $count = -2;
  foreach (@{$data{find_list}}) {
    next if ($_->[2] < $data{find_min});
    my $en = $_->[2];
    ++$count;
    last if ($en >= $energy);
  };
  ## display the edge just below the specified energy
  $data{find_lb} -> see($count);
  $data{find_lb} -> selectionClear(0, 'end');
  $data{find_lb} -> selectionSet($count);
};
