
## ===========================================================================
##  This is the find lines portion of hephaestus

sub line {
  $periodic_table -> packForget() if $current =~ /$uses_periodic_regex/;
  switch({page=>"line", text=>'Ordered List of Fluorescence Line Energies'});
};


sub setup_line {
  my $frame = $_[0] -> Frame(-borderwidth=>2, -relief=>'flat');

  $data{line_min}      = 100;
  $data{line_energy} ||= 8047;
  $data{line_harmonic} = 1;

  ## snarf (quietly!) the list of energies from the list used for the
  ## next_energy function in Xray::Absoprtion::Elam
  my $hash;
  do {
    no warnings;
    $hash = $$Xray::Absorption::Elam::r_elam{line_list};
  };
  my @line_list = ();
  foreach my $key (keys %$hash) {
    next unless exists $$hash{$key}->[2];
    push @line_list, $$hash{$key};
  };
  ## and sort by increasing energy
  @line_list = sort {$a->[2] <=> $b->[2]} @line_list;
  $data{line_list} = \@line_list;

  ## a list of all edges and energies
  my $lf = $frame -> LabFrame(-label=>"All fluorescence lines ($data{line_min} eV - 135 keV)",
			      -labelside=>'acrosstop',@label_args)
    -> pack(-fill=>'y', -side=>'left', -padx=>10, -pady=>1);
  my $lb = $lf -> Scrolled("Listbox",
			   -scrollbars => 'e',
			   -width      => 46,
			   -selectmode => 'single',
			   -font       => $config{fonts}{fixed},)
    -> pack(-fill=>'both', -expand=>1, -side=>'left');
  BindMouseWheel($lb);
  $data{line_lb} = $lb;
  foreach (@line_list) {
    next if ($_->[2] < $data{line_min});
    $lb -> insert('end', sprintf("%-2s %-8s %-9s (%6.4f) .... %8.1f ",
				 ucfirst($_->[0]),
				 Xray::Absorption->get_Siegbahn_full($_->[1]),
				 Xray::Absorption->get_IUPAC($_->[1]),
				 Xray::Absorption->get_intensity($_->[0],$_->[1]),
				 $_->[2]));
  };

  ## the interactive part
  $lf = $frame -> LabFrame(-label=>'Target energy',
			   -labelside=>'acrosstop', @label_args)
    -> pack(-fill=>'x', -expand=>1, -side=>'right', -pady=>1, -padx=>10);
  my $fr = $lf -> Frame() -> pack(-side=>'top', -pady=>3, -anchor=>'c');
  my $entry = $fr -> Entry(-width	    => 8,
			   -textvariable    => \$data{line_energy},
			   -font	    => $config{fonts}{smfixed},
			   -validate	    => 'key',
			   -validatecommand => \&set_variable)
    -> pack(-side=>'left', -pady=>4);
  $fr -> Label(-text=>'eV', @label_args)
    -> pack(-side=>'right');
##   $fr = $lf -> Frame() -> pack(-side=>'top', -pady=>3, -anchor=>'c');
##   $fr -> Label(-text=>'Harmonic: ', @label_args)
##     -> pack(-side=>'left');
##   $fr -> Radiobutton(-text=>"Fundamental", -variable=>\$data{line_harmonic},
## 		     -value=>1, -command => \&line_energy)
##     -> pack(-side=>'left');
##   $fr -> Radiobutton(-text=>"2nd", -variable=>\$data{line_harmonic},
## 		     -value=>2, -command => \&line_energy)
##     -> pack(-side=>'left');
##   $fr -> Radiobutton(-text=>"3rd", -variable=>\$data{line_harmonic},
## 		     -value=>3, -command => \&line_energy)
##     -> pack(-side=>'left');
  my $button = $lf -> Button(-width=>8, -text=>"Find it!", @button_args,
			     -command => \&line_energy)
    -> pack(-side=>'bottom', -pady=>3, -fill=>'x', -expand=>1);
  $entry -> bind("<KeyPress-Return>"=>sub{$button->invoke});

  ## initialize
  &line_energy;
  return $frame;
};

sub line_energy {
  ## deal with the harmonic setting
  my $energy = $data{line_energy} * $data{line_harmonic};
  ## deal with energies below the low energy cutoff
  if ($energy <= $data{line_min}) {
    $data{line_lb} -> see(0);
    $data{line_lb} -> selectionClear(0, 'end');
    $data{line_lb} -> selectionSet(0);
    return;
  };
  ## find the line energy just above the specified energy
  my $count = -2;
  foreach (@{$data{line_list}}) {
    next if ($_->[2] < $data{line_min});
    my $en = $_->[2];
    ++$count;
    last if ($en >= $energy);
  };
  ## display the line energy just below the specified energy
  $data{line_lb} -> see($count);
  $data{line_lb} -> selectionClear(0, 'end');
  $data{line_lb} -> selectionSet($count);
};
